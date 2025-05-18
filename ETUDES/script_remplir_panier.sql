
SELECT entrerFileAttente('daniel@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('jaein@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('hyunjin@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('felix@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('minho@email.com', 'Tournee mondiale de Stray Kids');

--toutes les 1 minutes on peut expulser qqun du sas en utilisant cette requête
SELECT verifierExpulsionsSAS(); 
--met l'utilisateur en tete de la file dans le sas pour l'autoriser à remplir son panier
SELECT basculerVersSAS();

-- simulation ajout des billets ds panier
--test avec un nb de billets raisonnable et pour un utilisateur qui est dans le sas
SELECT preReserverAvecEmail('daniel@email.com','Tournee mondiale de Stray Kids', '{"CAT_3": 2, "CAT_4": 2}'::jsonb);

--test nb de billets trop élevé pr statut
--SELECT preReserverAvecEmail('daniel@email.com','Tournee mondiale de Stray Kids','{"CAT_3": 3, "CAT_4": 4}'::jsonb);

--test utilisateur dans la file mais pas encore dans le sas
--SELECT preReserverAvecEmail('hyunjin@email.com','Tournee mondiale de Stray Kids','{"CAT_1": 2, "CAT_2": 1, "CAT_3":1}'::jsonb);

select * from prereservation;
select * from billet where statutBillet not in ('en vente');