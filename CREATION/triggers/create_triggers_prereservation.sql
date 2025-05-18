DROP TRIGGER IF EXISTS trigger_remettre_billets_en_vente ON PreReservation;

--CREATE OR REPLACE FUNCTION remettre_billets_en_vente()
DROP TRIGGER IF EXISTS trigger_Prereservations_en_vente ON PreReservation;
DROP TRIGGER IF EXISTS trigger_verrou_modification_prereservation ON PreReservation;
DROP TRIGGER IF EXISTS trigger_verrou_creation_prereservation ON PreReservation;

CREATE OR REPLACE FUNCTION remettre_billets_en_vente()
RETURNS TRIGGER AS $$
BEGIN
        PERFORM set_config('myapp.allow_status_change', 'on', true);
        PERFORM set_config('myapp.allow_idpanier_change', 'on', true);
        UPDATE Billet
        SET statutBillet = 'en vente',
            idPanier = NULL
        WHERE idPanier = OLD.idPanier;
        PERFORM set_config('myapp.allow_status_change', 'off', true);
        PERFORM set_config('myapp.allow_idpanier_change', 'off', true);

        RAISE NOTICE 'Prereservations associés au panier % remis en vente.', OLD.idPanier;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_remettre_billets_en_vente
AFTER DELETE ON PreReservation
FOR EACH ROW
EXECUTE FUNCTION remettre_Prereservations_en_vente();



CREATE OR REPLACE FUNCTION verrouiller_modification_prereservation()
RETURNS TRIGGER AS $$
BEGIN
    IF coalesce(current_setting('myapp.allow_modify_prereserv', true), 'off') IS DISTINCT FROM 'on' THEN
        RAISE EXCEPTION 'Modification de prereservation interdite hors trigger/fonction autorisé.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verrou_modification_prereservation
BEFORE UPDATE ON PreReservation
FOR EACH ROW
EXECUTE FUNCTION verrouiller_modification_prereservation();


CREATE OR REPLACE FUNCTION verrouiller_creation_prereservation()
RETURNS TRIGGER AS $$
BEGIN
    IF coalesce(current_setting('myapp.allow_create_prereserv', true), 'off') IS DISTINCT FROM 'on' THEN
        RAISE EXCEPTION 'Création de prereservation interdite hors trigger/fonction autorisé.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verrou_creation_prereservation
BEFORE INSERT ON PreReservation
FOR EACH ROW
EXECUTE FUNCTION verrouiller_creation_prereservation();
