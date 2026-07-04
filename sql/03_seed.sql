-- Sample data (seed) - cantina.
-- Load AFTER 01_schema.sql AND 02_triggers.sql (the triggers must already
-- exist: the stock is derived from the movimenti below).
-- Realistic but fictional data. Explicit IDs to make the FK references
-- deterministic.
--
-- Note: the stock on `listino` is not set here explicitly: it starts from
-- DEFAULT 0 and is derived automatically from the movimenti through the
-- triggers (02_triggers.sql). Every listino row must have ACQUISTO/CARICO
-- movimenti consistent with the wanted initial stock.

-- data cleanup (reverse FK order)
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

-- Company / wineries

INSERT INTO azienda (id_azienda, ragione_sociale, tipo, p_iva, titolare, email, attivo) VALUES
(1, 'Enoteca Adriatica S.r.l.', 'distributore', 'IT01234567890', 'Giulia Bernardi', 'info@enotecaadriatica.it', TRUE);

INSERT INTO cantina (id_cantina, nome, indirizzo, tipo, id_azienda) VALUES
(1, 'Magazzino Trieste', 'Via del Porto 12, Trieste', 'magazzino centrale', 1),
(2, 'Punto vendita Milano', 'Corso Garibaldi 88, Milano', 'enoteca', 1);

-- Employees
-- password_hash: bcrypt (cost 12). All employees have the demo password 'cantina2026'.

INSERT INTO dipendente (id_dipendente, matricola, nome, cognome, ruolo, username, password_hash, email, id_cantina) VALUES
(1, 1001, 'Giulia',  'Bernardi', 'titolare',     'g.bernardi', '$2b$12$WCbOfmBJVyeoxWA1vbV4sej/k4ltiXqz7lOsDEVoi.gkEK..9OdQe', 'g.bernardi@enotecaadriatica.it', 1),
(2, 1002, 'Marco',   'Ferri',    'magazziniere', 'm.ferri',    '$2b$12$ztTyo9kI0inXFP17gC32Iu3frWyT3g1BXlIUiBt6YEaK8bjbm4cZu', 'm.ferri@enotecaadriatica.it',    1),
(3, 1003, 'Sara',    'Conti',    'cameriere',    's.conti',    '$2b$12$Ak8kxqc0vWvKQbzrWMe4U.AKsQeeCHva/VmjeEQwU87dIBq76jniK', 's.conti@enotecaadriatica.it',    1),
(4, 1004, 'Luca',    'Rossi',    'magazziniere', 'l.rossi',    '$2b$12$umblRIVsiFr62BCcVbGWm.ksTeb8EXfYSdNrp3rjlltx0WtdxlGpy', 'l.rossi@enotecaadriatica.it',    2);

-- Countries / regions / producers / suppliers

INSERT INTO paese (id_paese, nome_paese, code_iso) VALUES
(1, 'Italia',  'IT'),
(2, 'Francia', 'FR'),
(3, 'Spagna',  'ES'),
(4, 'Scozia',  'GB');   -- needed by producer 5 (Highland Spirits Co.)

INSERT INTO regione (id_regione, nome_regione, zona, id_paese) VALUES
(1, 'Piemonte', 'Nord-Ovest', 1),
(2, 'Bordeaux', 'Sud-Ovest',  2),
(3, 'Rioja',    'Nord',       3);

INSERT INTO produttore (id_produttore, nome, id_paese, sito_web) VALUES
(1, 'Cantina Marchesi del Nebbiolo', 1, 'https://marchesidelnebbiolo.it'),
(2, 'Chateau Lumiere',               2, 'https://chateaulumiere.fr'),
(3, 'Bodega Tempranillo Real',       3, 'https://tempranilloreal.es'),
(4, 'Birrificio Bora',               1, 'https://birrificiobora.it'),
(5, 'Highland Spirits Co.',          4, 'https://highlandspirits.co.uk');

INSERT INTO fornitore (id_fornitore, ragione_sociale, p_iva, is_fornitore, is_cliente, email) VALUES
(1, 'Distribuzioni Vinicole Europa S.p.A.', 'IT09876543210', TRUE, FALSE, 'ordini@dve.eu');

-- Grape varieties

INSERT INTO vitigno (id_vitigno, nome, sinonimo) VALUES
(1, 'Nebbiolo',           'Spanna'),
(2, 'Cabernet Sauvignon', NULL),
(3, 'Merlot',             NULL),
(4, 'Tempranillo',        'Tinta del Pais');

-- Beverages (catalog)

INSERT INTO bevanda (id_bevanda, nome, categoria, gradazione_alcolica, volume, is_biologico, id_produttore, id_regione) VALUES
(1, 'Barolo DOCG',            'VINO',           14.0,  750, FALSE, 1, 1),
(2, 'Barbaresco DOCG',        'VINO',           13.5,  750, TRUE,  1, 1),
(3, 'Chateau Lumiere Rouge',  'VINO',           13.0,  750, FALSE, 2, 2),
(4, 'Rioja Reserva',          'VINO',           14.0,  750, FALSE, 3, 3),
(5, 'Bora IPA',               'BIRRA',           6.2,  330, FALSE, 4, 1),
(6, 'Highland Single Malt',   'SUPER_ALCOLICO', 43.0,  700, FALSE, 5, NULL);

-- subtypes (1:1 with bevanda)
INSERT INTO vino (id_bevanda, annata, colore, tipologia, metodo, tipo_denominazione, doc, acidita) VALUES
(1, 2019, 'rosso', 'fermo', 'tradizionale', 'DOCG', 'Barolo',     5.6),
(2, 2020, 'rosso', 'fermo', 'tradizionale', 'DOCG', 'Barbaresco', 5.4),
(3, 2018, 'rosso', 'fermo', 'tradizionale', 'AOC',  'Bordeaux',   5.1),
(4, 2017, 'rosso', 'fermo', 'tradizionale', 'DOCa', 'Rioja',      5.3);

INSERT INTO birra (id_bevanda, stile, tipo_fermentazione, ibu, ebc, is_filtrata, lievito) VALUES
(5, 'India Pale Ale', 'alta', 55.0, 14.0, FALSE, 'US-05');

INSERT INTO super_alcolico (id_bevanda, categoria, materia_prima, tipo_distillazione, numero_distillazioni, anni_invecchiamento, tipo_botte, is_torbato) VALUES
(6, 'whisky', 'orzo maltato', 'pot still', 2, 12, 'ex-bourbon', FALSE);

-- multivalued -> bridge tables (only for birra)
INSERT INTO birra_luppolo (id_bevanda, nome_luppolo) VALUES
(5, 'Cascade'), (5, 'Citra'), (5, 'Centennial');
INSERT INTO birra_malto (id_bevanda, nome_malto) VALUES
(5, 'Pilsner'), (5, 'Caramello'), (5, 'Monaco');

-- vino-vitigno blend (N:M with percentage)
INSERT INTO vino_vitigno (id_bevanda, id_vitigno, percentuale, annata_vitigno) VALUES
(1, 1, 100.0, 2019),                 -- Barolo: Nebbiolo 100%
(2, 1, 100.0, 2020),                 -- Barbaresco: Nebbiolo 100%
(3, 2, 70.0, 2018), (3, 3, 30.0, 2018), -- Bordeaux: Cab.Sauv 70 + Merlot 30
(4, 4, 100.0, 2017);                 -- Rioja: Tempranillo 100%

-- vinificazione: mandatory 1:1, one row per wine
INSERT INTO vinificazione (id_vinificazione, mese_vendemmia, giorni_macerazione, tipo_fermentazione, tipo_vendemmia, id_bevanda) VALUES
(1, 'ottobre', 30, 'spontanea', 'manuale', 1),
(2, 'ottobre', 25, 'spontanea', 'manuale', 2),
(3, 'settembre', 21, 'controllata', 'meccanica', 3),
(4, 'ottobre',   28, 'controllata', 'manuale',   4);

-- affinamento: optional 0:1 (only some wines)
INSERT INTO affinamento (id_affinamento, durata_legno_mesi, durata_bottiglia_mesi, tipo_legno, formato_legno, id_bevanda) VALUES
(1, 24, 12, 'rovere di Slavonia', 'botte grande', 1);

-- Price list (per winery)
-- Same bevanda in different wineries = different rows, different prices/stock.
-- stock not specified: starts from DEFAULT 0, the triggers derive it from
-- the movimenti inserted below.

INSERT INTO listino (id_listino, id_bevanda, id_cantina, prezzo_vendita, prezzo_acquisto, iva ) VALUES
(1, 1, 1, 45.00, 30.00, 22.0 ),   -- Barolo @ Trieste
(2, 1, 2, 52.00, 30.00, 22.0 ),   -- Barolo @ Milano (same wine, different price/stock)
(3, 2, 1, 38.00, 25.00, 22.0 ),   -- Barbaresco @ Trieste
(4, 3, 1, 60.00, 40.00, 22.0 ),   -- Bordeaux @ Trieste
(5, 4, 2, 28.00, 18.00, 22.0 ),   -- Rioja @ Milano
(6, 5, 1,  6.00,  3.00, 22.0 ),   -- IPA @ Trieste
(7, 6, 2, 75.00, 50.00, 22.0 );   -- Whisky @ Milano

-- Movements
-- Source of truth for the stock: every listino row has here at least one
-- ACQUISTO/CARICO that, via trigger, produces the initial stock wanted
-- for the demo.

INSERT INTO movimenti (id_movimento, tipo, quantita_bottiglie, prezzo_unitario, id_bevanda, id_dipendente, id_cantina, id_fornitore) VALUES
(1, 'ACQUISTO', 40, 30.00, 1, 2, 1, 1),   -- load Barolo @ Trieste (40)
(2, 'ACQUISTO', 10, 30.00, 1, 4, 2, 1),   -- load Barolo @ Milano (10)
(3, 'VENDITA',   5, 52.00, 1, 4, 2, NULL),-- sale of 5 Barolo @ Milano -> stock 5
(4, 'ACQUISTO', 24,  3.00, 5, 2, 1, 1),   -- load IPA @ Trieste (24)
(5, 'ACQUISTO', 72,  3.00, 5, 2, 1, 1),   -- another load IPA @ Trieste -> 96
(6, 'ACQUISTO', 20, 25.00, 2, 2, 1, 1),   -- load Barbaresco @ Trieste -> 20
(7, 'ACQUISTO', 12, 40.00, 3, 2, 1, 1),   -- load Bordeaux @ Trieste -> 12
(8, 'ACQUISTO', 30, 18.00, 4, 4, 2, 1),   -- load Rioja @ Milano -> 30
(9, 'ACQUISTO',  8, 50.00, 6, 4, 2, 1);   -- load Whisky @ Milano -> 8

-- Wine list

INSERT INTO carta_vini (id_carta_vini, titolo, stato, data_pubblicazione, id_cantina, id_dipendente) VALUES
(1, 'Carta dei Rossi - Trieste', 'pubblicata', CURRENT_TIMESTAMP, 1, 3);

INSERT INTO carta_vini_voce (id_carta_vini, id_listino, ordine, descrizione_posizione) VALUES
(1, 1, 1, 'Piemonte - in apertura'),
(1, 3, 2, 'Piemonte'),
(1, 4, 3, 'Francia - selezione');
