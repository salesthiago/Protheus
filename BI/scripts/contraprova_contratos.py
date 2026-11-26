"""Contraprova do dashboard de Contratos: baixa medicoes e contratos da API BI e gera uma planilha.

Uso:
    export PROTHEUS_USER=...; export PROTHEUS_PASS='...'     (ou digite quando pedir)
    python contraprova_contratos.py [--dias 30] [--desde 20250101] [--saida arquivo.xlsx]

Abas:
  Resumo            totais da janela (padrao: ultimos 30 dias pela data de entrega CNE_DTENT)
  Por medicao       uma linha por medicao da janela, maiores primeiro
  Por contrato      medido na janela x valor atual/saldo do contrato
  Sem CC - medicoes medicoes (todo o historico baixado) com item sem centro de custo (CNE_CC vazio)
  Sem CC - itens    itens sem centro de custo, detalhe
  Itens janela      todos os itens medidos na janela (base dos totais)
"""
import argparse
import getpass
import os
import sys
from datetime import date, timedelta

import pandas as pd
import requests

BASE_URL = "http://177.136.201.210:8086/rest/APIBI"


def get_all(s, path, params=None, page_size=5000):
    params, itens, page = dict(params or {}), [], 1
    while True:
        params.update({"page": page, "pageSize": page_size})
        r = s.get(f"{BASE_URL}{path}", params=params, timeout=600)
        if not r.ok:
            sys.exit(f"GET {path} -> {r.status_code}: {r.text[:300]}")
        j = r.json()
        itens.extend(j.get("items", []))
        print(f"  {path} pagina {page}: {len(itens)} linhas")
        if not j.get("hasNext"):
            return pd.DataFrame(itens)
        page += 1


def vazio(serie):
    return serie.isna() | (serie.astype(str).str.strip() == "")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dias", type=int, default=30)
    ap.add_argument("--desde", default="20250101", help="inicio do historico baixado (AAAAMMDD)")
    ap.add_argument("--saida", default=f"contraprova_contratos_{date.today():%Y%m%d}.xlsx")
    a = ap.parse_args()

    s = requests.Session()
    s.auth = (os.environ.get("PROTHEUS_USER") or input("Usuario API: "),
              os.environ.get("PROTHEUS_PASS") or getpass.getpass("Senha API: "))
    s.headers["Accept"] = "application/json"

    print("Baixando...")
    med = get_all(s, "/bi/contratos/medicoes", {"desde": a.desde})
    ctr = get_all(s, "/bi/contratos/contratos")

    med["VL_TOTAL"] = pd.to_numeric(med["VL_TOTAL"], errors="coerce").fillna(0)
    med["DT"] = pd.to_datetime(med["DT_ENTREGA"], format="%Y%m%d", errors="coerce")
    med["ENCERRADA"] = ~vazio(med["DT_ENCERR"])
    med["COM_PEDIDO"] = ~vazio(med["PEDIDO"])
    med["SEM_CC"] = vazio(med["CC"])
    for c in ("FILIAL", "CONTRATO", "REVISAO", "MEDICAO"):
        med[c] = med[c].astype(str).str.strip()

    # contrato: revisao atual (maior revisao que nao esta em revisao 09 nem revisada 10)
    for c in ("VL_INICIAL", "VL_ATUAL", "SALDO"):
        ctr[c] = pd.to_numeric(ctr[c], errors="coerce")
    ctr["_ord"] = ctr["SITUACAO"].isin(["09", "10"]).astype(int)
    atual = (ctr.sort_values(["FILIAL", "CONTRATO", "_ord", "REVISAO"], ascending=[True, True, True, False])
                .drop_duplicates(["FILIAL", "CONTRATO"])
                [["FILIAL", "CONTRATO", "REVISAO", "SITUACAO", "TIPO_DESC", "FORN_NOME",
                  "DT_INICIO", "DT_FIM", "VL_INICIAL", "VL_ATUAL", "SALDO"]]
                .rename(columns={"REVISAO": "REV_ATUAL", "FORN_NOME": "FORN_CONTRATO"}))

    hoje = pd.Timestamp(date.today())
    ini = hoje - timedelta(days=a.dias)
    jan = med[(med["DT"] >= ini) & (med["DT"] <= hoje)].copy()

    def soma(m):
        return jan.loc[m, "VL_TOTAL"].sum()
    resumo = pd.DataFrame([
        ("Janela (data de entrega)", f"{ini:%d/%m/%Y} a {hoje:%d/%m/%Y}"),
        ("Itens medidos", len(jan)),
        ("Medicoes distintas", jan[["FILIAL", "CONTRATO", "MEDICAO"]].drop_duplicates().shape[0]),
        ("Contratos distintos", jan[["FILIAL", "CONTRATO"]].drop_duplicates().shape[0]),
        ("Valor medido (tile 'Medido no periodo')", soma(jan.index == jan.index)),
        ("  - encerradas", soma(jan["ENCERRADA"])),
        ("  - com pedido gerado", soma(jan["COM_PEDIDO"])),
        ("  - sem pedido", soma(~jan["COM_PEDIDO"])),
        ("  - itens sem centro de custo", soma(jan["SEM_CC"])),
        ("Itens duplicados (mesma filial/contrato/revisao/medicao/item)",
         int(jan.duplicated(["FILIAL", "CONTRATO", "REVISAO", "MEDICAO", "ITEM"]).sum())),
    ], columns=["Indicador", "Valor"])
    por_fil = jan.groupby("FILIAL").agg(itens=("VL_TOTAL", "size"), valor=("VL_TOTAL", "sum")).reset_index()

    chave = ["FILIAL", "CONTRATO", "REVISAO", "MEDICAO"]
    def agrupa_med(df):
        return (df.groupby(chave, dropna=False)
                  .agg(DT_ENTREGA=("DT", "min"), DT_ENCERR=("DT_ENCERR", "max"), PEDIDO=("PEDIDO", "max"),
                       FORNECEDOR=("FORN_NOME", "max"), CC=("CC_DESC", lambda x: ", ".join(sorted(set(x.dropna()) - {""}))),
                       ITENS=("VL_TOTAL", "size"), ITENS_SEM_CC=("SEM_CC", "sum"),
                       VALOR=("VL_TOTAL", "sum"), VALOR_SEM_CC=("VL_TOTAL", lambda x: x[df.loc[x.index, "SEM_CC"]].sum()))
                  .reset_index().sort_values("VALOR", ascending=False))
    por_med = agrupa_med(jan)

    por_ctr = (jan.groupby(["FILIAL", "CONTRATO"]).agg(medicoes=("MEDICAO", "nunique"), medido_janela=("VL_TOTAL", "sum"))
                  .reset_index().merge(atual, on=["FILIAL", "CONTRATO"], how="left")
                  .sort_values("medido_janela", ascending=False))

    sem_cc_itens = med[med["SEM_CC"]].sort_values(["DT", "FILIAL", "CONTRATO", "MEDICAO", "ITEM"], ascending=[False, True, True, True, True])
    sem_cc_med = agrupa_med(med[med.set_index(chave).index.isin(sem_cc_itens.set_index(chave).index)])
    sem_cc_med = sem_cc_med.merge(atual[["FILIAL", "CONTRATO", "SITUACAO", "TIPO_DESC"]], on=["FILIAL", "CONTRATO"], how="left")

    cols_item = ["FILIAL", "CONTRATO", "REVISAO", "MEDICAO", "ITEM", "PRODUTO", "PROD_DESC", "QUANT", "VL_UNIT", "VL_TOTAL",
                 "DT_ENTREGA", "COMPET", "DT_ENCERR", "PEDIDO", "CC", "CC_DESC", "FORNECEDOR", "FORN_NOME", "PROJETO", "PROJ_DESC"]
    with pd.ExcelWriter(a.saida, engine="openpyxl") as xw:
        resumo.to_excel(xw, sheet_name="Resumo", index=False)
        por_fil.to_excel(xw, sheet_name="Resumo", index=False, startrow=len(resumo) + 2)
        por_med.to_excel(xw, sheet_name="Por medicao", index=False)
        por_ctr.to_excel(xw, sheet_name="Por contrato", index=False)
        sem_cc_med.to_excel(xw, sheet_name="Sem CC - medicoes", index=False)
        sem_cc_itens[cols_item].to_excel(xw, sheet_name="Sem CC - itens", index=False)
        jan[cols_item].to_excel(xw, sheet_name="Itens janela", index=False)
        for ws in xw.book.worksheets:
            ws.freeze_panes = "A2"
            for col in ws.columns:
                ws.column_dimensions[col[0].column_letter].width = min(45, max(10, *(len(str(c.value or "")) for c in col[:200])) + 2)
                for c in col[1:]:
                    if isinstance(c.value, float):
                        c.number_format = "#,##0.00"

    print(resumo.to_string(index=False))
    print(f"\nMedicoes com item sem CC (historico desde {a.desde}): {len(sem_cc_med)} | "
          f"valor sem CC: {sem_cc_itens['VL_TOTAL'].sum():,.2f}")
    print(f"Planilha: {os.path.abspath(a.saida)}")


if __name__ == "__main__":
    main()
