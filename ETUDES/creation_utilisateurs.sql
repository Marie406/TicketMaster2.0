CREATE OR REPLACE FUNCTION creer_utilisateur(
    nom VARCHAR,
    prenom VARCHAR,
    adresse TEXT,
    email VARCHAR,
    statut VARCHAR DEFAULT 'regular',
    pts INT DEFAULT 0
) RETURNS VOID AS $$
BEGIN
    INSERT INTO Utilisateur (
        nomUser,
        prenomUser,
        adresseUser,
        email,
        statutUser,
        ptsFidelite
    )
    VALUES (
        nom,
        prenom,
        adresse,
        email,
        statut,
        pts
    );
END;
$$ LANGUAGE plpgsql;

