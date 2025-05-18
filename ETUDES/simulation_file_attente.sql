--  Traitement de l'entrée dans la file si idUser est fourni
CREATE OR REPLACE FUNCTION tryEnterQueue(idUtilisateur INT, id_event_var INT)
RETURNS VOID AS $$
DECLARE
    idFile INT;
    capacite INT;
    rang_max INT;
    debut TIMESTAMP;
    fin TIMESTAMP;
BEGIN
    -- Utilisation de la fonction pour obtenir la file active
    BEGIN
        idFile := get_active_queue_for_event(id_event_var);
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Aucune session active trouvée pour l''événement "%".', id_event_var;
        RETURN;
    END;

    -- Récupération de la capacité et de la période de la session
    SELECT f.capaciteQueue, s.dateDebutSession, s.dateFinSession
    INTO capacite, debut, fin
    FROM FileAttente f
    JOIN SessionVente s ON f.idSessionVente = s.idSession
    WHERE f.idQueue = idFile;

    -- Vérifier si l'utilisateur est déjà dans la file
    IF EXISTS (
        SELECT 1 FROM Attendre
        WHERE idQueue = idFile AND idUser = idUtilisateur
    ) THEN
        RAISE NOTICE 'Utilisateur déjà dans la file.';
        RETURN;
    END IF;

    -- Vérifier si période valide (précaution redondante)
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
    PERFORM set_config('myapp.allow_create_attendre', 'on', true);
    INSERT INTO Attendre(idQueue, idUser, rang)
    VALUES (idFile, idUtilisateur, rang_max + 1);
    PERFORM set_config('myapp.allow_create_attendre', 'off', true);

    RAISE NOTICE 'Utilisateur "%" ajouté à la file active de l''événement "%".', idUtilisateur, id_event_var;
END;
$$ LANGUAGE plpgsql;



--  Fonction principale
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

CREATE OR REPLACE FUNCTION sortirFileAttente(emailUser VARCHAR, descriptionEvent_donnee TEXT)
RETURNS VOID AS $$
DECLARE
    idUtilisateur INT;
    id_event_var INT;
    idFile INT;
BEGIN
    -- Récupérer l'utilisateur
    idUtilisateur := getUserIdByEmail(emailUser);
    IF idUtilisateur IS NULL THEN
        RAISE NOTICE 'Utilisateur avec l''email % introuvable.', emailUser;
        RETURN;
    END IF;

    -- Récupérer l'événement
    id_event_var := getEventIdByDescription(descriptionEvent_donnee);
    IF id_event_var IS NULL THEN
        RAISE NOTICE 'Événement avec la description "%" introuvable.', descriptionEvent_donnee;
        RETURN;
    END IF;

    -- Récupérer la file d'attente active
    idFile := get_active_queue_for_event(id_event_var);

    -- Supprimer l'utilisateur de la file d'attente (table Attendre)
    DELETE FROM Attendre
    WHERE idUser = idUtilisateur AND idQueue = idFile;

    RAISE NOTICE 'Utilisateur % retiré de la file d''attente %.', idUtilisateur, idFile;
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
    PERFORM set_config('myapp.allow_modify_sv', 'on', true);
    UPDATE SessionVente
    SET dateDebutSession = p_dateDebut,
        dateFinSession = p_dateFin,
        nbBilletsMisEnVente = p_nbBillets,
        onlyVIP = p_onlyVIP,
        nbMaxBilletsAchetesVIP = p_maxVIP,
        nbMaxBilletsAchetesRegular = p_maxRegular
    WHERE idSession = p_idSession;
    PERFORM set_config('myapp.allow_modify_sv', 'off', true);
END;
$$ LANGUAGE plpgsql;
