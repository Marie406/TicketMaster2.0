DROP TRIGGER IF EXISTS trigger_verrou_modifications_concert ON Artiste;

CREATE OR REPLACE FUNCTION verrouiller_modifications_artiste()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.idArtiste IS DISTINCT FROM OLD.idArtiste THEN
        RAISE EXCEPTION 'Modification de idArtiste est interdite.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verrou_modifications_concert
BEFORE UPDATE ON Artiste
FOR EACH ROW
EXECUTE FUNCTION verrouiller_modifications_artiste();
