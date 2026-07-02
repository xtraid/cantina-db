DELIMITER $$
CREATE TRIGGER oversell BEFORE INSERT
  ON movimenti 
  FOR EACH ROW 
  BEGIN
    IF NEW.tipo IN ('SCARICO','VENDITA') THEN
      SELECT qr.giacenza INTO @giacenza FROM (SELECT l.giacenza FROM listino l
      WHERE l.id_cantina = NEW.id_cantina AND l.id_bevanda = NEW.id_bevanda) as qr
      ;
      IF @giacenza < NEW.quantita_bottiglie THEN
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
    END IF;
    IF NEW.tipo IN ('SCARICO', 'VENDITA') THEN
      UPDATE listino SET giacenza = giacenza - NEW.quantita_bottiglie 
      WHERE id_cantina = NEW.id_cantina AND id_bevanda = NEW.id_bevanda;

     END IF;
  END$$

DELIMITER ;
