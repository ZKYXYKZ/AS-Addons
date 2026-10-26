# Pilote automatique (expérimental, jamais publié)

Branche `experimental/autoplay` uniquement, pour les tests et simulations de builds. Rien de ce dossier ne doit arriver sur `main` ni dans une release.

- `AZBot/` : addon de test. Il lit la position du joueur (`GetPlayerMapPosition`), les coffres (`AZS_CHESTS`) et les repaires (`AZS_LAIRS`), choisit une cible (coffre le plus proche, sinon repaire avec un gardien vivant, sinon une ronde) et affiche dans le coin haut gauche un carré dont la couleur code les touches à tenir (rouge = bits 0 à 3, bleu = bits 4 à 7, vert = repère).
- `driver.ps1` : lit ce pixel à l'écran et tient les touches correspondantes dans la fenêtre du jeu (avancer = flèche haut, tourner = flèches gauche et droite). Le sens de rotation se corrige seul.
- `key.ps1` : envoie une touche (Entrée pour lancer la partie depuis le menu).

Le jeu bloque les fonctions de déplacement Lua (`MoveForwardStart`, etc.) : seules de vraies touches font bouger le personnage, et l'orientation compte (contrôles à la WoW).
