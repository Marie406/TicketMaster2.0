DROP VIEW vue_dispo_par_categorie;

CREATE OR REPLACE VIEW vue_dispo_par_categorie AS
SELECT
    B.idSession,
    C.idCategorie,
    C.nomCategorie,
    G.prix,
    COUNT(B.idBillet) FILTER (WHERE B.statutBillet = 'en vente') AS billets_restants
FROM Billet B
JOIN Siege S ON B.idSiege = S.idSiege
JOIN CategorieSiege C ON S.idCategorie = C.idCategorie
JOIN Grille G ON G.idEvent = B.idEvent AND G.idCategorie = C.idCategorie
WHERE B.idSession IS NOT NULL
GROUP BY B.idSession, C.idCategorie, C.nomCategorie, G.prix;

CREATE OR REPLACE FUNCTION informerUtilisateurOptionsAchat(idUserInput INT, idSessionInput INT)
RETURNS INT AS $$
DECLARE
    max_billets INT;
    rec RECORD;
BEGIN
    -- Appel de la fonction précédente pour récupérer le nombre de billets autorisés
    max_billets := recupererNbBilletsAchetables(idUserInput, idSessionInput);

    -- Si NULL, on arrête
    IF max_billets IS NULL THEN
        RAISE NOTICE 'Impossible de déterminer le nombre de billets achetables.';
        RETURN NULL;
    END IF;

    -- Afficher les options de billets disponibles par catégorie
    RAISE NOTICE 'Voici les prix des billets par catégories pour l''evenement souhaite :';

    FOR rec IN EXECUTE 'SELECT nomCategorie, prix, billets_restants
                        FROM vue_dispo_par_categorie
                        WHERE idSession = $1'
                        USING idSessionInput

    LOOP
        RAISE NOTICE '- Categorie % : %euros -> % billets restants',
            rec.nomCategorie, rec.prix, rec.billets_restants;
    END LOOP;

    RETURN max_billets;
END;
$$ LANGUAGE plpgsql;

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

CREATE OR REPLACE FUNCTION get_active_queue_for_event(id_event_var INT)
RETURNS INT AS $$
DECLARE
    idFile INT;
BEGIN
    -- On cherche la file d'attente liée à une session active pour l'événement
    SELECT f.idQueue
    INTO idFile
    FROM FileAttente f
    JOIN SessionVente s ON f.idSessionVente = s.idSession
    WHERE s.idEvent = id_event_var
      AND now() BETWEEN s.dateDebutSession AND s.dateFinSession
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Aucune file active trouvée pour l''événement %.', id_event_var;
    END IF;

    RETURN idFile;
END;
$$ LANGUAGE plpgsql;