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


CREATE TABLE Utilisateur(
idUser SERIAL PRIMARY KEY, 
nomUser VARCHAR(25) NOT NULL,
prenomUser VARCHAR(25) NOT NULL,
adresseUser TEXT,
dateInscription DATE NOT NULL DEFAULT CURRENT_DATE,
email VARCHAR(50) NOT NULL UNIQUE,
statutUser VARCHAR(10) CHECK (statutUser IN ('VIP', 'regular')),
ptsFidelite INTEGER NOT NULL DEFAULT 0,
CHECK (ptsFidelite>=0)
);

CREATE TABLE Concert(
idEvent SERIAL PRIMARY KEY, 
descriptionEvent TEXT NOT NULL,
niveauDemandeAttendu NUMERIC(3,2) DEFAULT 1.00,
CHECK (niveauDemandeAttendu >= 1), --pour garder des prix "raisonnables"
CHECK (niveauDemandeAttendu < 2) 
);

CREATE TABLE Calendrier (
    dateEvent DATE PRIMARY KEY
);

CREATE TABLE Lieu(
idLieu INT PRIMARY KEY,
nomLieu VARCHAR(50) NOT NULL,
adresseLieu VARCHAR NOT NULL,
capaciteAccueil INTEGER NOT NULL 
CHECK (capaciteAccueil>0)
);

CREATE TABLE CategorieSiege(
idCategorie INT PRIMARY KEY, 
nomCategorie VARCHAR(100) NOT NULL,
capaciteCategorie INTEGER NOT NULL
CHECK (capaciteCategorie >0), 
idLieu INT REFERENCES Lieu(idLieu) ON DELETE CASCADE
);

CREATE TABLE Siege (
    idSiege INT PRIMARY KEY,
    numSiege INTEGER NOT NULL,
    idCategorie INT REFERENCES CategorieSiege(idCategorie) ON DELETE CASCADE
);

CREATE TABLE AvoirLieu (
    dateEvent DATE REFERENCES Calendrier(dateEvent) ON DELETE CASCADE,
    idEvent INT REFERENCES Concert(idEvent) ON DELETE CASCADE,
    idLieu INT REFERENCES Lieu(idLieu) ON DELETE CASCADE,
    heure TIME NOT NULL,
    PRIMARY KEY (dateEvent, idEvent, idLieu)
);

CREATE TABLE Grille (
    idEvent INT REFERENCES Concert(idEvent) ON DELETE CASCADE,
    idCategorie INT REFERENCES CategorieSiege(idCategorie) ON DELETE CASCADE,
    prix NUMERIC(10,2) NOT NULL CHECK (prix > 0),
    PRIMARY KEY (idEvent, idCategorie)
);


CREATE TABLE Artiste (
    idArtiste SERIAL PRIMARY KEY,
    nomArtiste VARCHAR(255) NOT NULL,
    styleMusique VARCHAR(100),
    UNIQUE(nomArtiste)
);

CREATE TABLE Participe (
    idEvent INT REFERENCES Concert(idEvent) ON DELETE CASCADE,
    idArtiste INT REFERENCES Artiste(idArtiste) ON DELETE CASCADE,
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
    idEvent INT REFERENCES Concert(idEvent) ON DELETE CASCADE,
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
    prix NUMERIC(10,2) NOT NULL,
    idSiege INT REFERENCES Siege(idSiege) ON DELETE CASCADE, --à modifier ds pdf
    dateEvent DATE REFERENCES Calendrier(dateEvent) ON DELETE CASCADE,
    idEvent INT REFERENCES Concert(idEvent) ON DELETE CASCADE,
    idPanier INTEGER REFERENCES PreReservation(idPanier) ON DELETE SET NULL,
    idSession INTEGER REFERENCES SessionVente(idSession) ON DELETE SET NULL
);
