import datetime

import streamlit as st
import bcrypt
from db import run_query, call_proc, run_write, call_proc_write

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
    tab_stock, tab_queries, tab_move, tab_listino, tab_new = st.tabs(
        ["Stock", "Queries", "Register movement", "Add to price list", "New beverage"]
    )

    with tab_stock:
        rows = run_query(
            "SELECT * FROM v_giacenze_magazziniere WHERE id_cantina = %s",
            (u["id_cantina"],),
        )
        st.dataframe(rows)

    with tab_queries:
        st.subheader("Bottles understock (compared to average)")
        st.dataframe(call_proc("bevande_sotto_media"))
        st.subheader("Never sold in stock")
        st.dataframe(call_proc("bevande_mai_vendute"))

    with tab_move:
        movement_form(u)

    with tab_listino:
        listino_form(u)

    with tab_new:
        new_beverage_form(u)


def movement_form(u):
    tipo = st.selectbox(
        "Type", ["CARICO", "SCARICO", "VENDITA", "ACQUISTO"], key="mv_tipo"
    )
    bevande = run_query(
        "SELECT l.id_bevanda, b.nome FROM listino l "
        "INNER JOIN bevanda b USING(id_bevanda) "
        "WHERE l.id_cantina = %s AND l.attivo = TRUE ORDER BY b.nome",
        (u["id_cantina"],),
    )
    bev = st.selectbox(
        "Beverage", bevande, format_func=lambda b: b["nome"], key="mv_bev"
    )
    qta = st.number_input("Bottles", min_value=1, value=1, step=1, key="mv_qta")
    prezzo = st.number_input(
        "Unit price (optional)", min_value=0.0, value=0.0, step=0.01, key="mv_price"
    )

    id_fornitore = None
    if tipo == "ACQUISTO":
        fornitori = run_query(
            "SELECT id_fornitore, ragione_sociale FROM fornitore "
            "WHERE is_fornitore = TRUE AND attivo = TRUE ORDER BY ragione_sociale"
        )
        forn = st.selectbox(
            "Supplier",
            fornitori,
            format_func=lambda f: f["ragione_sociale"],
            key="mv_forn",
        )
        id_fornitore = forn["id_fornitore"] if forn else None

    if st.button("Register", key="mv_submit"):
        if bev is None:
            st.error("No beverage in this cellar's price list.")
            return
        try:
            run_write(
                "INSERT INTO movimenti "
                "(tipo, quantita_bottiglie, prezzo_unitario, id_bevanda, "
                "id_dipendente, id_cantina, id_fornitore) "
                "VALUES (%s, %s, %s, %s, %s, %s, %s)",
                (
                    tipo,
                    int(qta),
                    prezzo or None,
                    bev["id_bevanda"],
                    u["id_dipendente"],
                    u["id_cantina"],
                    id_fornitore,
                ),
            )
            st.success("Movement registered")
        except Exception as e:
            st.error(f"Rejected: {e}")


def listino_form(u):
    """Add a beverage from the global catalog to this cellar's price list."""
    bevande = run_query(
        "SELECT b.id_bevanda, b.nome FROM bevanda b "
        "WHERE b.attivo = TRUE "
        "AND b.id_bevanda NOT IN (SELECT id_bevanda FROM listino WHERE id_cantina = %s) "
        "ORDER BY b.nome",
        (u["id_cantina"],),
    )
    if not bevande:
        st.info("All active beverages are already in this cellar's price list.")
        return

    bev = st.selectbox(
        "Beverage", bevande, format_func=lambda b: b["nome"], key="pl_bev"
    )
    prezzo_acquisto = st.number_input(
        "Purchase price", min_value=0.0, value=0.0, step=0.01, key="pl_buy"
    )
    prezzo_vendita = st.number_input(
        "Sale price", min_value=0.0, value=0.0, step=0.01, key="pl_sell"
    )
    iva = st.number_input(
        "VAT % (optional)", min_value=0.0, value=0.0, step=0.5, key="pl_iva"
    )

    if st.button("Add to price list", key="pl_submit"):
        if prezzo_vendita < prezzo_acquisto:
            st.error("Sale price must be >= purchase price.")
            return
        try:
            run_write(
                "INSERT INTO listino "
                "(prezzo_vendita, prezzo_acquisto, iva, giacenza, id_bevanda, id_cantina) "
                "VALUES (%s, %s, %s, 0, %s, %s)",
                (
                    prezzo_vendita,
                    prezzo_acquisto,
                    iva or None,
                    bev["id_bevanda"],
                    u["id_cantina"],
                ),
            )
            st.success("Beverage added to price list (stock starts at 0)")
        except Exception as e:
            st.error(f"Rejected: {e}")


def new_beverage_form(u):
    """Create a brand-new beverage in the global catalog (bevanda + subtype),
    optionally creating its producer, atomically via the crea_bevanda SP."""
    nome = st.text_input("Name", key="nb_nome")
    categoria = st.selectbox(
        "Category", ["VINO", "BIRRA", "SUPER_ALCOLICO", "ANALCOLICO"], key="nb_cat"
    )
    gradazione = st.number_input(
        "ABV % (optional)", min_value=0.0, value=0.0, step=0.1, key="nb_abv"
    )
    volume = st.number_input(
        "Volume (optional)", min_value=0.0, value=0.0, step=0.1, key="nb_vol"
    )
    is_biologico = st.checkbox("Organic", key="nb_bio")

    produttori = run_query(
        "SELECT id_produttore, nome FROM produttore WHERE attivo = TRUE ORDER BY nome"
    )
    NEW_PRODUCER = {"id_produttore": None, "nome": "➕ New producer…"}
    scelta_p = st.selectbox(
        "Producer",
        [NEW_PRODUCER] + produttori,
        format_func=lambda p: p["nome"],
        key="nb_prod",
    )
    prod_nome = None
    prod_paese = None
    if scelta_p["id_produttore"] is None:
        prod_nome = st.text_input("New producer name", key="nb_prod_nome")
        prod_paese = st.text_input(
            "New producer country (optional)", key="nb_prod_paese"
        )

    # Wine-only details: shown only when category is VINO
    annata = colore = id_vitigno = percentuale = None
    mese_vendemmia = tipo_vendemmia = durata_legno = tipo_legno = None
    if categoria == "VINO":
        st.markdown("**Wine details**")
        annata = st.number_input(
            "Vintage", min_value=1900, max_value=2100, value=2020, step=1, key="nb_annata"
        )
        colore = st.text_input("Colour (optional)", key="nb_colore")
        vitigni = run_query("SELECT id_vitigno, nome FROM vitigno ORDER BY nome")
        vit = st.selectbox(
            "Grape variety", vitigni, format_func=lambda v: v["nome"], key="nb_vit"
        )
        id_vitigno = vit["id_vitigno"] if vit else None
        percentuale = st.number_input(
            "Grape %", min_value=0.0, max_value=100.0, value=100.0, step=1.0, key="nb_perc"
        )
        mese_vendemmia = st.text_input("Harvest month (optional)", key="nb_mese")
        tipo_vendemmia = st.text_input("Harvest type (optional)", key="nb_tipovend")
        st.caption("Aging (optional)")
        durata_legno = st.number_input(
            "Wood months", min_value=0, value=0, step=1, key="nb_legno"
        )
        tipo_legno = st.text_input("Wood type", key="nb_tipolegno")

    if st.button("Create beverage", key="nb_submit"):
        if not nome:
            st.error("Name is required.")
            return
        if scelta_p["id_produttore"] is None and not prod_nome:
            st.error("New producer name is required.")
            return
        if categoria == "VINO" and id_vitigno is None:
            st.error("A wine needs at least one grape variety.")
            return
        try:
            rows = call_proc_write(
                "crea_bevanda",
                (
                    nome,
                    categoria,
                    gradazione or None,
                    volume or None,
                    is_biologico,
                    scelta_p["id_produttore"],
                    prod_nome or None,
                    prod_paese or None,
                    annata,
                    colore or None,
                    id_vitigno,
                    percentuale,
                    mese_vendemmia or None,
                    tipo_vendemmia or None,
                    durata_legno or None,
                    tipo_legno or None,
                ),
            )
            new_id = rows[0]["id_bevanda"] if rows else "?"
            st.success(
                f"Beverage created (id {new_id}). "
                "Add it to a price list, then load stock."
            )
        except Exception as e:
            st.error(f"Rejected: {e}")


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
