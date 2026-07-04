-- 05_queries.sql — Example queries (document Sec. 14).
-- Domain: winery / beverages. DB: `cantina`.
-- Prerequisites: 01_schema, 02_triggers, 03_seed, 04_views already loaded.

USE cantina;

-- Q7 — Controlled-redundancy check: stock stored in listino vs recomputed
-- from movimenti (Σ inbound − Σ outbound). 0 rows = triggers correct.
DELIMITER $$
DROP PROCEDURE IF EXISTS verifica_ridondanza$$
CREATE PROCEDURE verifica_ridondanza (IN p_id_azienda INT)
    BEGIN
        SELECT l.id_cantina,
               l.id_bevanda,
               l.giacenza,
               (IFNULL((SELECT SUM(m.quantita_bottiglie) from movimenti m
             WHERE m.tipo IN ('CARICO','ACQUISTO') AND
                   m.id_cantina = l.id_cantina AND
                   m.id_bevanda = l.id_bevanda
             GROUP BY m.id_cantina, m.id_bevanda
            ),0) - IFNULL((SELECT sum(m.quantita_bottiglie) from movimenti m
             WHERE m.tipo IN ('SCARICO','VENDITA')AND
                   m.id_cantina = l.id_cantina AND
                   m.id_bevanda = l.id_bevanda
             GROUP BY m.id_cantina, m.id_bevanda
             ),0)) AS giacenza_ricalcolata
            FROM listino l
            WHERE l.id_cantina IN (SELECT id_cantina FROM cantina WHERE id_azienda = p_id_azienda)
            HAVING  giacenza_ricalcolata <> l.giacenza;
    END$$
DELIMITER ;


-- Q5 — Top N best-selling beverages over a date range, for a winery.
-- Uses the (id_cantina, data_ora) index from Sec. 12.
DELIMITER $$
DROP PROCEDURE IF EXISTS top_seller$$
CREATE PROCEDURE top_seller (IN p_cantina INT, IN p_start DATETIME, IN p_end DATETIME, IN p_n INT)
    BEGIN
        SELECT m.id_bevanda,b.nome, sum(m.quantita_bottiglie) AS totale_venduto FROM movimenti m
        INNER JOIN bevanda b using(id_bevanda)
        WHERE m.tipo = 'VENDITA' AND m.id_cantina = p_cantina AND  m.data_ora >= p_start AND m.data_ora < p_end
        GROUP BY  m.id_bevanda, b.nome
        ORDER BY totale_venduto DESC
        LIMIT p_n;
    END$$
DELIMITER ;


-- Q10 — Beverages below the average stock of their own winery (reorder list).
DELIMITER $$
DROP PROCEDURE IF EXISTS bevande_sotto_media$$
CREATE PROCEDURE bevande_sotto_media (IN p_id_cantina INT)
    BEGIN
        SELECT l.id_bevanda, l.id_cantina, b.nome
        FROM listino l
        INNER JOIN bevanda b USING(id_bevanda)
        WHERE l.id_cantina = p_id_cantina
          AND l.giacenza < (SELECT AVG(giacenza) FROM listino WHERE id_cantina = p_id_cantina);
    END$$
DELIMITER ;


-- Q1 — Full technical sheet of a wine (ISA hierarchy recomposed).
-- DESIGN CHOICE: a blend (>1 vitigno) produces MULTIPLE rows, one per vitigno;
-- collapsing the vitigni into a single sheet is the caller's responsibility.
DELIMITER $$
DROP PROCEDURE IF EXISTS vino_tecnical_data$$
CREATE PROCEDURE vino_tecnical_data (IN p_id INT)
    BEGIN
        SELECT
            b.nome as descrizione, v.doc, b.categoria, b.gradazione_alcolica,
            b.volume, b.is_biologico, b.data_inserimento,
            b.note, b.foto_url, b.attivo,
            v.annata, v.colore, v.tipologia,
            v.metodo, v.tipo_blend, v.tipo_denominazione,
            v.acidita, vi.mese_vendemmia, vi.giorni_macerazione,
            vi.tipo_fermentazione, vi.tipo_vendemmia,
            vv.percentuale, vv.annata_vitigno,
            vit.nome as nome_vitigno, vit.sinonimo as sinonimo_vitigno,
            af.durata_legno_mesi, af.durata_bottiglia_mesi,
            af.tipo_legno, af.formato_legno,
            p.nome as nome_produttore, pa.nome_paese, r.nome_regione,
            r.zona
            FROM bevanda b
        INNER JOIN vino v using(id_bevanda)
        INNER JOIN vinificazione vi using(id_bevanda)
        INNER JOIN vino_vitigno vv using(id_bevanda)
        INNER JOIN vitigno vit using(id_vitigno)
        LEFT JOIN affinamento af using (id_bevanda)
        INNER JOIN produttore p using(id_produttore)
        LEFT JOIN regione r using(id_regione)
        LEFT JOIN paese pa USING(id_paese)
        WHERE id_bevanda = p_id;
    END$$
DELIMITER ;


-- Q2 — Published wine list "ready to print", for a winery.
-- LEFT JOIN on vino: annata is NULL for any non-wine bevande on the list.
DELIMITER $$
DROP PROCEDURE IF EXISTS carta_vini_stampa$$
CREATE PROCEDURE carta_vini_stampa (IN p_cantina INT)
    BEGIN
        SELECT b.nome as descrizione, p.nome as nome_produttore, l.prezzo_vendita, vino.annata from carta_vini cv
        INNER JOIN carta_vini_voce v using(id_carta_vini)
        INNER JOIN listino l using(id_listino)
        INNER JOIN bevanda b using(id_bevanda)
        INNER JOIN produttore p using (id_produttore)
        LEFT JOIN vino  using(id_bevanda)
        WHERE cv.id_cantina = p_cantina AND cv.attivo = TRUE
        ORDER BY b.categoria, descrizione;
    END$$
DELIMITER ;


-- Q3 — Warehouse value per winery: Σ (stock × purchase price).
DELIMITER $$
DROP PROCEDURE IF EXISTS valore_magazzino$$
CREATE PROCEDURE valore_magazzino (IN p_id_azienda INT)
    BEGIN
        SELECT l.id_cantina, sum(l.giacenza * l.prezzo_acquisto) as capitale_immobile from listino l
             INNER JOIN cantina c USING(id_cantina)
            WHERE c.id_azienda = p_id_azienda
            GROUP BY l.id_cantina;
    END$$
DELIMITER ;


-- Q4 — Average margin per beverage category: AVG(prezzo_vendita − prezzo_acquisto).
DELIMITER $$
DROP PROCEDURE IF EXISTS margine_per_categoria$$
CREATE PROCEDURE margine_per_categoria (IN p_id_azienda INT)
    BEGIN
        SELECT b.categoria, AVG(l.prezzo_vendita - l.prezzo_acquisto) as margine_medio FROM listino l
        INNER JOIN bevanda b using (id_bevanda)
            INNER JOIN cantina c USING(id_cantina)
            WHERE c.id_azienda = p_id_azienda
            GROUP BY b.categoria;
    END$$
DELIMITER ;


-- Q6 — Blend wines: wines with more than one vitigno (GROUP BY + HAVING COUNT > 1).
DELIMITER $$
DROP PROCEDURE IF EXISTS vini_blend$$
CREATE PROCEDURE vini_blend ()
    BEGIN
       SELECT b.id_bevanda, (SELECT COUNT(vv.id_vitigno) FROM vino v
                             inner join vino_vitigno vv using(id_bevanda)
                             WHERE v.id_bevanda = b.id_bevanda
                            ) as n_blend
       FROM bevanda b
       GROUP BY b.id_bevanda
        HAVING n_blend > 1;
    END$$
DELIMITER ;


-- Q8 — Never-sold beverages (anti-join with NOT EXISTS).
DELIMITER $$
DROP PROCEDURE IF EXISTS bevande_mai_vendute$$
CREATE PROCEDURE bevande_mai_vendute (IN p_id_cantina INT)
    BEGIN
        SELECT l.id_bevanda
        FROM listino l
        WHERE l.id_cantina = p_id_cantina
          AND NOT EXISTS (SELECT 1 FROM movimenti m
                          WHERE m.id_bevanda = l.id_bevanda
                            AND m.id_cantina = p_id_cantina
                            AND m.tipo = 'VENDITA');
    END$$
DELIMITER ;


-- Q9 — Most active employee (most movimenti) for each winery.
-- MariaDB does not support correlated derived tables (LATERAL): the "max per winery"
-- is obtained with two NON-correlated derived tables joined together. The JOIN on
-- (id_cantina, n = max_n) keeps any ties.
DELIMITER $$
DROP PROCEDURE IF EXISTS dipendente_piu_attivo$$
CREATE PROCEDURE dipendente_piu_attivo (IN p_id_azienda INT)
    BEGIN
        SELECT conteggi.id_cantina, conteggi.id_dipendente, conteggi.n
        FROM (SELECT id_cantina, id_dipendente, COUNT(*) AS n
              FROM movimenti
              WHERE id_cantina IN (SELECT id_cantina FROM cantina WHERE id_azienda = p_id_azienda)
              GROUP BY id_cantina, id_dipendente) AS conteggi
        INNER JOIN (SELECT id_cantina, MAX(n) AS max_n
                    FROM (SELECT id_cantina, id_dipendente, COUNT(*) AS n
                          FROM movimenti
                          WHERE id_cantina IN (SELECT id_cantina FROM cantina WHERE id_azienda = p_id_azienda)
                          GROUP BY id_cantina, id_dipendente) AS t
                    GROUP BY id_cantina) AS massimi
            ON massimi.id_cantina = conteggi.id_cantina
           AND conteggi.n = massimi.max_n
        ORDER BY conteggi.id_cantina;
    END$$
DELIMITER ;


-- Application write procedures (Track B — not Sec. 14 queries).

-- crea_bevanda — inserts a "never seen" bevanda into the global catalog.
-- Atomic chain: (optional) new produttore -> bevanda (parent) -> subtype row,
-- mandatory for the total and exclusive generalization (t,d):
-- every bevanda MUST be exactly one of vino/birra/super_alcolico/analcolico.
-- Produttore: if p_id_produttore IS NULL it creates a new one from the p_produttore_* fields;
-- otherwise it reuses the existing one.
-- Atomicity is guaranteed by the caller (autocommit=OFF connection: single commit
-- at the end of CALL, rollback on any error/SIGNAL).
DELIMITER $$
DROP PROCEDURE IF EXISTS crea_bevanda$$
CREATE PROCEDURE crea_bevanda (
    IN p_nome              VARCHAR(255),
    IN p_categoria         VARCHAR(100),
    IN p_gradazione        DECIMAL(5,2),
    IN p_volume            DECIMAL(8,2),
    IN p_is_biologico      BOOLEAN,
    IN p_id_produttore     INT,
    IN p_produttore_nome   VARCHAR(255),
    IN p_id_paese          INT,
    -- VINO-only parameters (NULL for the other categories)
    IN p_annata            SMALLINT,
    IN p_colore            VARCHAR(50),
    IN p_vitigni_json      TEXT,
    IN p_mese_vendemmia    VARCHAR(20),
    IN p_tipo_vendemmia    VARCHAR(100),
    IN p_durata_legno_mesi SMALLINT,
    IN p_tipo_legno        VARCHAR(100)
)
    BEGIN
        DECLARE v_id_produttore INT;
        DECLARE v_id_bevanda    INT;

        -- Produttore: existing or new
        IF p_id_produttore IS NULL THEN
            IF p_produttore_nome IS NULL OR p_produttore_nome = '' THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Produttore mancante';
            END IF;
            INSERT INTO produttore (nome, id_paese)
            VALUES (p_produttore_nome, p_id_paese);
            SET v_id_produttore = LAST_INSERT_ID();
        ELSE
            SET v_id_produttore = p_id_produttore;
        END IF;

        -- Bevanda (parent of the hierarchy)
        INSERT INTO bevanda
            (nome, categoria, gradazione_alcolica, volume, is_biologico, id_produttore)
        VALUES
            (p_nome, p_categoria, p_gradazione, p_volume, p_is_biologico, v_id_produttore);
        SET v_id_bevanda = LAST_INSERT_ID();

        -- Mandatory subtype (total generalization)
        IF p_categoria = 'VINO' THEN
            -- a vino must have >= 1 vitigno (N:M relationship "Composto")
            IF p_vitigni_json IS NULL OR JSON_LENGTH(p_vitigni_json) = 0 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Vitigno mancante per il vino';
            END IF;
            -- the blend must sum EXACTLY to 100
            IF ( SELECT SUM(pct) FROM JSON_TABLE(
                     p_vitigni_json, '$[*]'
                     COLUMNS (id_vitigno INT PATH '$.id', pct DECIMAL(5,2) PATH '$.pct')
                 ) AS jt ) <> 100 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Le percentuali dei vitigni devono sommare a 100';
            END IF;

            INSERT INTO vino (id_bevanda, annata, colore)
            VALUES (v_id_bevanda, p_annata, p_colore);
            -- vinificazione: mandatory 1:1 participation
            INSERT INTO vinificazione (mese_vendemmia, tipo_vendemmia, id_bevanda)
            VALUES (p_mese_vendemmia, p_tipo_vendemmia, v_id_bevanda);
            -- the whole blend in one set-based insert
            INSERT INTO vino_vitigno (id_bevanda, id_vitigno, percentuale)
            SELECT v_id_bevanda, jt.id_vitigno, jt.pct
            FROM JSON_TABLE(
                p_vitigni_json, '$[*]'
                COLUMNS (id_vitigno INT PATH '$.id', pct DECIMAL(5,2) PATH '$.pct')
            ) AS jt;
            -- affinamento: optional (0:1) -> inserted only if provided
            IF p_durata_legno_mesi IS NOT NULL
               OR (p_tipo_legno IS NOT NULL AND p_tipo_legno <> '') THEN
                INSERT INTO affinamento (durata_legno_mesi, tipo_legno, id_bevanda)
                VALUES (p_durata_legno_mesi, p_tipo_legno, v_id_bevanda);
            END IF;
        ELSEIF p_categoria = 'BIRRA' THEN
            INSERT INTO birra (id_bevanda) VALUES (v_id_bevanda);
        ELSEIF p_categoria = 'SUPER_ALCOLICO' THEN
            INSERT INTO super_alcolico (id_bevanda) VALUES (v_id_bevanda);
        ELSEIF p_categoria = 'ANALCOLICO' THEN
            INSERT INTO analcolico (id_bevanda) VALUES (v_id_bevanda);
        ELSE
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Categoria non valida';
        END IF;

        SELECT v_id_bevanda AS id_bevanda;
    END$$
DELIMITER ;


-- crea_dipendente — inserts a new dipendente.
-- The password is not hashed here: p_password_hash already arrives as a
-- bcrypt hash computed by the application.
DELIMITER $$
DROP PROCEDURE IF EXISTS crea_dipendente$$
CREATE PROCEDURE crea_dipendente (
    IN p_matricola      INT,
    IN p_nome           VARCHAR(100),
    IN p_cognome        VARCHAR(100),
    IN p_ruolo          VARCHAR(100),
    IN p_username       VARCHAR(100),
    IN p_password_hash  VARCHAR(255),
    IN p_email          VARCHAR(255),
    IN p_id_cantina     INT,

    IN p_id_azienda     INT
)
    BEGIN
        IF p_ruolo NOT IN ('titolare','magazziniere','cameriere') THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ruolo non valido';
        END IF;
        IF (SELECT id_azienda FROM cantina WHere id_cantina = p_id_cantina ) <> p_id_azienda THEN
             SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cantina fuori dalla tua azienda';
        END IF;
        INsert INTO dipendente
            (matricola, nome, cognome, ruolo, username, password_hash, email, id_cantina)
        VALUES
            (p_matricola, p_nome, p_cognome, p_ruolo, p_username, p_password_hash,
             p_email, p_id_cantina);

        SELECT LAST_INSERT_ID() AS id_dipendente;
    END$$
DELIMITER ;
