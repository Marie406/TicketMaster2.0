
--à executer souvent (ttes les deux minutes pr simuler un vrai timer vu que le temps max ds le sas est 2 min)
CREATE OR REPLACE FUNCTION verifierExpulsionsSAS()
RETURNS VOID AS $$
BEGIN
    PERFORM set_config('myapp.allow_modify_sas', 'on', true);
    UPDATE SAS
    SET statusSAS = 'expulse', sortieSAS = now()
    WHERE statusSAS = 'en cours'
    AND now() > entreeSAS + timeoutSAS;
    PERFORM set_config('myapp.allow_modify_sas', 'off', true);
END;
$$ LANGUAGE plpgsql;

--met tt les utilisateurs des diff files qui sont rang = 1 dans le sas si ceux
--de leurs files qui étaient dans le sas ont fini/ont été expulsés
CREATE OR REPLACE FUNCTION basculerVersSAS()
RETURNS VOID AS $$
DECLARE
    u_id INT;
    q_id INT;
    user_in_sas INT;
BEGIN
    -- Sélectionner l'utilisateur avec rang = 1 dans chaque file
    FOR q_id IN SELECT DISTINCT idQueue FROM Attendre LOOP
        -- Vérifier que l'utilisateur avec rang = 1 dans la file n'est pas déjà dans SAS
        SELECT idUser INTO u_id
        FROM Attendre
        WHERE idQueue = q_id AND rang = 1;

        -- Vérifier si l'utilisateur est déjà dans le SAS
        SELECT COUNT(1) INTO user_in_sas
        FROM SAS
        WHERE idQueue = q_id AND statusSAS = 'en cours';

        -- Si l'utilisateur est numéro 1 et aucun utilisateur dans le SAS pour cette file
        IF user_in_sas = 0 THEN
            -- Ajouter l'utilisateur dans SAS
            PERFORM set_config('myapp.allow_create_sas', 'on', true);
            INSERT INTO SAS(idUser, idQueue) VALUES (u_id, q_id);
            RAISE NOTICE 'Utilisateur % ajouté dans le SAS pour la file %.', u_id, q_id;
            PERFORM set_config('myapp.allow_create_sas', 'off', true);

            -- Supprimer l'utilisateur de la table Attendre
            DELETE FROM Attendre
            WHERE idQueue = q_id AND idUser = u_id;

            -- Avancer le rang de tous les utilisateurs suivants dans la file
            PERFORM set_config('myapp.allow_modify_attendre', 'on', true);
            UPDATE Attendre
            SET rang = rang - 1
            WHERE idQueue = q_id AND rang > 1;
            PERFORM set_config('myapp.allow_modify_attendre', 'off', true);

        ELSE
            RAISE NOTICE 'La file % a déjà un utilisateur dans le SAS, l''utilisateur % ne peut pas entrer.', q_id, u_id;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

--ces deux lignes à executer pour mettre à jour la situation dans Attendre et dans le SAS
SELECT verifierExpulsionsSAS();
SELECT basculerVersSAS();
