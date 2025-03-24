--pas encore pu tester ça

\copy Artiste FROM 'dataBase/artistes.csv' DELIMITER ';' CSV HEADER;
\copy Concert FROM 'dataBase/concerts.csv' DELIMITER ';' CSV HEADER;
\copy Utilisateur FROM 'dataBase/utilisateurs.csv' DELIMITER ';' CSV HEADER;
\copy Calendrier FROM 'dataBase/calendrier.csv' DELIMITER ';' CSV HEADER;
\copy Lieu FROM 'dataBase/lieux.csv' DELIMITER ';' CSV HEADER;
\copy CategorieSiege FROM 'dataBase/categories_siege.csv' DELIMITER ';' CSV HEADER;
\copy Siege FROM 'dataBase/sieges.csv' DELIMITER ';' CSV HEADER;
\copy AvoirLieu FROM 'dataBase/avoir_lieu.csv' DELIMITER ';' CSV HEADER;
\copy Grille FROM 'dataBase/grille.csv' DELIMITER ';' CSV HEADER;
\copy Participe FROM 'dataBase/participe.csv' DELIMITER ';' CSV HEADER;
\copy SessionVente FROM 'dataBase/sessions_vente.csv' DELIMITER ';' CSV HEADER;
\copy Billet FROM 'dataBase/billets.csv' DELIMITER ';' CSV HEADER;
