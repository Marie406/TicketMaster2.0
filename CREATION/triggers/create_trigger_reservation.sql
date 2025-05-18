CREATE OR REPLACE FUNCTION creer_reservations_depuis_transac()
RETURNS TRIGGER AS $$
DECLARE
    billet RECORD;
BEGIN
    IF OLD.statutTransaction = 'en attente' AND NEW.statutTransaction = 'validé' THEN
        SELECT idUser FROM Transac t
        WHERE t.idTransac = NEW.idTransac;
        -- Insérer une réservation liée à la transaction
        INSERT INTO Reservation(dateReservation, idUser, idTransac)
        VALUES (NOW(), idUser, NEW.idTransac);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_creer_reservations_apres_validation
AFTER UPDATE OF statutTransaction ON Transac
FOR EACH ROW
WHEN (OLD.statutTransaction IS DISTINCT FROM NEW.statutTransaction AND NEW.statutTransaction = 'validé')
EXECUTE FUNCTION creer_reservations_depuis_transac();

--ajouter trigger pour que tt les billets de la transaction soient mis à 'vendu'

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


CREATE TRIGGER trigger_billets_vendus
AFTER UPDATE OF statutTransaction ON Transac
FOR EACH ROW
EXECUTE FUNCTION marquer_billets_vendus();

