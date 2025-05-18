
DROP TRIGGER IF EXISTS trg_check_rang ON Attendre;
DROP TRIGGER IF EXISTS trigger_verifie_periode_session ON Attendre;

DROP TRIGGER IF EXISTS trigger_verrou_modification_attendre ON Attendre;
DROP TRIGGER IF EXISTS trigger_verrou_creation_attendre ON Attendre;

CREATE OR REPLACE FUNCTION verrouiller_modification_attendre()
RETURNS TRIGGER AS $$
BEGIN
    IF coalesce(current_setting('myapp.allow_modify_attendre', true), 'off') IS DISTINCT FROM 'on' THEN
        RAISE EXCEPTION 'Modification de attendre interdite hors trigger/fonction autorisé.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verrou_modification_attendre
BEFORE UPDATE ON Attendre
FOR EACH ROW
EXECUTE FUNCTION verrouiller_modification_attendre();


CREATE OR REPLACE FUNCTION verrouiller_creation_attendre()
RETURNS TRIGGER AS $$
BEGIN
    IF coalesce(current_setting('myapp.allow_create_attendre', true), 'off') IS DISTINCT FROM 'on' THEN
        RAISE EXCEPTION 'Création de attendre interdite hors trigger/fonction autorisé.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verrou_creation_attendre
BEFORE INSERT ON Attendre
FOR EACH ROW
EXECUTE FUNCTION verrouiller_creation_attendre();





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



-- Fonction pour décaler les rangs après la sortie d'un utilisateur de la file d'attente
CREATE OR REPLACE FUNCTION shift_queue_after_exit()
RETURNS TRIGGER AS $$
BEGIN
    -- Décrémenter le rang de tous les utilisateurs situés derrière celui qui vient de quitter
    UPDATE Attendre
    SET rang = rang - 1
    WHERE idQueue = OLD.idQueue
      AND rang > OLD.rang;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Trigger qui s'exécute après chaque suppression d'une ligne dans la table Attendre
CREATE TRIGGER trg_shift_queue_after_exit
AFTER DELETE ON Attendre
FOR EACH ROW
EXECUTE FUNCTION shift_queue_after_exit();


-- fonction qui met le rang d'un un utilisateur
CREATE OR REPLACE FUNCTION trg_combine_capacity_and_rank()
RETURNS TRIGGER AS $$
DECLARE
    current_count INTEGER;
    max_capacity INTEGER;
    max_rank INTEGER;
BEGIN
    -- Récupérer la capacité maximale de la file
    SELECT capaciteQueue
      INTO max_capacity
      FROM FileAttente
     WHERE idQueue = NEW.idQueue;

    -- Compter les utilisateurs déjà présents dans la file
    SELECT COUNT(*)
      INTO current_count
      FROM Attendre
     WHERE idQueue = NEW.idQueue;

    -- Si la file est pleine, empêcher l'insertion
    IF current_count >= max_capacity THEN
        RAISE EXCEPTION 'Impossible d ajouter un utilisateur. La file d attente (idQueue = %) est pleine (capacité maximale: %).', NEW.idQueue, max_capacity;
    END IF;

    -- sinon on met l'utilisateur à la fin de la file
    SELECT COALESCE(MAX(rang), 0)
      INTO max_rank
      FROM Attendre
     WHERE idQueue = NEW.idQueue;

    NEW.rang := max_rank + 1;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_before_insert_attendre
BEFORE INSERT ON Attendre
FOR EACH ROW
EXECUTE FUNCTION trg_combine_capacity_and_rank();
