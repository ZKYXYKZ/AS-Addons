# AS-Addons

[English](README.md) · **Français**

Des outils pour [Azeroth Survivors](https://wow.aethus.pl/), un jeu de type survivors bâti sur un client WoW 1.12 réécrit : survivre aux vagues, monter de niveau, choisir sorts et bijoux, battre les boss, passer aux cartes plus difficiles.

- **AS Companion** : une application Windows pour préparer vos builds, lancer le jeu, choisir les cartes de niveau à votre place et garder les statistiques de vos parties.
- **SurvivorsUI**, **SurvivorsBuilds**, **SurvivorsGuardians** : des addons en jeu, écrits pour ce mode de jeu.

![SurvivorsUI et SurvivorsGuardians en partie](docs/gameplay.jpg)

[![Buy me a coffee](AS-Companion/web/img/buymeacoffee.png)](https://www.buymeacoffee.com/zkyxykz)

## Démarrage rapide

1. Téléchargez `AzerothSurvivors-Addons.zip` depuis la [dernière version](https://github.com/ZKYXYKZ/AS-Addons/releases/latest).
2. Extrayez-le dans le dossier du jeu, celui qui contient `AzerothSurvivors.exe`. Il y ajoute `ASCompanion.exe` et place les trois addons dans `benilla-config\AddOns`, le dossier d'où le jeu charge les addons.
3. Lancez `ASCompanion.exe`, créez un build pour votre classe, puis cliquez sur **Lancer le jeu**.

Le compagnon se met à jour, lui et les addons, depuis les versions publiées sur GitHub. Windows 10 ou 11, rien d'autre à installer.

## AS Companion

Le compagnon s'ouvre dans sa propre fenêtre, affichée par Microsoft WebView2 (intégré à Windows 10 et 11). Si WebView2 manque, le compagnon propose de le télécharger et de l'installer en arrière-plan, et ouvre en attendant son interface dans votre navigateur. Une icône dans la zone de notification rouvre la fenêtre. Fermer la fenêtre arrête le compagnon, sauf si une partie qu'il a lancée tourne encore.

### Builds

- **Talents** : les trois arbres de la classe avec leurs fonds d'origine, 51 points, paliers et apogée.
- **Sorts** : ordre de priorité avec un poids de 1 à 5, et sorts bannis. Une partie garde 6 sorts : les 6 premiers sont visés, les suivants servent de repli.
- **Bijoux** : anneaux, bijoux et amulettes visés ou de repli, dont l'amulette légendaire de chaque sort, chacun avec un poids de 1 à 5. Chaque bijou affiche ses effets, décodés depuis le jeu.
- **Règles** : poids de la rareté, relances gardées en réserve, bannissements, relancer avant de passer, niveau à partir duquel les anneaux et bijoux de repli sont acceptés, bonus de légendaire, adaptation à la partie.
- **Partage** : Exporter et Importer un build complet en une ligne de texte.

### En partie

Cliquez sur **Lancer le jeu**. Le jeu doit être lancé par le compagnon : c'est ainsi qu'il lit les cartes de niveau, dans la sortie console du jeu.

- Un bandeau par-dessus le jeu indique la meilleure carte, sans prendre le focus.
- La **sélection auto** (Options) appuie sur 1, 2, 3, 4 ou R à votre place, et réessaie si le jeu a raté la touche. Passer et Bannir n'ont pas encore de touche dans le jeu : ils restent manuels.
- Le conseil s'adapte à la partie : sorts déjà pris, leur rang, leur part réelle de vos dégâts (lue dans le journal de combat du jeu), l'amulette portée et ses améliorations, votre chance et les emplacements de bijoux libres. Les anneaux et bijoux ne se changent plus une fois pris : les replis ne sont acceptés qu'à partir du niveau fixé dans les Règles.
- La chance vient du jeu lui-même : l'addon SurvivorsBuilds la relève au début de chaque partie, et le compagnon y ajoute les bijoux de chance pris pendant la partie.

### Statistiques

Chaque partie lancée depuis le compagnon est enregistrée à sa fin, mode endless compris (après le boss final, le jeu peut continuer, avec un boss toutes les 5 minutes, jusqu'à la mort) :

- filtres par classe, zone et résultat ;
- chiffres clés : parties, victoires, temps joué, meilleure survie, niveau et victimes max, DPS moyen et max, boss et gardiens tués, meilleur endless ;
- durée de survie et DPS par partie, survie moyenne par classe, part des dégâts par sort ;
- tableaux par spécialisation et par race, et dernières parties.

### Addons

Liste les addons du jeu avec leur description, la version installée et la dernière version. Installez, mettez à jour, activez, désactivez ou désinstallez-les (les dossiers désinstallés partent à la corbeille). Fermez le jeu avant.

### Options

Chemin du jeu (avec un bouton Parcourir), langue, sélection auto, bandeau de conseil, version et recherche de mise à jour.

### Mises à jour

Au démarrage, le compagnon consulte la dernière version publiée sur GitHub. Si elle est plus récente, un bouton **Mettre à jour** apparaît dans la barre d'état : il télécharge la version, vérifie son SHA-256, met à jour les addons installés et le compagnon, puis redémarre. Builds, statistiques et réglages sont conservés dans `%APPDATA%\AS-Companion`.

### Avertissement Windows

`ASCompanion.exe` n'est pas signé : SmartScreen peut avertir au premier lancement. Cliquez sur **Informations complémentaires**, puis **Exécuter quand même**. Il est compilé depuis ce dépôt par GitHub Actions, et `SHA256SUMS.txt` dans chaque version permet de vérifier chaque fichier.

## Addons

Les trois partagent une fenêtre : le bouton doré `S` sur la minicarte, `/survivors`, ou une touche réglée dans Raccourcis > Survivors.

### SurvivorsBuilds

La passerelle avec AS Companion.

- Un panneau qui reste à l'écran pendant la partie : les 6 sorts visés avec leur icône et leur rang, les bijoux portés dans la couleur de leur qualité (visés ou de repli), et les bijoux visés encore manquants.
- Pendant le choix d'une carte : sorts à bannir, relances restantes et règle du build.
- Chaque sort pris ou monté est écrit dans le chat avec sa priorité.
- Relève votre chance pour le compagnon et active le journal de combat qu'il lit.

### SurvivorsUI

Une interface compacte qui remplace celle d'origine.

- Bloc en bas au centre : barre de cible, vie, ressource, icônes de sorts avec recharge, barre d'expérience.
- Les cadres joueur et cible et les barres d'action d'origine sont masqués. Chat épuré, minicarte carrée avec zoom à la molette, micro-boutons qui s'effacent jusqu'au survol.
- Réglages dans l'onglet Interface de la fenêtre commune, ou `/sui` : taille de chaque bloc, déverrouillage pour déplacer les cadres sur une grille avec aimantation (Maj pour la désactiver), recul de la caméra de 15 à 90 mètres.

![Réglages avec les cadres déverrouillés](docs/settings.jpg)

### SurvivorsGuardians

Un suivi des quatre repaires de gardiens et des boss, alimenté par l'API d'addons du jeu.

- Une ligne par repaire : nom du gardien, vie, endormi ou en combat.
- Un repaire vide affiche le compte à rebours avant le retour d'un gardien.
- Les boss ont leur propre ligne avec leur vie. L'en-tête compte les repaires occupés et affiche le prochain boss avec son compte à rebours.
- Un clic sur une ligne cible ce gardien ou ce boss.

Les panneaux Build et Gardiens se déplacent directement à la souris.

## Limites connues

- Passer et Bannir ne peuvent pas être automatisés tant que le jeu ne leur donne pas de touche.
- Le chrono, les compteurs de victimes et d'or, le compteur de dégâts et la rangée d'icônes de sorts sont dessinés par le moteur du jeu : les addons ne peuvent ni les déplacer ni les masquer.
- Les addons ne peuvent rien envoyer au compagnon pendant la partie. Le compagnon lit à la place la sortie console et le journal de combat du jeu.

## Pour les développeurs

- Compiler le compagnon : `node tools/build-companion.js` (utilise le compilateur C# fourni avec Windows, sortie dans `dist\`).
- Publier : poussez un tag `vX.Y.Z`. GitHub Actions compile le compagnon, emballe les addons avec cette version et publie `ASCompanion.exe`, `AzerothSurvivors-Addons.zip`, un zip par addon, `addons.json` et `SHA256SUMS.txt`.
- `NOTES.md` décrit ce que le jeu expose, comment les données sont décodées depuis les fichiers du jeu, et le fonctionnement de chaque partie.

## Avertissement

Projet de fan non officiel, sans lien avec Azeroth Survivors ni avec Blizzard Entertainment.

Développé par [ZKYXYKZ](https://x.com/zkyxykz).
