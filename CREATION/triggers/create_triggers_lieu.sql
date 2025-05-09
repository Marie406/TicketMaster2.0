DROP TRIGGER IF EXISTS trigger_verrou_modifications_lieu ON Lieu;

CREATE OR REPLACE FUNCTION verrouiller_modifications_lieu()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.idLieu IS DISTINCT FROM OLD.idLieu THEN
        RAISE EXCEPTION 'Modification de idLieu est interdite.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verrou_modifications_lieu
BEFORE UPDATE ON Lieu
FOR EACH ROW
EXECUTE FUNCTION verrouiller_modifications_lieu();
