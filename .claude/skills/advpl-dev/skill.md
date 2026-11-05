---
name: advpl-dev
description: >
  Especialista em desenvolvimento ADVPL/TLPP para o ecossistema TOTVS Protheus.
  Use esta skill para auxiliar com: escrita e revisão de código ADVPL e TLPP,
  criação de pontos de entrada (convencional e MVC), desenvolvimento de APIs REST,
  consultas SQL/Embedded SQL, acesso a tabelas do Protheus, criação de classes OO,
  estrutura MVC (Model-View-Controller), reports com SetPrintServer/FWMSPrinter,
  tratamento de erros, boas práticas de nomenclatura, performance e debugging.
  Ativar sempre que o usuário mencionar: ADVPL, TLPP, Protheus, TDS, ponto de entrada,
  RecLock, MsUnlock, BeginTran, MVC Protheus, SX (SX3, SX5, SB1 etc.), customização ERP,
  User Function, rotina MATA/SIGACOM/SIGAFAT/SIGAEST, ou qualquer desenvolvimento para
  o ecossistema TOTVS. Inclui referências a boas práticas do Guia Oficial TDN TOTVS.
  Ativar também sempre que arquivos .prw, .prg ou .tlpp forem analisados, criados ou modificados.
---

## Overview
Esta skill orienta o Claude a agir como um Especialista Sênior em Protheus (ADVPL/TLPP). Ela deve ser ativada sempre que arquivos `.prw`, `.prg`, ou `.tlpp` forem analisados, criados ou modificados.

## Diretrizes de Codificação (TOTVS Standard)
- **Interface**: Dar preferência absoluta para o padrão MVC (Model-View-Controller) da TOTVS em novas rotinas.
- **Consultas**: Sempre utilize `ChangeQuery()` e respeite o uso de alias e tabelas compartilhadas/exclusivas através das funções `RetSqlName()`.
- **Performance**: Evite loops `While` que realizam queries internas. Use `Embedded SQL` sempre que possível.

## Recursos Disponíveis
Caso precise consultar assinaturas de funções específicas da TOTVS, consulte os arquivos markdown disponíveis no diretório Windows `.\resources\` desta skill.

> Em caso de conflito entre as diretrizes acima e o guia abaixo, as diretrizes acima (padrão do projeto) prevalecem.

---

# ADVPL / TLPP — Skill de Desenvolvimento Protheus

> Documentação de referência: **TDN TOTVS** (tdn.totvs.com) | **Central de Atendimento TOTVS** | **TOTVS Developers**

---

## 1. FUNDAMENTOS DA LINGUAGEM

### 1.1 Tipos de Dados

| Tipo   | Prefixo | Exemplos                            | Notas                                  |
|--------|---------|-------------------------------------|----------------------------------------|
| Caracter | `c`   | `cNome`, `cCodigo`                  | Strings com aspas duplas               |
| Numérico | `n`   | `nTotal`, `nQtd`                    | Int e float unificados                 |
| Data     | `d`   | `dEmissao`, `dVenc`                 | Criada via `CToD()`, `Date()`          |
| Lógico   | `l`   | `lAtivo`, `lOk`                     | `.T.` / `.F.` (`.Y.`/`.N.` também ok) |
| Array    | `a`   | `aItens`, `aParam`                  | Índice começa em **1**; máx 100.000 elem. |
| Objeto   | `o`   | `oModel`, `oGrid`                   | Instâncias de classes                  |
| Bloco    | `b`   | `bValid`, `bWhen`                   | Código armazenado para execução futura |
| NIL      | `x` (genérico) | `xRet`                   | Variável não inicializada              |

> ⚠️ ADVPL **não é strongly typed** — variáveis mudam de tipo dinamicamente. TLPP introduz tipagem forte.

---

### 1.2 Notação Húngara (convenção obrigatória)

```advpl
Local cNome    := "João"           // c = Caracter
Local nSalario := 2500.00          // n = Numérico
Local dAdmiss  := CToD("01/03/25") // d = Data
Local lAtivo   := .T.              // l = Lógico
Local aItens   := {}               // a = Array
Local oObj     := NIL              // o = Objeto
```

---

### 1.3 Escopo de Variáveis

| Comando  | Escopo                                      | Boas Práticas                          |
|----------|---------------------------------------------|----------------------------------------|
| `LOCAL`  | Função atual apenas                         | ✅ **Preferir sempre** — não vaza      |
| `STATIC` | Arquivo fonte; persiste entre chamadas      | ⚠️ Usar para contadores/caches locais  |
| `PRIVATE`| Função atual + filhas (herança)             | ⚠️ Apenas quando necessário            |
| `PUBLIC` | Todo o ambiente (sessão)                    | 🚫 Evitar; causa efeitos colaterais    |

> **Regra de ouro:** declare **sempre** `LOCAL` no topo da função; nunca use variáveis não declaradas.

---

### 1.4 Limitação de 10 Caracteres (ADVPL clássico)

```advpl
// ❌ ERRADO — os dois nomes colapsam (mesmos 10 primeiros chars)
Local nTotalGeralAnual   := 300
Local nTotalGeralMensal  := 100  // MESMO que a anterior!

// ✅ CORRETO — diferenciar nos primeiros caracteres
Local nAnualTotal  := 300
Local nMensalTotal := 100
```

> **TLPP resolve isso** com suporte a nomes longos nativamente.

---

## 2. ESTRUTURA DE PROGRAMAS

### 2.1 Cabeçalho Padrão com Protheus.doc

```advpl
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} MinhaFuncao
  Breve descrição do que a função faz.
  @type  Function
  @author Seu Nome
  @since 2025-01-01
  @version 1.0
  @param cCodigo, Caracter, Código do produto
  @param nQtd,    Numérico, Quantidade a processar
  @return lOk, Lógico, .T. se processou com sucesso
  @see MATA010, SB1
/*/
User Function MinhaFuncao( cCodigo, nQtd )
  Local lOk := .T.
  // ... implementação
Return lOk
```

### 2.2 Tipos de Função

```advpl
// Ponto de entrada — chamada pelo ERP (nome curto, máx 10 chars)
User Function MT010INC()   // PE após inclusão em MATA010
  // PARAMIXB traz os parâmetros do sistema
  Local aParam := PARAMIXB
Return .T.

// Função auxiliar local ao arquivo
Static Function ValidaDados( cCod, nVal )
Return ( !Empty(cCod) .AND. nVal > 0 )

// Função pública (acessível via ExecBlock/CallFunc)
Function U_HelperFn()
Return NIL
```

---

## 3. BANCO DE DADOS — PADRÕES E ARMADILHAS

### 3.1 Acesso via ISAM (modo ERP)

```advpl
// ✅ PADRÃO ERP: usar RecLock + MsUnlock + BeginTran/EndTran
BeginTran()
  If RecLock("SB1", .F.)   // .F. = alteração, .T. = inclusão
    SB1->B1_DESC := "Novo Produto"
    MsUnlock()
  EndIf
EndTran()

// Para inclusão de novo registro:
BeginTran()
  RecLock("SB1", .T.)      // .T. = append/novo
    SB1->B1_COD   := "000001"
    SB1->B1_DESC  := "Produto Teste"
  MsUnlock()
EndTran()
```

> 🚫 **NUNCA misturar** funções de Framework (`RecLock`, `MsUnlock`, `BeginTran`) com funções de baixo nível (`DBAppend`, `DBRUnlock`, `TCCommit`) no mesmo processo.

### 3.2 Acesso via SQL (TCQuery / Embedded SQL)

```advpl
Local cQuery := ""
Local cAliasQ := GetNextAlias()

cQuery := "SELECT B1_COD, B1_DESC "
cQuery += "  FROM " + RetSqlName("SB1") + " SB1 "
cQuery += " WHERE B1_FILIAL = '" + xFilial("SB1") + "' "
cQuery += "   AND SB1.D_E_L_E_T_ = ' ' "  // Filtro de exclusão lógica
cQuery += " ORDER BY B1_COD"

TCQuery( cQuery, .T., cAliasQ )

If !(cAliasQ)->(EOF())
  While !(cAliasQ)->(EOF())
    ConOut("Produto: " + (cAliasQ)->B1_COD + " - " + (cAliasQ)->B1_DESC)
    (cAliasQ)->(DBSkip())
  EndDo
EndIf

(cAliasQ)->(DBCloseArea())
```

> ✅ **Sempre** filtrar `D_E_L_E_T_ = ' '` (registros não excluídos logicamente).
> ✅ **Sempre** usar `xFilial("ALIAS")` no filtro de filial em consultas SQL.
> ✅ Usar `RetSqlName()` para obter o nome real da tabela no banco.

### 3.3 Posicionamento em Tabelas

```advpl
// Busca com índice (preferível para performance)
If MsSeek( xFilial("SA1") + cCodCli, "SA1", "1" )
  // Registro encontrado no índice 1 da SA1
  cNomeCli := SA1->A1_NOME
EndIf

// Busca sem índice (evitar em volumes grandes)
SA1->(DBSetOrder(1))
If SA1->(DbSeek( xFilial("SA1") + cCodCli ))
  cNomeCli := SA1->A1_NOME
EndIf
```

---

## 4. PONTOS DE ENTRADA (PE)

### 4.1 PE Convencional

```advpl
#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} MT010INC
  Ponto de entrada executado após inclusão de produto em MATA010.
  @type  User Function
  @author Dev
  @since 2025-01-01
  @param Nenhum (usa PARAMIXB)
  @return NIL
/*/
User Function MT010INC()
  Local aParam := PARAMIXB
  // aParam[1] = código do produto incluído (conforme doc TDN)
  ConOut("Produto incluído: " + SB1->B1_COD)
Return NIL
```

### 4.2 PE em MVC (padrão moderno — único PE por Model)

```advpl
#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} GPEA010
  Ponto de entrada único para fonte MVC GPEA010.
  O ID do PE deve ser igual ao ID do Model de dados.
  @type  User Function
  @param aParam, Array, Parâmetros via PARAMIXB
  @return xRet, Variado, Depende do IDPonto executado
/*/
User Function GPEA010()
  Local aParam := PARAMIXB
  Local xRet   := NIL
  Local cIDPonto := ""

  If ValType(aParam) == "A" .AND. Len(aParam) >= 1
    cIDPonto := aParam[1]  // Identifica qual momento do MVC chamou o PE
  EndIf

  Do Case
    Case cIDPonto == "MODELINIT"
      // Inicialização do model
      xRet := .T.

    Case cIDPonto == "MODELCOMMITTTS"
      // Após gravação — dentro da transação
      xRet := .T.

    Case cIDPonto == "MODELCANCEL"
      // Usuário cancelou
      xRet := .F.

    Case cIDPonto == "VIEWINIT"
      // View foi inicializada
  EndCase

Return xRet
```

> ⚠️ Em MVC: o nome do `User Function` (PE) deve ser **igual ao ID do Model**, mas **nunca** igual ao nome do arquivo fonte.

---

## 5. DESENVOLVIMENTO MVC

### 5.1 Estrutura de um Fonte MVC Completo

```advpl
#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TOTVS.CH"

// ---- CONTROLLER ----
User Function MYFONT01()
  Local aArea  := GetArea()
  Local oBrowse

  oBrowse := FwMBrowse():New()
  oBrowse:SetAlias("SB1")
  oBrowse:SetDescription("Cadastro de Produtos")
  oBrowse:Activate()

  RestArea(aArea)
Return NIL

// ---- MODEL ----
Static Function ModelDef()
  Local oModel  := MPFormModel():New("MYFONT01MDL", /*bPre*/, /*bPost*/, /*bCommit*/, /*bCancel*/)
  Local oStruct := FWFormStruct(1, "SB1")

  oModel:AddFields("SB1MASTER", /*parent*/, oStruct)
  oModel:SetPrimaryKey({"B1_COD"})

Return oModel

// ---- VIEW ----
Static Function ViewDef()
  Local oView  := FWFormView():New()
  Local oModel := FWLoadModel("MYFONT01")

  oView:SetModel(oModel)
  oView:AddField("VIEW01", FWFormStruct(2, "SB1"), "SB1MASTER")
  oView:CreateHorizontalBox("TOP", 100)
  oView:SetOwnerView("VIEW01", "TOP")

Return oView
```

---

## 6. REST API (ADVPL / TLPP)

### 6.1 Endpoint REST com TLPP (recomendado)

```tlpp
// Arquivo: MYAPI.tlpp
#INCLUDE "TLPP-CORE.TH"
#INCLUDE "TLPP-MVC.TH"

Namespace MyApp.Api

@Get("/produtos")
Function u_GetProdutos() As Object
  Local jResp    As JsonObject
  Local cQuery   As Character
  Local cAliasQ  As Character

  jResp    := JsonObject():New()
  cAliasQ  := GetNextAlias()
  cQuery   := "SELECT B1_COD, B1_DESC FROM " + RetSqlName("SB1")
  cQuery   += " WHERE B1_FILIAL = '" + xFilial("SB1") + "'"
  cQuery   += "   AND D_E_L_E_T_ = ' '"

  TCQuery(cQuery, .T., cAliasQ)

  Local aItens := {}
  While !(cAliasQ)->(EOF())
    Local jItem := JsonObject():New()
    jItem["codigo"] := AllTrim((cAliasQ)->B1_COD)
    jItem["descricao"] := AllTrim((cAliasQ)->B1_DESC)
    AAdd(aItens, jItem)
    (cAliasQ)->(DBSkip())
  EndDo
  (cAliasQ)->(DBCloseArea())

  jResp["items"] := aItens
  oRest:setResponse(jResp:toJson())

Return jResp
```

### 6.2 REST com ADVPL clássico (WSRestful)

```advpl
#INCLUDE "PROTHEUS.CH"
#INCLUDE "APWEBSRV.CH"

// Necessário registrar no appserver.ini: [HTTPServer] / [REST]
WSRestful oMeuServico Description "Serviço de Produtos"
  WsData oRest As Object

  WSMethod GET Description "Lista produtos" wsSyntax "/produtos"

End WSRestful

WSMethod GET WsReceive oMeuServico
  Local jResp := JsonObject():New()
  jResp["status"] := "ok"
  ::SetContentType("application/json")
  ::SetResponse(jResp:toJson())
Return .T.
```

---

## 7. TRATAMENTO DE ERROS

```advpl
// Try/Catch nativo do ADVPL
Begin Sequence With {|oErr| BreakOnError(oErr)}
  // Código que pode falhar
  RecLock("SB1", .F.)
  SB1->B1_DESC := "Teste"
  MsUnlock()
Recover With oErr
  // oErr:Description, oErr:Operation, oErr:SubCode
  MsgStop("Erro: " + oErr:Description, "Atenção")
  ConOut("[ERRO] " + oErr:Description + " - " + oErr:Operation)
End Sequence

// Alternativa: função ErrorBlock
Local bErr := ErrorBlock({|e| MyErrHandler(e)})
// ... código ...
ErrorBlock(bErr) // Restaura handler anterior

Static Function MyErrHandler(oErr)
  ConOut("Erro capturado: " + oErr:Description)
Return Break(oErr) // Interrompe o sequence
```

---

## 8. PERFORMANCE — REGRAS CRÍTICAS

1. **Evitar macroexecução desnecessária** (`&cVar`) — tem overhead elevado. Prefira `Eval(bBloco)`.
2. **Fechar áreas abertas** — sempre fechar `TCQuery` com `DBCloseArea()` após uso.
3. **Transações curtas** — não deixar `BeginTran()` aberto por longos períodos; aumenta locks.
4. **Arrays grandes** — evitar arrays com > 10.000 elementos; usar queries paginadas.
5. **TCQuery vs ISAM** — para **relatórios e leituras**, SQL é mais rápido; para **gravação no ERP**, use RecLock/MsUnlock.
6. **ConOut para log** — usar `ConOut()` em JOBs (sem interface). Nunca usar `Alert()` em processos servidor.
7. **Filtros SQL** — sempre indexar filtros de WHERE com campos indexados; evitar `LIKE '%valor%'`.
8. **Não misturar** funções de Framework com funções de baixo nível (DBAppend, DBRUnlock, TCCommit) no mesmo processo do ERP.

---

## 9. CONVENÇÕES DE NOMENCLATURA

| Elemento         | Padrão                            | Exemplo                  |
|------------------|-----------------------------------|--------------------------|
| Arquivo fonte    | 7 chars maiúsculos + extensão     | `MATA010.PRW`, `GPEA010.PRW` |
| User Function    | `U_` + nome (para chamada externa)| `U_ValidaCliente()`      |
| Static Function  | PascalCase                        | `ValidaDados()`          |
| Variável Local   | Prefixo tipo + CamelCase          | `cNomeCli`, `nValTotal`  |
| Parâmetros       | Mesmo padrão de variáveis         | `cCodigo`, `lAtivo`      |
| Constantes       | UPPER_SNAKE_CASE                  | `MAX_TENTATIVAS`         |
| Classes          | PascalCase (sem limite de chars)  | `FwFormModel`            |
| Métodos          | PascalCase                        | `oModel:GetValue()`      |
| Includes         | UPPER.CH                          | `PROTHEUS.CH`, `TOTVS.CH`|

---

## 10. INCLUDES ESSENCIAIS

```advpl
#INCLUDE "PROTHEUS.CH"   // Base do Protheus — sempre incluir
#INCLUDE "TOTVS.CH"      // Framework geral
#INCLUDE "FWMVCDEF.CH"   // Constantes MVC (MODEL_FIELD_WHEN, etc.)
#INCLUDE "PARMTYPE.CH"   // Validação de tipos de parâmetros
#INCLUDE "APWEBSRV.CH"   // WebServices REST/SOAP (clássico)
#INCLUDE "TLPP-CORE.TH"  // Núcleo TLPP (somente em fontes .tlpp)
#INCLUDE "TLPP-MVC.TH"   // MVC em TLPP
```

---

## 11. TLPP — DIFERENÇAS E MODERNIZAÇÃO

| Recurso           | ADVPL clássico           | TLPP                              |
|-------------------|--------------------------|-----------------------------------|
| Tipagem           | Dinâmica                 | Forte (`As Character`, `As Numeric`) |
| Nomes longos      | Máx 10 chars             | Ilimitado                         |
| Namespaces        | Não                      | ✅ `Namespace MinhaEmpresa.Modulo` |
| Parâmetros nomeados | Não                   | ✅ `fn(cNome := "João")`          |
| Try/Catch         | `Begin Sequence`         | ✅ `Try / Catch / Finally`        |
| Annotations REST  | Não                      | ✅ `@Get`, `@Post`, `@Put`        |
| Extensão          | `.prw` / `.prg` / `.prx` | `.tlpp`                           |
| Compatibilidade   | —                        | Chama ADVPL e vice-versa          |

---

## 12. CHECKLIST DE QUALIDADE

Antes de entregar um fonte ADVPL/TLPP, verificar:

- [ ] Todas as variáveis declaradas com `LOCAL` (ou escopo correto) no topo da função
- [ ] Notação Húngara aplicada em todas as variáveis
- [ ] `Protheus.doc` preenchido (type, author, since, param, return)
- [ ] `#INCLUDE` dos headers necessários no topo
- [ ] Filtro `D_E_L_E_T_ = ' '` em todas as queries SQL
- [ ] `xFilial()` nos filtros de tabelas multi-empresa/filial
- [ ] Alias de TCQuery fechado com `DBCloseArea()`
- [ ] `BeginTran/EndTran` envolvendo operações de gravação
- [ ] `RecLock/MsUnlock` em par — nunca um sem o outro
- [ ] Tratamento de erro com `Begin Sequence` ou Try/Catch (TLPP)
- [ ] `GetArea/RestArea` para preservar posicionamento de tabelas em funções auxiliares
- [ ] `ConOut()` para log em processos servidor/JOB (nunca `Alert/MsgInfo`)
- [ ] Nomes de funções com máximo 10 caracteres significativos (ADVPL clássico)
- [ ] PE MVC: ID do model ≠ nome do arquivo fonte

---

## 13. REFERÊNCIAS

Para detalhes adicionais, consulte os arquivos em `references/`:

- `references/funcoes-essenciais.md` — catálogo de funções mais usadas
- `references/tabelas-sx.md` — estrutura das tabelas SX do dicionário
- `references/erros-comuns.md` — erros frequentes e soluções
- `references/rest-avancado.md` — configuração completa do servidor REST

**Links TDN:**
- Guia de Boas Práticas ADVPL: `tdn.totvs.com/pages/releaseview.action?pageId=22480352`
- Convenções da linguagem: `tdn.totvs.com/pages/viewpage.action?pageId=22480357`
- REST TLPP: `tdn.totvs.com/display/tec/REST`
- Tipos de Dados: `tdn.totvs.com/display/tec/Tipos+de+Dados`
- Funções ADVPL: `tdn.totvs.com/display/tec/AdvPL+-+Functions`

---

## APÊNDICE A — Funções Essenciais (conteúdo de `references/funcoes-essenciais.md`)

### Strings

| Função         | Uso                                              | Exemplo                            |
|----------------|--------------------------------------------------|------------------------------------|
| `AllTrim()`    | Remove espaços no início e fim                   | `AllTrim(SA1->A1_NOME)`            |
| `SubStr()`     | Extrai substring                                 | `SubStr(cStr, 1, 5)`               |
| `At()`         | Posição de substring                             | `At(".", cEmail)`                  |
| `Len()`        | Comprimento da string                            | `Len(cStr)`                        |
| `Upper()`      | Converte para maiúsculas                         | `Upper(cCod)`                      |
| `Lower()`      | Converte para minúsculas                         | `Lower(cEmail)`                    |
| `StrZero()`    | Número para string com zeros à esquerda          | `StrZero(nNum, 6)` → `"000001"`    |
| `PadR()`       | Preenche à direita com espaços                   | `PadR(cNome, 50)`                  |
| `PadL()`       | Preenche à esquerda com espaços                  | `PadL(cCod, 10)`                   |
| `cValToChar()` | Converte qualquer tipo para string               | `cValToChar(nTotal)`               |
| `Str()`        | Numérico para caracter                           | `Str(nVal, 10, 2)`                 |
| `Val()`        | String para numérico                             | `Val("123.45")`                    |
| `Empty()`      | Verifica se está vazio (qualquer tipo)           | `If Empty(cCod)`                   |

### Datas

| Função         | Uso                                              | Exemplo                            |
|----------------|--------------------------------------------------|------------------------------------|
| `Date()`       | Data de hoje                                     | `dHoje := Date()`                  |
| `CToD()`       | String para data                                 | `CToD("31/12/2025")`               |
| `DToC()`       | Data para string                                 | `DToC(dData)` → `"31/12/2025"`     |
| `DToS()`       | Data para string no formato YYYYMMDD             | `DToS(dData)` → `"20251231"`       |
| `SToD()`       | String YYYYMMDD para data                        | `SToD("20251231")`                 |
| `Month()`      | Mês da data                                      | `Month(Date())` → `3`              |
| `Year()`       | Ano da data                                      | `Year(Date())` → `2025`            |
| `Day()`        | Dia da data                                      | `Day(Date())` → `31`              |
| `LastDay()`    | Último dia do mês                                | `LastDay(1, 2025)` → `31`         |

### Arrays

| Função         | Uso                                              | Exemplo                            |
|----------------|--------------------------------------------------|------------------------------------|
| `AAdd()`       | Adiciona elemento ao final                       | `AAdd(aLista, "item")`             |
| `ASize()`      | Redimensiona array                               | `ASize(aArr, 10)`                  |
| `Len()`        | Tamanho do array                                 | `Len(aArr)`                        |
| `AScan()`      | Busca em array (retorna índice ou 0)             | `AScan(aArr, "valor")`             |
| `AFill()`      | Preenche array com valor                         | `AFill(aArr, 0)`                   |
| `AClone()`     | Copia um array                                   | `aCopia := AClone(aOrig)`          |
| `ASort()`      | Ordena array                                     | `ASort(aArr)`                      |
| `DEL()`        | Remove elemento por índice                       | `ADel(aArr, nIdx); ASize(aArr, Len(aArr)-1)` |

### Banco de Dados (modo ERP)

| Função           | Uso                                            |
|------------------|------------------------------------------------|
| `RecLock()`      | Trava registro para alterar (.F.) ou incluir (.T.) |
| `MsUnlock()`     | Destrava registro após inclusão/alteração      |
| `BeginTran()`    | Inicia transação no banco                      |
| `EndTran()`      | Confirma transação                             |
| `RollBackTran()` | Desfaz transação                               |
| `MsSeek()`       | Posiciona em registro por chave + alias + índice |
| `xFilial()`      | Retorna código de filial para filtros          |
| `RetSqlName()`   | Retorna nome real da tabela no SQL             |
| `TCQuery()`      | Executa query SQL e cria alias temporário      |
| `GetNextAlias()` | Obtém próximo nome de alias disponível         |
| `DBCloseArea()`  | Fecha área de trabalho (alias)                 |
| `DBSkip()`       | Avança para próximo registro                   |
| `DBGoTop()`      | Vai para o primeiro registro                   |
| `DBSetOrder()`   | Define ordem/índice ativo                      |
| `DBSeek()`       | Busca registro pela chave do índice ativo      |

### Ambiente / Configuração

| Função           | Uso                                            |
|------------------|------------------------------------------------|
| `GetArea()`      | Salva áreas de trabalho abertas                |
| `RestArea()`     | Restaura áreas de trabalho salvas              |
| `GetEnvServer()` | Retorna nome do ambiente                       |
| `FunName()`      | Nome da função em execução                     |
| `ThreadId()`     | ID da thread atual                             |
| `SuperGetMV()`   | Lê parâmetro do SX6 (configurações do sistema) |

### Interface / Mensagens

| Função           | Uso                                            |
|------------------|------------------------------------------------|
| `MsgInfo()`      | Caixa de mensagem informativa                  |
| `MsgStop()`      | Caixa de aviso (ponto de atenção)              |
| `MsgYesNo()`     | Pergunta Sim/Não, retorna lógico               |
| `ApMsgYesNo()`   | Versão "Ap" do MsgYesNo                        |
| `ConOut()`       | Grava no log do console do servidor            |
| `Alert()`        | Mensagem simples (somente com SmartClient)     |
| `Help()`         | Exibe ajuda contextual do campo                |

### Conversão / Validação

| Função           | Uso                                            |
|------------------|------------------------------------------------|
| `ValType()`      | Retorna tipo da variável: C, N, D, L, A, O, B, U |
| `IsNil()`        | Verifica se é NIL                              |
| `Type()`         | Verifica tipo de variável PUBLIC/PRIVATE por nome |
| `cValToChar()`   | Converte qualquer tipo para string             |
| `Posicione()`    | Posiciona em tabela e retorna valor do campo   |
| `ExistCpo()`     | Verifica se campo existe na tabela             |
| `ExistAlias()`   | Verifica se alias está aberto                  |

### JSON (TLPP / ADVPL moderno)

```advpl
// Criar JSON
Local jObj := JsonObject():New()
jObj["nome"]  := "Produto A"
jObj["preco"] := 99.90
jObj["ativo"] := .T.
cJson := jObj:toJson()

// Ler JSON
Local jParsed := JsonObject():New()
jParsed:fromJson(cJson)
cNome := jParsed["nome"]

// Array JSON
Local aItens := {}
Local jItem  := JsonObject():New()
jItem["id"]  := 1
AAdd(aItens, jItem)
jObj["itens"] := aItens
```

---

## APÊNDICE B — Tabelas SX (conteúdo de `references/tabelas-sx.md`)

### Tabelas do Dicionário (SX*)

| Tabela | Descrição                                    | Campos Principais                         |
|--------|----------------------------------------------|-------------------------------------------|
| SX2    | Dicionário de Tabelas                        | X2_CHAVE, X2_NOME, X2_NUMCAM             |
| SX3    | Dicionário de Campos                         | X3_ARQUIVO, X3_CAMPO, X3_TIPO, X3_TAMANHO, X3_DECIMAL, X3_TITULO |
| SX5    | Tabelas de Domínio (Tabelas Genéricas)       | X5_TABELA, X5_CHAVE, X5_DESCRI           |
| SX6    | Parâmetros do Sistema (MV_*)                 | X6_VAR, X6_TIPO, X6_CONTEUD, X6_DESCRIC |
| SX7    | Gatilhos                                     | X7_CAMPO, X7_REGRA, X7_ALIAS             |
| SXA    | Opções de campos tipo Combo                  | XA_ALIAS, XA_CAMPO, XA_OPCAO, XA_DESCRI |
| SXB    | Consultas Padrão (F3)                        | XB_ALIAS, XB_TIPO, XB_SEQ, XB_COLUNA    |
| SXD    | Pastas (Folders de tela)                     | XD_ROTINA, XD_SEQUEN, XD_DESCRI         |
| SXE    | Numerações Automáticas                        | XE_SEQUEN, XE_CAMPO, XE_CHAVE           |
| SXF    | Número de campos por tabela                   | —                                        |
| SXG    | Índices do dicionário                         | XG_INDICE, XG_ORDEM, XG_CHAVE           |

### Como ler parâmetros SX6 (MV_PAR*)

```advpl
// Lê valor do parâmetro MV_XXXX
Local cValor := SuperGetMV("MV_NOMEPAR")

// Com valor default caso não exista
Local cValor := SuperGetMV("MV_NOMEPAR", .F., "valorpadrao")

// Tipos de retorno dependem do tipo do parâmetro (C, N, D, L)
Local nDias  := Val(SuperGetMV("MV_PRAZO"))
Local lAtivo := SuperGetMV("MV_ATIVO") == "1"
```

### Como ler SX5 (tabelas de domínio)

```advpl
// Função padrão para buscar descrição em tabela de domínio
Local cDescri := ""

// Usando Posicione()
cDescri := Posicione("SX5", 1, xFilial("SX5") + "XX" + cChave, "X5_DESCRI")

// Ou via DbSeek direto
If SX5->(DbSeek( xFilial("SX5") + "XX" + cChave ))
  cDescri := AllTrim(SX5->X5_DESCRI)
EndIf
```

### Tabelas de Dados Principais

### Financeiro
| Tabela | Módulo    | Descrição                    |
|--------|-----------|------------------------------|
| SE1    | SIGAFIN   | Contas a Receber             |
| SE2    | SIGAFIN   | Contas a Pagar               |
| SE5    | SIGAFIN   | Movimentação Bancária        |
| SA6    | SIGAFIN   | Bancos                       |

### Estoque / Produtos
| Tabela | Módulo    | Descrição                    |
|--------|-----------|------------------------------|
| SB1    | SIGAEST   | Cadastro de Produtos         |
| SB2    | SIGAEST   | Saldos em Estoque            |
| SB8    | SIGAEST   | Rastreabilidade (Lotes)      |
| SD3    | SIGAEST   | Movimentações de Estoque     |

### Compras / Faturamento
| Tabela | Módulo    | Descrição                    |
|--------|-----------|------------------------------|
| SC1    | SIGACOM   | Solicitações de Compra       |
| SC7    | SIGACOM   | Pedidos de Compra            |
| SD1    | SIGACOM   | Itens de NF de Entrada       |
| SF1    | SIGACOM   | Cabeçalho de NF de Entrada   |
| SF2    | SIGAFAT   | Cabeçalho de NF de Saída     |
| SD2    | SIGAFAT   | Itens de NF de Saída         |
| SC5    | SIGAFAT   | Cabeçalho de Pedido de Venda |
| SC6    | SIGAFAT   | Itens de Pedido de Venda     |

### Cadastros Gerais
| Tabela | Módulo    | Descrição                    |
|--------|-----------|------------------------------|
| SA1    | Geral     | Clientes                     |
| SA2    | Geral     | Fornecedores                 |
| SA3    | Geral     | Vendedores                   |
| SA4    | Geral     | Transportadoras              |
| SCC    | Geral     | Centro de Custos             |
| CTT    | SIGACTB   | Centro de Custo              |

### Campos Especiais de Controle

| Campo        | Descrição                                     |
|--------------|-----------------------------------------------|
| D_E_L_E_T_   | Marca de exclusão lógica (`'*'` = excluído, `' '` = ativo) |
| R_E_C_N_O_   | Número do registro físico (interno)           |
| R_E_C_D_E_L_ | Índice de exclusão lógica                    |
| `*_FILIAL`   | Código da filial (ex: B1_FILIAL, A1_FILIAL)  |

```advpl
// Sempre filtrar registros ativos:
cQuery += " WHERE D_E_L_E_T_ = ' '"

// E por filial (em tabelas multi-empresa):
cQuery += "   AND B1_FILIAL = '" + xFilial("SB1") + "'"
```

### Função Posicione() — Referência Rápida

```advpl
// Syntax: Posicione(cAlias, nOrdem, cChave, cCampo)
// Retorna o valor do campo sem alterar o posicionamento atual

Local cNomeCli := Posicione("SA1", 1, xFilial("SA1") + cCodCli, "A1_NOME")
Local cNomeProd := Posicione("SB1", 1, xFilial("SB1") + cCodProd, "B1_DESC")
Local nSaldo := Val(Posicione("SB2", 1, xFilial("SB2") + cCodProd + cArmazem, "B2_QATU"))
```

---

## APÊNDICE C — Erros Comuns (conteúdo de `references/erros-comuns.md`)

### Erros de Runtime Frequentes

### "Variable does not exist: nNomeVariavel"
**Causa:** Variável usada sem ser declarada.
**Solução:**
```advpl
// ❌ Errado
nResultado := nValor * 2

// ✅ Correto
Local nValor := 0
Local nResultado := 0
nResultado := nValor * 2
```

---

### "Type mismatch on +"
**Causa:** Tentativa de concatenar tipos incompatíveis (ex: string + NIL ou string + número).
**Solução:**
```advpl
// ❌ Errado
cMsg := "Valor: " + nTotal

// ✅ Correto — usar cValToChar() ou Str()
cMsg := "Valor: " + cValToChar(nTotal)
cMsg := "Valor: " + Str(nTotal, 10, 2)
```

---

### Variáveis com nomes de 10+ chars colidindo
**Causa:** ADVPL considera apenas os primeiros 10 chars do nome.
**Sintoma:** Uma variável "sobrescreve" outra sem motivo aparente.
**Solução:**
```advpl
// ❌ Colidem (mesmos 10 primeiros chars)
Local nTotalGeralAnual   := 300
Local nTotalGeralMensal  := 100  // Na prática é a mesma!

// ✅ Diferencia nos primeiros caracteres
Local nAnualTotal  := 300
Local nMensalTotal := 100
```

---

### Lock / Deadlock em tabelas
**Causa:** `RecLock()` não seguido de `MsUnlock()` (erro, exception, Return antecipado).
**Solução:**
```advpl
// ✅ Usar Begin Sequence para garantir destravamento
Begin Sequence
  RecLock("SB1", .F.)
    SB1->B1_DESC := "Novo"
  MsUnlock()
Recover With oErr
  MsUnlock()  // Garante desbloqueio mesmo em erro
  MsgStop(oErr:Description)
End Sequence
```

---

### Alias de TCQuery não fechado (vazamento de cursores)
**Causa:** `TCQuery()` sem `DBCloseArea()` correspondente.
**Sintoma:** Número crescente de cursores abertos no DBAccess, degradação de performance.
**Solução:**
```advpl
Local cAliasQ := GetNextAlias()
TCQuery(cQuery, .T., cAliasQ)

// ... processamento ...

(cAliasQ)->(DBCloseArea())  // SEMPRE fechar
```

---

### "PE MVC com mesmo nome do Model"
**Causa:** O arquivo fonte (User Function) tem o mesmo nome do ID do Model de dados.
**Solução:**
```advpl
// ❌ Fonte GPEA010 com Model ID = "GPEA010"
// ✅ Fonte GPEA010 com Model ID = "GPEA010MDL" (ou qualquer nome diferente)
```

---

### "D_E_L_E_T_ retornando registros excluídos"
**Causa:** Query SQL sem filtro de exclusão lógica do Protheus.
**Solução:**
```advpl
// ❌ Sem filtro
cQuery := "SELECT * FROM SB1010"

// ✅ Com filtro de exclusão lógica
cQuery := "SELECT * FROM " + RetSqlName("SB1")
cQuery += " WHERE D_E_L_E_T_ = ' '"
```

---

### Performance degradada em consultas SQL
**Causa:** Falta de filtro de filial, LIKE com wildcard no início, ou falta de índice.
**Soluções:**
```advpl
// ✅ Sempre filtrar por filial
cQuery += " WHERE B1_FILIAL = '" + xFilial("SB1") + "'"

// ✅ Evitar LIKE '%valor%' — não usa índice
// Preferir LIKE 'valor%' ou filtro exato

// ✅ ORDER BY apenas em campos indexados
```

---

### Função não encontrada em tempo de execução
**Causa:** Nome da função com mais de 10 chars — ADVPL trunca na compilação.
**Sintoma:** "Function 'OpenNoTaxReceipt' not found" mas a função existe.
**Solução:**
```advpl
// ADVPL vai procurar pelos primeiros 10 chars: "OpenNoTaxR"
// Se houver outra função OpenNoTaxReceiptBound, haverá colisão
// ✅ Estratégia: colocar diferenciador no início do nome
Function RecNoTaxOpen()   // Receipt No Tax Open
Function RecNoTaxClose()  // Receipt No Tax Close
```

---

### Erros de Ambiente

### Compilação com erro de #INCLUDE não encontrado
```advpl
// Verificar paths no TDS/VSCode e nos includes do appserver.ini
// Includes essenciais:
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"
```

### ConOut() não aparece no log
- Verificar se o nível de log do AppServer está configurado corretamente
- ConOut só aparece no console.log do Application Server
- Usar `ApMsgAlerta()` para debug com interface, ou `ConOut()` + visualizar via TDS Console

### Erro ao executar REST: "404 Not Found"
- Verificar se o `[HTTP]` e `[REST]` estão configurados no appserver.ini
- Certificar que o arquivo foi compilado no RPO correto
- Em TLPP: verificar se o `Namespace` e a `@Get`/`@Post` annotation estão corretos

---

> Guia (seções 1–13 e apêndices) importado de https://github.com/jaylson/claude-skill-advpl (commit 5c9e01d), licença MIT © 2025 Jaylson.
