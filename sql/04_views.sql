-- ============================================================
--  Viste per ruolo (schema esterno) - cantina
--  Carica DOPO 01_schema.sql (+ 02_seed.sql per i dati).
--  Ogni vista e' lo schema esterno di un ruolo: espone solo
--  le colonne pertinenti e autorizzate per quel ruolo (t09).
-- ============================================================

USE cantina;

-- Magazziniere: giacenze per cantina (no dati finanziari, quelli al titolare).
CREATE OR REPLACE VIEW v_giacenze_magazziniere AS
    SELECT c.nome as nome_cantina, b.nome as descrizione_bevanda, b.categoria, p.nome as nome_produttore, l.giacenza, l.prezzo_vendita from listino l
    INNER JOIN bevanda b using(id_bevanda)
    INNER JOIN produttore p using(id_produttore)
    INNER JOIN cantina c using(id_cantina)
    WHERE l.attivo = TRUE AND b.attivo =TRUE
    ORDER BY c.id_cantina, l.giacenza desc;

CREATE OR REPLACE VIEW v_giacenze_titolare AS
    SELECT c.nome as nome_cantina, b.nome as descrizione_bevanda, b.categoria,
           p.nome as nome_produttore, l.giacenza, l.prezzo_vendita, l.prezzo_acquisto,
           (l.prezzo_vendita - l.prezzo_acquisto) as margine
            FROM listino l
    INNER JOIN bevanda b using(id_bevanda)
    INNER JOIN produttore p using(id_produttore)
    INNER JOIN cantina c using(id_cantina)
    WHERE l.attivo = TRUE AND b.attivo =TRUE
    ORDER BY c.id_cantina, l.giacenza desc;


CREATE OR REPLACE VIEW v_carta_vini_cameriere AS
    SELECT cv.titolo, c.nome as cantina_di_provenienza, v.descrizione_posizione,
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
    ORDER BY cv.titolo, v.ordine

;
