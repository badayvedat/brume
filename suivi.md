# Brume

Terminal perso pour macOS, simple et beau, qui remplace Ghostty.

## Décisions

- macOS uniquement : Swift + SwiftUI, moteur Ghostty via le paquet libghostty-spm (vue terminal fournie, suit Ghostty officiel).
- Sans Xcode : `swift build` + script qui fabrique le .app, comme Orby. GhosttyKit téléchargé précompilé.
- Repo neuf sur le compte GitHub perso, sans historique. Muxy (MIT) sert de référence : pièces utiles par étape dans [docs/reprise-muxy.md](docs/reprise-muxy.md).
- Terminal proche de Ghostty, pas de fonctions en trop. Barre du haut à la Muxy : onglets maison et boutons. Au choix, les onglets listés dans une barre latérale à gauche (onglets verticaux).
- Un onglet contient ses splits, comme Ghostty, Arc et Dia (chapitre 7) : remplace les zones façon Muxy du chapitre 4, où chaque split avait ses onglets.
- DA inspirée de Monocode (MIT) : flou et teinte, sans image de fond.

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

- [x] Onglets gérés dans la fenêtre à la place des onglets natifs de macOS : une seule liste, que la barre du haut et la barre latérale affichent
- [ ] Choisir ce qu'on reprend d'autre de Muxy (disposition, précédent / suivant...)
- [x] Barre d'onglets maison dans la barre de titre : onglets arrondis, croix, à la place des onglets natifs
- [x] Bouton nouvel onglet dans la barre (en plus de Cmd+T)
- [x] Bouton nouvelle fenêtre dans la barre (en plus de Cmd+N)
- [x] Réordonner les onglets en les glissant
- [x] Renommer un onglet : double-clic, clic droit ou Cmd+Shift+R, champ vidé = nom automatique
- [x] Numéros des onglets affichés tant qu'on tient Cmd, pour Cmd+1, Cmd+2...
- [x] Boutons de split dans la barre : à droite, en dessous
- [x] Infobulles maison sous les boutons et les onglets, avec le raccourci
- [x] Zones façon Muxy : chaque split a sa barre d'onglets, un onglet = un terminal, numéros sur toute la fenêtre
- [x] Glisser un onglet : au centre d'une zone il la rejoint, près d'un bord il ouvre une zone de ce côté
- [x] Séparateur des zones en couleur d'accent au survol
- [x] Déplacer l'onglet vers la zone voisine au clavier (Ctrl+Cmd+flèche), ou ouvrir une zone de ce côté
- [x] Icône terminal dans l'onglet, remplacée par le numéro tant que Cmd est tenu
- [x] Menu « ... » : ouvrir le dossier du terminal dans le Finder ou un éditeur détecté (icône de l'app), copier le chemin. Les réglages y entreront avec le chapitre 5
- [x] Clic droit sur un onglet : fermer les autres, fermer ceux de droite, couleur (6 au choix)
- [x] Restaurer au relancement les fenêtres, zones, onglets, dossiers, noms et couleurs
- [x] « Réinitialiser les onglets » dans le menu ... : la fenêtre revient à un seul onglet (le terminal actif), sans couleurs, noms ni zoom

## 5. Réglages en interface

Comme Monocode : réglages dans la fenêtre, gris neutres, seule la couleur choisie change. Brume reste toujours sombre.

- [x] Page de réglages dans la fenêtre du terminal (Cmd+virgule, menu « ... »), barre latérale Général / Apparence, Échap ou Cmd+W pour revenir, fondu
- [x] Restaurer ou non la session au démarrage (Général)
- [x] Effet verre en interrupteur, avec opacité et flou en trois crans (faible, moyen, fort) quand il est allumé, bascule en fondu
- [x] Couleur en 10 pastilles (Brume par défaut, noir, bleu...) : le fond en prend la teinte (faible, moyenne, forte), le curseur, la sélection et les éléments actifs la couleur pleine, en fondu
- [x] Police en liste (JetBrains Mono, Menlo, Monaco et 9 polices libres embarquées), taille de départ en − / +
- [x] Langue de l'interface (français / anglais), en direct
- [x] Menus maison façon Monocode (« ... » et clic droit sur un onglet), raccourcis affichés en entier
- [x] Coloration des commandes : 16 palettes reprises de thèmes connus, aperçu dépliable

## 6. Page de démarrage

- [x] Intégrer fastfetch (2.69 précompilé, figé par empreinte, embarqué et signé dans l'app)
- [x] Page « Accueil » des réglages : visuel, texte ou les deux. 8 visuels en pixel art à la couleur d'accent (fantôme couronné, Saturne, nuage, soucoupe, slime, diamant, lune, champignon) + la pomme officielle de fastfetch en ASCII (une seule taille, retirée si elle ne tient pas), visuel et texte en petit / moyen / grand, informations aucune / essentiel / par catégorie
- [x] Terminal trop petit (split) : la page prend une taille plus petite, puis se passe du visuel
- [x] Réglages façon Monocode : rien n'apparaît ni ne disparaît (réglages sans effet estompés), visuels en vignettes, sélecteurs à pastille glissante, aperçu en fondu, menus qui s'ouvrent en fondu
- [x] Position : gauche, centré, droite
- [x] Option « aucune » : interrupteur, visuel et informations désactivables
- [x] Aperçu en direct dans les réglages, rendu par fastfetch

## 7. Onglets verticaux

Comme les onglets verticaux de Chrome, Firefox ou Arc : les terminaux listés dans une barre latérale à gauche plutôt qu'en haut. Pas une vue « agents » : rien pour surveiller des processus.

- [x] Barre latérale des onglets à gauche, au choix avec la barre du haut, en-tête de l'onglet affiché à droite, largeur réglable au bord (160 à 360)
- [x] Un onglet divisé (⌘D) devient « Groupe 1 », « Groupe 2 »… : en haut un seul onglet à l'icône split, sur le côté un groupe repliable (chevron à droite) dont chaque terminal se renomme, se colore, se glisse (échange de place, ou dépôt sur un terminal avec la vraie place en aperçu) ; « Dissocier le groupe », « Sortir du groupe » ; le terminal d'origine garde le nom de l'onglet divisé
- [x] Menus selon le contexte (onglet, groupe, terminal) et clic droit dans le terminal : copier, coller, diviser, agrandir, sortir du groupe, fermer
- [x] Chaque onglet a un nom, une couleur et une icône (12 au choix : projet, serveur, machine, cloud, base de données, IA, production…)
- [x] Au relancement, on retrouve ses onglets tels quels, groupes repliés compris ; l'ancienne session (zones) est convertie
- [x] Raccourci clavier pour basculer entre les onglets en haut et la barre latérale (⌃⌘S, celui de macOS pour la barre latérale), aussi dans le menu « … » et dans Réglages › Général, en fondu
- [x] Dans la barre latérale, les mêmes actions qu'en haut : créer, renommer, réordonner, fermer, couleur et icône ; ouverture en accordéon, fermeture nette où les voisins glissent, pas de croix sur le seul onglet (il se ferme avec la fenêtre)
- [x] Pastille sur l'onglet : elle respire quand Claude Code travaille, anneau s'il donne un pourcentage, pleine quand une commande finit, sonne ou notifie dans un onglet caché (OSC 9;4 par le patch `tab-progress`)
- [x] Agrandir le split actif à tout l'onglet (⇧⌘↩ comme Ghostty), bouton à l'accent pour revenir

## 8. DA Monocode

- [x] Couleurs et tokens de base (`Ink` : un blanc à différentes opacités)
- [x] Barre d'onglets aux mesures de Monocode (40 de haut, onglets de 30)
- [x] Effet verre sur la barre latérale des réglages : essayé puis écarté, elle reste dans la DA du terminal (code gardé en commentaire dans `SettingsPage`)

## 9. Autocomplétion des commandes connues

- [x] Menu de complétion de zsh (Tab, flèches, ⇧Tab, Échap), complétions de Homebrew, réglages pour couper les suggestions de l'historique et l'autocomplétion
- [ ] Intégration zsh qui transmet la ligne en cours au terminal
- [ ] Suggestions via carapace (gh, git, docker...)
- [ ] Popup natif au niveau du curseur
- [ ] Validation au clavier (Tab, Entrée, Échap)

## 10. Finitions

- [ ] Icône définitive
- [ ] App installable (.app / .dmg)
- [ ] Utiliser le terminal au quotidien à la place de Ghostty
