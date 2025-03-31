
\COPY Artiste FROM 'bdd/artistes.csv' DELIMITER ';' CSV HEADER;
\COPY Concert FROM 'bdd/concerts.csv' DELIMITER ';' CSV HEADER;
\COPY Utilisateur FROM 'bdd/utilisateurs.csv' DELIMITER ';' CSV HEADER;
\COPY Calendrier FROM 'bdd/calendrier.csv' DELIMITER ';' CSV HEADER;
\COPY Lieu FROM 'bdd/lieux.csv' DELIMITER ';' CSV HEADER;
\COPY CategorieSiege FROM 'bdd/categories_sieges.csv' DELIMITER ';' CSV HEADER;
\COPY Siege FROM 'bdd/sieges.csv' DELIMITER ';' CSV HEADER;
\COPY AvoirLieu FROM 'bdd/avoir_lieu.csv' DELIMITER ';' CSV HEADER;
\COPY Grille FROM 'bdd/grille.csv' DELIMITER ';' CSV HEADER;
\COPY Participe FROM 'bdd/participe.csv' DELIMITER ';' CSV HEADER;
\COPY SessionVente FROM 'bdd/sessions_ventes.csv' DELIMITER ';' CSV HEADER;
\COPY Billet FROM 'bdd/billets.csv' DELIMITER ';' CSV HEADER;
