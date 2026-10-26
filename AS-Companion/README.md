# AS-Companion

Lanceur pour Azeroth Survivors qui conseille, ou prend, la meilleure carte à chaque choix selon un build SurvivorsBuilds.

1. Dans le jeu : Survivors > Builds > Exporter, copier le texte.
2. Le coller dans `build.txt`, à côté de ce fichier.
3. Lancer le jeu par `Start-Companion.cmd` (conseil seul) ou `Start-Companion.cmd -Auto` (choisit, relance tout seul).
4. Chemin du jeu différent : `Start-Companion.cmd -GamePath "D:\...\AzerothSurvivors.exe"`.

Un bandeau au premier plan affiche le conseil pendant le choix. En `-Auto`, les touches 1, 2, 3 et R sont envoyées à la fenêtre du jeu, même si elle n'a pas le focus. Skip et bannir restent à faire à la main (pas de touche dans le jeu). Sans skip débloqué sur le compte, la carte la plus rare non bannie est prise.

Le jeu doit être lancé par le compagnon : c'est ainsi qu'il lit les cartes proposées, que le jeu écrit sur sa sortie console. Journal dans `companion.log`.
