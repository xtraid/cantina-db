import bcrypt
import streamlit as st

from db import run_query, run_write, call_proc_write


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
            "Vintage",
            min_value=1900,
            max_value=2100,
            value=2020,
            step=1,
            key="nb_annata",
        )
        colore = st.text_input("Colour (optional)", key="nb_colore")
        vitigni = run_query("SELECT id_vitigno, nome FROM vitigno ORDER BY nome")
        vit = st.selectbox(
            "Grape variety", vitigni, format_func=lambda v: v["nome"], key="nb_vit"
        )
        id_vitigno = vit["id_vitigno"] if vit else None
        percentuale = st.number_input(
            "Grape %",
            min_value=0.0,
            max_value=100.0,
            value=100.0,
            step=1.0,
            key="nb_perc",
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


def add_employee_form(u):
    nome = st.text_input("First name", key="ae_nome")
    cognome = st.text_input("Last name", key="ae_cognome")
    matricola = st.number_input("Badge number", min_value=1, step=1, key="ae_matricola")
    username = st.text_input("Username", key="ae_user")
    password = st.text_input("Password", type="password", key="ae_pwd")
    email = st.text_input("Email (optional)", key="ae_email")
    ruolo = st.selectbox("Role", ["magazziniere", "cameriere"], key="ae_ruolo")

    cantine = run_query(
        "SELECT id_cantina, nome FROM cantina WHERE id_azienda = %s ORDER BY nome",
        (u["id_azienda"],),
    )
    cantina = st.selectbox(
        "Cellar", cantine, format_func=lambda c: c["nome"], key="ae_cant"
    )

    if st.button("Create employee", key="ae_submit"):
        if not nome or not cognome or not username or not password:
            st.error("First name, last name, username and password are required.")
            return
        password_hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()
        try:
            rows = call_proc_write(
                "crea_dipendente",
                (
                    int(matricola),
                    nome,
                    cognome,
                    ruolo,
                    username,
                    password_hash,
                    email or None,
                    cantina["id_cantina"],
                    u["id_azienda"],
                ),
            )
            new_id = rows[0]["id_dipendente"] if rows else "?"
            st.success(f"Employee created (id {new_id}).")
        except Exception as e:
            st.error(f"Rejected: {e}")
