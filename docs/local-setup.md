# Local database configuration

After loading the SQL scripts in the [README](../README.md#running-locally),
create `app/.streamlit/secrets.toml` (create the `.streamlit` directory if needed):

```toml
[mysql]
host = "127.0.0.1"
port = 3306
database = "cantina"

[mysql.login]
user = "cantina_login"
password = "login_pw"

[mysql.titolare]
user = "cantina_titolare"
password = "titolare_pw"

[mysql.magazziniere]
user = "cantina_magazziniere"
password = "magazziniere_pw"

[mysql.cameriere]
user = "cantina_cameriere"
password = "cameriere_pw"
```

These are the local demo database accounts created by
[`07_grants.sql`](../sql/07_grants.sql). If you change their passwords, update
this configuration to match. Employee logins are separate: use the
[demo accounts](../DEMO.md#03-demo-credentials) in the app.

For a remote database requiring TLS, add `ssl_ca` under `[mysql]`, pointing to
the provider's CA certificate. Relative certificate paths are resolved from the
repository root. The local configuration above does not enable TLS.

From `app/`, run `uv run streamlit run app.py` and open `http://localhost:8501`.

## Italiano

Dopo aver caricato gli script SQL, crea `app/.streamlit/secrets.toml` con il
contenuto qui sopra, creando la directory `.streamlit` se manca. Le password
sono quelle degli utenti DB definiti in `07_grants.sql`: se le cambi, aggiorna
anche la configurazione. Per accedere all’interfaccia usa invece gli account
dipendente della demo.

Per un DB remoto con TLS, aggiungi `ssl_ca` nella sezione `[mysql]` con il percorso
del certificato CA del provider; i percorsi relativi partono dalla root del repo.
Dalla cartella `app`, esegui `uv run streamlit run app.py` e apri
`http://localhost:8501`.
