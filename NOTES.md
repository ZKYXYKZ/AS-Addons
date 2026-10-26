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

Fichiers : `Movers.lua` (registre des blocs déplaçables, grille, aimantation, échelle), `Settings.lua` (panneau, bouton « UI » sur la minimap, caméra), `SurvivorsUI.lua` (cadres).

- Réglages : bouton « UI » en bas à droite de la minimap ou `/sui`. Positions et tailles dans la variable sauvegardée `SurvivorsUIDB`.
- Mode déverrouillé : grille de 32 unités centrée sur l'écran, glisser pour déplacer, molette pour redimensionner, Maj pour désactiver l'aimantation. Aimantation à 8 unités sur les bords et centres des autres blocs, les bords et le centre de l'écran, puis la grille.
- Un autre addon ajoute un bloc avec `SurvivorsUI.Register(cle, libelle, frame, point, x, y, echelle)`.
- `GetLeft`/`GetTop` et les décalages de `SetPoint` sont dans l'unité propre du cadre (écran divisé par son échelle), vérifié en jeu.
- Caméra : `SetCVar("cameraDistanceMaxFactor", n)` et `cameraDistanceMax` (n x 15 yd) sont acceptés au-delà de la limite du menu du jeu. Défaut de l'addon : 3 (45 yd), réglable de 15 à 90 yd.

## SurvivorsGuardians : fonctionnement interne

- `GetMapLandmarkInfo` n'expose un gardien qu'une fois proche. Les gardiens vus sont mémorisés par carte dans `SurvivorsGuardiansDB.zones[zone]["Nom@x,y"]` et rechargés au début de la run suivante. Deux gardiens peuvent porter le même nom (deux Kobold Taskmaster à Elwynn), d'où la clé nom + position et le rapprochement à 0,03 unité de carte.
- `TargetByName(nom, 1)` atteint un gardien même hors de vue, mais le changement de cible est asynchrone. Relevé automatique (niveau, vie) : ciblage, lecture au tick suivant, puis `TargetLastTarget()` ou `ClearTarget()`. Un gardien est relevé au plus toutes les 30 s. `SURVIVORS_PEEKING` gèle la barre de cible de SurvivorsUI pendant ce temps. `/guardians peek` coupe le relevé.
- Les emotes du jeu arrivent avec `%s` non remplacé dans `arg1` et le nom dans `arg2`.
- Horloge de run : le timer natif est illisible en Lua. L'addon compte le temps tant que des événements de combat arrivent ; pendant l'écran de choix de montée de niveau seuls les événements de recharge continuent, donc l'horloge se fige. Écart mesuré face au timer natif : 1 à 5 s.
- Boss : intervalle supposé de 180 s (observé à Elwynn et Warsong), recalé à chaque boss détecté et appris dans `SurvivorsGuardiansDB.bossEvery`. Détection du boss par texte (« has come! », « approaches! », cri) ou unité classée `worldboss`, jamais vue en test.
- Réapparition d'un gardien : délai appris entre sa mort et « claims its lair once more », stocké dans `SurvivorsGuardiansDB.respawn`, puis affiché en compte à rebours sur les lignes mortes. Jamais observé en test.

## SurvivorsGuardians

Panneau déplaçable sous la minimap : une ligne par gardien avec boussole (nord en haut), temps de trajet estimé, vie si déjà ciblé, état « slain ». Clic sur une ligne : cible le gardien. Repères colorés sur le bord de la minimap. `/guardians` remet le panneau à sa place.

## Jeu v0.119 : ce qui a changé et ce que le jeu expose (26/10/2026)

- La config est maintenant à côté de l'exe : `<dossier du jeu>\benilla-config` (AddOns, saved, etc.). `BENILLA_HOME` la déplace toujours.
- API officielle pour addons, code Lua embarqué dans l'exe (`AZSApiFrame`) : canaux `CHAT_MSG_ADDON` `AZSRUN`, `AZSZONE`, `AZSBOSSES`, `AZSUNITS`, `AZSLAIRS`, `AZSSPELLS`, `AZSTIMERS`, `AZSPETS`, `AZSMETER`, `AZSBANNER`, etc. et fonctions `AZS_GetRunTime`, `AZS_GetPhase`, `AZS_GetGuardians`, `AZS_GetLairs`, `AZS_GetUpcomingBosses`, `AZS_GetBosses`, `AZS_RegisterBannerHandler`, `AZS_SetStoringLevels`, `AZS_OpenStoredLevels`. `AZSLAIRS` donne les 4 repaires avec état, nom, temps restant et position : c'est la bonne source pour refaire SurvivorsGuardians.
- Aucune donnée sur les cartes proposées à la montée de niveau n'arrive au Lua. L'écran de choix est natif (Bevy) et se pilote au clavier (1 2 3 pour choisir, R pour relancer). Les choix sortent en JSON sur la sortie standard (`rogue: {"type":"choices",...}`) quand le jeu est lancé avec stdout redirigé.
- Talents : l'API Lua `GetTalentInfo` renvoie les talents de WoW vanilla, pas ceux du jeu. Les vrais talents sont des tables Rust dans `.rdata` : entrées de 160 octets (clé, nom, icône, effets, description ; rangée, colonne et rang max aux octets 104 à 106 ; prérequis). Effet type 0x24 : bonus de stat, valeur par rang en f32 ; type 0x25 : bonus sur un sort, clé du sort et valeur par rang.
- Localisation : 14 tables JSON embarquées (anglais, français, etc.), 2979 clés dont `ability.<clé>.name`, `rarity.0..5`, et les talents indexés par leur texte anglais.
- Un autre addon a laissé ses variables chez l'utilisateur : `saved\ASBuilder.lua` (builds par classe, variantes, priorités de sorts et de bijoux, bannissements).
