import datetime

import streamlit as st
import bcrypt
from db import run_query, call_proc

st.title("Cantina * accesso")


def log_in(username, password):
    """search username and
    check if the password hash is the same"""

    rows = run_query(
        "SELECT id_dipendente, nome, cognome, ruolo, id_cantina, password_hash "
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
    show_sp = st.toggle("Show queries (SP)", key="sp_owner")
    if show_sp:
        st.subheader("Warehouse value (tied-up capital)")
        st.dataframe(call_proc("valore_magazzino"))
        st.subheader("Average margin by category")
        st.dataframe(call_proc("margine_per_categoria"))
        st.subheader("Blend wines (>1 grapes variety)")
        st.dataframe(call_proc("vini_blend"))
        st.subheader("Most active employee per winery")
        st.dataframe(call_proc("dipendente_piu_attivo"))
        st.subheader("QC: stock vs movements (0 rows = OK)")
        st.dataframe(call_proc("verifica_ridondanza"))

        st.subheader("Top sellers (by period)")
        cantine = run_query(
            "SELECT id_cantina, nome FROM cantina "
            "WHERE id_azienda = (SELECT id_azienda FROM cantina WHERE id_cantina = %s) "
            "ORDER BY nome",
            (u["id_cantina"],),
        )
        scelta_c = st.selectbox(
            "Winery", cantine, format_func=lambda c: c["nome"], key="ts_cantina"
        )
        col_from, col_to = st.columns(2)
        p_start = col_from.date_input(
            "From", value=datetime.date(2000, 1, 1), key="ts_start"
        )
        p_end = col_to.date_input(
            "To (exclusive)",
            value=datetime.date.today() + datetime.timedelta(days=1),
            key="ts_end",
        )
        p_n = st.number_input("How many", min_value=1, value=5, step=1, key="ts_n")
        st.dataframe(
            call_proc(
                "top_seller",
                (scelta_c["id_cantina"], p_start, p_end, int(p_n)),
            )
        )
    else:
        rows = run_query(
            "SELECT * FROM v_giacenze_titolare "
            "WHERE id_azienda = (SELECT id_azienda FROM cantina WHERE id_cantina = %s)",
            (u["id_cantina"],),
        )
        st.dataframe(rows)


def store_page(u):
    st.header("Magazzino - giacenze")
    show_sp = st.toggle("Show queries (SP)", key="sp_store")
    if show_sp:
        st.subheader("Bottles understock (compared to average)")
        st.dataframe(call_proc("bevande_sotto_media"))
        st.subheader("Never sold in stock")
        st.dataframe(call_proc("bevande_mai_vendute"))
    else:
        rows = run_query(
            "SELECT * FROM v_giacenze_magazziniere WHERE id_cantina = %s",
            (u["id_cantina"],),
        )
        st.dataframe(rows)


def waiter_page(u):
    st.header("Wine sheet")
    show_sp = st.toggle("Show queries (SP)", key="sp_waiter")
    if show_sp:
        st.subheader("Printable wine list")
        st.dataframe(call_proc("carta_vini_stampa", (u["id_cantina"],)))
        st.subheader("Wine technical sheet")
        lista_vini = run_query(
            "SELECT b.id_bevanda, b.nome FROM bevanda b "
            "INNER JOIN vino v USING(id_bevanda) "
            "WHERE b.attivo = TRUE ORDER BY b.nome"
        )
        scelta_v = st.selectbox("Wine", lista_vini, format_func=lambda x: x["nome"])
        st.dataframe(call_proc("vino_tecnical_data", (scelta_v["id_bevanda"],)))
    else:
        rows = run_query(
            "SELECT * FROM v_carta_vini_cameriere WHERE id_cantina = %s",
            (u["id_cantina"],),
        )
        st.dataframe(rows)


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
