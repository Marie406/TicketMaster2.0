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


CREATE OR REPLACE FUNCTION mettre_a_jour_montant_transaction()
RETURNS TRIGGER AS $$
DECLARE
    total NUMERIC(10,2) := 0;
    points_fidelite INT;
    reduction_percent NUMERIC(5,2) := 0;
    reduction NUMERIC(10,2) := 0;
    prix_billet NUMERIC(10,2);
BEGIN
    -- Calculer le montant total du panier avant réduction
    FOR prix_billet IN
        SELECT prix
        FROM Billet
        WHERE idPanier = NEW.idPanier
    LOOP
        total := total + prix_billet;
    END LOOP;

    reduction_percent := calculer_reduction(NEW.idPanier);

    -- Calculer la réduction totale
    reduction := total * reduction_percent;

    -- Appliquer la réduction sur le montant total
    total := total - reduction;

    -- Mettre à jour la transaction correspondante avec le montant calculé
    UPDATE Transac
    SET montant = total
    WHERE idPanier = NEW.idPanier;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



CREATE TRIGGER trigger_mettre_a_jour_montant_transac
AFTER UPDATE OF idPanier ON Billet
FOR EACH ROW
WHEN (OLD.idPanier IS DISTINCT FROM NEW.idPanier AND NEW.idPanier IS NOT NULL)
EXECUTE FUNCTION mettre_a_jour_montant_transaction();
