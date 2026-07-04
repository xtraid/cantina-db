-- ============================================================
--  Utenti DB e permessi per ruolo (GRANT/REVOKE) - cantina
--
--  ESEGUIRE COME ROOT (o utente con GRANT OPTION su `cantina`):
--      sudo mariadb cantina < sql/07_grants.sql
--  L'utente applicativo (es. `manuel`) NON ha GRANT OPTION su
--  `cantina` e non puo' eseguire questo script.
--
--  Modello: un utente MySQL PER RUOLO (non per dipendente).
--  - Lo scoping per COLONNE lo danno le viste (schema esterno).
--  - Lo scoping per RIGHE (id_cantina/id_azienda) lo passa l'app.
--  - Viste e stored procedure sono SQL SECURITY DEFINER (default):
--    l'invoker ha bisogno solo di SELECT sulla vista / EXECUTE sulla
--    SP, non dei privilegi sulle tabelle sottostanti. I permessi su
--    TABELLE BASE qui sotto servono solo dove i form leggono/scrivono
--    le tabelle DIRETTAMENTE (non tramite vista).
--
--  NB: questi utenti MySQL sono un layer DIVERSO dai login applicativi
--  (tabella `dipendente`, bcrypt). Le password qui devono combaciare
--  con quelle in app/.streamlit/secrets.toml.
-- ============================================================

-- Re-eseguibile
DROP USER IF EXISTS 'cantina_login'@'%';
DROP USER IF EXISTS 'cantina_titolare'@'%';
DROP USER IF EXISTS 'cantina_magazziniere'@'%';
DROP USER IF EXISTS 'cantina_cameriere'@'%';

CREATE USER 'cantina_login'@'%'        IDENTIFIED BY 'login_pw';
CREATE USER 'cantina_titolare'@'%'     IDENTIFIED BY 'titolare_pw';
CREATE USER 'cantina_magazziniere'@'%' IDENTIFIED BY 'magazziniere_pw';
CREATE USER 'cantina_cameriere'@'%'    IDENTIFIED BY 'cameriere_pw';

-- ------------------------------------------------------------
--  cantina_login — bootstrap PRE-login.
--  Usato una sola volta, prima di conoscere il ruolo, per
--  verificare le credenziali (auth.log_in): legge dipendente ⨝ cantina.
--  Nessun altro privilegio.
-- ------------------------------------------------------------
GRANT SELECT ON cantina.dipendente TO 'cantina_login'@'%';
GRANT SELECT ON cantina.cantina    TO 'cantina_login'@'%';

-- ------------------------------------------------------------
--  cantina_cameriere — SOLO lettura, nessuna vendita.
--  - carta vini tramite vista;
--  - toggle "query SP": scheda tecnica + carta stampabile;
--    la scheda tecnica legge bevanda ⨝ vino DIRETTAMENTE (pages.py).
-- ------------------------------------------------------------
GRANT SELECT ON cantina.v_carta_vini_cameriere TO 'cantina_cameriere'@'%';
GRANT SELECT ON cantina.bevanda                 TO 'cantina_cameriere'@'%';
GRANT SELECT ON cantina.vino                    TO 'cantina_cameriere'@'%';
GRANT EXECUTE ON PROCEDURE cantina.carta_vini_stampa    TO 'cantina_cameriere'@'%';
GRANT EXECUTE ON PROCEDURE cantina.vino_tecnical_data   TO 'cantina_cameriere'@'%';

-- ------------------------------------------------------------
--  cantina_magazziniere — gestione operativa della propria cantina.
--  Letture: viste overview + gestione, e tabelle base lette dai form
--  (dropdown). Scritture: movimenti (append-only) e listino.
--  UPDATE su listino e' PER COLONNA: prezzo/iva/attivo si', giacenza NO
--  (la giacenza la mantengono solo i trigger sui movimenti).
-- ------------------------------------------------------------
GRANT SELECT ON cantina.v_giacenze_magazziniere TO 'cantina_magazziniere'@'%';
GRANT SELECT ON cantina.v_gestione_magazzino    TO 'cantina_magazziniere'@'%';
-- tabelle base lette direttamente dai form (movimenti/listino/new_beverage)
GRANT SELECT ON cantina.listino    TO 'cantina_magazziniere'@'%';
GRANT SELECT ON cantina.bevanda    TO 'cantina_magazziniere'@'%';
GRANT SELECT ON cantina.fornitore  TO 'cantina_magazziniere'@'%';
GRANT SELECT ON cantina.produttore TO 'cantina_magazziniere'@'%';
GRANT SELECT ON cantina.vitigno    TO 'cantina_magazziniere'@'%';
-- scritture
GRANT INSERT ON cantina.movimenti  TO 'cantina_magazziniere'@'%';
GRANT INSERT ON cantina.listino    TO 'cantina_magazziniere'@'%';
GRANT UPDATE (prezzo_vendita, prezzo_acquisto, iva, attivo)
      ON cantina.listino TO 'cantina_magazziniere'@'%';
-- query di cantina + creazione bevanda (SP con SECURITY DEFINER)
GRANT EXECUTE ON PROCEDURE cantina.bevande_sotto_media  TO 'cantina_magazziniere'@'%';
GRANT EXECUTE ON PROCEDURE cantina.bevande_mai_vendute  TO 'cantina_magazziniere'@'%';
GRANT EXECUTE ON PROCEDURE cantina.crea_bevanda         TO 'cantina_magazziniere'@'%';

-- ------------------------------------------------------------
--  cantina_titolare — visione d'azienda + creazione dipendenti.
--  Non tocca tabelle direttamente: legge dalle viste (SECURITY DEFINER)
--  ed esegue le SP. Unica tabella base letta: `cantina` (dropdown cantine
--  e form nuovo dipendente in pages.py/forms.py).
-- ------------------------------------------------------------
GRANT SELECT ON cantina.v_giacenze_titolare  TO 'cantina_titolare'@'%';
GRANT SELECT ON cantina.v_gestione_azienda   TO 'cantina_titolare'@'%';
GRANT SELECT ON cantina.v_dipendenti_azienda TO 'cantina_titolare'@'%';
GRANT SELECT ON cantina.cantina              TO 'cantina_titolare'@'%';
-- query gestionali d'azienda
GRANT EXECUTE ON PROCEDURE cantina.valore_magazzino     TO 'cantina_titolare'@'%';
GRANT EXECUTE ON PROCEDURE cantina.margine_per_categoria TO 'cantina_titolare'@'%';
GRANT EXECUTE ON PROCEDURE cantina.vini_blend           TO 'cantina_titolare'@'%';
GRANT EXECUTE ON PROCEDURE cantina.dipendente_piu_attivo TO 'cantina_titolare'@'%';
GRANT EXECUTE ON PROCEDURE cantina.verifica_ridondanza  TO 'cantina_titolare'@'%';
GRANT EXECUTE ON PROCEDURE cantina.top_seller           TO 'cantina_titolare'@'%';
GRANT EXECUTE ON PROCEDURE cantina.crea_dipendente      TO 'cantina_titolare'@'%';

FLUSH PRIVILEGES;
