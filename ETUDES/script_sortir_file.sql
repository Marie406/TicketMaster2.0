

--test sortir de la file

SELECT entrerFileAttente('jaein@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('hyunjin@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('felix@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('daniel@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('minho@email.com', 'Tournee mondiale de Stray Kids');

SELECT * FROM FileAttente;
SELECT * FROM Attendre;

SELECT sortirFileAttente('felix@email.com', 'Tournee mondiale de Stray Kids');
SELECT * FROM FileAttente;
SELECT * FROM Attendre;