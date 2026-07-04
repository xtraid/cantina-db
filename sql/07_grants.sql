-- DB users and per-role permissions (GRANT/REVOKE) - cantina.
--
-- Run as root (or a user with GRANT OPTION on `cantina`):
--     sudo mariadb cantina < sql/07_grants.sql
-- The application user (e.g. `manuel`) does not have GRANT OPTION on `cantina`
-- and cannot run this script.
--
-- Model: one MySQL user per role (not per employee).
-- - Column-level scoping is provided by the views (external schema).
-- - Row-level scoping (id_cantina/id_azienda) is passed by the app.
-- - Views and stored procedures are SQL SECURITY DEFINER (default):
--   the invoker only needs SELECT on the view / EXECUTE on the
--   SP, not privileges on the underlying tables. The permissions on
--   base tables below are needed only where the forms read/write
--   the tables directly (not through a view).
--
-- Note: these MySQL users are a different layer from the application logins
-- (`dipendente` table, bcrypt). The passwords here must match those
-- in app/.streamlit/secrets.toml.

-- Re-runnable
DROP USER IF EXISTS 'cantina_login'@'%';
DROP USER IF EXISTS 'cantina_titolare'@'%';
DROP USER IF EXISTS 'cantina_magazziniere'@'%';
DROP USER IF EXISTS 'cantina_cameriere'@'%';

CREATE USER 'cantina_login'@'%'        IDENTIFIED BY 'login_pw';
CREATE USER 'cantina_titolare'@'%'     IDENTIFIED BY 'titolare_pw';
CREATE USER 'cantina_magazziniere'@'%' IDENTIFIED BY 'magazziniere_pw';
CREATE USER 'cantina_cameriere'@'%'    IDENTIFIED BY 'cameriere_pw';

-- cantina_login — pre-login bootstrap.
-- Used once, before the role is known, to verify the credentials
-- (auth.log_in): reads dipendente ⨝ cantina. No other privilege.
GRANT SELECT ON cantina.dipendente TO 'cantina_login'@'%';
GRANT SELECT ON cantina.cantina    TO 'cantina_login'@'%';

-- cantina_cameriere — read-only, no sales.
-- 3-tab page (pages.py):
-- - tab "Carta vini": view v_carta_vini_cameriere;
-- - tab "Carta stampabile": SP carta_vini_stampa;
-- - tab "Scheda tecnica": SP vino_tecnical_data + reads bevanda ⨝ vino
--   directly (wine dropdown).
GRANT SELECT ON cantina.v_carta_vini_cameriere TO 'cantina_cameriere'@'%';
GRANT SELECT ON cantina.bevanda                 TO 'cantina_cameriere'@'%';
GRANT SELECT ON cantina.vino                    TO 'cantina_cameriere'@'%';
GRANT EXECUTE ON PROCEDURE cantina.carta_vini_stampa    TO 'cantina_cameriere'@'%';
GRANT EXECUTE ON PROCEDURE cantina.vino_tecnical_data   TO 'cantina_cameriere'@'%';

-- cantina_magazziniere — operational management of its own winery.
-- Reads: overview + management views, and base tables read by the forms
-- (dropdowns). Writes: movimenti (append-only) and listino.
-- UPDATE on listino is per-column: prezzo/iva/attivo yes, giacenza no
-- (giacenza is maintained only by the triggers on movimenti).
GRANT SELECT ON cantina.v_giacenze_magazziniere TO 'cantina_magazziniere'@'%';
GRANT SELECT ON cantina.v_gestione_magazzino    TO 'cantina_magazziniere'@'%';
-- base tables read directly by the forms (movimenti/listino/new_beverage)
GRANT SELECT ON cantina.listino    TO 'cantina_magazziniere'@'%';
GRANT SELECT ON cantina.bevanda    TO 'cantina_magazziniere'@'%';
GRANT SELECT ON cantina.fornitore  TO 'cantina_magazziniere'@'%';
GRANT SELECT ON cantina.produttore TO 'cantina_magazziniere'@'%';
GRANT SELECT ON cantina.paese      TO 'cantina_magazziniere'@'%';
GRANT SELECT ON cantina.vitigno    TO 'cantina_magazziniere'@'%';
-- writes
GRANT INSERT ON cantina.movimenti  TO 'cantina_magazziniere'@'%';
GRANT INSERT ON cantina.listino    TO 'cantina_magazziniere'@'%';
GRANT UPDATE (prezzo_vendita, prezzo_acquisto, iva, attivo)
      ON cantina.listino TO 'cantina_magazziniere'@'%';
-- winery queries + beverage creation (SP with SECURITY DEFINER)
GRANT EXECUTE ON PROCEDURE cantina.bevande_sotto_media  TO 'cantina_magazziniere'@'%';
GRANT EXECUTE ON PROCEDURE cantina.bevande_mai_vendute  TO 'cantina_magazziniere'@'%';
GRANT EXECUTE ON PROCEDURE cantina.crea_bevanda         TO 'cantina_magazziniere'@'%';

-- cantina_titolare — company-wide view + employee creation.
-- Does not touch tables directly: reads from the views (SECURITY DEFINER)
-- and runs the SPs. Only base table read: `cantina` (winery dropdown
-- and new-employee form in pages.py/forms.py).
GRANT SELECT ON cantina.v_giacenze_titolare  TO 'cantina_titolare'@'%';
GRANT SELECT ON cantina.v_gestione_azienda   TO 'cantina_titolare'@'%';
GRANT SELECT ON cantina.v_dipendenti_azienda TO 'cantina_titolare'@'%';
GRANT SELECT ON cantina.cantina              TO 'cantina_titolare'@'%';
-- company management queries
GRANT EXECUTE ON PROCEDURE cantina.valore_magazzino     TO 'cantina_titolare'@'%';
GRANT EXECUTE ON PROCEDURE cantina.margine_per_categoria TO 'cantina_titolare'@'%';
GRANT EXECUTE ON PROCEDURE cantina.vini_blend           TO 'cantina_titolare'@'%';
GRANT EXECUTE ON PROCEDURE cantina.dipendente_piu_attivo TO 'cantina_titolare'@'%';
GRANT EXECUTE ON PROCEDURE cantina.verifica_ridondanza  TO 'cantina_titolare'@'%';
GRANT EXECUTE ON PROCEDURE cantina.top_seller           TO 'cantina_titolare'@'%';
GRANT EXECUTE ON PROCEDURE cantina.crea_dipendente      TO 'cantina_titolare'@'%';

FLUSH PRIVILEGES;
