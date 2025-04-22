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

--2. ajout des artistes pour l'evenement
SELECT ajouter_artiste('Taemin', 'Kpop');
SELECT ajouter_artiste('GOT7', 'Kpop');

--3. fonction pour créer le concert et ajouter un artiste si inexistant ds bdd
--maj de la table PARTICIPE
CREATE OR REPLACE FUNCTION creer_evenement(
    description TEXT,
    nom_artistes TEXT[]
) RETURNS INT AS $$
DECLARE
    id_event INT;
    id_artiste INT;
    nom TEXT;
BEGIN
    -- Créer le concert
    INSERT INTO Concert(descriptionEvent)
    VALUES (description)
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


--4. creer le concert
--cet échantillon permet de vérifier que Stray Kids n'est pas ajouté qd il a déjà été créer 
--via les donnees du csv , que BewhY est bien crée et que les ajouts
-- d'artistes de la fct ajouter_artiste fonctionnent 
-- permet aussi de verif qu'on peut bien ajouter plusieurs artistes à un concert -> regarder table Participe
SELECT creer_evenement('Concert evenement BewhY', ARRAY['BewhY']);
SELECT creer_evenement('Tournee japonaise de Taemin', ARRAY['Taemin']);
SELECT creer_evenement('Promotion nouveau single de GOT7', ARRAY['GOT7']);
SELECT creer_evenement('Concert en France de Stray Kids', ARRAY['Stray Kids']);
SELECT creer_evenement('Gala des Pieces jaunes 2026', ARRAY['GDragon', 'GOT7', 'Stray Kids', 'BewhY']);
