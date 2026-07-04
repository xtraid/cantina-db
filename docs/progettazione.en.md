# Design document — Conceptual design

> English translation of `progettazione.md`. Entity, attribute and relationship
> names are kept in Italian on purpose: they are the identifiers used by the
> schema (`sql/01_schema.sql`) and the graded deliverable.

Management system for wineries (*cantine*) and beverage storage.

---

## 1. Requirements in natural language

The proposed product is a management software for wineries: it positions itself
as a single tool for archiving and managing everything related to beverage
storage. The client company using the product gets a management system for its
own cellars, which keeps track of the employees working there and guarantees
traceability and history of the operations performed on the products.

The main object of management is beverage storage. For each beverage we consider
the type — wine, beer, soft drink or spirit — and the region of origin; for wines
we additionally record specific technical details, such as the grape variety,
the vinification and the aging.

Finally, the system manages warehouse movements: from load and unload movements
the available quantity (stock, *giacenza*) of each beverage is derived. Both
internal movements and external ones, such as supplies, are tracked. On the sales
side, each cellar has one or more wine lists, each collecting a set of beverages
put on offer with their related sales data (such as the price).

---

## 2. Glossary of terms

| Term | Definition | Synonyms / not to be confused with | Links | Frequency |
|---|---|---|---|---|
| Azienda | Client of the system, usually a company | Business/activity (alias); != Produttore and != Fornitore | Cantina | — |
| Cantina | Physical place where products are stored | — | Azienda, Carta vini, Dipendente, Movimento, Listino | — |
| Carta vini | A particular selection of beverages on sale, with their commercial data | = menu/catalog; contains Listino entries | Cantina, Listino, Dipendente | — |
| Listino | Entity with the commercial data of a beverage in a cellar | A standalone entity (NOT attributes of Bevanda); holds both sale price and purchase price | Carta vini, Bevanda, Cantina | — |
| Dipendente | System user with the power to modify it (operator) | = user enabled to modify the system; != customer/consumer (who has no access) | Cantina, Movimento, Carta vini | — |
| Bevanda | Generic stored and managed product (global catalog) | = product; quantities expressed in bottles; stock is NOT an attribute of it but of the Listino (relative to the beverage-cellar pair) | Regione, Produttore, Movimento, Listino, Vino, Birra, Analcolico, Superalcolico | — |
| Vino | Alcoholic beverage obtained from grape fermentation | — | Bevanda, Vitigno, Vinificazione, Affinamento | — |
| Birra | Alcoholic beverage from the fermentation of malt and hops | — | Bevanda | — |
| Analcolico | Generic non-alcoholic beverage | — | Bevanda | — |
| Superalcolico | Spirit or beverage over 20 degrees | — | Bevanda | — |
| Vitigno | Grape variety a wine is made from | = grape / variety | Vino | — |
| Vinificazione | Process turning grapes into wine | != Affinamento != aging (distinct phases) | Vino | — |
| Affinamento | Wine maturation phase after vinification (e.g. in cask or bottle) | != Vinificazione (which precedes it) | Vino | — |
| Regione | Geographic origin of a beverage | Provenance; for wines != denomination (DOC/DOCG) | Bevanda | — |
| Produttore | Who makes the beverage | != Fornitore (who supplies movements); != Azienda (the client) | Bevanda | — |
| Fornitore | Who supplies purchase movements (may also be a customer) | != Produttore (who manufactures); != Azienda | Movimento | — |
| Movimento | Record of a transfer, sale or acquisition of bottles and its value | = operation; load/unload = movement types (sale = unload, supply/acquisition = load); load price != sale price | Bevanda, Giacenza, Dipendente, Cantina, Fornitore | ~3/day (per cellar) |
| Giacenza | Available quantity of a beverage in a cellar, in bottles. Attribute of the **Listino** (beverage-cellar pair), **derived** from movements (loads - unloads), stored for efficiency and kept consistent via triggers | = stock / inventory / availability | Listino, Movimento | — |
| Fornitura | An external purchase movement (NOT an entity: it is a Movimento of type ACQUISTO with a Fornitore) | != Produttore (who manufactures) and != Fornitore (who supplies) | Movimento, Fornitore | ~1-2/week (per cellar) |

> **Frequency note.** Frequencies are estimated **per single cellar**, in a
> reference scenario of a *mid-sized commercial business*. The private -> chain
> scale is a **volume** (number of cellars, already modeled by Azienda -> N
> Cantine), which will be revisited in physical design.

---

## 3. Homogeneous sentences per entity

### Azienda

- The company is the client using the management system.
- For each company we care about: id_azienda, business name, VAT number, type,
  main office address, email, certified email (PEC), phone, owner, website.
- A company owns one or more cellars.

### Cantina

- A cellar is the physical place where beverages are stored.
- For each cellar we care about: id_cantina, name, address, type.
- Each cellar is owned by one and only one company.
- One or more employees work in a cellar.
- Each cellar publishes one or more wine lists and manages its own price lists.
- Warehouse movements happen at a cellar.

### Bevanda (and types: Vino / Birra / Analcolico / Superalcolico)

- A beverage is the generic stored and managed product.
- For each beverage we care about: id_bevanda, name, category (discriminant),
  alcohol content, volume, whether organic, insertion date, notes.
- Each beverage is made by a producer and may come from a region.
- Stock is not a datum of the beverage but of the price list (see below): it
  depends on the cellar.
- A beverage specializes, totally and exclusively (t,d), into wine, beer, spirit
  or soft drink.
- A wine is characterized by: vintage, color, type, method, blend type,
  denomination type, DOC, acidity; it is composed of one or more grape varieties
  (with percentage and vintage), is obtained from a vinification and may undergo
  an aging.
- A beer is characterized by: style, fermentation type, IBU, EBC, original and
  final gravity, whether filtered/pasteurized/refermented, hops, malts, yeast.
- A soft drink is characterized by: category, ingredients, whether with added
  sugars, whether sparkling.
- A spirit is characterized by: category, raw material, distillation type and
  number, years of aging, cask type, whether peated, phenol ppm, blend.

### Vitigno / Vinificazione / Affinamento

- A grape variety is the grape a wine is made from; we care about its name
  (identifier) and a possible synonym.
- A wine is composed of one or more grape varieties; for each variety in the
  blend we record percentage and vintage.
- Vinification is the process of turning grapes into wine (one-to-one with the
  wine); we care about: id_vinificazione, harvest month, maceration days,
  fermentation type, harvest type.
- Aging is the maturation phase of the wine following vinification; we care
  about: id_affinamento, wood duration (months), bottle duration (months), wood
  type, wood format.

### Regione

- A region represents the geographic provenance of a beverage.
- For each region we care about: country name (identifier), ISO code, region
  name, zone.
- A region may be the provenance of many beverages.

### Produttore / Fornitore

- A producer is who makes a beverage; we care about: id_produttore, name,
  country, website.
- A producer makes one or more beverages.
- A supplier is who supplies purchase movements; we care about: id_fornitore,
  business name, VAT number, address, contacts, whether also a customer.
- A supplier may be involved in several movements; it is distinct from the
  producer.

### Dipendente

- An employee is the operator enabled to use/modify the system.
- For each employee we care about: badge number (identifier), first name, last
  name, role, username, email.
- Each employee works in a cellar.
- An employee records movements and curates wine lists.

### Movimenti

- A movement records a warehouse operation (load, unload, sale or purchase) on a
  beverage.
- For each movement we care about: id_movimento, type, number of bottles, unit
  price, date and time.
- Each movement concerns a beverage and happens at a cellar.
- Each movement is recorded by an employee.
- Purchase movements involve a supplier (who supplies), distinct from the
  producer (who makes the beverage).
- The stock of a beverage is updated based on its movements.

### Carta vini / Listino

- A price list records, for a beverage in a cellar, the commercial data and the
  stock; we care about: id_listino, sale price, purchase price, VAT, stock
  (derived from movements), status, last update date.
- A wine list is a selection of beverages on sale, published by a cellar and
  curated by an employee.
- For each wine list we care about: id_carta_vini, title, status,
  creation/publication/archival dates.
- A wine list contains one or more entries, each referring to a price-list entry,
  with an ordering and a position description.

---

## 4. Data dictionary

> **Modeling note.** The dictionary already adopts attribute names in their
> logical-level form (a bridge toward the DDL). The Bevanda generalization is
> **total and exclusive (t,d)**. **Stock** is an attribute of the **Listino**
> (relative to the beverage-cellar pair), **derived** from movements, stored as a
> column for efficiency (denormalization motivated by frequent reads, see Sec. 8)
> and kept consistent by the triggers in Sec. 5.

### 4.1 Entities

| Entity | Description | Attributes | Identifier |
|---|---|---|---|
| Azienda | Client that owns the cellars | id_azienda, ragione_sociale, p_iva, tipo, indirizzo_sede_principale, email, pec, telefono, titolare, sito_web, attivo | id_azienda |
| Cantina | Physical place where beverages are stored | id_cantina, nome, indirizzo, tipo | id_cantina (+ external: azienda) |
| Dipendente | Operator enabled to use/modify the system | matricola, nome, cognome, ruolo, username, password_hash, email, attivo | matricola |
| Regione | Geographic provenance of a beverage | nome_paese, code_iso, nome_regione, zona | nome_paese |
| Vitigno | Grape variety a wine is made from | nome, sinonimo | nome |
| Produttore | Who makes the beverage | id_produttore, nome, paese, sito_web, attivo | id_produttore |
| Fornitore | Who supplies movements (may also be a customer) | id_fornitore, ragione_sociale, p_iva, is_cliente, is_fornitore, indirizzo, telefono, email, attivo | id_fornitore |
| Bevanda | Generic stored product (parent of the t,d generalization) | id_bevanda, nome, categoria (discriminant), gradazione_alcolica, volume, is_biologico, data_inserimento, note, attivo | id_bevanda |
| Vino | Subtype of Bevanda | annata, colore, tipologia, metodo, tipo_blend, tipo_denominazione, doc, acidita | id_bevanda (inherited) |
| Birra | Subtype of Bevanda | stile, tipo_fermentazione, ibu, ebc, densita_originale, densita_finale, is_filtrata, is_pastorizzata, is_rifermentata, luppoli, malti, lievito | id_bevanda (inherited) |
| Super_alcolico | Subtype of Bevanda | categoria, materia_prima, tipo_distillazione, numero_distillazioni, anni_invecchiamento, tipo_botte, is_torbato, ppm_fenoli, blend | id_bevanda (inherited) |
| Analcolico | Subtype of Bevanda | categoria, ingredienti, has_zuccheri_aggiunti, is_frizzante | id_bevanda (inherited) |
| Vinificazione | Process turning grapes into wine (1:1 with Vino) | id_vinificazione, mese_vendemmia, giorni_macerazione, tipo_fermentazione, tipo_vendemmia | id_vinificazione |
| Affinamento | Wine maturation phase (0:1 with Vino) | id_affinamento, durata_legno_mesi, durata_bottiglia_mesi, tipo_legno, formato_legno | id_affinamento |
| Movimenti | Warehouse load/unload of beverages | id_movimento, tipo (CARICO/SCARICO/VENDITA/ACQUISTO), quantita_bottiglie, prezzo_unitario, data_ora | id_movimento |
| Listino | Sale/purchase data and stock of a beverage in a cellar | id_listino, prezzo_vendita, prezzo_acquisto, iva, giacenza (derived from movements, stored), attivo, data_ultimo_aggiornamento | id_listino |
| Carta vini | Selection of beverages on sale, published by a cellar | id_carta_vini, titolo, stato, data_creazione, data_pubblicazione, data_archiviazione, attivo | id_carta_vini |

### 4.2 Relationships

| Relationship | Description | Entities involved | Attributes | Cardinality (min,max) |
|---|---|---|---|---|
| Possiede | A company owns one or more cellars | Azienda, Cantina | — | Azienda (1,N) - Cantina (1,1) |
| Lavora_in | An employee works in a cellar | Dipendente, Cantina | — | Dipendente (1,1) - Cantina (0,N) |
| Produce | A producer makes the beverages | Produttore, Bevanda | — | Produttore (0,N) - Bevanda (1,1) |
| Proviene | A beverage comes from a region | Bevanda, Regione | — | Bevanda (0,1) - Regione (0,N) |
| Generalizzazione | Bevanda specializes into the 4 types (total and exclusive, t,d) | Bevanda -> Vino/Birra/Super_alcolico/Analcolico | discriminant: categoria | total + exclusive coverage |
| Viene_vinificato | A wine is obtained from a vinification | Vino, Vinificazione | — | Vino (1,1) - Vinificazione (1,1) |
| Viene_affinato | A wine may undergo an aging | Vino, Affinamento | — | Vino (0,1) - Affinamento (1,1) |
| Composto | A wine is a blend of one or more grape varieties | Vino, Vitigno | percentuale, annata_vitigno | Vino (1,N) - Vitigno (0,N) |
| Registra | An employee records the movements | Dipendente, Movimenti | — | Dipendente (0,N) - Movimenti (1,1) |
| Avviene_in | A movement happens at a cellar | Movimenti, Cantina | — | Movimenti (1,1) - Cantina (0,N) |
| Coinvolge | A (purchase) movement involves a supplier | Movimenti, Fornitore | — | Movimenti (0,1) - Fornitore (0,N) |
| Riguarda | A price-list entry concerns a beverage | Listino, Bevanda | — | Listino (1,1) - Bevanda (0,N) |
| Contiene | A cellar has its own price lists | Cantina, Listino | — | Listino (1,1) - Cantina (0,N) |
| Pubblica | A cellar publishes the wine lists | Cantina, Carta vini | — | Carta vini (1,1) - Cantina (0,N) |
| Cura | An employee curates a wine list | Dipendente, Carta vini | — | Carta vini (1,1) - Dipendente (0,N) |
| Contiene_voce | A wine list contains price-list entries | Carta vini, Listino | ordine, descrizione_posizione | Carta vini (0,N) - Listino (0,N) |

---

## 5. Constraints not expressible graphically

**Stock / movements** (-> triggers on `movimenti`)

- A beverage's stock cannot become negative (`giacenza >= 0`).
- An unload/sale movement cannot exceed the beverage's current stock.
- A beverage's stock must stay consistent with the sum of its movements (loads -
  unloads): it must be updated automatically on every movement.

**Prices** (-> trigger/check on `listino`)

- The sale price of a price-list entry should be >= the purchase price (no
  below-cost selling).

**Generalization consistency (t,d)** (-> triggers on the subtypes)

- Each beverage has exactly one specialization, consistent with `categoria` (an
  `id_bevanda` present in `vino` => `categoria = 'VINO'`, etc.).
- Only beverages of category VINO can have vinification, aging and grape
  varieties associated.

**Wine / grape varieties**

- The percentages of the grape varieties composing a wine
  (`vino_vitigno.percentuale`) must sum to 100%.

**Movements / supplier**

- A movement of type ACQUISTO must reference a supplier; the other types
  (sale/internal unload) must not.

**Wine list (dates)**

- For a wine list: `data_pubblicazione >= data_creazione` and
  `data_archiviazione >= data_pubblicazione`.

**Wine list (cellar consistency)**

- All price-list entries contained in a wine list must belong to the **same
  cellar** that publishes the list. (The `Pubblica` card->cellar relationship is
  kept for efficiency but is redundant w.r.t. the path card->listino->cellar, see
  Sec. 8.1: this constraint guarantees its consistency.)

---

## 6. E-R schema (reference)

![E-R schema](er.png)

*(vector version: [er.svg](er.svg))*

---

# Part II — Logical design

> Logical design proceeds in two phases: **restructuring** of the E-R schema
> (Sec. 7-9), guided by the application workload, and **translation** into the
> relational model (Sec. 10). Restructuring starts from the analysis of volumes
> and operations.

## 7. Table of volumes and operations

> **Reference scenario:** a multi-tenant system at steady state — a single
> database shared by all client companies, with a global *Bevanda* catalog. The
> *Volume* column therefore counts the **total instances in the system**, derived
> from the base parameters below. **Time horizon** for accumulating data
> (movements): ~2-3 years of operation before periodic archival.

**Base parameters** (rows are derived from these by multiplication): companies
~10^2-10^3; cellars per company ~1-5; employees per cellar ~5-30; beverages in the
global catalog ~10^5-10^6; beverages in stock per cellar ~10^2-10^3;
movements/day per cellar ~50; ~300 operating days/year.

### 7.1 Table of volumes

| Concept | Type (E/R) | Volume (estimated instances) | Notes / how I estimated it |
|---|---|---|---|
| Azienda | E | 10^2-10^3 | product aimed at companies, growth by word of mouth; beyond this scale the infrastructure would need a rework |
| Cantina | E | 10^2-10^4 | Companies x cellars per company (1-5) |
| Dipendente | E | 10^3-10^5 | Cellars x staff per cellar (5-30) |
| Bevanda (catalog) | E | 10^5-10^6 | global shared catalog, essentially static; inflated by vintages/cuvees/different producers |
| Vino (subtype) | E | 10^5-10^6 | dominant share of the catalog (service specialized on wines) |
| Birra / Analcolico / Super_alcolico | E | 10^3-10^5 | niche compared to wines |
| Movimenti | E | 10^7-10^8 | Cellars x ~50/day x ~300 days x 2-3 years. WARNING: dominant table; **grows unbounded** -> periodic archival |
| Listino | E | 10^4-10^7 | Cellars x beverages in stock per cellar (10^2-10^3) |
| Carta vini | E | 10^3-10^5 | Cellars x lists per cellar (8-30); selection browsable by the customer to order |
| Produttore / Fornitore | E | 10^4-10^5 | producers/suppliers worldwide number in the tens of thousands |
| Composto (wine-variety) | R | ~2.5 x Vino (10^5-10^6) | (avg varieties per wine ~2-3) x n. wines; scales with Vino |
| Contiene_voce (card-listino) | R | 10^4-10^6 | Wine lists x entries per list |

### 7.2 Table of operations

> The table covers **service and reporting** operations (the application load that
> drives the redundancy/indexing decisions, Sec. 8/12). **Administrative** operations
> (company/employee onboarding) are by nature very rare and do not impact those
> decisions — they are listed anyway (O6) for completeness, since otherwise `Azienda`
> would remain a table untouched by any operation.

| # | Operation | Type (I/B) | Frequency (per cellar) |
|---|---|---|---|
| O1a | Record a **load** (delivery from supplier) — *management* | I | ~1-3 / week (event, often multi-bottle) |
| O1b | Record an **unload/sale** — *service* | I | ~50 / evening |
| O2 | Consult a beverage's stock | I | ~50 / evening |
| O3 | View / print a wine list | I | ~10-30 / evening |
| O4 | Insert a new beverage in the catalog | I | ~1-5 / week |
| O5 | Supplies / movements report for the month | B | ~2 / month |
| O6 | Register a new client company / employee — *administration* | I | ~1 / year (company), a few / year (employees) — not relevant to the load |

> **Note:** O1a and O1b together make up the "record movement" operation used in
> aggregate in Sec. 8 (the stock cost/benefit analysis applies to *any* insert into
> `Movimenti`, regardless of type — both a load and an unload update the stock). The
> aggregate frequency used in Sec. 8 (~50/evening) remains valid as an estimate of the
> combined set: O1a is a small minority of it, O1b the majority.

---

## 8. Redundancy analysis

**Redundancy analyzed:** **stock** (available quantity in bottles) is derivable
from Movimenti (sum of loads - sum of unloads). Since *Bevanda* is the global
catalog, stock is relative to the (beverage, cellar) pair: it therefore lives on
**Listino**. We assess whether to **store** it as a column on Listino (maintained
by triggers) or **recompute it on the fly** from movements at every consultation.

**Reference period:** one evening of service, a single cellar. Frequencies (from
the operations table): O2 *consult stock* ~50/evening; O1a+O1b *record movement*
(load+unload/sale aggregated) ~50/evening (one movement per bottle, per-bottle
traceability). Convention: a **write** counts **double** (read the block +
rewrite).

`M` = number of movements already accumulated in archive for that beverage in
that cellar (grows over time: movements are not deleted).

| Operation | A) stored stock (on Listino) | B) stock derived from movements |
|---|---|---|
| O2 — consult stock (x50) | reads 1 Listino row = 1 R -> **50** | sums the M movements = M R -> **50*M** |
| O1a/O1b — record movement (x50, aggregated) | write mov (1 W) + read stock (1 R) + update stock (1 W) = 5 -> **250** | write mov (1 W) = 2 -> **100** |
| **Total accesses / evening** | **300** (stable) | **50*M + 100** (grows with M) |

**Break-even:** B is convenient only if `50*M + 100 < 300`, i.e. `M < 4`.
Derivation would be cheaper only as long as each beverage has fewer than ~4
movements in archive; but *Movimenti* is the fastest-growing table, so M exceeds 4
after a few operating days and from there A's advantage grows over time.
Moreover, in a warehouse management system stock is consulted constantly (every
sale checks it): **reads dominate**, and derivation would pay the scan of the
largest table in the database on every read.

**Decision:** we **keep stock stored** as a column on Listino, updated
automatically by the triggers on movements (Sec. 5). We accept the redundancy and
the maintenance cost in exchange for constant-cost reads. *(Possible application
variant: buffer the updates at end of service to reduce writes, at the cost of a
stock that is not real-time during service.)*

### 8.1 Other redundancies considered

Besides stock (an attribute derivable from other entities), the other two forms
of redundancy are evaluated.

**Relationships derivable from a cycle.**

- **Avviene_in (Movimenti-Cantina).** A movement's cellar is derivable from the
  cycle `Movimenti -Registra-> Dipendente -Lavora_in-> Cantina`, assuming the rule
  "an employee records movements only in their own cellar". The relationship is
  therefore formally redundant. **We decide to keep it**: movements are queried by
  cellar constantly (it is the basis of stock computation) and the
  employee<->cellar rule is not stable over time (an employee can be reassigned).
  The redundancy is accepted for efficiency and robustness.
- **Pubblica (Carta vini-Cantina).** A wine list's cellar is derivable from the
  path `Carta vini -Contiene_voce-> Listino -Contiene-> Cantina`. **We decide to
  keep it** for direct card->cellar access; this entails a consistency constraint
  (all entries of a card must belong to the cellar that publishes it), placed
  among the non-graphical constraints (Sec. 5).

**Derivable attributes not stored.** The VAT-included price of a price-list entry
(`prezzo_vendita` + `iva`) and the value of a movement row (`quantita_bottiglie x
prezzo_unitario`) are computed on the fly and not stored.

**Aggregates not stored.** Indicators such as warehouse value or revenue per
cellar are derivable from movements; being required only in periodic reports (O5,
batch, low frequency) they are computed on demand and not stored.

---

## 9. Restructuring of the E-R schema

### 9.1 Removing the generalization (Bevanda -> 4 types, t,d)

The generalization `Bevanda -> {Vino, Birra, Analcolico, Super_alcolico}` is total
and exclusive (t,d). Among the three possible routes (merge into parent, merge
into children, replace with relationship) we choose **replacement with a
relationship**:

- we **keep the parent table `Bevanda`** with id and common attributes;
- we create **4 child tables** (Vino, Birra, Analcolico, Super_alcolico), each
  with its own specific attributes and **PK = FK toward Bevanda** (1:1 link);
- the discriminant `categoria` on Bevanda indicates the corresponding child.

**Rationale.** Bevanda is the global catalog and is **heavily referenced**
(Listino, Movimenti, Produce, Proviene): keeping it as a single entity gives their
FKs a single target and allows queries over the whole catalog without UNION.
Moreover the subtypes have **many distinct attributes** (Vino ~8, Birra ~12,
Super_alcolico ~9, Analcolico ~4): keeping them in separate tables avoids the ~33
mostly-NULL columns that merging into the parent would produce. The cost (one join
to get beverage + subtype detail) is acceptable.

**Resulting constraint** (already in Sec. 5): being a t,d generalization, each
`id_bevanda` must appear in **exactly one** of the 4 child tables, consistently
with `categoria`.

### 9.2 Removing multivalued attributes

Some subtype attributes are effectively **lists** (multiple values for the same
instance) and are not allowed in the logical model. We remove them by transforming
them into a junction table with a composite key. Being a warehouse/sales system
(not a production one), of these values we care about the **name only**: we do not
model doses or quantities, which would concern manufacturing the product.

| Multivalued attribute | Entity | Transformation (PK = the whole pair) |
|---|---|---|
| `luppoli` | Birra | `birra_luppolo(id_bevanda, nome_luppolo)` |
| `malti` | Birra | `birra_malto(id_bevanda, nome_malto)` |
| `ingredienti` | Analcolico | `analcolico_ingrediente(id_bevanda, nome_ingrediente)` |

Each `id_bevanda` is an FK toward the respective child table (Sec. 9.1).

**Non-multivalued cases:**
- `vitigni` of Vino: already modeled as the relationship **Composto** (N:M
  Vino-Vitigno with attributes `percentuale`, `annata_vitigno`) -> already
  normalized, it is the reference model.
- `blend` of Super_alcolico: a descriptive flag (it's a blend / note), not a list
  -> remains an atomic attribute on Super_alcolico.

### 9.3 Choice of primary identifiers

For **entities** we adopt a uniform style with a **surrogate key**: each entity
has a numeric `id_...` column as PK. The choice favors simplicity and stability of
keys (criteria: no optionality, simplicity, frequent use in joins) and is
convenient for implementation (FKs always single-column, ORM-friendly).

**Normalization warning.** The surrogate does not eliminate the functional
dependencies among the natural attributes: normalization (Sec. 10 and normal
forms) must still be conducted on the **natural candidate keys**, not on the
surrogate, which would otherwise mask the violations. Consequently every natural
key remains protected by a `UNIQUE` constraint.

| Entity | PK | Constraint / notes |
|---|---|---|
| Paese | id_paese | `UNIQUE(nome_paese)` (decomposed from Regione, see Sec. 11.2) |
| Regione | id_regione | FK `id_paese`; `UNIQUE(id_paese, nome_regione)` |
| Vitigno | id_vitigno | `UNIQUE(nome)` |
| Dipendente | id_dipendente | `UNIQUE(matricola)` |
| Cantina | id_cantina | FK `id_azienda`; opt. `UNIQUE(id_azienda, numero)` |
| (other entities) | id_... | surrogate already present in the dictionary (Sec. 4) |

**Junction tables (N:M).** For many-to-many relationships we use a **composite
PK** made of the involved FKs (already unique and meaningful, avoids a useless
surrogate):

- `Composto(id_bevanda, id_vitigno)` + attributes `percentuale`, `annata_vitigno`
- `Contiene_voce(id_carta_vini, id_listino)` + attributes `ordine`,
  `descrizione_posizione`
- `birra_luppolo(id_bevanda, nome_luppolo)`, `birra_malto(id_bevanda, nome_malto)`,
  `analcolico_ingrediente(id_bevanda, nome_ingrediente)`

---

## 10. Relational logical schema

> **Notation:** `R(`**PK in bold**`, attributes, FK -> Table)`. Bold attributes
> form the primary key; `FK -> T` indicates a foreign key toward `T`; `[N]` =
> nullable, `[U]` = UNIQUE constraint. The translation applies the choices of
> Sec. 8-9.

**Registries and company structure**

- Azienda(**id_azienda**, ragione_sociale, p_iva, tipo, indirizzo_sede_principale, email, pec, telefono, titolare, sito_web, attivo)
- Cantina(**id_cantina**, nome, indirizzo, tipo, id_azienda -> Azienda)
- Dipendente(**id_dipendente**, matricola [U], nome, cognome, ruolo, username, password_hash, email, attivo, id_cantina -> Cantina)
- Paese(**id_paese**, nome_paese [U], code_iso)
- Regione(**id_regione**, nome_regione, zona, id_paese -> Paese) — UNIQUE(id_paese, nome_regione)
- Produttore(**id_produttore**, nome, paese, sito_web, attivo)
- Fornitore(**id_fornitore**, ragione_sociale, p_iva, is_cliente, is_fornitore, indirizzo, telefono, email, attivo)
- Vitigno(**id_vitigno**, nome [U], sinonimo)

**Bevanda and subtypes** (generalization translated with 1:1 relationship, Sec. 9.1)

- Bevanda(**id_bevanda**, nome, categoria, gradazione_alcolica, volume, is_biologico, data_inserimento, note, attivo, id_produttore -> Produttore, id_regione -> Regione [N])
- Vino(**id_bevanda** -> Bevanda, annata, colore, tipologia, metodo, tipo_blend, tipo_denominazione, doc, acidita)
- Birra(**id_bevanda** -> Bevanda, stile, tipo_fermentazione, ibu, ebc, densita_originale, densita_finale, is_filtrata, is_pastorizzata, is_rifermentata, lievito)
- Super_alcolico(**id_bevanda** -> Bevanda, categoria, materia_prima, tipo_distillazione, numero_distillazioni, anni_invecchiamento, tipo_botte, is_torbato, ppm_fenoli, blend)
- Analcolico(**id_bevanda** -> Bevanda, categoria, has_zuccheri_aggiunti, is_frizzante)

**Wine details** (1:1 with Vino)

- Vinificazione(**id_vinificazione**, mese_vendemmia, giorni_macerazione, tipo_fermentazione, tipo_vendemmia, id_bevanda -> Vino [U])
- Affinamento(**id_affinamento**, durata_legno_mesi, durata_bottiglia_mesi, tipo_legno, formato_legno, id_bevanda -> Vino [U])

**Warehouse and sales**

- Listino(**id_listino**, prezzo_vendita, prezzo_acquisto, iva, giacenza, attivo, data_ultimo_aggiornamento, id_cantina -> Cantina, id_bevanda -> Bevanda) — UNIQUE(id_cantina, id_bevanda)
- Movimenti(**id_movimento**, tipo, quantita_bottiglie, prezzo_unitario, data_ora, id_bevanda -> Bevanda, id_cantina -> Cantina, id_dipendente -> Dipendente, id_fornitore -> Fornitore [N])
- Carta_vini(**id_carta_vini**, titolo, stato, data_creazione, data_pubblicazione, data_archiviazione, attivo, id_cantina -> Cantina, id_dipendente -> Dipendente)

**Junction tables** (N:M and multivalued attributes, composite PK)

- Composto(**id_bevanda** -> Vino, **id_vitigno** -> Vitigno, percentuale, annata_vitigno)
- Contiene_voce(**id_carta_vini** -> Carta_vini, **id_listino** -> Listino, ordine, descrizione_posizione)
- birra_luppolo(**id_bevanda** -> Birra, **nome_luppolo**)
- birra_malto(**id_bevanda** -> Birra, **nome_malto**)
- analcolico_ingrediente(**id_bevanda** -> Analcolico, **nome_ingrediente**)

> **Translation notes (choices adopted).**
> 1. **Movimenti** references `id_bevanda` and `id_cantina` directly: the
>    `giacenza` on Listino is derived by summing movements with the same
>    (beverage, cellar). The direct movement->cellar link is the `Avviene_in`
>    relationship kept for efficiency (Sec. 8.1). *Alternative:* have Movimenti
>    point to `id_listino` (which already encodes beverage+cellar).
> 2. **Vinificazione/Affinamento** are translated as separate relations with a 1:1
>    FK toward Vino. *Alternative:* merge Vinificazione into Vino (1:1 mandatory on
>    both sides); we preferred to keep them distinct for conceptual clarity.
> 3. The `id_regione` FK on Bevanda is nullable (optional provenance); all other
>    entity FKs are NOT NULL except `id_fornitore` on Movimenti (only for purchase
>    movements).

---

## 11. Verification of normal forms

> The logical schema (Sec. 10) derives methodically from a well-formed E-R — each
> entity represents a single concept and each association is correctly reified —
> so it is **already substantially in 3NF by construction**. This section
> **verifies** it formally (1NF -> 2NF -> 3NF) and documents the points where a
> normal form has been **deliberately broken** for workload reasons.
>
> **Methodological warning (Sec. 9.3).** The analysis is conducted on the
> **natural candidate keys** (those protected by `UNIQUE`), not on the surrogates
> `id_...`: being invented keys on which every attribute trivially depends, the
> surrogates would **mask** the real functional dependencies among natural
> attributes and would make any table appear 3NF. **Anticipated outcome:** the
> schema is in 3NF, **except for two deliberate denormalizations** (stock and
> `Movimenti.id_cantina`), already motivated in the redundancy analysis (Sec. 8
> and 8.1).

### 11.1 First normal form (1NF)

All columns are **atomic**: a single value per cell, no repeating groups. The only
originally multivalued attributes — `luppoli` and `malti` of Birra, `ingredienti`
of Analcolico — were already removed during restructuring (Sec. 9.2),
transforming them into the tables `birra_luppolo`, `birra_malto` and
`analcolico_ingrediente`. No relation contains lists or repeating groups -> **the
whole schema is in 1NF**.

### 11.2 Second normal form (2NF)

2NF concerns **only** the **partial** dependencies on a **composite** key (a
non-key attribute depending on only part of the PK).

- **18 entities with a simple PK** (surrogate `id_...`): a 1NF relation with a
  simple PK is **automatically in 2NF**, because there is no "part" of the key on
  which an attribute could partially depend.
- **5 tables with a composite PK** (N:M junctions and multivalued) — the only ones
  to verify:
  - `Composto(`**id_bevanda, id_vitigno**`, percentuale, annata_vitigno)`:
    `percentuale` and `annata_vitigno` depend on the **whole pair** — the vintage
    is that of *that grape variety in that specific wine*, not of the variety in
    itself (the same variety enters blends of different vintages in different
    wines). No partial dependency.
  - `Contiene_voce(`**id_carta_vini, id_listino**`, ordine, descrizione_posizione)`:
    `ordine` and `descrizione_posizione` describe the position of *that entry in
    that card* -> depend on the pair.
  - `birra_luppolo`, `birra_malto`, `analcolico_ingrediente`: **all-key** (no
    non-key attribute) -> trivially in 2NF (and 3NF): there is no attribute that
    could depend partially or transitively on anything.

**Paese/Regione decomposition (to preserve 2NF).** To represent several regions in
the same country (e.g. Piemonte and Veneto in Italy) the natural key of a merged
`Regione` would be `(nome_paese, nome_regione)`. But `code_iso` depends **only** on
`nome_paese` — a *part* of the key -> **partial dependency**, a 2NF violation (the
ISO code is a property of the Country, not of the region). To avoid it we
**decompose** into `Paese(`**nome_paese**`, code_iso)` and
`Regione(`**nome_regione**`, zona, -> Paese)`: this way in `Paese` `code_iso`
depends on the whole key and `Regione` no longer holds attributes of the Country
-> both in 2NF.

-> **the whole schema is in 2NF**.

### 11.3 Third normal form (3NF)

3NF forbids **transitive dependencies** among non-key attributes (`A -> B -> C`)
and **computed columns**. Conducted on natural keys, the schema is in **3NF by
construction**: each table describes a single entity or association and its
attributes describe the key directly. The few functional dependencies among
natural attributes have a **candidate key as determinant** and therefore do not
violate 3NF — for example in `Paese` the FD `nome_paese -> code_iso` (the ISO
code is determined by the country) has `nome_paese` as determinant, which is a
candidate key (`UNIQUE`).

Moreover, the derivable attributes that are **not stored** (VAT-included price of
a price-list entry, value of a movement row `quantita x prezzo`, report
aggregates — Sec. 8.1) **preserve** 3NF precisely because they are computed on the
fly and not materialized: the violation is not "a computable value exists", it is
*storing it*.

Two **stored attributes that knowingly violate 3NF** are the exception, already
decided in the redundancy analysis:

1. **`giacenza` (on Listino) — computed column.** It is derivable from
   `Movimenti` (sum of loads - sum of unloads for the beverage-cellar pair):
   storing it makes it a **redundant** datum, violating the "no computed columns"
   rule. *Deliberate choice* (Sec. 8): stock is **read** constantly (every sale
   checks it) while deriving it would cost the scan of the largest table in the
   database on every read; we accept the redundancy in exchange for
   constant-cost reads, keeping the value consistent with the **triggers** on
   movements (Sec. 5).

2. **`id_cantina` (on Movimenti) — transitive dependency.** The chain
   `id_movimento -> id_dipendente -> id_cantina` holds: a movement is recorded by
   an employee (`Registra`) who works in a cellar (`Lavora_in`). So a non-key
   attribute (`id_dipendente`) determines another non-key one (`id_cantina`) ->
   transitive dependency. *Deliberate choice* (Sec. 8.1): movements are queried
   **by cellar** constantly (it is the basis of stock computation) and the
   employee<->cellar rule is **not stable** over time — an employee can be
   reassigned, but their movements stay in the cellar where they happened ->
   keeping `id_cantina` direct is more **robust**, as well as more efficient.

Both respect the **four criteria** of a good denormalization: done deliberately,
with an excellent reason, aware of the consistency cost (managed via triggers),
and **documented**. The course slides stop at 3NF: BCNF is not considered.

### 11.4 Summary

| Normal form | Outcome | Detail |
|---|---|---|
| **1NF** | satisfied by the whole schema | atomic columns; multivalued already removed in Sec. 9.2 (hops/malts/ingredients -> dedicated tables) |
| **2NF** | satisfied by the whole schema | 18 entities with simple PK -> automatic; 5 with composite PK verified (full dependency on `Composto`/`Contiene_voce`; 3 all-key trivial); `Regione` decomposed into `Paese`+`Regione` to avoid the partial dependency of `code_iso` |
| **3NF** | satisfied except 2 deliberate choices | knowing violations: `giacenza` (computed column) and `Movimenti.id_cantina` (transitive via employee), motivated in Sec. 8/8.1 and maintained by the triggers |

---

## 12. Physical design and external schema

> Input to this section: the logical schema (Sec. 10, already frozen) and the
> **application load** (Sec. 7 — table of volumes and operations). In relational
> RDBMSs, physical design in practice reduces to **index selection**: the engine
> (MariaDB/InnoDB) already uses a B-tree as its primary structure (every table is
> physically organized around its own PK — access by PK requires no extra index),
> so here we only justify **secondary indexes**.

**Base indexes (already present in `01_schema.sql`).** Every foreign key involved
in frequent joins (Sec. 10) is indexed — recommended practice since FKs are
almost always used in join or filter conditions. This already covers, with no
further reasoning needed, O1a/O1b-O4 on the small/medium-sized tables
(`listino`, `carta_vini`, `bevanda`, etc.).

**Case analyzed: `Movimenti` and the monthly report (O5).** `Movimenti` is, by
construction (Sec. 7.1), the dominant table of the system: it grows without ever
deleting rows (10^7-10^8 expected instances). Operation O5 ("supplies/movements
report for the month", batch, ~2/month per cellar) typically filters by
**cellar** and by **date range** — but `data_ora` was not covered by any index,
only the FKs (`id_bevanda`, `id_dipendente`, `id_cantina`, `id_fornitore`) were.
Without an index on `data_ora`, every O5 would degenerate into a full scan of
the largest table in the database.

*Cost/benefit analysis (same method as Sec. 8):* O1a+O1b (record movement,
aggregated) are much more frequent than O5 (~50/evening vs ~2/month), but
frequency alone doesn't decide — what matters is the **cost per operation**. A
B-tree index costs, on every INSERT, an **O(log n)** update (a few extra pages),
while the absence of an index costs, on every O5, a **full scan** of the
dominant table. The small repeated overhead on O1a/O1b is negligible compared
to the huge scan avoided on O5 -> the index is worth it despite O1a/O1b
dominating in frequency.

*Chosen solution:* a **composite** index `(id_cantina, data_ora)` instead of a
single one on `data_ora`, because O5 typically filters by cellar **and** by date
together, and by the **leftmost prefix** rule a composite index automatically
also serves queries that filter on `id_cantina` alone. This made the previous
single index `idx_movimenti_cantina` **redundant** (same prefix, no additional
benefit, only extra write/space cost) -> **removed** and replaced by
`idx_movimenti_cantina_data`:

```sql
CREATE INDEX idx_movimenti_cantina_data ON movimenti(id_cantina, data_ora);
```

**Why no other indexes.** Consistent with the principle "an index speeds up
reads but slows down writes and takes up space" (you don't index everything), no
further indexes are added beyond this one: stock (O2) is already covered by the
`UNIQUE(id_cantina, id_bevanda)` constraint on `Listino` (which is effectively
an index); browsing the wine list (O3) is already covered by the composite PK
`(id_carta_vini, id_listino)` of `Contiene_voce`, whose leftmost prefix serves
exactly the "all entries of a list" pattern; reference tables (`produttore`,
`fornitore`, etc.) have volumes and read/write frequencies too low to justify
indexes beyond the FKs already present.

### 12.1 Secondary index summary

| Index | Table | Columns | Operation that justifies it |
|---|---|---|---|
| `idx_movimenti_cantina_data` | Movimenti | `(id_cantina, data_ora)` | O5 — monthly report per cellar; also covers cellar-only filters (leftmost prefix) |
| `idx_movimenti_bevanda` | Movimenti | `id_bevanda` | join/filter by beverage (stock computation, triggers) |
| `idx_movimenti_dipendente` | Movimenti | `id_dipendente` | O1a/O1b — join on `Registra` |
| `idx_movimenti_fornitore` | Movimenti | `id_fornitore` | O5 — supplies report |
| `uq_listino_bevanda_cantina` (UNIQUE) | Listino | `(id_cantina, id_bevanda)` | O2 — consult stock, point access |
| Composite PK `Contiene_voce` | Carta_vini_voce | `(id_carta_vini, id_listino)` | O3 — view wine list, ordered by entry |

### 12.2 External schema: per-role views

Beyond the logical schema (conceptual/logical level) and the physical one (internal
level), the system defines an **external level** through views (`04_views.sql`). Each
view is the external schema of an application **role**: it exposes only the pertinent
and authorized columns, hiding the rest. This applies the **abstraction and security**
principle of views (t09): permissions are granted on the *views*, not on the base
tables, so a role never sees columns it is not entitled to. Views are **virtual**
(re-executed on each access, not materialized copies of the data) and directly feed the
per-role pages of the demo.

| View | Role | Exposes | Hides |
|---|---|---|---|
| `v_giacenze_magazziniere` | warehouse clerk | cellar, beverage, category, producer, stock, sale price | financial data (cost, margin) |
| `v_giacenze_titolare` | owner | as above **+** purchase price and margin | — (role with full visibility) |
| `v_carta_vini_cameriere` | waiter | wine-list title, position, beverage, producer, sale price | only `pubblicata` and active lists; no stock/cost data |

The first two start from the same base (`listino` joined with `bevanda`, `produttore`,
`cantina`, filtered on `attivo`): the difference is **only in the set of columns**,
which is exactly the point of views as an external schema. The third filters
`stato = 'pubblicata' AND attivo` — the waiter sees only what is actually in service,
not drafts or archived lists.

```sql
CREATE OR REPLACE VIEW v_giacenze_magazziniere AS
    SELECT c.id_cantina, c.nome AS nome_cantina, b.nome AS descrizione_bevanda, b.categoria,
           p.nome AS nome_produttore, l.giacenza, l.prezzo_vendita
    FROM listino l
    INNER JOIN bevanda b    USING(id_bevanda)
    INNER JOIN produttore p USING(id_produttore)
    INNER JOIN cantina c    USING(id_cantina)
    WHERE l.attivo = TRUE AND b.attivo = TRUE
    ORDER BY c.id_cantina, l.giacenza DESC;

CREATE OR REPLACE VIEW v_giacenze_titolare AS
    SELECT c.id_azienda, c.id_cantina, c.nome AS nome_cantina, b.nome AS descrizione_bevanda, b.categoria,
           p.nome AS nome_produttore, l.giacenza, l.prezzo_vendita, l.prezzo_acquisto,
           (l.prezzo_vendita - l.prezzo_acquisto) AS margine
    FROM listino l
    INNER JOIN bevanda b    USING(id_bevanda)
    INNER JOIN produttore p USING(id_produttore)
    INNER JOIN cantina c    USING(id_cantina)
    WHERE l.attivo = TRUE AND b.attivo = TRUE
    ORDER BY c.id_cantina, l.giacenza DESC;

CREATE OR REPLACE VIEW v_carta_vini_cameriere AS
    SELECT c.id_cantina, cv.titolo, c.nome AS cantina_di_provenienza, v.descrizione_posizione, v.ordine,
           b.nome AS descrizione_bevanda, b.categoria, p.nome AS produttore, l.prezzo_vendita
    FROM carta_vini cv
    INNER JOIN cantina c         USING(id_cantina)
    INNER JOIN carta_vini_voce v USING(id_carta_vini)
    INNER JOIN listino l         USING(id_listino)
    INNER JOIN bevanda b         USING(id_bevanda)
    INNER JOIN produttore p      USING(id_produttore)
    WHERE cv.stato = 'pubblicata' AND cv.attivo = TRUE
      AND l.attivo = TRUE AND b.attivo = TRUE
    ORDER BY cv.titolo, v.ordine;
```

> **Consistency note:** in `v_carta_vini_cameriere` the cellar shown is that of the list
> (`carta_vini.id_cantina`), while the price comes from the listino entry: the two
> coincide thanks to the constraint "entries of a list in the same cellar" (Sec. 5),
> enforced by the `carta_vini_coerenza_cantina` trigger (Sec. 13.2), which guarantees the
> view is correct.

#### 12.2.1 Per-cellar scoping (application level)

The views also expose the identifiers `id_cantina` (and `id_azienda` for the owner):
these are not "domain" data but **filter keys**. Given the logged-in employee, the
application restricts the view to their scope:

- **warehouse clerk** and **waiter** → to their own cellar: `WHERE id_cantina = ?`
  (`?` = the session user's `dipendente.id_cantina`);
- **owner** → to the cellars of their own company:
  `WHERE id_azienda = (SELECT id_azienda FROM cantina WHERE id_cantina = ?)`.

Two important caveats:

- The filter is at the **application level**, not real access control: the demo connects
  with a **single** MariaDB user that technically sees everything. DB-level enforcement
  (`GRANT`/`REVOKE` per role on the views) is the "strong" external schema and remains a
  planned extension.
- The owner's ownership is **derived from the assigned cellar**
  (`dipendente.id_cantina → cantina.id_azienda`), because `azienda.titolare` is a **textual**
  attribute and not an FK to `dipendente`. With a single company in the seed the two readings
  coincide; the "full" model would require an FK `azienda.id_titolare → dipendente`.

---

## 13. Procedural constraints (triggers)

> Input to this section: the constraints not expressible graphically listed in
> Sec. 5. A **CHECK** in MariaDB is evaluated at the **single-row** level (it can
> only compare columns of the same row being inserted/updated); a constraint
> that requires reading **other rows** or **other tables** — like the first
> group in Sec. 5 (stock/movements) — is not expressible with a CHECK and
> requires a **trigger**.

### 13.1 Implemented triggers

**`oversell`** — `BEFORE INSERT ON movimenti`, `FOR EACH ROW`.

Implements the second constraint of the "Stock / movements" group in Sec. 5 ("an
unload/sale movement cannot exceed the beverage's current stock"). For movements
of type `SCARICO`/`VENDITA`, it reads the current stock of the
`(id_cantina, id_bevanda)` pair from `Listino` into a local variable and raises
an application error (`SIGNAL SQLSTATE '45000'`) that prevents the insert if the
stock is **insufficient** relative to `NEW.quantita_bottiglie` **or nonexistent**
(`v_giacenza IS NULL`: the pair is not in the listino, so there is nothing to
unload):

```sql
DELIMITER $$
CREATE TRIGGER oversell BEFORE INSERT
  ON movimenti
  FOR EACH ROW
  BEGIN
    DECLARE v_giacenza INT DEFAULT NULL;
    IF NEW.tipo IN ('SCARICO','VENDITA') THEN
      SELECT qr.giacenza INTO v_giacenza FROM (SELECT l.giacenza FROM listino l
      WHERE l.id_cantina = NEW.id_cantina AND l.id_bevanda = NEW.id_bevanda) as qr
      ;
      IF v_giacenza IS NULL OR v_giacenza < NEW.quantita_bottiglie THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Bottiglie insufficienti';
      END IF;
    END IF;
  END$$
DELIMITER ;
```

**`follow_up`** — `AFTER INSERT ON movimenti`, `FOR EACH ROW`.

Implements the first and third constraints of the same group ("stock cannot
become negative" — guaranteed upstream by `oversell` plus the CHECK
`chk_listino_giacenza` on `Listino` as a safety net — and "stock must remain
consistent with the sum of movements, updated automatically"). After a movement
is inserted, it updates `Listino.giacenza` for the `(id_cantina, id_bevanda)`
pair: increasing for `CARICO`/`ACQUISTO`, decreasing for `SCARICO`/`VENDITA`.
Being `AFTER INSERT`, it only acts on movements already validated by
`oversell` (unload side).

On the **load** side, the `UPDATE` protects consistency by checking `ROW_COUNT()`
right after: if it touched **0 rows**, the `(id_cantina, id_bevanda)` pair is not
in the listino, so stock would be lost silently — the movement is therefore
rejected with `SIGNAL` (and the INSERT rolled back). This is the design choice
"first create the listino entry, then load": a load doesn't know prices, so it
cannot auto-create the `Listino` row. The check is safe because
`chk_movimenti_quantita` (`quantita_bottiglie > 0`) guarantees the `UPDATE`
always modifies the row when it exists.

```sql
DELIMITER $$
CREATE TRIGGER follow_up AFTER INSERT
  ON movimenti
  FOR EACH ROW
  BEGIN
    IF NEW.tipo IN ('CARICO', 'ACQUISTO') THEN
      UPDATE listino SET giacenza = giacenza + NEW.quantita_bottiglie
      WHERE id_cantina = NEW.id_cantina AND id_bevanda = NEW.id_bevanda;
      IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Carico su bevanda non presente nel listino della cantina';
      END IF;
    END IF;
    IF NEW.tipo IN ('SCARICO', 'VENDITA') THEN
      UPDATE listino SET giacenza = giacenza - NEW.quantita_bottiglie
      WHERE id_cantina = NEW.id_cantina AND id_bevanda = NEW.id_bevanda;
    END IF;
  END$$
DELIMITER ;
```

As a consequence, in `03_seed.sql` stock is no longer explicitly assigned in
`Listino`: it starts from `DEFAULT 0` and is entirely derived from the
movements loaded in the same file, via `follow_up` — consistency between seed
data and application logic verified directly on the DB (expected values
40/5/20/12/30/96/8 confirmed for the 7 rows of `Listino`).

*Verification performed:* both triggers loaded on the real DB; tested an unload
insert exceeding available stock (correctly blocked by `oversell` with error
1644/45000), a load on a pair not present in the listino (blocked by `follow_up`
via `ROW_COUNT() = 0`, with the INSERT rollback confirmed) and a valid insert
(accepted, with `Listino.giacenza` correctly updated by `follow_up`).

> **Scope: INSERT only.** Both triggers are on `INSERT`: `UPDATE` and `DELETE` on
> `Movimenti` do not recompute stock. This is consistent with the **append-only**
> design of movements (Sec. 7.1: movements are never deleted, they accumulate and
> are periodically archived): a correction is recorded as a new movement of the
> opposite sign, not by modifying or deleting existing ones. Stock therefore stays
> consistent with the sum of movements at all times.

### 13.2 Other Sec. 5 constraints — single-row CHECKs and multi-row triggers

The Sec. 5 constraints expressible at the **single-row** level are implemented as
`CHECK` in `01_schema.sql` (evaluated by the engine on every insert/update). The
constraints that require reading **other rows or other tables** are implemented as
triggers in `02_triggers.sql`:

| Constraint (Sec. 5) | Mechanism | Rationale | Status |
|---|---|---|---|
| Sale price >= purchase price | CHECK | comparison between columns of the same `Listino` row | done (`chk_listino_prezzo`) |
| `ACQUISTO` movement requires a supplier, other types don't | CHECK | comparison between columns of the same `Movimenti` row | done (`chk_movimenti_acquisto`) |
| Wine list: `data_pubblicazione >= data_creazione`, `data_archiviazione >= data_pubblicazione` | CHECK | comparison between columns of the same `Carta_vini` row | done (`chk_cartavini_date_pub`, `chk_cartavini_date_arch`) |
| Generalization consistency (t,d): `categoria` consistent with presence in `vino`/`birra`/`analcolico`/`super_alcolico` | trigger | requires reading the parent `bevanda` row from the subtype | done (`isa_vino`, `isa_birra`, `isa_super_alcolico`, `isa_analcolico`) |
| Grape variety percentages (`vino_vitigno.percentuale`) sum to 100% | trigger + SP | aggregate over multiple rows of the same beverage | done — see note below (`vino_vitigno_somma` + `crea_bevanda`) |
| Cellar consistency between wine list and listino entries | trigger | requires traversing `Carta_vini_voce` -> `Listino` to compare cellar | done (`carta_vini_coerenza_cantina`) |

> **Note on the "percentages = 100%" constraint.** Exact equality is an aggregate over
> multiple rows that are only complete once the whole blend is inserted: a row-by-row trigger
> cannot enforce it without *deferred* constraints (absent in MariaDB), since it would already
> reject the first row of every blend. The constraint is therefore realized on **two levels**:
> (1) the `vino_vitigno_somma` trigger (`BEFORE INSERT`) is a model-level safety net, rejecting
> any overshoot (`sum > 100`); (2) the `crea_bevanda` stored procedure (Sec. 14.3) receives the
> **whole** blend as JSON and enforces exact equality `= 100` before writing. The app uses only
> the SP and never inserts into `vino_vitigno` directly: the abstraction guarantees the
> invariant, the trigger protects it from other writes.

> **Scope: `INSERT` only.** Like `oversell`/`follow_up` (Sec. 13.1), the integrity triggers
> in this section cover `INSERT` only: a direct `UPDATE` on `vino_vitigno.percentuale`,
> `bevanda.categoria` or `listino.id_cantina` would bypass them. A deliberate choice: the
> application exposes none of those `UPDATE`s, and full coverage would require mirror
> triggers without adding design content.

### 13.3 Concurrency: oversell / follow_up race condition (not handled — design note)

`oversell`'s `SELECT` is a **non-blocking** read: two concurrent `VENDITA` movements on
the same `(id_cantina, id_bevanda)` pair can both read the same stock (e.g. 5) and both
pass the check, driving stock below zero. In this scenario the second `follow_up`
`UPDATE` is still **rejected by the CHECK `chk_listino_giacenza` (`giacenza >= 0`) on
`Listino`**, which acts as a safety net and preserves the invariant — but the error
returned is the generic CHECK one, not the application message "Bottiglie insufficienti".

The canonical solution would be a blocking `SELECT ... FOR UPDATE` read in the trigger,
which serializes concurrent sales on the same listino row. It is not implemented (out of
scope for a single-user project DB), but is documented here because the correctness of
the invariant does not rely on luck: it is guaranteed downstream by the CHECK.

---

## 14. Example queries

> The following queries exercise the schema, covering the required constructs (multiple
> joins, aggregations, subqueries) and tying back to the sections already written: where
> possible each query corresponds to an operation of table 7.2 and "demonstrates" a design
> choice. Presentation: for each, the natural-language question, the corresponding 7.2
> operation (where it exists) and the SQL construct demonstrated. **6-8 well-chosen queries
> are enough**; priority to those marked as such in the «Prio» column, which tie the queries
> to the rest of the design.

### 14.1 Outline

| # | Group | Question (natural language) | Op. 7.2 | Construct demonstrated | Prio |
|---|---|---|---|---|---|
| 1 | join | Full sheet of a wine: name, producer, region and country, grape varieties with percentages, ageing | O3 | longest join chain (bevanda→vino→vino_vitigno→vitigno, regione→paese); shows the 2NF Paese/Regione decomposition (Sec. 11) | |
| 2 | join | Published wine list "ready to print": entries in order with beverage, producer and price | O3 | multiple joins + `WHERE stato='pubblicata'` + `ORDER BY`; it is the query behind the waiter's view (external schema) | |
| 3 | aggreg. | Warehouse value per cellar: sum of stock × purchase price | O5 | `SUM(...)` + `GROUP BY` cellar | |
| 4 | aggreg. | Average margin per beverage category | O5 | `GROUP BY` on the generalization discriminant (t,d) | |
| 5 | aggreg. | Top N best-selling beverages in a date range, for a cellar | O5 | `tipo='VENDITA'` filter + `data_ora` range + `GROUP BY`/`ORDER BY`/`LIMIT`; **uses the `(id_cantina, data_ora)` index from Sec. 12** → closes the loop with physical design | yes |
| 6 | aggreg. | Blend wines: wines made of more than one grape variety, with the count | — | `GROUP BY` + `HAVING COUNT(*) > 1` | |
| 7 | subquery | Controlled-redundancy check: stock stored in the listino vs recomputed from movements (loads − unloads) | — | scalar/derived sum subquery; verifies the Sec. 8 denormalization and tests the triggers | yes |
| 8 | subquery | Listino beverages never sold (or never moved) | — | anti-join with `NOT EXISTS` (equivalent to `LEFT JOIN … IS NULL`) | |
| 9 | subquery | The most active employee of each cellar (who recorded the most movements) | — | subquery on the per-group maximum | |
| 10 | subquery | Beverages below their cellar's average stock (reorder list) | O2 | **correlated subquery** | yes |

### 14.2 Implementation

Each query is wrapped in a **stored procedure** in `05_queries_and_sp.sql` (name in parentheses):
this also satisfies the "programmable" requirement (t11), parameterizes the queries that need
it (`IN p_...`) and offers a single entry point to the application. Below is the core `SELECT`
of each; all have been verified on the real DB.

**Q1 — Technical sheet of a wine** (`vino_tecnical_data(p_id)`). A blend produces multiple
rows, one per grape variety; collapsing them into a single sheet is the caller's responsibility.

```sql
SELECT b.nome AS descrizione, v.doc, b.categoria, b.gradazione_alcolica, b.volume,
       b.is_biologico, v.annata, v.colore, v.tipologia, v.metodo, v.tipo_blend,
       v.tipo_denominazione, v.acidita, vi.mese_vendemmia, vi.giorni_macerazione,
       vi.tipo_fermentazione, vi.tipo_vendemmia, vv.percentuale, vv.annata_vitigno,
       vit.nome AS nome_vitigno, vit.sinonimo AS sinonimo_vitigno,
       af.durata_legno_mesi, af.durata_bottiglia_mesi, af.tipo_legno, af.formato_legno,
       p.nome AS nome_produttore, pa.nome_paese, r.nome_regione, r.zona
FROM bevanda b
INNER JOIN vino v            USING(id_bevanda)
INNER JOIN vinificazione vi  USING(id_bevanda)
INNER JOIN vino_vitigno vv   USING(id_bevanda)
INNER JOIN vitigno vit       USING(id_vitigno)
LEFT  JOIN affinamento af    USING(id_bevanda)   -- optional → LEFT
INNER JOIN produttore p      USING(id_produttore)
INNER JOIN regione r         USING(id_regione)
INNER JOIN paese pa          USING(id_paese)
WHERE id_bevanda = p_id;
```

**Q2 — Wine list ready to print** (`carta_vini_stampa(p_cantina)`). `LEFT JOIN vino` because the
vintage exists only for wines (NULL for any non-wine beverage in the list).

```sql
SELECT b.nome AS descrizione, p.nome AS nome_produttore, l.prezzo_vendita, vino.annata
FROM carta_vini cv
INNER JOIN carta_vini_voce v USING(id_carta_vini)
INNER JOIN listino l         USING(id_listino)
INNER JOIN bevanda b         USING(id_bevanda)
INNER JOIN produttore p      USING(id_produttore)
LEFT  JOIN vino              USING(id_bevanda)
WHERE cv.id_cantina = p_cantina AND cv.attivo = TRUE
ORDER BY b.categoria, descrizione;
```

**Q3 — Warehouse value per cellar** (`valore_magazzino()`). `SUM` of an expression + `GROUP BY`.

```sql
SELECT l.id_cantina, SUM(l.giacenza * l.prezzo_acquisto) AS capitale_immobile
FROM listino l
GROUP BY l.id_cantina;
```

**Q4 — Average margin per category** (`margine_per_categoria()`). `AVG` over an expression + `GROUP BY`.

```sql
SELECT b.categoria, AVG(l.prezzo_vendita - l.prezzo_acquisto) AS margine_medio
FROM listino l
INNER JOIN bevanda b USING(id_bevanda)
GROUP BY b.categoria;
```

**Q5 — Top N sold per cellar/range** (`top_seller(p_cantina, p_start, p_end, p_n)`).
`tipo='VENDITA'` filter + half-open range on `data_ora`: **uses the `(id_cantina, data_ora)`
index from Sec. 12** → closes the loop with physical design.

```sql
SELECT m.id_bevanda, b.nome, SUM(m.quantita_bottiglie) AS totale_venduto
FROM movimenti m
INNER JOIN bevanda b USING(id_bevanda)
WHERE m.tipo = 'VENDITA' AND m.id_cantina = p_cantina
  AND m.data_ora >= p_start AND m.data_ora < p_end
GROUP BY m.id_bevanda, b.nome
ORDER BY totale_venduto DESC
LIMIT p_n;
```

**Q6 — Blend wines** (`vini_blend()`). Filter on the **aggregate** with `HAVING COUNT > 1` (not `WHERE`).

```sql
SELECT b.id_bevanda,
       (SELECT COUNT(vv.id_vitigno) FROM vino v
        INNER JOIN vino_vitigno vv USING(id_bevanda)
        WHERE v.id_bevanda = b.id_bevanda) AS n_blend
FROM bevanda b
GROUP BY b.id_bevanda
HAVING n_blend > 1;
```

**Q7 — Controlled-redundancy check** (`verifica_ridondanza()`). Stored vs recomputed stock; each
sum is protected by `IFNULL(..,0)` because a `SUM` over no rows returns NULL. **0 rows = triggers
correct** → the Sec. 8 test.

```sql
SELECT l.id_cantina, l.id_bevanda, l.giacenza,
       ( IFNULL((SELECT SUM(m.quantita_bottiglie) FROM movimenti m
                 WHERE m.tipo IN ('CARICO','ACQUISTO')
                   AND m.id_cantina = l.id_cantina AND m.id_bevanda = l.id_bevanda
                 GROUP BY m.id_cantina, m.id_bevanda), 0)
       - IFNULL((SELECT SUM(m.quantita_bottiglie) FROM movimenti m
                 WHERE m.tipo IN ('SCARICO','VENDITA')
                   AND m.id_cantina = l.id_cantina AND m.id_bevanda = l.id_bevanda
                 GROUP BY m.id_cantina, m.id_bevanda), 0) ) AS giacenza_ricalcolata
FROM listino l
HAVING giacenza_ricalcolata <> l.giacenza;
```

**Q8 — Beverages never sold** (`bevande_mai_vendute()`). Anti-join with `NOT EXISTS`.

```sql
SELECT b.id_bevanda
FROM bevanda b
WHERE NOT EXISTS (SELECT 1 FROM movimenti m1
                 WHERE b.id_bevanda = m1.id_bevanda AND m1.tipo = 'VENDITA');
```

**Q9 — Most active employee per cellar** (`dipendente_piu_attivo()`). Per-group maximum: two
**non-correlated** derived tables joined (MariaDB does not support correlated LATERAL); the join
on `(id_cantina, n = max_n)` keeps any ties.

```sql
SELECT conteggi.id_cantina, conteggi.id_dipendente, conteggi.n
FROM (SELECT id_cantina, id_dipendente, COUNT(*) AS n
      FROM movimenti GROUP BY id_cantina, id_dipendente) AS conteggi
INNER JOIN (SELECT id_cantina, MAX(n) AS max_n
            FROM (SELECT id_cantina, id_dipendente, COUNT(*) AS n
                  FROM movimenti GROUP BY id_cantina, id_dipendente) AS t
            GROUP BY id_cantina) AS massimi
    ON massimi.id_cantina = conteggi.id_cantina AND conteggi.n = massimi.max_n
ORDER BY conteggi.id_cantina;
```

**Q10 — Beverages below their cellar's average stock** (`bevande_sotto_media()`). **Correlated**
subquery: the average is recomputed for each row's cellar.

```sql
SELECT l.id_bevanda, id_cantina, b.nome
FROM listino l
INNER JOIN bevanda b USING(id_bevanda)
WHERE l.giacenza < (SELECT AVG(giacenza) FROM listino WHERE l.id_cantina = id_cantina);
```

### 14.3 Write procedure: `crea_bevanda`

Besides the read queries, `05_queries_and_sp.sql` holds a **write** procedure the app uses to
introduce a brand-new beverage into the global catalog. The design point is **atomicity**: a
single transaction (connection `autocommit=OFF`, one commit at the end of the `CALL`, rollback
on any `SIGNAL`/error) that satisfies the conceptual-model constraints in one shot:

- **Total, exclusive generalization `(t,d)`**: it inserts the `bevanda` parent *and* the
  matching subtype row (`vino`/`birra`/`super_alcolico`/`analcolico`). A beverage with no
  subtype would break totality (Sec. 9.1).
- **Producer**: it optionally creates a new `produttore` (when no existing id is passed), since
  `bevanda.id_produttore` is NOT NULL.
- **Wine constraints** (only when `categoria = 'VINO'`): it creates the `vinificazione`
  (mandatory **1:1** participation) and the **grape blend** (N:M "Composto" relation, ≥1);
  `affinamento` (0:1) is inserted only if provided. A `SIGNAL 'Vitigno mancante per il vino'`
  guards the ≥1 rule.

The blend is passed as a **JSON array** `[{"id": <id_vitigno>, "pct": <percentuale>}, …]`: the
SP expands it with `JSON_TABLE`, checks that the percentages sum to **exactly 100**
(`SIGNAL 'Le percentuali dei vitigni devono sommare a 100'`) and inserts all `vino_vitigno`
rows with a single `INSERT ... SELECT`. The procedure is thus the **abstraction layer** that
enforces the aggregate "= 100%" constraint (Sec. 13.2): the user sends the whole blend and
never touches the `vino_vitigno` table directly.

### 14.4 Write procedure: `crea_dipendente`

Similar to `crea_bevanda` but on a single table (`dipendente`); it encapsulates two
**authorization/integrity** checks at the DB level, so they hold for a direct call too, not
just through the UI:

- **Valid role**: `SIGNAL` if `p_ruolo` is not one of `titolare`/`magazziniere`/`cameriere`
  (the `ruolo` column has no CHECK in the schema, so the constraint is enforced here).
- **Per-company scoping**: it receives the logged-in owner's `id_azienda` and rejects with a
  `SIGNAL` ('Cantina fuori dalla tua azienda') any `p_id_cantina` that does not belong to that
  company. This is the *server-side* counterpart of the application filter in Sec. 12.2.1: the
  dropdown only shows the company's cellars, and the SP enforces it anyway (defense in depth).

The **password is never handled in clear text by the DB**: the app computes the bcrypt hash
(`bcrypt.hashpw`) and passes only `p_password_hash` to the SP.

> **Known limitation:** onboarding a **new company** is not exposed in the app (which scopes
> every operation to the logged-in user's company): for now it requires a **database
> super-user** to create it via SQL/seed (see `06_seed_azienda2.sql`).

---
