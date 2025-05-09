DROP TRIGGER IF EXISTS trigger_creer_file_attente ON SessionVente;

CREATE OR REPLACE FUNCTION creer_file_attente()
RETURNS TRIGGER AS $$
DECLARE
    id_new_file INT;
BEGIN
    INSERT INTO FileAttente (capaciteQueue, idSessionVente)
    VALUES (LEAST(NEW.nbBilletsMisEnVente*2, 1000), NEW.idSession) -- 100 peut être une valeur par défaut ou à adapter
    RETURNING idQueue INTO id_new_file;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_creer_file_attente
AFTER INSERT ON SessionVente
FOR EACH ROW
EXECUTE FUNCTION creer_file_attente();
