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
[`docs/progettazione.md`](docs/progettazione.md) and [`docs/er.svg`](docs/er.svg).

## Technical highlights

- **3NF schema**, verified, with two *deliberate, documented* denormalizations
  (stored stock, `id_cantina` on movements) justified by a volume/operations
  analysis.
- **Triggers** keep stock consistent and forbid negative quantities.
- **Views** as an external schema: each role (waiter, warehouse, owner) sees only
  what it needs.
- **Streamlit demo**: employee login, movement registration, stock and wine-list
  consultation.

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
│   ├── 02_triggers.sql    # (wip) stock, non-graphical constraints
│   ├── 03_views.sql       # (wip) per-role views
│   └── 04_seed.sql        # (wip) realistic sample data
├── app/                   # (wip) Streamlit application
├── docs/
│   ├── progettazione.md   # design document (requirements -> logical -> 3NF)
│   └── er.svg / er.png    # E-R schema
└── README.md
```

## Quick start

```bash
# 1. create the database (as root)
sudo mariadb -e "CREATE DATABASE cantina CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# 2. load the schema
mariadb -u <user> -p cantina < sql/01_schema.sql
```

## Status

🚧 Work in progress — schema complete and validated; triggers, views and app on the way.

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
- **Demo Streamlit**: login per dipendente, registrazione movimenti,
  consultazione giacenze e carte vini.

### Stato

🚧 In sviluppo — schema completo e validato; trigger, viste e app in arrivo.
