"""Medicoes e contratos de compra ligados aos ATERROS, com a situacao de pagamento (ultimos N dias).

Uso:
    export PROTHEUS_USER=...; export PROTHEUS_PASS='...'     (ou digite quando pedir)
    python medicoes_aterro.py [--dias 60] [--filtro ATERR] [--saida arquivo.xlsx]

O que e "aterro": item de medicao em que algum destes textos contem --filtro (sem acento, maiusculo):
  nome da filial, centro de custo (CC + descricao), projeto/classe de valor, tipo do contrato ou produto.
A coluna CRITERIO_ATERRO diz qual deles casou. A aba "Filiais" lista todas para conferir o criterio.

Vinculo medicao -> titulo a pagar (SE2):
  1. titulo gerado pela propria medicao (E2_MDCONTR + E2_MEDNUME) - precisa da API com essas colunas;
  2. senao, pelo pedido da medicao (CNE_PEDIDO) = pedido da nota fiscal do titulo.
Situacao: Pago | Parcialmente pago | Em aberto | Sem titulo (NF nao lancada) | Sem pedido e sem titulo.
"""
import argparse
import getpass
import os
import sys
import unicodedata
from datetime import date, timedelta

import pandas as pd
import requests

BASE_URL = "http://177.136.201.210:8086/rest/APIBI"


def get_all(s, path, params=None, page_size=5000):
    params, itens, page = dict(params or {}), [], 1
    while True:
        params.update({"page": page, "pageSize": page_size})
        r = s.get(f"{BASE_URL}{path}", params=params, timeout=900)
        if not r.ok:
            sys.exit(f"GET {path} -> {r.status_code}: {r.text[:300]}")
        j = r.json()
        itens.extend(j.get("items", []))
        print(f"  {path} pagina {page}: {len(itens)} linhas")
        if not j.get("hasNext"):
            return pd.DataFrame(itens)
        page += 1


def norm(x):
    x = "" if x is None or (isinstance(x, float) and pd.isna(x)) else str(x)
    return unicodedata.normalize("NFKD", x).encode("ascii", "ignore").decode().upper().strip()


def txt(df, col):
    return df[col].map(norm) if col in df.columns else pd.Series("", index=df.index)


def num(df, col):
    return pd.to_numeric(df[col], errors="coerce").fillna(0) if col in df.columns else 0.0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dias", type=int, default=60)
    ap.add_argument("--filtro", default="ATERR", help="texto que identifica aterro (padrao ATERR: aterro/aterros)")
    ap.add_argument("--saida", default=f"medicoes_aterro_{date.today():%Y%m%d}.xlsx")
    a = ap.parse_args()
    filtro = norm(a.filtro)

    hoje = date.today()
    ini = hoje - timedelta(days=a.dias)
    de, ate = f"{ini:%Y%m%d}", f"{hoje:%Y%m%d}"

    s = requests.Session()
    s.auth = (os.environ.get("PROTHEUS_USER") or input("Usuario API: "),
              os.environ.get("PROTHEUS_PASS") or getpass.getpass("Senha API: "))
    s.headers["Accept"] = "application/json"

    print("Baixando...")
    fil = get_all(s, "/bi/geral/filiais")
    med = get_all(s, "/bi/contratos/medicoes", {"desde": de})
    ctr = get_all(s, "/bi/contratos/contratos")
    abertos = get_all(s, "/bi/financeiro/titulos-abertos", {"escopo": "TODOS"})
    pagos = get_all(s, "/bi/financeiro/pagamentos", {"de": de, "ate": ate, "escopo": "TODOS"})

    # ---------------- medicoes da janela + criterio aterro
    for c in ("FILIAL", "CONTRATO", "REVISAO", "MEDICAO", "PEDIDO"):
        med[c] = med[c].fillna("").astype(str).str.strip()
    med["VL_TOTAL"] = num(med, "VL_TOTAL")
    med = med[med["DT_ENTREGA"].astype(str).between(de, ate)].copy()
    nomes = dict(zip(fil["FILIAL"].astype(str).str.strip(), fil["NOME"])) if len(fil) else {}
    med["FILIAL_NOME"] = med["FILIAL"].map(nomes).fillna("")

    ctr["FILIAL"] = ctr["FILIAL"].astype(str).str.strip()
    ctr["CONTRATO"] = ctr["CONTRATO"].astype(str).str.strip()
    tipo = ctr.drop_duplicates(["FILIAL", "CONTRATO"], keep="last").set_index(["FILIAL", "CONTRATO"])["TIPO_DESC"]
    med["TIPO_CONTRATO"] = [tipo.get((f, c), "") for f, c in zip(med["FILIAL"], med["CONTRATO"])]

    criterios = {
        "filial": txt(med, "FILIAL_NOME"),
        "centro de custo": txt(med, "CC") + " " + txt(med, "CC_DESC"),
        "projeto": txt(med, "PROJETO") + " " + txt(med, "PROJ_DESC"),
        "tipo do contrato": txt(med, "TIPO_CONTRATO"),
        "produto": txt(med, "PROD_DESC"),
    }
    med["CRITERIO_ATERRO"] = ""
    for nome, serie in criterios.items():
        casou = serie.str.contains(filtro, regex=False)
        med.loc[casou, "CRITERIO_ATERRO"] += (med.loc[casou, "CRITERIO_ATERRO"].ne("").map({True: ", ", False: ""}) + nome)
    # o contrato inteiro entra se qualquer item dele casou
    chave_ctr = med["FILIAL"] + "|" + med["CONTRATO"]
    ctr_aterro = set(chave_ctr[med["CRITERIO_ATERRO"] != ""])
    med["CRITERIO_ATERRO"] = med["CRITERIO_ATERRO"].where(med["CRITERIO_ATERRO"] != "",
                                                          chave_ctr.isin(ctr_aterro).map({True: "outro item do contrato", False: ""}))
    at = med[med["CRITERIO_ATERRO"] != ""].copy()

    # ---------------- titulos (abertos + pagos na janela), um por REC
    tit = pd.concat([abertos.assign(_o="aberto"), pagos.assign(_o="pago")], ignore_index=True)
    for c in ("FILIAL", "PEDIDO", "MDCONTR", "MEDNUME", "PREFIXO", "NUM", "PARCELA", "TIPO", "FORNECEDOR"):
        tit[c] = tit[c].fillna("").astype(str).str.strip() if c in tit.columns else ""
    tit["PAGO"] = num(tit, "PAGO")
    tit["VALOR"], tit["SALDO"] = num(tit, "VALOR"), num(tit, "SALDO")
    tem_md = (tit["MDCONTR"] != "").any()
    t1 = (tit.groupby("REC")
             .agg(FILIAL=("FILIAL", "first"), PREFIXO=("PREFIXO", "first"), NUM=("NUM", "first"),
                  PARCELA=("PARCELA", "first"), TIPO=("TIPO", "first"), FORNECEDOR=("FORNECEDOR", "first"),
                  VENCREA=("VENCREA", "first"), VALOR=("VALOR", "first"), SALDO=("SALDO", "min"),
                  PAGO_JANELA=("PAGO", "sum"), ULT_PAGTO=("PAGO_EM", "max"),
                  PEDIDO=("PEDIDO", "first"), MDCONTR=("MDCONTR", "first"), MEDNUME=("MEDNUME", "first"))
             .reset_index())

    # vinculo por medicao (titulo gerado pela medicao) e por pedido
    md = t1[t1["MDCONTR"] != ""].assign(K=lambda d: d["FILIAL"] + "|" + d["MDCONTR"] + "|" + d["MEDNUME"])
    pd_ = t1[t1["PEDIDO"] != ""].assign(K=lambda d: d["FILIAL"] + "|" + d["PEDIDO"])

    chave = ["FILIAL", "FILIAL_NOME", "CONTRATO", "REVISAO", "MEDICAO"]
    mm = (at.groupby(chave)
            .agg(DT_ENTREGA=("DT_ENTREGA", "min"), DT_ENCERR=("DT_ENCERR", "max"),
                 FORNECEDOR=("FORN_NOME", "max"), TIPO_CONTRATO=("TIPO_CONTRATO", "max"),
                 CC=("CC_DESC", lambda x: ", ".join(sorted(set(x.dropna()) - {""}))),
                 PROJETO=("PROJ_DESC", lambda x: ", ".join(sorted(set(x.dropna()) - {""}))),
                 PEDIDOS=("PEDIDO", lambda x: ", ".join(sorted(set(x) - {""}))),
                 CRITERIO_ATERRO=("CRITERIO_ATERRO", "first"), ITENS=("VL_TOTAL", "size"),
                 VALOR_MEDIDO=("VL_TOTAL", "sum"))
            .reset_index())

    vinc = []
    for _, r in mm.iterrows():
        k_md = f"{r.FILIAL}|{r.CONTRATO}|{r.MEDICAO}"
        ts = md[md["K"] == k_md]
        via = "medicao (E2_MDCONTR)"
        if ts.empty and r.PEDIDOS:
            ts = pd_[pd_["K"].isin([f"{r.FILIAL}|{p}" for p in r.PEDIDOS.split(", ")])]
            via = "pedido"
        for _, t in ts.iterrows():
            vinc.append({**{c: r[c] for c in ("FILIAL", "CONTRATO", "MEDICAO")}, "VIA": via,
                         **{c: t[c] for c in ("REC", "PREFIXO", "NUM", "PARCELA", "TIPO", "VENCREA",
                                              "VALOR", "SALDO", "PAGO_JANELA", "ULT_PAGTO")}})
    vinc = pd.DataFrame(vinc, columns=["FILIAL", "CONTRATO", "MEDICAO", "VIA", "REC", "PREFIXO", "NUM", "PARCELA",
                                       "TIPO", "VENCREA", "VALOR", "SALDO", "PAGO_JANELA", "ULT_PAGTO"])
    agg = (vinc.drop_duplicates(["FILIAL", "CONTRATO", "MEDICAO", "REC"])
               .groupby(["FILIAL", "CONTRATO", "MEDICAO"])
               .agg(TITULOS=("REC", "nunique"), VIA=("VIA", "first"), VALOR_TITULOS=("VALOR", "sum"),
                    SALDO_ABERTO=("SALDO", "sum"), PAGO_NA_JANELA=("PAGO_JANELA", "sum"), ULT_PAGTO=("ULT_PAGTO", "max"))
               .reset_index())
    mm = mm.merge(agg, on=["FILIAL", "CONTRATO", "MEDICAO"], how="left")
    for c in ("TITULOS", "VALOR_TITULOS", "SALDO_ABERTO", "PAGO_NA_JANELA"):
        mm[c] = mm[c].fillna(0)

    def situacao(r):
        if r.TITULOS == 0:
            return "Sem titulo (NF nao lancada)" if r.PEDIDOS else "Sem pedido e sem titulo"
        if r.SALDO_ABERTO <= 0.005:
            return "Pago"
        return "Parcialmente pago" if r.PAGO_NA_JANELA > 0 or r.SALDO_ABERTO < r.VALOR_TITULOS - 0.005 else "Em aberto"
    mm["SITUACAO"] = mm.apply(situacao, axis=1)
    mm = mm.sort_values(["SITUACAO", "VALOR_MEDIDO"], ascending=[True, False])

    # ---------------- contratos dos aterros (revisao atual)
    for c in ("VL_INICIAL", "VL_ATUAL", "SALDO"):
        ctr[c] = pd.to_numeric(ctr[c], errors="coerce")
    ctr["_ord"] = ctr["SITUACAO"].isin(["09", "10"]).astype(int)
    cont = (ctr[(ctr["FILIAL"] + "|" + ctr["CONTRATO"]).isin(ctr_aterro)]
               .sort_values(["FILIAL", "CONTRATO", "_ord", "REVISAO"], ascending=[True, True, True, False])
               .drop_duplicates(["FILIAL", "CONTRATO"]).drop(columns=["_ord", "_endpoint", "_params", "_ingestao"], errors="ignore"))
    por_ctr = mm.groupby(["FILIAL", "CONTRATO"]).agg(
        MEDICOES=("MEDICAO", "size"), MEDIDO_JANELA=("VALOR_MEDIDO", "sum"), PAGO_NA_JANELA=("PAGO_NA_JANELA", "sum"),
        SALDO_TITULOS_ABERTO=("SALDO_ABERTO", "sum"),
        MEDIDO_SEM_TITULO=("VALOR_MEDIDO", lambda x: x[mm.loc[x.index, "TITULOS"] == 0].sum())).reset_index()
    cont = cont.merge(por_ctr, on=["FILIAL", "CONTRATO"], how="left").sort_values("MEDIDO_JANELA", ascending=False)

    resumo = (mm.groupby("SITUACAO").agg(MEDICOES=("MEDICAO", "size"), VALOR_MEDIDO=("VALOR_MEDIDO", "sum"),
                                         PAGO_NA_JANELA=("PAGO_NA_JANELA", "sum"), SALDO_ABERTO=("SALDO_ABERTO", "sum"))
                .reset_index())
    resumo.loc[len(resumo)] = ["TOTAL", resumo["MEDICOES"].sum(), resumo["VALOR_MEDIDO"].sum(),
                               resumo["PAGO_NA_JANELA"].sum(), resumo["SALDO_ABERTO"].sum()]
    info = pd.DataFrame([
        ("Janela (data de entrega da medicao)", f"{ini:%d/%m/%Y} a {hoje:%d/%m/%Y}"),
        ("Filtro aterro", a.filtro),
        ("Medicoes de compra na janela (todas)", med[["FILIAL", "CONTRATO", "MEDICAO"]].drop_duplicates().shape[0]),
        ("Valor medido na janela (todas)", med["VL_TOTAL"].sum()),
        ("Medicoes de aterro", len(mm)),
        ("Valor medido de aterro", mm["VALOR_MEDIDO"].sum()),
        ("API devolve E2_MDCONTR/E2_MEDNUME?", "sim" if tem_md else
         "NAO - recompile BIQFIN.PRW; titulos gerados sem pedido aparecem como 'Sem pedido e sem titulo'"),
    ], columns=["Indicador", "Valor"])
    por_crit = at.groupby("CRITERIO_ATERRO").agg(itens=("VL_TOTAL", "size"), valor=("VL_TOTAL", "sum")).reset_index()
    filiais = fil.assign(TEM_FILTRO=fil["NOME"].map(norm).str.contains(filtro, regex=False)) if len(fil) else fil

    itens_cols = ["FILIAL", "FILIAL_NOME", "CONTRATO", "REVISAO", "MEDICAO", "ITEM", "PRODUTO", "PROD_DESC", "QUANT",
                  "VL_UNIT", "VL_TOTAL", "DT_ENTREGA", "DT_ENCERR", "PEDIDO", "CC", "CC_DESC", "PROJETO", "PROJ_DESC",
                  "FORN_NOME", "TIPO_CONTRATO", "CRITERIO_ATERRO"]
    with pd.ExcelWriter(a.saida, engine="openpyxl") as xw:
        info.to_excel(xw, sheet_name="Resumo", index=False)
        resumo.to_excel(xw, sheet_name="Resumo", index=False, startrow=len(info) + 2)
        por_crit.to_excel(xw, sheet_name="Resumo", index=False, startrow=len(info) + len(resumo) + 5)
        mm.to_excel(xw, sheet_name="Medicoes aterro", index=False)
        cont.to_excel(xw, sheet_name="Contratos aterro", index=False)
        vinc.to_excel(xw, sheet_name="Titulos vinculados", index=False)
        at[[c for c in itens_cols if c in at.columns]].to_excel(xw, sheet_name="Itens aterro", index=False)
        filiais.drop(columns=["_endpoint", "_params", "_ingestao"], errors="ignore").to_excel(xw, sheet_name="Filiais", index=False)
        for ws in xw.book.worksheets:
            ws.freeze_panes = "A2"
            for col in ws.columns:
                ws.column_dimensions[col[0].column_letter].width = min(45, max(10, *(len(str(c.value or "")) for c in col[:200])) + 2)
                for c in col[1:]:
                    if isinstance(c.value, float):
                        c.number_format = "#,##0.00"

    print(info.to_string(index=False))
    print()
    print(resumo.to_string(index=False))
    print(f"\nPlanilha: {os.path.abspath(a.saida)}")


if __name__ == "__main__":
    main()
