import bcrypt

from db import run_query


def log_in(username, password):
    """Looks up the given username and checks the password against its
    stored bcrypt hash. Returns the employee row (dict, includes the
    joined cantina.id_azienda) on match, None if the username is unknown,
    inactive, or the password does not match."""

    rows = run_query(
        "SELECT d.id_dipendente, d.nome, d.cognome, d.ruolo, d.id_cantina, d.password_hash, c.id_azienda "
        "FROM dipendente d "
        "INNER JOIN cantina c USING(id_cantina) "
        "WHERE username = %s AND attivo = TRUE",
        (username,),
    )
    if not rows:
        return None
    user = rows[0]
    if bcrypt.checkpw(password.encode(), user["password_hash"].encode()):
        return user
    return None


def id_azienda(u):
    """Returns the company id of the logged-in user — tenant scope for
    owner-level queries/SP. Set at login (see log_in), so no extra DB
    round-trip."""
    return u["id_azienda"]


def id_cantina(u):
    """Returns the cellar id of the logged-in user — tenant scope for
    warehouse-level queries/SP. Set at login (see log_in)."""
    return u["id_cantina"]
