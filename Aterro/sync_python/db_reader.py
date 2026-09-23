import logging
from datetime import date, timedelta
from typing import Any, Dict, List, Optional

# Campos da NJH que podem ser corrigidos pela tela de edição do sincronizador.
# Mantido como allow-list explícita: update_njh_record() só aceita estas
# colunas, nunca nomes vindos livremente de fora.
EDITABLE_NJH_FIELDS = (
    "NJH_STATUS",
    "NJH_PESO1",
    "NJH_PESO2",
    "NJH_PSSUBT",
    "NJH_OBS",
    "NJH_DATPS1",
    "NJH_HORPS1",
    "NJH_DATPS2",
    "NJH_HORPS2",
    "NJH_PLACA",
    "NJH_NOMMOT",
)

NJH_VIEW_COLUMNS = """
    NJH_FILIAL, NJH_CODPAV, NJH_DATA, NJH_CODENT, NJH_NOMENT,
    NJH_CODPRO, NJH_DESPRO, NJH_PLACA, NJH_NOMMOT,
    NJH_DATPS1, NJH_HORPS1, NJH_PESO1,
    NJH_DATPS2, NJH_HORPS2, NJH_PESO2,
    NJH_PSSUBT, NJH_OBS, NJH_STATUS, NJH_XCLVL, NJH_XROTA, NJH_XCLIEN,
    NJH_XSINC, NJH_XDTSIN
"""

# Os drivers são importados sob demanda para não exigir todos instalados.
# Instale apenas o driver correspondente ao banco utilizado:
#   SQL Server : pip install pyodbc
#   PostgreSQL : pip install psycopg2-binary
#   MySQL      : pip install pymysql


class DBReader:
    """Lê registros do banco Protheus de origem e marca os sincronizados.

    Suporta SQL Server, PostgreSQL e MySQL — escolhido via source_db.type
    em config.yaml.
    """

    def __init__(self, config: dict, logger: logging.Logger):
        self.config = config
        self.logger = logger
        self.conn = None

        self._db_type: str = config.get("type", "sqlserver").lower()
        self._empresa: str = config.get("empresa", "01")
        self._filial: str = config.get("filial", "01  ")
        self._suffix: str = f"{self._empresa}0"
        self._table_case: str = config.get("table_case", "upper").lower()

    # ------------------------------------------------------------------
    # Conexão
    # ------------------------------------------------------------------

    def connect(self):
        dispatch = {
            "sqlserver": self._connect_sqlserver,
            "postgres":  self._connect_postgres,
            "mysql":     self._connect_mysql,
        }
        if self._db_type not in dispatch:
            raise ValueError(
                f"source_db.type inválido: '{self._db_type}'. "
                "Use: sqlserver | postgres | mysql"
            )
        dispatch[self._db_type]()

    def _connect_sqlserver(self):
        import pyodbc  # pip install pyodbc

        cfg = self.config.get("sqlserver", {})
        if cfg.get("trusted_connection"):
            conn_str = (
                f"DRIVER={{{cfg['driver']}}};"
                f"SERVER={cfg['server']};"
                f"DATABASE={cfg['database']};"
                "Trusted_Connection=yes;"
            )
        else:
            conn_str = (
                f"DRIVER={{{cfg['driver']}}};"
                f"SERVER={cfg['server']};"
                f"DATABASE={cfg['database']};"
                f"UID={cfg['username']};"
                f"PWD={cfg['password']};"
            )
        self.conn = pyodbc.connect(conn_str, autocommit=False)
        self.logger.info(
            f"[DB] SQL Server conectado: {cfg['server']} / {cfg['database']}"
        )

    def _connect_postgres(self):
        import psycopg2  # pip install psycopg2-binary

        cfg = self.config.get("postgres", {})
        kwargs: dict = dict(
            host=cfg["host"],
            port=cfg.get("port", 5432),
            dbname=cfg["database"],
            user=cfg["username"],
            password=cfg["password"],
        )
        if cfg.get("sslmode"):
            kwargs["sslmode"] = cfg["sslmode"]

        self.conn = psycopg2.connect(**kwargs)
        self.conn.autocommit = False
        self.logger.info(
            f"[DB] PostgreSQL conectado: {cfg['host']}:{cfg.get('port', 5432)} / {cfg['database']}"
        )

    def _connect_mysql(self):
        import pymysql  # pip install pymysql

        cfg = self.config.get("mysql", {})
        self.conn = pymysql.connect(
            host=cfg["host"],
            port=cfg.get("port", 3306),
            database=cfg["database"],
            user=cfg["username"],
            password=cfg["password"],
            charset=cfg.get("charset", "utf8mb4"),
            autocommit=False,
        )
        self.logger.info(
            f"[DB] MySQL conectado: {cfg['host']}:{cfg.get('port', 3306)} / {cfg['database']}"
        )

    def disconnect(self):
        if self.conn:
            self.conn.close()
            self.conn = None
            self.logger.debug("[DB] Conexão encerrada.")

    # ------------------------------------------------------------------
    # Helpers de dialeto SQL
    # ------------------------------------------------------------------

    def _ph(self) -> str:
        """Placeholder de parâmetro: ? (SQL Server) ou %s (PostgreSQL/MySQL)."""
        return "?" if self._db_type == "sqlserver" else "%s"

    def _limit(self, n: int) -> tuple[str, str]:
        """Retorna (prefixo_select, sufixo_from) para limitar linhas."""
        if self._db_type == "sqlserver":
            return f"TOP {n}", ""
        return "", f"LIMIT {n}"

    def _table(self, name: str) -> str:
        tbl = f"{name}{self._suffix}"
        return tbl.lower() if self._table_case == "lower" else tbl.upper()

    def _rows_to_dicts(self, cursor) -> List[Dict[str, Any]]:
        # Normaliza para maiúsculas: PostgreSQL retorna nomes em minúsculas,
        # SQL Server preserva o case — padronizamos para não depender do banco.
        columns = [col[0].upper() for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]

    # ------------------------------------------------------------------
    # NJH - Movimentos de Pesagem
    # ------------------------------------------------------------------

    def get_njh_pending(self, batch_size: int = 50) -> List[Dict[str, Any]]:
        """Registros NJH finalizados (NJH_STATUS='2') e ainda não sincronizados
        (NJH_XSINC <> 'S'). Só pesagens finalizadas são enviadas à API."""
        tbl = self._table("NJH")
        ph = self._ph()
        top, limit = self._limit(batch_size)

        sql = f"""
            SELECT {top}
                NJH_FILIAL, NJH_CODPAV, NJH_DATA,   NJH_CODENT, NJH_LOJENT,
                NJH_NOMENT, NJH_NLJENT, NJH_CODPRO,  NJH_DESPRO, NJH_UM1PRO,
                NJH_PLACA,  NJH_NOMMOT, NJH_DATPS1,  NJH_HORPS1, NJH_PESO1,
                NJH_MODPS1, NJH_DATPS2, NJH_HORPS2,  NJH_PESO2,  NJH_MODPS2,
                NJH_PSSUBT, NJH_OBS,    NJH_STATUS,  NJH_XCLVL,
                NJH_XROTA,  NJH_XCLIEN,
                R_E_C_N_O_ AS RECNO
            FROM {tbl}
            WHERE NJH_FILIAL = {ph}
              AND TRIM(NJH_STATUS) = '2'
              AND (NJH_XSINC IS NULL OR TRIM(NJH_XSINC) <> 'S')
              AND D_E_L_E_T_ = ' '
            ORDER BY NJH_DATA, NJH_CODPAV
            {limit}
        """
        cur = self.conn.cursor()
        cur.execute(sql, (self._filial,))
        rows = self._rows_to_dicts(cur)
        self.logger.debug(f"[DB][NJH] {len(rows)} registro(s) pendente(s) em {tbl}.")
        return rows

    def get_njh_synced_recent(self, recheck_days: int, batch_size: int = 200) -> List[Dict[str, Any]]:
        """Registros NJH já marcados como sincronizados (NJH_XSINC='S'),
        sincronizados nos últimos `recheck_days` dias — usado para detectar
        alterações pós-sincronização (ex.: mudança de NJH_STATUS, correção de
        peso) que precisam ser replicadas em produção via updMovNJH."""
        tbl = self._table("NJH")
        ph = self._ph()
        top, limit = self._limit(batch_size)
        cutoff = (date.today() - timedelta(days=recheck_days)).strftime("%Y%m%d")

        sql = f"""
            SELECT {top}
                NJH_FILIAL, NJH_CODPAV, NJH_DATA,   NJH_CODENT, NJH_LOJENT,
                NJH_NOMENT, NJH_NLJENT, NJH_CODPRO,  NJH_DESPRO, NJH_UM1PRO,
                NJH_PLACA,  NJH_NOMMOT, NJH_DATPS1,  NJH_HORPS1, NJH_PESO1,
                NJH_MODPS1, NJH_DATPS2, NJH_HORPS2,  NJH_PESO2,  NJH_MODPS2,
                NJH_PSSUBT, NJH_OBS,    NJH_STATUS,  NJH_XCLVL,
                NJH_XROTA,  NJH_XCLIEN,
                R_E_C_N_O_ AS RECNO
            FROM {tbl}
            WHERE NJH_FILIAL = {ph}
              AND TRIM(NJH_XSINC) = 'S'
              AND NJH_XDTSIN >= {ph}
              AND D_E_L_E_T_ = ' '
            ORDER BY NJH_XDTSIN DESC
            {limit}
        """
        cur = self.conn.cursor()
        cur.execute(sql, (self._filial, cutoff))
        rows = self._rows_to_dicts(cur)
        self.logger.debug(f"[DB][NJH] {len(rows)} registro(s) sincronizado(s) recente(s) em {tbl}.")
        return rows

    def get_njh_overview(self, limit: int = 500) -> List[Dict[str, Any]]:
        """Registros NJH mais recentes (qualquer status) para a tela de
        visualização de sincronização — não filtra por status nem por XSINC."""
        tbl = self._table("NJH")
        ph = self._ph()
        top, sql_limit = self._limit(limit)

        sql = f"""
            SELECT {top}
                {NJH_VIEW_COLUMNS},
                R_E_C_N_O_ AS RECNO
            FROM {tbl}
            WHERE NJH_FILIAL = {ph}
              AND D_E_L_E_T_ = ' '
            ORDER BY NJH_DATA DESC, NJH_CODPAV DESC
            {sql_limit}
        """
        cur = self.conn.cursor()
        cur.execute(sql, (self._filial,))
        return self._rows_to_dicts(cur)

    def get_njh_by_recno(self, recno: int) -> Optional[Dict[str, Any]]:
        tbl = self._table("NJH")
        ph = self._ph()
        sql = f"""
            SELECT {NJH_VIEW_COLUMNS}, R_E_C_N_O_ AS RECNO
            FROM {tbl}
            WHERE R_E_C_N_O_ = {ph}
        """
        cur = self.conn.cursor()
        cur.execute(sql, (recno,))
        rows = self._rows_to_dicts(cur)
        return rows[0] if rows else None

    def update_njh_record(self, recno: int, fields: Dict[str, Any]):
        """Grava diretamente na tabela NJH de origem os campos editados pela
        tela do sincronizador. `fields` só pode conter colunas presentes em
        EDITABLE_NJH_FIELDS (allow-list) — nunca nomes de coluna livres."""
        if not fields:
            return
        invalid = set(fields) - set(EDITABLE_NJH_FIELDS)
        if invalid:
            raise ValueError(f"Campo(s) não editável(is): {', '.join(sorted(invalid))}")

        tbl = self._table("NJH")
        ph = self._ph()
        set_clause = ", ".join(f"{col} = {ph}" for col in fields)
        sql = f"UPDATE {tbl} SET {set_clause} WHERE R_E_C_N_O_ = {ph}"
        params = list(fields.values()) + [recno]
        cur = self.conn.cursor()
        cur.execute(sql, params)
        self.conn.commit()
        self.logger.info(f"[DB][NJH] RECNO={recno} atualizado manualmente: {list(fields.keys())}")

    def mark_njh_synced(self, recno: int):
        """Atualiza NJH_XSINC='S' e NJH_XDTSIN=hoje para o registro sincronizado."""
        tbl = self._table("NJH")
        ph = self._ph()
        today = date.today().strftime("%Y%m%d")
        sql = f"""
            UPDATE {tbl}
            SET NJH_XSINC = 'S', NJH_XDTSIN = {ph}
            WHERE R_E_C_N_O_ = {ph}
        """
        cur = self.conn.cursor()
        cur.execute(sql, (today, recno))
        self.conn.commit()

    # ------------------------------------------------------------------
    # DA3 - Cadastro de Veículos
    # ------------------------------------------------------------------

    def get_da3_pending(self, batch_size: int = 50) -> List[Dict[str, Any]]:
        """
        Registros DA3 a serem sincronizados.

        DA3 não possui campo de controle de sincronização padrão.
        Ajuste o filtro WHERE conforme a necessidade do projeto.
        """
        tbl = self._table("DA3")
        ph = self._ph()
        top, limit = self._limit(batch_size)

        sql = f"""
            SELECT {top}
                DA3_FILIAL, DA3_COD, DA3_PLACA, DA3_XCODCL, DA3_XLOJCL, DA3_XCOD,
                DA3_STATUS,
                R_E_C_N_O_ AS RECNO
            FROM {tbl}
            WHERE DA3_FILIAL = {ph}
              AND D_E_L_E_T_ = ' '
            ORDER BY DA3_COD
            {limit}
        """
        cur = self.conn.cursor()
        cur.execute(sql, (self._filial,))
        rows = self._rows_to_dicts(cur)
        self.logger.debug(f"[DB][DA3] {len(rows)} registro(s) em {tbl}.")
        return rows

    # ------------------------------------------------------------------
    # NJ0 - Fornecedores / Entidades
    # ------------------------------------------------------------------

    def get_nj0_pending(self, batch_size: int = 50) -> List[Dict[str, Any]]:
        """
        Registros NJ0 a serem sincronizados.

        Ajuste os campos SELECT e o filtro WHERE conforme os campos
        reais da tabela NJ0 do projeto.
        """
        tbl = self._table("NJ0")
        ph = self._ph()
        top, limit = self._limit(batch_size)

        sql = f"""
            SELECT {top}
                NJ0_FILIAL, NJ0_CODENT, NJ0_NOME, NJ0_LOJENT, NJ0_NOMLOJ, NJ0_CLASSE, NJ0_ITVDAP
                NJ0_ATIVO, NJ0_DEPALF,
                R_E_C_N_O_ AS RECNO
            FROM {tbl}
            WHERE NJ0_FILIAL = {ph}
              AND D_E_L_E_T_ = ' '
            ORDER BY NJ0_CODENT
            {limit}
        """
        cur = self.conn.cursor()
        cur.execute(sql, (self._filial,))
        rows = self._rows_to_dicts(cur)
        self.logger.debug(f"[DB][NJ0] {len(rows)} registro(s) em {tbl}.")
        return rows
