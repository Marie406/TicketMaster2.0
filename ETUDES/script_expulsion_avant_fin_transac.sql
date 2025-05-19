

SELECT entrerFileAttente('daniel@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('hyunjin@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('jaein@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('felix@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('minho@email.com', 'Tournee mondiale de Stray Kids');

SELECT verifierExpulsionsSAS(); 
SELECT basculerVersSAS();

SELECT preReserverAvecEmail('daniel@email.com','Tournee mondiale de Stray Kids', '{"CAT_3": 2, "CAT_4": 2}'::jsonb);

SELECT * FROM Billet WHERE statutBillet not in ('en vente');

--attendre 1 min puis faire
/*SELECT verifierExpulsionsSAS(); 
SELECT basculerVersSAS();
--le panier est vidé de ses billets
select * from billet where statutBillet not in ('en vente');
select * from transac;
SELECT * FROM SAS;
SELECT effectuerTransaction('daniel@email.com', 264);*/