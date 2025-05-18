CREATE OR REPLACE FUNCTION charger_lieux()
RETURNS void AS $$
BEGIN
    COPY Lieu(idLieu, nomLieu, adresseLieu, capaciteAccueil)
    FROM '/home/marielou/projet_bda_m1/CREATION/bdd/lieux.csv'
    WITH (
         FORMAT csv,
         DELIMITER ';',
         HEADER true
    );
END;
$$ LANGUAGE plpgsql;

SELECT charger_lieux();
