# 🍷 Cantina DB — winery & beverage storage management

*Relational database and small management app for a winery: global beverage
catalog, per-cellar stock, load/unload movements with **stock derived and kept
consistent by triggers**, wine lists, and role-based employee access.*

> 🇮🇹 Versione italiana più sotto · [Italiano](#-versione-italiana)

Born as a coursework project for **Databases** (University of Trieste) and
extended with a working demo application.

---

## Domain in a nutshell

A **company** (`azienda`) owns one or more **cellars** (`cantina`). Each cellar's
**employees** (`dipendente`) record stock **movements** (`movimenti`) — load,
unload, sale, purchase — on **beverages** (`bevanda`) from a global catalog.
From loads minus unloads we derive the **stock** (`giacenza`), which is an
attribute of the **price list** (`listino`, the beverage-cellar pair). Each
cellar publishes **wine lists** (`carta_vini`).

A beverage specializes — total, exclusive generalization `(t,d)` — into **wine**,
**beer**, **spirit**, **soft drink**; wines model grape varieties (N:M blend),
vinification and aging.

> **Note:** table and column names are in Italian on purpose — they match the
> design document (`docs/progettazione.md`), which is the graded deliverable.

Full E-R schema and design rationale in
[`docs/progettazione.en.md`](docs/progettazione.en.md).

![E-R schema](docs/er.png)

*(vector version: [`docs/er.svg`](docs/er.svg))*

## Technical highlights

- **3NF schema**, verified, with two *deliberate, documented* denormalizations
  (stored stock, `id_cantina` on movements) justified by a volume/operations
  analysis.
- **Triggers** keep stock consistent and forbid negative quantities.
- **Views** as an external schema: each role (waiter, warehouse, owner) sees only
  what it needs.
- **10 example queries** as stored procedures (joins, aggregations, subqueries),
  each tied back to a design choice (Sec. 14) and **runnable in-app** via a
  per-role toggle.
- **Streamlit demo**: employee login, per-cellar stock and wine-list consultation
  (row-scoped to the employee's own cellar), stock-movement registration, atomic
  catalog writes (new beverage / price-list entry) and owner-side employee creation
  — all scoped to the user's company both in the UI and server-side in the procedures.

## Stack

| Component | Technology |
|---|---|
| DBMS | MariaDB 10.6+ (InnoDB, utf8mb4) |
| App | Python + Streamlit |
| DB access | parameterized queries (SQL-injection safe) |

## Repo layout

```
cantina-db/
├── sql/
│   ├── 01_schema.sql      # DDL: tables, constraints, indexes
│   ├── 02_triggers.sql    # stock maintenance (follow_up) + oversell guard
│   ├── 03_seed.sql        # realistic sample data (stock derived via triggers)
│   ├── 04_views.sql       # per-role views (warehouse / owner / waiter)
│   ├── 05_queries_and_sp.sql  # 10 example queries + app write procedures (all stored procedures)
│   └── 06_seed_azienda2.sql   # second company (demo data for per-company scoping)
├── app/                   # Streamlit application
│   ├── db.py              # connection + query/write helpers
│   ├── auth.py            # employee login
│   ├── forms.py           # write forms (movement / price-list / new beverage / new employee)
│   ├── pages.py           # per-role pages (owner / warehouse / waiter)
│   └── app.py             # entry point: login gate, session, role routing
├── docs/
│   ├── progettazione.md   # design document IT (requirements -> logical -> 3NF -> physical -> triggers)
│   ├── progettazione.en.md# design document EN
│   └── er.svg / er.png    # E-R schema
└── README.md
```

## Quick start

```bash
# 1. create the database (as root)
sudo mariadb -e "CREATE DATABASE cantina CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# 2. load the SQL files in numeric order
mariadb -u <user> -p cantina < sql/01_schema.sql
mariadb -u <user> -p cantina < sql/02_triggers.sql
mariadb -u <user> -p cantina < sql/03_seed.sql
mariadb -u <user> -p cantina < sql/04_views.sql
mariadb -u <user> -p cantina < sql/05_queries_and_sp.sql   # stored procedures (queries + app writes)
mariadb -u <user> -p cantina < sql/06_seed_azienda2.sql    # second company (scoping demo)
```

### Demo credentials

Two companies, to show per-company scoping. Passwords are demo-only.

| Company | Username | Role | Password |
|---|---|---|---|
| Enoteca Adriatica | `g.bernardi` | owner | `cantina2026` |
| Enoteca Adriatica | `m.ferri` | warehouse | `cantina2026` |
| Enoteca Adriatica | `s.conti` | waiter | `cantina2026` |
| Enoteca Adriatica | `l.rossi` | warehouse (cellar 2) | `cantina2026` |
| Cantine del Sole | `m.verdi` | owner | `verdi123` |

> ℹ️ The numeric order is significant: triggers (`02`) load **before** the seed
> (`03`) because stock (`giacenza`) is not hardcoded — it starts at 0 and is built
> up by the `follow_up` trigger as the seed inserts the movements.

## Status

🚧 Work in progress — schema, triggers, all three per-role views and the 10 example
queries (stored procedures) complete and validated on MariaDB; the design document
(IT + EN) is complete. The Streamlit app has employee login and a per-role page
(owner / warehouse / waiter), each **row-scoped to its own cellar** and able to run
its Sec. 14 stored-procedure queries via a toggle. The app now **writes**:
movement registration (load/sale → stock kept live by the triggers, oversell surfaced
to the user), price-list entries, atomic new-beverage creation (`crea_bevanda`, Sec. 14.3)
and owner-side employee creation (`crea_dipendente`, Sec. 14.4) scoped to the owner's
company. The app is **split into modules** (`db`/`auth`/`forms`/`pages`/`app`) and a second
company (`06_seed_azienda2.sql`) demonstrates per-company scoping. Still to come: the
GRANT/REVOKE role demo (and new-company onboarding, currently DBA-only) and the remaining
trigger-based constraints (docs Sec. 13.2).

---

<a name="-versione-italiana"></a>
## 🇮🇹 Versione italiana

Database relazionale e piccolo gestionale per una **azienda vinicola**: catalogo
bevande globale, magazzino per cantina, movimenti di carico/scarico con
**giacenza derivata e mantenuta coerente dai trigger**, carte vini e gestione dei
dipendenti con permessi per ruolo.

Nato come elaborato per il corso di **Basi di Dati** (Università di Trieste) ed
esteso con una demo applicativa funzionante.

### Dominio in breve

Un'**azienda** possiede una o più **cantine**. In ogni cantina i **dipendenti**
registrano i **movimenti** di magazzino (carico, scarico, vendita, acquisto)
sulle **bevande** del catalogo globale. Da carichi − scarichi si deriva la
**giacenza**, attributo del **listino** (la coppia bevanda-cantina). Ogni cantina
pubblica delle **carte vini**.

La bevanda si specializza — generalizzazione totale ed esclusiva `(t,d)` — in
**vino**, **birra**, **superalcolico**, **analcolico**; del vino si modellano
vitigni (blend N:M), vinificazione e affinamento.

Schema E-R completo e scelte di progetto in
[`docs/progettazione.md`](docs/progettazione.md) e [`docs/er.svg`](docs/er.svg).

### Caratteristiche tecniche

- **Schema 3NF** verificato, con due denormalizzazioni *deliberate e documentate*
  (giacenza memorizzata, `id_cantina` sui movimenti) motivate dall'analisi di
  volumi/operazioni.
- **Trigger** per mantenere la giacenza coerente e impedire scorte negative.
- **Viste** come schema esterno: ogni ruolo (cameriere, magazziniere, titolare)
  vede solo ciò che gli compete.
- **10 query di esempio** come stored procedure (join, aggregazioni, subquery),
  ciascuna agganciata a una scelta di progetto (Sez. 14) ed **eseguibili
  nell'app** tramite un toggle per ruolo.
- **Demo Streamlit**: login per dipendente, consultazione giacenze e carte vini,
  registrazione movimenti, scritture atomiche sul catalogo (nuova bevanda / voce di
  listino) e creazione dipendenti lato titolare — tutto filtrato sull'azienda
  dell'utente, sia in UI sia lato server nelle procedure.

### Stato

🚧 In sviluppo — schema, trigger, tutte e tre le viste per ruolo e le 10 query di
esempio (stored procedure) completi e validati su MariaDB; il documento di
progettazione (IT + EN) è completo. L'app Streamlit ha il login dipendente e una
pagina per ruolo (titolare / magazziniere / cameriere), ciascuna **filtrata sulla
propria cantina** e con le query stored-procedure della Sez. 14 eseguibili tramite
toggle. L'app ora **scrive**: registrazione movimenti (carico/vendita → giacenza
aggiornata dai trigger, oversell mostrato all'utente), aggiunta a listino, creazione
atomica di una bevanda nuova (`crea_bevanda`, Sez. 14.3) e creazione dipendenti lato
titolare (`crea_dipendente`, Sez. 14.4) filtrata sull'azienda. L'app è **divisa in
moduli** (`db`/`auth`/`forms`/`pages`/`app`) e una seconda azienda
(`06_seed_azienda2.sql`) dimostra lo scoping per azienda. Ancora da fare: la demo dei
permessi GRANT/REVOKE (e l'onboarding di una nuova azienda, per ora solo via DBA) e i
vincoli via trigger rimanenti (documento Sez. 13.2).

> ℹ️ L'ordine numerico è significativo: i trigger (`02`) si caricano **prima** del
> seed (`03`) perché la giacenza non è scritta a mano — parte da 0 e viene costruita
> dal trigger `follow_up` man mano che il seed inserisce i movimenti.
