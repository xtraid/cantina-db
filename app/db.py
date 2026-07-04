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
    """Pick the MySQL user/password for the current request.
    Before login (no user in session) we use the `login` bootstrap account,
    which may only read dipendente/cantina to verify credentials. Once a user
    is logged in we connect as their per-role MySQL user, so GRANT/REVOKE
    enforce what that role can see and do."""
    user = st.session_state.get("user")
    section = _ROLE_SECTION.get(user["ruolo"], "login") if user else "login"
    return st.secrets["mysql"][section]


def get_connection():
    """Connect to MariaDB as the current role's MySQL user (secrets.toml)."""
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
    )


def run_query(sql, params=None):
    """ "Execute a Select and returns the output rows,
    'params' runs separatly from Sql"""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            return cur.fetchall()
    finally:
        conn.close()


def call_proc(name, args=()):
    """Calls store procedure and returns the result records"""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.callproc(name, args)
            return cur.fetchall()
    finally:
        conn.close()


def run_write(sql, params=None):
    """Execute a insert,
    'params' runs separatly from Sql"""
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
    """Call a writing stored procedure: commit on success, rollback on error.
    Returns the procedure's result rows (e.g. the new id)."""
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
