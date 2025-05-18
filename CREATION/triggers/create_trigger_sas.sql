DROP TRIGGER IF EXISTS trg_annuler_pre_resa_if_sas_expelled ON SAS;
DROP TRIGGER IF EXISTS trigger_creer_panier_prereservation ON SAS;

DROP TRIGGER IF EXISTS trigger_verrou_modification_sas ON SAS;
DROP TRIGGER IF EXISTS trigger_verrou_creation_sas ON SAS;

CREATE OR REPLACE FUNCTION verrouiller_modification_sas()
RETURNS TRIGGER AS $$
BEGIN
    IF coalesce(current_setting('myapp.allow_modify_sas', true), 'off') IS DISTINCT FROM 'on' THEN
        RAISE EXCEPTION 'Modification du sas interdite hors trigger/fonction autorisé.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verrou_modification_sas
BEFORE UPDATE ON SAS
FOR EACH ROW
EXECUTE FUNCTION verrouiller_modification_sas();


CREATE OR REPLACE FUNCTION verrouiller_creation_sas()
RETURNS TRIGGER AS $$
BEGIN

    IF coalesce(current_setting('myapp.allow_create_sas', true), 'off') IS DISTINCT FROM 'on' THEN
        RAISE EXCEPTION 'Création du sas interdite hors trigger/fonction autorisé.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verrou_creation_sas
BEFORE INSERT ON SAS
FOR EACH ROW
EXECUTE FUNCTION verrouiller_creation_sas();



-- Fonction trigger qui annule la pré‑réservation (supprime la ligne dans PreReservation)
-- lorsque l'utilisateur est expulse du SAS.
CREATE OR REPLACE FUNCTION annuler_pre_reservation_if_user_lost_SAS()
RETURNS TRIGGER AS $$
DECLARE
    v_session INT;
BEGIN
        -- Récupérer la session de vente associée à la file (FileAttente)
        SELECT idSessionVente
          INTO v_session
          FROM FileAttente
          WHERE idQueue = NEW.idQueue;

        -- Supprimer la pré‑réservation correspondante pour cet utilisateur dans cette session
        DELETE FROM PreReservation
        WHERE idUser = NEW.idUser
        AND idSession = v_session;

        RAISE NOTICE 'La pré‑réservation de l utilisateur % pour la session % a été annulée (utilisateur expulsé du SAS).',
                     NEW.idUser, v_session;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger sur la table SAS qui s'exécute après la mise à jour du champ statusSAS.
-- dès qu'un utilisateur est explusé du sas.
CREATE TRIGGER trigger_annuler_pre_resa_if_sas_expelled
AFTER UPDATE OF statusSAS ON SAS
FOR EACH ROW
WHEN (OLD.statusSAS = 'en cours' AND NEW.statusSAS = 'expulse')
EXECUTE FUNCTION annuler_pre_reservation_if_user_lost_SAS();


CREATE OR REPLACE FUNCTION creer_prereservation()
RETURNS TRIGGER AS $$
DECLARE
    v_idSession INTEGER;
BEGIN
    -- Récupérer la session associée à la file d'attente
    SELECT idSessionVente
    INTO v_idSession
    FROM FileAttente
    WHERE idQueue = NEW.idQueue;

    -- Insérer le nouveau panier
    PERFORM set_config('myapp.allow_create_prereserv', 'on', true);
    INSERT INTO PreReservation (idUser, idSession)
    VALUES (NEW.idUser, v_idSession);
    PERFORM set_config('myapp.allow_create_prereserv', 'off', true);

    -- Notifier l'utilisateur
    PERFORM informerUtilisateurOptionsAchat(NEW.idUser, v_idSession);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_creer_panier_prereservation
AFTER INSERT ON SAS
FOR EACH ROW
EXECUTE FUNCTION creer_prereservation();
