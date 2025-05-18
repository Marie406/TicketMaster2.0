DROP TRIGGER IF EXISTS trigger_billets_en_vente ON PreReservation;

CREATE OR REPLACE FUNCTION remettre_billets_en_vente()
RETURNS TRIGGER AS $$
BEGIN
        UPDATE Billet
        SET statutBillet = 'en vente',
            idPanier = NULL
        WHERE idPanier = OLD.idPanier;

        RAISE NOTICE 'Billets associés au panier % remis en vente.', OLD.idPanier;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_billets_en_vente
AFTER DELETE ON PreReservation
FOR EACH ROW
EXECUTE FUNCTION remettre_billets_en_vente();