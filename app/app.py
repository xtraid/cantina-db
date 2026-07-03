import streamlit as st

from auth import log_in
from pages import owner_page, store_page, waiter_page

st.title("Cantina * accesso")

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
