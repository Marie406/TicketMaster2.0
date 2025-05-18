DROP TRIGGER IF EXISTS trg_annuler_pre_resa_if_sas_expelled ON SAS;

-- Fonction trigger qui annule la pré‑réservation (supprime la ligne dans PreReservation)
-- lorsque l'utilisateur quitte le SAS.
CREATE OR REPLACE FUNCTION annuler_pre_reservation_if_user_lost_SAS()
RETURNS TRIGGER AS $$
DECLARE
    v_session INT;
BEGIN
    -- Vérifier que le statut passe bien de 'en cours' à 'expulse'
    --IF OLD.statusSAS = 'en cours' AND NEW.statusSAS = 'expulse' THEN
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
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger sur la table SAS qui s'exécute après la mise à jour du champ statusSAS.
-- dès qu'un utilisateur est explusé du sas.
CREATE TRIGGER trg_annuler_pre_resa_if_sas_expelled
AFTER UPDATE OF statusSAS ON SAS
FOR EACH ROW
WHEN (OLD.statusSAS = 'en cours' AND NEW.statusSAS = 'expulse')
EXECUTE FUNCTION annuler_pre_reservation_if_user_lost_SAS();
