-- ============================================================
--  Dati di esempio (seed) - cantina
--  Carica DOPO 01_schema.sql. Dati realistici ma inventati.
--  ID espliciti per rendere deterministici i riferimenti FK.
--
--  NB: la giacenza su `listino` e' impostata qui esplicitamente
--      perche' il trigger di mantenimento (03_triggers.sql) non
--      e' ancora installato. Una volta attivo, sara' derivata
--      automaticamente dai movimenti.
-- ============================================================

-- pulizia dati (ordine inverso alle FK)
DELETE FROM carta_vini_voce;
DELETE FROM carta_vini;
DELETE FROM movimenti;
DELETE FROM listino;
DELETE FROM vino_vitigno;
DELETE FROM birra_malto;
DELETE FROM birra_luppolo;
DELETE FROM analcolico_ingrediente;
DELETE FROM affinamento;
DELETE FROM vinificazione;
DELETE FROM analcolico;
DELETE FROM super_alcolico;
DELETE FROM birra;
DELETE FROM vino;
DELETE FROM bevanda;
DELETE FROM vitigno;
DELETE FROM fornitore;
DELETE FROM produttore;
DELETE FROM regione;
DELETE FROM paese;
DELETE FROM dipendente;
DELETE FROM cantina;
DELETE FROM azienda;

-- ===================== AZIENDA / CANTINE =====================

INSERT INTO azienda (id_azienda, ragione_sociale, tipo, p_iva, titolare, email, attivo) VALUES
(1, 'Enoteca Adriatica S.r.l.', 'distributore', 'IT01234567890', 'Giulia Bernardi', 'info@enotecaadriatica.it', TRUE);

INSERT INTO cantina (id_cantina, nome, indirizzo, tipo, id_azienda) VALUES
(1, 'Magazzino Trieste', 'Via del Porto 12, Trieste', 'magazzino centrale', 1),
(2, 'Punto vendita Milano', 'Corso Garibaldi 88, Milano', 'enoteca', 1);

-- ===================== DIPENDENTI =====================
-- password_hash: placeholder; verranno rigenerati con bcrypt in fase di app.

INSERT INTO dipendente (id_dipendente, matricola, nome, cognome, ruolo, username, password_hash, email, id_cantina) VALUES
(1, 1001, 'Giulia',  'Bernardi', 'titolare',     'g.bernardi', '$2b$12$placeholderHashTitolare......................', 'g.bernardi@enotecaadriatica.it', 1),
(2, 1002, 'Marco',   'Ferri',    'magazziniere', 'm.ferri',    '$2b$12$placeholderHashMagazz1......................', 'm.ferri@enotecaadriatica.it',    1),
(3, 1003, 'Sara',    'Conti',    'cameriere',    's.conti',    '$2b$12$placeholderHashCamer1......................', 's.conti@enotecaadriatica.it',    1),
(4, 1004, 'Luca',    'Rossi',    'magazziniere', 'l.rossi',    '$2b$12$placeholderHashMagazz2......................', 'l.rossi@enotecaadriatica.it',    2);

-- ===================== PAESI / REGIONI / PRODUTTORI / FORNITORI =====================

INSERT INTO paese (id_paese, nome_paese, code_iso) VALUES
(1, 'Italia',  'IT'),
(2, 'Francia', 'FR'),
(3, 'Spagna',  'ES');

INSERT INTO regione (id_regione, nome_regione, zona, id_paese) VALUES
(1, 'Piemonte', 'Nord-Ovest', 1),
(2, 'Bordeaux', 'Sud-Ovest',  2),
(3, 'Rioja',    'Nord',       3);

INSERT INTO produttore (id_produttore, nome, paese, sito_web) VALUES
(1, 'Cantina Marchesi del Nebbiolo', 'Italia',  'https://marchesidelnebbiolo.it'),
(2, 'Chateau Lumiere',               'Francia', 'https://chateaulumiere.fr'),
(3, 'Bodega Tempranillo Real',       'Spagna',  'https://tempranilloreal.es'),
(4, 'Birrificio Bora',               'Italia',  'https://birrificiobora.it'),
(5, 'Highland Spirits Co.',          'Scozia',  'https://highlandspirits.co.uk');

INSERT INTO fornitore (id_fornitore, ragione_sociale, p_iva, is_fornitore, is_cliente, email) VALUES
(1, 'Distribuzioni Vinicole Europa S.p.A.', 'IT09876543210', TRUE, FALSE, 'ordini@dve.eu');

-- ===================== VITIGNI =====================

INSERT INTO vitigno (id_vitigno, nome, sinonimo) VALUES
(1, 'Nebbiolo',           'Spanna'),
(2, 'Cabernet Sauvignon', NULL),
(3, 'Merlot',             NULL),
(4, 'Tempranillo',        'Tinta del Pais');

-- ===================== BEVANDE (catalogo) =====================

INSERT INTO bevanda (id_bevanda, nome, categoria, gradazione_alcolica, volume, is_biologico, id_produttore, id_regione) VALUES
(1, 'Barolo DOCG',            'VINO',           14.0,  750, FALSE, 1, 1),
(2, 'Barbaresco DOCG',        'VINO',           13.5,  750, TRUE,  1, 1),
(3, 'Chateau Lumiere Rouge',  'VINO',           13.0,  750, FALSE, 2, 2),
(4, 'Rioja Reserva',          'VINO',           14.0,  750, FALSE, 3, 3),
(5, 'Bora IPA',               'BIRRA',           6.2,  330, FALSE, 4, 1),
(6, 'Highland Single Malt',   'SUPER_ALCOLICO', 43.0,  700, FALSE, 5, NULL);

-- sottotipi (1:1 con bevanda)
INSERT INTO vino (id_bevanda, annata, colore, tipologia, metodo, tipo_denominazione, doc, acidita) VALUES
(1, 2019, 'rosso', 'fermo', 'tradizionale', 'DOCG', 'Barolo',     5.6),
(2, 2020, 'rosso', 'fermo', 'tradizionale', 'DOCG', 'Barbaresco', 5.4),
(3, 2018, 'rosso', 'fermo', 'tradizionale', 'AOC',  'Bordeaux',   5.1),
(4, 2017, 'rosso', 'fermo', 'tradizionale', 'DOCa', 'Rioja',      5.3);

INSERT INTO birra (id_bevanda, stile, tipo_fermentazione, ibu, ebc, is_filtrata, lievito) VALUES
(5, 'India Pale Ale', 'alta', 55.0, 14.0, FALSE, 'US-05');

INSERT INTO super_alcolico (id_bevanda, categoria, materia_prima, tipo_distillazione, numero_distillazioni, anni_invecchiamento, tipo_botte, is_torbato) VALUES
(6, 'whisky', 'orzo maltato', 'pot still', 2, 12, 'ex-bourbon', FALSE);

-- multivalore -> tabelle ponte (solo per la birra)
INSERT INTO birra_luppolo (id_bevanda, nome_luppolo) VALUES
(5, 'Cascade'), (5, 'Citra'), (5, 'Centennial');
INSERT INTO birra_malto (id_bevanda, nome_malto) VALUES
(5, 'Pilsner'), (5, 'Caramello'), (5, 'Monaco');

-- blend vino-vitigno (N:M con percentuale)
INSERT INTO vino_vitigno (id_bevanda, id_vitigno, percentuale, annata_vitigno) VALUES
(1, 1, 100.0, 2019),                 -- Barolo: Nebbiolo 100%
(2, 1, 100.0, 2020),                 -- Barbaresco: Nebbiolo 100%
(3, 2, 70.0, 2018), (3, 3, 30.0, 2018), -- Bordeaux: Cab.Sauv 70 + Merlot 30
(4, 4, 100.0, 2017);                 -- Rioja: Tempranillo 100%

-- vinificazione / affinamento (solo alcuni vini)
INSERT INTO vinificazione (id_vinificazione, mese_vendemmia, giorni_macerazione, tipo_fermentazione, tipo_vendemmia, id_bevanda) VALUES
(1, 'ottobre', 30, 'spontanea', 'manuale', 1),
(2, 'ottobre', 25, 'spontanea', 'manuale', 2);

INSERT INTO affinamento (id_affinamento, durata_legno_mesi, durata_bottiglia_mesi, tipo_legno, formato_legno, id_bevanda) VALUES
(1, 24, 12, 'rovere di Slavonia', 'botte grande', 1);

-- ===================== LISTINO (per cantina) =====================
-- Stessa bevanda in cantine diverse = righe diverse, prezzi/giacenze diversi.
-- giacenza impostata a mano (trigger non ancora attivo).

INSERT INTO listino (id_listino, id_bevanda, id_cantina, prezzo_vendita, prezzo_acquisto, iva, giacenza) VALUES
(1, 1, 1, 45.00, 30.00, 22.0, 40),   -- Barolo @ Trieste
(2, 1, 2, 52.00, 30.00, 22.0,  5),   -- Barolo @ Milano (stesso vino, prezzo/giacenza diversi)
(3, 2, 1, 38.00, 25.00, 22.0, 20),   -- Barbaresco @ Trieste
(4, 3, 1, 60.00, 40.00, 22.0, 12),   -- Bordeaux @ Trieste
(5, 4, 2, 28.00, 18.00, 22.0, 30),   -- Rioja @ Milano
(6, 5, 1,  6.00,  3.00, 22.0, 96),   -- IPA @ Trieste
(7, 6, 2, 75.00, 50.00, 22.0,  8);   -- Whisky @ Milano

-- ===================== MOVIMENTI =====================
-- Coerenti con le giacenze sopra (dove presenti).

INSERT INTO movimenti (id_movimento, tipo, quantita_bottiglie, prezzo_unitario, id_bevanda, id_dipendente, id_cantina, id_fornitore) VALUES
(1, 'ACQUISTO', 40, 30.00, 1, 2, 1, 1),   -- carico Barolo @ Trieste (40)
(2, 'ACQUISTO', 10, 30.00, 1, 4, 2, 1),   -- carico Barolo @ Milano (10)
(3, 'VENDITA',   5, 52.00, 1, 4, 2, NULL),-- vendita 5 Barolo @ Milano -> giacenza 5
(4, 'ACQUISTO', 24,  3.00, 5, 2, 1, 1),   -- carico IPA @ Trieste (24)
(5, 'ACQUISTO', 72,  3.00, 5, 2, 1, 1);   -- altro carico IPA @ Trieste -> 96

-- ===================== CARTA VINI =====================

INSERT INTO carta_vini (id_carta_vini, titolo, stato, data_pubblicazione, id_cantina, id_dipendente) VALUES
(1, 'Carta dei Rossi - Trieste', 'pubblicata', CURRENT_TIMESTAMP, 1, 3);

INSERT INTO carta_vini_voce (id_carta_vini, id_listino, ordine, descrizione_posizione) VALUES
(1, 1, 1, 'Piemonte - in apertura'),
(1, 3, 2, 'Piemonte'),
(1, 4, 3, 'Francia - selezione');
