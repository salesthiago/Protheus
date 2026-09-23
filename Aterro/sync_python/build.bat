@echo off
setlocal

echo ============================================================
echo  Build - Sincronizador Aterro Quebec Ambiental
echo ============================================================
echo.

set PYTHON_EXE=

python --version >nul 2>&1
if not errorlevel 1 (
    set PYTHON_EXE=python
    goto :python_found
)

py --version >nul 2>&1
if not errorlevel 1 (
    set PYTHON_EXE=py
    goto :python_found
)

for /d %%D in ("%LOCALAPPDATA%\Python\pythoncore*") do (
    if exist "%%D\python.exe" (
        set "PYTHON_EXE=%%D\python.exe"
        goto :python_found
    )
)

for /d %%D in ("%LOCALAPPDATA%\Programs\Python\Python*") do (
    if exist "%%D\python.exe" (
        set "PYTHON_EXE=%%D\python.exe"
        goto :python_found
    )
)

echo ERRO: Python nao encontrado. Instale Python 3.10+ e tente novamente.
pause
exit /b 1

:python_found
echo Python: %PYTHON_EXE%
echo.

echo Encerrando instancia anterior do SyncAterro (se estiver rodando)...
taskkill /F /IM SyncAterro.exe >nul 2>&1
timeout /t 2 /nobreak >nul

echo [1/4] Instalando dependencias...
"%PYTHON_EXE%" -m pip install -r requirements.txt --quiet
if errorlevel 1 (
    echo ERRO ao instalar dependencias
    pause
    exit /b 1
)
"%PYTHON_EXE%" -m pip install pyinstaller --quiet
if errorlevel 1 (
    echo ERRO ao instalar PyInstaller
    pause
    exit /b 1
)

echo [2/4] Gerando icone...
if exist "logo.png" (
    "%PYTHON_EXE%" make_icon.py
) else (
    echo AVISO: logo.png nao encontrado.
)

echo [3/4] Compilando executavel...
if exist "app.ico" (
    "%PYTHON_EXE%" -m PyInstaller sync_aterro.spec --noconfirm
) else (
    "%PYTHON_EXE%" -m PyInstaller tray_app.py --onefile --noconsole --name SyncAterro --hidden-import pystray._win32 --hidden-import PIL._imaging --hidden-import psycopg2 --hidden-import pymysql --noconfirm
)
if errorlevel 1 (
    echo ERRO: Falha na compilacao
    pause
    exit /b 1
)

echo [4/4] Preparando distribuicao...
copy /Y config.yaml dist\config.yaml >nul 2>&1
if not exist "dist\logs" mkdir "dist\logs"

echo.
echo ============================================================
echo  BUILD CONCLUIDO!
echo  Executavel : dist\SyncAterro.exe
echo  Config     : dist\config.yaml
echo  Logs       : dist\logs\
echo ============================================================
echo.
pause