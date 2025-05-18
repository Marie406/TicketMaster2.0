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


--PREPARE billets_par_categorie(INT) AS
--SELECT * FROM vue_dispo_par_categorie WHERE idSession = $1;

CREATE OR REPLACE FUNCTION recupererNbBilletsAchetables(idUserInput INT, idSessionInput INT)
RETURNS INT AS $$
DECLARE
    type_utilisateur VARCHAR;
    max_billets INT;
BEGIN
    -- Récupérer le type de l'utilisateur
    SELECT statutUser INTO type_utilisateur
    FROM Utilisateur
    WHERE idUser = idUserInput;

    IF NOT FOUND THEN
        RAISE NOTICE 'Utilisateur avec id % introuvable.', idUserInput;
        RETURN NULL;
    END IF;

    -- Récupérer le nombre max de billets selon le type
    IF type_utilisateur = 'VIP' THEN
        SELECT nbMaxBilletsAchetesVIP INTO max_billets
        FROM SessionVente
        WHERE idSession = idSessionInput;
    ELSIF type_utilisateur = 'regular' THEN
        SELECT nbMaxBilletsAchetesRegular INTO max_billets
        FROM SessionVente
        WHERE idSession = idSessionInput;
    ELSE
        RAISE NOTICE 'Type d''utilisateur inconnu.';
        RETURN NULL;
    END IF;

    IF NOT FOUND THEN
        RAISE NOTICE 'Session avec id % introuvable.', idSessionInput;
        RETURN NULL;
    END IF;

    -- Afficher
    RAISE NOTICE 'Bonjour utilisateur %, vous avez un compte % et pouvez acheter jusqu''à % billets pendant cette session.',
        idUserInput, type_utilisateur, max_billets;

    RETURN max_billets;
END;
$$ LANGUAGE plpgsql;

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


--si la demande du client est faisable en terme de nb de billet demandés et autorisés + disponibles
-- alors crée un panier et associe les billets des catégories désirées à cet idPanier
CREATE OR REPLACE FUNCTION prereserver_demande(
    idPanierInput INT,
    idUserInput INT,
    idSessionInput INT,
    demandes JSONB
)
RETURNS INT AS $$
DECLARE
    idEventFound INT;
    idLieuFound INT;
    max_billets INT;
    total_demandes INT := 0;
    billets_dispos INT[];
    billets_temp INT[];
    cat TEXT;
    nbDemandes INT;
    idCategorieTrouvee INT;
BEGIN
    -- Récupérer idEvent et idLieu à partir de la session
    SELECT idEvent, idLieu INTO idEventFound, idLieuFound
    FROM SessionVente
    WHERE idSession = idSessionInput;

    IF NOT FOUND THEN
        RAISE NOTICE 'Session % introuvable.', idSessionInput;
        RETURN NULL;
    END IF;

    -- Récupérer le max de billets autorisé
    max_billets := recupererNbBilletsAchetables(idUserInput, idSessionInput);

    IF max_billets IS NULL THEN
        RAISE NOTICE 'Impossible de récupérer la limite de billets.';
        RETURN NULL;
    END IF;

    -- Vérification des disponibilités
    billets_dispos := ARRAY[]::INT[];

    FOR cat IN SELECT jsonb_object_keys(demandes)
    LOOP
        nbDemandes := (demandes ->> cat)::INT;
        total_demandes := total_demandes + nbDemandes;

        -- Récupérer l'idCategorie pour ce nom de catégorie
        SELECT G.idCategorie INTO idCategorieTrouvee
        FROM Grille G
        JOIN CategorieSiege C ON G.idCategorie = C.idCategorie
        WHERE G.idEvent = idEventFound
          AND C.idLieu = idLieuFound
          AND C.nomCategorie = cat;

        IF NOT FOUND THEN
            RAISE NOTICE 'Catégorie % introuvable pour l''événement.', cat;
            RAISE NOTICE 'La pré-réservation ne peut aboutir';
            RETURN NULL;
        END IF;

        -- Récupérer les billets disponibles pour cette catégorie
        SELECT ARRAY(
            SELECT B.idBillet
            FROM Billet B
            JOIN Siege S ON B.idSiege = S.idSiege
            WHERE B.idSession = idSessionInput
              AND S.idCategorie = idCategorieTrouvee
              AND B.statutBillet = 'en vente'
            LIMIT nbDemandes
        ) INTO billets_temp;

        IF array_length(billets_temp, 1) < nbDemandes THEN
            RAISE NOTICE 'Pas assez de billets disponibles pour la catégorie %.', cat;
            RAISE NOTICE 'La pré-réservation ne peut aboutir';
            RETURN NULL;
        END IF;

        billets_dispos := billets_dispos || billets_temp;
    END LOOP;

    -- Vérification finale du nombre total
    IF total_demandes > max_billets THEN
        RAISE NOTICE 'Vous avez demandé % billets, mais vous ne pouvez en acheter que %.', total_demandes, max_billets;
        RAISE NOTICE 'La pré-réservation ne peut aboutir';
        RETURN NULL;
    END IF;

    -- on autorise le changement de statut des billets
    PERFORM set_config('myapp.allow_statut_change', 'on', true);
    PERFORM set_config('myapp.allow_idpanier_change', 'on', true);

    -- Affectation des billets au panier
    UPDATE Billet
    SET idPanier = idPanierInput,
        statutBillet = 'dans un panier'
    WHERE idBillet = ANY(billets_dispos);

    RAISE NOTICE 'Pré-réservation effectuée pour utilisateur % de % billets', idUserInput, total_demandes;
    RETURN idPanierUser;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION creer_transaction_avec_montant_zero(idPanierInput)
RETURNS TRIGGER AS $$
BEGIN
    -- Créer une transaction avec un montant initial à 0 lorsque la pré-réservation est créée
    INSERT INTO Transac(montant, statutTransaction, idPanier)
    VALUES (0, 'en attente', idPanierInput);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



--vérifie que l'utilisateur est bien dans le sas de la session et
-- avec un statutSas 'en cours'
CREATE OR REPLACE FUNCTION preReserver(
    idPanierUser INT;
    demandes JSONB
) RETURNS VOID AS $$
DECLARE
    idUserFound INT;
    idSessionFound INT;
    idQueueFound INT;
BEGIN
    -- on recupère l'iduser et idsession a partir de l'idpanier
    SELECT
    idUser, idSession INTO idUserFound, idsessionFound
    FROM PreReservation p
    WHERE p.idPanier = idPanierUser;

    -- on recuper l'idqueue
    SELECT idQueue AS idQueueFound
    FROM FileAttente f
    WHERE f.idSession = idSessionFound;

    -- Vérifier que l'utilisateur est bien dans le SAS associé à cette file
    IF NOT EXISTS (
        SELECT 1 FROM SAS s
        WHERE s.idQueue = idQueueFound AND s.idUser = idUserFound
            AND statusSAS = 'en cours'
    ) THEN
        RAISE NOTICE 'Utilisateur % non présent dans le SAS de la queue % pour l''événement %', idUserFound, idQueueFound, idEvent;
        RAISE NOTICE 'La pré-réservation ne peut aboutir';
        RETURN;
    END IF;

    PERFORM prereserver_demande(idPanierUser, idUserFound, idSessionFound, demandes);
    PERFORM creer_transaction_avec_montant_zero(idPanierUser);

END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION preReserverAvecEmail(
    emailUser VARCHAR,
    descriptionEvent TEXT,
    demandes JSONB
) RETURNS VOID AS $$
DECLARE
    idUserFound INT;
    idEventFound INT;
    idQueueFound INT;
BEGIN
    -- Récupérer l'identifiant de l'utilisateur
    idUserFound := getUserIdByEmail(emailUser);

    -- Récupérer l'identifiant de l'événement
    idEventFound := getEventIdByDescription(descriptionEvent);

    -- Obtenir l'identifiant de la file d'attente active
    idQueueFound := get_active_queue_for_event(idEventFound);

    -- Vérifier que l'utilisateur est bien dans le SAS associé à cette file
    IF NOT EXISTS (
        SELECT 1 FROM SAS s
        WHERE s.idQueue = idQueueFound AND s.idUser = idUserFound
            AND statusSAS = 'en cours'
    ) THEN
        RAISE NOTICE 'Utilisateur % non présent dans le SAS de la file % pour l''événement %', idUserFound, idQueueFound, descriptionEvent;
        RAISE NOTICE 'La pré-réservation ne peut aboutir';
        RETURN;
    END IF;

    -- Appel de la fonction de pré-réservation
    PERFORM creerPreReservation(idUserFound, idQueueFound, demandes);

END;
$$ LANGUAGE plpgsql;

SELECT idPanier
FROM PreReservation
WHERE idUser = getUserIdByEmail(emailUser);


--test avec un nb de billets raisonnable et pour un utilisateur qui est dans le sas
--SELECT preReserverAvecEmail('daniel@email.com','Tournee mondiale de Stray Kids','{"CAT_3": 2, "CAT_4": 2}'::jsonb);

--test nb de billets trop élevé pr statut
--SELECT preReserver('daniel@email.com','Tournee mondiale de Stray Kids','{"CAT_3": 3, "CAT_4": 4}'::jsonb);

--test utilisateur dans la file mais pas encore dans le sas
--SELECT preReserver('hyunjin@email.com','Tournee mondiale de Stray Kids','{"CAT_1": 2, "CAT_2": 1, "CAT_3":1}'::jsonb);

--tester qd nb billets coherent avec limite fixé par la sessionVente mais les stocks sont insuffisants

--montrer les resultats des tests avec
--select * from prereservation;
--select * from billet where idpanier is not null;
