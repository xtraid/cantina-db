-- ============================================================================
-- 05_queries.sql — Query di esempio (documento Sez. 14)
-- Dominio: cantina / bevande. DB: `cantina`.
-- Prerequisiti: 01_schema, 02_triggers, 03_seed, 04_views già caricati.
-- ============================================================================

USE cantina;

-- Q7 — Verifica della ridondanza controllata: giacenza memorizzata in listino
-- vs ricalcolata dai movimenti (Σ carichi − Σ scarichi). 0 righe = trigger corretti.
DELIMITER $$
DROP PROCEDURE IF EXISTS verifica_ridondanza$$
CREATE PROCEDURE verifica_ridondanza ()
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
            HAVING  giacenza_ricalcolata <> l.giacenza;
    END$$
DELIMITER ;


-- Q5 — Top N bevande più vendute in un intervallo di date, per una cantina.
-- Usa l'indice (id_cantina, data_ora) di Sez. 12.
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


-- Q10 — Bevande sotto la giacenza media della propria cantina (lista riordino).
DELIMITER $$
DROP PROCEDURE IF EXISTS bevande_sotto_media$$
CREATE PROCEDURE bevande_sotto_media ()
    BEGIN
        SELECT l.id_bevanda, id_cantina, b.nome FROM listino  l
            INNER JOIN bevanda b using (id_bevanda)
            where l.giacenza < (SELECT avg(giacenza) from listino where l.id_cantina = id_cantina);
    END$$
DELIMITER ;


-- Q1 — Scheda tecnica completa di un vino (gerarchia ISA ricomposta).
-- SCELTA DI PROGETTO: un blend (>1 vitigno) produce PIÙ righe, una per vitigno;
-- collassare i vitigni in un'unica scheda è responsabilità del chiamante.
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
        INNER JOIN regione r using(id_regione)
        INNER JOIN paese pa USING(id_paese)
        WHERE id_bevanda = p_id;
    END$$
DELIMITER ;


-- Q2 — Carta vini pubblicata "pronta per la stampa", di una cantina.
-- LEFT JOIN su vino: l'annata è NULL per eventuali bevande non-vino in carta.
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


-- Q3 — Valore di magazzino per cantina: Σ (giacenza × prezzo di acquisto).
DELIMITER $$
DROP PROCEDURE IF EXISTS valore_magazzino$$
CREATE PROCEDURE valore_magazzino ()
    BEGIN
        SELECT l.id_cantina, sum(l.giacenza * l.prezzo_acquisto) as capitale_immobile from listino l
        GROUP BY l.id_cantina;
    END$$
DELIMITER ;


-- Q4 — Margine medio per categoria di bevanda: AVG(prezzo_vendita − prezzo_acquisto).
DELIMITER $$
DROP PROCEDURE IF EXISTS margine_per_categoria$$
CREATE PROCEDURE margine_per_categoria ()
    BEGIN
        SELECT b.categoria, AVG(l.prezzo_vendita - l.prezzo_acquisto) as margine_medio FROM listino l
        INNER JOIN bevanda b using (id_bevanda)
        GROUP BY b.categoria;
    END$$
DELIMITER ;


-- Q6 — Vini blend: vini con più di un vitigno (GROUP BY + HAVING COUNT > 1).
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


-- Q8 — Bevande mai vendute (anti-join con NOT EXISTS).
DELIMITER $$
DROP PROCEDURE IF EXISTS bevande_mai_vendute$$
CREATE PROCEDURE bevande_mai_vendute ()
    BEGIN
        SELECT b.id_bevanda from bevanda b
        where NOT EXISTS (SELECT 1 from movimenti m1
                                       WHERE b.id_bevanda = m1.id_bevanda AND m1.tipo = 'VENDITA');
    END$$
DELIMITER ;


-- Q9 — Dipendente più attivo (più movimenti) per ciascuna cantina.
-- MariaDB non supporta le derived table correlate (LATERAL): il "max per cantina"
-- si ottiene con due derived table NON correlate unite in JOIN. Il JOIN su
-- (id_cantina, n = max_n) tiene eventuali pareggi.
DELIMITER $$
DROP PROCEDURE IF EXISTS dipendente_piu_attivo$$
CREATE PROCEDURE dipendente_piu_attivo ()
    BEGIN
        SELECT conteggi.id_cantina, conteggi.id_dipendente, conteggi.n
        FROM (SELECT id_cantina, id_dipendente, COUNT(*) AS n
              FROM movimenti
              GROUP BY id_cantina, id_dipendente) AS conteggi
        INNER JOIN (SELECT id_cantina, MAX(n) AS max_n
                    FROM (SELECT id_cantina, id_dipendente, COUNT(*) AS n
                          FROM movimenti
                          GROUP BY id_cantina, id_dipendente) AS t
                    GROUP BY id_cantina) AS massimi
            ON massimi.id_cantina = conteggi.id_cantina
           AND conteggi.n = massimi.max_n
        ORDER BY conteggi.id_cantina;
    END$$
DELIMITER ;


-- ============================================================================
-- Procedure di scrittura dell'applicazione (Track B — NON query di Sez. 14).
-- ============================================================================

-- crea_bevanda — inserisce una bevanda "mai vista" nel catalogo globale.
-- Catena atomica: (eventuale) produttore nuovo -> bevanda (padre) -> riga del
-- sottotipo, obbligatoria per la generalizzazione totale ed esclusiva (t,d):
-- ogni bevanda DEVE essere esattamente una tra vino/birra/super_alcolico/analcolico.
-- Produttore: se p_id_produttore IS NULL ne crea uno nuovo dai campi p_produttore_*;
-- altrimenti riusa quello esistente.
-- L'atomicità è garantita dal chiamante (connessione autocommit=OFF: commit unico
-- a fine CALL, rollback su qualunque errore/SIGNAL).
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
    IN p_produttore_paese  VARCHAR(100),
    -- Parametri del solo VINO (NULL per le altre categorie)
    IN p_annata            SMALLINT,
    IN p_colore            VARCHAR(50),
    IN p_id_vitigno        INT,
    IN p_percentuale       DECIMAL(5,2),
    IN p_mese_vendemmia    VARCHAR(20),
    IN p_tipo_vendemmia    VARCHAR(100),
    IN p_durata_legno_mesi SMALLINT,
    IN p_tipo_legno        VARCHAR(100)
)
    BEGIN
        DECLARE v_id_produttore INT;
        DECLARE v_id_bevanda    INT;

        -- Produttore: esistente o nuovo
        IF p_id_produttore IS NULL THEN
            IF p_produttore_nome IS NULL OR p_produttore_nome = '' THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Produttore mancante';
            END IF;
            INSERT INTO produttore (nome, paese)
            VALUES (p_produttore_nome, p_produttore_paese);
            SET v_id_produttore = LAST_INSERT_ID();
        ELSE
            SET v_id_produttore = p_id_produttore;
        END IF;

        -- Bevanda (padre della gerarchia)
        INSERT INTO bevanda
            (nome, categoria, gradazione_alcolica, volume, is_biologico, id_produttore)
        VALUES
            (p_nome, p_categoria, p_gradazione, p_volume, p_is_biologico, v_id_produttore);
        SET v_id_bevanda = LAST_INSERT_ID();

        -- Sottotipo obbligatorio (generalizzazione totale)
        IF p_categoria = 'VINO' THEN
            -- vino deve avere >= 1 vitigno (relazione N:M "Composto")
            IF p_id_vitigno IS NULL THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Vitigno mancante per il vino';
            END IF;
            INSERT INTO vino (id_bevanda, annata, colore)
            VALUES (v_id_bevanda, p_annata, p_colore);
            -- vinificazione: partecipazione 1:1 obbligatoria
            INSERT INTO vinificazione (mese_vendemmia, tipo_vendemmia, id_bevanda)
            VALUES (p_mese_vendemmia, p_tipo_vendemmia, v_id_bevanda);
            INSERT INTO vino_vitigno (id_bevanda, id_vitigno, percentuale)
            VALUES (v_id_bevanda, p_id_vitigno, p_percentuale);
            -- affinamento: opzionale (0:1) -> inserito solo se fornito
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
