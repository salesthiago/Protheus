"""DRE de custos 2026 (regime de caixa) - so titulos com pedido de contrato e/ou OS, sem financiamentos.
Uso: python dre_custos.py <pagamentos.json|.csv> <saida.xlsx> <pasta_amostra_frota> [data_base AAAA-MM-DD]
  pagamentos: JSON de /bi/financeiro/pagamentos (escopo padrao CONTRATO_OS) ou CSV da query
              BI/sql/pagamentos_custos_contrato_os_2026.sql"""
import json
import os
import sys
from datetime import date

import pandas as pd
from openpyxl import Workbook
from openpyxl.comments import Comment
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.datavalidation import DataValidation

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mapa_dre as MD  # noqa: E402

SRC, OUT, FROTA = sys.argv[1], sys.argv[2], sys.argv[3]
DATA_BASE = date.fromisoformat(sys.argv[4]) if len(sys.argv) > 4 else date.today()
ANO = "2026"

COLS = ["REC", "FILIAL", "PREFIXO", "NUM", "PARCELA", "TIPO", "FORNECE", "LOJA", "FORNECEDOR", "NATUREZA", "NATUREZA_DESC",
        "EMISSAO", "VENCREA", "PAGO_EM", "PAGO", "JUROS", "MULTA", "DESCONTO", "TIPODOC", "MOTBX", "PEDIDO", "CONTRATO",
        "OS", "VINCULO"]

# ------------------------------------------------------------------ leitura
if SRC.lower().endswith(".csv"):
    pag = pd.read_csv(SRC, sep=None, engine="python", dtype=str, keep_default_na=False, encoding_errors="replace")
    if "VINCULO" not in pag.columns:                       # CSV salvo sem cabecalho
        pag = pd.read_csv(SRC, sep=None, engine="python", dtype=str, keep_default_na=False, header=None,
                          names=COLS, encoding_errors="replace")
    for c in ("PAGO", "JUROS", "MULTA", "DESCONTO"):
        pag[c] = pd.to_numeric(pag[c].str.replace(",", ".", regex=False), errors="coerce").fillna(0.0)
    pag = pag.replace({"NULL": ""})
else:
    d = json.load(open(SRC))
    pag = pd.DataFrame(d.get("items", d) if isinstance(d, dict) else d)
if "VINCULO" not in pag.columns:
    sys.exit("ERRO: os pagamentos nao trazem VINCULO (contrato/OS). Use a API recompilada ou o CSV da query.")
for c in ("PEDIDO", "CONTRATO", "OS", "VINCULO", "NATUREZA", "NATUREZA_DESC", "FORNECEDOR", "MOTBX", "TIPODOC", "TIPO"):
    pag[c] = pag[c].fillna("").astype(str).str.replace('"', "").str.strip()
for c in ("JUROS", "MULTA", "DESCONTO"):
    pag[c] = pag[c].fillna(0.0)
log = {"lidos": (len(pag), pag.PAGO.sum())}

# ------------------------------------------------------------------ filtros (todos obrigatorios)
pag = pag[pag.PAGO_EM.astype(str).str[:4] == ANO]                                   # so 2026
log["2026"] = (len(pag), pag.PAGO.sum())
pag = pag[(pag.PEDIDO != "") & pag.VINCULO.isin(["CONTRATO", "OS", "CONTRATO+OS"])]  # pedido de contrato e/ou OS
log["contrato/OS"] = (len(pag), pag.PAGO.sum())
nao_caixa = pag.MOTBX.isin(["LIQ", "FAT", "CMP"]) | (pag.TIPODOC == "CP")
pag = pag[~nao_caixa]
log["caixa"] = (len(pag), pag.PAGO.sum())
up = pag.NATUREZA_DESC.str.upper()
eh_fin = (pag.NATUREZA.isin(MD.NAT_FIN) | up.str.contains(MD.RE_FIN, regex=True)
          | (pag.NATUREZA.isin(MD.NAT_BEM) & pag.FORNECEDOR.str.upper().str.contains(MD.RE_BANCO, regex=True)))
pag = pag[~eh_fin].copy()
log["sem financiamento"] = (len(pag), pag.PAGO.sum())
for k, (n, v) in log.items():
    print(f"{k:18} {n:>8} linhas  R$ {v:,.2f}")
if pag.empty:
    sys.exit("ERRO: nenhum pagamento de 2026 depois dos filtros.")

pag["MESN"] = pag.PAGO_EM.astype(str).str[4:6].astype(int).astype(object)
pag["JM"] = pag.JUROS + pag.MULTA
pag = pag.sort_values(["PAGO_EM", "FILIAL", "NUM"]).reset_index(drop=True)
meses = sorted(int(m) for m in pag.MESN.unique())
mes_atual = DATA_BASE.month if str(DATA_BASE.year) == ANO else 99

# ------------------------------------------------------------------ estilos
F = "Arial"
AZUL = "1F3864"
FONT, BOLD = Font(name=F, size=10), Font(name=F, size=10, bold=True)
HEAD = Font(name=F, size=10, bold=True, color="FFFFFF")
TITLE = Font(name=F, size=14, bold=True, color=AZUL)
SUB = Font(name=F, size=10, italic=True, color="595959")
INP = Font(name=F, size=10, color="0000FF")
HFILL, SFILL = PatternFill("solid", fgColor=AZUL), PatternFill("solid", fgColor="D9E2F3")
TFILL, GFILL = PatternFill("solid", fgColor="BDD7EE"), PatternFill("solid", fgColor="F2F2F2")
YFILL = PatternFill("solid", fgColor="FFFF00")
THIN = Side(style="thin", color="BFBFBF")
BOX = Border(top=THIN, bottom=THIN, left=THIN, right=THIN)
BRL = '"R$" #,##0;-"R$" #,##0;"-"'
BRL2 = '"R$" #,##0.00;-"R$" #,##0.00;"-"'
PCT, INT, DT = '0.0%;-0.0%;"-"', '#,##0;-#,##0;"-"', "dd/mm/yyyy"
NOMES_MES = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"]

wb = Workbook()
wb.remove(wb.active)


def sheet(nome, titulo, sub=None):
    ws = wb.create_sheet(nome)
    ws.sheet_view.showGridLines = False
    ws["A1"], ws["A1"].font = titulo, TITLE
    if sub:
        ws["A2"], ws["A2"].font = sub, SUB
    return ws


def put(ws, r, c, v, fmt=None, font=FONT, fill=None, border=True):
    x = ws.cell(row=r, column=c, value=v)
    x.font = font
    if fmt:
        x.number_format = fmt
    if fill:
        x.fill = fill
    if border:
        x.border = BOX
    return x


def header(ws, r, c, titles):
    for i, t in enumerate(titles):
        x = put(ws, r, c + i, t, font=HEAD, fill=HFILL)
        x.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    ws.row_dimensions[r].height = 30


def widths(ws, ws_w):
    for i, w in enumerate(ws_w, start=1):
        ws.column_dimensions[get_column_letter(i)].width = w


def mlabel(m):
    return f"{NOMES_MES[m - 1]}/{ANO}" + (" (parcial)" if m == mes_atual else "")


# ------------------------------------------------------------------ NATUREZAS (classificacao editavel)
nat = (pag.groupby("NATUREZA").agg(DESC=("NATUREZA_DESC", "first")).reset_index().sort_values("NATUREZA"))
nat["GRUPO"] = [MD.grupo(c, d) for c, d in zip(nat.NATUREZA, nat.DESC)]
wsN = sheet("Naturezas", "Classificação das naturezas na DRE",
            "Coluna amarela editável: escolha outro grupo na lista e a DRE recalcula.")
header(wsN, 4, 1, ["Natureza", "Descrição", "Grupo DRE", "Custo 2026", "Pagamentos"])
n1, nN = 5, 5 + len(nat) - 1
# base: colunas fixas (definidas abaixo) - custo em R, natureza em H, mes em A
BASE_N = len(pag)
b1, bN = 5, 5 + BASE_N - 1
B = lambda col: f"Base_Pagamentos!${col}${b1}:${col}${bN}"
for i, x in enumerate(nat.itertuples(index=False)):
    r = n1 + i
    put(wsN, r, 1, x.NATUREZA, "@")
    put(wsN, r, 2, x.DESC or "(sem descrição)")
    put(wsN, r, 3, x.GRUPO, font=INP, fill=YFILL)
    put(wsN, r, 4, f"=SUMIFS({B('R')},{B('H')},$A{r})", BRL2)
    put(wsN, r, 5, f"=COUNTIFS({B('H')},$A{r})", INT)
put(wsN, nN + 1, 1, "Total", font=BOLD, fill=SFILL)
put(wsN, nN + 1, 2, None, fill=SFILL)
put(wsN, nN + 1, 3, None, fill=SFILL)
put(wsN, nN + 1, 4, f"=SUM(D{n1}:D{nN})", BRL2, BOLD, SFILL)
put(wsN, nN + 1, 5, f"=SUM(E{n1}:E{nN})", INT, BOLD, SFILL)
widths(wsN, [10, 46, 44, 18, 12])
wsN.freeze_panes = "A5"

# ------------------------------------------------------------------ GRUPOS
GRUPOS_CUSTO = ["TER", "LOC", "COMB", "MAN", "MAT", "RES", "RET", "SAL", "ENC", "BEN", "SST", "ADM", "JUR", "ALU", "TI",
                "TRIB", "SEG", "VIA", "MKT", "OUT", "DED", "TAR", "IR", "CAPEX", "PARC", "MOV"]
wsG = sheet("Grupos", "Grupos da DRE de custos", "Lista usada na coluna 'Grupo DRE' da aba Naturezas.")
AREAS = ["Financeiro", "Compras", "Frota", "Estoque", "Pessoas"]
FORA = "Fora do custo"
AREA = {"TER": "Compras", "LOC": "Frota", "COMB": "Frota", "MAN": "Frota", "MAT": "Estoque", "RES": "Compras",
        "RET": "Financeiro", "SAL": "Pessoas", "ENC": "Pessoas", "BEN": "Pessoas", "SST": "Pessoas", "ADM": "Compras",
        "JUR": "Compras", "ALU": "Compras", "TI": "Compras", "TRIB": "Financeiro", "SEG": "Financeiro", "VIA": "Compras",
        "MKT": "Compras", "OUT": "Compras", "DED": "Financeiro", "TAR": "Financeiro", "IR": "Financeiro",
        "CAPEX": FORA, "PARC": FORA, "MOV": FORA}
header(wsG, 3, 1, ["Grupo DRE", "Bloco", "Área"])
for i, k in enumerate(GRUPOS_CUSTO):
    put(wsG, 4 + i, 1, MD.G[k])
    put(wsG, 4 + i, 2, MD.BLOCO[k])
    put(wsG, 4 + i, 3, AREA[k], font=INP, fill=YFILL)
gN = 4 + len(GRUPOS_CUSTO) - 1
put(wsG, 3, 5, "Pagamentos de pedido com OS vão para Frota? (S/N)", font=BOLD)
put(wsG, 3, 6, "S", font=INP, fill=YFILL)
wsG["F3"].comment = Comment("S: todo pagamento de pedido ligado a OS conta como custo de Frota, qualquer que seja a natureza. "
                            "N: a área vem só do grupo da natureza.", "DRE")
put(wsG, 5, 5, "Áreas válidas", font=BOLD)
for i, a in enumerate(AREAS + [FORA]):
    put(wsG, 6 + i, 5, a)
dva = DataValidation(type="list", formula1=f"=Grupos!$E$6:$E${6 + len(AREAS)}", allow_blank=False)
wsG.add_data_validation(dva)
dva.add(f"C4:C{gN}")
dvo = DataValidation(type="list", formula1='"S,N"', allow_blank=False)
wsG.add_data_validation(dvo)
dvo.add("F3")
widths(wsG, [48, 26, 16, 3, 50, 6])
dv = DataValidation(type="list", formula1=f"=Grupos!$A$4:$A${gN}", allow_blank=False,
                    error="Escolha um grupo da aba Grupos.", errorTitle="Grupo inválido")
wsN.add_data_validation(dv)
dv.add(f"C{n1}:C{nN}")

# ------------------------------------------------------------------ BASE_PAGAMENTOS (detalhe)
wsB = sheet("Base_Pagamentos", f"Pagamentos {ANO} - títulos com pedido de contrato e/ou OS",
            "Uma linha por pagamento. Custo = pago - juros - multa + desconto. Grupo vem da aba Naturezas; área, da aba Grupos.")
cols = [("Mês", INT, 6), ("Pago em", DT, 11), ("Filial", "@", 7), ("Prefixo", "@", 8), ("Número", "@", 12),
        ("Parcela", "@", 7), ("Fornecedor", None, 38), ("Natureza", "@", 9), ("Descrição natureza", None, 34),
        ("Grupo DRE", None, 36), ("Vínculo", None, 13), ("Pedido", "@", 9), ("Contrato", "@", 16), ("OS", "@", 8),
        ("Valor pago", BRL2, 15), ("Juros + multa", BRL2, 12), ("Desconto", BRL2, 11), ("Custo", BRL2, 15),
        ("Área", None, 13)]
header(wsB, 4, 1, [c[0] for c in cols])
NAT_RNG = f"Naturezas!$A${n1}:$A${nN}"
GRP_RNG = f"Naturezas!$C${n1}:$C${nN}"
for i, x in enumerate(pag.itertuples(index=False)):
    r = b1 + i
    pe = str(x.PAGO_EM)
    vals = [int(x.MESN), date(int(pe[:4]), int(pe[4:6]), int(pe[6:8])), x.FILIAL, x.PREFIXO, x.NUM, x.PARCELA, x.FORNECEDOR,
            x.NATUREZA, x.NATUREZA_DESC, f"=INDEX({GRP_RNG},MATCH(H{r},{NAT_RNG},0))", x.VINCULO, x.PEDIDO, x.CONTRATO,
            x.OS, round(float(x.PAGO), 2), round(float(x.JM), 2), round(float(x.DESCONTO), 2), f"=O{r}-P{r}+Q{r}",
            f'=IF(INDEX(Grupos!$C$4:$C${gN},MATCH(J{r},Grupos!$A$4:$A${gN},0))="{FORA}","{FORA}",'
            f'IF(AND(Grupos!$F$3="S",N{r}<>""),"Frota",INDEX(Grupos!$C$4:$C${gN},MATCH(J{r},Grupos!$A$4:$A${gN},0))))']
    for j, v in enumerate(vals):
        c = wsB.cell(row=r, column=j + 1, value=v)
        c.font = FONT
        if cols[j][1]:
            c.number_format = cols[j][1]
widths(wsB, [c[2] for c in cols])
wsB.freeze_panes = "A5"
wsB.auto_filter.ref = f"A4:S{bN}"

# ------------------------------------------------------------------ DRE_CUSTOS (mensal)
wsD = sheet("DRE_Custos", f"DRE de custos {ANO} - regime de caixa (R$)",
            "Somente títulos de notas com pedido de compra de contrato e/ou ordem de serviço. Sem financiamentos e empréstimos. "
            "Valores positivos = custo; descontos reduzem o custo.")
NM = len(meses)
cM = lambda j: get_column_letter(2 + j)
ctot, cpct = get_column_letter(2 + NM), get_column_letter(3 + NM)
header(wsD, 4, 1, ["Linha"] + [mlabel(m) for m in meses] + [f"Total {ANO}", "% do custo operacional"])
presentes = set(nat.GRUPO)
BLOCOS = [("Custo dos serviços prestados", ["TER", "LOC", "COMB", "MAN", "MAT", "RES", "RET"], "Total custo dos serviços"),
          ("Despesas com pessoal", ["SAL", "ENC", "BEN", "SST"], "Total despesas com pessoal"),
          ("Despesas gerais e administrativas", ["ADM", "JUR", "ALU", "TI", "TRIB", "SEG", "VIA", "MKT", "OUT", "DED", "IR"],
           "Total despesas gerais e administrativas")]
r = 5
row_tot, grp_rows = [], []
for titulo, ks, tot in BLOCOS:
    ks = [k for k in ks if MD.G[k] in presentes]
    if not ks:
        continue
    put(wsD, r, 1, titulo, font=BOLD, fill=GFILL)
    for j in range(NM + 2):
        put(wsD, r, 2 + j, None, fill=GFILL)
    r += 1
    first = r
    for k in ks:
        put(wsD, r, 1, "   " + MD.G[k])
        for j, m in enumerate(meses):
            put(wsD, r, 2 + j, f'=SUMIFS({B("R")},{B("J")},"{MD.G[k]}",{B("A")},{m})', BRL)
        put(wsD, r, 2 + NM, f"=SUM(B{r}:{cM(NM - 1)}{r})", BRL, BOLD)
        grp_rows.append(r)
        r += 1
    put(wsD, r, 1, tot, font=BOLD, fill=SFILL)
    for j in range(NM + 1):
        L = get_column_letter(2 + j)
        put(wsD, r, 2 + j, f"=SUM({L}{first}:{L}{r - 1})", BRL, BOLD, SFILL)
    row_tot.append(r)
    r += 1
r_op = r
put(wsD, r_op, 1, "(=) Custo operacional total", font=BOLD, fill=TFILL)
for j in range(NM + 1):
    L = get_column_letter(2 + j)
    put(wsD, r_op, 2 + j, "=" + "+".join(f"{L}{q}" for q in row_tot), BRL, BOLD, TFILL)
r += 2
put(wsD, r, 1, "Resultado financeiro dos pagamentos", font=BOLD, fill=GFILL)
for j in range(NM + 2):
    put(wsD, r, 2 + j, None, fill=GFILL)
r += 1
r_jm = r
put(wsD, r, 1, "   Juros e multas por atraso")
for j, m in enumerate(meses):
    put(wsD, r, 2 + j, f"=SUMIFS({B('P')},{B('A')},{m})", BRL)
r += 1
r_ds = r
put(wsD, r, 1, "   (-) Descontos obtidos")
for j, m in enumerate(meses):
    put(wsD, r, 2 + j, f"=-SUMIFS({B('Q')},{B('A')},{m})", BRL)
r += 1
r_tar = None
if MD.G["TAR"] in presentes:
    r_tar = r
    put(wsD, r, 1, "   " + MD.G["TAR"])
    for j, m in enumerate(meses):
        put(wsD, r, 2 + j, f'=SUMIFS({B("R")},{B("J")},"{MD.G["TAR"]}",{B("A")},{m})', BRL)
    grp_rows.append(r)
    r += 1
for q in [r_jm, r_ds] + ([r_tar] if r_tar else []):
    put(wsD, q, 2 + NM, f"=SUM(B{q}:{cM(NM - 1)}{q})", BRL, BOLD)
r_fin = r
put(wsD, r_fin, 1, "Total resultado financeiro", font=BOLD, fill=SFILL)
for j in range(NM + 1):
    L = get_column_letter(2 + j)
    put(wsD, r_fin, 2 + j, f"=SUM({L}{r_jm}:{L}{r_fin - 1})", BRL, BOLD, SFILL)
r += 1
r_ct = r
put(wsD, r_ct, 1, "(=) Custo total pago (contratos e OS)", font=BOLD, fill=TFILL)
for j in range(NM + 1):
    L = get_column_letter(2 + j)
    put(wsD, r_ct, 2 + j, f"={L}{r_op}+{L}{r_fin}", BRL, BOLD, TFILL)
r += 2
memo = [k for k in ["CAPEX", "PARC", "MOV"] if MD.G[k] in presentes]
if memo:
    put(wsD, r, 1, "Fora do custo (memória - saídas de caixa que não são custo do período)", font=BOLD, fill=GFILL)
    for j in range(NM + 2):
        put(wsD, r, 2 + j, None, fill=GFILL)
    r += 1
    for k in memo:
        put(wsD, r, 1, "   " + MD.G[k])
        for j, m in enumerate(meses):
            put(wsD, r, 2 + j, f'=SUMIFS({B("R")},{B("J")},"{MD.G[k]}",{B("A")},{m})', BRL)
        put(wsD, r, 2 + NM, f"=SUM(B{r}:{cM(NM - 1)}{r})", BRL, BOLD)
        grp_rows.append(r)
        r += 1
    r += 1
r_chk = r
put(wsD, r_chk, 1, "Conferência: custo da base fora da DRE (deve ser zero)", font=SUB)
for j, m in enumerate(meses):
    put(wsD, r_chk, 2 + j, f"=ROUND(SUMIFS({B('R')},{B('A')},{m})-(" + "+".join(f"{cM(j)}{q}" for q in grp_rows) + "),2)",
        BRL, SUB)
wsD[f"A{r_chk}"].comment = Comment("Diferente de zero = natureza com grupo fora da lista ou de um grupo sem linha na DRE.", "DRE")
for q in list(range(5, r_ct + 1)):
    v = wsD.cell(row=q, column=2 + NM).value
    if v is not None and q <= r_op:
        put(wsD, q, 3 + NM, f"=IFERROR({ctot}{q}/{ctot}${r_op},0)", PCT,
            BOLD if q in row_tot or q == r_op else FONT, (TFILL if q == r_op else SFILL) if q in row_tot + [r_op] else None)
if mes_atual in meses:
    put(wsD, r_chk + 2, 1, f"{mlabel(mes_atual)}: mês em andamento na data da extração ({DATA_BASE:%d/%m/%Y}).",
        font=SUB, border=False)
wsD.column_dimensions["A"].width = 60
for j in range(NM + 2):
    wsD.column_dimensions[get_column_letter(2 + j)].width = 14
wsD.freeze_panes = "B5"

# ------------------------------------------------------------------ CUSTOS_AREA
wsA = sheet("Custos_Area", f"Custo {ANO} por área - Financeiro, Compras, Frota, Estoque e Pessoas",
            "Área definida pelo grupo da natureza (aba Grupos). Pedidos com OS contam em Frota. "
            "Financeiro inclui juros e multas por atraso, menos os descontos obtidos.")
header(wsA, 4, 1, ["Área"] + [mlabel(m) for m in meses] + [f"Total {ANO}", "% do custo total"])
a1 = 5
for i, a in enumerate(AREAS):
    q = a1 + i
    put(wsA, q, 1, a, font=BOLD)
    for j, m in enumerate(meses):
        f = f'=SUMIFS({B("R")},{B("S")},$A{q},{B("A")},{m})'
        if a == "Financeiro":
            f += f"+SUMIFS({B('P')},{B('A')},{m})-SUMIFS({B('Q')},{B('A')},{m})"
        put(wsA, q, 2 + j, f, BRL)
    put(wsA, q, 2 + NM, f"=SUM(B{q}:{cM(NM - 1)}{q})", BRL, BOLD)
    put(wsA, q, 3 + NM, f"=IFERROR({ctot}{q}/{ctot}${a1 + len(AREAS)},0)", PCT, BOLD)
aT = a1 + len(AREAS)
put(wsA, aT, 1, "Total (= custo total pago)", font=BOLD, fill=TFILL)
for j in range(NM + 1):
    L = get_column_letter(2 + j)
    put(wsA, aT, 2 + j, f"=SUM({L}{a1}:{L}{aT - 1})", BRL, BOLD, TFILL)
put(wsA, aT, 3 + NM, f"=IFERROR({ctot}{aT}/{ctot}{aT},0)", PCT, BOLD, TFILL)
put(wsA, aT + 1, 1, "Conferência com a DRE_Custos (deve ser zero)", font=SUB)
for j in range(NM + 1):
    L = get_column_letter(2 + j)
    put(wsA, aT + 1, 2 + j, f"=ROUND({L}{aT}-DRE_Custos!{L}{r_ct},2)", BRL, SUB)

# detalhe: grupos dentro de cada area, abertos por vinculo
q = aT + 4
put(wsA, q - 1, 1, "Detalhe por área: grupos de custo e vínculo do pedido", font=Font(name=F, size=12, bold=True, color=AZUL),
    border=False)
header(wsA, q, 1, ["Área / grupo", "Contrato", "OS", "Contrato + OS", "Total", "% da área"])
q += 1
gmap = dict(zip(nat.NATUREZA, nat.GRUPO))
gk_area = {MD.G[k]: AREA[k] for k in GRUPOS_CUSTO}
pg = pag.assign(GR=pag.NATUREZA.map(gmap))
pg["AR"] = [FORA if gk_area[g] == FORA else ("Frota" if o else gk_area[g]) for g, o in zip(pg.GR, pg.OS)]
pg["C"] = pg.PAGO - pg.JM + pg.DESCONTO
area_tot_rows = []
VS = ["CONTRATO", "OS", "CONTRATO+OS"]
for a in AREAS:
    put(wsA, q, 1, a, font=BOLD, fill=SFILL)
    hdr = q
    q += 1
    first = q
    gl = pg[pg.AR == a].groupby("GR").C.sum().sort_values(ascending=False).index.tolist()
    for g in gl:
        put(wsA, q, 1, "   " + g)
        for j, v in enumerate(VS):
            put(wsA, q, 2 + j, f'=SUMIFS({B("R")},{B("S")},"{a}",{B("J")},"{g}",{B("K")},"{v}")', BRL)
        put(wsA, q, 5, f"=SUM(B{q}:D{q})", BRL, BOLD)
        put(wsA, q, 6, f"=IFERROR(E{q}/E${hdr},0)", PCT)
        q += 1
    if a == "Financeiro":
        put(wsA, q, 1, "   Juros e multas por atraso")
        for j, v in enumerate(VS):
            put(wsA, q, 2 + j, f'=SUMIFS({B("P")},{B("K")},"{v}")', BRL)
        put(wsA, q, 5, f"=SUM(B{q}:D{q})", BRL, BOLD)
        put(wsA, q, 6, f"=IFERROR(E{q}/E${hdr},0)", PCT)
        q += 1
        put(wsA, q, 1, "   (-) Descontos obtidos")
        for j, v in enumerate(VS):
            put(wsA, q, 2 + j, f'=-SUMIFS({B("Q")},{B("K")},"{v}")', BRL)
        put(wsA, q, 5, f"=SUM(B{q}:D{q})", BRL, BOLD)
        put(wsA, q, 6, f"=IFERROR(E{q}/E${hdr},0)", PCT)
        q += 1
    for c in range(2, 6):
        L = get_column_letter(c)
        put(wsA, hdr, c, f"=SUM({L}{first}:{L}{q - 1})" if q > first else 0, BRL, BOLD, SFILL)
    put(wsA, hdr, 6, f"=IFERROR(E{hdr}/{ctot}${aT},0)", PCT, BOLD, SFILL)
    area_tot_rows.append(hdr)
put(wsA, q, 1, "Total", font=BOLD, fill=TFILL)
for c in range(2, 6):
    L = get_column_letter(c)
    put(wsA, q, c, "=" + "+".join(f"{L}{h}" for h in area_tot_rows), BRL, BOLD, TFILL)
put(wsA, q, 6, None, fill=TFILL)
put(wsA, q + 1, 1, "Na coluna '% da área', a linha da área mostra a participação dela no custo total.", font=SUB, border=False)
put(wsA, q + 2, 1, "Grupo que não aparece numa área: altere a área do grupo na aba Grupos e gere de novo, "
    "ou use os filtros da Base_Pagamentos (coluna Área).", font=SUB, border=False)
wsA.column_dimensions["A"].width = 52
for j in range(NM + 2):
    wsA.column_dimensions[get_column_letter(2 + j)].width = 14
wsA.freeze_panes = "B5"

# ------------------------------------------------------------------ CUSTOS_VINCULO
wsV = sheet("Custos_Vinculo", f"Custo {ANO} por grupo e vínculo do pedido",
            "Contrato = pedido gerado por contrato; OS = pedido ligado a ordem de serviço da manutenção; Contrato + OS = os dois.")
VS = ["CONTRATO", "OS", "CONTRATO+OS"]
header(wsV, 4, 1, ["Grupo DRE", "Contrato", "OS", "Contrato + OS", "Total", "% do total"])
gr = [g for g in nat.GRUPO.unique()]
gr = sorted(gr, key=lambda g: -pag.assign(G=pag.NATUREZA.map(dict(zip(nat.NATUREZA, nat.GRUPO)))).query("G == @g").eval("PAGO - JM + DESCONTO").sum())
for i, g in enumerate(gr):
    q = 5 + i
    put(wsV, q, 1, g)
    for j, v in enumerate(VS):
        put(wsV, q, 2 + j, f'=SUMIFS({B("R")},{B("J")},$A{q},{B("K")},"{v}")', BRL)
    put(wsV, q, 5, f"=SUM(B{q}:D{q})", BRL, BOLD)
    put(wsV, q, 6, f"=IFERROR(E{q}/$E${5 + len(gr)},0)", PCT)
qt = 5 + len(gr)
put(wsV, qt, 1, "Total", font=BOLD, fill=SFILL)
for c in range(2, 6):
    L = get_column_letter(c)
    put(wsV, qt, c, f"=SUM({L}5:{L}{qt - 1})", BRL, BOLD, SFILL)
put(wsV, qt, 6, f"=IFERROR(E{qt}/E{qt},0)", PCT, BOLD, SFILL)
put(wsV, qt + 1, 1, "% por vínculo", font=BOLD)
for c in range(2, 5):
    L = get_column_letter(c)
    put(wsV, qt + 1, c, f"=IFERROR({L}{qt}/$E${qt},0)", PCT, BOLD)
widths(wsV, [46, 17, 17, 17, 17, 11])

# ------------------------------------------------------------------ CUSTOS_CONTRATOS
wsC = sheet("Custos_Contratos", f"Custo {ANO} por contrato", "Pagamentos de pedidos gerados por contrato (inclui contrato + OS).")
header(wsC, 4, 1, ["#", "Contrato", "Fornecedor principal", "Custo", "Juros + multa", "Pagamentos", "% do custo de contratos",
                   "% acumulado"])
pc = pag[pag.CONTRATO != ""]
ordem_c = pc.assign(C=pc.PAGO - pc.JM + pc.DESCONTO).groupby("CONTRATO").C.sum().sort_values(ascending=False)
forn_c = pc.groupby(["CONTRATO", "FORNECEDOR"]).PAGO.sum().reset_index().sort_values("PAGO", ascending=False) \
    .drop_duplicates("CONTRATO").set_index("CONTRATO").FORNECEDOR
c1 = 5
cN = c1 + max(len(ordem_c), 1) - 1
for i, ct in enumerate(ordem_c.index):
    q = c1 + i
    put(wsC, q, 1, i + 1, INT)
    put(wsC, q, 2, ct, "@")
    put(wsC, q, 3, forn_c.get(ct, ""))
    put(wsC, q, 4, f"=SUMIFS({B('R')},{B('M')},$B{q})", BRL)
    put(wsC, q, 5, f"=SUMIFS({B('P')},{B('M')},$B{q})", BRL)
    put(wsC, q, 6, f"=COUNTIFS({B('M')},$B{q})", INT)
    put(wsC, q, 7, f"=IFERROR(D{q}/$D${cN + 1},0)", PCT)
    put(wsC, q, 8, f"=G{q}" if i == 0 else f"=H{q - 1}+G{q}", PCT)
put(wsC, cN + 1, 1, "Total", font=BOLD, fill=SFILL)
put(wsC, cN + 1, 2, f'=COUNTA(B{c1}:B{cN})&" contratos"', font=BOLD, fill=SFILL)
put(wsC, cN + 1, 3, None, fill=SFILL)
for c, fmt in ((4, BRL), (5, BRL), (6, INT)):
    L = get_column_letter(c)
    put(wsC, cN + 1, c, f"=SUM({L}{c1}:{L}{cN})", fmt, BOLD, SFILL)
wsC.freeze_panes = "A5"
wsC.auto_filter.ref = f"A4:H{cN}"
widths(wsC, [6, 18, 44, 16, 13, 11, 13, 12])

# ------------------------------------------------------------------ CUSTOS_OS
wsO = sheet("Custos_OS", f"Custo {ANO} por ordem de serviço",
            "Pagamentos de pedidos ligados a OS da manutenção (inclui contrato + OS). Bem e serviço vêm do cadastro de OS.")


def ler(nome):
    p = os.path.join(FROTA, nome + ".json")
    if not os.path.exists(p):
        return pd.DataFrame()
    d = json.load(open(p))
    return pd.DataFrame(d.get("items", d) if isinstance(d, dict) else d)


ordens, bens = ler("bi_frota_ordens"), ler("bi_frota_bens")
os_info = ordens.drop_duplicates("OS").set_index("OS") if len(ordens) else pd.DataFrame()
bem_nome = bens.groupby("COD").NOME.max() if len(bens) and "COD" in bens.columns else pd.Series(dtype=str)
po = pag[pag.OS != ""]
ordem_o = po.assign(C=po.PAGO - po.JM + po.DESCONTO).groupby("OS").C.sum().sort_values(ascending=False)
header(wsO, 4, 1, ["#", "OS", "Bem", "Descrição do bem", "Serviço", "Custo", "Pagamentos", "% do custo de OS"])
o1 = 5
oN = o1 + max(len(ordem_o), 1) - 1
for i, o in enumerate(ordem_o.index):
    q = o1 + i
    inf = os_info.loc[o] if o in os_info.index else None
    bem = "" if inf is None else inf.BEM
    put(wsO, q, 1, i + 1, INT)
    put(wsO, q, 2, o, "@")
    put(wsO, q, 3, bem, "@")
    put(wsO, q, 4, bem_nome.get(bem, "") if bem else "")
    put(wsO, q, 5, "" if inf is None else inf.SERVD)
    put(wsO, q, 6, f"=SUMIFS({B('R')},{B('N')},$B{q})", BRL)
    put(wsO, q, 7, f"=COUNTIFS({B('N')},$B{q})", INT)
    put(wsO, q, 8, f"=IFERROR(F{q}/$F${oN + 1},0)", PCT)
put(wsO, oN + 1, 1, "Total", font=BOLD, fill=SFILL)
put(wsO, oN + 1, 2, f'=COUNTA(B{o1}:B{oN})&" OS"', font=BOLD, fill=SFILL)
for c in (3, 4, 5):
    put(wsO, oN + 1, c, None, fill=SFILL)
put(wsO, oN + 1, 6, f"=SUM(F{o1}:F{oN})", BRL, BOLD, SFILL)
put(wsO, oN + 1, 7, f"=SUM(G{o1}:G{oN})", INT, BOLD, SFILL)
wsO.freeze_panes = "A5"
wsO.auto_filter.ref = f"A4:H{oN}"
widths(wsO, [6, 9, 12, 38, 34, 16, 11, 12])

# ------------------------------------------------------------------ CUSTOS_FORNECEDORES
wsF = sheet("Custos_Fornecedores", f"Custo {ANO} por fornecedor (Pareto)",
            "Classe A = fornecedores que somam até 80% do custo; B até 95%; C o restante.")
ordem_f = pag.assign(C=pag.PAGO - pag.JM + pag.DESCONTO).groupby("FORNECEDOR").C.sum().sort_values(ascending=False)
ordem_f = ordem_f[ordem_f != 0]
header(wsF, 4, 1, ["#", "Fornecedor", "Custo", "Contrato", "OS", "Contrato + OS", "Pagamentos", "% do custo", "% acumulado",
                   "Classe"])
f1 = 5
fN = f1 + len(ordem_f) - 1
for i, fo in enumerate(ordem_f.index):
    q = f1 + i
    put(wsF, q, 1, i + 1, INT)
    put(wsF, q, 2, fo)
    put(wsF, q, 3, f"=SUMIFS({B('R')},{B('G')},$B{q})", BRL)
    for j, v in enumerate(VS):
        put(wsF, q, 4 + j, f'=SUMIFS({B("R")},{B("G")},$B{q},{B("K")},"{v}")', BRL)
    put(wsF, q, 7, f"=COUNTIFS({B('G')},$B{q})", INT)
    put(wsF, q, 8, f"=IFERROR(C{q}/$C${fN + 1},0)", PCT)
    put(wsF, q, 9, f"=H{q}" if i == 0 else f"=I{q - 1}+H{q}", PCT)
    put(wsF, q, 10, f'=IF(I{q}<=0.8,"A",IF(I{q}<=0.95,"B","C"))')
put(wsF, fN + 1, 1, "Total", font=BOLD, fill=SFILL)
put(wsF, fN + 1, 2, f'=COUNTA(B{f1}:B{fN})&" fornecedores"', font=BOLD, fill=SFILL)
for c in range(3, 8):
    L = get_column_letter(c)
    put(wsF, fN + 1, c, f"=SUM({L}{f1}:{L}{fN})", INT if c == 7 else BRL, BOLD, SFILL)
wsF.freeze_panes = "A5"
wsF.auto_filter.ref = f"A4:J{fN}"
widths(wsF, [6, 44, 16, 15, 15, 15, 11, 10, 11, 8])

# ------------------------------------------------------------------ RESUMO
wsR = sheet("Resumo", f"Custos {ANO} - contratos e ordens de serviço",
            f"Pagamentos de {ANO} de títulos com pedido de compra de contrato e/ou OS. Sem financiamentos e empréstimos. "
            f"Extração em {DATA_BASE:%d/%m/%Y}.")
header(wsR, 4, 1, ["Indicador", "Valor", "Como ler"])
ult_fechado = max([m for m in meses if m != mes_atual] or meses)
kpis = [
    (f"Custo total pago em {ANO}", f"=DRE_Custos!{ctot}{r_ct}", BRL, "Custo operacional + juros/multas - descontos."),
    ("Custo operacional", f"=DRE_Custos!{ctot}{r_op}", BRL, "Sem juros, multas e descontos."),
    ("Custo com contrato (só contrato)", f"=Custos_Vinculo!B{qt}", BRL, "Pedidos gerados por contrato."),
    ("Custo com OS (só OS)", f"=Custos_Vinculo!C{qt}", BRL, "Pedidos ligados a ordem de serviço."),
    ("Custo com contrato + OS", f"=Custos_Vinculo!D{qt}", BRL, "Pedidos com os dois vínculos."),
    ("Média mensal (meses fechados)",
     f"=AVERAGE(DRE_Custos!B{r_op}:DRE_Custos!{cM(meses.index(ult_fechado))}{r_op})", BRL,
     f"Custo operacional médio de jan a {NOMES_MES[ult_fechado - 1]}."),
    ("Juros e multas por atraso", f"=DRE_Custos!{ctot}{r_jm}", BRL, "Custo de pagar fora do prazo."),
] + [(f"Custo - {a}", f"=Custos_Area!{ctot}{a1 + i}", BRL,
      {"Financeiro": "Tributos, retenções, tarifas, seguros e juros/multas (menos descontos).",
       "Compras": "Serviços terceirizados, resíduos, administrativo, jurídico, TI, aluguéis.",
       "Frota": "Combustível, manutenção, locação de veículos/máquinas e tudo que veio de pedido com OS.",
       "Estoque": "Materiais e insumos operacionais.",
       "Pessoas": "Salários, encargos, benefícios, EPI, uniformes e exames."}[a]) for i, a in enumerate(AREAS)] + [
    ("Contratos com custo no ano", f'=COUNTIF(Custos_Contratos!D{c1}:D{cN},">0")', INT, "Veja Custos_Contratos."),
    ("OS com custo no ano", f'=COUNTIF(Custos_OS!F{o1}:F{oN},">0")', INT, "Veja Custos_OS."),
    ("Fornecedores na classe A (80% do custo)", f'=COUNTIF(Custos_Fornecedores!J{f1}:J{fN},"A")', INT,
     "Poucos fornecedores concentram a maior parte do custo."),
]
for i, (k, f, fmt, como) in enumerate(kpis):
    q = 5 + i
    put(wsR, q, 1, k, font=BOLD)
    put(wsR, q, 2, f, fmt, BOLD)
    put(wsR, q, 3, como, font=SUB)
widths(wsR, [44, 20, 60])

# ------------------------------------------------------------------ NOTAS
wsX = sheet("Notas", "Fontes, filtros e limitações")
notas = [
    ("Período", f"Somente pagamentos feitos em {ANO} (data da baixa). Regime de caixa; sem receita, depreciação ou provisões."),
    ("Filtro 1 - contrato/OS", "Só títulos de notas de entrada cujo pedido de compra tem contrato (C7_CONTRA) e/ou ordem de serviço da "
     "manutenção (C7_OP ou C1_OP = número da OS + 'OS001'). Títulos sem esse pedido não entram."),
    ("Filtro 2 - financiamento", "Sem financiamentos e empréstimos: capital de giro, empréstimos, FCO, consórcios, BNDES, mútuo, "
     "leasing, FINAME, juros/encargos de crédito e compras de veículos, caminhões, máquinas e equipamentos pagas a bancos e financeiras."),
    ("Filtro 3 - só caixa", "Sem baixas por liquidação (LIQ), fatura (FAT) e compensação (CP/CMP): nelas não sai dinheiro, "
     "o valor é pago em outro título ou já saiu no adiantamento."),
    ("Juros, multas e descontos", "O valor pago já inclui juros/multa e vem líquido do desconto. O custo é o valor original; "
     "juros, multas e descontos ficam no resultado financeiro."),
    ("Áreas", "Financeiro: tributos, retenções, tarifas, seguros, juros/multas (menos descontos). Compras: serviços terceirizados, "
     "resíduos, administrativo, jurídico, TI, aluguéis, viagens. Frota: combustível, manutenção, locação de veículos e máquinas, e todo "
     "pagamento de pedido ligado a OS. Estoque: materiais e insumos. Pessoas (RH): salários, encargos, benefícios e saúde/segurança. "
     "A área de cada grupo e a regra da OS são editáveis na aba Grupos."),
    ("Classificação", "Cada natureza está em um grupo da DRE (aba Naturezas, coluna amarela). Pode ser alterada; a linha de "
     "conferência da DRE_Custos deve ficar zero."),
    ("Fonte", os.path.basename(SRC)),
]
header(wsX, 3, 1, ["Tema", "Descrição"])
for i, (t, x) in enumerate(notas):
    put(wsX, 4 + i, 1, t, font=BOLD).alignment = Alignment(vertical="top")
    put(wsX, 4 + i, 2, x).alignment = Alignment(wrap_text=True, vertical="top")
widths(wsX, [26, 120])

wb._sheets = [wb[n] for n in ["Resumo", "DRE_Custos", "Custos_Area", "Custos_Vinculo", "Custos_Contratos", "Custos_OS", "Custos_Fornecedores",
                              "Naturezas", "Base_Pagamentos", "Grupos", "Notas"]]
wb["Resumo"].sheet_properties.tabColor = AZUL
wb["DRE_Custos"].sheet_properties.tabColor = AZUL
wb["Custos_Area"].sheet_properties.tabColor = AZUL
wb["Base_Pagamentos"].sheet_properties.tabColor = "A6A6A6"
wb.save(OUT)
print("ok", OUT, "| pagamentos:", len(pag), "| naturezas:", len(nat), "| meses:", meses)
