DROP TRIGGER IF EXISTS trigger_verifier_et_attribuer_session ON SessionVente;

-- Automatise l'attibution de l'id se session aux billets à vendre dans cette session
CREATE OR REPLACE FUNCTION verifier_et_attribuer_session_vente()
RETURNS TRIGGER AS $$
DECLARE
    nb_billets_disponibles INT;
BEGIN
    -- Compter les billets disponibles pour CET événement et CETTE date
    SELECT COUNT(*) INTO nb_billets_disponibles
    FROM Billet
    WHERE statutBillet = 'en vente'
      AND idEvent = NEW.idEvent
      AND idLieu = NEW.idLieu
      AND idSession = NULL; -- que les billets qui ne sont pas encore attribués

    -- Vérifier qu'on a assez de billets pour la session et maj de l'idSession des billets choisis
    IF nb_billets_disponibles >= NEW.nbBilletsMisEnVente THEN
        WITH billets_a_mettre_a_jour AS (
            SELECT idBillet
            FROM Billet
            WHERE statutBillet = 'en vente'
              AND idEvent = NEW.idEvent
              AND dateEvent = NEW.dateEvent
            LIMIT NEW.nbBilletsMisEnVente
        )
        UPDATE Billet
        SET idSession = NEW.idSession
        WHERE idBillet IN (SELECT idBillet FROM billets_a_mettre_a_jour);
    ELSE
        RAISE EXCEPTION 'Pas assez de billets disponibles pour l''événement % à la date %', NEW.idEvent, NEW.dateEvent;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_verifier_et_attribuer_session
BEFORE INSERT ON SessionVente
FOR EACH ROW
EXECUTE FUNCTION verifier_et_attribuer_session_vente();

-- Automatiser la suppression de idsession de la session annulée
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
