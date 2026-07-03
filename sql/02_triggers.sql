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

DELIMITER ;
