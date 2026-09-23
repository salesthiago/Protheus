# Sincronizador Aterro - Quebec Ambiental

Aplicativo de bandeja do Windows que sincroniza pesagens (NJH), veículos (DA3) e
fornecedores (NJ0) do banco de origem local com a API REST do Protheus de
produção (`/APIAterro/...`).

## O que o aplicativo faz

- Roda em segundo plano, com ícone na bandeja do sistema.
- A cada ciclo (padrão: 5 min), busca pesagens **finalizadas** (`NJH_STATUS = '2'`)
  ainda não enviadas e faz o POST para a API de produção.
- Reverifica pesagens **já sincronizadas** nos últimos N dias (padrão: 30) para
  detectar alterações feitas depois do envio (ex.: status mudou, peso foi
  corrigido) e replica a alteração em produção via um endpoint de atualização.
- Guarda o histórico de sincronização localmente em `sync_state.sqlite`
  (na mesma pasta do `config.yaml`) — não depende só do campo `NJH_XSINC`.

### Telas (clique com o botão direito no ícone da bandeja)

| Item do menu | O que faz |
| --- | --- |
| **Executar Agora** | Força um ciclo de sincronização imediatamente |
| **Ativar/Desativar** | Liga/desliga o sincronizador sem fechar o app |
| **Ver Sincronização...** | Lista as pesagens e a situação de cada uma (Pendente / Sincronizado / Alterado / Erro / Não finalizado). Permite editar um registro (grava direto na tabela NJH de origem) e reenviar na hora, ou apenas clicar "Sincronizar agora" |
| **Ver Log** | Abre o arquivo de log no bloco de notas |
| **Configurar...** | Abre o formulário de configuração (edita o `config.yaml` sem precisar editar o YAML na mão) |
| **Sair** | Encerra o aplicativo |

## Requisitos

- Windows 10/11.
- Python 3.10+ (só necessário para rodar em modo desenvolvimento ou para compilar;
  o `.exe` gerado já é autônomo e não exige Python instalado na máquina destino).
- Driver do banco de origem conforme `source_db.type` no `config.yaml`:
  SQL Server → ODBC Driver 17/18; PostgreSQL/MySQL não precisam de driver de SO.

## Rodando em modo desenvolvimento

```powershell
cd "Aterro\sync_python"
python -m pip install -r requirements.txt
python tray_app.py          # com ícone na bandeja, telas de config/sincronização
python main.py               # loop contínuo sem bandeja (mesma lógica de sync)
python main.py --once        # executa um único ciclo e encerra (bom para testar)
```

Antes de rodar, ajuste o `config.yaml` (ou use a tela **Configurar...** depois de
abrir `tray_app.py` uma vez) com os dados reais do banco de origem e da API.

## Compilando o `.exe`

### Opção 1 — script pronto

```powershell
cd "Aterro\sync_python"
.\build.bat
```

Ele instala as dependências, gera `app.ico` a partir de `logo.png` (se existir),
compila com PyInstaller e deixa tudo pronto em `dist\`:

- `dist\SyncAterro.exe`
- `dist\config.yaml` (cópia do config.yaml da raiz do projeto)
- `dist\logs\`

### Opção 2 — manual

```powershell
cd "Aterro\sync_python"
python -m pip install -r requirements.txt
python -m pip install pyinstaller
python -m PyInstaller sync_aterro.spec --noconfirm
copy config.yaml dist\config.yaml
mkdir dist\logs
```

> **Importante:** o `sync_aterro.spec` inclui o `tkinter` no build (é usado
> pelas telas de Configurações e Sincronização). Não remova `tkinter` da lista
> `excludes` do `.spec` — sem ele o `.exe` sobe o ícone na bandeja mas quebra
> ao tentar abrir qualquer uma das duas telas.

Depois de compilar, **copie a pasta `dist\` inteira** (não só o `.exe`) para o
local definitivo, por exemplo `C:\SyncAterro\`. O `.exe` procura o
`config.yaml`, a pasta `logs\` e o `sync_state.sqlite` sempre ao lado dele
próprio — não importa de onde ele for iniciado (duplo clique, atalho, tarefa
agendada), então não existe um "diretório de trabalho" especial a configurar.

## Colocando na Inicialização do Windows

Depois de copiar a pasta `dist\` para o local definitivo (ex.: `C:\SyncAterro\`):

**Passo a passo (manual):**

1. Pressione `Win + R`, digite `shell:startup` e Enter — abre a pasta de
   Inicialização do usuário atual.
2. Clique com o botão direito dentro dela → **Novo → Atalho**.
3. Em "Digite o local do item", cole o caminho completo do executável:
   ```
   C:\SyncAterro\SyncAterro.exe
   ```
4. Dê um nome (ex.: `Sincronizador Aterro`) e finalize.

O aplicativo passará a abrir automaticamente (minimizado na bandeja) sempre
que o usuário fizer login no Windows.

**Alternativa — criar o atalho via PowerShell** (rode uma vez, ajustando o
caminho do `.exe` se for diferente):

```powershell
$exe = "C:\SyncAterro\SyncAterro.exe"
$linkPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Sincronizador Aterro.lnk"

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($linkPath)
$shortcut.TargetPath = $exe
$shortcut.WorkingDirectory = Split-Path $exe
$shortcut.IconLocation = $exe
$shortcut.Description = "Sincronizador Aterro - Quebec Ambiental"
$shortcut.Save()
```

`$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\` é a mesma pasta
que `shell:startup` abre — o script só automatiza a criação do atalho.

Para **remover** da inicialização, apague o arquivo `.lnk` dessa pasta (ou
delete o atalho pela mesma tela do `shell:startup`).

## Estrutura de arquivos (pasta `dist\`, produção)

```
SyncAterro.exe        # executável (não precisa de Python instalado)
config.yaml           # configuração (edite pela tela "Configurar..." ou manualmente)
sync_state.sqlite      # criado automaticamente — histórico local de sincronização
logs\
  sync_aterro.log      # log rotativo (10 MB x 5 arquivos, configurável)
```

## Solução de problemas

- **"Falha ao conectar no banco de origem"**: confira `source_db` no
  `config.yaml` (tipo do banco, host, credenciais) pela tela **Configurar...**
  ou editando o arquivo diretamente.
- **Nada aparece na bandeja**: confira `logs\sync_aterro.log` — se o processo
  morreu na inicialização, o motivo estará lá.
- **Um registro não sincroniza**: abra **Ver Sincronização...**, procure o
  ticket na lista — a coluna "Sincronização" explica a situação (ex.:
  "Não finalizado" significa que `NJH_STATUS` ainda não é `2`).
