-- pour tester les verrous

SELECT entrerFileAttente('daniel@email.com', 'Tournee mondiale de Stray Kids');
--à partir de là ça bloque pour empecher qu'on puisse modifier des données sensibles avec des INSERT/UPDATE/DELETE
UPDATE Billet SET prix = 2 WHERE idBillet = 520;

SELECT preReserverAvecEmail('daniel@email.com','Tournee mondiale de Stray Kids', '{"CAT_3": 2, "CAT_4": 2}'::jsonb);
--impossible de modifier une transaction depuis l'extérieur des fonctions autorisées
UPDATE Transac T
SET montant = 1.00
FROM PreReservation P
WHERE T.idPanier = P.idPanier
  AND T.statutTransaction = 'en attente'
  AND P.idUser = 9;

--d'autres verrous existent sur les différentes tables