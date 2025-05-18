--1. création des utilisateurs
SELECT creer_utilisateur('Kim', 'Jisoo', '14 rue de Séoul', 'jisoo@email.com', 'VIP', 120);
SELECT creer_utilisateur('Park', 'Jimin', '23 avenue des Idoles', 'jimin@email.com', 'VIP', 150);
SELECT creer_utilisateur('Choi', 'Soojin', '45 boulevard des Fans', 'soojin@email.com', 'regular', 30);
SELECT creer_utilisateur('Lee', 'Minho', '78 rue des Concerts', 'minho@email.com', 'regular', 60);
SELECT creer_utilisateur('Jeon', 'Jungkook', '5 place du Kpop', 'jungkook@email.com', 'VIP', 180);
SELECT creer_utilisateur('Hwang', 'Hyunjin', '3 avenue Hallyu', 'hyunjin@email.com', 'regular', 90);
SELECT creer_utilisateur('Seo', 'Jaein', '9 rue du Han', 'jaein@email.com', 'regular', 45);
SELECT creer_utilisateur('Yoo', 'Nari', '32 rue du Flow', 'nari@email.com', 'VIP', 200);
SELECT creer_utilisateur('Han', 'Seungmin', '56 place des Tickets', 'seungmin@email.com', 'regular', 55);
SELECT creer_utilisateur('Kang', 'Daniel', '11 allée des Stages', 'daniel@email.com', 'VIP', 210);
SELECT creer_utilisateur('Im', 'Nayeon', '18 rue de la Pop', 'nayeon@email.com', 'VIP', 160);
SELECT creer_utilisateur('Kim', 'Seokjin', '33 rue du Micro', 'seokjin@email.com', 'regular', 75);
SELECT creer_utilisateur('Oh', 'Sehun', '7 boulevard du Fandom', 'sehun@email.com', 'regular', 50);
SELECT creer_utilisateur('Ahn', 'Yujin', '21 chemin du Lightstick', 'yujin@email.com', 'VIP', 170);
SELECT creer_utilisateur('Shin', 'Ryujin', '13 rue du Soundcheck', 'ryujin@email.com', 'regular', 40);
SELECT creer_utilisateur('Lee', 'Felix', '22 avenue des Backstages', 'felix@email.com', 'VIP', 130);
SELECT creer_utilisateur('Bang', 'Chan', '91 passage des Fansigns', 'chan@email.com', 'VIP', 195);
SELECT creer_utilisateur('Kim', 'Taehyung', '6 ruelle des Bias', 'taehyung@email.com', 'VIP', 220);
SELECT creer_utilisateur('Moon', 'Bin', '16 rue de la Scène', 'bin@email.com', 'regular', 65);
SELECT creer_utilisateur('Jung', 'Eunji', '2 avenue des Harmonies', 'eunji@email.com', 'regular', 70);

SELECT * FROM Utilisateur;

--2. ajout des artistes pour l'evenement
SELECT ajouter_artiste('Taemin', 'Kpop');
SELECT ajouter_artiste('GOT7', 'Kpop');

-- permet de vérifier que Stray Kids n'est pas ajouté qd il a déjà été créer 
--via les donnees du csv , que BewhY est bien crée et que les ajouts
-- d'artistes de la fct ajouter_artiste fonctionnent 
-- permet aussi de verif qu'on peut bien ajouter plusieurs artistes à un concert
-- 3. création des evenements 
SELECT creer_evenement('Concert evenement BewhY', ARRAY['BewhY'], 1.0);
SELECT creer_evenement('Tournee japonaise de Taemin', ARRAY['Taemin'], 1.4);
SELECT creer_evenement('Promotion nouveau single de GOT7', ARRAY['GOT7'], 1.5);
SELECT creer_evenement('Concert en France de Stray Kids', ARRAY['Stray Kids'], 1.6);
SELECT creer_evenement('Gala des Pieces jaunes 2026', ARRAY['GDragon', 'GOT7', 'Stray Kids', 'BewhY'], 1.3);

SELECT * FROM Participe;


--organisation des concerts avec date, lieu et heure
SELECT organiser_concert('Tournee japonaise de Taemin', DATE '2025-07-12', 17, TIME '19:30');
SELECT organiser_concert('Tournee japonaise de Taemin', DATE '2025-07-19', 18, TIME '20:30');
SELECT organiser_concert('Tournee japonaise de Taemin', DATE '2025-07-22', 16, TIME '20:00');
SELECT organiser_concert('Concert en France de Stray Kids', DATE '2025-07-22', 1, TIME '19:30');

SELECT * FROM AvoirLieu;

--4. simu file attente
--test avec une file d'attente ouverte
SELECT modifier_session_vente(1, TIMESTAMP '2025-05-07 10:00:00', TIMESTAMP '2025-05-21 23:59:59', 800, FALSE, 6,4);
SELECT entrerFileAttente('daniel@email.com', 'Tournee mondiale de Stray Kids');
SELECT entrerFileAttente('hyunjin@email.com', 'Tournee mondiale de Stray Kids');
--SELECT * FROM FileAttente;
--SELECT * FROM Attendre;

--test qui verifie qu'un mm utilisateur peut pas entrer dans une file qu'il fait déja
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

--tester de remplir une file attente et d'ajouter des gens derriere

--test sortir de la file
--SELECT sortirFileAttente('felix@email.com', 'Tournee mondiale de Stray Kids');
--SELECT * FROM FileAttente;
--SELECT * FROM Attendre;

--5. sortie de fileAttente et entrée dans le sas où préreservation possible
SELECT verifierExpulsionsSAS();
SELECT basculerVersSAS();


--6. simulation ajout des billets ds panier
--test avec un nb de billets raisonnable et pour un utilisateur qui est dans le sas
SELECT preReserverAvecEmail('daniel@email.com','{"CAT_3": 2, "CAT_4": 2}'::jsonb);

--test nb de billets trop élevé pr statut
--SELECT preReserver('daniel@email.com','Tournee mondiale de Stray Kids','{"CAT_3": 3, "CAT_4": 4}'::jsonb);

--test utilisateur dans la file mais pas encore dans le sas
--SELECT preReserver('hyunjin@email.com','Tournee mondiale de Stray Kids','{"CAT_1": 2, "CAT_2": 1, "CAT_3":1}'::jsonb);

--tester qd nb billets coherent avec limite fixé par la sessionVente mais les stocks sont insuffisants

select * from prereservation;
select * from billet where statutBillet not in ('en vente');

--au bout de 2min+ faire ça puis effectuer transaction pour montrer que impossible car trop tard
--SELECT verifierExpulsionsSAS();
--SELECT basculerVersSAS();

--7. simulation de tentatives de paiement de transactions avec différents montants

--test qd on est en position de faire une transaction et qu'on donne un montant suffisant
SELECT effectuerTransaction('daniel@email.com', 264);

-- test montant insuffisant
--SELECT effectuerTransaction('daniel@email.com', 60);

--test pas de transaction en attente
--SELECT effectuerTransaction('hyunjin@email.com', 400);

select * from billet where statutBillet not in ('en vente');
select * from transac;

--8. visualisation de tous les billets reservés pour un utilisateur
SELECT * FROM afficher_billets_par_email('daniel@email.com');



--ces deux lignes à executer pour mettre à jour la situation dans Attendre et dans le SAS
--SELECT verifierExpulsionsSAS();
--SELECT basculerVersSAS();