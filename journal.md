Les tables Siege, Categorie, Lieu sont uniquement créées à partir des csv et de insert_data.sql
Il existe aussi des données pour les tables Concert, Calendrier, Artiste et Utilisateur dans
les csv mais ce sont des tables qui sont aussi modifiables depuis les scripts dans ETUDES
Pour l'instant à chaque fois qu'on veut test un truc on peut copie-colle le contenu de cmd.sql

22-04-2025
Trouver une façon de définir les prix des billets dans la table Grille(avant potentielles reductions liées aux ptsFidelite d'un User) telle que ces prix dépendent d'un événement et d'une catégorie. Pour l'instant je me dis que je peux récup nomCategorie et si on ajoute un
attribut niveauDemandeAttendu dans la classe Concert alors je me sers des deux et d'un prix de base : ex si nomCategorie = "CAT_1" alors prix de base = 70euros puis si niveauDemandeAttendu = 1.5 alors prix pour l'idCategorie et l'idEvent concerné = 70*1.5 = 105euros. Mais ça ça implique une df niveauDemandeAttendu, nomCategorie -> prix et donc c'est pas en 3NF, comment faire ?
note à moi-même : je me suis arreté ds orga_concerts.sql.
Marie

23-04-2025
Tout ce que j'ai écris est non corrigé et non testé.
A faire la prochaine fois: tester tous les triggers écris et leurs concurences, + continuer à écrire les triggers pour attendre et fille d'attente (tout ce qui est panier et réservation on le fera plus tard)
