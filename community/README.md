# AS Stats

Collecte des parties partagées par AS Companion et page de statistiques publique, sans base de données ni dépendance.

- `server.js` : Node seul. `POST /api/runs` (64 Ko max, 60 envois par heure par IP, 30 par installation), `DELETE /api/install/:id`, `GET /api/stats` (calculé en mémoire, cache 60 s), `GET /` et `GET /i18n.json`.
- Stockage : une ligne JSON par partie dans `data/runs-AAAA-MM.ndjson`. Les statistiques sont reconstruites au démarrage puis tenues à jour à chaque partie reçue.
- Anonymat : l'identifiant d'installation est haché (SHA-256) avant stockage, l'IP n'est jamais écrite.
- `names.json` (zones et races dans les 14 langues du jeu, pour les ramener à une clé) et `public/i18n.json` (textes de la page, classes, spés, races, zones et sorts) : générés par `node tools/community-i18n.js <dossier loc>` à partir des traductions extraites de l'exe (`tools/extract-loc.js`).

## Déploiement (VPS ZKYSolutions)

```bash
tar czf - server.js names.json nginx.conf public | ssh ludo@51.75.19.40 'tar xzf - -C /srv/www/as-stats && pm2 restart as-stats'
```

Première installation : `PORT=3040 DATA_DIR=/srv/www/as-stats/data pm2 start server.js --name as-stats --max-memory-restart 120M && pm2 save`, puis Nginx (`nginx.conf`) et certificat Let's Encrypt pour `as-stats.zkysolutions.com`.
