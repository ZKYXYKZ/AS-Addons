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

## SurvivorsGuardians

- Réécrit le 26/10/2026 sur l'API du jeu : `AZS_GetLairs()` (4 repaires : `index, state, name, id, left, x, y, z, mx, my, flag`), `AZS_UNITS` pour la vie (`id` du repaire = `id` de l'unité), `AZS_GetBosses()` et `AZS_GetUpcomingBosses()`.
- États d'un repaire : `empty` (`left` = secondes avant qu'un gardien s'installe, 20 s en début de run, 180 s après une mort, -1 sinon), `asleep`, `awake` (en combat). `flag` = repaire visé par le drapeau de la minimap. Les lignes arrivent chaque seconde, le compte à rebours est interpolé avec `AZS_LAIRS_UPDATED`.
- `AZSBOSSES` donne tout le calendrier (`index, at, name, final, state`) : Elwynn 180/360/540/720 s, boss final à 960 s. Le compte à rebours de l'en-tête suit le « prochain boss » natif à la seconde.
- Retirés à la demande : boussole par ligne et repères sur le bord de la minimap (inutiles), lecture des repères de carte, des messages de chat et ciblage furtif.

## Fenêtre commune (Hub.lua)

`Hub.lua` est copié tel quel dans chaque addon et ne s'installe qu'une fois (`SurvivorsHub.version`). Le premier chargé crée la fenêtre, le bouton minimap `S`, `/survivors` et `/sv`. Un addon ajoute un onglet avec `SurvivorsHub.RegisterTab(id, libellé, ordre, function(panel) ... end)` ; le contenu est construit à la première ouverture. Modifier Hub.lua impose d'augmenter `VERSION` et de recopier le fichier dans tous les addons.

## AS Companion (builder) et SurvivorsBuilds (passerelle)

- Le builder vit dans le compagnon `ASCompanion.exe` (source `AS-Companion\src\Companion.cs`, C# 5 compilé par le `csc.exe` du .NET Framework 4 livré avec Windows : `node tools/build-companion.js` vers `dist\`). Il embarque `AS-Companion\web` en ressources, sert l'interface sur http://localhost:47821/ et l'affiche dans une fenêtre Edge en mode application (`--app`, profil `%LOCALAPPDATA%\AS-Companion\ui`). Fermer la fenêtre arrête le compagnon sauf si le jeu tourne (fenêtre détectée par le verrou `lockfile` du profil). Un second lancement rouvre seulement la fenêtre (mutex), l'icône de notification aussi. Onglets : Build (talents, sorts, bijoux sur une page), Règles, Options. Bouton « Parcourir » du chemin du jeu : `/api/browse` ouvre un sélecteur de fichier Windows depuis l'exe.
- Builds et journal dans `%APPDATA%\AS-Companion`. Au premier lancement, `state.json` est repris de `AS-Companion\` à côté de l'exe (ancienne version PowerShell, retirée).
- Release : `.github/workflows/release.yml` compile sur un tag `v*` et publie l'exe, `AzerothSurvivors-Addons.zip` (exe + `benilla-configAddOns` avec les 3 addons, à extraire dans le dossier du jeu) et `SHA256SUMS.txt`. Exe non signé : avertissement SmartScreen au premier lancement.
- Touches de la sélection auto : renvoyées toutes les 1,5 s (4 fois au plus) tant que le jeu n'a pas répondu par `picked`, `resume` ou de nouvelles `choices`. Le bandeau ne prend plus le focus (`WS_EX_NOACTIVATE`) : avec l'ancien bandeau, une touche du joueur pendant le choix pouvait faire perdre la sélection.
- Chance : lue dans les stats de partie que le jeu envoie aux addons (canal `AZS`, champ `luck=`, 0,40 = 40 %, c'est la « Chance » de la fiche personnage). SurvivorsBuilds la relève au début de chaque run dans `SurvivorsBuildsDB.luck[classe]` ; le compagnon la relit au lancement suivant et la recopie dans la passerelle. Faute de mesure pour la classe : talents de chance du build (`v` x rang). S'y ajoutent les bijoux de chance pris pendant la run, lus dans le texte de la carte prise : une Marque de l'Élu commune affiche « +22% de chance », pas les 15 % de base. Une carte d'amélioration affiche l'ancienne et la nouvelle valeur (« 1.5% » 2.4% ») : la chance de chaque bijou est remplacée par la nouvelle, pas ajoutée. Chaque bijou pris est noté dans le journal (`took ...`). Modèle des raretés : fréquences observées 58/24/11/5/2 %, poids de la rareté r multiplié par (1 + chance)^r (hypothèse, formule du jeu non décodée ; le tirage est à 0x145c04a31). Une carte hors cible est relancée si son score est sous 0,4 x poids max du build x rareté moyenne attendue.
- Bannir rafraîchit les cartes : conseillé dès qu'une carte bannie apparaît (en sélection auto, la relance passe d'abord, bannir n'a pas de touche).
- Amulettes normales : le champ lu comme description (« $ ») est la tranche des effets (64 octets ; type 36 = stat, octet +8 = id de stat, flottant +4 = valeur ; +64 = rareté). Id de stat vers gabarit : table de saut de 0x145ade270 (v0.119). Anneaux et bijoux : valeur de base en flottant à +64 de la fiche de 72 octets. Ce sont des valeurs de base, le jeu les augmente avec la rareté de la carte. `legendary-render.js` écrit aussi `jewel-text.json` (5e argument), fusionné par `gen-companion.js` (4e argument).
- Fonds des arbres de talents : images classiques de wowhead (`wow.zamimg.com/images/wow/talents/backgrounds/classic/<id TalentTab>.jpg`) embarquées dans `web\img\<classe>-<n>.jpg`.
- Données : `web\data.json`, généré par `node tools/gen-companion.js data.json legendary-text.json AS-Companion/web/data.json jewel-text.json`.
- « Lancer le jeu » écrit `<jeu>\benilla-config\saved\SurvivorsBuilds.lua` (ou `%BENILLA_HOME%\saved`) avec `SurvivorsBuildsDB.link` : date de lancement, sélection auto, langue, et pour chaque classe le build actif réduit (sorts et poids, noms, bannis, bijoux visés, réserve, bannissements, relance). Puis il lance le jeu et lit sa sortie console.
- Aucun canal du Lua vers l'extérieur (print, chat, erreurs, SendChatMessage n'atteignent pas stdout) et le jeu ne lit les variables sauvegardées qu'au chargement : la passerelle est à sens unique, écrite avant le lancement. L'addon considère le lien actif si `link.launched` date de moins de 2 minutes.
- L'addon SurvivorsBuilds ne contient plus que `Hub.lua`, `Core.lua` (lien, langue, classe), `Guide.lua` (panneau pendant le choix, annonces dans le chat), `Window.lua` (onglet Builds en lecture seule) et `Bindings.xml`.
- Conseil (`Advise`) : poids du sort dans le build (x0,5 au-delà de 6 emplacements), x1,25 si le sort est déjà pris et x`boost` si l'amulette portée est la légendaire de ce sort (option « adapter »). Bijoux : poids 1 à 5 par bijou listé (`build.jw`, défaut 5 pour les visés, 3 pour les repli), score = poids x 2. Légendaire : max(poids listé x 2, poids du sort dans le build x boost), sans les bonus de la run (sort déjà pris, légendaire portée) qui faisaient double compte. Amélioration d'un bijou porté (« II », « III »…) : toujours prise (au moins 4). Anneaux et bijoux : 2 emplacements chacun ; une fois pleins, seules les améliorations comptent ; repli seulement à partir du niveau `fallbackLevel`. Amulette : remplace la portée seulement si son poids est supérieur à celui de la portée, majoré de 25 % par amélioration déjà prise sur elle (suivi des choix faits par la sélection auto). Sur un écran de bijoux avant `fallbackLevel`, 2 relances au plus. Score final : base x (1 + influence x rareté). Sinon : bannir, relancer au-delà de la réserve, passer seulement si `skip` est disponible, sinon la carte la plus rare non bannie.
- Reconnaissance des cartes par `kind` : sorts pour `new`/`upgrade`, bijou de la catégorie pour `ring`/`trinket`/`amulet` (corrige Frappe-terre, même icône que Colère). Légendaire : titre contenant le nom du sort et icône de la famille.
- Sélection auto : touches 1, 2, 3 et R envoyées par PostMessage. Skip et bannir n'ont pas de touche et restent manuels.
- Amulettes légendaires : une par sort, construites par la fonction du jeu à 0x145ad7f00 (v0.119) à partir de la fiche du sort (octet de type à +0x75, champs +0x44 à +0x68). `tools/legendary.js` exécute cette fonction dans un mini-émulateur x86-64 (`tools/emu.js`, `iced-x86`) pour les 113 sorts, puis `tools/legendary-render.js` traduit chaque effet (64 octets) avec les gabarits du jeu. Correspondance type → gabarit relevée dans la fonction de rédaction à 0x145c1afe0. Adresses à retrouver à chaque version avec `tools/xref.js "Amulet of the Inferno"` et `tools/dis.js`.
- Chaîne de données : `extract-loc.js`, `extract-data.js`, `legendary.js`, `legendary-render.js`, puis `gen-companion.js` (`npm install iced-x86@1.21.0` dans `tools`).
- Sélection des cartes depuis le Lua : impossible (v0.119). Écran Bevy natif, aucun cadre Lua, aucun événement pendant le choix hormis `AZSRUN ph=choosing`, aucune commande ni variable de configuration.
- Texte de partage : `SB1;classe;nom;rangs arbre1/arbre2/arbre3;sort:poids,...;bannis;anneau[:poids],...;bijou[:poids],...;amulette[:poids],...;rareté,réserve,relance,bannissements,niveauRepli,boost,adapter`.

## Fait le 26/10/2026 (demandes de la session précédente)

1. Compagnon installé dans le dossier du jeu (`<jeu>\AS-Companion`) : il devient le builder et transmet les builds à l'addon au lancement.
2. Option « Sélection auto des cartes » dans le compagnon, affichée par l'addon (« nécessite le compagnon »).
3. Pondération adaptée à la run : sorts pris et légendaire portée relèvent le poids du sort.
4. Frappe-terre reconnu (reconnaissance par `kind`).
5. Anneaux et bijoux de repli seulement à partir d'un niveau réglable, amulette à tout moment.

## Jeu v0.119 : ce qui a changé et ce que le jeu expose (26/10/2026)

- La config est maintenant à côté de l'exe : `<dossier du jeu>\benilla-config` (AddOns, saved, etc.). `BENILLA_HOME` la déplace toujours.
- API officielle pour addons, code Lua embarqué dans l'exe (`AZSApiFrame`) : canaux `CHAT_MSG_ADDON` `AZSRUN`, `AZSZONE`, `AZSBOSSES`, `AZSUNITS`, `AZSLAIRS`, `AZSSPELLS`, `AZSTIMERS`, `AZSPETS`, `AZSMETER`, `AZSBANNER`, etc. et fonctions `AZS_GetRunTime`, `AZS_GetPhase`, `AZS_GetGuardians`, `AZS_GetLairs`, `AZS_GetUpcomingBosses`, `AZS_GetBosses`, `AZS_RegisterBannerHandler`, `AZS_SetStoringLevels`, `AZS_OpenStoredLevels`. `AZSLAIRS` donne les 4 repaires avec état, nom, temps restant et position : c'est la bonne source pour refaire SurvivorsGuardians.
- Aucune donnée sur les cartes proposées à la montée de niveau n'arrive au Lua. L'écran de choix est natif (Bevy) et se pilote au clavier (1 2 3 pour choisir, R pour relancer). Les choix sortent en JSON sur la sortie standard (`rogue: {"type":"choices",...}`) quand le jeu est lancé avec stdout redirigé.
- Talents : l'API Lua `GetTalentInfo` renvoie les talents de WoW vanilla, pas ceux du jeu. Les vrais talents sont des tables Rust dans `.rdata` : entrées de 160 octets (clé, nom, icône, effets, description ; rangée, colonne et rang max aux octets 104 à 106 ; prérequis). Effet type 0x24 : bonus de stat, valeur par rang en f32 ; type 0x25 : bonus sur un sort, clé du sort et valeur par rang.
- Localisation : 14 tables JSON embarquées (anglais, français, etc.), 2979 clés dont `ability.<clé>.name`, `rarity.0..5`, et les talents indexés par leur texte anglais.
- Le moteur dessine l'écran de choix des cartes par-dessus l'UI Lua, assombrie mais lisible : le guide de SurvivorsBuilds reste visible pendant le choix.
- Les arbres de talents du jeu : 4 colonnes, 7 rangées, une rangée s'ouvre tous les 5 points dans l'arbre, paliers (milestone) aux rangées 2 et 4, apogée (capstone) rangée 6, 51 points au total. Le champ « clé » à l'octet 112 d'un talent n'est pas un prérequis (le jeu ne trace que la colonne des paliers) : ignoré.
- Un run garde 6 sorts (« Takes a spell slot · 3/6 » sur les cartes).
- Un autre addon a laissé ses variables chez l'utilisateur : `saved\ASBuilder.lua` (builds par classe, variantes, priorités de sorts et de bijoux, bannissements).
