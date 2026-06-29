-- ============================================================
--  Gestione Cantina / Azienda Vinicola - Schema relazionale
--  MariaDB 10.6+ (InnoDB, utf8mb4)
--
--  Traduzione del modello logico in DDL; ogni relazione e'
--  annotata con le rispettive cardinalita'. Script re-eseguibile:
--  i DROP iniziali ricreano lo schema da zero.
-- ============================================================

-- USE cantina;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS carta_vini_voce;
DROP TABLE IF EXISTS carta_vini;
DROP TABLE IF EXISTS listino;
DROP TABLE IF EXISTS movimenti;
DROP TABLE IF EXISTS vino_vitigno;
DROP TABLE IF EXISTS affinamento;
DROP TABLE IF EXISTS vinificazione;
DROP TABLE IF EXISTS analcolico_ingrediente;
DROP TABLE IF EXISTS birra_malto;
DROP TABLE IF EXISTS birra_luppolo;
DROP TABLE IF EXISTS analcolico;
DROP TABLE IF EXISTS super_alcolico;
DROP TABLE IF EXISTS birra;
DROP TABLE IF EXISTS vino;
DROP TABLE IF EXISTS bevanda;
DROP TABLE IF EXISTS vitigno;
DROP TABLE IF EXISTS fornitore;
DROP TABLE IF EXISTS produttore;
DROP TABLE IF EXISTS regione;
DROP TABLE IF EXISTS dipendente;
DROP TABLE IF EXISTS cantina;
DROP TABLE IF EXISTS azienda;
SET FOREIGN_KEY_CHECKS = 1;

-- ===================== ANAGRAFICHE =====================

CREATE TABLE azienda (
    id_azienda                INT AUTO_INCREMENT PRIMARY KEY,
    tipo                      VARCHAR(100),
    ragione_sociale           VARCHAR(255) NOT NULL,
    indirizzo_sede_principale VARCHAR(255),
    p_iva                     VARCHAR(20),
    email                     VARCHAR(255),
    pec                       VARCHAR(255),
    telefono                  VARCHAR(50),
    titolare                  VARCHAR(255),
    sito_web                  VARCHAR(255),
    logo                      VARCHAR(255),
    attivo                    BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE cantina (
    id_cantina          INT AUTO_INCREMENT PRIMARY KEY,
    nome                VARCHAR(255) NOT NULL,
    indirizzo           VARCHAR(255),
    tipo                VARCHAR(100),
    id_azienda          INT NOT NULL,
    CONSTRAINT fk_cantina_azienda
        FOREIGN KEY (id_azienda) REFERENCES azienda(id_azienda)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- "Possiede": Azienda (1:N) - Cantina (1:1) => FK su Cantina, NOT NULL

CREATE TABLE dipendente (
    id_dipendente       INT AUTO_INCREMENT PRIMARY KEY,
    matricola           INT NOT NULL UNIQUE,
    nome                VARCHAR(100) NOT NULL,
    cognome             VARCHAR(100) NOT NULL,
    ruolo               VARCHAR(100),
    username            VARCHAR(100) UNIQUE,
    password_hash       VARCHAR(255),
    email               VARCHAR(255),
    attivo              BOOLEAN DEFAULT TRUE,
    id_cantina          INT NOT NULL,
    CONSTRAINT fk_dipendente_cantina
        FOREIGN KEY (id_cantina) REFERENCES cantina(id_cantina)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- "Lavora_in": Dipendente (1:1) - Cantina (1:N) => FK su Dipendente, NOT NULL

CREATE TABLE regione (
    id_regione          INT AUTO_INCREMENT PRIMARY KEY,
    nome_paese          VARCHAR(100) NOT NULL UNIQUE,
    code_iso            VARCHAR(10),
    nome_regione        VARCHAR(100),
    zona                VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE produttore (
    id_produttore       INT AUTO_INCREMENT PRIMARY KEY,
    nome                VARCHAR(255) NOT NULL,
    paese               VARCHAR(100),
    sito_web            VARCHAR(255),
    attivo              BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE fornitore (
    id_fornitore        INT AUTO_INCREMENT PRIMARY KEY,
    ragione_sociale     VARCHAR(255) NOT NULL,
    p_iva               VARCHAR(20),
    is_cliente          BOOLEAN DEFAULT FALSE,
    is_fornitore        BOOLEAN DEFAULT FALSE,
    indirizzo           VARCHAR(255),
    telefono            VARCHAR(50),
    email               VARCHAR(255),
    attivo              BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE vitigno (
    id_vitigno          INT AUTO_INCREMENT PRIMARY KEY,
    nome                VARCHAR(150) NOT NULL UNIQUE,
    sinonimo            VARCHAR(150)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== BEVANDA (padre) + GENERALIZZAZIONE TOTALE/ESCLUSIVA (t,d) =====

CREATE TABLE bevanda (
    id_bevanda          INT AUTO_INCREMENT PRIMARY KEY,
    nome                VARCHAR(255) NOT NULL,
    categoria           VARCHAR(100),          -- discriminante (t,d)
    gradazione_alcolica DECIMAL(5,2),
    volume              DECIMAL(8,2),
    is_biologico        BOOLEAN DEFAULT FALSE,
    data_inserimento    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    note                TEXT,
    foto_url            VARCHAR(500),
    attivo              BOOLEAN DEFAULT TRUE,
    id_produttore       INT NOT NULL,
    id_regione          INT,                   -- provenienza opzionale
    CONSTRAINT fk_bevanda_produttore
        FOREIGN KEY (id_produttore) REFERENCES produttore(id_produttore),
    CONSTRAINT fk_bevanda_regione
        FOREIGN KEY (id_regione) REFERENCES regione(id_regione),
    CONSTRAINT chk_bevanda_categoria
        CHECK (categoria IN ('VINO','BIRRA','SUPER_ALCOLICO','ANALCOLICO'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- "Produce": Produttore (1:N) - Bevanda (1:1) => FK su Bevanda, NOT NULL
-- "Proviene": Bevanda (0:1) - Regione (0:N) => FK su Bevanda, NULLABLE

CREATE TABLE vino (
    id_bevanda          INT PRIMARY KEY,
    annata              SMALLINT,
    colore              VARCHAR(50),
    tipologia           VARCHAR(100),
    metodo              VARCHAR(100),
    tipo_blend          VARCHAR(100),
    tipo_denominazione  VARCHAR(100),
    doc                 VARCHAR(100),
    acidita             DECIMAL(5,2),
    CONSTRAINT fk_vino_bevanda
        FOREIGN KEY (id_bevanda) REFERENCES bevanda(id_bevanda) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE birra (
    id_bevanda          INT PRIMARY KEY,
    stile               VARCHAR(100),
    tipo_fermentazione  VARCHAR(100),
    ibu                 DECIMAL(6,2),
    ebc                 DECIMAL(6,2),
    densita_originale   DECIMAL(6,3),
    densita_finale      DECIMAL(6,3),
    is_filtrata         BOOLEAN DEFAULT FALSE,
    is_pastorizzata     BOOLEAN DEFAULT FALSE,
    is_rifermentata     BOOLEAN DEFAULT FALSE,
    lievito             VARCHAR(255),
    CONSTRAINT fk_birra_bevanda
        FOREIGN KEY (id_bevanda) REFERENCES bevanda(id_bevanda) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE super_alcolico (
    id_bevanda          INT PRIMARY KEY,
    categoria           VARCHAR(100),
    materia_prima       VARCHAR(150),
    tipo_distillazione  VARCHAR(100),
    numero_distillazioni SMALLINT,
    anni_invecchiamento SMALLINT,
    tipo_botte          VARCHAR(100),
    is_torbato          BOOLEAN DEFAULT FALSE,
    ppm_fenoli          DECIMAL(6,2),
    blend               VARCHAR(255),
    CONSTRAINT fk_superalcolico_bevanda
        FOREIGN KEY (id_bevanda) REFERENCES bevanda(id_bevanda) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE analcolico (
    id_bevanda          INT PRIMARY KEY,
    categoria           VARCHAR(100),
    has_zuccheri_aggiunti BOOLEAN DEFAULT FALSE,
    is_frizzante        BOOLEAN DEFAULT FALSE,
    CONSTRAINT fk_analcolico_bevanda
        FOREIGN KEY (id_bevanda) REFERENCES bevanda(id_bevanda) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== ATTRIBUTI MULTIVALORE -> TABELLE PONTE (1NF) =====

CREATE TABLE birra_luppolo (
    id_bevanda          INT NOT NULL,
    nome_luppolo        VARCHAR(150) NOT NULL,
    PRIMARY KEY (id_bevanda, nome_luppolo),
    CONSTRAINT fk_birraluppolo_birra
        FOREIGN KEY (id_bevanda) REFERENCES birra(id_bevanda) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE birra_malto (
    id_bevanda          INT NOT NULL,
    nome_malto          VARCHAR(150) NOT NULL,
    PRIMARY KEY (id_bevanda, nome_malto),
    CONSTRAINT fk_birramalto_birra
        FOREIGN KEY (id_bevanda) REFERENCES birra(id_bevanda) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE analcolico_ingrediente (
    id_bevanda          INT NOT NULL,
    nome_ingrediente    VARCHAR(150) NOT NULL,
    PRIMARY KEY (id_bevanda, nome_ingrediente),
    CONSTRAINT fk_analingr_analcolico
        FOREIGN KEY (id_bevanda) REFERENCES analcolico(id_bevanda) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== DETTAGLI DEL SOLO VINO =====

CREATE TABLE vinificazione (
    id_vinificazione    INT AUTO_INCREMENT PRIMARY KEY,
    mese_vendemmia      VARCHAR(20),
    giorni_macerazione  SMALLINT,
    tipo_fermentazione  VARCHAR(100),
    tipo_vendemmia      VARCHAR(100),
    id_bevanda          INT NOT NULL UNIQUE,
    CONSTRAINT fk_vinificazione_vino
        FOREIGN KEY (id_bevanda) REFERENCES vino(id_bevanda)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- "Viene_vinificato": Vino (1:1) - Vinificazione (1:1)

CREATE TABLE affinamento (
    id_affinamento      INT AUTO_INCREMENT PRIMARY KEY,
    durata_legno_mesi   SMALLINT,
    durata_bottiglia_mesi SMALLINT,
    tipo_legno          VARCHAR(100),
    formato_legno       VARCHAR(100),
    id_bevanda          INT UNIQUE,   -- nullable: 0:1 lato Affinamento
    CONSTRAINT fk_affinamento_vino
        FOREIGN KEY (id_bevanda) REFERENCES vino(id_bevanda)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- "Viene_affinato": Vino (1:1) - Affinamento (0:1)

-- ===== N:M Vino - Vitigno ("Composto") =====

CREATE TABLE vino_vitigno (
    id_bevanda          INT NOT NULL,
    id_vitigno          INT NOT NULL,
    percentuale         DECIMAL(5,2),
    annata_vitigno      SMALLINT,
    PRIMARY KEY (id_bevanda, id_vitigno),
    CONSTRAINT fk_vinovitigno_vino
        FOREIGN KEY (id_bevanda) REFERENCES vino(id_bevanda),
    CONSTRAINT fk_vinovitigno_vitigno
        FOREIGN KEY (id_vitigno) REFERENCES vitigno(id_vitigno)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== MOVIMENTI =====

CREATE TABLE movimenti (
    id_movimento        INT AUTO_INCREMENT PRIMARY KEY,
    tipo                VARCHAR(50) NOT NULL,
    quantita_bottiglie  INT NOT NULL,
    prezzo_unitario     DECIMAL(10,2),
    data_ora            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_bevanda          INT NOT NULL,      -- "Riguarda": Bevanda - Movimenti (base della giacenza per bevanda,cantina)
    id_dipendente       INT NOT NULL,      -- "Registra": Dipendente (0:N) - Movimenti (1:1)
    id_cantina          INT NOT NULL,      -- "Avviene_in": Cantina (0:N) - Movimenti (1:1)
    id_fornitore        INT,               -- "Coinvolge": Fornitore (0:N) - Movimenti (0:1)
    CONSTRAINT fk_movimenti_bevanda
        FOREIGN KEY (id_bevanda) REFERENCES bevanda(id_bevanda),
    CONSTRAINT fk_movimenti_dipendente
        FOREIGN KEY (id_dipendente) REFERENCES dipendente(id_dipendente),
    CONSTRAINT fk_movimenti_cantina
        FOREIGN KEY (id_cantina) REFERENCES cantina(id_cantina),
    CONSTRAINT fk_movimenti_fornitore
        FOREIGN KEY (id_fornitore) REFERENCES fornitore(id_fornitore),
    CONSTRAINT chk_movimenti_tipo CHECK (tipo IN ('CARICO','SCARICO','VENDITA','ACQUISTO')),
    CONSTRAINT chk_movimenti_quantita CHECK (quantita_bottiglie > 0),
    CONSTRAINT chk_movimenti_acquisto CHECK (tipo <> 'ACQUISTO' OR id_fornitore IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== LISTINO / CARTA VINI =====

CREATE TABLE listino (
    id_listino          INT AUTO_INCREMENT PRIMARY KEY,
    prezzo_vendita      DECIMAL(10,2),
    prezzo_acquisto     DECIMAL(10,2),
    iva                 DECIMAL(5,2),
    giacenza            INT NOT NULL DEFAULT 0,   -- derivata dai movimenti, mantenuta dai trigger
    attivo              BOOLEAN DEFAULT TRUE,
    data_ultimo_aggiornamento TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    id_bevanda          INT NOT NULL,   -- "Riguarda": Bevanda (0:N) - Listino (1:1)
    id_cantina          INT NOT NULL,   -- "Contiene": Cantina (0:N) - Listino (1:1)
    CONSTRAINT fk_listino_bevanda
        FOREIGN KEY (id_bevanda) REFERENCES bevanda(id_bevanda),
    CONSTRAINT fk_listino_cantina
        FOREIGN KEY (id_cantina) REFERENCES cantina(id_cantina),
    CONSTRAINT chk_listino_prezzo CHECK (prezzo_vendita >= prezzo_acquisto),
    CONSTRAINT chk_listino_giacenza CHECK (giacenza >= 0),
    CONSTRAINT uq_listino_bevanda_cantina UNIQUE (id_cantina, id_bevanda)  -- una bevanda al massimo 1 volta per cantina
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE carta_vini (
    id_carta_vini       INT AUTO_INCREMENT PRIMARY KEY,
    titolo              VARCHAR(255) NOT NULL,
    stato               VARCHAR(50),
    data_creazione      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_pubblicazione  TIMESTAMP NULL,
    data_archiviazione  TIMESTAMP NULL,
    attivo              BOOLEAN DEFAULT TRUE,
    id_cantina          INT NOT NULL,    -- "Pubblica": Carta_vini (1:1) - Cantina (1:N)
    id_dipendente       INT NOT NULL,    -- "Cura": Carta_vini (1:1) - Dipendente (0:N)
    CONSTRAINT fk_cartavini_cantina
        FOREIGN KEY (id_cantina) REFERENCES cantina(id_cantina),
    CONSTRAINT fk_cartavini_dipendente
        FOREIGN KEY (id_dipendente) REFERENCES dipendente(id_dipendente),
    CONSTRAINT chk_cartavini_date_pub  CHECK (data_pubblicazione IS NULL OR data_pubblicazione >= data_creazione),
    CONSTRAINT chk_cartavini_date_arch CHECK (data_archiviazione IS NULL OR data_archiviazione >= data_pubblicazione)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE carta_vini_voce (
    id_carta_vini       INT NOT NULL,
    id_listino          INT NOT NULL,
    ordine              INT,
    descrizione_posizione VARCHAR(255),
    PRIMARY KEY (id_carta_vini, id_listino),
    CONSTRAINT fk_cvvoce_cartavini
        FOREIGN KEY (id_carta_vini) REFERENCES carta_vini(id_carta_vini),
    CONSTRAINT fk_cvvoce_listino
        FOREIGN KEY (id_listino) REFERENCES listino(id_listino)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== INDICI SULLE FK =====

CREATE INDEX idx_cantina_azienda       ON cantina(id_azienda);
CREATE INDEX idx_dipendente_cantina    ON dipendente(id_cantina);
CREATE INDEX idx_bevanda_produttore    ON bevanda(id_produttore);
CREATE INDEX idx_bevanda_regione       ON bevanda(id_regione);
CREATE INDEX idx_movimenti_bevanda     ON movimenti(id_bevanda);
CREATE INDEX idx_movimenti_dipendente  ON movimenti(id_dipendente);
CREATE INDEX idx_movimenti_cantina     ON movimenti(id_cantina);
CREATE INDEX idx_movimenti_fornitore   ON movimenti(id_fornitore);
CREATE INDEX idx_listino_bevanda       ON listino(id_bevanda);
CREATE INDEX idx_listino_cantina       ON listino(id_cantina);
CREATE INDEX idx_cartavini_cantina     ON carta_vini(id_cantina);
CREATE INDEX idx_cartavini_dipendente  ON carta_vini(id_dipendente);
