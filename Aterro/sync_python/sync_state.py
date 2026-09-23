"""
Estado local de sincronizacao (SQLite).

Guarda, por tabela+chave de registro, o hash do ultimo payload enviado
com sucesso para a API. Isso permite detectar quando um registro que ja
foi sincronizado mudou na origem (ex.: status da pesagem foi alterado
depois do envio) e precisa ser reenviado via endpoint de atualizacao,
sem depender de nenhum campo novo no dicionario de dados do Protheus.

Tambem serve de base para a tela "visualizar sincronizados x nao
sincronizados" do sincronizador (ultimo horario de sincronizacao,
ultimo erro, etc.).
"""

import contextlib
import hashlib
import json
import sqlite3
import threading
from pathlib import Path
from typing import Any, Dict, Optional


class SyncStateStore:
    def __init__(self, db_path: Path):
        self.db_path = Path(db_path)
        self._lock = threading.Lock()
        self._init_db()

    def _connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(str(self.db_path))
        conn.row_factory = sqlite3.Row
        return conn

    def _init_db(self):
        # `with sqlite3.Connection` só faz commit/rollback ao sair do bloco,
        # não fecha a conexão — por isso o `contextlib.closing` explícito em
        # todos os métodos abaixo, para não vazar handles do arquivo .sqlite.
        with self._lock, contextlib.closing(self._connect()) as conn, conn:
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS sync_state (
                    table_name      TEXT NOT NULL,
                    record_key      TEXT NOT NULL,
                    payload_hash    TEXT NOT NULL,
                    status          TEXT NOT NULL,
                    last_synced_at  TEXT,
                    last_attempt_at TEXT,
                    last_error      TEXT,
                    PRIMARY KEY (table_name, record_key)
                )
                """
            )

    @staticmethod
    def hash_payload(payload: Dict[str, Any]) -> str:
        raw = json.dumps(payload, sort_keys=True, default=str)
        return hashlib.sha256(raw.encode("utf-8")).hexdigest()

    def get(self, table_name: str, record_key: str) -> Optional[dict]:
        with self._lock, contextlib.closing(self._connect()) as conn:
            cur = conn.execute(
                "SELECT * FROM sync_state WHERE table_name = ? AND record_key = ?",
                (table_name, record_key),
            )
            row = cur.fetchone()
            return dict(row) if row else None

    def all(self, table_name: str) -> Dict[str, dict]:
        with self._lock, contextlib.closing(self._connect()) as conn:
            cur = conn.execute("SELECT * FROM sync_state WHERE table_name = ?", (table_name,))
            return {row["record_key"]: dict(row) for row in cur.fetchall()}

    def mark_synced(self, table_name: str, record_key: str, payload: dict, when: str):
        payload_hash = self.hash_payload(payload)
        with self._lock, contextlib.closing(self._connect()) as conn, conn:
            conn.execute(
                """
                INSERT INTO sync_state
                    (table_name, record_key, payload_hash, status, last_synced_at, last_attempt_at, last_error)
                VALUES (?, ?, ?, 'synced', ?, ?, NULL)
                ON CONFLICT(table_name, record_key) DO UPDATE SET
                    payload_hash    = excluded.payload_hash,
                    status          = 'synced',
                    last_synced_at  = excluded.last_synced_at,
                    last_attempt_at = excluded.last_attempt_at,
                    last_error      = NULL
                """,
                (table_name, record_key, payload_hash, when, when),
            )

    def mark_error(self, table_name: str, record_key: str, when: str, error: str):
        with self._lock, contextlib.closing(self._connect()) as conn, conn:
            conn.execute(
                """
                INSERT INTO sync_state
                    (table_name, record_key, payload_hash, status, last_synced_at, last_attempt_at, last_error)
                VALUES (?, ?, '', 'error', NULL, ?, ?)
                ON CONFLICT(table_name, record_key) DO UPDATE SET
                    status          = 'error',
                    last_attempt_at = excluded.last_attempt_at,
                    last_error      = excluded.last_error
                """,
                (table_name, record_key, when, error),
            )

    def needs_resync(self, table_name: str, record_key: str, payload: dict) -> bool:
        """True se o registro nunca foi sincronizado com sucesso OU se o
        conteudo atual difere do ultimo hash sincronizado."""
        state = self.get(table_name, record_key)
        if state is None or state["status"] != "synced":
            return True
        return state["payload_hash"] != self.hash_payload(payload)

    def was_ever_synced(self, table_name: str, record_key: str) -> bool:
        state = self.get(table_name, record_key)
        return bool(state and state["status"] == "synced" and state["last_synced_at"])
