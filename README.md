CHANEAC Marie  
RIBEIRO MARQUES Marie-Lou

# Guide d'utilisation :

Se placer dans le répertoire racine du projet puis, depuis une base de données vide exécuter la commande :
`\i main.sql`

Le fichier main.sql est chargé de remplir la base de données avec toutes les tables, index, triggers, fonctions nécéssaires aux différents scénarios.

Ensuite pour exécuter les différents scénarios on peut utiliser les commandes :

`\i ETUDES/script_commun_init.sql` (celui-ci est directement exécuté dans le main donc pas besoin de relancer la commande, il simule la création de nouveaux utilisateurs et événements)

`\i ETUDES/script_faire_queue.sql`

`\i ETUDES/script_sortir_file.sql`

`\i ETUDES/script_remplir_panier.sql`

`\i ETUDES/script_validation_transac.sql`

`\i ETUDES/script_expulsion_avant_fin_transac.sql` (Pour celui-ci se référer aux commentaires dans le fichier)

Les scripts de ces scénarios sont indépendants, aussi on les appelera sur des tables vidées et pré-remplies au préalable grâce à la commande `\i main.sql`. De plus, on pourra décommenter et commenter certaines requêtes dans ces fichiers pour tester différentes situations.
