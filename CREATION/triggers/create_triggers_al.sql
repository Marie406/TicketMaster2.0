DROP TRIGGER IF EXISTS trigger_verifier_horaire_al ON AvoirLieu;
DROP TRIGGER IF EXISTS trigger_set_grille ON AvoirLieu;
DROP TRIGGER IF EXISTS trigger_supprimer_dans_grille ON AvoirLieu;

-- Eviter les doublons d'horaires sur le même lieu
CREATE OR REPLACE FUNCTION verifier_horaire_al()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM AvoirLieu
        WHERE dateEvent = NEW.dateEvent
        AND idLieu = NEW.idLieu
        AND heure = NEW.heure
    ) THEN
        RAISE EXCEPTION 'Un concert est déjà prévu à cette date, heure et lieu.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verifier_horaire_al
BEFORE INSERT ON AvoirLieu
FOR EACH ROW
EXECUTE FUNCTION verifier_horaire_al();

--fct qui calcule et ajoute les prix dans la table Grille
--les prix des cat sont par défaut et multipliés par un coef propre à l'evenement
--ds la réalité les prix dépendent aussi des taxes que le lieu applique
CREATE OR REPLACE FUNCTION setGrillePrix()
RETURNS TRIGGER AS $$
BEGIN
    -- avec cette fonction toutes les mêmes catégories de tous les lieux ont les mêmes prix
    INSERT INTO Grille (idEvent, idCategorie, prix)
    SELECT
        NEW.idEvent,
        cs.idCategorie,
        ROUND(
            CASE cs.nomCategorie
                WHEN 'CAT_1' THEN 80.00
                WHEN 'CAT_2' THEN 70.00
                WHEN 'CAT_3' THEN 60.00
                WHEN 'CAT_4' THEN 50.00
                WHEN 'CAT_5' THEN 40.00
                ELSE 60.00  -- par défaut, si jamais un nom n'est pas prévu
            END * c.niveauDemandeAttendu, 2
        ) AS prix
    FROM CategorieSiege cs
    JOIN Concert c ON c.idEvent = NEW.idEvent
    WHERE cs.idLieu = NEW.idLieu;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_grille
AFTER INSERT ON AvoirLieu
FOR EACH ROW
EXECUTE FUNCTION setGrillePrix();

-- Supression automatique dans la grille si le concert n'a plus Lieu
CREATE OR REPLACE FUNCTION supprimer_dans_grille()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM Grille WHERE idEvent = OLD.idEvent;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_supprimer_dans_grille
AFTER DELETE ON AvoirLieu
FOR EACH ROW
EXECUTE FUNCTION supprimer_dans_grille();
