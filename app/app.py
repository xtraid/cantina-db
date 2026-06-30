import streamlit as st
import bcrypt
from db import run_query

st.title("Cantina * accesso")


def log_in(username, password):
    """search username and
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


def owner_page(u):
    st.header("Owner's dashboard")
    st.write("placeholder: Cellar summary, sales, employee manager")


def store_page(u):
    st.header("Magazzino - giacenze")
    rows = run_query("SELECT * FROM v_giacenze_magazziniere")
    st.dataframe(rows)


def waiter_page(u):
    st.header("Wine sheet")
    st.write("placeholder: wine sheet and sells registration")


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
    st.divider()
    role = u["ruolo"]
    if role == "titolare":
        owner_page(u)
    elif role == "magazziniere":
        store_page(u)
    elif role == "cameriere":
        waiter_page(u)
    else:
        st.warning(f"Role not recognised: {role}")
