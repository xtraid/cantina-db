# Implemented schema

The [E-R diagram](er.svg) is the *conceptual* model; the tables actually created by
[`sql/01_schema.sql`](../sql/01_schema.sql) drift from it because of the normalization steps (2NF split of
`paese`/`regione`, producer country as a FK, the `(t,d)` generalization mapped to a
parent + one child table per subtype, multivalued attributes moved to bridge tables).
The graph below is the **foreign-key graph of the schema as built** — one box per
table, each arrow pointing from a table to the table its FK references. It is generated
from [`docs/schema.dot`](schema.dot) with
[`graph-easy`](https://metacpan.org/dist/Graph-Easy) (pure-ASCII output, so it renders
identically on GitHub and in any terminal):

```bash
graph-easy docs/schema.dot --as=ascii
```

```
                          +------------------------+
                          |      affinamento       |
                          +------------------------+
                            |
                            |
                            v
     +--------------+     +------------------------+     +---------------+
     | vino_vitigno | --> |          vino          | <-- | vinificazione |
     +--------------+     +------------------------+     +---------------+
       |                    |
       |                    |
       v                    v
     +--------------+     +----------------------------------------------+     +----------------+
     |   vitigno    |     |                                              | <-- | super_alcolico |
     +--------------+     |                                              |     +----------------+
                          |                                              |
       +----------------> |                   bevanda                    | <-----------------------+
       |                  |                                              |                         |
       |                  |                                              |                         |
       |               +> |                                              | <+                      |
       |               |  +----------------------------------------------+  |                      |
       |               |    |                              |                |                      |
       |               |    |                              |                |                      |
       |               |    v                              v                |                      |
       |               |  +------------------------+     +---------------+  |                      |
       |               |  |       produttore       |     |    regione    |  |                      |
       |               |  +------------------------+     +---------------+  |                      |
       |               |    |                              |                |                      |
       |               |    |                              |                |                      |
       |               |    v                              |                |                      |
       |               |  +------------------------+       |                |                      |
       |               |  |         paese          | <-----+                |                      |
       |               |  +------------------------+                        |                      |
       |               |  +------------------------+                        |                      |
       |               |  | analcolico_ingrediente |                        |                      |
       |               |  +------------------------+                        |                      |
       |               |    |                                               |                      |
       |               |    |                                               |                      |
       |               |    v                                               |                      |
       |               |  +------------------------+                        |                      |
       |               +- |       analcolico       |                        |                      |
       |                  +------------------------+                        |                      |
       |                  +------------------------+                        |                      |
       |                  |     birra_luppolo      |                        |                      |
       |                  +------------------------+                        |                      |
       |                    |                                               |                      |
       |                    |                                               |                      |
       |                    v                                               |                      |
       |                  +------------------------+                        |                      |
       |                  |         birra          | -----------------------+                      |
       |                  +------------------------+                                               |
       |                    ^                                                                      |
       |                    |                                                                      |
       |                    |                                                                      |
       |                  +------------------------+                                               |
       |                  |      birra_malto       |                                               |
       |                  +------------------------+                                               |
       |                                                                                           |
       |                                                                                           |
       |                                                                                           |
     +--------------+     +------------------------+                                               |
     |   listino    | <-- |    carta_vini_voce     |                                               |
     +--------------+     +------------------------+                                               |
       |                    |                                                                      |
       |                    |                                                                      |
       |                    v                                                                      |
       |                  +------------------------+                                               |
       |                  |       carta_vini       | -+                                            |
       |                  +------------------------+  |                                            |
       |                    |                         |                                            |
       |                    |                         |                                            |
       |                    v                         |                                            |
       |                  +------------------------+  |                                            |
  +----+----------------> |       dipendente       |  |                                            |
  |    |                  +------------------------+  |                                            |
  |    |                    |                         |                                            |
  |    |                    |                         |                                            |
  |    |                    v                         v                                            |
  |    |                  +----------------------------------------------+                         |
  |    +----------------> |                   cantina                    |                         |
  |                       +----------------------------------------------+                         |
  |                         |                              ^                                       |
  |                         |                              |                                       |
  |                         v                              |                                       |
  |                       +------------------------+     +---------------+                         |
  |                       |        azienda         |  +- |   movimenti   | ------------------------+
  |                       +------------------------+  |  +---------------+
  |                                                   |    |
  +---------------------------------------------------+    |
                                                           v
                                                         +---------------+
                                                         |   fornitore   |
                                                         +---------------+
```

<details>
<summary>Full relational schema (all attributes)</summary>

```
azienda(id_azienda PK, ragione_sociale, tipo, indirizzo_sede_principale,
        p_iva, email, pec, telefono, titolare, sito_web, logo, attivo)
cantina(id_cantina PK, nome, indirizzo, tipo, id_azienda FK→azienda)
dipendente(id_dipendente PK, matricola U, nome, cognome, ruolo,
        username U, password_hash, email, attivo, id_cantina FK→cantina)
paese(id_paese PK, nome_paese U, code_iso)
regione(id_regione PK, nome_regione, zona, id_paese FK→paese) U(id_paese, nome_regione)
produttore(id_produttore PK, nome, id_paese FK→paese opt., sito_web, attivo)
fornitore(id_fornitore PK, ragione_sociale, p_iva, is_cliente, is_fornitore,
        indirizzo, telefono, email, attivo)
vitigno(id_vitigno PK, nome U, sinonimo)

bevanda(id_bevanda PK, nome, categoria, gradazione_alcolica, volume, is_biologico,
        data_inserimento, note, foto_url, attivo,
        id_produttore FK→produttore, id_regione FK→regione opt.)
vino(id_bevanda PK FK→bevanda, annata, colore, tipologia, metodo,
        tipo_blend, tipo_denominazione, doc, acidita)
birra(id_bevanda PK FK→bevanda, stile, tipo_fermentazione, ibu, ebc,
        densita_originale, densita_finale, is_filtrata, is_pastorizzata,
        is_rifermentata, lievito)
super_alcolico(id_bevanda PK FK→bevanda, categoria, materia_prima, tipo_distillazione,
        numero_distillazioni, anni_invecchiamento, tipo_botte, is_torbato,
        ppm_fenoli, blend)
analcolico(id_bevanda PK FK→bevanda, categoria, has_zuccheri_aggiunti, is_frizzante)
birra_luppolo(id_bevanda PK FK→birra, nome_luppolo PK)
birra_malto(id_bevanda PK FK→birra, nome_malto PK)
analcolico_ingrediente(id_bevanda PK FK→analcolico, nome_ingrediente PK)
vinificazione(id_vinificazione PK, mese_vendemmia, giorni_macerazione,
        tipo_fermentazione, tipo_vendemmia, id_bevanda U FK→vino)
affinamento(id_affinamento PK, durata_legno_mesi, durata_bottiglia_mesi,
        tipo_legno, formato_legno, id_bevanda U FK→vino opt.)
vino_vitigno(id_bevanda PK FK→vino, id_vitigno PK FK→vitigno,
        percentuale, annata_vitigno)

movimenti(id_movimento PK, tipo, quantita_bottiglie, prezzo_unitario, data_ora,
        id_bevanda FK→bevanda, id_dipendente FK→dipendente,
        id_cantina FK→cantina, id_fornitore FK→fornitore opt.)
listino(id_listino PK, prezzo_vendita, prezzo_acquisto, iva, giacenza, attivo,
        data_ultimo_aggiornamento, id_bevanda FK→bevanda, id_cantina FK→cantina)
        U(id_cantina, id_bevanda)
carta_vini(id_carta_vini PK, titolo, stato, data_creazione, data_pubblicazione,
        data_archiviazione, attivo, id_cantina FK→cantina, id_dipendente FK→dipendente)
carta_vini_voce(id_carta_vini PK FK→carta_vini, id_listino PK FK→listino,
        ordine, descrizione_posizione)
```

</details>


## Italiano

Il [diagramma E-R](er.svg) descrive il modello concettuale; il grafo sopra
mostra le foreign key delle tabelle implementate in
[`sql/01_schema.sql`](../sql/01_schema.sql). Le differenze derivano dalla
normalizzazione di paese e regione, dalla rappresentazione dei sottotipi di
bevanda e dalle tabelle ponte per gli attributi multivalore.

Il blocco espandibile elenca tutte le relazioni e i loro attributi. Per le
motivazioni delle scelte, consulta la [progettazione](progettazione.md).

[Back to README / Torna al README](../README.md)
