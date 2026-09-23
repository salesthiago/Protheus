# Sinistros de Frota (MNTA540 em POUI) — Cronograma da 1ª Etapa

> Recriação da rotina padrão **MNTA540** (Sinistros / SIGAMNT) no modelo híbrido
> Angular + PO-UI + FWCallApp, seguindo **exatamente** o padrão de `POUI/estmvc001`
> (igual em `POUI/rtm002` / `POUI/rtm003`): **sem HTTP/REST** — o front fala direto
> com o ADVPL pelo canal `AdvplToJs / JsToAdvpl`. Ver §6.
>
> Menu: **módulo Gestão de Frotas (95 / SIGAMNT)**. User Function `U_MNTA540App()`.
> Projeto Angular: `POUI/frtsin001`.

Base: 5 PDFs oficiais (`C:\Users\Protheus\Desktop\sinistros\`) + SX3 real de
**TRH** (`sx39901_trh.txt`, 56 campos) e de **TRI, TRN, TRO, TRM, TRJ** (prints
enviados 2026-09-03).

---

## 0. Decisões confirmadas pelo cliente

| # | Tema | Decisão |
|---|------|---------|
| 1 | Envolvidos / anexos | **Sem tabelas custom.** Filhas nativas: **TRI** (anexos/documentos), **TRN** (testemunhas), **TRO** (veículos envolvidos + condutor), **TRM** (vítimas), **TRJ** (inquérito/jurídico — fora do escopo). |
| 2 | Filial na importação | Ignorar a coluna UNIDADE; gravar tudo na **filial do usuário logado** (`cFilAnt`). |
| 3 | Bem não encontrado | **Pular a linha** e listar os não importados no relatório final. |
| 4 | Evento | Equipamento → `TRH_EVENTO='3'` (Incidente); veículo → `TRH_EVENTO='1'` (Acidente). |
| 5 | OS automática | Desligada — forçar `TRH_FLGDAN='2'` na carga. |
| 6 | Culpabilidade | Somente registro (sem integração Financeiro/folha). |
| 7 | Terceiro | Texto livre + CPF (não cadastrar em SA1/SA2 agora). |
| 8 | Status (SX5 `SP`) | Criar: `01`=ABERTURA, `02`=AGUARDANDO DOCUMENTAÇÃO, `03`=ABERTURA DE INQUÉRITO, `04`=JURÍDICO, `05`=NEGOCIAÇÃO, `06`=ARQUIVADO, `07`=CANCELADO. De‑para: vazio→`01`, `FAZENDO TERMO DE ACORDO`→`05`, `FINALIZADO`→`06`. |
| 9 | TST (coluna 11) | É **nome de testemunha** → grava em **TRN**. |
| 10 | Menu | Módulo Gestão de Frotas (95). |
| 11 | Origem do veículo (TRO) | Campo custom **`TRO_ZORIG`** C(1): `1`=Quebec, `2`=Terceiro. |
| 12 | Culpabilidade | Fica em **`TRH_ZCULPA`** (custom, cabeçalho). `TRJ_CULAPU` só na fase jurídica. |
| 13 | Anexo físico | Arquivo **no servidor** em `\sinistros\anexos\<filial>\<numsin>\`, **limite 100 MB/arquivo**; metadados em campos custom `TRI_Z*`. |
| 14 | Matrícula do condutor Quebec | Campo custom **`TRO_ZMAT`** C(6), F3 SRA. |

---

## 1. Estrutura das tabelas (SX3 real)

### 1.1 TRH — Sinistro (cabeçalho) — 56 campos
Campos-chave para esta etapa (tipo/tam):

`TRH_FILIAL`(C2) · `TRH_NUMSIN`(C6, `GetSXENum('TRH','TRH_NUMSIN')`) ·
`TRH_DTACID`(D) **(O)** · `TRH_HRACID`(C5) **(O)** ·
`TRH_EVENTO`(C1, `1=Acidente;2=Roubo;3=Incidente`, init `'1'`) **(O)** ·
`TRH_CODBEM`(C16, F3 ST9 `T9_CATBEM` in 2,4) **(O)** ·
`TRH_NOMBEM`(C30, auto `T9_NOME`) · `TRH_PLACA`(C8) **(O)** ·
`TRH_GRAVID`(C1, init `'1'`) · `TRH_TEMPO`/`TRH_VIA`/`TRH_PERIOD`(`1=Manhã;2=Noite;3=Tarde;4=Madrugada`)/`TRH_VIADIR` (init `'1'`) ·
`TRH_LOCAL`(C60) **(O)** · `TRH_CIDACI`(C40) · `TRH_UFACID`(C2, F3 SX5 `12`) **(O)** ·
`TRH_INTERR`/`TRH_GUINCH`/`TRH_CONDEL`/`TRH_TEREVA`/`TRH_FLGDAN` (`1=Sim;2=Não`, init `'2'`) ·
`TRH_STATUS`(C2, F3 SX5 `SP`, init `'01'`) · `TRH_DESCRI`(M80, chave `TRH_MMSYP`) **(O)** ·
`TRH_FLGCOM`(C1, `1=Não Complementado;2=Complementado;3=Finalizado`, init `'2'`) ·
`TRH_DTDIG`(init `DDATABASE`) · `TRH_HRDIG`(init `TIME()`) · `TRH_ORDEM`(C6).

### 1.2 TRO — Veículos envolvidos (35 campos) — **o coração do mapeamento**
`TRO_FILIAL`(C2) · `TRO_NUMSIN`(C6) · `TRO_SEQVEI`(C3) ·
`TRO_PLACA`(C8) · `TRO_TIPVEI`(C1, *domínio a confirmar — §7.1.1*) ·
`TRO_DESVEI`(C40, veículo) · `TRO_MOTVEI`(C40, **condutor**) · `TRO_TELMOT`(C15) ·
`TRO_ENDMOR`(C40) · `TRO_CIDMOT`(C20) · `TRO_UFMOT`(C2) · `TRO_CNHMOT`(C15) ·
`TRO_DTVALC`(D) · `TRO_SSPMOT`(C6) · `TRO_UFCNH`(C2) ·
`TRO_RG`(C15) · `TRO_RGORG`(C6) · `TRO_UFREG`(C2) · `TRO_CPF`(C14, **CPF condutor**) ·
`TRO_DANOS`(C1, `?`) · `TRO_VALPRE`(N12,2, Vlr. Prejuízo) ·
`TRO_NOMPR`(C40, Proprietário) · `TRO_TELPRO`/`TRO_ENDPRO`/`TRO_CIDPRO`/`TRO_UFPRO` ·
`TRO_SEGUR`(C1) · `TRO_SEGCOR`(C40, Seguradora) · `TRO_APOLIC`(C20) · `TRO_TELSEG`(C15) ·
`TRO_RENAVA`(C15) · `TRO_DESC`(M10, chave `TRO_MMSYP`) ·
**`TRO_VALTER`(N12,2 — Val Pag Terceiro)** · **`TRO_PERCEN`(N8,2 — % de Ganho)**.

### 1.3 TRN — Testemunhas (11 campos)
`TRN_FILIAL` · `TRN_NUMSIN`(C6) · `TRN_SEQTES`(C3) · `TRN_NOMTES`(C40) ·
`TRN_TELTES`(C15) · `TRN_ENDTES`(C40) · `TRN_CIDTES`(C20) · `TRN_UFTES`(C2) ·
`TRN_TIPDOC`(C1) · `TRN_DOCTO`(C15) · `TRN_QLFTES`(C15, Qualificação).

### 1.4 TRM — Vítimas (16 campos)
`TRM_FILIAL` · `TRM_NUMSIN`(C6) · `TRM_SEQVIT`(C3) ·
**`TRM_INDFUN`(C1 — Funcionário? 1/2)** · **`TRM_MATVIT`(C6 — Cód. Vítima / matrícula)** ·
`TRM_NOMVIT`(C40) · `TRM_TELVIT`/`TRM_ENDVIT`/`TRM_CIDVIT`/`TRM_UFVIT` ·
`TRM_LESOES`(C80) · `TRM_ACAO`(C80) · `TRM_DESFUN`(C40, Função) ·
`TRM_FATAL`(C1) · `TRM_CODVIT`(C1, Cond. Vítima) · `TRM_VALVIT`(N14,2, Valor gasto c/ vítima).
→ A planilha não traz dados de vítima; TRM fica disponível só para uso manual na tela.

### 1.5 TRI — Anexos / Documentos (8 campos)
`TRI_FILIAL` · `TRI_NUMSIN`(C6) · `TRI_CODBEM`(C16) · `TRI_NOMBEM`(C30) ·
`TRI_CODDOC`(C6, F3 `TRU`) · `TRI_NOMDOC`(C30) · `TRI_DTREC`(D) · `TRI_HRREC`(C5).
→ **TRI não guarda o arquivo físico** (só registra o documento recebido). Para
anexar foto/termo/contrato de fato, precisamos de campos custom + arquivo no
servidor — ver §3.3 e §7.1.3.

### 1.6 TRJ — Inquérito / Processo Judicial (20 campos) — fora do escopo
Contém, entre outros, **`TRJ_CULAPU`(C2 — Culpa Apurada)** e **`TRJ_DESCUL`(C40 —
Descrição da Culpa)**. É a "culpa" na visão jurídica; será preenchida na etapa do
processo. A classificação operacional de culpabilidade desta etapa fica no
cabeçalho (`TRH_ZCULPA`, §3.2) para não exigir abertura de inquérito.

---

## 2. Escopo desta etapa

| # | Entrega |
|---|---------|
| A | Campos custom (TRH/TRO/TRI) + criação dos códigos SX5 `SP` + TRU (tipos de anexo) |
| B | Backend `MNTA540App.prw` — canal `JsToAdvpl` + CRUD de TRH e filhas TRO/TRN/TRM/TRI + lookups |
| C | **Importação de `sinistros 2026.csv`** para a filial logada (de‑para de bem por placa/série, simulação + efetivação) |
| D | Frontend `POUI/frtsin001` — lista + editor em abas (Sinistro / Veículos / Testemunhas / Vítimas / Anexos) + wizard de importação |
| E | Anexos (TRI + arquivo no servidor) — foto, termo, contrato, BO, NF |
| F | Teste em SmartClient + ajustes |

**Fora do escopo:** OS automática, pastas Cargas / Imóveis / Animais, processo
jurídico (TRJ / TRR / MNTA595 / MNTA965), integração Financeiro/folha, seguro/franquia.

---

## 3. Modelo de dados

### 3.1 Mapa da planilha → tabelas

**Cabeçalho — TRH** (1 registro por linha da planilha):

| Col CSV | Campo TRH |
|---------|-----------|
| 1 DATA DO SINISTRO (`dd/mm/aaaa`) | `TRH_DTACID` |
| 3 PLACA/Nº SÉRIE → busca ST9 | `TRH_CODBEM`, `TRH_PLACA`, `TRH_NOMBEM` |
| (bem achado por placa) → veículo | `TRH_EVENTO='1'` |
| (bem achado só por série) → equipamento | `TRH_EVENTO='3'` |
| 16 STATUS | `TRH_STATUS` (de‑para §0.8) |
| 17 OBSERVAÇÃO | `TRH_DESCRI` |
| 0 NUMERO DO FOR | `TRH_ZNRFOR` (custom) |
| 10 CULPABILIDADE | `TRH_ZCULPA` + `TRH_ZCLPNM` (custom, §3.2 / §4.4) |
| 14 EM FOLHA | `TRH_ZVLFOL` (custom — só registro) |
| 15 SALDO A DESCONTAR | `TRH_ZVLSLD` (custom — só registro) |

**Veículo/equipamento da Quebec — TRO (SEQVEI `001`)**:

| Col CSV | Campo TRO |
|---------|-----------|
| 3 (placa do bem, se veículo) | `TRO_PLACA` |
| 4 CARRO DA QUEBEC (descrição) | `TRO_DESVEI` |
| 5 NOME DO CONDUTOR QUEBEC | `TRO_MOTVEI` |
| 6 MATRICULA | `TRO_ZMAT` (custom, F3 SRA) + nome do SRA reforça `TRO_MOTVEI` |
| origem = Quebec | `TRO_TIPVEI` (ou `TRO_ZORIG='1'` — §7.1.1) |

**Veículo do terceiro — TRO (SEQVEI `002`, só quando há placa/CPF de terceiro)**:

| Col CSV | Campo TRO |
|---------|-----------|
| 9 PLACA DO TERCEIRO | `TRO_PLACA` |
| 8 NOME DO MOTORISTA TERCEIRO | `TRO_MOTVEI`, `TRO_NOMPR` |
| 7 CPF: TERCEIRO | `TRO_CPF` |
| 12 VALOR A SER PAGO AO TERCEIRO | **`TRO_VALTER`** (nativo) |
| — | `TRO_DANOS='1'` |
| origem = Terceiro | `TRO_TIPVEI` (ou `TRO_ZORIG='2'`) |

**Testemunha — TRN (SEQTES `001`, quando col 11 preenchida)**:

| Col CSV | Campo TRN |
|---------|-----------|
| 11 TST | `TRN_NOMTES` |
| fixo | `TRN_QLFTES = "TST"` |

Colunas ignoradas: 2 (UNIDADE — decisão 0.2), 13 (ACIDENTE INTERNO — sempre vazia).

### 3.2 Campos custom a criar

**TRH**
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `TRH_ZCULPA` | C(1) | Culpabilidade: `1`=Terceiro, `2`=Empresa, `3`=Funcionário, `4`=Força maior/sem culpa, `9`=A apurar |
| `TRH_ZCLPNM` | C(60) | Nome do apontado como culpado (texto da planilha) |
| `TRH_ZNRFOR` | C(6) | "Número do FOR" da planilha |
| `TRH_ZVLFOL` | N(14,2) | Valor lançado em folha (col. 14) — só registro |
| `TRH_ZVLSLD` | N(14,2) | Saldo a descontar (col. 15) — só registro |
| `TRH_ZIMPKEY`| C(40) | Hash da linha de origem — idempotência da importação |
| `TRH_ZFONTE` | C(1) | Origem: `I`=Importação, `M`=Manual |

**TRO**
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `TRO_ZMAT` | C(6) | Matrícula do condutor quando funcionário Quebec — F3 SRA |
| `TRO_ZORIG` | C(1) | `1`=Veículo Quebec, `2`=Veículo de terceiro |

**TRI** (para guardar o arquivo físico — §7.1.3)
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `TRI_ZTIPO` | C(1) | `1`=Foto, `2`=Termo, `3`=Contrato, `4`=BO, `5`=NF, `9`=Outros *(ou usar `TRI_CODDOC`+TRU)* |
| `TRI_ZARQ` | C(100) | Nome do arquivo original |
| `TRI_ZPATH` | C(254) | Caminho no servidor (`\sinistros\anexos\<filial>\<numsin>\`) |
| `TRI_ZMIME` | C(40) | Content-type |
| `TRI_ZTAM` | N(12,0) | Tamanho em bytes (**limite 100 MB/arquivo**, validado no front e no backend) |

### 3.3 SX5 `SP` (Status) e TRU (tipos de anexo) — criar via `MNTA540Tab.prw`
- SX5 `SP`: os 7 códigos da decisão 0.8.
- TRU (se optar por classificar anexo pelo cadastro nativo): `0001`=Foto do
  acidente, `0002`=Termo, `0003`=Contrato, `0004`=Boletim de ocorrência, `0005`=Nota fiscal.

---

## 4. Importação (`sinistros 2026.csv`)

### 4.1 Leitura
`;` separador · **CP1252/ANSI** (não converter) · descarta linhas cujo campo 0
comece com `NUMERO` (cabeçalho repetido) e linhas vazias · **99 registros** ·
coluna UNIDADE ignorada → tudo em `cFilAnt`.

### 4.2 De‑para do bem (placa **ou** série → `TRH_CODBEM`)
1. Normaliza col. 3 (remove espaço/ponto/traço, caixa alta).
2. `ST9` (`T9_CATBEM` in `'2','4'`), na filial logada e depois em qualquer:
   `T9_PLACA` → se não achar, `T9_SERIE`.
3. Achou com `T9_PLACA` preenchida → veículo → `TRH_EVENTO='1'`; achou só por
   série → equipamento → `TRH_EVENTO='3'`.
4. Não achou → pula; registra em `erros[]` `{linha, numeroFor, placa, motivo}`.

### 4.3 Culpabilidade (col. 10 — texto livre)
| Valor | `TRH_ZCULPA` | `TRH_ZCLPNM` |
|-------|-------------|-------------|
| `QUEBEC` | `2` | "QUEBEC" |
| `TERCEIRO` | `1` | nome do motorista terceiro |
| `FORÇA MAIOR`, `NÃO TEM` | `4` | valor original |
| = condutor Quebec (col. 5) | `3` | nome |
| = motorista terceiro (col. 8) | `1` | nome |
| outro (ex.: "ESTA EM VOTAÇÃO NO COMITE") | `9` | valor original |

### 4.4 Defaults dos obrigatórios do TRH sem origem na planilha
SX3 já traz `init` para `GRAVID/TEMPO/VIA/PERIOD/VIADIR='1'` e
`INTERR/GUINCH/CONDEL/TEREVA/FLGDAN='2'`. Faltam:
`TRH_HRACID="00:00"` · `TRH_LOCAL="IMPORTADO PLANILHA"` · `TRH_UFACID`=UF da filial ·
`TRH_FLGDAN="2"` (garante OS desligada) · `TRH_DESCRI`=col. 17 ou texto padrão.

### 4.5 Gravação e idempotência
- `TRH`: `GetSXENum` → `RecLock` → campos + defaults + `TRH_Z*` → `MsUnLock` → `ConfirmSX8`.
- Filhas TRO/TRN gravadas na sequência com o `TRH_NUMSIN` gerado (`TRO_SEQVEI`/`TRN_SEQTES` sequenciais).
- Monetário: remove `R$`, `.` de milhar e espaços; `-` → `0`.
- **Idempotência**: `TRH_ZIMPKEY` = hash de `NUMERO_FOR + DATA + PLACA/SÉRIE + CPF`.
  Reimport pula linhas já gravadas (conta como "duplicada").
- `sinistroImportarSimular` → prévia linha a linha, sem gravar.
- `sinistroImportar` → transação; retorna `{ importados, duplicados, erros[] }`.

---

## 5. Estrutura de pastas

```
frotas/sinistro/
├── CRONOGRAMA.md
├── dicionario.md            (Fase A — campos custom, SX5 'SP', TRU, mapa final)
├── MNTA540Tab.prw           (Fase A — cria campos custom + SX5 + TRU)
├── MNTA540App.prw           (Fase B — U_MNTA540App() + JsToAdvpl + Do Case)
└── resource/frtsin001.app   (Fase F — build Angular empacotado)

POUI/frtsin001/              (Fase D — cópia do esqueleto de POUI/estmvc001)
├── src/app/services/advpl-bridge.service.ts      (IDÊNTICO ao estmvc001)
├── src/app/services/protheus-bridge.service.ts   (IDÊNTICO ao estmvc001)
├── src/app/services/sinistro.service.ts
├── src/app/models/sinistro.model.ts
├── src/app/pages/sinistro-list/
├── src/app/pages/sinistro-editor/    (abas Sinistro / Veículos / Testemunhas / Vítimas / Anexos)
├── src/app/pages/sinistro-import/    (wizard: arquivo → simulação → efetivar → relatório)
└── public/assets/preload/advpltojs.js  (OBRIGATÓRIO — sem ele o canal trava sem erro)
```

---

## 6. Padrão POUI (sem REST — confirmado com `estmvc001`)

- `advpl-bridge.service.ts` / `protheus-bridge.service.ts` **copiados sem alteração** de `POUI/estmvc001`.
- Front: `this.advplBridge.call<T>(type, payload)` → `ProJsToAdvplService.buildObservable`
  envia `{ ...payload, receiveId }` como `content`; ADVPL responde
  `oWebChannel:AdvplToJs(cReceiveId, oResp:toJson())`. `receiveId` embutido no JSON.
- `app.config.ts`: `provideRouter(routes, withHashLocation())`; sem REST de dados.
- `public/assets/preload/advpltojs.js` precisa existir e ser copiado no build.

### Operações do canal `JsToAdvpl` (`MNTA540App.prw`) — mesmo `Do Case` do `RTM003App.prw`

| type | função | uso |
|------|--------|-----|
| `sinistroListar` | `ZsiList` | grid (filtros: período, placa/bem, evento, culpabilidade, status) |
| `sinistroDetalhe` | `ZsiDet` | TRH + TRO + TRN + TRM + TRI |
| `sinistroCriar` / `sinistroAtualizar` | `ZsiCriar` / `ZsiAtu` | manutenção da TRH |
| `veiculoSalvar` / `veiculoRemover` | `ZsiVei*` | aba Veículos (TRO) |
| `testemunhaSalvar` / `testemunhaRemover` | `ZsiTes*` | aba Testemunhas (TRN) |
| `vitimaSalvar` / `vitimaRemover` | `ZsiVit*` | aba Vítimas (TRM) |
| `anexoUpload` / `anexoListar` / `anexoDownload` / `anexoRemover` | `ZsiAnx*` | aba Anexos (TRI) |
| `sinistroImportarSimular` / `sinistroImportar` | `ZsiImpSim` / `ZsiImp` | wizard |
| `lookupBem` | `ZsiLkBem` | ST9 por placa/série/descrição (`T9_CATBEM` in 2,4) |
| `lookupFuncionario` | `ZsiLkFunc` | SRA por matrícula/nome |
| `lookupDominio` | `ZsiLkDom` | domínios fixos + SX5 (`AF`/`CX`/`SP`/`12`) |

---

## 7. Cronograma

| Fase | Atividades | Depende de | Estimativa |
|------|-----------|-----------|-----------|
| **0 · Preparação** | ✅ pasta, docs e SX3 (TRH + 5 filhas) analisados; ✅ todas as decisões fechadas (§0) | — | concluída |
| **A · Modelagem** | ✅ `dicionario.md` + `MNTA540Tab.prw` (`U_MNT540Tab()` — campos custom TRH/TRO/TRI + SX5 `SP` + TRU + `X31UpdTable`) | Fase 0 | concluída |
| **B · Backend base** | ✅ `MNTA540App.prw`: `U_MNTA540App()` + `JsToAdvpl` (Do Case, 15 ops); `ZsiList/ZsiDet/ZsiMont/ZsiCriar/ZsiAtu`; filhas `ZsiVei*/ZsiTes*/ZsiVit*` (RecLock direto em TRO/TRN/TRM); lookups `ZsiLkBem/ZsiLkFunc/ZsiLkDom`; `ZsiBemPorChave` (de-para placa/série); imports = stub p/ Fase C | Fase A | concluída |
| **C · Importação** ⭐ | ✅ `ZsiImpProc` (parser CSV `;`/CP1252 via `ZsiSplit` que preserva campos vazios; `ZsiImpConteudo` aceita `conteudoBase64`/`conteudo`); `ZsiImpLinha` (de-para bem, evento 1/3, `ZsiClassCulpa`, `ZsiDeParaStatus`, `ZsiParseData`/`ZsiParseMoeda`, `ZsiSemAcento`); `ZsiImpKey` (MD5) + `ZsiJaImportado` (idempotência `TRH_ZIMPKEY`); `ZsiImpSim` (prévia) / `ZsiImp` (efetiva via `ZsiCriarCore` + TRO Quebec/terceiro + TRN do TST); relatório `{resumo, linhas, erros}` | Fase B | concluída |
| **D · Frontend PO-UI** | ✅ `POUI/frtsin001` (Angular 19; esqueleto = cópia fiel de `POUI/estmvc001` — `advpl-bridge.service.ts` + `protheus-bridge.service.ts` + `public/assets/preload/advpltojs.js` verbatim); `sinistro.model.ts` + `sinistro.service.ts` (contrato §7.1); `sinistro-list` (filtros + busca avançada); `sinistro-editor` (`po-tabs`: Sinistro / Veículos / Testemunhas / Vítimas / Anexos + modais de CRUD das filhas + busca de bem); `sinistro-import` (`po-stepper`: arquivo → simulação `po-table` → resultado) | Fase B | concluída |
| **E · Anexos (TRI)** | `ZsiAnx*` (base64 → `\sinistros\anexos\...`, campos `TRI_Z*`); `po-upload` na aba Anexos com filtro por tipo | Fases A, D | 1,5 dia |
| **F · Teste SmartClient + ajustes** | empacotar `frtsin001.app`; menu no módulo 95; `U_MNTA540App()`; importar a planilha na filial de teste; sinistro manual; anexar foto; corrigir bugs do 1º teste | Fases C, D, E | 1,5 dia |

**Total: ~12 dias úteis** (sequencial). Fases C e D em paralelo após a Fase B → **~9 dias**.

---

## 7.1 Status

Fases 0, A, B, C, **D** concluídas. `frotas/sinistro/{dicionario.md, MNTA540Tab.prw,
MNTA540App.prw}` + `POUI/frtsin001/` (**build `ng build` OK** — validado com as
dependências do `rtm003`; `dist/.../assets/preload/advpltojs.js` presente).
Pré-requisito para compilar o ADVPL: rodar `U_MNT540Tab()` antes.
Para o frontend: `cd POUI/frtsin001 && npm install && npm run build`.

**Próximo passo: Fase E** (anexos TRI: `ZsiAnx*` + `po-upload`) e **Fase F**
(empacotar `resource/frtsin001.app`, item de menu no módulo 95, `U_MNTA540App()`,
1º teste em SmartClient — o padrão do projeto é o 1º teste real achar 2-3 ajustes).

<!-- histórico da definição de escopo abaixo -->
### (planejamento) Fase D — projeto Angular `POUI/frtsin001` (cópia do esqueleto de
`POUI/estmvc001`: `advpl-bridge.service.ts` + `protheus-bridge.service.ts` +
`advpltojs.js` sem alteração; `sinistro.model.ts` / `sinistro.service.ts`; páginas
`sinistro-list`, `sinistro-editor` com abas, `sinistro-import` wizard). É o que
libera o 1º teste em SmartClient (Fase F).

### Contrato do canal (para o `sinistro.service.ts`)
Todas as ops respondem `{success, ...}` ou `{success:false, message}`.
- `sinistroListar {numero?,dataDe?,dataAte?,placa?,evento?,culpabilidade?,status?}` → `{sinistros:[...]}`
- `sinistroDetalhe {numero}` → `{sinistro:{...,veiculos,testemunhas,vitimas,anexos}}`
- `sinistroCriar {sinistro,veiculos?,testemunhas?,vitimas?}` → `{sinistro}`
- `sinistroAtualizar {sinistro:{numero,...}}` → `{sinistro}`
- `veiculoSalvar {numero,veiculo:{seq?,...}}` / `veiculoRemover {numero,seq}`
- `testemunhaSalvar {numero,testemunha}` / `testemunhaRemover {numero,seq}`
- `vitimaSalvar {numero,vitima}` / `vitimaRemover {numero,seq}`
- `lookupBem {filtro}` → `{items:[{codigo,nome,placa,serie,catbem,tipo}]}`
- `lookupFuncionario {filtro}` → `{items:[{matricula,nome,centroCusto}]}`
- `lookupDominio {dominio}` → `{items:[{valor,label}]}` (dominios: evento, gravidade,
  tempo, via, periodo, viadir, simnao, culpa, fonte, origveic, tpanexo, status, uf,
  tipoevento, causa)
- `sinistroImportarSimular {conteudoBase64}` / `sinistroImportar {conteudoBase64}` →
  `{efetivado, totalLinhas, resumo:{paraCriar,duplicadas,comErro,importadas}, linhas:[...], erros:[...], numeros?:[...]}`
- `configParametrizar {}` → `{success, message, log:[...]}` — roda `U_MNT540Tab(.T.)` no servidor
  (cria campos custom + SX5 `SP` + TRU). Tela **Configuração** (rota `sinistros/configuracao`,
  botão na lista). `U_MNT540Tab` foi refatorada: aceita `lSilent` e retorna o log linha a linha.
- (Fase E) `anexoUpload/Listar/Download/Remover`
