# Icône de l'application

## Où en est l'icône

L'icône n'est pas encore choisie. Le travail se fait hors du dépôt, dans le dossier local de Jérémy `~/Documents/Images/Logos/Brume/` :

| Dossier | Contenu |
|---|---|
| `propositions/` | un SVG par proposition, numérotés (`08f-souffle-propre.svg`, `11b-cadre-souffle-coin-invite.svg`…) |
| `sources/<piste>/` | le générateur Python de chaque SVG, qui le reproduit à l'identique |
| `outils/` | `rendu-un.sh` (rendu rsvg 1024 → 16 px, planche de contrôle) et `rendu-webkit.sh` (rendu WebKit) |
| `planche.html` | la planche de comparaison, avec la bande Dock à côté de Ghostty, Dia et Orby |

Pistes retenues au dernier tour : **Souffle propre** (08f), **Écran et écho** (09g), et **Cadre et souffle** (11, 11b), un écran façon Ghostty avec le souffle à la place du fantôme. Jérémy a trouvé 11b « archi clean ».

## Règles de dessin

- Grille macOS : canevas de 1024 × 1024, corps de 824 × 824 posé à 100 px des bords, coins de 185 px, ombre portée douce dessous.
- Palette neutre tant que la couleur n'est pas choisie : nuit `#2c3547` → `#12161e`, blancs `#ffffff` `#eef2f9` `#dfe6f4`, accent de l'app `#8b9dc3` en touche.
- Ce que Jérémy rejette : les primitives géométriques plates (des ronds, des bandes) ; le flou qui porte la forme, car il nuit à la lisibilité ; un contour ondulé ; une texture de brume « photo ». La brume passe par des échos nets, une dissolution en bout de forme, du grain discret.
- Une nouvelle version va dans un nouveau fichier : on n'écrase jamais une proposition.
- L'icône doit se reconnaître à 32 px et rester une forme nette à 16 px.

## Vérifier un SVG

Rendre avec `rsvg-convert -w <taille>` en 1024, 128, 64, 32 et 16, et regarder chaque taille. Le navigateur et le Dock passent par d'autres moteurs : comparer aussi avec un rendu WebKit, servi par un serveur local, car les écarts sont réels.

- WebKit applique un masque morceau par morceau : des formes semi-transparentes qui se chevauchent sous un masque y font des rectangles plus clairs. Fusionner ces formes en un seul tracé.
- `feDisplacementMap` posé sur un groupe ne rend pas pareil dans WebKit. Dessiner l'effet dans la géométrie, ou ne l'appliquer qu'à une forme simple.
- Le grain de `feTurbulence` sort plus fort dans Chrome : le doser bas.
- Tout filtre en `filterUnits="userSpaceOnUse"` sur tout le canevas, sinon le flou est coupé.

## Produire l'icône finale

1. Rendre le SVG choisi avec `rsvg-convert` dans un dossier `AppIcon.iconset` : `icon_16x16.png` à `icon_512x512@2x.png`, chaque taille en @1x et @2x.
2. `iconutil -c icns AppIcon.iconset -o Resources/AppIcon.icns`.
3. Le script de build copie `Resources/AppIcon.icns` dans l'app s'il existe. Relancer le build, puis vérifier l'icône dans le Dock et le Finder.
