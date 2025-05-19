
--test avec une file d'attente ouvert
SELECT entrerFileAttente('daniel@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('hyunjin@email.com', 'Tournee mondiale de Stray Kids');

--test qui verifie qu'un même utilisateur ne peut pas entrer dans une file qu'il fait déjà
SELECT entrerFileAttente('felix@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('felix@email.com', 'Tournee mondiale de Stray Kids');

--test avec file attente fermée
--impossible d'entrer
SELECT entrerFileAttente('sehun@email.com', 'Concert de Billie Eilish');

--test avec evenement introuvable -> file attente inexistante
--impossible d'entrer
SELECT entrerFileAttente('eunji@email.com', 'Epik High concert');

SELECT * FROM FileAttente;
SELECT * FROM Attendre;