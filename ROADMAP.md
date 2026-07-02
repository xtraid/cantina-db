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
- [ ] Example queries (joins, aggregations, subqueries)
- [ ] (optional) demo application  ← **Track B**

## Track B — Demo app (this repo)

- [x] `01_schema.sql` — DDL, validated on MariaDB
- [x] `02_triggers.sql` — stock maintenance (`follow_up`) + oversell guard   ← also Track A (sec. 5/13)
- [x] `03_seed.sql` — realistic sample data (stock derived via triggers)
- [x] `04_views.sql` — per-role external schema (warehouse / owner / waiter)  ← also Track A (topic09)
- [x] App: project setup + DB connection (parameterized, injection-safe)  ← topic12
- [x] App: authentication (employee login, role in session)
- [x] App: per-role pages (warehouse / waiter / owner) — each reads its own view
- [ ] App: movement registration (load/sale -> stock moves live)
- [ ] App: permissions demo (GRANT/REVOKE, real DB roles)                 ← topic09
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

Triggers, all per-role views and all per-role pages are done and validated. Next
up on Track B: the **movement-registration screen** (load/sale → stock moves live
via the triggers), then the GRANT/REVOKE permissions demo. Known limitation: the
role views expose every cellar's rows (column-scoped, not row-scoped by cantina) —
per-cantina filtering is future work.
