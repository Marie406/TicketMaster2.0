DROP TRIGGER IF EXISTS trigger_avant_insert_billet ON Billet;
DROP TRIGGER IF EXISTS trigger_avant_insert_statut_billet ON Billet;
DROP TRIGGER IF EXISTS trigger_verrou_modifications_billet ON Billet;
DROP TRIGGER IF EXISTS trigger_mis_panier_billet ON Billet;
DROP TRIGGER IF EXISTS trigger_vendre_billet ON Billet;
DROP TRIGGER IF EXISTS trigger_autoriser_changement_idsession ON Billet;
-- -> Ajouter un trigger pour verifier les prix des billets lors de l'insert en fonction de categorie...
-- -> Problème à changer, trouver une autre solution que


-- Empêcher l’ajout d’un billet si le nombre de billets
-- dépasse la capacité du lieu concerné par l’événement
CREATE OR REPLACE FUNCTION avant_insert_billet()
RETURNS TRIGGER AS $$
DECLARE
    capacite_du_lieu INT;
    total_billets INT;
BEGIN
    -- Récupérer la capacité du lieu concerné par l'événement
    SELECT L.capaciteAccueil
    INTO capacite_du_lieu
    FROM Lieu L
    JOIN AvoirLieu AL ON L.idLieu = AL.idLieu
    WHERE AL.idEvent = NEW.idEvent AND AL.dateEvent = NEW.dateEvent
    FOR UPDATE;

    -- Calculer le nombre total de billets déjà existants pour cet événement
    SELECT COUNT(*) INTO total_billets
    FROM Billet
    WHERE idEvent = NEW.idEvent AND dateEvent = NEW.dateEvent;

    -- Comparer la capacité avec le nombre total de billets
    IF total_billets >= capacite_du_lieu THEN
        -- Si la capacité est atteinte, lever une exception pour empêcher l'insertion
        RAISE EXCEPTION 'La capacité du lieu pour cet événement est atteinte, impossible d''ajouter un nouveau billet.';
    END IF;

    -- Si tout va bien, retourner la ligne pour l'insertion
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_avant_insert_billet
BEFORE INSERT ON billet
FOR EACH ROW
EXECUTE FUNCTION avant_insert_billet();

-- Vérifier que le statut du billet est bien 'en vente' avnt d'insérer
CREATE OR REPLACE FUNCTION verifier_statut_billet()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.statutBillet IS DISTINCT FROM 'en vente' THEN
        RAISE EXCEPTION 'Le statut initial du billet doit être "en vente".';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_avant_insert_statut_billet
BEFORE INSERT ON Billet
FOR EACH ROW
EXECUTE FUNCTION verifier_statut_billet();

-- Empêcher toute modification manuelle d'une ligne de la table billet
-- sauf pour le prix si c'est pour appliquer une réduction
-- et pour le status, si le billet est vendu ou mis dans un panier
-- et pour le idSession si c'est fait correctement
CREATE OR REPLACE FUNCTION verrouiller_modifications_billet()
RETURNS TRIGGER AS $$
BEGIN
    -- Refuser toute modification si le billet est déjà vendu
    IF OLD.statutBillet = 'vendu' THEN
        RAISE EXCEPTION 'Impossible de modifier le billet : il est déjà vendu.';
    END IF;

    -- Prix
    IF NEW.prix IS DISTINCT FROM OLD.prix AND
       coalesce(current_setting('myapp.allow_price_change', true), 'off') IS DISTINCT FROM 'on' THEN
        RAISE EXCEPTION 'Modification du prix interdite hors trigger autorisé.';
    END IF;

    -- Statut
    IF NEW.statutBillet IS DISTINCT FROM OLD.statutBillet AND
       coalesce(current_setting('myapp.allow_statut_change', true), 'off') IS DISTINCT FROM 'on' THEN
        RAISE EXCEPTION 'Modification du statut interdite hors trigger autorisé.';
    END IF;

    -- idSession
    IF NEW.idSession IS DISTINCT FROM OLD.idSession AND
       coalesce(current_setting('myapp.allow_idsession_change', true), 'off') IS DISTINCT FROM 'on' THEN
        RAISE EXCEPTION 'Modification de idSession interdite hors trigger autorisé.';
    END IF;

    -- idPanier
    IF NEW.idPanier IS DISTINCT FROM OLD.idPanier AND
       coalesce(current_setting('myapp.allow_idpanier_change', true), 'off') IS DISTINCT FROM 'on' THEN
        RAISE EXCEPTION 'Modification de idPanier interdite hors trigger autorisé.';
    END IF;

    -- Autres champs non modifiables
    IF NEW.idSiege IS DISTINCT FROM OLD.idSiege
       OR NEW.dateEvent IS DISTINCT FROM OLD.dateEvent
       OR NEW.idEvent IS DISTINCT FROM OLD.idEvent THEN
        RAISE EXCEPTION 'Modification de champs non autorisés (idSiege, dateEvent ou idEvent).';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



CREATE TRIGGER trigger_verrou_modifications_billet
BEFORE UPDATE ON Billet
FOR EACH ROW
EXECUTE FUNCTION verrouiller_modifications_billet();




-- Autoriser la modification du prix si on applique une réduction (quand achat par un 'VIP')
CREATE OR REPLACE FUNCTION appliquer_reduction_billet()
RETURNS TRIGGER AS $$
BEGIN
    -- Créer la variable 'myapp.allow_price_change' dans la base valant 'on' pour autoriser
    -- temporairement la modification du prix
    PERFORM set_config('myapp.allow_price_change', 'on', true);
    NEW.prix := NEW.prix * 0.9;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Autoriser la modification du prix si le billet à été mis dans un panier
CREATE OR REPLACE FUNCTION mis_panier_billet()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM set_config('myapp.allow_statut_change', 'on', true);
    NEW.statutBillet := 'dans un panier';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_mis_panier_billet
BEFORE UPDATE ON Billet
FOR EACH ROW
WHEN (OLD.statutBillet = 'en vente' AND NEW.statutBillet = 'dans un panier')
EXECUTE FUNCTION mis_panier_billet();

-- Autoriser la modification du statut si le billet à été vendu depuis un panier
CREATE OR REPLACE FUNCTION vendu_billet()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM set_config('myapp.allow_statut_change', 'on', true);
    NEW.statutBillet := 'vendu';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_vendre_billet
BEFORE UPDATE ON Billet
FOR EACH ROW
WHEN (OLD.statutBillet = 'dans un panier' AND NEW.statutBillet = 'vendu')
EXECUTE FUNCTION vendu_billet();

-- si il passe de qqchose à null ou de null à une idSession existante
-- normalement il faudrait aussi empecher de mettre une idSession déjà passée dessus...
CREATE OR REPLACE FUNCTION autoriser_changement_idsession()
RETURNS TRIGGER AS $$
DECLARE
    session_existe BOOLEAN;
BEGIN
    -- Cas 1 : passage de NULL → idSession existante
    IF OLD.idSession IS NULL AND NEW.idSession IS NOT NULL THEN
        SELECT EXISTS (
            SELECT 1 FROM SessionVente WHERE idSession = NEW.idSession
        ) INTO session_existe;

        IF session_existe THEN
            PERFORM set_config('myapp.allow_idsession_change', 'on', true);
        ELSE
            RAISE EXCEPTION 'La session % n''existe pas dans SessionVente.', NEW.idSession;
        END IF;

    -- Cas 2 : passage d’une session → NULL
    ELSIF OLD.idSession IS NOT NULL AND NEW.idSession IS NULL THEN
        PERFORM set_config('myapp.allow_idsession_change', 'on', true);

    -- Tout autre cas : changement refusé
    ELSE
        RAISE EXCEPTION 'Changement de idSession non autorisé (valeurs : % → %)', OLD.idSession, NEW.idSession;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_autoriser_changement_idsession
BEFORE UPDATE ON Billet
FOR EACH ROW
WHEN (OLD.idSession IS DISTINCT FROM NEW.idSession)
EXECUTE FUNCTION autoriser_changement_idsession();
