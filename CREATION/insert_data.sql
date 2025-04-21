
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
