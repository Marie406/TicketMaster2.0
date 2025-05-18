\i CREATION/creation_tables.sql
\i CREATION/fonctions_communes.sql
\i CREATION/all_triggers.sql
\i CREATION/insert_data.sql
\i ETUDES/creation_utilisateurs.sql
\i ETUDES/creation_evenements.sql
\i ETUDES/orga_concerts.sql
\i ETUDES/simulation_file_attente.sql
\i ETUDES/simu_entreeSAS_majAttendre.sql
\i ETUDES/simulation_pre-reservations.sql
\i ETUDES/validation_transaction.sql
\i ETUDES/consultation_billets_achetes.sql


--ces deux lignes à executer pour mettre à jour la situation dans Attendre et dans le SAS
SELECT verifierExpulsionsSAS();
SELECT basculerVersSAS();