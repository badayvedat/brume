# Brume

Terminal perso pour macOS, simple et beau, qui remplace Ghostty.

## Décisions

- macOS uniquement : Swift + SwiftUI, moteur Ghostty via le paquet libghostty-spm (vue terminal fournie, suit Ghostty officiel).
- Sans Xcode : `swift build` + script qui fabrique le .app, comme Orby. GhosttyKit téléchargé précompilé.
- Repo neuf sur le compte GitHub perso, sans historique. Muxy (MIT) sert de référence : pièces utiles par étape dans [docs/reprise-muxy.md](docs/reprise-muxy.md).
- Interface proche de Ghostty en vue terminal : pas de fonctions en trop.
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
- [ ] Barre de défilement et défilement fluide au trackpad
- [ ] Recherche dans le terminal (Cmd+F)
- [ ] Zoom du texte (Cmd+plus, Cmd+moins, Cmd+0)
- [ ] Confirmation avant de fermer un terminal où une commande tourne
- [ ] Raccourcis de l'app interceptés avant le terminal
- [ ] Reprendre tes réglages Ghostty : Shift+Entrée = saut de ligne (Claude Code), Option gauche = Alt
- [ ] Textes d'autorisation macOS (Documents, Bureau...) dans l'Info.plist

## 4. Réglages en interface

- [ ] Panneau de réglages en sidebar
- [ ] Opacité et flou
- [ ] Police et taille du texte
- [ ] Thèmes de couleurs prêts à choisir (module GhosttyTheme du paquet)
- [ ] Couleurs de la coloration syntaxique et du texte grisé de l'autocomplétion (gris trop peu contrasté par défaut)
- [ ] Sélection lisible : le thème par défaut met un fond quasi noir (#303030) qui masque le texte sélectionné
- [ ] Image de fond (choix, opacité)
- [ ] Changements appliqués en direct, sans redémarrer

## 5. Page de démarrage

- [ ] Intégrer fastfetch
- [ ] 3 ou 4 presets au choix dans les réglages
- [ ] Position : gauche, centré, droite
- [ ] Option « aucune »

## 6. Vue agents

- [ ] Sidebar des sessions façon conversations
- [ ] Raccourci pour basculer vue agents / vue terminal
- [ ] Créer, renommer, fermer une session depuis la sidebar

## 7. DA Monocode

- [ ] Couleurs et tokens de base
- [ ] Effet verre sur la sidebar
- [ ] Effet de fondu de l'image de fond
- [ ] Boutons nouvel onglet et nouvelle fenêtre dans l'interface (en plus de Cmd+T et Cmd+N)

## 8. Autocomplétion des commandes connues

- [ ] Intégration zsh qui transmet la ligne en cours au terminal
- [ ] Suggestions via carapace (gh, git, docker...)
- [ ] Popup natif au niveau du curseur
- [ ] Validation au clavier (Tab, Entrée, Échap)

## 9. Finitions

- [ ] Icône définitive
- [ ] App installable (.app / .dmg)
- [ ] Utiliser le terminal au quotidien à la place de Ghostty
