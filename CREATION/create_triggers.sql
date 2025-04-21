
DROP TRIGGER IF EXISTS trg_check_rang ON Attendre;
DROP TRIGGER IF EXISTS trigger_creer_file_attente ON SessionVente;

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

-- Le trigger suivant est pr l'instant remplacé par l'execution à plusieurs reprises de gestion_files.sql

--fonction pour l'ajout automatique d'une file attente ds--
-- la table fileAttente une fois qu'une sessionEvenement est créée--
/*
CREATE OR REPLACE FUNCTION creer_file_attente_apres_session()
RETURNS TRIGGER AS $$
DECLARE
    capacite_estimee INT;
BEGIN
    -- Calcul du nombre min de personnes nécessaires pour écouler les billets
    capacite_estimee := CEIL(NEW.nbBilletsMisEnVente::DECIMAL / NEW.nbMaxBilletsAchetesVIP);

    -- Appliquer un plafond ds la file attente à 2000
    -- au cas où capacitee_estimee est bcp trop grand 
    --et risquerait de faire crasher le serveur irl
    IF capacite_estimee > 2000 THEN
        capacite_estimee := 2000;
    END IF;

    INSERT INTO FileAttente (capaciteQueue, idSessionVente)
    VALUES (capacite_estimee, NEW.idSession);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_creer_file_attente
AFTER INSERT ON SessionVente
FOR EACH ROW
EXECUTE FUNCTION creer_file_attente_apres_session();
/*