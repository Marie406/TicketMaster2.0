DROP TRIGGER IF EXISTS trigger_verrou_modification_reservation ON Reservation;
DROP TRIGGER IF EXISTS trigger_verrou_creation_reservation ON Reservation;

CREATE OR REPLACE FUNCTION verrouiller_modification_reservation()
RETURNS TRIGGER AS $$
BEGIN
    IF coalesce(current_setting('myapp.allow_modify_reserv', true), 'off') IS DISTINCT FROM 'on' THEN
        RAISE EXCEPTION 'Modification de reservation interdite hors trigger/fonction autorisé.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verrou_modification_reservation
BEFORE UPDATE ON Reservation
FOR EACH ROW
EXECUTE FUNCTION verrouiller_modification_reservation();


CREATE OR REPLACE FUNCTION verrouiller_creation_reservation()
RETURNS TRIGGER AS $$
BEGIN

    IF coalesce(current_setting('myapp.allow_create_reserv', true), 'off') IS DISTINCT FROM 'on' THEN
        RAISE EXCEPTION 'Création de reservation interdite hors trigger/fonction autorisé.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verrou_creation_reservation
BEFORE INSERT ON Reservation
FOR EACH ROW
EXECUTE FUNCTION verrouiller_creation_reservation();
