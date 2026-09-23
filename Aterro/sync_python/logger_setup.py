import logging
import logging.handlers
from pathlib import Path
from typing import Optional


def setup_logger(config: dict, base_dir: Optional[Path] = None) -> logging.Logger:
    # Resolve sempre em relação à pasta do .exe/script — nunca ao diretório de
    # trabalho atual, que varia conforme como o processo é iniciado (duplo
    # clique, atalho na Inicialização do Windows, agendador de tarefas etc.).
    base_dir = base_dir or Path(__file__).parent
    log_dir = base_dir / config.get("directory", "logs")
    log_dir.mkdir(parents=True, exist_ok=True)

    log_file = log_dir / config.get("filename", "sync_aterro.log")
    level = getattr(logging, config.get("level", "INFO").upper(), logging.INFO)

    logger = logging.getLogger("sync_aterro")
    logger.setLevel(level)

    if logger.handlers:
        logger.handlers.clear()

    fmt = logging.Formatter(
        "%(asctime)s [%(levelname)-8s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    file_handler = logging.handlers.RotatingFileHandler(
        log_file,
        maxBytes=config.get("max_bytes", 10_485_760),
        backupCount=config.get("backup_count", 5),
        encoding="utf-8",
    )
    file_handler.setFormatter(fmt)

    console_handler = logging.StreamHandler()
    console_handler.setFormatter(fmt)

    logger.addHandler(file_handler)
    logger.addHandler(console_handler)

    return logger
