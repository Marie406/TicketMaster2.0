CHANEAC Marie, parcours : LP, num étudiant : 22400026;  
RIBEIRO MARQUES Marie-Lou, parcours : MIC, num étudiant : 22414541;

Guide d'utilisation :
Depuis le répertoire du projet :
-lancer un terminal et se connecter à psql et à une base de données dédiée au projet
-exécuter les commandes dans l'ordre suivant :
\i CREATION/creation_tables.sql
\i CREATION/create_triggers.sql
\i CREATION/insert_data.sql

-ensuite le fichier gestion_files.sql est à exécuter avec la commande
\i CREATION/gestion_files.sql
il est responsable de la création et suppressions des files d'attente en fonction des dates debut/fin des sessions de ventes, donc pour le tester il faut créer des sessions de ventes dans sessions_ventes.csv aux horaires où on teste, on pourrait automatiser les suppressions et créations mais comme elles dépendent des heures il y a différentes techniques supportées par différents système d'exploitations et comme on a pas les mêmes et qu'on sait pas ce que les profs utilisent non plus... l'autre option c'est créer les files avant l'heure avec un trigger (voir com ds create_triggers) et ne pas les supprimer non plus, et creer une vue qui ne montre que les files "actives" mais faut voir si ça bloque les utilisateurs qui essaient d'entrer dans une files inactive ou pas 