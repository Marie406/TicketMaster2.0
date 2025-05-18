DROP TRIGGER IF EXISTS trigger_verifier_et_attribuer_session ON SessionVente;
DROP TRIGGER IF EXISTS trigger_nettoyer_billets_apres_annulation ON SessionVente;
DROP TRIGGER IF EXISTS trigger_creer_sv_attente ON SessionVente;

DROP TRIGGER IF EXISTS trigger_verrou_modification_sv ON SessionVente;
DROP TRIGGER IF EXISTS trigger_verrou_creation_sv ON SessionVente;

CREATE OR REPLACE FUNCTION verrouiller_modification_sv()
RETURNS TRIGGER AS $$
BEGIN
    IF coalesce(current_setting('myapp.allow_modify_sv', true), 'off') IS DISTINCT FROM 'on' THEN
        RAISE EXCEPTION 'Modification de la sv interdite hors trigger/fonction autorisé.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verrou_modification_sv
BEFORE UPDATE ON SessionVente
FOR EACH ROW
EXECUTE FUNCTION verrouiller_modification_sv();


CREATE OR REPLACE FUNCTION verrouiller_creation_sv()
RETURNS TRIGGER AS $$
BEGIN
    IF coalesce(current_setting('myapp.allow_create_sv', true), 'off') IS DISTINCT FROM 'on' THEN
        RAISE EXCEPTION 'Création de la sv interdite hors trigger/fonction autorisé.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verrou_creation_sv
BEFORE INSERT ON SessionVente
FOR EACH ROW
EXECUTE FUNCTION verrouiller_creation_sv();





-- Automatise l'attibution de l'id se session aux billets à vendre dans cette session
CREATE OR REPLACE FUNCTION verifier_et_attribuer_session_vente()
RETURNS TRIGGER AS $$
DECLARE
    nb_billets_disponibles INT;
BEGIN
    -- Compter les billets disponibles pour cet événement, cette date et ce lieu
    SELECT COUNT(*) INTO nb_billets_disponibles
    FROM Billet b
    JOIN Siege s ON b.idSiege = s.idSiege
    JOIN CategorieSiege c ON s.idCategorie = c.idCategorie
    WHERE b.statutBillet = 'en vente'
      AND b.idEvent = NEW.idEvent
      AND b.idSession IS NULL
      AND c.idLieu = NEW.idLieu;

    -- Vérifier qu'on a assez de billets pour la session et maj de l'idSession des billets choisis
    IF nb_billets_disponibles >= NEW.nbBilletsMisEnVente THEN
        WITH billets_a_mettre_a_jour AS (
            SELECT b.idBillet
            FROM Billet b
            JOIN Siege s ON b.idSiege = s.idSiege
            JOIN CategorieSiege c ON s.idCategorie = c.idCategorie
            WHERE b.statutBillet = 'en vente'
              AND b.idEvent = NEW.idEvent
              AND b.idSession IS NULL
              AND c.idLieu = NEW.idLieu
            LIMIT NEW.nbBilletsMisEnVente
        )
        UPDATE Billet
        SET idSession = NEW.idSession
        WHERE idBillet IN (SELECT idBillet FROM billets_a_mettre_a_jour);
    ELSE
        RAISE EXCEPTION 'Pas assez de billets disponibles pour l''événement % au lieu %', NEW.idEvent, NEW.idLieu;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_verifier_et_attribuer_session
AFTER INSERT ON SessionVente
FOR EACH ROW
EXECUTE FUNCTION verifier_et_attribuer_session_vente();

-- Automatiser la suppression de idsession de la session annulée
-- est pas forcément utile car on a un on delete set null ds la table Billet
CREATE OR REPLACE FUNCTION nettoyer_billets_session_annulee()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Billet
    SET idSession = NULL
    WHERE idSession = OLD.idSession;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_nettoyer_billets_apres_annulation
AFTER DELETE ON SessionVente
FOR EACH ROW
EXECUTE FUNCTION nettoyer_billets_session_annulee();


CREATE OR REPLACE FUNCTION creer_file_attente()
RETURNS TRIGGER AS $$
DECLARE
    id_new_file INT;
BEGIN
    INSERT INTO FileAttente (capaciteQueue, idSessionVente)
    VALUES (LEAST(NEW.nbBilletsMisEnVente*2, 1000), NEW.idSession) -- 100 peut être une valeur par défaut ou à adapter
    RETURNING idQueue INTO id_new_file;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_creer_file_attente
AFTER INSERT ON SessionVente
FOR EACH ROW
EXECUTE FUNCTION creer_file_attente();
