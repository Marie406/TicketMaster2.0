DROP TABLE IF EXISTS Billet;
DROP TABLE IF EXISTS Reservation;
DROP TABLE IF EXISTS Transac;
DROP TABLE IF EXISTS PreReservation;
DROP TABLE IF EXISTS Attendre;
DROP TABLE IF EXISTS FileAttente;
DROP TABLE IF EXISTS SessionVente;
DROP TABLE IF EXISTS Participe;
DROP TABLE IF EXISTS Artiste;
DROP TABLE IF EXISTS Grille;
DROP TABLE IF EXISTS AvoirLieu;
DROP TABLE IF EXISTS Siege;
DROP TABLE IF EXISTS CategorieSiege;
DROP TABLE IF EXISTS Lieu;
DROP TABLE IF EXISTS Calendrier;
DROP TABLE IF EXISTS Concert;
DROP TABLE IF EXISTS Utilisateur;

--à voir si on met des SERIAL ou pas pour les tables qui peuvent
-- être considérées comme créées quand on fait les simulations 
--de file et d'achat

CREATE TABLE Utilisateur(
idUser SERIAL PRIMARY KEY, 
nomUser VARCHAR(25) NOT NULL,
prenomUser VARCHAR(25) NOT NULL,
dateInscription DATE NOT NULL DEFAULT CURRENT_DATE,
email VARCHAR(50) NOT NULL UNIQUE,
adresseUser TEXT,
statutUser VARCHAR(10) CHECK (statutUser IN ('VIP', 'regular')),
ptsFidelite INTEGER NOT NULL DEFAULT 0,
CHECK (ptsFidelite>=0)
);

CREATE TABLE Concert(
idEvent VARCHAR(15) PRIMARY KEY, 
descriptionEvent TEXT NOT NULL
);

CREATE TABLE Calendrier (
    dateEvent DATE PRIMARY KEY
);

CREATE TABLE Lieu(
idLieu SERIAL PRIMARY KEY,
nomLieu VARCHAR(50) NOT NULL,
adresseLieu VARCHAR NOT NULL,
capaciteAccueil INTEGER NOT NULL 
CHECK (capaciteAccueil>0)
);

CREATE TABLE CategorieSiege(
idCategorie SERIAL PRIMARY KEY, 
nomCategorie VARCHAR(100) NOT NULL,
capaciteCategorie INTEGER NOT NULL
CHECK (capaciteCategorie >0), 
idLieu INTEGER REFERENCES Lieu(idLieu) ON DELETE CASCADE
);

CREATE TABLE Siege (
    idSiege SERIAL PRIMARY KEY,
    numSiege INTEGER NOT NULL,
    idCategorie INTEGER REFERENCES CategorieSiege(idCategorie) ON DELETE CASCADE
);

CREATE TABLE AvoirLieu (
    dateEvent DATE REFERENCES Calendrier(dateEvent) ON DELETE CASCADE,
    idEvent VARCHAR REFERENCES Concert(idEvent) ON DELETE CASCADE,
    idLieu INTEGER REFERENCES Lieu(idLieu) ON DELETE CASCADE,
    heure TIME NOT NULL,
    PRIMARY KEY (dateEvent, idEvent, idLieu)
);

CREATE TABLE Grille (
    idEvent VARCHAR REFERENCES Concert(idEvent) ON DELETE CASCADE,
    idCategorie INTEGER REFERENCES CategorieSiege(idCategorie) ON DELETE CASCADE,
    prix NUMERIC(10,2) NOT NULL CHECK (prix > 0),
    PRIMARY KEY (idEvent, idCategorie)
);


CREATE TABLE Artiste (
    idArtiste VARCHAR(20) PRIMARY KEY,
    nomArtiste VARCHAR(255) NOT NULL,
    styleMusique VARCHAR(100)
);

CREATE TABLE Participe (
    idEvent VARCHAR REFERENCES Concert(idEvent) ON DELETE CASCADE,
    idArtiste VARCHAR REFERENCES Artiste(idArtiste) ON DELETE CASCADE,
    PRIMARY KEY (idEvent, idArtiste)
);

CREATE TABLE SessionVente (
    idSession SERIAL PRIMARY KEY,
    dateDebutSession TIMESTAMP NOT NULL,
    dateFinSession TIMESTAMP NOT NULL,
    nbBilletsMisEnVente INTEGER NOT NULL CHECK (nbBilletsMisEnVente > 0),
    onlyVIP BOOLEAN NOT NULL,
    nbMaxBilletsAchetesVIP INTEGER NOT NULL CHECK (nbMaxBilletsAchetesVIP >= 0),
    nbMaxBilletsAchetesRegular INTEGER NOT NULL CHECK (nbMaxBilletsAchetesRegular >= 0),
    idEvent VARCHAR REFERENCES Concert(idEvent) ON DELETE CASCADE,
    CHECK (dateDebutSession < dateFinSession)
);


CREATE TABLE FileAttente (
    idQueue SERIAL PRIMARY KEY,
    capaciteQueue INTEGER NOT NULL CHECK (capaciteQueue > 0),
    idSessionVente INTEGER REFERENCES SessionVente(idSession) ON DELETE CASCADE
);

CREATE TABLE Attendre (
    idQueue INTEGER REFERENCES FileAttente(idQueue) ON DELETE CASCADE,
    idUser INTEGER REFERENCES Utilisateur(idUser) ON DELETE CASCADE,
    rang INTEGER NOT NULL,
    PRIMARY KEY (idQueue, idUser),
    UNIQUE (idQueue, rang) -- Un rang ne peut être occupé que par un seul utilisateur
);


CREATE OR REPLACE FUNCTION check_rang_valid() RETURNS TRIGGER AS $$
DECLARE
    max_capacity INT;
BEGIN
    SELECT capaciteQueue INTO max_capacity FROM FileAttente WHERE idQueue = NEW.idQueue;

    IF NEW.rang < 0 OR NEW.rang >= max_capacity THEN
        RAISE EXCEPTION 'Le rang % est invalide. Il doit etre entre 0 et %', NEW.rang, max_capacity - 1;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création du trigger pour vérifier `rang`
CREATE TRIGGER trg_check_rang
BEFORE INSERT OR UPDATE ON Attendre
FOR EACH ROW
EXECUTE FUNCTION check_rang_valid();


CREATE TABLE PreReservation (
    idPanier SERIAL PRIMARY KEY,
    dateHeureCreation TIMESTAMP NOT NULL DEFAULT NOW(),
    idUser INTEGER REFERENCES Utilisateur(idUser) ON DELETE CASCADE,
    idSession INTEGER REFERENCES SessionVente(idSession) ON DELETE CASCADE
);


CREATE TABLE Transac (
    idTransaction SERIAL PRIMARY KEY,
    dateTransaction TIMESTAMP NOT NULL DEFAULT NOW(),
    montant NUMERIC(10,2) NOT NULL CHECK (montant > 0),
    statutTransaction VARCHAR(50) CHECK (statutTransaction IN ('en attente', 'validé', 'annulé')),
    idPanier INTEGER REFERENCES PreReservation(idPanier) ON DELETE CASCADE
);


CREATE TABLE Reservation (
    idReservation SERIAL PRIMARY KEY,
    dateReservation TIMESTAMP NOT NULL DEFAULT NOW(),
    idUser INTEGER REFERENCES Utilisateur(idUser) ON DELETE CASCADE,
    idTransaction INTEGER REFERENCES Transac(idTransaction) ON DELETE CASCADE
);

--les ON DELETE SET NULL c'est parce que le billet continue d'exister même 
--si une session de vente est annulée ou si un panier est effacé de la BD
CREATE TABLE Billet (
    idBillet SERIAL PRIMARY KEY,
    statutBillet VARCHAR(50) CHECK (statutBillet IN ('en vente', 'dans un panier', 'vendu')),
    numSiege INTEGER REFERENCES Siege(idSiege) ON DELETE CASCADE,
    dateEvent DATE REFERENCES Calendrier(dateEvent) ON DELETE CASCADE,
    idEvent VARCHAR REFERENCES Concert(idEvent) ON DELETE CASCADE,
    idPanier INTEGER REFERENCES PreReservation(idPanier) ON DELETE SET NULL,
    idSession INTEGER REFERENCES SessionVente(idSession) ON DELETE SET NULL
);
