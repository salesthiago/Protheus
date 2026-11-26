"""Classificacao das naturezas para a DRE e regras de exclusao de financiamento (extraido de dre.py)."""
NAT_FIN = {"311103", "268002", "268006", "350001", "350002", "350003", "351001", "352001", "353001", "353003",
           "268003", "111006"}
RE_FIN = r"EMPREST|FINANCIAMENT|CAPITAL DE GIRO|CONSORCIO|LEASING|FINAME|\bFCO\b|MUTUO|BNDES|LIMITE DE CREDITO|OPERACOES FINANCEIRAS|ABERTURA CREDITO"
RE_BANCO = (r"\bBANCO\b|\bBANK\b|FINANCIAMENTOS|LEASING|CAIXA ECONOMICA|SANTANDER|ITAU|BRADESCO S|BNDES|SICOOB|SICREDI|"
            r"ADMINISTRADORA DE CONSORCIOS|CREDITO|DAYCOVAL|SOFISA")
NAT_BEM = {"342001", "342002", "341002", "341003"}       # veiculos, caminhoes, equipamentos, maquinas

G = {  # grupo -> linhas da DRE
    "DED": "Impostos sobre o faturamento",
    "TER": "Serviços terceirizados", "LOC": "Locação de máquinas, veículos e equipamentos",
    "COMB": "Combustíveis e lubrificantes", "MAN": "Manutenção de frota e equipamentos",
    "MAT": "Materiais e insumos operacionais", "RES": "Tratamento e destinação de resíduos",
    "RET": "Retenções de terceiros recolhidas",
    "SAL": "Salários, férias, 13º e rescisões", "ENC": "Encargos sociais", "BEN": "Benefícios",
    "SST": "Saúde e segurança do trabalho",
    "ADM": "Administrativas gerais", "JUR": "Jurídico, processos e acordos",
    "ALU": "Aluguéis, condomínio e utilidades", "TI": "TI e sistemas", "TRIB": "Tributos, taxas e licenças",
    "SEG": "Seguros", "VIA": "Viagens e deslocamentos", "MKT": "Marketing, comissões e doações",
    "OUT": "Outras despesas",
    "JM": "Juros e multas por atraso", "TAR": "Tarifas bancárias", "DSC": "Descontos obtidos",
    "IR": "IRPJ e CSLL",
    "CAPEX": "Investimentos (bens comprados sem financiamento)", "PARC": "Parcelamento de tributos",
    "MOV": "Adiantamentos, aportes e outras movimentações",
}
COD = {}
def m(grp, *cods):
    for c in cods:
        COD[c] = grp
m("DED", "210014", "210015", "210001")
m("TER", "310002", "311064", "311031", "311008", "311038", "311003", "311006", "311015", "311048", "311014", "311061",
  "311007", "311107", "311105", "311001", "311032", "311025", "260003", "311090", "311023", "311054", "311009",
  "310009", "242001", "311056", "311104", "110003", "110006")
m("LOC", "310001", "311002", "311017", "311018", "311042", "311019", "311026", "311046", "311057", "311082", "311106",
  "311110", "311043", "311012", "290001", "311034", "311111", "311010", "310011", "311033", "311091")
m("COMB", "311096", "311095", "290002", "311094", "311037")
m("MAN", "290003", "290004", "280001", "290011", "290014", "290012", "290015", "311100", "311108", "311022", "311053",
  "311097", "290010", "311092")
m("MAT", "230003", "230001", "310007", "311060", "344003", "310003", "231001", "231004", "230002", "230004", "410032",
  "410079", "112009")
m("RES", "311070", "311035", "311059", "311011", "311049", "311045", "411113")
m("RET", "210004", "210005", "210006", "210007", "210008", "210010", "410060", "240004", "PIS", "")
m("SAL", "260001", "262001", "263001", "264001", "260005", "267001", "261002", "260002", "410039", "260006", "260008",
  "410063")
m("ENC", "269001", "269002", "264002", "269003", "269005", "269006", "269007", "311051")
m("BEN", "261003", "261006", "261004", "261011", "261012", "261007", "261013", "261017", "311030", "311029", "311028",
  "311081", "311020", "311024", "410071", "410045", "260007", "261001", "302002")
m("SST", "265003", "265002", "266001", "265005", "311021", "410062", "311101", "311083", "411104")
m("JUR", "311044", "272003", "311013", "271009", "271008", "210013", "271005", "311050", "410058", "210018")
m("ALU", "240003", "240005", "240001", "240002", "311016", "311040", "311077", "250001", "250002", "330001", "330002",
  "311004", "330003", "280002", "280003", "280004", "281001", "311068", "410034", "311069", "311084", "311079")
m("TI", "341004", "263003", "272004", "311071", "311072", "410057", "311005", "311075", "311073", "311052")
m("TRIB", "241003", "344002", "290008", "410069", "241001", "241002", "241004", "311102", "311085", "411114", "271011",
  "271001", "290009", "410067", "290007", "211003")
m("SEG", "290005", "290016", "242002", "310005", "261011")
m("VIA", "410048", "301001", "300001", "300002", "301003", "302001", "301005", "310006", "410047", "271003", "290013")
m("MKT", "410054", "410100", "321003", "321002", "311027", "410099", "321004", "410061", "311041", "320001", "410092")
m("TAR", "360003", "360005", "360006")
m("IR", "210016", "210017")
m("CAPEX", "341002", "342001", "342002", "341003", "340002", "343001", "410053", "341001", "343002", "410070", "344001")
m("PARC", "351002")
m("MOV", "271013", "380001", "380002", "411111", "112006", "112002", "311093", "271010")
m("ADM", "271006", "271007", "271012", "420000", "420001", "420002", "410033", "271014", "270001", "270002", "270003",
  "271002", "311047", "311109", "311074", "272002", "410035", "410093", "273002", "311076", "311080", "410052",
  "280005", "311086")
PREFIXO = {"29": "MAN", "31": "TER", "27": "ADM", "28": "ALU", "26": "SAL", "41": "ADM", "42": "ADM", "23": "MAT",
           "24": "TRIB", "21": "RET", "30": "VIA", "33": "ALU", "34": "CAPEX", "36": "TAR", "38": "MOV", "11": "MOV"}


def grupo(cod, desc):
    if cod in COD:
        return G[COD[cod]]
    return G[PREFIXO.get(cod[:2], "OUT")]



BLOCO = {"DED": "Deduções", "TER": "Custo dos serviços", "LOC": "Custo dos serviços", "COMB": "Custo dos serviços",
         "MAN": "Custo dos serviços", "MAT": "Custo dos serviços", "RES": "Custo dos serviços", "RET": "Custo dos serviços",
         "SAL": "Pessoal", "ENC": "Pessoal", "BEN": "Pessoal", "SST": "Pessoal",
         "ADM": "Gerais e administrativas", "JUR": "Gerais e administrativas", "ALU": "Gerais e administrativas",
         "TI": "Gerais e administrativas", "TRIB": "Gerais e administrativas", "SEG": "Gerais e administrativas",
         "VIA": "Gerais e administrativas", "MKT": "Gerais e administrativas", "OUT": "Gerais e administrativas",
         "JM": "Resultado financeiro", "TAR": "Resultado financeiro", "DSC": "Resultado financeiro", "IR": "IRPJ e CSLL",
         "CAPEX": "Fora do resultado", "PARC": "Fora do resultado", "MOV": "Fora do resultado"}
