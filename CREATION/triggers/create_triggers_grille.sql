DROP TRIGGER IF EXISTS trigger_genererBillets ON Grille;

-- pour automatiser la création des billets
CREATE OR REPLACE FUNCTION genererBillets()
RETURNS TRIGGER AS $$
DECLARE
    siege_id INT;
    nb_billets INT;
    siege RECORD;
    date_ DATE;
    idLieu_ INT;
BEGIN
    -- Récupération de la capacité pour la catégorie concernée
    SELECT capaciteCategorie, idLieu INTO nb_billets, idLieu_
    FROM CategorieSiege
    WHERE idCategorie = NEW.idCategorie;

    -- Boucle sur toutes les dates de l’événement dans ce lieu
    FOR date_ IN
        SELECT dateEvent
        FROM AvoirLieu
        WHERE idEvent = NEW.idEvent
        AND idLieu = idLieu_
    LOOP
        -- Sélection des sièges disponibles pour cette catégorie
        FOR siege IN
            SELECT s.idSiege
            FROM Siege s
            WHERE s.idCategorie = NEW.idCategorie
            AND NOT EXISTS (
                SELECT 1 FROM Billet b
                WHERE b.idSiege = s.idSiege
                AND b.idEvent = NEW.idEvent
                AND b.dateEvent = date_
            )
            LIMIT nb_billets
            
        LOOP
            -- Insertion des billets avec la bonne date
            INSERT INTO Billet (
                statutBillet, prix, idSiege, dateEvent, idEvent, idPanier, idSession
            ) VALUES (
                'en vente', NEW.prix, siege.idSiege, date_, NEW.idEvent, NULL, NULL
            );
        END LOOP;
    END LOOP;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- on fait un seul trigger pour éviter des problèmes de concurrence sur la même table
CREATE TRIGGER trigger_genererBillets
AFTER INSERT ON Grille
FOR EACH ROW
EXECUTE FUNCTION genererBillets();
