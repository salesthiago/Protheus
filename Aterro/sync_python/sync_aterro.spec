# -*- mode: python ; coding: utf-8 -*-
# PyInstaller spec — Sincronizador Aterro Quebec
# Gera um único .exe sem janela de console, com ícone embutido.

block_cipher = None

a = Analysis(
    ['tray_app.py'],
    pathex=[],
    binaries=[],
    datas=[
        ('app.ico', '.'),           # ícone embutido (acessado via sys._MEIPASS)
    ],
    hiddenimports=[
        'pystray._win32',
        'PIL._imaging',
        'PIL.Image',
        'PIL.ImageDraw',
        'PIL.ImageFont',
        'yaml',
        'requests',
        # SQL Server
        'pyodbc',
        # PostgreSQL
        'psycopg2',
        'psycopg2.extras',
        'psycopg2.extensions',
        # MySQL / MariaDB
        'pymysql',
        'pymysql.connections',
        'pymysql.cursors',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        # tkinter NAO pode ser excluido: as telas de Configuracoes e de
        # Sincronizacao (gui.py) dependem dele.
        'matplotlib',
        'numpy',
        'scipy',
        'pandas',
    ],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='SyncAterro',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,                 # UPX pode causar falsos positivos em antivírus
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,             # sem janela de console
    disable_windowed_traceback=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='app.ico',
)
