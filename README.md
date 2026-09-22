# Cantina DB

Cantina DB is a relational database and small management application for a winery.
It started as my Database Systems coursework at the University of Trieste and grew
into a Streamlit application, developed against MariaDB, with a public MySQL-backed demo.

The database tracks companies, cellars, employees, beverages, stock movements and
wine lists. Stock is derived from the movement ledger and maintained by database
triggers rather than edited directly.

**[Live demo](https://cantina-db.streamlit.app/)** ·
**[Demo walkthrough](DEMO.md)** ·
**[Design document](docs/progettazione.en.md)** ·
[Italiano](#italiano)

## What it does

A company can own multiple cellars. Employees record purchases, sales, loads and
unloads against a shared beverage catalog. These movements determine the available
stock for each beverage/cellar pair. The database also models producers, suppliers,
grape varieties, vinification, aging and wine lists.

The Streamlit app lets employees log in, consult stock and wine lists, and perform
the operations available to their role. Warehouse staff register movements and
manage price lists; owners can also create employees within their company.

![E-R diagram](docs/er.png)

[Vector diagram](docs/er.svg) · [Implemented schema and relations](docs/schema.md)

## Technical highlights

- **Normalized relational schema**, with stored stock derived from movements.
- **Stock triggers** update quantities when movements are inserted and reject
  sales or unloads that exceed available stock.
- **Stored procedures** handle reporting and operations such as creating a beverage
  and its related records in one transaction.
- **Role-based access** uses database views and grants for owners, warehouse staff
  and waiters, with company/cellar filtering in the application.
- **Streamlit demo** exposes these operations so you can see triggers and stored
  procedures in action.

## Live demo

[Open the demo](https://cantina-db.streamlit.app/) and sign in with one of the
[demo accounts](DEMO.md#03-demo-credentials). The app may take a little time to wake up.

The [walkthrough](DEMO.md) covers each role. To try the stock logic, log in as a
warehouse employee, register a load, then a sale, and check the updated quantity.
A sale larger than the available stock is rejected by the database trigger.

## Running locally

You need MariaDB 10.6+, Python 3.14+ and `uv`. From the repository root, create a
local database and load the SQL files in numeric order:

```bash
sudo mariadb -e "CREATE DATABASE cantina CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
for script in sql/0[1-7]_*.sql; do
    sudo mariadb cantina < "$script" || break
done
```

Triggers load before the seed: stock starts at zero and is built from the sample
movements. The last script creates the database accounts and grants for each role.

Create `app/.streamlit/secrets.toml` using the
[local configuration example](docs/local-setup.md), then start the app:

```bash
cd app
uv run streamlit run app.py
```

Open `http://localhost:8501` and use the same [demo accounts](DEMO.md#03-demo-credentials).

## Current state

The app supports login, stock and wine-list browsing, movement registration,
price-list changes, beverage creation and employee creation. Movements are
append-only; corrections use compensating movements. New companies are added by a DBA.

Row-level isolation between companies is enforced partly by the application,
rather than entirely by the database. This is the main authorization boundary
I would redesign for production. There is no automated test suite yet;
[DEMO.md](DEMO.md) documents the manual walkthrough.

### Possible next steps

- Enforce company/cellar isolation through one consistent authorization boundary.
- Add automated checks for permissions, stock updates and oversell rejection.
- Add a workflow for creating companies and their first employees.

## Repository layout

- `sql/` — schema, triggers, seed data, views, stored procedures and grants.
- `app/` — Streamlit UI, authentication and database access.
- `docs/` — design documents, schema diagrams and walkthrough screenshots.

## Documentation

- Design: [English](docs/progettazione.en.md) / [Italiano](docs/progettazione.md).
- [Implemented schema](docs/schema.md): foreign-key graph and full relation list.
- [Demo walkthrough](DEMO.md): accounts, screenshots and operations to try.
- [Local configuration](docs/local-setup.md): database connection settings.

## Italiano

Cantina DB è un database relazionale con un piccolo gestionale per una cantina.
È nato come mio elaborato di Basi di Dati all’Università di Trieste ed è diventato
un’applicazione Streamlit, sviluppata su MariaDB, con una demo pubblica su MySQL.
La giacenza deriva dai movimenti ed è mantenuta dai trigger del database.

**[Demo online](https://cantina-db.streamlit.app/)** ·
**[Guida alla demo](DEMO.md#-guida-dimostrativa-versione-italiana)** ·
**[Progettazione](docs/progettazione.md)**

### Cosa fa

Un’azienda possiede una o più cantine. I dipendenti registrano acquisti, vendite,
carichi e scarichi su un catalogo condiviso di bevande: questi movimenti determinano
la giacenza per ogni coppia bevanda/cantina. Il modello comprende anche produttori,
fornitori, vitigni, vinificazione, affinamento e carte vini.

L’app permette di consultare i dati e svolgere le operazioni previste dal proprio
ruolo: il magazziniere registra movimenti e gestisce il listino; il titolare può
anche creare dipendenti della propria azienda. Il [diagramma E-R](docs/er.svg) e lo
[schema implementato](docs/schema.md) descrivono il modello nel dettaglio.

### Caratteristiche tecniche

- Schema relazionale normalizzato, con giacenza memorizzata e derivata dai movimenti.
- Trigger che aggiornano le scorte e bloccano vendite o scarichi superiori al disponibile.
- Stored procedure per le interrogazioni e operazioni atomiche, come creare una bevanda.
- Viste e permessi DB per titolare, magazziniere e cameriere, con filtri per azienda/cantina nell’app.
- Demo Streamlit per vedere trigger e stored procedure in azione.

### Provare la demo

Apri la [demo online](https://cantina-db.streamlit.app/) e usa le
[credenziali demo](DEMO.md#03-demo-credentials). Il primo caricamento può richiedere
un po’ di tempo. Come magazziniere, registra un carico e una vendita e osserva la
giacenza: una vendita superiore alle scorte viene rifiutata dal trigger.
La [guida illustrata](DEMO.md#-guida-dimostrativa-versione-italiana) mostra gli altri percorsi.

### Avvio locale

Servono MariaDB 10.6+, Python 3.14+ e `uv`. I [comandi sopra](#running-locally)
creano il database e caricano gli script SQL in ordine numerico: i trigger precedono
i dati di esempio, così la giacenza viene costruita dai movimenti anche nel seed.
Configura `app/.streamlit/secrets.toml` seguendo l’[esempio locale](docs/local-setup.md),
poi esegui `uv run streamlit run app.py` dalla cartella `app`.
Accedi a `http://localhost:8501` con gli stessi account della demo.

### Stato e limiti

Funzionano login, consultazione di giacenze e carte vini, registrazione dei movimenti,
modifica dei listini, creazione di bevande e dipendenti. I movimenti non si modificano:
gli errori si correggono con movimenti di compensazione. Le nuove aziende le aggiunge il DBA.

L’isolamento delle righe tra aziende dipende in parte dall’applicazione, non è imposto
interamente dal database: è il principale confine di autorizzazione che riprogetterei
per un uso in produzione. Non c’è ancora una suite di test automatici;
la verifica manuale è descritta nella guida alla demo.

I possibili prossimi passi sono rendere uniforme l’autorizzazione, aggiungere test
su permessi e scorte e introdurre un flusso per creare aziende e primi dipendenti.
