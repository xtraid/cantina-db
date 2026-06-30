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
- [ ] **Physical design** — indexes, storage (course topic15) · *scheduled, next days*
- [ ] Example queries (joins, aggregations, subqueries)
- [ ] (optional) demo application  ← **Track B**

## Track B — Demo app (this repo)

- [x] `01_schema.sql` — DDL, validated on MariaDB
- [x] `02_seed.sql` — realistic sample data
- [ ] `03_triggers.sql` — stock maintenance + non-graphical constraints   ← also Track A (sec. 5)
- [ ] `04_views.sql` — per-role external schema                           ← also Track A (topic09)
- [x] App: project setup + DB connection (parameterized, injection-safe)  ← topic12
- [x] App: authentication (employee login, role in session)
- [ ] App: per-role pages (warehouse / waiter / owner)
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
   `03_triggers.sql` in place.
3. **Views before per-role pages.** Each role reads the DB through its own view.
4. Building the app naturally produces the optional "demo application" of Track A
   and exercises course topics 09 (views/permissions), 11 (triggers), 12 (app
   access) on real data.

## Current focus

Track B → **frontend**: start from the design-stable foundation (project setup +
DB connection + login), then slot the trigger in right before the movement screen.
