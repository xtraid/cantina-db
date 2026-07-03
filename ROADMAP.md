# Roadmap

Two parallel tracks share the same database. **Track A** is the graded exam
project (the written deliverable); **Track B** is the demo management app. They
reinforce each other: several Track B artifacts (triggers, views, app access) are
*also* required pieces of Track A.

Legend: `[x]` done · `[~]` in progress · `[ ]` to do

---

## Track A — Exam project (deliverable, due 2026-07-05)

- [x] Conceptual design — requirements, glossary, E-R schema
- [x] Logical design — relational schema, FK/constraints
- [x] Normalization — 1NF/2NF/3NF verified; deliberate denormalizations documented
- [x] Normalization refinement — Paese/Regione decomposition (2NF)
- [x] **Physical design** — load-justified secondary index on `movimenti` (topic15); documented in Sec. 12
- [x] Procedural constraints — `oversell` + `follow_up` triggers (Sec. 13); row-level CHECKs already in schema
- [x] External schema — per-role views documented (Sec. 12.2)
- [x] Example queries — 10 as stored procedures (Sec. 14): joins, aggregations, subqueries
- [ ] Assembly + compression to <=15pp, then PDF export
- [ ] (optional) demo application  ← **Track B**

## Track B — Demo app (this repo)

- [x] `01_schema.sql` — DDL, validated on MariaDB
- [x] `02_triggers.sql` — stock maintenance (`follow_up`) + oversell guard   ← also Track A (sec. 5/13)
- [x] `03_seed.sql` — realistic sample data (stock derived via triggers)
- [x] `04_views.sql` — per-role external schema (warehouse / owner / waiter)  ← also Track A (topic09)
- [x] App: project setup + DB connection (parameterized, injection-safe)  ← topic12
- [x] App: authentication (employee login, role in session)
- [x] App: per-role pages (warehouse / waiter / owner) — each reads its own view
- [x] App: Sec.14 stored procedures runnable per role (toggle) + per-cantina row scoping
- [x] App: movement registration (load/sale -> stock moves live; oversell shown to the user)
- [x] App: catalog writes — add beverage to price list; create a new beverage (bevanda+subtype+producer, wine details) atomically via `crea_bevanda` SP (Sec. 14.3)
- [x] App: owner adds employees via `crea_dipendente` SP — role guard + per-company scoping (UI dropdown + server-side SIGNAL); bcrypt hashing app-side (Sec. 14.4)
- [x] App: split into modules (`db` / `auth` / `forms` / `pages` / `app`)
- [x] `06_seed_azienda2.sql` — second company, to exercise per-company scoping
- [ ] App: permissions tab (GRANT/REVOKE, real DB roles) + new-company onboarding (currently DBA-only)   ← topic09
- [ ] README polish — app screenshot / short gif

---

## Why this order (sync points)

1. **The app depends on the *logical* schema, which is now frozen.** The pending
   physical design (Track A) is about *indexes/performance* — it does **not**
   change the tables/columns the app queries. So Track B can proceed in parallel.
2. **Trigger before the movement screen.** The "register a movement -> stock
   updates / oversell is blocked" demo is the core mechanic; it needs
   `02_triggers.sql` in place.
3. **Views before per-role pages.** Each role reads the DB through its own view.
4. Building the app naturally produces the optional "demo application" of Track A
   and exercises course topics 09 (views/permissions), 11 (triggers), 12 (app
   access) on real data.

## Current focus

**Track A's written content is complete** — conceptual through physical design,
triggers, external-schema views (Sec. 12.2) and the 10 example queries (Sec. 14) are
all documented, IT and EN in sync. What's left for the deliverable is **compression
to <=15pp and the PDF export**.

On Track B: triggers, all per-role views and per-role pages are done and validated;
each role page runs its Sec.14 stored procedures (via a toggle) and is **row-scoped to
the employee's own cellar** (owner: to their company's cellars). The app now **writes**:
the warehouse page registers movements (load/sale → stock moves live via the triggers,
oversell surfaced to the user), adds beverages to a price list, and creates brand-new
beverages atomically (`crea_bevanda`, Sec. 14.3); the owner adds employees
(`crea_dipendente`, Sec. 14.4) with a role guard and per-company scoping enforced both in
the UI and server-side. The app has been **split into modules** (`db`/`auth`/`forms`/`pages`/
`app`), and `06_seed_azienda2.sql` adds a second company so the scoping is demonstrable.
Next: the GRANT/REVOKE permissions tab and README polish. Two acknowledged limits: row
scoping is enforced at the application level (DB-level GRANT/REVOKE per role is future work),
and onboarding a new company is DBA-only (not exposed in the app).
