import datetime

import streamlit as st

from db import run_query, call_proc
from auth import id_azienda, id_cantina
from forms import (
    movement_form,
    listino_form,
    edit_listino_form,
    new_beverage_form,
    add_employee_form,
)


def owner_page(u):
    st.header("Owner's dashboard")
    tab_stock, tab_queries, tab_mgmt, tab_emp = st.tabs(
        ["Stock", "Queries", "Management", "Add employee"]
    )

    with tab_stock:
        rows = run_query(
            "SELECT * FROM v_giacenze_titolare WHERE id_azienda = %s",
            (id_azienda(u),),
        )
        st.dataframe(rows)

    with tab_queries:
        st.subheader("Warehouse value (tied-up capital)")
        st.dataframe(call_proc("valore_magazzino", (id_azienda(u),)))
        st.subheader("Average margin by category")
        st.dataframe(call_proc("margine_per_categoria", (id_azienda(u),)))
        st.subheader("Blend wines (>1 grapes variety)")
        st.dataframe(call_proc("vini_blend"))
        st.subheader("Most active employee per winery")
        st.dataframe(call_proc("dipendente_piu_attivo", (id_azienda(u),)))
        st.subheader("QC: stock vs movements (0 rows = OK)")
        st.dataframe(call_proc("verifica_ridondanza", (id_azienda(u),)))

        st.subheader("Top sellers (by period)")
        cantine = run_query(
            "SELECT id_cantina, nome FROM cantina WHERE id_azienda = %s ORDER BY nome",
            (id_azienda(u),),
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

    with tab_mgmt:
        st.subheader("Price list — every cellar of the company")
        st.dataframe(
            run_query(
                "SELECT * FROM v_gestione_azienda WHERE id_azienda = %s",
                (id_azienda(u),),
            )
        )
        st.subheader("Employees")
        st.dataframe(
            run_query(
                "SELECT * FROM v_dipendenti_azienda WHERE id_azienda = %s",
                (id_azienda(u),),
            )
        )

    with tab_emp:
        add_employee_form(u)


def store_page(u):
    st.header("Magazzino - giacenze")
    tab_stock, tab_queries, tab_mgmt, tab_move, tab_listino, tab_new = st.tabs(
        [
            "Stock",
            "Queries",
            "Management",
            "Register movement",
            "Add to price list",
            "New beverage",
        ]
    )

    with tab_stock:
        rows = run_query(
            "SELECT * FROM v_giacenze_magazziniere WHERE id_cantina = %s",
            (id_cantina(u),),
        )
        st.dataframe(rows)

    with tab_queries:
        st.subheader("Bottles understock (compared to average)")
        st.dataframe(call_proc("bevande_sotto_media", (id_cantina(u),)))
        st.subheader("Never sold in stock")
        st.dataframe(call_proc("bevande_mai_vendute", (id_cantina(u),)))

    with tab_mgmt:
        st.subheader("Price list management")
        st.dataframe(
            run_query(
                "SELECT * FROM v_gestione_magazzino WHERE id_cantina = %s",
                (id_cantina(u),),
            )
        )
        st.markdown("**Edit prices / soft-delete**")
        edit_listino_form(u)

    with tab_move:
        movement_form(u)

    with tab_listino:
        listino_form(u)

    with tab_new:
        new_beverage_form(u)


def waiter_page(u):
    st.header("Wine sheet")
    show_sp = st.toggle("Show queries (SP)", key="sp_waiter")
    if show_sp:
        st.subheader("Printable wine list")
        st.dataframe(call_proc("carta_vini_stampa", (id_cantina(u),)))
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
            (id_cantina(u),),
        )
        st.dataframe(rows)
