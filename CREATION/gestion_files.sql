--fichier à executer à différents moments en fonction des dates dans SessionVentes

-- Crée les files d’attente uniquement si :
-- - la session a commencé (dateDebutSession <= NOW())
-- - la session n’est pas encore terminée (NOW() <= dateFinSession)
-- - la file n’existe pas déjà
INSERT INTO FileAttente (capaciteQueue, idSessionVente)
SELECT 
    -- Appliquer un plafond ds la file attente à 2000
    -- au cas où capacitee_estimee est bcp trop grand 
    --et risquerait de faire crasher le serveur irl
    LEAST(CEIL(nbBilletsMisEnVente::DECIMAL / NULLIF(nbMaxBilletsAchetesVIP, 1)), 2000),
    idSession
FROM SessionVente
--ne créer la file que si on est dans la période de la session de vente
WHERE dateDebutSession <= NOW()
  AND NOW() <= dateFinSession
  AND idSession NOT IN (
    SELECT idSessionVente FROM FileAttente
);

-- Supprime les files d’attente pour les sessions terminées
DELETE FROM FileAttente
WHERE idSessionVente IN (
    SELECT idSession FROM SessionVente
    WHERE dateFinSession < NOW()
);
