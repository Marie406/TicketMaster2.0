DROP TRIGGER IF EXISTS trigger_verrou_modification_file ON FileAttente;
DROP TRIGGER IF EXISTS trigger_verrou_creation_file ON FileAttente;

CREATE OR REPLACE FUNCTION verrouiller_modification_file()
RETURNS TRIGGER AS $$
BEGIN
    IF coalesce(current_setting('myapp.allow_modify_file', true), 'off') IS DISTINCT FROM 'on' THEN
        RAISE EXCEPTION 'Modification de la file interdite hors trigger/fonction autorisé.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verrou_modification_file
BEFORE UPDATE ON FileAttente
FOR EACH ROW
EXECUTE FUNCTION verrouiller_modification_file();


CREATE OR REPLACE FUNCTION verrouiller_creation_file()
RETURNS TRIGGER AS $$
BEGIN
    IF coalesce(current_setting('myapp.allow_create_file', true), 'off') IS DISTINCT FROM 'on' THEN
        RAISE EXCEPTION 'Création de la file interdite hors trigger/fonction autorisé.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verrou_creation_file
BEFORE INSERT ON FileAttente
FOR EACH ROW
EXECUTE FUNCTION verrouiller_creation_file();
