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