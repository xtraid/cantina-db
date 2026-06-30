import pymysql
import streamlit as st


def get_connection():
    """ "Connects to MariaDB using credentials
    in secrets.toml"""
    cfg = st.secrets["mysql"]
    return pymysql.connect(
        host=cfg["host"],
        port=int(cfg["port"]),
        user=cfg["user"],
        password=cfg["password"],
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
