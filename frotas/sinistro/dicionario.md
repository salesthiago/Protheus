# Sinistros de Frota — Dicionário (Fase A)

Campos de usuário, tabela de status (SX5 `SP`) e tipos de anexo (TRU) necessários
para o `frtsin001` / `MNTA540App.prw`. Tudo é criado pelo programa
[`MNTA540Tab.prw`](MNTA540Tab.prw) (`U_MNT540Tab()`) — ou pode ser importado pelo
Configurador usando os atributos abaixo.

Convenção: prefixo **`_Z`** em campo de tabela padrão (TOTVS) e **`_Z` + livre** —
`X3_PROPRI = 'U'` (usuário), `X3_CONTEXT = 'R'` (real).

---

## 1. Campos novos em **TRH** (Sinistro — cabeçalho)

| Campo | Tipo | Tam | Dec | Título | Descrição | Domínio / F3 / Picture |
|-------|------|-----|-----|--------|-----------|------------------------|
| `TRH_ZCULPA` | C | 1 | 0 | Culpabilid. | Culpabilidade do sinistro | Combo `1=Terceiro;2=Empresa;3=Funcionario;4=Forca Maior/Sem Culpa;9=A Apurar` |
| `TRH_ZCLPNM` | C | 60 | 0 | Nome Culpado | Nome do responsavel apontado como culpado | Picture `@!` |
| `TRH_ZNRFOR` | C | 6 | 0 | Nr. FOR | Numero do FOR na planilha de origem | Picture `@!` |
| `TRH_ZVLFOL` | N | 14 | 2 | Vlr. Folha | Valor lancado em folha (somente registro) | `@E 99,999,999,999.99` |
| `TRH_ZVLSLD` | N | 14 | 2 | Vlr. Saldo | Saldo a descontar (somente registro) | `@E 99,999,999,999.99` |
| `TRH_ZIMPKEY`| C | 40 | 0 | Chave Import | Hash da linha de origem (idempotencia da importacao) | Picture `@!` — `X3_INIBRW='S'` |
| `TRH_ZFONTE` | C | 1 | 0 | Origem Reg. | Origem do registro | Combo `I=Importacao;M=Manual` — init `'M'` |

## 2. Campos novos em **TRO** (Veículos envolvidos)

| Campo | Tipo | Tam | Dec | Título | Descrição | Domínio / F3 |
|-------|------|-----|-----|--------|-----------|--------------|
| `TRO_ZORIG` | C | 1 | 0 | Orig. Veic. | Origem do veiculo envolvido | Combo `1=Quebec;2=Terceiro` — init `'2'` |
| `TRO_ZMAT`  | C | 6 | 0 | Matr. Cond. | Matricula do condutor quando funcionario Quebec | F3 `SRA` — `X3_WHEN` `M->TRO_ZORIG=='1'` |

## 3. Campos novos em **TRI** (Anexos / Documentos)

TRI padrão só registra "documento recebido"; estes campos guardam o arquivo físico.

| Campo | Tipo | Tam | Dec | Título | Descrição | Domínio |
|-------|------|-----|-----|--------|-----------|---------|
| `TRI_ZTIPO` | C | 1 | 0 | Tp. Anexo | Tipo do anexo | Combo `1=Foto;2=Termo;3=Contrato;4=BO;5=Nota Fiscal;9=Outros` |
| `TRI_ZARQ`  | C | 100 | 0 | Arquivo | Nome do arquivo original | `@!` |
| `TRI_ZPATH` | C | 254 | 0 | Caminho | Caminho no servidor (`\sinistros\anexos\<filial>\<numsin>\`) | `@!` — `X3_INIBRW='S'` |
| `TRI_ZMIME` | C | 40 | 0 | Mime | Content-type do arquivo | `@!` |
| `TRI_ZTAM`  | N | 12 | 0 | Tam. Bytes | Tamanho em bytes (limite 100 MB = 104857600) | `@E 999,999,999,999` |

> `X31UpdTable("TRH")`, `X31UpdTable("TRO")` e `X31UpdTable("TRI")` ao final, para
> materializar as colunas no banco.

---

## 4. SX5 — tabela `SP` (Status do Processo do Sinistro)

`TRH_STATUS` (C2, `X3_F3` já aponta para SX5 `SP`, init `'01'`).

| Chave | Descrição (PT) |
|-------|----------------|
| `01` | ABERTURA |
| `02` | AGUARDANDO DOCUMENTACAO |
| `03` | ABERTURA DE INQUERITO |
| `04` | JURIDICO |
| `05` | NEGOCIACAO |
| `06` | ARQUIVADO |
| `07` | CANCELADO |

De-para do STATUS da planilha → `TRH_STATUS`:

| Planilha (coluna 16) | `TRH_STATUS` |
|----------------------|--------------|
| *(vazio)* | `01` ABERTURA |
| `FAZENDO TERMO DE ACORDO` | `05` NEGOCIACAO |
| `FINALIZADO` | `06` ARQUIVADO |

---

## 5. TRU — Tipos de documento de anexo (opcional, para `TRI_CODDOC`)

Usados só se optarmos por classificar o anexo também pelo cadastro nativo
(além de `TRI_ZTIPO`). `TRU_TIPEVE='1'` (genérico).

| `TRU_CODDOC` | `TRU_NOMDOC` |
|--------------|-------------|
| `000001` | FOTO DO ACIDENTE |
| `000002` | TERMO |
| `000003` | CONTRATO |
| `000004` | BOLETIM DE OCORRENCIA |
| `000005` | NOTA FISCAL |

---

## 6. Mapa consolidado: planilha `sinistros 2026.csv` → tabelas

`;` · CP1252 · 99 registros · descartar linhas com campo 0 iniciando por `NUMERO`
e linhas vazias · **coluna 2 (UNIDADE) ignorada** → grava em `cFilAnt`.

| # | Coluna CSV | Tabela.Campo | Observação |
|---|-----------|--------------|------------|
| 0 | NUMERO DO FOR | `TRH_ZNRFOR` | — |
| 1 | DATA DO SINISTRO | `TRH_DTACID` | `dd/mm/aaaa` → Date |
| 2 | UNIDADE | — | ignorada |
| 3 | PLACA VEICULO OU Nº SERIE | `TRH_CODBEM`, `TRH_PLACA`, `TRH_NOMBEM` | busca ST9 (`T9_CATBEM` in 2,4): `T9_PLACA`→`T9_SERIE`; não achou = pula + relatório |
| 3 | (achou por placa) | `TRH_EVENTO='1'` | veículo = Acidente |
| 3 | (achou só por série) | `TRH_EVENTO='3'` | equipamento = Incidente |
| 4 | CARRO DA QUEBEC | `TRO(001).TRO_DESVEI` | descrição; confere vs `T9_NOME` |
| 5 | NOME DO CONDUTOR QUEBEC | `TRO(001).TRO_MOTVEI` | veículo Quebec |
| 6 | MATRICULA | `TRO(001).TRO_ZMAT` | busca SRA; nome do SRA reforça `TRO_MOTVEI` |
| — | origem Quebec | `TRO(001).TRO_ZORIG='1'` | — |
| 7 | CPF: TERCEIRO | `TRO(002).TRO_CPF` | só cria TRO(002) se houver placa/CPF de terceiro |
| 8 | NOME DO MOTORISTA TERCEIRO | `TRO(002).TRO_MOTVEI`, `TRO_NOMPR` | — |
| 9 | PLACA DO TERCEIRO | `TRO(002).TRO_PLACA` | — |
| — | origem terceiro | `TRO(002).TRO_ZORIG='2'`, `TRO_DANOS='1'` | — |
| 10 | CULPABILIDADE | `TRH_ZCULPA` + `TRH_ZCLPNM` | heurística (§4.4 do CRONOGRAMA) |
| 11 | TST | `TRN(001).TRN_NOMTES` + `TRN_QLFTES='TST'` | só se preenchida |
| 12 | VALOR A SER PAGO AO TERCEIRO | `TRO(002).TRO_VALTER` | **campo nativo** |
| 13 | ACIDENTE INTERNO | — | sempre vazia |
| 14 | EM FOLHA | `TRH_ZVLFOL` | só registro |
| 15 | SALDO A DESCONTAR | `TRH_ZVLSLD` | só registro |
| 16 | STATUS | `TRH_STATUS` | de-para §4 |
| 17 | OBSERVACAO | `TRH_DESCRI` | memo (`TRH_MMSYP`) |

### Defaults dos obrigatórios do TRH sem origem na planilha
SX3 já inicializa `GRAVID/TEMPO/VIA/PERIOD/VIADIR='1'` e
`INTERR/GUINCH/CONDEL/TEREVA/FLGDAN='2'`. Complementar na carga:
`TRH_HRACID='00:00'` · `TRH_LOCAL='IMPORTADO PLANILHA'` · `TRH_UFACID`=UF da filial ·
`TRH_FLGDAN='2'` (OS desligada) · `TRH_DESCRI`=col.17 ou `'Importado da planilha sinistros 2026'` ·
`TRH_ZFONTE='I'` · `TRH_ZIMPKEY`=hash(`NUMERO_FOR+DATA+PLACA/SERIE+CPF`).

### Numeração
`TRH_NUMSIN` via `GetSXENum('TRH','TRH_NUMSIN')` + `ConfirmSX8()` / `RollBackSX8()`
(mesma técnica de `RTM003App.prw`). `TRO_SEQVEI` / `TRN_SEQTES` sequenciais por sinistro.
