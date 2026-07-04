-- 06_seed_azienda2.sql — Second company (demo data).
-- Serves to show per-company scoping: an owner sees/manages only the wineries
-- of their own company. Load AFTER 01_schema (independent of the triggers).
-- Demo owner: username 'm.verdi', password 'verdi123'.

USE cantina;

INSERT INTO azienda (ragione_sociale, tipo, p_iva, titolare, email)
VALUES ('Cantine del Sole S.r.l.', 'azienda vinicola', 'IT12345678901',
        'Marco Verdi', 'info@cantinedelsole.it');

INSERT INTO cantina (nome, indirizzo, tipo, id_azienda)
VALUES ('Cantina Napoli', 'Via Toledo 1, Napoli', 'magazzino',
        (SELECT id_azienda FROM azienda WHERE ragione_sociale = 'Cantine del Sole S.r.l.'));

INSERT INTO cantina (nome, indirizzo, tipo, id_azienda)
VALUES ('Enoteca Palermo', 'Via Maqueda 5, Palermo', 'punto vendita',
        (SELECT id_azienda FROM azienda WHERE ragione_sociale = 'Cantine del Sole S.r.l.'));

INSERT INTO dipendente
    (matricola, nome, cognome, ruolo, username, password_hash, email, id_cantina)
VALUES
    (2001, 'Marco', 'Verdi', 'titolare', 'm.verdi',
     '$2b$12$VPefTDj.i8g5O.vIaX/W6u60WVVnkzUGnwLdLI.MF/QOkr7SdNanO',
     'm.verdi@cantinedelsole.it',
     (SELECT id_cantina FROM cantina WHERE nome = 'Cantina Napoli'));
