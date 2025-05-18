DROP TRIGGER IF EXISTS trigger_creer_reservations_apres_validation ON Transac;
DROP TRIGGER IF EXISTS trigger_billets_vendus ON Transac;
--DROP TRIGGER IF EXISTS trigger_supprimer_prereservation ON Transac;


CREATE OR REPLACE FUNCTION calculer_reduction(idPanierInput INT)
RETURNS NUMERIC(5,2) AS $$
DECLARE
    points_fidelite INT;
    reduction_percent NUMERIC(5,2) := 0;
BEGIN
    -- Récupérer les points de fidélité de l'utilisateur associé au panier
    SELECT u.ptsFidelite INTO points_fidelite
    FROM Utilisateur u
    JOIN PreReservation p ON p.idUser = u.idUser
    WHERE p.idPanier = idPanierInput;

    -- Appliquer la réduction en fonction des points de fidélité
    IF points_fidelite >= 300 THEN
        reduction_percent := 0.30;  -- 30% de réduction
    ELSIF points_fidelite >= 200 THEN
        reduction_percent := 0.20;  -- 20% de réduction
    ELSIF points_fidelite >= 100 THEN
        reduction_percent := 0.10;  -- 10% de réduction
    ELSE
        reduction_percent := 0.00;  -- Pas de réduction
    END IF;

    RETURN reduction_percent;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION creer_transaction_avec_montant_calcule(idPanierInput INTEGER)
RETURNS VOID AS $$
DECLARE
    total NUMERIC(10,2) := 0;
    reduction_percent NUMERIC(5,2) := 0;
    reduction NUMERIC(10,2) := 0;
    prix_billet NUMERIC(10,2);
BEGIN
    -- Calcul du montant total brut du panier
    FOR prix_billet IN
        SELECT prix
        FROM Billet
        WHERE idPanier = idPanierInput
    LOOP
        total := total + prix_billet;
    END LOOP;

    -- Appliquer une réduction si applicable
    reduction_percent := calculer_reduction(idPanierInput);
    reduction := total * reduction_percent;
    total := total - reduction;

    -- Insérer la transaction avec le montant calculé
    INSERT INTO Transac(montant, statutTransaction, idPanier)
    VALUES (total, 'en attente', idPanierInput);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION creer_reservations_depuis_transac()
RETURNS TRIGGER AS $$
DECLARE
    user_id INT;
BEGIN
    IF OLD.statutTransaction = 'en attente' AND NEW.statutTransaction = 'validé' THEN

        -- Récupérer l'idUser à partir du panier lié à la transaction
        SELECT idUser INTO user_id
        FROM PreReservation
        WHERE idPanier = NEW.idPanier;

        IF user_id IS NULL THEN
            RAISE NOTICE 'Aucun utilisateur trouvé pour le panier %', NEW.idPanier;
            RETURN NEW;
        END IF;

        -- Insérer une réservation liée à la transaction
        INSERT INTO Reservation(dateReservation, idUser, idTransaction)
        VALUES (NOW(), user_id, NEW.idTransaction);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION marquer_billets_vendus()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.statutTransaction = 'en attente' AND NEW.statutTransaction = 'validé' THEN
        UPDATE Billet
        SET statutBillet = 'vendu'
        WHERE idPanier = NEW.idPanier;

        RAISE NOTICE 'Billets associés au panier % marqués comme vendus.', NEW.idPanier;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/*CREATE OR REPLACE FUNCTION supprimer_prereservation_si_transaction_validee()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifie si le statut est passé de 'en attente' à 'validé'
    IF OLD.statutTransaction = 'en attente' AND NEW.statutTransaction = 'validé' THEN
        DELETE FROM PreReservation
        WHERE idPanier = NEW.idPanier;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;*/

CREATE TRIGGER trigger_creer_reservations_apres_validation
AFTER UPDATE OF statutTransaction ON Transac
FOR EACH ROW
WHEN (OLD.statutTransaction IS DISTINCT FROM NEW.statutTransaction AND NEW.statutTransaction = 'validé')
EXECUTE FUNCTION creer_reservations_depuis_transac();

CREATE TRIGGER trigger_billets_vendus
AFTER UPDATE OF statutTransaction ON Transac
FOR EACH ROW
WHEN (OLD.statutTransaction IS DISTINCT FROM NEW.statutTransaction AND NEW.statutTransaction = 'validé')
EXECUTE FUNCTION marquer_billets_vendus();

/*CREATE TRIGGER trigger_supprimer_prereservation
AFTER UPDATE OF statutTransaction ON Transac
FOR EACH ROW
WHEN (
    OLD.statutTransaction IS DISTINCT FROM NEW.statutTransaction
    AND NEW.statutTransaction = 'validé'
)
EXECUTE FUNCTION supprimer_prereservation_si_transaction_validee();*/
