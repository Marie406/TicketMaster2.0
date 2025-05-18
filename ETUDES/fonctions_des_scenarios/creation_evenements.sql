--1. fonction pour ajouter l'artiste qui va participer à l'evenement
CREATE OR REPLACE FUNCTION ajouter_artiste(nom VARCHAR, style VARCHAR)
RETURNS INT AS $$
DECLARE
    id INT;
BEGIN
    SELECT idArtiste INTO id FROM Artiste WHERE nomArtiste = nom;
    IF NOT FOUND THEN
        INSERT INTO Artiste (nomArtiste, styleMusique)
        VALUES (nom, style)
        RETURNING idArtiste INTO id;
    END IF;
    RETURN id;
END;
$$ LANGUAGE plpgsql;


-- fonction pour créer le concert et ajouter un artiste si inexistant ds bdd
CREATE OR REPLACE FUNCTION creer_evenement(
    descriptionEvent TEXT,
    nom_artistes TEXT[],
    niveauDemandeAttendu NUMERIC(3,2)
) RETURNS INT AS $$
DECLARE
    id_event INT;
    id_artiste INT;
    nom TEXT;
BEGIN
    -- Créer le concert
    INSERT INTO Concert(descriptionEvent, niveauDemandeAttendu)
    VALUES (descriptionEvent, niveauDemandeAttendu)
    RETURNING idEvent INTO id_event;

    -- Boucle sur chaque artiste
    FOREACH nom IN ARRAY nom_artistes
    LOOP
        -- Vérifie si l'artiste existe déjà
        SELECT idArtiste INTO id_artiste
        FROM Artiste
        WHERE nomArtiste = nom;

        -- Si l'artiste n'existe pas, on le crée
        IF NOT FOUND THEN
            INSERT INTO Artiste(nomArtiste, styleMusique)
            VALUES (nom, NULL)
            RETURNING idArtiste INTO id_artiste;
        END IF;

        -- Ajouter la relation dans Participe
        INSERT INTO Participe(idEvent, idArtiste)
        VALUES (id_event, id_artiste);
    END LOOP;

    -- Retourner l'id du concert créé
    RETURN id_event;
END;
$$ LANGUAGE plpgsql;

