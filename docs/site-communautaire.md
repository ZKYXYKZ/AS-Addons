# Site communautaire Azeroth Survivors

Projet préparé le 27/10/2026, rien n'est encore installé sur le VPS.

## Objectif

Un site public qui rassemble les parties des joueurs qui le souhaitent, pour savoir ce qui marche vraiment :

- meilleures parties par zone et par difficulté (Normal, Héroïque I à V) ;
- classes, spés et races comparées : taux de victoire, durée de survie, DPS à 5, 10, 15 et 20 minutes ;
- builds les plus joués et les plus efficaces, importables en un clic dans le compagnon (code `SB1;…`) ;
- sorts et bijoux : part des dégâts, fréquence de prise, effet des légendaires et des améliorations ;
- fiche d'une partie : courbe de DPS et de dégâts subis minute par minute, cartes prises, équipement.

## Architecture

```
AS Companion (option « Partager mes parties », désactivée par défaut)
        │  POST https://<sous-domaine>/api/runs   (résumé JSON, voir plus bas)
        ▼
Nginx (VPS 51.75.19.40, HTTPS Let's Encrypt)
        ▼
Nuxt 3 (Nitro, pm2) dans /srv/www/as-community
   ├─ server/api/*      réception, validation, lecture des statistiques
   ├─ pages/*           site public
   └─ SQLite (better-sqlite3), sauvegarde quotidienne comme les autres sites
```

Un seul service Nuxt pour l'API et le site, comme les sites déjà hébergés. SQLite suffit pour quelques milliers de parties par jour ; le passage à PostgreSQL resterait possible sans changer l'API.

## Données envoyées par le compagnon

Une partie = un résumé, envoyé à la fin de la partie (victoire, défaite ou abandon). Aucun pseudo, aucun chemin, aucune adresse.

```json
{
  "v": 1,
  "client": "1.7.28",
  "game": "0.120.5",
  "install": "uuid aléatoire tiré une fois, pour compter les joueurs sans les identifier",
  "class": "mage", "race": "gnome", "spec": 1,
  "zone": "naxx", "difficulty": 0,
  "result": "victory", "time": 1210, "level": 57, "kills": 24261,
  "dps": 242862, "damage": 293000000, "taken": 21400,
  "talents": "0515135000000/5025123315031/0000000000000",
  "build": "SB1;mage;…",
  "minutes": [ { "dps": 5000, "taken": 97, "level": 4 } ],
  "spells": { "pyroblast": { "rank": 19, "share": 0.66 } },
  "jewels": { "rings": ["accuria:10", "dragonslayer:8"], "trinkets": ["blackhand:8", "chosen:5"], "amulet": "leg:pyroblast:3" },
  "picks": [ { "t": 64, "kind": "levelup", "took": "pyroblast", "rarity": 2 } ]
}
```

Tout existe déjà côté compagnon (fichiers `research`, `runs.json`) sauf la difficulté, que le jeu n'annonce pas encore au début de la partie.

## Pages

| Page | Contenu |
| --- | --- |
| Accueil | dernières victoires, records par zone, nombre de parties et de joueurs |
| Classements | meilleures parties par zone et difficulté, filtres classe, spé, race |
| Classes | pour chaque classe et spé : victoires, survie médiane, DPS par minute, races |
| Builds | builds regroupés par talents et sorts, résultats, bouton « Copier pour le compagnon » |
| Sorts et bijoux | part des dégâts, taux de prise, progression des améliorations |
| Partie | courbes minute par minute, cartes prises, équipement |
| À propos | ce qui est collecté, comment l'activer ou le couper, suppression sur demande |

## API

| Méthode | Route | Rôle |
| --- | --- | --- |
| POST | `/api/runs` | recevoir une partie (taille limitée, schéma validé, limite par installation) |
| GET | `/api/runs/:id` | une partie |
| GET | `/api/leaderboard?zone=&difficulty=&class=` | classements |
| GET | `/api/stats/classes`, `/api/stats/builds`, `/api/stats/spells` | agrégats, mis en cache |
| DELETE | `/api/install/:install` | effacer toutes les parties d'une installation (bouton dans le compagnon) |

## Compagnon

- Option « Partager mes parties » activée par défaut, désactivable dans les options (« Vos parties améliorent ce compagnon »), message affiché une fois au premier lancement.
- Envoi en tâche de fond à la fin de la partie, nouvel essai plus tard si le serveur ne répond pas, jamais pendant une partie.
- Bouton « Supprimer mes parties partagées ».
- Le README devra remplacer « pas de télémétrie » par la description de cette option.

## Déploiement sur le VPS

Même méthode que les sites existants :

1. `/srv/www/as-community`, build Nuxt (`.output`) envoyé depuis le PC ou construit sur place ;
2. `pm2 start .output/server/index.mjs --name as-community`, port local dédié ;
3. bloc Nginx pour le sous-domaine, certificat Let's Encrypt ;
4. base SQLite dans `/srv/www/as-community/data`, sauvegarde quotidienne avec les autres.

## Étapes

1. Réception seule : `POST /api/runs` + stockage, option dans le compagnon, page « À propos ».
2. Classements et fiches de partie.
3. Statistiques par classe, spé, race et build.
4. Import d'un build en un clic, comparaison avec le simulateur.

## À décider

- Sous-domaine et création du DNS.
- Nom du site.
- Option désactivée par défaut (proposé) ou proposée au premier lancement.
- Durée de conservation des parties.
