"""
Sincronizador Aterro - Quebec Ambiental
Ponto de entrada do executável com ícone na bandeja do sistema.
"""

import sys
import threading
import os
import tkinter as tk
from pathlib import Path

import pystray
import yaml
from PIL import Image

from gui import ConfigWindow, SyncStatusWindow
from logger_setup import setup_logger
from sync_manager import SyncManager


# ---------------------------------------------------------------------------
# Utilitários de caminho — funciona tanto em .py quanto em .exe (PyInstaller)
# ---------------------------------------------------------------------------

def _exe_dir() -> Path:
    """Pasta onde o .exe reside (ou pasta do script em desenvolvimento)."""
    if getattr(sys, "frozen", False):
        return Path(sys.executable).parent
    return Path(__file__).parent


def _resource(filename: str) -> Path:
    """Recurso embutido no .exe pelo PyInstaller."""
    if getattr(sys, "frozen", False):
        return Path(sys._MEIPASS) / filename  # type: ignore[attr-defined]
    return Path(__file__).parent / filename


# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------

class SyncTrayApp:
    def __init__(self):
        self._stop_event = threading.Event()
        self._manual_trigger = threading.Event()
        self._lock = threading.Lock()
        self._icon: pystray.Icon | None = None
        self._config: dict = {}
        self._logger = None
        self._sync_thread: threading.Thread | None = None
        self._base_dir = _exe_dir()

        # Janela oculta que mantém o mainloop do Tkinter vivo na thread
        # principal. As janelas de configuração/sincronização são abertas
        # como Toplevel dela, sempre agendadas via self._root.after(0, ...)
        # a partir dos callbacks do ícone (que rodam em outra thread).
        self._root = tk.Tk()
        self._root.withdraw()
        self._config_window: tk.Toplevel | None = None
        self._status_window: tk.Toplevel | None = None

        self._reload_config()
        self._logger = setup_logger(self._config["log"], self._base_dir)
        self._logger.info("Sincronizador Aterro iniciado.")

    # ------------------------------------------------------------------
    # Config
    # ------------------------------------------------------------------

    def _reload_config(self):
        path = self._base_dir / "config.yaml"
        with open(path, encoding="utf-8") as f:
            self._config = yaml.safe_load(f)

    def _save_config(self):
        path = self._base_dir / "config.yaml"
        with open(path, "w", encoding="utf-8") as f:
            yaml.dump(self._config, f, allow_unicode=True, default_flow_style=False)

    def _is_enabled(self) -> bool:
        return bool(self._config.get("enabled", True))

    # ------------------------------------------------------------------
    # Menu dinâmico
    # ------------------------------------------------------------------

    def _status_text(self, item) -> str:
        return "● Ativo" if self._is_enabled() else "○ Inativo"

    def _toggle_text(self, item) -> str:
        return "Desativar" if self._is_enabled() else "Ativar"

    def _build_menu(self) -> pystray.Menu:
        return pystray.Menu(
            pystray.MenuItem(self._status_text, None, enabled=False),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("Executar Agora", self._on_run_now),
            pystray.MenuItem(self._toggle_text, self._on_toggle),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("Ver Sincronização...", self._on_open_status),
            pystray.MenuItem("Ver Log", self._on_open_log),
            pystray.MenuItem("Configurar...", self._on_open_config),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("Sair", self._on_exit),
        )

    # ------------------------------------------------------------------
    # Ações do menu
    # ------------------------------------------------------------------

    def _on_run_now(self, icon, item):
        self._manual_trigger.set()

    def _on_toggle(self, icon, item):
        with self._lock:
            self._reload_config()
            self._config["enabled"] = not self._is_enabled()
            self._save_config()
            state = "ATIVADO" if self._is_enabled() else "DESATIVADO"
            self._logger.info(f"Sincronizador {state} pelo usuário.")

    def _on_open_log(self, icon, item):
        log_dir = self._config["log"].get("directory", "logs")
        log_file = self._config["log"].get("filename", "sync_aterro.log")
        path = self._base_dir / log_dir / log_file
        if path.exists():
            os.startfile(str(path))
        else:
            self._logger.warning("Arquivo de log não encontrado.")

    def _on_open_config(self, icon, item):
        # Callback do pystray roda em outra thread; agenda a criação da
        # janela Tkinter para rodar com segurança na thread do mainloop.
        self._root.after(0, self._show_config_window)

    def _show_config_window(self):
        with self._lock:
            self._reload_config()

        if self._config_window is not None and self._config_window.winfo_exists():
            self._force_foreground(self._config_window)
            return

        def _on_saved():
            with self._lock:
                self._reload_config()
            self._manual_trigger.set()  # aplica mudanças (ex.: ativar/desativar) já no próximo ciclo

        self._config_window = ConfigWindow(self._root, self._base_dir / "config.yaml", on_saved=_on_saved)
        self._force_foreground(self._config_window)

    def _on_open_status(self, icon, item):
        self._root.after(0, self._show_status_window)

    def _show_status_window(self):
        if self._status_window is not None and self._status_window.winfo_exists():
            self._force_foreground(self._status_window)
            return

        with self._lock:
            self._reload_config()
        self._status_window = SyncStatusWindow(self._root, self._config, self._logger, self._base_dir)
        self._force_foreground(self._status_window)

    @staticmethod
    def _force_foreground(win: tk.Toplevel):
        # Janelas criadas a partir do callback do icone da bandeja (thread em
        # segundo plano) costumam abrir atras da janela em foco: o Windows
        # bloqueia processos em segundo plano de "roubar" o foco. Alternar
        # -topmost contorna essa restricao e garante que o usuario veja a
        # janela.
        win.deiconify()
        win.lift()
        win.attributes("-topmost", True)
        win.after(150, lambda: win.attributes("-topmost", False))
        win.focus_force()

    def _on_exit(self, icon, item):
        self._logger.info("Encerrando Sincronizador Aterro.")
        self._stop_event.set()
        self._manual_trigger.set()  # desbloqueia a espera no loop
        icon.stop()
        self._root.after(0, self._root.quit)

    # ------------------------------------------------------------------
    # Loop de sincronização (thread separada)
    # ------------------------------------------------------------------

    def _sync_loop(self):
        while not self._stop_event.is_set():
            try:
                with self._lock:
                    self._reload_config()

                if self._is_enabled():
                    manager = SyncManager(self._config, self._logger, self._base_dir)
                    manager.run_sync_cycle()
                else:
                    self._logger.debug("Sincronizador inativo, pulando ciclo.")

            except Exception:
                self._logger.error("Erro no ciclo de sincronização", exc_info=True)

            interval = self._config.get("sync", {}).get("interval_seconds", 300)
            self._manual_trigger.wait(timeout=interval)
            self._manual_trigger.clear()

    # ------------------------------------------------------------------
    # Execução principal
    # ------------------------------------------------------------------

    def run(self):
        # Inicia o loop de sync em background
        self._sync_thread = threading.Thread(target=self._sync_loop, daemon=True)
        self._sync_thread.start()

        # Carrega ícone
        ico_path = _resource("app.ico")
        if ico_path.exists():
            image = Image.open(ico_path)
        else:
            # Fallback: círculo verde com "Q"
            image = _make_fallback_icon()

        icon = pystray.Icon(
            name="SyncAterro",
            icon=image,
            title="Sincronizador Aterro - Quebec",
            menu=self._build_menu(),
        )
        self._icon = icon

        # O ícone roda em sua própria thread (run_detached) porque o
        # mainloop do Tkinter, necessário para as janelas de configuração e
        # sincronização, precisa rodar na thread principal.
        icon.run_detached()
        self._root.mainloop()


# ---------------------------------------------------------------------------
# Ícone de fallback caso app.ico não exista
# ---------------------------------------------------------------------------

def _make_fallback_icon() -> Image.Image:
    from PIL import ImageDraw, ImageFont
    size = 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse([2, 2, size - 2, size - 2], fill=(34, 139, 34))
    try:
        font = ImageFont.truetype("arial.ttf", 32)
    except Exception:
        font = ImageFont.load_default()
    draw.text((size // 2, size // 2), "Q", fill="white", font=font, anchor="mm")
    return img


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    app = SyncTrayApp()
    app.run()
