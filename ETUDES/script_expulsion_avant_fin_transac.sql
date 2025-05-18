

SELECT entrerFileAttente('daniel@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('hyunjin@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('jaein@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('felix@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('minho@email.com', 'Tournee mondiale de Stray Kids');

SELECT verifierExpulsionsSAS(); 
SELECT basculerVersSAS();

SELECT preReserverAvecEmail('daniel@email.com','Tournee mondiale de Stray Kids', '{"CAT_3": 2, "CAT_4": 2}'::jsonb);

--attendre 1 min puis faire
/*SELECT verifierExpulsionsSAS(); 
select * from billet where statutBillet not in ('en vente');
select * from transac;
SELECT effectuerTransaction('daniel@email.com', 264);*/