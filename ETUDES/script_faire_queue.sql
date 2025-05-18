-- simu file attente

--test avec une file d'attente ouvert
SELECT entrerFileAttente('daniel@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('hyunjin@email.com', 'Tournee mondiale de Stray Kids');
SELECT * FROM FileAttente;
SELECT * FROM Attendre;

--test qui verifie qu'un même utilisateur ne peut pas entrer dans une file qu'il fait déjà
SELECT entrerFileAttente('felix@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('felix@email.com', 'Tournee mondiale de Stray Kids');
--SELECT * FROM FileAttente;
--SELECT * FROM Attendre;

--test avec file attente fermée
SELECT entrerFileAttente('sehun@email.com', 'Concert de Billie Eilish');
--SELECT * FROM FileAttente;
--SELECT * FROM Attendre;

--test avec evenement introuvable -> file attente inexistante
SELECT entrerFileAttente('eunji@email.com', 'Epik High concert');
--SELECT * FROM FileAttente;
--SELECT * FROM Attendre;

