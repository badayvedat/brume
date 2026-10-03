# Brume

Terminal macOS perso, simple et beau, qui remplace Ghostty. Étapes et avancement dans [suivi.md](suivi.md) : cocher en fin de tâche.

## Build

```bash
bash create-dev-cert.sh      # une fois par machine
bash setup.sh                # avant un `swift build` nu (build-app.sh le lance seul)
bash build-app.sh --debug    # build rapide, installe dans /Applications, relance
bash build-app.sh            # release
```

- Seulement les Command Line Tools sur la machine, pas de Xcode : tout passe par SwiftPM et `build-app.sh`. Jamais de `.xcodeproj` ni de `xcodebuild`. Pas de macros SwiftUI (`@Entry`, `#Preview`) : leur plugin n'existe qu'avec Xcode.
- Signer avec le certificat stable « Brume Dev ». En ad-hoc, macOS redemande les permissions (Documents, Bureau...) à chaque build.
- Vérifier un rendu : `bash capture.sh` capture la seule fenêtre Brume, puis lire l'image. Pas de capture plein écran. Elle ne montre pas le bureau flouté du style Verre : pour le voir, `screencapture -R` sur les bornes de la fenêtre. Claude a l'Accessibilité : raccourcis et frappe via `osascript` (System Events), clics et glisser via des `CGEvent` postés aux coordonnées de la fenêtre.
- Capturer sans toucher à la fenêtre de Jérémy : une copie du `.app` lancée par `open -n --env CFFIXED_USER_HOME=<dossier>` prend session et réglages dans `<dossier>/Library/Application Support/Brume/`. Avec `open -g`, aucune fenêtre ne s'ouvre ; `screencapture -l` échoue si la fenêtre est sur un autre bureau.
- Le `.zshrc` de Jérémy charge déjà ses greffons brew, qui masquent ceux embarqués : pour tester ceux de Brume, lancer `open --env ZDOTDIR=<dossier vide> /Applications/Brume.app`.
- Tests : `bash run-tests.sh`. `swift test` nu ne trouve pas Swift Testing avec les CLT.
- Brume rouvre au lancement (réglage « Restaurer la session ») les fenêtres enregistrées en quittant (`~/Library/Application Support/Brume/session.json`) : supprimer ce fichier pour repartir d'une fenêtre neuve. Un arrêt brutal (`killall`, relance par `build-app.sh`) n'enregistre rien.

## Contraintes

- Moteur : libghostty-spm, copié dans `Vendor/` (gitignoré) par `setup.sh` qui applique `Patches/`. Ne jamais éditer `Vendor/` à la main : tout changement passe par un patch.
- Les `.bundle` de ressources SwiftPM vont dans `Contents/Resources` : codesign refuse tout contenu à la racine de l'app, et c'est ce que le patch fait lire au paquet.
- L'intégration shell du paquet est une réécriture qui ignore `sudo` et `path` de Ghostty : activer une option dans la config ne suffit pas, vérifier `shell-integration/zsh/ghostty-integration`. `ssh-*` y est ajouté par `Patches/`.
- Un raccourci de l'app se déclare dans le menu (`App/*Commands.swift`) : le patch `menu-keys` lui donne la priorité sur ceux du moteur, dont le paquet ne transmet pas les actions. Pas de `keybind = ...=unbind`.
- Une vue terminal recréée par SwiftUI tue son shell : garder son identité (terminaux de toutes les zones à plat dans un `ForEach` par identifiant, jamais déplacés d'un conteneur à l'autre). Les onglets cachés restent montés, transparents, avec `isSurfaceVisible = false`.
- Onglets maison, pas d'onglets natifs (`tabbingMode = .disallowed`). Pas de `isMovable = false` comme Muxy : `performDrag` de `WindowDragArea` ne déplace plus rien.
- Tout code repris de Muxy (MIT) garde sa mention de copyright dans le dépôt.
- Pas de `Image(systemName:)` : passer par `SystemSymbol` (`DesignSystem/`). Chargés après le moteur, des symboles sortent vides, au hasard du lancement.
- Pas de `NSAlert.runModal()` : sur macOS 27, l'alerte modale plante en dessinant un symbole système. Toujours en feuille (`beginSheetModal`), comme `CloseConfirmation`.
- Brume est toujours sombre (`AppDelegate`), le thème du moteur aussi : ne jamais régler l'apparence d'une fenêtre d'après la couleur du terminal, ça boucle et la fenêtre clignote.
- Menus : `PopupMenu` (`DesignSystem/`), pas `Menu`, `.contextMenu` ni `NSMenu` : chargés après le moteur, leurs glyphes ⌘ sortent vides, et leur surlignage prend l'accent du Mac.
- Survol : `.onHover` de SwiftUI, pas de `NSTrackingArea` dans une vue représentée. SwiftUI la repose en redessinant et l'entrée de la souris se perd, et elle ignore `allowsHitTesting(false)` (infobulles des terminaux cachés sous les réglages).
- Pas de `.toolbar` SwiftUI ni de `windowToolbarStyle` : la barre d'outils vide `.unifiedCompact` posée par `WindowTitlebar` donne sa hauteur de 40 à la barre d'onglets et y centre les boutons rouge, jaune, vert.
- Jamais `windowBackgroundDragBehavior(.enabled)` : déplacer la fenêtre par le fond casse la sélection de texte du terminal.
