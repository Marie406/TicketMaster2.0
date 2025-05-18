DROP FUNCTION prereserver_demande(integer,integer,integer,jsonb);

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


--si la demande du client est faisable en terme de nb de billet demandés et autorisés + disponibles
-- alors crée un panier et associe les billets des catégories désirées à cet idPanier
CREATE OR REPLACE FUNCTION prereserver_demande(
    idPanierInput INT,
    idUserInput INT,
    idSessionInput INT,
    demandes JSONB
)
RETURNS VOID AS $$
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
        RETURN;
    END IF;

    -- Récupérer le max de billets autorisé
    max_billets := recupererNbBilletsAchetables(idUserInput, idSessionInput);

    IF max_billets IS NULL THEN
        RAISE NOTICE 'Impossible de récupérer la limite de billets.';
        RETURN;
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
            RETURN;
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
            RETURN;
        END IF;

        billets_dispos := billets_dispos || billets_temp;
    END LOOP;

    -- Vérification finale du nombre total
    IF total_demandes > max_billets THEN
        RAISE NOTICE 'Vous avez demandé % billets, mais vous ne pouvez en acheter que %.', total_demandes, max_billets;
        RAISE NOTICE 'La pré-réservation ne peut aboutir';
        RETURN;
    END IF;

    -- on autorise le changement de statut des billets
    PERFORM set_config('myapp.allow_statut_change', 'on', true);
    PERFORM set_config('myapp.allow_idpanier_change', 'on', true);

    -- Affectation des billets au panier
    UPDATE Billet
    SET idPanier = idPanierInput,
        statutBillet = 'dans un panier'
    WHERE idBillet = ANY(billets_dispos);

    PERFORM set_config('myapp.allow_statut_change', 'off', true);
    PERFORM set_config('myapp.allow_idpanier_change', 'off', true);

    RAISE NOTICE 'Pré-réservation effectuée pour utilisateur % de % billets', idUserInput, total_demandes;
    RETURN;
END;
$$ LANGUAGE plpgsql;


--vérifie que l'utilisateur est bien dans le sas de la session et
-- avec un statutSas 'en cours'
CREATE OR REPLACE FUNCTION preReserver(
    idPanierUser INT,
    demandes JSONB
) RETURNS VOID AS $$
DECLARE
    idUserFound INT;
    idSessionFound INT;
    idQueueFound INT;
BEGIN
    -- On récupère idUser et idSession à partir de l'idPanier
    --repose sur le fait que les lignes sont supprimées de
    --PreReservation pour un utilisateur dès qu'il sort du sas
    --ou qu'il valide sa transaction
    SELECT idUser, idSession INTO idUserFound, idSessionFound
    FROM PreReservation p
    WHERE p.idPanier = idPanierUser;

    -- On récupère idQueue
    SELECT idQueue INTO idQueueFound
    FROM FileAttente f
    WHERE f.idSessionVente = idSessionFound;

    -- Vérifier que l'utilisateur est bien dans le SAS
    IF NOT EXISTS (
        SELECT 1 FROM SAS s
        WHERE s.idQueue = idQueueFound
          AND s.idUser = idUserFound
          AND statusSAS = 'en cours'
    ) THEN
        RAISE NOTICE 'Utilisateur % non présent dans le SAS de la queue %', idUserFound, idQueueFound;
        RAISE NOTICE 'La pré-réservation ne peut aboutir';
        RETURN;
    END IF;

    PERFORM prereserver_demande(idPanierUser, idUserFound, idSessionFound, demandes);
    PERFORM creer_transaction_avec_montant_calcule(idPanierUser);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION preReserverAvecEmail(
    emailUser VARCHAR,
    descriptionEvent TEXT,
    demandes JSONB
) RETURNS VOID AS $$
DECLARE
    idUserFound INT;
    idPanierFound INT;
BEGIN
    -- Récupérer l'identifiant de l'utilisateur.
    idUserFound := getUserIdByEmail(emailUser);

    -- Récupérer le panier associé à l'utilisateur.
    SELECT idPanier
    INTO idPanierFound
    FROM PreReservation
    WHERE idUser = idUserFound;

    IF idPanierFound IS NULL THEN
        RAISE EXCEPTION 'Aucun panier trouvé pour l''utilisateur %', idUserFound;
    END IF;

    PERFORM preReserver(idPanierFound, demandes);
END;
$$ LANGUAGE plpgsql;
