-- Recherche de l'utilisateur, renvoie NULL si introuvable
CREATE OR REPLACE FUNCTION getUserIdByEmail(emailInput VARCHAR)
RETURNS INT AS $$
DECLARE
    userId INT;
BEGIN
    SELECT idUser INTO userId
    FROM Utilisateur
    WHERE email = emailInput;

    RETURN userId;
END;
$$ LANGUAGE plpgsql;

-- Renvoie NULL si aucun événement ne correspond
CREATE OR REPLACE FUNCTION getEventIdByDescription(descriptionInput TEXT)
RETURNS INT AS $$
DECLARE
    eventId INT;
BEGIN
    SELECT idEvent INTO eventId
    FROM Concert
    WHERE descriptionEvent = descriptionInput;

    RETURN eventId;  
END;
$$ LANGUAGE plpgsql;


-- 2. Traitement de l'entrée dans la file si idUser est fourni
CREATE OR REPLACE FUNCTION tryEnterQueue(idUtilisateur INT, id_event_var INT)
RETURNS VOID AS $$
DECLARE
    idFile INT;
    capacite INT;
    rang_max INT;
    debut TIMESTAMP;
    fin TIMESTAMP;
BEGIN
    -- Chercher la session active correspondant à cet idEvent, sous-entend qu'il y en a au plus une
    SELECT f.idQueue, f.capaciteQueue, s.dateDebutSession, s.dateFinSession
    INTO idFile, capacite, debut, fin
    FROM FileAttente f
    JOIN SessionVente s ON f.idSessionVente = s.idSession
    WHERE s.idEvent = id_event_var
      AND now() BETWEEN s.dateDebutSession AND s.dateFinSession;

    IF NOT FOUND THEN
        RAISE NOTICE 'Aucune session active trouvée pour l''événement "%".', id_event_var;
        RETURN;
    END IF;

    -- Vérifier si l'utilisateur est déjà dans la file
    IF EXISTS (
        SELECT 1 FROM Attendre
        WHERE idQueue = idFile AND idUser = idUtilisateur
    ) THEN
        RAISE NOTICE 'Utilisateur déjà dans la file.';
        RETURN;
    END IF;

    -- Vérifier si période valide
    IF now() < debut OR now() > fin THEN
        RAISE NOTICE 'Période invalide (% - %)', debut, fin;
        RETURN;
    END IF;

    -- Calcul du rang max
    SELECT COALESCE(MAX(rang), 0) INTO rang_max
    FROM Attendre
    WHERE idQueue = idFile;

    IF rang_max >= capacite THEN
        RAISE NOTICE 'File pleine (% / %)', rang_max, capacite;
        RETURN;
    END IF;

    -- Insertion dans la file
    INSERT INTO Attendre(idQueue, idUser, rang)
    VALUES (idFile, idUtilisateur, rang_max + 1);

    RAISE NOTICE 'Utilisateur "%" ajouté à la file active de l''événement "%".', idUtilisateur, id_event_var;
END;
$$ LANGUAGE plpgsql;


-- 3. Fonction principale
CREATE OR REPLACE FUNCTION entrerFileAttente(emailUser VARCHAR, descriptionEvent_donnee TEXT)
RETURNS VOID AS $$
DECLARE
    idUtilisateur INT;
    id_event_var INT;
BEGIN
    idUtilisateur := getUserIdByEmail(emailUser);

    IF idUtilisateur IS NULL THEN
        RAISE NOTICE 'Utilisateur avec l''email % introuvable.', emailUser;
        RETURN;
    END IF;

    id_event_var := getEventIdByDescription(descriptionEvent_donnee);

    IF id_event_var IS NULL THEN
        RAISE NOTICE 'evenement avec la description "%" introuvable.', descriptionEvent_donnee;
        RETURN;
    END IF;

    PERFORM tryEnterQueue(idUtilisateur, id_event_var);
END;
$$ LANGUAGE plpgsql;



--un peu dangereux de modif ça, en tt cas faudrait que ça ejecte les gens si ils sont dans une file d'attente active de la session et qu'elle est modif
-- ou alors il faudrait empecher de modifier une session dont le debut est avant now
CREATE OR REPLACE FUNCTION modifier_session_vente(
    p_idSession INT,
    p_dateDebut TIMESTAMP,
    p_dateFin TIMESTAMP,
    p_nbBillets INT,
    p_onlyVIP BOOLEAN,
    p_maxVIP INT,
    p_maxRegular INT
)
RETURNS VOID AS $$
BEGIN
    UPDATE SessionVente
    SET dateDebutSession = p_dateDebut,
        dateFinSession = p_dateFin,
        nbBilletsMisEnVente = p_nbBillets,
        onlyVIP = p_onlyVIP,
        nbMaxBilletsAchetesVIP = p_maxVIP,
        nbMaxBilletsAchetesRegular = p_maxRegular
    WHERE idSession = p_idSession;
END;
$$ LANGUAGE plpgsql;


--test avec une file d'attente ouverte
SELECT modifier_session_vente(1, TIMESTAMP '2025-05-07 10:00:00', TIMESTAMP '2025-05-21 23:59:59', 800, FALSE, 6,4);
SELECT entrerFileAttente('daniel@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('hyunjin@email.com', 'Tournee mondiale de Stray Kids');
--SELECT * FROM FileAttente;
--SELECT * FROM Attendre;

--test qui verifie qu'un mm utilisateur peut pas entrer dans une file qu'il fait déja
SELECT entrerFileAttente('felix@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('felix@email.com', 'Tournee mondiale de Stray Kids');
--SELECT * FROM FileAttente;
--SELECT * FROM Attendre;

--test avec file attente fermée
SELECT entrerFileAttente('sehun@email.com', 'Concert de Billie Eilish');
--SELECT * FROM FileAttente;
--SELECT * FROM Attendre;

--test avec evenement introuvable -> file attente inexistante
SELECT entrerFileAttente('eunji@email.com', 'Epik High concert');
--SELECT * FROM FileAttente;
--SELECT * FROM Attendre;

--tester de remplir une file attente et d'ajouter des gens derriere