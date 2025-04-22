
-- ajout des données dans les tables
\COPY Artiste FROM 'CREATION/bdd/artistes.csv' DELIMITER ';' CSV HEADER;
\COPY Concert FROM 'CREATION/bdd/concerts.csv' DELIMITER ';' CSV HEADER;
\COPY Utilisateur FROM 'CREATION/bdd/utilisateurs.csv' DELIMITER ';' CSV HEADER;
\COPY Calendrier FROM 'CREATION/bdd/calendrier.csv' DELIMITER ';' CSV HEADER;
\COPY Lieu FROM 'CREATION/bdd/lieux.csv' DELIMITER ';' CSV HEADER;
\COPY CategorieSiege FROM 'CREATION/bdd/categories_sieges.csv' DELIMITER ';' CSV HEADER;
\COPY Siege FROM 'CREATION/bdd/sieges.csv' DELIMITER ';' CSV HEADER;
\COPY AvoirLieu FROM 'CREATION/bdd/avoir_lieu.csv' DELIMITER ';' CSV HEADER;
\COPY Grille FROM 'CREATION/bdd/grille.csv' DELIMITER ';' CSV HEADER;
\COPY Participe FROM 'CREATION/bdd/participe.csv' DELIMITER ';' CSV HEADER;
\COPY SessionVente FROM 'CREATION/bdd/sessions_ventes.csv' DELIMITER ';' CSV HEADER;
\COPY Billet FROM 'CREATION/bdd/billets.csv' DELIMITER ';' CSV HEADER;

-- pour toutes les tables qui ont une clé primaire SERIAL et qui ont 
--reçu des données on maj la val du serial
SELECT setval('artiste_idartiste_seq', (SELECT MAX(idArtiste) FROM Artiste));
SELECT setval('concert_idevent_seq', (SELECT MAX(idEvent) FROM Concert));
SELECT setval('utilisateur_iduser_seq', (SELECT MAX(idUser) FROM Utilisateur));
SELECT setval('sessionvente_idsession_seq', (SELECT MAX(idSession) FROM SessionVente));
SELECT setval('billet_idbillet_seq', (SELECT MAX(idBillet) FROM Billet));