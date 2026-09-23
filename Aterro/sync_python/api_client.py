import logging
import time

import requests
from requests.auth import HTTPBasicAuth


class APIClient:
    """Cliente HTTP para a API REST do Protheus (Aterro)."""

    def __init__(self, config: dict, logger: logging.Logger):
        self.base_url = config["base_url"].rstrip("/")
        self.timeout = config.get("timeout_seconds", 30)
        self.logger = logger

        self.session = requests.Session()
        self.session.auth = HTTPBasicAuth(config["username"], config["password"])
        self.session.headers.update(
            {
                "Content-Type": "application/json",
                "Accept": "application/json",
                "tenantId": str(config.get("tenant_id", "01")),
            }
        )

    def _post(
        self, endpoint: str, payload: dict, retry_attempts: int, retry_delay: int
    ) -> dict:
        url = f"{self.base_url}{endpoint}"
        for attempt in range(1, retry_attempts + 1):
            try:
                resp = self.session.post(url, json=payload, timeout=self.timeout)
                try:
                    data = resp.json()
                except Exception:
                    data = resp.text

                if resp.status_code in (200, 201):
                    return {"success": True, "status": resp.status_code, "data": data}

                # 4xx = erro de negócio; repetir não vai mudar o resultado
                if 400 <= resp.status_code < 500:
                    self.logger.warning(
                        f"[API] {endpoint} HTTP {resp.status_code} (sem retry): {resp.text[:300]}"
                    )
                    return {"success": False, "status": resp.status_code, "data": data}

                # 5xx = erro de servidor; vale tentar novamente
                self.logger.warning(
                    f"[API] {endpoint} retornou HTTP {resp.status_code} "
                    f"(tentativa {attempt}/{retry_attempts}): {resp.text[:300]}"
                )

            except requests.exceptions.ConnectionError as exc:
                self.logger.error(
                    f"[API] Erro de conexão em {endpoint} "
                    f"(tentativa {attempt}/{retry_attempts}): {exc}"
                )
            except requests.exceptions.Timeout:
                self.logger.error(
                    f"[API] Timeout em {endpoint} (tentativa {attempt}/{retry_attempts})"
                )
            except Exception as exc:
                self.logger.error(
                    f"[API] Erro inesperado em {endpoint} "
                    f"(tentativa {attempt}/{retry_attempts}): {exc}"
                )

            if attempt < retry_attempts:
                time.sleep(retry_delay)

        return {"success": False, "status": None, "data": None}

    def post_njh(self, payload: dict, retry_attempts: int = 3, retry_delay: int = 10) -> dict:
        return self._post("/APIAterro/recMovNJH", payload, retry_attempts, retry_delay)

    def update_njh(self, payload: dict, retry_attempts: int = 3, retry_delay: int = 10) -> dict:
        """Atualiza um registro NJH já sincronizado anteriormente (endpoint updMovNJH)."""
        return self._post("/APIAterro/updMovNJH", payload, retry_attempts, retry_delay)

    def post_da3(self, payload: dict, retry_attempts: int = 3, retry_delay: int = 10) -> dict:
        return self._post("/APIAterro/recCadDA3", payload, retry_attempts, retry_delay)

    def post_nj0(self, payload: dict, retry_attempts: int = 3, retry_delay: int = 10) -> dict:
        return self._post("/APIAterro/recCADNJ0", payload, retry_attempts, retry_delay)
