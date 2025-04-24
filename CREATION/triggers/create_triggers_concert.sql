DROP TRIGGER IF EXISTS trigger_verrou_modifications_concert ON Concert;

CREATE OR REPLACE FUNCTION verrouiller_modifications_concert()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.idEvent IS DISTINCT FROM OLD.idEvent THEN
        RAISE EXCEPTION 'Modification de idEvent est interdite.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verrou_modifications_concert
BEFORE UPDATE ON Concert
FOR EACH ROW
EXECUTE FUNCTION verrouiller_modifications_concert();
