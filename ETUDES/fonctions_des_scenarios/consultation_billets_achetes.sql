CREATE OR REPLACE FUNCTION afficher_billets_par_email(emailUtilisateur VARCHAR)
RETURNS TABLE (
    idBillet INT,
    nomCategorie VARCHAR,
    prix NUMERIC,
    place INT,
    dateConcert DATE,
    descriptionConcert TEXT,
    dateAchat TIMESTAMP
) AS $$
DECLARE
    userId INT;
BEGIN
    userId := getUserIdByEmail(emailUtilisateur);
    RAISE NOTICE 'Voici les billets de l’utilisateur %', userId;

    -- Retourner les lignes filtrées de la vue
    RETURN QUERY
    SELECT 
        b.idBillet,
        c.nomCategorie,
        b.prix,
        b.idSiege as place,
        b.dateEvent as dateConcert,
        e.descriptionEvent as descriptionConcert,
        t.dateTransaction AS dateAchat
    FROM 
        Billet b
    JOIN 
        PreReservation p ON b.idPanier = p.idPanier
    JOIN 
        Transac t ON p.idPanier = t.idPanier
    JOIN 
        Siege s ON b.idSiege = s.idSiege
    JOIN 
        CategorieSiege c ON s.idCategorie = c.idCategorie
    JOIN 
        Concert e ON b.idEvent = e.idEvent
    WHERE 
        b.statutBillet = 'vendu'
        AND p.idUser = userId;
END;
$$ LANGUAGE plpgsql;
