DROP TRIGGER IF EXISTS trigger_verrou_modifications_categorie ON CategorieSiege;

CREATE OR REPLACE FUNCTION verrouiller_modifications_categorie()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.idCategorie IS DISTINCT FROM OLD.idCategorie THEN
        RAISE EXCEPTION 'Modification de idCategorie est interdite.';
    END IF;

    IF NEW.nomCategorie IS DISTINCT FROM OLD.nomCategorie THEN
        RAISE EXCEPTION 'Modification de nomCategorie est interdite';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verrou_modifications_categorie
BEFORE UPDATE ON CategorieSiege
FOR EACH ROW
EXECUTE FUNCTION verrouiller_modifications_categorie();
