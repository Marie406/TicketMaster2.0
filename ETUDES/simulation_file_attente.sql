DROP FUNCTION entrerfileattente(integer,text);

--corriger fct entrerFileAttente car marche pas comme il faut (trouve pas de sessions actives alors qu'il y en a)
--à voir si il faut remettre comme avant la clé primaire de AvoirLieu sans idLieu
-- et s'il vaut mieux pas mettre sessionVente en lien avec avoirLieu sur le diag

CREATE OR REPLACE FUNCTION entrerFileAttente(idUtilisateur INT, descriptionEvent_donnee TEXT)
RETURNS VOID AS $$
DECLARE
    id_event_var INT;
    idFile INT;
    capacite INT;
    rang_max INT;
    debut TIMESTAMP;
    fin TIMESTAMP;
BEGIN

    IF idUtilisateur is NULL THEN
        RAISE NOTICE 'Utilisateur avec email "%" introuvable.', emailUser;
        RETURN;
    END IF;

    -- Chercher l'idEvent à partir de la description de l'événement
    SELECT idEvent INTO id_event_var
    FROM Concert
    WHERE descriptionEvent = descriptionEvent_donnee;

    IF NOT FOUND THEN
        RAISE NOTICE 'evenement avec la description "%" introuvable.', descriptionEvent_donnee;
        RETURN;
    END IF;

    -- Chercher la session active correspondant à cet idEvent
    SELECT f.idQueue, f.capaciteQueue, s.dateDebutSession, s.dateFinSession
    INTO idFile, capacite, debut, fin
    FROM FileAttente f
    JOIN SessionVente s ON f.idSessionVente = s.idSession
    WHERE s.idEvent = id_event_var
    AND now() BETWEEN s.dateDebutSession AND s.dateFinSession;

    -- Vérifier si une session active a été trouvée
    IF NOT FOUND THEN
        RAISE NOTICE 'Aucune session active trouvée pour l''événement "%".', descriptionEvent_donnee;
        RETURN;
    END IF;

    -- Vérifier si l'utilisateur est déjà dans la file d'attente
    IF EXISTS (
        SELECT 1 FROM Attendre
        WHERE idQueue = idFile AND idUser = idUtilisateur
    ) THEN
        RAISE NOTICE 'Utilisateur déjà dans la file.';
        RETURN;
    END IF;

    -- Vérifier si la période de la session est valide
    IF now() < debut OR now() > fin THEN
        RAISE NOTICE 'Impossible d''entrer dans la file : période invalide (% - %)', debut, fin;
        RETURN;
    END IF;

    -- Récupérer le rang max actuel dans la file d'attente
    SELECT COALESCE(MAX(rang), 0) INTO rang_max
    FROM Attendre
    WHERE idQueue = idFile;

    -- Vérifier si la file est pleine
    IF rang_max >= capacite THEN
        RAISE NOTICE 'La file d''attente est pleine (% / %)', rang_max, capacite;
        RETURN;
    END IF;

    -- Ajouter l'utilisateur dans la file d'attente
    INSERT INTO Attendre(idQueue, idUser, rang)
    VALUES (idFile, idUtilisateur, rang_max + 1);

    RAISE NOTICE 'Utilisateur ajouté à la file d''attente pour l''événement "%".', descriptionEvent_donnee;
END;
$$ LANGUAGE plpgsql;



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
SELECT entrerFileAttente(15, 'Tournee mondiale de Stray Kids');

--test avec file attente fermée
--SELECT entrerFileAttente(1, 'Tournee japonaise de Taemin');

--test avec evenement introuvable -> file attente inexistante