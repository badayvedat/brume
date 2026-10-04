# Icône de l'application

## L'icône actuelle

`Resources/AppIcon.svg` : un écran dans son cadre, à la façon de Ghostty, avec le souffle de Brume en haut à gauche et un petit `>_` dessous, en palette neutre. `bash scripts/make-icon.sh` en tire `Resources/AppIcon.icns`, que le script de build copie dans l'app.

Les autres propositions et leurs générateurs Python vivent hors du dépôt, dans un dossier de travail local. Chaque générateur reproduit son SVG à l'identique. Deux outils servent à les vérifier : un rendu rsvg de 1024 à 16 px avec planche de contrôle, et un rendu WebKit.

## Règles de dessin

- Grille macOS : canevas de 1024 × 1024, corps de 824 × 824 posé à 100 px des bords, coins de 185 px, ombre portée douce dessous.
- Palette neutre tant que la couleur n'est pas choisie : nuit `#2c3547` → `#12161e`, blancs `#ffffff` `#eef2f9` `#dfe6f4`, accent de l'app `#8b9dc3` en touche.
- Ce qui a été rejeté : les primitives géométriques plates (des ronds, des bandes) ; le flou qui porte la forme, car il nuit à la lisibilité ; un contour ondulé ; une texture de brume « photo ». La brume passe par des échos nets, une dissolution en bout de forme, du grain discret.
- Une nouvelle version va dans un nouveau fichier : on n'écrase jamais une proposition.
- L'icône doit se reconnaître à 32 px et rester une forme nette à 16 px.

## Vérifier un SVG

Rendre avec `rsvg-convert -w <taille>` en 1024, 128, 64, 32 et 16, et regarder chaque taille. Le navigateur et le Dock passent par d'autres moteurs : comparer aussi avec un rendu WebKit, servi par un serveur local, car les écarts sont réels.

- WebKit applique un masque morceau par morceau : des formes semi-transparentes qui se chevauchent sous un masque y font des rectangles plus clairs. Fusionner ces formes en un seul tracé.
- `feDisplacementMap` posé sur un groupe ne rend pas pareil dans WebKit. Dessiner l'effet dans la géométrie, ou ne l'appliquer qu'à une forme simple.
- Le grain de `feTurbulence` sort plus fort dans Chrome : le doser bas.
- Tout filtre en `filterUnits="userSpaceOnUse"` sur tout le canevas, sinon le flou est coupé.

## Produire l'icône

`bash scripts/make-icon.sh` rend le SVG avec `rsvg-convert` dans un `AppIcon.iconset` (16 à 512 px, en @1x et @2x), puis `iconutil` en fait `Resources/AppIcon.icns`. Relancer ensuite le build, et vérifier l'icône dans le Dock et le Finder.

## Fond du DMG

`Resources/dmg/background.svg`, rendu en @1x et @2x par `scripts/make-dmg.sh`. Le Finder écrit le nom des icônes en noir en mode clair et en blanc en mode sombre : la bande de ton moyen sous les noms les garde lisibles dans les deux cas. La mise en page (taille de la fenêtre, position des icônes) est dans `scripts/dmg-settings.py`.
