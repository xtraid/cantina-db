import streamlit as st
import bcrypt
from db import run_query

st.title("Cantina * accesso")


def log_in(username, password):
    """ search username and
    check if the password hash is the same"""

    rows = run_query(
        "SELECT id_dipendente, nome, cognome, ruolo, password_hash "
        "FROM dipendente WHERE username = %s AND attivo = TRUE",
        (username,),
    )
    if not rows:
        return None
    user = rows[0]
    if bcrypt.checkpw(password.encode(), user["password_hash"].encode()):
        return user
    return None


if "user" not in st.session_state:
    st.session_state.user = None

if st.session_state.user is None:
    with st.form("login"):
        username = st.text_input("Username")
        password = st.text_input("password", type="password")
        acces = st.form_submit_button("Access")
    if acces:
        user = log_in(username, password)
        if user:
            st.session_state.user = user
            st.rerun()
        else:
            st.error("Username or password not valid")
else:
    u = st.session_state.user
    st.success(f"Welcome {u['nome']} {u['cognome']} ruolo: **{u['ruolo']}**")
    if st.button("Logout"):
        st.session_state.user = None
        st.rerun()
