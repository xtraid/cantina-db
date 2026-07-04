from pathlib import Path

import pymysql
import streamlit as st

# App role -> secrets subsection = which MySQL user we connect as.
# Each role maps to a least-privilege DB user (sql/07_grants.sql), so the DB
# itself enforces the role's column/table privileges.
_ROLE_SECTION = {
    "titolare": "titolare",
    "magazziniere": "magazziniere",
    "cameriere": "cameriere",
}


def _role_credentials():
    """Picks the MySQL user/password for the current request.
    Before login (no user in session) we use the `login` bootstrap account,
    which may only read dipendente/cantina to verify credentials. Once a user
    is logged in we connect as their per-role MySQL user, so GRANT/REVOKE
    enforce what that role can see and do."""
    user = st.session_state.get("user")
    section = _ROLE_SECTION.get(user["ruolo"], "login") if user else "login"
    return st.secrets["mysql"][section]


def _ssl_options():
    """TLS options for the connection. Managed databases (e.g. Aiven) require
    it: when `ssl_ca` in secrets points at a CA certificate we open a verified
    TLS connection. Locally, with no `ssl_ca`, we connect in plaintext as
    before, so the same code runs against the local MariaDB unchanged."""
    ca = st.secrets["mysql"].get("ssl_ca")
    if not ca:
        return {}
    # A relative path is resolved against the repo root (db.py lives in app/),
    # so it works regardless of the process' working directory (e.g. Streamlit
    # Community Cloud runs from the repo root, but this stays correct anyway).
    ca_path = Path(ca)
    if not ca_path.is_absolute():
        ca_path = Path(__file__).resolve().parent.parent / ca_path
    return {"ssl_ca": str(ca_path)}


def get_connection():
    """Connects to MariaDB as the current role's MySQL user (secrets.toml)."""
    cfg = st.secrets["mysql"]
    creds = _role_credentials()
    return pymysql.connect(
        host=cfg["host"],
        port=int(cfg["port"]),
        user=creds["user"],
        password=creds["password"],
        database=cfg["database"],
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=False,
        **_ssl_options(),
    )


def run_query(sql, params=None):
    """Executes a SELECT and returns the fetched rows. `params` is bound
    separately from the SQL text, not interpolated into it."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            return cur.fetchall()
    finally:
        conn.close()


def call_proc(name, args=()):
    """Calls a stored procedure and returns its result rows."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.callproc(name, args)
            return cur.fetchall()
    finally:
        conn.close()


def run_write(sql, params=None):
    """Executes a write statement (INSERT/UPDATE) inside a transaction:
    commits on success, rolls back on error. `params` is bound separately
    from the SQL text."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def call_proc_write(name, args=()):
    """Calls a writing stored procedure: commits on success, rolls back on
    error. Returns the procedure's result rows (e.g. the new id)."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.callproc(name, args)
            rows = cur.fetchall()
        conn.commit()
        return rows
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()
