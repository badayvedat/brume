# Brume

Terminal perso pour macOS, simple et beau, qui remplace Ghostty.

## Décisions

- macOS uniquement : Swift + SwiftUI, moteur GhosttyKit (libghostty).
- Sans Xcode : `swift build` + script qui fabrique le .app, comme Orby. GhosttyKit téléchargé précompilé.
- Repo neuf sur le compte GitHub perso, sans historique : on reprend de Muxy (MIT) seulement ce qui sert, en gardant sa mention de licence.
- Interface proche de Ghostty en vue terminal : pas de fonctions en trop.
- DA inspirée de Monocode (MIT) : flou, teinte réglable, image de fond fondue.

## 1. Mise en place

- [x] Choisir le nom du terminal
- [x] Créer le repo sur le compte GitHub perso
- [x] Package Swift vide qui ouvre une fenêtre
- [x] Script de build qui fabrique `Brume.app`

## 2. Reprise de Muxy

- [ ] Lister ce que fait Muxy, trier garder / jeter
- [ ] Copier uniquement le nécessaire : moteur terminal, sidebar, réglages
- [ ] Vue terminal aussi épurée que Ghostty
- [ ] Compiler et lancer un terminal qui marche

## 3. Base du terminal

- [ ] Annoncer `xterm-256color` par défaut (nano en SSH)
- [ ] Coloration syntaxique des commandes active par défaut
- [ ] Autocomplétion depuis l'historique (texte grisé) active par défaut
- [ ] Raccourcis de base (onglets, fermer, nouvelle fenêtre)

## 4. Réglages en interface

- [ ] Panneau de réglages en sidebar
- [ ] Opacité et flou
- [ ] Police et taille du texte
- [ ] Thèmes de couleurs prêts à choisir
- [ ] Couleurs de la coloration syntaxique
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

## 8. Autocomplétion des commandes connues

- [ ] Intégration zsh qui transmet la ligne en cours au terminal
- [ ] Suggestions via carapace (gh, git, docker...)
- [ ] Popup natif au niveau du curseur
- [ ] Validation au clavier (Tab, Entrée, Échap)

## 9. Finitions

- [ ] Icône définitive
- [ ] App installable (.app / .dmg)
- [ ] Utiliser le terminal au quotidien à la place de Ghostty
