# Visuels de la page de démarrage

Les visuels en pixel art affichés par fastfetch à l'ouverture d'un terminal (Réglages › Démarrage).

## Comment c'est fait

- Chaque visuel est une grille de lettres dans `Sources/BrumeCore/Constants/PixelArt.swift`, une lettre par pixel. Le codage des couleurs est en tête du fichier : `A` `L` `D` `E` sont des nuances de l'accent, `H` `W` `G` `S` des gris, `O` le contour, `K` le noir, `Z` `Y` `y` l'or, et `.` le vide.
- Deux tailles dessinées : la normale et la petite (`…Small`), redessinée et non réduite pour garder les détails. La grande est la normale agrandie ×1,5 au plus proche voisin (`WelcomeBuilder.enlarged`).
- Dans le terminal, `WelcomeBuilder` met deux pixels par case avec les demi-blocs `▀` `▄`, en couleurs 24 bits. Les vignettes des réglages (`VisualPicker`) dessinent la petite grille.

## Ajouter un visuel

1. Un `case` dans `WelcomeVisual` (`Models/Welcome.swift`). L'ordre des cas est celui de la grille des réglages, trois par ligne.
2. Une clé `TextKey` dans `L10n.swift`, en français et en anglais, reliée dans `WelcomeVisual.title`.
3. Les deux grilles dans `PixelArt.swift`, et leur cas dans les deux `switch` de `pixels(for:small:)`.
4. `bash scripts/run-tests.sh` : les tests vérifient d'eux-mêmes chaque visuel (lignes de même largeur, petite version présente, config fastfetch valide).

Tailles des visuels existants : normale jusqu'à 46 × 34, petite autour de 22 × 18. Une hauteur paire évite une demi-case vide en bas.

## Générer une grille : `scripts/pixel-art.py`

Le script produit le Souffle et le Terminal, et sert de modèle pour un nouveau dessin. Il affiche les tableaux Swift à coller, et écrit une planche d'aperçu en accent Brume et en orange, à côté du Fantôme et du Nuage :

```bash
python3 scripts/pixel-art.py /tmp/planche.png
```

Il demande Python 3 avec Pillow, et `rsvg-convert` (Homebrew : `librsvg`).

- **Forme courbe (Souffle)** : la forme est décrite en SVG, rastérisée en sur-échantillonnage (`couverture`), puis éclairée depuis le haut à gauche par un produit scalaire avec la normale du bord (`eclairer`). Un contour `O` d'un pixel est ajouté autour.
- **Glyphe droit (Terminal)** : il est posé pixel par pixel (`invite_net`). La branche du bas du `>` est le miroir exact de celle du haut, et l'ombrage fait un pixel net sur chaque bord, avec la lumière venant du haut. Avec une lumière en diagonale, une branche est éclairée de biais et l'autre de face : les deux paraissent d'épaisseurs différentes.
- **Visages, couronnes, détails** : à poser à la main dans la grille. La rastérisation ne les rend pas lisibles en petit.

## Vérifier

- L'aperçu du script montre les grilles exactes, aux couleurs de deux accents.
- Dans l'app : Réglages › Démarrage. Une copie lancée à part ne passe pas au premier plan pendant qu'on utilise Brume, et son terminal sort vide à la capture. Pour voir ce que fastfetch affiche vraiment, rends en image le fichier généré par l'app : `~/Library/Application Support/Brume/welcome-logo-medium.txt`.
