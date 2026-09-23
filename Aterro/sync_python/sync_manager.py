import logging
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Optional

from api_client import APIClient
from db_reader import DBReader
from sync_state import SyncStateStore


def _now() -> str:
    return datetime.now().isoformat(timespec="seconds")


class SyncManager:
    """Orquestra a sincronização das tabelas NJH, DA3 e NJ0."""

    def __init__(self, config: dict, logger: logging.Logger, base_dir: Optional[Path] = None):
        self.logger = logger
        self.api = APIClient(config["api"], logger)
        self.db = DBReader(config["source_db"], logger)

        base_dir = base_dir or Path(__file__).parent
        sync_cfg = config.get("sync", {})
        state_filename = sync_cfg.get("state_db_filename", "sync_state.sqlite")
        self.state = SyncStateStore(base_dir / state_filename)

        # source_db.clvl tem prioridade; njh_xclvl no topo do config é fallback legado
        self.njh_xclvl = (
            config.get("source_db", {}).get("clvl")
            or config.get("njh_xclvl", "")
        )
        self.batch_size = sync_cfg.get("batch_size", 50)
        self.retry_attempts = sync_cfg.get("retry_attempts", 3)
        self.retry_delay = sync_cfg.get("retry_delay_seconds", 10)
        # Janela (em dias) usada para reverificar registros já sincronizados em
        # busca de alterações posteriores (ex.: mudança de status) que precisam
        # ser replicadas para a API via updMovNJH.
        self.recheck_days = sync_cfg.get("recheck_days", 30)

    # ------------------------------------------------------------------
    # Helper: detecta resposta "registro já existe" em produção
    # ------------------------------------------------------------------

    @staticmethod
    def _is_already_exists(result: dict) -> bool:
        """Retorna True quando a API indica que o registro já foi gravado."""
        if result.get("status") != 400:
            return False
        data = result.get("data") or {}
        if isinstance(data, dict):
            msg = (
                str(data.get("errorMessage", ""))
                + str(data.get("message", ""))
            ).lower()
        else:
            msg = str(data).lower()
        return "gravado" in msg or "já" in msg or "already" in msg or "duplicate" in msg

    # ------------------------------------------------------------------
    # Ciclo principal
    # ------------------------------------------------------------------

    def run_sync_cycle(self):
        self.logger.info("=" * 55)
        self.logger.info("Iniciando ciclo de sincronização")
        try:
            self.db.connect()
            self._sync_nj0()
            self._sync_da3()
            self._sync_njh()
        except Exception:
            self.logger.error("Erro durante ciclo de sincronização", exc_info=True)
        finally:
            self.db.disconnect()
        self.logger.info("Ciclo de sincronização concluído")
        self.logger.info("=" * 55)

    # ------------------------------------------------------------------
    # NJH
    # ------------------------------------------------------------------

    @staticmethod
    def _njh_payload_key(payload: Dict[str, Any]) -> str:
        """Chave alinhada ao índice usado pelo ADVPL (DbSetOrder(3): FILIAL+XCLVL+CODPAV)."""
        return f"{payload['NJH_FILIAL']}|{payload['NJH_XCLVL']}|{payload['NJH_CODPAV']}"

    def _sync_njh(self):
        self.logger.info("[NJH] Buscando registros pendentes (status finalizado, ainda não sincronizados)...")
        records = self.db.get_njh_pending(self.batch_size)
        self.logger.info(f"[NJH] {len(records)} registro(s) pendente(s) de inserção.")

        ok = err = 0
        for rec in records:
            payload = self._build_njh_payload(rec)
            key = self._njh_payload_key(payload)
            result = self.api.post_njh(payload, self.retry_attempts, self.retry_delay)

            if result["success"]:
                self.db.mark_njh_synced(rec["RECNO"])
                self.state.mark_synced("NJH", key, payload, _now())
                self.logger.info(f"[NJH] CODPAV={payload['NJH_CODPAV']} sincronizado com sucesso (inserção).")
                ok += 1
            elif self._is_already_exists(result):
                self.db.mark_njh_synced(rec["RECNO"])
                self.state.mark_synced("NJH", key, payload, _now())
                self.logger.info(f"[NJH] CODPAV={payload['NJH_CODPAV']} já existia em produção — marcado como sincronizado.")
                ok += 1
            else:
                self.state.mark_error("NJH", key, _now(), f"HTTP {result['status']}: {str(result['data'])[:300]}")
                self.logger.error(
                    f"[NJH] CODPAV={payload['NJH_CODPAV']} FALHOU (inserção) — "
                    f"HTTP {result['status']} | resp: {str(result['data'])[:200]}"
                )
                err += 1

        self.logger.info(f"[NJH] Inserção: {ok} ok, {err} erro(s).")

        # Registros já sincronizados podem ter mudado depois do envio (ex.: status
        # alterado de '2' para outro valor, correção de peso/observação). Detecta
        # via hash local e replica a alteração em produção pelo endpoint de update.
        self.logger.info(f"[NJH] Verificando alterações em registros já sincronizados (últimos {self.recheck_days} dia(s))...")
        recent_synced = self.db.get_njh_synced_recent(self.recheck_days, self.batch_size)

        upd_ok = upd_err = upd_skip = 0
        for rec in recent_synced:
            payload = self._build_njh_payload(rec)
            key = self._njh_payload_key(payload)

            if not self.state.needs_resync("NJH", key, payload):
                upd_skip += 1
                continue

            result = self.api.update_njh(payload, self.retry_attempts, self.retry_delay)
            if result["success"]:
                self.db.mark_njh_synced(rec["RECNO"])
                self.state.mark_synced("NJH", key, payload, _now())
                self.logger.info(f"[NJH] CODPAV={payload['NJH_CODPAV']} atualizado em produção (alteração detectada).")
                upd_ok += 1
            else:
                self.state.mark_error("NJH", key, _now(), f"HTTP {result['status']}: {str(result['data'])[:300]}")
                self.logger.error(
                    f"[NJH] CODPAV={payload['NJH_CODPAV']} FALHOU (atualização) — "
                    f"HTTP {result['status']} | resp: {str(result['data'])[:200]}"
                )
                upd_err += 1

        self.logger.info(f"[NJH] Atualização: {upd_ok} ok, {upd_err} erro(s), {upd_skip} sem alteração.")

    def njh_record_situation(self, rec: Dict[str, Any]) -> str:
        """Classifica a situação de sincronização de um registro NJH para a
        tela de visualização, combinando NJH_STATUS/NJH_XSINC (Protheus) com
        o hash local (mudanças pós-sincronização)."""
        status = (rec.get("NJH_STATUS") or "").strip()
        xsinc = (rec.get("NJH_XSINC") or "").strip().upper()

        if status != "2":
            return "Não finalizado"

        payload = self._build_njh_payload(rec)
        key = self._njh_payload_key(payload)

        if xsinc != "S":
            state = self.state.get("NJH", key)
            if state and state.get("status") == "error":
                return "Erro"
            return "Pendente"

        if self.state.needs_resync("NJH", key, payload):
            return "Alterado (precisa ressincronizar)"
        return "Sincronizado"

    def resync_njh_record(self, recno: int) -> Dict[str, Any]:
        """Envia imediatamente um único registro NJH (inserção ou atualização,
        conforme já tenha sido sincronizado antes). Usado pela tela de edição
        do sincronizador logo após o usuário salvar uma correção manual.

        Abre e fecha a própria conexão com o banco — não depende de um ciclo
        de sincronização em andamento.
        """
        self.db.connect()
        try:
            rec = self.db.get_njh_by_recno(recno)
            if rec is None:
                return {"success": False, "message": "Registro não encontrado."}

            payload = self._build_njh_payload(rec)
            key = self._njh_payload_key(payload)
            already_synced = self.state.was_ever_synced("NJH", key)

            if not already_synced and (rec.get("NJH_STATUS") or "").strip() != "2":
                return {
                    "success": False,
                    "message": "Registro ainda não está com status '2' (finalizado) — não será enviado.",
                }

            if already_synced:
                result = self.api.update_njh(payload, self.retry_attempts, self.retry_delay)
            else:
                result = self.api.post_njh(payload, self.retry_attempts, self.retry_delay)
                if not result["success"] and self._is_already_exists(result):
                    result = self.api.update_njh(payload, self.retry_attempts, self.retry_delay)

            if result["success"] or self._is_already_exists(result):
                self.db.mark_njh_synced(recno)
                self.state.mark_synced("NJH", key, payload, _now())
                return {"success": True, "message": "Sincronizado com sucesso."}

            self.state.mark_error("NJH", key, _now(), f"HTTP {result['status']}: {str(result['data'])[:300]}")
            return {"success": False, "message": f"Falha HTTP {result['status']}: {result['data']}"}
        finally:
            self.db.disconnect()

    def _build_njh_payload(self, rec: Dict[str, Any]) -> dict:
        def s(field: str) -> str:
            return (rec.get(field) or "").strip()

        def fmt_date(val) -> str:
            if val is None:
                return ""
            if hasattr(val, "strftime"):
                return val.strftime("%Y%m%d")
            return str(val).replace("-", "")[:8]

        # NJH_XCLVL sempre vem da variável source_db.clvl (nunca do banco de origem).
        xclvl = self.njh_xclvl
        if not xclvl:
            self.logger.warning("[NJH] source_db.clvl não configurado — NJH_XCLVL será enviado vazio.")

        return {
            "NJH_FILIAL": s("NJH_FILIAL"),
            "NJH_CODPAV": s("NJH_CODPAV"),
            "NJH_DATA"  : fmt_date(rec.get("NJH_DATA")),
            "NJH_CODENT": s("NJH_CODENT"),
            "NJH_LOJENT": s("NJH_LOJENT"),
            "NJH_NOMENT": s("NJH_NOMENT"),
            "NJH_NLJENT": s("NJH_NLJENT"),
            "NJH_CODPRO": s("NJH_CODPRO"),
            "NJH_DESPRO": s("NJH_DESPRO"),
            "NJH_UM1PRO": s("NJH_UM1PRO"),
            "NJH_PLACA" : s("NJH_PLACA"),
            "NJH_NOMMOT": s("NJH_NOMMOT"),
            "NJH_DATPS1": fmt_date(rec.get("NJH_DATPS1")),
            "NJH_HORPS1": s("NJH_HORPS1"),
            "NJH_PESO1" : float(rec.get("NJH_PESO1") or 0),
            "NJH_MODPS1": s("NJH_MODPS1"),
            "NJH_DATPS2": fmt_date(rec.get("NJH_DATPS2")),
            "NJH_HORPS2": s("NJH_HORPS2"),
            "NJH_PESO2" : float(rec.get("NJH_PESO2") or 0),
            "NJH_MODPS2": s("NJH_MODPS2"),
            "NJH_PSSUBT": float(rec.get("NJH_PSSUBT") or 0),
            "NJH_OBS"   : s("NJH_OBS"),
            "NJH_STATUS": s("NJH_STATUS"),
            "NJH_XCLVL" : xclvl,
            "NJH_XNOMPR": s("NJH_XNOMPR"),
            "NJH_XROTA" : s("NJH_XROTA"),
            "NJH_XCLIEN": s("NJH_XCLIEN"),
            "NJH_CLVL"  : s("NJH_CLVL"),
        }

    # ------------------------------------------------------------------
    # DA3
    # ------------------------------------------------------------------

    def _sync_da3(self):
        self.logger.info("[DA3] Buscando registros...")
        records = self.db.get_da3_pending(self.batch_size)
        self.logger.info(f"[DA3] {len(records)} registro(s) encontrado(s).")

        ok = err = 0
        for rec in records:
            cod = (rec.get("DA3_COD") or "").strip()
            payload = self._build_da3_payload(rec)
            result = self.api.post_da3(payload, self.retry_attempts, self.retry_delay)

            if result["success"] or self._is_already_exists(result):
                self.logger.info(f"[DA3] COD={cod} sincronizado com sucesso.")
                ok += 1
            else:
                self.logger.error(
                    f"[DA3] COD={cod} FALHOU — "
                    f"HTTP {result['status']} | resp: {str(result['data'])[:200]}"
                )
                err += 1

        self.logger.info(f"[DA3] Resultado: {ok} ok, {err} erro(s).")

    def _build_da3_payload(self, rec: Dict[str, Any]) -> dict:
        def s(field: str) -> str:
            return (rec.get(field) or "").strip()

        # Ajuste os campos conforme o contrato real da API /APIAterro/recCadDA3
        return {
            "DA3_FILIAL": s("DA3_FILIAL"),
            "DA3_COD"   : s("DA3_COD"),
            "DA3_DESCRI": s("DA3_DESCRI"),
            "DA3_PLACA" : s("DA3_PLACA"),
        }

    # ------------------------------------------------------------------
    # NJ0
    # ------------------------------------------------------------------

    def _sync_nj0(self):
        self.logger.info("[NJ0] Buscando registros...")
        records = self.db.get_nj0_pending(self.batch_size)
        self.logger.info(f"[NJ0] {len(records)} registro(s) encontrado(s).")

        ok = err = 0
        for rec in records:
            cod = (rec.get("NJ0_COD") or "").strip()
            payload = self._build_nj0_payload(rec)
            result = self.api.post_nj0(payload, self.retry_attempts, self.retry_delay)

            if result["success"] or self._is_already_exists(result):
                self.logger.info(f"[NJ0] COD={cod} sincronizado com sucesso.")
                ok += 1
            else:
                self.logger.error(
                    f"[NJ0] COD={cod} FALHOU — "
                    f"HTTP {result['status']} | resp: {str(result['data'])[:200]}"
                )
                err += 1

        self.logger.info(f"[NJ0] Resultado: {ok} ok, {err} erro(s).")

    def _build_nj0_payload(self, rec: Dict[str, Any]) -> dict:
        def s(field: str) -> str:
            return (rec.get(field) or "").strip()

        # Ajuste os campos conforme o contrato real da API /APIAterro/recCADNJ0
        return {
            "NJ0_FILIAL": s("NJ0_FILIAL"),
            "NJ0_COD"   : s("NJ0_COD"),
            "NJ0_NOME"  : s("NJ0_NOME"),
            "NJ0_LOJA"  : s("NJ0_LOJA"),
        }
