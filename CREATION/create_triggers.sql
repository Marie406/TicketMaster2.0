
DROP TRIGGER IF EXISTS trg_check_rang ON Attendre;
DROP TRIGGER IF EXISTS trigger_set_grille ON AvoirLieu;
DROP TRIGGER IF EXISTS trigger_genererBillets ON Grille;
--DROP TRIGGER IF EXISTS trigger_creer_file_attente ON SessionVente;

CREATE OR REPLACE FUNCTION check_rang_valid() RETURNS TRIGGER AS $$
DECLARE
    max_capacity INT;
BEGIN
    SELECT capaciteQueue INTO max_capacity FROM FileAttente WHERE idQueue = NEW.idQueue;

    IF NEW.rang < 0 OR NEW.rang >= max_capacity THEN
        RAISE EXCEPTION 'Le rang % est invalide. Il doit etre entre 0 et %', NEW.rang, max_capacity - 1;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création du trigger pour vérifier le rang
CREATE TRIGGER trg_check_rang
BEFORE INSERT OR UPDATE ON Attendre
FOR EACH ROW
EXECUTE FUNCTION check_rang_valid();


--fct qui calcule et ajoute les prix dans la table Grille
--les prix des cat sont par défaut et multipliés par un coef propre à l'evenement
--ds la réalité les prix dépendent aussi des taxes que le lieu applique
CREATE OR REPLACE FUNCTION setGrillePrix()
RETURNS TRIGGER AS $$
BEGIN
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


-- Le trigger suivant est pr l'instant remplacé par l'execution à plusieurs reprises de gestion_files.sql

--fonction pour l'ajout automatique d'une file attente ds--
-- la table fileAttente une fois qu'une sessionEvenement est créée--
/*
CREATE OR REPLACE FUNCTION creer_file_attente_apres_session()
RETURNS TRIGGER AS $$
DECLARE
    capacite_estimee INT;
BEGIN
    -- Calcul du nombre min de personnes nécessaires pour écouler les billets
    capacite_estimee := CEIL(NEW.nbBilletsMisEnVente::DECIMAL / NEW.nbMaxBilletsAchetesVIP);

    -- Appliquer un plafond ds la file attente à 2000
    -- au cas où capacitee_estimee est bcp trop grand 
    --et risquerait de faire crasher le serveur irl
    IF capacite_estimee > 2000 THEN
        capacite_estimee := 2000;
    END IF;

    INSERT INTO FileAttente (capaciteQueue, idSessionVente)
    VALUES (capacite_estimee, NEW.idSession);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_creer_file_attente
AFTER INSERT ON SessionVente
FOR EACH ROW
EXECUTE FUNCTION creer_file_attente_apres_session();
/*

