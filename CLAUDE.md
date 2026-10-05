# Brume

Terminal macOS simple et beau, bâti sur le moteur de Ghostty (paquet libghostty-spm), en Swift et SwiftUI.

Avant de toucher à l'icône de l'app, aux visuels de la page Démarrage, de tester ou de publier une version : lire `docs/icone.md`, `docs/visuels-demarrage.md`, `docs/tester-une-version.md` ou `docs/distribution.md`.

## Build

```bash
bash scripts/create-dev-cert.sh      # une fois par machine
bash scripts/setup.sh                # avant un `swift build` nu (le script de build le lance seul)
bash scripts/build-app.sh --debug    # build rapide, installe dans /Applications, relance
bash scripts/build-app.sh            # release
bash scripts/build-app.sh --debug --no-install   # fabrique le .app sans toucher au Brume ouvert
bash scripts/make-icon.sh            # Resources/AppIcon.icns depuis Resources/AppIcon.svg
bash scripts/make-dmg.sh             # .build/Brume.dmg, fond dans Resources/dmg/
```

- Seulement les Command Line Tools, pas de Xcode : tout passe par SwiftPM et `scripts/build-app.sh`. Jamais de `.xcodeproj` ni de `xcodebuild`. Pas de macros SwiftUI (`@Entry`, `#Preview`) : leur plugin n'existe qu'avec Xcode.
- Signer avec le certificat stable « Brume Dev ». En ad-hoc, macOS redemande les permissions (Documents, Bureau...) à chaque build.
- Tests : `bash scripts/run-tests.sh`. `swift test` nu ne trouve pas Swift Testing avec les CLT.
- Vérifier un rendu : `bash scripts/capture.sh` capture la seule fenêtre Brume, puis lire l'image. Pas de capture plein écran. Elle ne montre pas le bureau flouté du style Verre : pour le voir, `screencapture -R` sur les bornes de la fenêtre.
- Vérifier une page des réglages : lancer l'app avec `--args -BrumeSettings welcome` (`general`, `appearance`), plus `-BrumePreview YES` pour l'aperçu de la page Démarrage.
- Une copie du `.app` lancée par `open -n --env CFFIXED_USER_HOME=<dossier>` prend session et réglages dans `<dossier>/Library/Application Support/Brume/`, sans toucher à ceux du Brume ouvert. Les défauts de l'app (préférences de Sparkle), eux, restent partagés. Avec `open -g`, aucune fenêtre ne s'ouvre ; `screencapture -l` échoue si la fenêtre est sur un autre bureau.
- Sans clic, sur une copie : `--env ZDOTDIR=<dossier>` dont le `.zshrc` fait `exec sleep 300` simule une commande en cours ; `NSRunningApplication(processIdentifier:)` `.hide()` / `.terminate()` (JXA) masque ou quitte cette copie seule.
- Un `.zshrc` qui charge déjà des greffons brew masque ceux embarqués : pour tester ceux de Brume, lancer `open --env ZDOTDIR=<dossier vide> /Applications/Brume.app`.
- Tester un comportement de zsh (complétion, greffons) sans fenêtre : sourcer le bloc voulu de `Vendor/.../shell-integration/zsh/ghostty-integration` dans un `zsh -f -i` piloté par `expect` (fourni par macOS). `zpty` ne rend pas la sortie de façon fiable.
- Brume rouvre au lancement (réglage « Restaurer la session ») les fenêtres de `~/Library/Application Support/Brume/session.json`, réécrit deux secondes après un changement et à la sortie (`killall`, SIGTERM de `scripts/build-app.sh` compris) : le supprimer, Brume fermé, pour repartir d'une fenêtre neuve. Même `kill -9` ne perd que les deux dernières secondes.

## Contraintes

- Moteur : libghostty-spm, copié dans `Vendor/` (gitignoré) par `scripts/setup.sh` qui applique `Patches/`. Ne jamais éditer `Vendor/` à la main : tout changement passe par un patch, sauf ce qu'une sous-classe de la vue terminal fournie par `makePlatformView` suffit à faire (`BrumeTerminalView`). Les patchs s'appliquent par ordre alphabétique : un patch qui touche un fichier déjà patché se nomme après l'autre.
- Les `.bundle` de ressources SwiftPM vont dans `Contents/Resources` : codesign refuse tout contenu à la racine de l'app, et c'est ce que le patch fait lire au paquet.
- L'intégration shell du paquet est une réécriture qui ignore `sudo` et `path` de Ghostty : activer une option dans la config ne suffit pas, vérifier `shell-integration/zsh/ghostty-integration`. `ssh-*` y est ajouté par `Patches/`.
- Un raccourci de l'app se déclare dans le menu (`App/*Commands.swift`) : le patch `menu-keys` lui donne la priorité sur ceux du moteur, dont le paquet ne transmet pas les actions. Pas de `keybind = ...=unbind`. Une commande qui agit sur les terminaux passe par `workspace.showingTerminals { }` : sinon elle agit sous la page Réglages ou la carte « Réinitialiser » sans qu'on la voie. Un article ne porte qu'un raccourci : un second raccourci fixe (⌃Tab) s'intercepte dans `BrumeTerminalView.performKeyEquivalent`, que toutes les vues terminal de la fenêtre reçoivent, même cachées.
- Raccourcis modifiables dans les réglages (`ShortcutAction`) : jamais écrits en dur, ni au menu ni dans une infobulle, passer par `settings.keyboardShortcut(_:)` et `settings.shortcutLabel(_:)`. Un nouveau raccourci fixe s'ajoute à `ReservedShortcut.all`, sinon la page Raccourcis ne voit pas le conflit.
- Une vue terminal recréée par SwiftUI tue son shell : garder son identité (terminaux de tous les onglets à plat dans un `ForEach` par identifiant, jamais déplacés d'un conteneur à l'autre). Les onglets cachés restent montés, transparents, avec `isSurfaceVisible = false`.
- Onglets maison, pas d'onglets natifs (`tabbingMode = .disallowed`). Pas de `isMovable = false` : `performDrag` de `WindowDragArea` ne déplace plus rien.
- Tout code repris d'un projet tiers garde sa mention de copyright en tête de fichier et s'ajoute à `THIRD_PARTY_LICENSES.md`, comme tout composant embarqué dans l'app.
- Pas de `Image(systemName:)` : passer par `SystemSymbol` (`DesignSystem/`). Chargés après le moteur, des symboles sortent vides, au hasard du lancement.
- Pas de `NSAlert.runModal()` : sur macOS 27, l'alerte modale plante en dessinant un symbole système. Toujours en feuille (`beginSheetModal`), comme `CloseConfirmation`. Une alerte de l'app (quitter, mises à jour) se pose sur `TerminalWorkspace.front()`, jamais `NSApp.keyWindow` : ce peut être le panneau d'un `PopupMenu`, qui emporte la feuille, ou rien si Brume est masqué. Sparkle en ouvre aussi : `UpdaterUserDriver` les remplace, d'où un `SPUUpdater` monté à la main plutôt que `SPUStandardUpdaterController`.
- Brume est toujours sombre (`AppDelegate`), le thème du moteur aussi : ne jamais régler l'apparence d'une fenêtre d'après la couleur du terminal, ça boucle et la fenêtre clignote.
- Menus : `PopupMenu` (`DesignSystem/`), pas `Menu`, `.contextMenu` ni `NSMenu` : chargés après le moteur, leurs glyphes ⌘ sortent vides, et leur surlignage prend l'accent du Mac.
- Survol : `.onHover` de SwiftUI, pas de `NSTrackingArea` dans une vue représentée. SwiftUI la repose en redessinant et l'entrée de la souris se perd, et elle ignore `allowsHitTesting(false)` (infobulles des terminaux cachés sous les réglages).
- Pas de `.toolbar` SwiftUI ni de `windowToolbarStyle` : la barre d'outils vide `.unifiedCompact` posée par `WindowTitlebar` donne sa hauteur de 40 à la barre d'onglets et y centre les boutons rouge, jaune, vert.
- Jamais `windowBackgroundDragBehavior(.enabled)` : déplacer la fenêtre par le fond casse la sélection de texte du terminal.
