# Brume

Terminal perso pour macOS, simple et beau, qui remplace Ghostty.

## Décisions

- macOS uniquement : Swift + SwiftUI, moteur Ghostty via le paquet libghostty-spm (vue terminal fournie, suit Ghostty officiel).
- Sans Xcode : `swift build` + script qui fabrique le .app, comme Orby. GhosttyKit téléchargé précompilé.
- Repo neuf sur le compte GitHub perso, sans historique. Muxy (MIT) sert de référence : pièces utiles par étape dans [docs/reprise-muxy.md](docs/reprise-muxy.md).
- Terminal proche de Ghostty, pas de fonctions en trop. Barre du haut à la Muxy : onglets maison et boutons. Au choix, les onglets listés à gauche (vue agents).
- DA inspirée de Monocode (MIT) : flou, teinte réglable, image de fond fondue.

## 1. Mise en place

- [x] Choisir le nom du terminal
- [x] Créer le repo sur le compte GitHub perso
- [x] Package Swift vide qui ouvre une fenêtre
- [x] Script de build qui fabrique `Brume.app`

## 2. Reprise de Muxy

- [x] Lister ce que fait Muxy, trier garder / jeter
- [x] Moteur : libghostty-spm plutôt que le code de Muxy, incompatible avec ce moteur
- [x] Vue terminal aussi épurée que Ghostty
- [x] Compiler et lancer un terminal qui marche

## 3. Base d'un terminal moderne (au niveau de Ghostty)

- [x] nano en SSH : garder `xterm-ghostty` sur le Mac, installer la fiche sur le serveur ou se replier sur `xterm-256color` (options `ssh-env` et `ssh-terminfo` de Ghostty)
- [x] Coloration syntaxique des commandes active par défaut
- [x] Autocomplétion depuis l'historique (texte grisé) active par défaut
- [x] Onglets (Cmd+T) et nouvelle fenêtre (Cmd+N) : partager un seul `TerminalController`, aujourd'hui chaque fenêtre crée le sien
- [x] Splits : côte à côte (Cmd+D), dessous (Cmd+Shift+D), passer de l'un à l'autre
- [x] Redimensionner les splits en glissant la séparation (ratio 0,15 à 0,85 comme Muxy)
- [x] Barre de défilement et défilement fluide au trackpad
- [x] Recherche dans le terminal (Cmd+F)
- [x] Zoom du texte (Cmd+plus, Cmd+moins, Cmd+0)
- [x] Nouveau split ou onglet ouvert dans le dossier du terminal actif (comme Ghostty)
- [x] Réinitialiser les tailles : texte des terminaux de la fenêtre, splits remis à parts égales
- [x] Barre d'onglets claire sur un terminal sombre (fond clair des terminaux ouverts avant le passage du moteur en sombre)
- [x] Confirmation avant de fermer un terminal où une commande tourne
- [x] Raccourcis de l'app interceptés avant le terminal
- [x] Reprendre tes réglages Ghostty : Shift+Entrée = saut de ligne (Claude Code), Option gauche = Alt
- [x] Textes d'autorisation macOS (Documents, Bureau...) dans l'Info.plist

## 4. Interface façon Muxy

- [x] Onglets gérés dans la fenêtre à la place des onglets natifs de macOS : une seule liste, que la barre du haut et la vue agents affichent
- [ ] Choisir ce qu'on reprend d'autre de Muxy (disposition, précédent / suivant...)
- [x] Barre d'onglets maison dans la barre de titre : onglets arrondis, soulignés de la couleur d'accent, croix, à la place des onglets natifs
- [x] Bouton nouvel onglet dans la barre (en plus de Cmd+T)
- [x] Bouton nouvelle fenêtre dans la barre (en plus de Cmd+N)
- [x] Réordonner les onglets en les glissant
- [x] Renommer un onglet : double-clic, clic droit ou Cmd+Shift+R, champ vidé = nom automatique
- [x] Numéros des onglets affichés tant qu'on tient Cmd, pour Cmd+1, Cmd+2...
- [x] Boutons de split dans la barre : à droite, en dessous
- [x] Infobulles maison sous les boutons et les onglets, avec le raccourci
- [x] Glisser un onglet sur le terminal pour en faire un split (comme Muxy, en plus fluide)
- [ ] Bouton « Ouvrir avec » : dossier du terminal actif dans le Finder, un éditeur...

## 5. Réglages en interface

- [ ] Panneau de réglages en sidebar
- [ ] Opacité et flou
- [ ] Police et taille du texte
- [ ] Thèmes de couleurs prêts à choisir (module GhosttyTheme du paquet)
- [ ] Couleurs de la coloration syntaxique et du texte grisé de l'autocomplétion (gris trop peu contrasté par défaut)
- [ ] Sélection lisible : le thème par défaut met un fond quasi noir (#303030) qui masque le texte sélectionné
- [ ] Image de fond (choix, opacité)
- [ ] Changements appliqués en direct, sans redémarrer
- [ ] Langue de l'interface (français / anglais) : `L10n.language` passe dans le store des réglages, et les menus en dur passent aux clés `TextKey`

## 6. Page de démarrage

- [ ] Intégrer fastfetch
- [ ] 3 ou 4 presets au choix dans les réglages
- [ ] Position : gauche, centré, droite
- [ ] Option « aucune »

## 7. Vue agents

- [ ] Sidebar des sessions façon conversations : les onglets de la fenêtre listés à gauche, au choix avec la barre du haut
- [ ] Raccourci pour basculer vue agents / vue terminal
- [ ] Créer, renommer, fermer une session depuis la sidebar

## 8. DA Monocode

- [ ] Couleurs et tokens de base
- [ ] Effet verre sur la sidebar
- [ ] Effet de fondu de l'image de fond

## 9. Autocomplétion des commandes connues

- [ ] Intégration zsh qui transmet la ligne en cours au terminal
- [ ] Suggestions via carapace (gh, git, docker...)
- [ ] Popup natif au niveau du curseur
- [ ] Validation au clavier (Tab, Entrée, Échap)

## 10. Finitions

- [ ] Icône définitive
- [ ] App installable (.app / .dmg)
- [ ] Utiliser le terminal au quotidien à la place de Ghostty
