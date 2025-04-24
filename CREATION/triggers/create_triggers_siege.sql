DROP TRIGGER IF EXISTS trigger_verrou_modifications_siege ON Siege;

CREATE OR REPLACE FUNCTION verrouiller_modifications_siege()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.idSiege IS DISTINCT FROM OLD.idSiege THEN
        RAISE EXCEPTION 'Modification de idSiege est interdite.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verrou_modifications_siege
BEFORE UPDATE ON Concert
FOR EACH ROW
EXECUTE FUNCTION verrouiller_modifications_siege();
