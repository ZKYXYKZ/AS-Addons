# Addons Azeroth Survivors

Sources des addons : ce dossier. Le jeu ne lit pas ce dossier, il lit `C:\Git\wenilla\benilla-config\AddOns` (chemin de dev codé en dur dans l'exe, déplaçable avec la variable `BENILLA_HOME`).

## Ce que le jeu supporte

- Addons WoW 1.12 : `.toc` avec `## Interface: 11200`, Lua 5.0 (`table.getn`, `this`, `event`, `arg1`), API de widgets complète.
- Les addons se chargent au début d'une run. Variables sauvegardées écrites dans `<home>\saved\<Addon>.lua` à la fermeture propre du jeu.
- `hooksecurefunc` et `UnitPosition` n'existent pas.
- HUD natif hors de portée du Lua : timer, « next boss », Kills/Gold/cache, compteur de dégâts, rangée d'icônes de sorts en haut à gauche.

## Données utiles

- Gardiens (mini-boss) : `GetMapLandmarkInfo(i)` renvoie `"<Nom> (Guardian)"` vivant, `"<Nom>'s lair (empty)"` mort, avec x/y de carte. Appeler `SetMapToCurrentZone()` avant.
- Position joueur : `GetPlayerMapPosition("player")`.
- Stats de run : événement `CHAT_MSG_ADDON`, préfixe `AZS`, format `cle=valeur;`.
- Annonces : `CHAT_MSG_RAID_BOSS_EMOTE` et `CHAT_MSG_SYSTEM`.

## Tester sans toucher à la partie du joueur

Variables d'environnement lues par l'exe :

- `BENILLA_HOME` : dossier de config isolé (contient `AddOns`, `saved`).
- `WOW_ROGUE_SAVE` : fichier de sauvegarde séparé.
- `WOW_ROGUE_AUTOSTART=1`, `WOW_ROGUE_AUTOPLAY=1`, `WOW_ROGUE_AUTOPICK=1` : lance et joue une run seul.
- `WOW_ROGUE_SHOTS=<dossier>` : captures PNG régulières.

Les logs sortent sur stderr (`ui_script: ...`). Fermer la fenêtre proprement pour que les variables sauvegardées soient écrites.

## SurvivorsUI

Bloc bas centre : cible, vie, ressource, sorts (voile de recharge), XP. Cadres Blizzard joueur, cible et barres d'action masqués. Chat épuré en bas à gauche. Minimap carrée, zoom à la molette. Micro-boutons et sac en bas à droite, estompés hors survol. Erreurs d'initialisation dans la variable sauvegardée `SurvivorsUIErrors`.

## SurvivorsGuardians

Panneau déplaçable sous la minimap : une ligne par gardien avec boussole (nord en haut), temps de trajet estimé, vie si déjà ciblé, état « slain ». Clic sur une ligne : cible le gardien. Repères colorés sur le bord de la minimap. `/guardians` remet le panneau à sa place.
