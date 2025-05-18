CREATE INDEX idx_avoirlieu_date_lieu_heure ON AvoirLieu(dateEvent, idLieu, heure);

CREATE INDEX idx_billet_statut_event_session ON Billet(statutBillet, idEvent, idSession);

CREATE INDEX idx_billet_panier ON Billet(idPanier);

CREATE INDEX idx_categorie_idlieu ON CategorieSiege(idLieu);

CREATE INDEX idx_prereservation_user ON PreReservation(idUser);

CREATE INDEX idx_billet_statut ON Billet(statutBillet);

CREATE INDEX idx_billet_idsiege ON Billet(idSiege);

CREATE INDEX idx_transac_panier ON Transac(idPanier);

CREATE INDEX idx_sas_status ON SAS(statusSAS);

CREATE INDEX idx_fileattente_sessionvente ON FileAttente(idSessionVente);
