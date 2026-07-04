-- ============================================================
--  Viste per ruolo (schema esterno) - cantina
--  Carica DOPO 01_schema.sql (+ 03_seed.sql per i dati).
--  Ogni vista e' lo schema esterno di un ruolo: espone solo
--  le colonne pertinenti e autorizzate per quel ruolo (t09).
-- ============================================================

USE cantina;

CREATE OR REPLACE VIEW v_giacenze_magazziniere AS
    SELECT c.id_cantina, c.nome as nome_cantina, b.nome as descrizione_bevanda, b.categoria, p.nome as nome_produttore, l.giacenza, l.prezzo_vendita from listino l
    INNER JOIN bevanda b using(id_bevanda)
    INNER JOIN produttore p using(id_produttore)
    INNER JOIN cantina c using(id_cantina)
    WHERE l.attivo = TRUE AND b.attivo =TRUE
    ORDER BY c.id_cantina, l.giacenza desc;

CREATE OR REPLACE VIEW v_giacenze_titolare AS
    SELECT c.id_azienda, c.id_cantina, c.nome as nome_cantina, b.nome as descrizione_bevanda, b.categoria,
           p.nome as nome_produttore, l.giacenza, l.prezzo_vendita, l.prezzo_acquisto,
           (l.prezzo_vendita - l.prezzo_acquisto) as margine
            FROM listino l
    INNER JOIN bevanda b using(id_bevanda)
    INNER JOIN produttore p using(id_produttore)
    INNER JOIN cantina c using(id_cantina)
    WHERE l.attivo = TRUE AND b.attivo =TRUE
    ORDER BY c.id_cantina, l.giacenza desc;


CREATE OR REPLACE VIEW v_carta_vini_cameriere AS
    SELECT c.id_cantina, cv.titolo, c.nome as cantina_di_provenienza, v.descrizione_posizione,
           v.ordine, b.nome as descrizione_bevanda, b.categoria, p.nome as produttore,
           l.prezzo_vendita
           FROM  carta_vini cv
    INNER JOIN  cantina c using(id_cantina)
    INNER JOIN carta_vini_voce v using(id_carta_vini)
    INNER JOIN listino l using(id_listino)
    INNER JOIN bevanda b using(id_bevanda)
    INNER JOIN produttore p using(id_produttore)

    WHERE cv.stato = 'pubblicata' AND
          cv.attivo = TRUE AND
          l.attivo = TRUE AND
          b.attivo = TRUE
    ORDER BY cv.titolo, v.ordine;

CREATE OR REPLACE VIEW v_gestione_magazzino AS
    SELECT l.id_listino,                         -- serve per UPDATE/DELETE app-side
           c.id_cantina,                         -- scoping
           c.nome AS nome_cantina,
           b.id_bevanda,
           b.nome AS descrizione_bevanda,
           b.categoria,
           p.nome AS nome_produttore,
           l.giacenza,
           l.prezzo_acquisto,
           l.prezzo_vendita,
           (l.prezzo_vendita - l.prezzo_acquisto) AS margine,
           l.attivo,                             -- mostra anche le disattivate
           l.data_ultimo_aggiornamento
    FROM listino l
    INNER JOIN bevanda b USING(id_bevanda)
    INNER JOIN produttore p USING(id_produttore)
    INNER JOIN cantina c USING(id_cantina)
     ORDER BY l.attivo DESC, b.nome;

CREATE OR REPLACE VIEW v_gestione_azienda AS
    SELECT l.id_listino,
           c.id_azienda,                         -- scoping titolare
           c.id_cantina,
           c.nome AS nome_cantina,
           b.id_bevanda,
           b.nome AS descrizione_bevanda,
           b.categoria,
           p.nome AS nome_produttore,
           l.giacenza,
           l.prezzo_acquisto,
           l.prezzo_vendita,
           (l.prezzo_vendita - l.prezzo_acquisto) AS margine,
           l.attivo,
           l.data_ultimo_aggiornamento
    FROM listino l
    INNER JOIN bevanda b USING(id_bevanda)
    INNER JOIN produttore p USING(id_produttore)
    INNER JOIN cantina c USING(id_cantina)
    ORDER BY c.id_cantina, l.attivo DESC, b.nome;

CREATE OR REPLACE VIEW v_dipendenti_azienda AS
    SELECT c.id_azienda,                          -- scoping titolare
           d.id_dipendente,
           d.matricola,
           d.nome,
           d.cognome,
           d.ruolo,
           d.username,
           d.email,
           d.attivo,
           c.id_cantina,
           c.nome AS nome_cantina
    FROM dipendente d
    INNER JOIN cantina c USING(id_cantina)
    ORDER BY c.id_cantina, d.cognome, d.nome;
