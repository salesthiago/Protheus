"""
Telas Tkinter do Sincronizador Aterro.

  - ConfigWindow:      formulario de configuracao (edita config.yaml).
  - SyncStatusWindow:  lista de pesagens (NJH) e situacao de sincronizacao,
                       com opcao de editar um registro e forcar nova sincronizacao.
  - EditRecordDialog:  edicao de um unico registro NJH, gravando direto na
                       tabela de origem e reenviando para a API na sequencia.

Estas janelas rodam sempre na thread principal (onde roda o mainloop do
Tkinter). Quem chama a partir de outra thread (ex.: callback do icone da
bandeja) deve usar root.after(0, ...) para agendar a abertura com seguranca.
"""

import tkinter as tk
import unicodedata
from pathlib import Path
from tkinter import messagebox, ttk
from typing import Callable, Optional


def _norm(text: str) -> str:
    """Remove acentos e baixa a caixa, para comparar texto de forma tolerante."""
    return unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode().lower()

import yaml

from db_reader import EDITABLE_NJH_FIELDS, DBReader
from sync_manager import SyncManager

NJH_STATUS_LABELS = {
    "0": "0 - Incompleto (aberto)",
    "1": "1 - Incompleto (1a pesagem)",
    "2": "2 - Finalizado",
    "3": "3 - Incompleto",
    "4": "4 - Cancelado",
}


# ---------------------------------------------------------------------------
# Janela de Configuracao
# ---------------------------------------------------------------------------

class ConfigWindow(tk.Toplevel):
    def __init__(self, master, config_path: Path, on_saved: Optional[Callable] = None):
        super().__init__(master)
        self.title("Sincronizador Aterro - Configuracoes")
        self.geometry("600x620")
        self.config_path = config_path
        self.on_saved = on_saved

        self._vars: dict[str, tk.StringVar] = {}
        self._types: dict[str, type] = {}

        with open(config_path, encoding="utf-8") as f:
            self._config = yaml.safe_load(f) or {}

        self._build_form()
        # Nao usar self.transient(master): quando master e a janela raiz
        # oculta (root.withdraw()), o Windows/Tk mantem a Toplevel marcada
        # como "transient" permanentemente invisivel (state "withdrawn"),
        # mesmo apos deiconify()/lift(). grab_set() ja garante o modal.
        self.grab_set()

    # -- helpers de construcao ------------------------------------------------

    def _row(self, parent, label, key, raw_value, row, show=None):
        ttk.Label(parent, text=label).grid(row=row, column=0, sticky="w", padx=6, pady=3)
        var = tk.StringVar(value=str(raw_value))
        ttk.Entry(parent, textvariable=var, width=38, show=show).grid(
            row=row, column=1, sticky="we", padx=6, pady=3
        )
        self._vars[key] = var
        self._types[key] = type(raw_value)
        return var

    def _build_form(self):
        nb = ttk.Notebook(self)
        nb.pack(fill="both", expand=True, padx=8, pady=8)

        # --- Geral ---
        tab_geral = ttk.Frame(nb)
        nb.add(tab_geral, text="Geral")

        self._enabled_var = tk.BooleanVar(value=bool(self._config.get("enabled", True)))
        ttk.Checkbutton(tab_geral, text="Sincronizador ativo", variable=self._enabled_var).grid(
            row=0, column=0, columnspan=2, sticky="w", padx=6, pady=6
        )

        api = self._config.get("api", {})
        self._row(tab_geral, "API - URL base:", "api.base_url", api.get("base_url", ""), 1)
        self._row(tab_geral, "API - Tenant ID:", "api.tenant_id", api.get("tenant_id", "01"), 2)
        self._row(tab_geral, "API - Usuario:", "api.username", api.get("username", ""), 3)
        self._row(tab_geral, "API - Senha:", "api.password", api.get("password", ""), 4, show="*")
        self._row(tab_geral, "API - Timeout (s):", "api.timeout_seconds", api.get("timeout_seconds", 30), 5)

        sync = self._config.get("sync", {})
        self._row(tab_geral, "Intervalo entre ciclos (s):", "sync.interval_seconds", sync.get("interval_seconds", 300), 6)
        self._row(tab_geral, "Registros por ciclo (batch):", "sync.batch_size", sync.get("batch_size", 50), 7)
        self._row(tab_geral, "Tentativas em caso de falha:", "sync.retry_attempts", sync.get("retry_attempts", 3), 8)
        self._row(tab_geral, "Espera entre tentativas (s):", "sync.retry_delay_seconds", sync.get("retry_delay_seconds", 10), 9)
        self._row(
            tab_geral, "Reverificar sincronizados (dias):", "sync.recheck_days", sync.get("recheck_days", 30), 10
        )

        for c in range(2):
            tab_geral.grid_columnconfigure(c, weight=1)

        # --- Banco de origem ---
        tab_db = ttk.Frame(nb)
        nb.add(tab_db, text="Banco de Origem")

        src = self._config.get("source_db", {})
        self._db_type_var = tk.StringVar(value=src.get("type", "postgres"))
        ttk.Label(tab_db, text="Tipo do banco:").grid(row=0, column=0, sticky="w", padx=6, pady=3)
        ttk.Combobox(
            tab_db, textvariable=self._db_type_var, state="readonly",
            values=["sqlserver", "postgres", "mysql"], width=20,
        ).grid(row=0, column=1, sticky="w", padx=6, pady=3)

        self._row(tab_db, "Empresa:", "source_db.empresa", src.get("empresa", "01"), 1)
        self._row(tab_db, "Filial (mantenha o espacamento):", "source_db.filial", src.get("filial", "01  "), 2)
        self._row(tab_db, "CLVL (centro de custo / NJH_XCLVL):", "source_db.clvl", src.get("clvl", ""), 3)

        sub = ttk.LabelFrame(tab_db, text="Conexao (preencha apenas os campos do tipo escolhido acima)")
        sub.grid(row=4, column=0, columnspan=2, sticky="we", padx=6, pady=10)

        pg = src.get("postgres", {})
        self._row(sub, "PostgreSQL - Host:", "source_db.postgres.host", pg.get("host", "localhost"), 0)
        self._row(sub, "PostgreSQL - Porta:", "source_db.postgres.port", pg.get("port", 5432), 1)
        self._row(sub, "PostgreSQL - Banco:", "source_db.postgres.database", pg.get("database", ""), 2)
        self._row(sub, "PostgreSQL - Usuario:", "source_db.postgres.username", pg.get("username", ""), 3)
        self._row(sub, "PostgreSQL - Senha:", "source_db.postgres.password", pg.get("password", ""), 4, show="*")

        ss = src.get("sqlserver", {})
        self._row(sub, "SQL Server - Servidor:", "source_db.sqlserver.server", ss.get("server", ""), 5)
        self._row(sub, "SQL Server - Banco:", "source_db.sqlserver.database", ss.get("database", ""), 6)
        self._row(sub, "SQL Server - Usuario:", "source_db.sqlserver.username", ss.get("username", ""), 7)
        self._row(sub, "SQL Server - Senha:", "source_db.sqlserver.password", ss.get("password", ""), 8, show="*")

        my = src.get("mysql", {})
        self._row(sub, "MySQL - Host:", "source_db.mysql.host", my.get("host", "localhost"), 9)
        self._row(sub, "MySQL - Porta:", "source_db.mysql.port", my.get("port", 3306), 10)
        self._row(sub, "MySQL - Banco:", "source_db.mysql.database", my.get("database", ""), 11)
        self._row(sub, "MySQL - Usuario:", "source_db.mysql.username", my.get("username", ""), 12)
        self._row(sub, "MySQL - Senha:", "source_db.mysql.password", my.get("password", ""), 13, show="*")

        for c in range(2):
            tab_db.grid_columnconfigure(c, weight=1)
            sub.grid_columnconfigure(c, weight=1)

        # --- Log ---
        tab_log = ttk.Frame(nb)
        nb.add(tab_log, text="Log")
        log_cfg = self._config.get("log", {})
        ttk.Label(tab_log, text="Nivel:").grid(row=0, column=0, sticky="w", padx=6, pady=3)
        self._log_level_var = tk.StringVar(value=log_cfg.get("level", "INFO"))
        ttk.Combobox(
            tab_log, textvariable=self._log_level_var, state="readonly",
            values=["DEBUG", "INFO", "WARNING", "ERROR"], width=20,
        ).grid(row=0, column=1, sticky="w", padx=6, pady=3)

        # --- Botoes ---
        btns = ttk.Frame(self)
        btns.pack(fill="x", padx=8, pady=(0, 8))
        ttk.Button(btns, text="Salvar", command=self._save).pack(side="right", padx=4)
        ttk.Button(btns, text="Cancelar", command=self.destroy).pack(side="right")

    # -- persistencia -----------------------------------------------------

    @staticmethod
    def _set_nested(d: dict, dotted_key: str, value):
        parts = dotted_key.split(".")
        for part in parts[:-1]:
            d = d.setdefault(part, {})
        d[parts[-1]] = value

    def _save(self):
        errors = []
        for key, var in self._vars.items():
            text = var.get()
            target_type = self._types.get(key, str)
            value = text
            if target_type is int:
                try:
                    value = int(text)
                except ValueError:
                    errors.append(f"'{key}' precisa ser um numero inteiro (valor: '{text}').")
            elif target_type is float:
                try:
                    value = float(text)
                except ValueError:
                    errors.append(f"'{key}' precisa ser um numero (valor: '{text}').")
            # strings (empresa, filial, clvl, tenant_id, senhas, etc.) ficam como digitado,
            # sem conversao automatica — evita perder zeros a esquerda.
            self._set_nested(self._config, key, value)

        if errors:
            messagebox.showerror("Configuracoes", "\n".join(errors), parent=self)
            return

        self._config["enabled"] = self._enabled_var.get()
        self._config.setdefault("source_db", {})["type"] = self._db_type_var.get()
        self._config.setdefault("log", {})["level"] = self._log_level_var.get()

        try:
            with open(self.config_path, "w", encoding="utf-8") as f:
                yaml.dump(self._config, f, allow_unicode=True, default_flow_style=False)
        except Exception as exc:
            messagebox.showerror("Configuracoes", f"Erro ao salvar config.yaml: {exc}", parent=self)
            return

        messagebox.showinfo("Configuracoes", "Configuracoes salvas com sucesso.", parent=self)
        if self.on_saved:
            self.on_saved()
        self.destroy()


# ---------------------------------------------------------------------------
# Janela de Visualizacao / Edicao de Sincronizacao
# ---------------------------------------------------------------------------

class SyncStatusWindow(tk.Toplevel):
    COLUMNS = (
        "data", "codpav", "placa", "motorista", "peso1", "peso2",
        "status", "situacao", "ultima_sinc", "ultimo_erro",
    )
    HEADINGS = {
        "data": "Data", "codpav": "Ticket", "placa": "Placa", "motorista": "Motorista",
        "peso1": "Peso 1", "peso2": "Peso 2", "status": "Status Protheus",
        "situacao": "Sincronizacao", "ultima_sinc": "Ultima Sinc.", "ultimo_erro": "Ultimo Erro",
    }

    def __init__(self, master, config: dict, logger, base_dir: Path):
        super().__init__(master)
        self.title("Sincronizador Aterro - Sincronizacao (NJH)")
        self.geometry("1100x520")
        self.config_data = config
        self.logger = logger
        self.base_dir = base_dir
        self._recno_by_iid: dict[str, int] = {}

        self._build_ui()
        # Nao usar self.transient(master): master e a janela raiz oculta
        # (root.withdraw()), o que deixaria esta Toplevel presa em estado
        # "withdrawn" (invisivel) mesmo apos deiconify()/lift().
        self._refresh()

    def _build_ui(self):
        top = ttk.Frame(self)
        top.pack(fill="x", padx=8, pady=6)
        ttk.Button(top, text="Atualizar lista", command=self._refresh).pack(side="left")
        ttk.Button(top, text="Editar / Solicitar nova sincronizacao...", command=self._edit_selected).pack(
            side="left", padx=6
        )
        ttk.Button(top, text="Sincronizar agora", command=self._sync_selected).pack(side="left")

        self._filter_var = tk.StringVar(value="todos")
        ttk.Label(top, text="   Filtro:").pack(side="left", padx=(16, 4))
        ttk.Combobox(
            top, textvariable=self._filter_var, state="readonly", width=28,
            values=["todos", "pendente", "sincronizado", "alterado (precisa ressincronizar)", "erro", "nao finalizado"],
        ).pack(side="left")
        ttk.Button(top, text="Filtrar", command=self._refresh).pack(side="left", padx=6)

        tree_frame = ttk.Frame(self)
        tree_frame.pack(fill="both", expand=True, padx=8, pady=(0, 8))

        self.tree = ttk.Treeview(tree_frame, columns=self.COLUMNS, show="headings", selectmode="browse")
        for col in self.COLUMNS:
            self.tree.heading(col, text=self.HEADINGS[col])
            self.tree.column(col, width=110, anchor="w")
        self.tree.column("motorista", width=160)
        self.tree.column("ultimo_erro", width=220)

        vsb = ttk.Scrollbar(tree_frame, orient="vertical", command=self.tree.yview)
        self.tree.configure(yscrollcommand=vsb.set)
        self.tree.pack(side="left", fill="both", expand=True)
        vsb.pack(side="right", fill="y")

        self.tree.bind("<Double-1>", lambda e: self._edit_selected())

        self.status_label = ttk.Label(self, text="")
        self.status_label.pack(fill="x", padx=8, pady=(0, 6))

    def _manager(self) -> SyncManager:
        return SyncManager(self.config_data, self.logger, self.base_dir)

    def _refresh(self):
        self.tree.delete(*self.tree.get_children())
        self._recno_by_iid.clear()

        manager = self._manager()
        db = manager.db
        try:
            db.connect()
            records = db.get_njh_overview(limit=500)
        except Exception as exc:
            messagebox.showerror("Sincronizacao", f"Erro ao consultar o banco de origem:\n{exc}", parent=self)
            return
        finally:
            db.disconnect()

        wanted = self._filter_var.get()
        shown = 0
        for rec in records:
            situacao = manager.njh_record_situation(rec)
            if wanted != "todos" and _norm(situacao) != _norm(wanted):
                continue

            payload_key = manager._njh_payload_key(manager._build_njh_payload(rec))
            state = manager.state.get("NJH", payload_key)
            ultima_sinc = (state or {}).get("last_synced_at") or ""
            ultimo_erro = (state or {}).get("last_error") or ""

            iid = self.tree.insert(
                "", "end",
                values=(
                    str(rec.get("NJH_DATA") or ""),
                    (rec.get("NJH_CODPAV") or "").strip(),
                    (rec.get("NJH_PLACA") or "").strip(),
                    (rec.get("NJH_NOMMOT") or "").strip(),
                    rec.get("NJH_PESO1") or 0,
                    rec.get("NJH_PESO2") or 0,
                    (rec.get("NJH_STATUS") or "").strip(),
                    situacao,
                    ultima_sinc,
                    ultimo_erro,
                ),
            )
            self._recno_by_iid[iid] = rec["RECNO"]
            shown += 1

        self.status_label.config(text=f"{shown} registro(s) exibido(s) de {len(records)} carregado(s).")

    def _selected_recno(self) -> Optional[int]:
        sel = self.tree.selection()
        if not sel:
            messagebox.showwarning("Sincronizacao", "Selecione um registro na lista.", parent=self)
            return None
        return self._recno_by_iid.get(sel[0])

    def _edit_selected(self):
        recno = self._selected_recno()
        if recno is None:
            return
        EditRecordDialog(self, self.config_data, self.logger, self.base_dir, recno, on_saved=self._refresh)

    def _sync_selected(self):
        recno = self._selected_recno()
        if recno is None:
            return
        manager = self._manager()
        result = manager.resync_njh_record(recno)
        if result["success"]:
            messagebox.showinfo("Sincronizacao", result["message"], parent=self)
        else:
            messagebox.showerror("Sincronizacao", result["message"], parent=self)
        self._refresh()


# ---------------------------------------------------------------------------
# Dialogo de Edicao de um Registro
# ---------------------------------------------------------------------------

class EditRecordDialog(tk.Toplevel):
    def __init__(self, master, config: dict, logger, base_dir: Path, recno: int, on_saved: Optional[Callable] = None):
        super().__init__(master)
        self.title(f"Editar registro NJH (RECNO={recno})")
        self.geometry("420x420")
        self.config_data = config
        self.logger = logger
        self.base_dir = base_dir
        self.recno = recno
        self.on_saved = on_saved

        self.db = DBReader(config["source_db"], logger)
        self.db.connect()
        self.record = self.db.get_njh_by_recno(recno)

        if self.record is None:
            messagebox.showerror("Editar registro", "Registro nao encontrado.", parent=master)
            self.db.disconnect()
            self.destroy()
            return

        self._build_form()
        self.transient(master)
        self.grab_set()
        self.protocol("WM_DELETE_WINDOW", self._on_close)

    def _build_form(self):
        rec = self.record
        frm = ttk.Frame(self)
        frm.pack(fill="both", expand=True, padx=10, pady=10)

        r = 0
        ttk.Label(frm, text=f"Ticket: {(rec.get('NJH_CODPAV') or '').strip()}").grid(
            row=r, column=0, columnspan=2, sticky="w", pady=(0, 8)
        )
        r += 1
        ttk.Label(frm, text=f"Data: {rec.get('NJH_DATA')}   Cliente: {(rec.get('NJH_NOMENT') or '').strip()}").grid(
            row=r, column=0, columnspan=2, sticky="w", pady=(0, 8)
        )
        r += 1

        ttk.Label(frm, text="Status:").grid(row=r, column=0, sticky="w", pady=3)
        cur_status = (rec.get("NJH_STATUS") or "").strip()
        self.status_var = tk.StringVar(value=NJH_STATUS_LABELS.get(cur_status, cur_status))
        ttk.Combobox(
            frm, textvariable=self.status_var, state="readonly", width=30,
            values=list(NJH_STATUS_LABELS.values()),
        ).grid(row=r, column=1, sticky="we", pady=3)
        r += 1

        self.field_vars: dict[str, tk.StringVar] = {}

        def add_field(label, field, value):
            nonlocal r
            ttk.Label(frm, text=label).grid(row=r, column=0, sticky="w", pady=3)
            var = tk.StringVar(value="" if value is None else str(value))
            ttk.Entry(frm, textvariable=var, width=30).grid(row=r, column=1, sticky="we", pady=3)
            self.field_vars[field] = var
            r += 1

        add_field("Placa:", "NJH_PLACA", (rec.get("NJH_PLACA") or "").strip())
        add_field("Motorista:", "NJH_NOMMOT", (rec.get("NJH_NOMMOT") or "").strip())
        add_field("Peso 1 (kg):", "NJH_PESO1", rec.get("NJH_PESO1") or 0)
        add_field("Peso 2 (kg):", "NJH_PESO2", rec.get("NJH_PESO2") or 0)
        add_field("Peso Liquido (NJH_PSSUBT):", "NJH_PSSUBT", rec.get("NJH_PSSUBT") or 0)
        add_field("Observacao:", "NJH_OBS", (rec.get("NJH_OBS") or "").strip())

        for c in range(2):
            frm.grid_columnconfigure(c, weight=1)

        btns = ttk.Frame(self)
        btns.pack(fill="x", padx=10, pady=(0, 10))
        ttk.Button(btns, text="Salvar e sincronizar", command=self._save_and_sync).pack(side="right", padx=4)
        ttk.Button(btns, text="Cancelar", command=self._on_close).pack(side="right")

    def _on_close(self):
        self.db.disconnect()
        self.destroy()

    def _save_and_sync(self):
        fields: dict = {}

        status_label = self.status_var.get()
        new_status = next((k for k, v in NJH_STATUS_LABELS.items() if v == status_label), None)
        if new_status and new_status != (self.record.get("NJH_STATUS") or "").strip():
            fields["NJH_STATUS"] = new_status

        for field, var in self.field_vars.items():
            text = var.get()
            old = self.record.get(field)
            old_text = "" if old is None else str(old).strip()
            if text.strip() == old_text:
                continue
            if field in ("NJH_PESO1", "NJH_PESO2", "NJH_PSSUBT"):
                try:
                    fields[field] = float(text.replace(",", "."))
                except ValueError:
                    messagebox.showerror("Editar registro", f"Valor invalido para {field}: '{text}'", parent=self)
                    return
            else:
                fields[field] = text

        invalid = set(fields) - set(EDITABLE_NJH_FIELDS)
        if invalid:
            messagebox.showerror("Editar registro", f"Campo(s) nao editavel(is): {invalid}", parent=self)
            return

        if not fields:
            messagebox.showinfo("Editar registro", "Nenhuma alteracao para salvar.", parent=self)
            return

        try:
            self.db.update_njh_record(self.recno, fields)
        except Exception as exc:
            messagebox.showerror("Editar registro", f"Erro ao gravar no banco de origem:\n{exc}", parent=self)
            return
        finally:
            self.db.disconnect()

        manager = SyncManager(self.config_data, self.logger, self.base_dir)
        result = manager.resync_njh_record(self.recno)

        if result["success"]:
            messagebox.showinfo("Editar registro", f"Registro salvo e sincronizado.\n{result['message']}", parent=self)
        else:
            messagebox.showwarning(
                "Editar registro",
                f"Registro salvo na base de origem, mas a sincronizacao falhou:\n{result['message']}\n\n"
                "Sera reenviado automaticamente no proximo ciclo.",
                parent=self,
            )

        if self.on_saved:
            self.on_saved()
        self.destroy()
