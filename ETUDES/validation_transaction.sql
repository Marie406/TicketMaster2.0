-- sous l'hypothese qu'il y a qu'une transaction en cours par utilisateur
CREATE OR REPLACE FUNCTION effectuerTransaction(emailUser TEXT, montant_utilisateur NUMERIC)
RETURNS VOID AS $$
DECLARE
    userId INT;
    panierId INT;
    montant_transac NUMERIC;
BEGIN
    -- 1. Récupérer l'id de l'utilisateur
    userId := getUserIdByEmail(emailUser);

    IF userId IS NULL THEN
        RAISE EXCEPTION 'Aucun utilisateur trouvé avec cet email.';
    END IF;

    -- 2. Trouver l'idPanier de la transaction en attente pour cet utilisateur
    SELECT t.idPanier, t.montant INTO panierId, montant_transac
    FROM Transac t
    JOIN PreReservation p ON t.idPanier = p.idPanier
    WHERE t.statutTransaction = 'en attente'
      AND p.idUser = userId
    LIMIT 1;

    IF panierId IS NULL THEN
        RAISE EXCEPTION 'Aucune transaction en attente trouvée pour cet utilisateur.';
    END IF;

    -- 3. Vérifier que le montant est suffisant
    IF montant_utilisateur < montant_transac THEN
        -- Annuler la transaction en attente

        PERFORM set_config('myapp.allow_modify_transac', 'on', true);
        UPDATE Transac
        SET statutTransaction = 'annulé'
        WHERE idPanier = panierId
        AND statutTransaction = 'en attente';
        PERFORM set_config('myapp.allow_modify_transac', 'off', true);

        -- Créer une nouvelle transaction en attente
        PERFORM set_config('myapp.allow_create_transac', 'on', true);
        INSERT INTO Transac (montant, statutTransaction, idPanier)
        VALUES (montant_transac, 'en attente', panierId);
        PERFORM set_config('myapp.allow_create_transac', 'off', true);
        RAISE NOTICE 'Montant insuffisant. Requis : %, fourni : %. Nouvelle transaction créée en attente.', montant_transac, montant_utilisateur;
    ELSE
        -- Valider la transaction
        PERFORM set_config('myapp.allow_modify_transac', 'on', true);
        UPDATE Transac
        SET statutTransaction = 'validé'
        WHERE idPanier = panierId
          AND statutTransaction = 'en attente';
        PERFORM set_config('myapp.allow_modify_transac', 'off', true);

        RAISE NOTICE 'Transaction validée pour le panier %, utilisateur %', panierId, userId;
    END IF;
END;
$$ LANGUAGE plpgsql;


--test qd on est en position de faire une transaction et qu'on donne un montant suffisant
SELECT effectuerTransaction('daniel@email.com', 264);
--pr verif que ça fait bien ce qu'on veut
--select * from billet where statutBillet not in ('en vente', 'dans un panier');
--select * from transaction;

-- test montant insuffisant
--SELECT effectuerTransaction('daniel@email.com', 60);

--test pas de transaction en attente
--SELECT effectuerTransaction('hyunjin@email.com', 400);
