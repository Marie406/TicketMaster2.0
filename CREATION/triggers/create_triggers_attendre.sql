
DROP TRIGGER IF EXISTS trg_check_rang ON Attendre;
--DROP TRIGGER IF EXISTS trigger_set_grille ON AvoirLieu;
--DROP TRIGGER IF EXISTS trigger_genererBillets ON Grille;
-- DROP TRIGGER IF EXISTS trigger_creer_file_attente ON SessionVente;


CREATE OR REPLACE FUNCTION check_rang_valid() RETURNS TRIGGER AS $$
DECLARE
    max_capacity INT;
BEGIN
    SELECT capaciteQueue INTO max_capacity FROM FileAttente WHERE idQueue = NEW.idQueue;

    IF NEW.rang < 0 OR NEW.rang >= max_capacity THEN
        RAISE EXCEPTION 'Le rang % est invalide. Il doit etre entre 0 et %', NEW.rang, max_capacity - 1;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création du trigger pour vérifier le rang
CREATE TRIGGER trg_check_rang
BEFORE INSERT OR UPDATE ON Attendre
FOR EACH ROW
EXECUTE FUNCTION check_rang_valid();

