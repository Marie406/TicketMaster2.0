

SELECT entrerFileAttente('daniel@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('hyunjin@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('jaein@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('felix@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('minho@email.com', 'Tournee mondiale de Stray Kids');

--toutes les 1 minutes on peut expulser qqun du sas en utilisant cette requête
SELECT verifierExpulsionsSAS(); 
--met l'utilisateur en tete de la file dans le sas pour l'autoriser à remplir son panier
SELECT basculerVersSAS();

SELECT preReserverAvecEmail('daniel@email.com','Tournee mondiale de Stray Kids', '{"CAT_3": 2, "CAT_4": 2}'::jsonb);

-- simulation de tentatives de paiement de transactions avec différents montants

--test qd on est en position de faire une transaction et qu'on donne un montant suffisant
SELECT effectuerTransaction('daniel@email.com', 264);

-- test montant insuffisant
--SELECT effectuerTransaction('daniel@email.com', 60);

--test pas de transaction en attente
--SELECT effectuerTransaction('hyunjin@email.com', 400);

select * from billet where statutBillet not in ('en vente');
select * from transac;


SELECT verifierExpulsionsSAS(); 
SELECT basculerVersSAS();

SELECT preReserverAvecEmail('hyunjin@email.com','Tournee mondiale de Stray Kids','{"CAT_1": 2, "CAT_2": 1, "CAT_3":1}'::jsonb);

select * from billet where statutBillet not in ('en vente');
select * from transac;

SELECT effectuerTransaction('hyunjin@email.com', 435);

--8. visualisation de tous les billets reservés pour un utilisateur
SELECT * FROM afficher_billets_par_email('daniel@email.com');

--8. visualisation de tous les billets reservés pour un utilisateur
SELECT * FROM afficher_billets_par_email('hyunjin@email.com');