DROP TRIGGER IF EXISTS trigger_verrou_utilisateur ON Utilisateur;
-- -> créer une fonction maj_pts_fidelite (en fonction des achats faits)

CREATE OR REPLACE FUNCTION verrouiller_modifications_utilisateur()
RETURNS TRIGGER AS $$
BEGIN
    -- Interdire la modification de lemail
    IF NEW.email IS DISTINCT FROM OLD.email THEN
        RAISE EXCEPTION 'Modification de l\'email interdite.';
    END IF;

    -- Interdire la modification du statut utilisateur
    IF NEW.statutUser IS DISTINCT FROM OLD.statutUser THEN
        RAISE EXCEPTION 'Modification du statut utilisateur interdite.';
    END IF;

    -- Interdire la modification de la date d'dateInscription
    IF NEW.dateInscription IS DISTINCT FROM OLD.dateInscription THEN
        RAISE EXCEPTION 'Modification de la date d\'incription interdite';
    END IF;

    -- Vérifier la modification des points de fidélité
    IF NEW.ptsFidelite IS DISTINCT FROM OLD.ptsFidelite THEN
        IF current_setting('myapp.allow_pts_update', true) IS DISTINCT FROM 'on' THEN
            RAISE EXCEPTION 'Modification des points de fidélité interdite en dehors de maj_points_fidelite.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verrou_utilisateur
BEFORE UPDATE ON Utilisateur
FOR EACH ROW
EXECUTE FUNCTION verrouiller_modifications_utilisateur();
