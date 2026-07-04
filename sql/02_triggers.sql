DELIMITER $$
CREATE TRIGGER oversell BEFORE INSERT
  ON movimenti 
  FOR EACH ROW 
  BEGIN
    DECLARE v_giacenza INT DEFAULT NULL;
    IF NEW.tipo IN ('SCARICO','VENDITA') THEN
      SELECT qr.giacenza INTO v_giacenza FROM (SELECT l.giacenza FROM listino l
      WHERE l.id_cantina = NEW.id_cantina AND l.id_bevanda = NEW.id_bevanda) as qr
      ;
      IF v_giacenza IS NULL OR v_giacenza < NEW.quantita_bottiglie THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Bottiglie insufficienti';
      END IF;
    END IF;
  END$$


CREATE TRIGGER follow_up AFTER INSERT
  ON movimenti
  FOR EACH ROW 
  BEGIN
    IF NEW.tipo IN ('CARICO', 'ACQUISTO') THEN
      UPDATE listino SET giacenza = giacenza + NEW.quantita_bottiglie
      WHERE id_cantina = NEW.id_cantina AND id_bevanda = NEW.id_bevanda;
      -- ROW_COUNT() letto SUBITO dopo l'UPDATE: 0 righe = la coppia
      -- (cantina, bevanda) non è a listino → il carico va respinto, altrimenti
      -- la giacenza andrebbe persa in silenzio. Sicuro perché quantita_bottiglie>0
      -- (chk_movimenti_quantita) rende la riga sempre "changed".
      IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Carico su bevanda non presente nel listino della cantina';
      END IF;
    END IF;
    IF NEW.tipo IN ('SCARICO', 'VENDITA') THEN
      UPDATE listino SET giacenza = giacenza - NEW.quantita_bottiglie 
      WHERE id_cantina = NEW.id_cantina AND id_bevanda = NEW.id_bevanda;

     END IF;
  END$$


CREATE TRIGGER carta_vini_coerenza_cantina BEFORE INSERT
    ON carta_vini_voce
    FOR EACH ROW
    BEGIN
        DECLARE v_cantina_carta INT;
        DECLARE v_cantina_listino INT;

        SELECT id_cantina INTO v_cantina_carta
            FROM carta_vini
            WHERE id_carta_vini = NEW.id_carta_vini;

        SELECT id_cantina INTO v_cantina_listino
            From listino
            WHERE id_listino = NEW.id_listino;
        IF v_cantina_carta <> v_cantina_listino THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Voce di listino di una cantina diversa da quella della carta';
        end if;
    end $$

CREATE TRIGGER isa_vino BEFORE INSERT
    ON vino
    FOR EACH ROW
    BEGIN
        IF (SELECT categoria FROM bevanda WHERE id_bevanda = NEW.id_bevanda) <> 'VINO' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Categoria incoerente: la bevanda non è VINO';
        END IF;

    END $$

CREATE TRIGGER isa_birra BEFORE INSERT
    ON birra
    FOR EACH ROW
    BEGIN
        IF (SELECT categoria FROM bevanda WHERE id_bevanda = NEW.id_bevanda) <> 'BIRRA' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Categoria incoerente: la bevanda non è BIRRA';
        END IF;
    END $$

CREATE TRIGGER isa_super_alcolico BEFORE INSERT
    ON super_alcolico
    FOR EACH ROW
    BEGIN
        IF (SELECT categoria FROM bevanda WHERE id_bevanda = NEW.id_bevanda) <> 'SUPER_ALCOLICO' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Categoria incoerente: la bevanda non è SUPER_ALCOLICO';
        END IF;
    END $$

CREATE TRIGGER isa_analcolico BEFORE INSERT
    ON analcolico
    FOR EACH ROW
    BEGIN
        IF (SELECT categoria FROM bevanda WHERE id_bevanda = NEW.id_bevanda) <> 'ANALCOLICO' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Categoria incoerente: la bevanda non è ANALCOLICO';
        END IF;
    END $$

CREATE TRIGGER vino_vitigno_somma BEFORE INSERT
    ON vino_vitigno
    FOR EACH ROW
    BEGIN
        DECLARE  v_somma DECIMAL(5,2);

        SELECT COALESCE(SUM(percentuale), 0) INTO v_somma
            FROM vino_vitigno
            WHERE id_bevanda = NEW.id_bevanda;
        IF v_somma + COALESCE(NEW.percentuale, 0) > 100 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La somma delle percentuali dei vitigni supera 100';
        END IF;
    END $$

DELIMITER ;
