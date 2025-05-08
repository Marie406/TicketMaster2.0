
DROP TRIGGER IF EXISTS trg_check_rang ON Attendre;
DROP TRIGGER IF EXISTS trigger_verifie_periode_session ON Attendre;


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


CREATE OR REPLACE FUNCTION verifie_periode_session()
RETURNS TRIGGER AS $$
DECLARE
    debut TIMESTAMP;
    fin TIMESTAMP;
BEGIN
    SELECT sv.dateDebutSession, sv.dateFinSession
    INTO debut, fin
    FROM FileAttente fa
    JOIN SessionVente sv ON fa.idSessionVente = sv.idSession
    WHERE fa.idQueue = NEW.idQueue;

    IF current_timestamp NOT BETWEEN debut AND fin THEN
        RAISE EXCEPTION 'Vous ne pouvez pas rejoindre la file d''attente en dehors de la période d''ouverture.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verifie_periode_session
BEFORE INSERT ON Attendre
FOR EACH ROW
EXECUTE FUNCTION verifie_periode_session();
