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


--organisation des concerts avec date, lieu et heure
SELECT organiser_concert('Tournee japonaise de Taemin', DATE '2025-07-12', 17, TIME '19:30');
SELECT organiser_concert('Tournee japonaise de Taemin', DATE '2025-07-19', 18, TIME '20:30');
SELECT organiser_concert('Tournee japonaise de Taemin', DATE '2025-07-22', 16, TIME '20:00');
SELECT organiser_concert('Concert en France de Stray Kids', DATE '2025-07-22', 1, TIME '19:30');

--ajouter un trigger qui à chaque insertion dans AvoirLieu nous crée des billets en faisannt
-- dans la table Categorie on somme toutes les capacitesCategorie telles que la foreignKey idLieu correspond à celle qui est dans AvoirLieu
-- ce nb sera la nb de billet mis en vente
-- pour chaque idCategorie et idEvent on devrait definir une grille de prix, ce prix on le garde car on doit créer 
--capaciteCategorie nb de billets avec ce prix et on associe chacun de ces billets à un siege de la dite categorie


