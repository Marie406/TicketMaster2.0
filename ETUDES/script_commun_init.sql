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

SELECT modifier_session_vente(1, TIMESTAMP '2025-05-07 10:00:00', TIMESTAMP '2025-05-21 23:59:59', 800, FALSE, 6,4);





