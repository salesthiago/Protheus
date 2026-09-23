"""
Sincronizador Aterro - Quebec Ambiental
Uso:
    python main.py           # execução contínua (loop configurado em config.yaml)
    python main.py --once    # executa um único ciclo e encerra (útil para testes)
"""

import signal
import sys
import time
from pathlib import Path

import yaml

from logger_setup import setup_logger
from sync_manager import SyncManager


def load_config() -> dict:
    path = Path(__file__).parent / "config.yaml"
    with open(path, encoding="utf-8") as f:
        return yaml.safe_load(f)


def main():
    run_once = "--once" in sys.argv
    base_dir = Path(__file__).parent

    config = load_config()
    logger = setup_logger(config["log"], base_dir)

    logger.info("=" * 55)
    logger.info("Sincronizador Aterro - Quebec Ambiental")
    logger.info(f"  API base URL : {config['api']['base_url']}")
    logger.info(f"  Tenant ID    : {config['api'].get('tenant_id', '01')}")
    logger.info(f"  NJH_XCLVL   : {config.get('njh_xclvl') or '(usa valor do banco)'}")
    logger.info(f"  Modo         : {'uma execução' if run_once else 'contínuo'}")
    logger.info("=" * 55)

    if not config.get("enabled", True):
        logger.warning("Sincronizador DESATIVADO em config.yaml. Encerrando.")
        return

    manager = SyncManager(config, logger, base_dir)

    if run_once:
        manager.run_sync_cycle()
        return

    interval = config.get("sync", {}).get("interval_seconds", 300)

    def handle_shutdown(sig, frame):
        logger.info("Sinal de encerramento recebido. Encerrando.")
        sys.exit(0)

    signal.signal(signal.SIGINT, handle_shutdown)
    signal.signal(signal.SIGTERM, handle_shutdown)

    while True:
        # Recarrega config a cada ciclo para refletir mudanças sem reiniciar
        try:
            config = load_config()
        except Exception as exc:
            logger.error(f"Falha ao recarregar config.yaml: {exc}")

        if not config.get("enabled", True):
            logger.info("Sincronizador DESATIVADO em config.yaml. Aguardando próximo ciclo.")
        else:
            manager = SyncManager(config, logger, base_dir)
            manager.run_sync_cycle()

        interval = config.get("sync", {}).get("interval_seconds", 300)
        logger.info(f"Próximo ciclo em {interval}s. Pressione Ctrl+C para encerrar.")
        time.sleep(interval)


if __name__ == "__main__":
    main()
