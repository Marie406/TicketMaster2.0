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


SELECT creer_utilisateur('Kim', 'Jisoo', '14 rue de Séoul', 'jisoo@email.com', 'VIP', 120);
SELECT creer_utilisateur('Park', 'Jimin', '23 avenue des Idoles', 'jimin@email.com', 'VIP', 150);
SELECT creer_utilisateur('Choi', 'Soojin', '45 boulevard des Fans', 'soojin@email.com', 'regular', 30);
SELECT creer_utilisateur('Lee', 'Minho', '78 rue des Concerts', 'minho@email.com', 'regular', 60);
SELECT creer_utilisateur('Jeon', 'Jungkook', '5 place du Kpop', 'jungkook@email.com', 'VIP', 180);
SELECT creer_utilisateur('Hwang', 'Hyunjin', '3 avenue Hallyu', 'hyunjin@email.com', 'regular', 90);
SELECT creer_utilisateur('Seo', 'Jaein', '9 rue du Han', 'jaein@email.com', 'regular', 45);
SELECT creer_utilisateur('Yoo', 'Nari', '32 rue du Flow', 'nari@email.com', 'VIP', 200);
SELECT creer_utilisateur('Han', 'Seungmin', '56 place des Tickets', 'seungmin@email.com', 'regular', 55);
SELECT creer_utilisateur('Kang', 'Daniel', '11 allée des Stages', 'daniel@email.com', 'VIP', 210);
SELECT creer_utilisateur('Im', 'Nayeon', '18 rue de la Pop', 'nayeon@email.com', 'VIP', 160);
SELECT creer_utilisateur('Kim', 'Seokjin', '33 rue du Micro', 'seokjin@email.com', 'regular', 75);
SELECT creer_utilisateur('Oh', 'Sehun', '7 boulevard du Fandom', 'sehun@email.com', 'regular', 50);
SELECT creer_utilisateur('Ahn', 'Yujin', '21 chemin du Lightstick', 'yujin@email.com', 'VIP', 170);
SELECT creer_utilisateur('Shin', 'Ryujin', '13 rue du Soundcheck', 'ryujin@email.com', 'regular', 40);
SELECT creer_utilisateur('Lee', 'Felix', '22 avenue des Backstages', 'felix@email.com', 'VIP', 130);
SELECT creer_utilisateur('Bang', 'Chan', '91 passage des Fansigns', 'chan@email.com', 'VIP', 195);
SELECT creer_utilisateur('Kim', 'Taehyung', '6 ruelle des Bias', 'taehyung@email.com', 'VIP', 220);
SELECT creer_utilisateur('Moon', 'Bin', '16 rue de la Scène', 'bin@email.com', 'regular', 65);
SELECT creer_utilisateur('Jung', 'Eunji', '2 avenue des Harmonies', 'eunji@email.com', 'regular', 70);
