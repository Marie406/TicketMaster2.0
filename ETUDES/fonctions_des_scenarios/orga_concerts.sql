--fct qui remplit la table Calendrier si nécéssaire et qui remplit la table AvoirLieu
CREATE OR REPLACE FUNCTION organiser_concert(
    description TEXT,
    date_event DATE,
    id_lieu INT,
    heure TIME
) RETURNS VOID AS $$
DECLARE
    id_event INT;
BEGIN
    -- 1. Récupérer l'id du concert
    SELECT idEvent INTO id_event
    FROM Concert
    WHERE descriptionEvent = description;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Concert avec description "%" introuvable.', description;
    END IF;

    -- 2. Ajouter la date dans le calendrier si elle n'existe pas
    INSERT INTO Calendrier(dateEvent)
    SELECT date_event
    WHERE NOT EXISTS (
        SELECT 1 FROM Calendrier WHERE dateEvent = date_event
    );

    -- 3. Vérifier que le lieu existe (facultatif, sinon laisser la FK gérer)
    IF NOT EXISTS (
        SELECT 1 FROM Lieu WHERE idLieu = id_lieu
    ) THEN
        RAISE EXCEPTION 'Lieu avec id % introuvable.', id_lieu;
    END IF;

    -- 4. Ajouter dans AvoirLieu
    INSERT INTO AvoirLieu(dateEvent, idEvent, idLieu, heure)
    VALUES (date_event, id_event, id_lieu, heure);
END;
$$ LANGUAGE plpgsql;



