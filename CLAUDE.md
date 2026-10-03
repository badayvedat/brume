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
- Vérifier un rendu : `bash capture.sh` capture la seule fenêtre Brume, puis lire l'image. Pas de capture plein écran. Claude ne peut pas taper au clavier (pas d'Accessibilité) : demander à Jérémy de tester les raccourcis.
- Le `.zshrc` de Jérémy charge déjà ses greffons brew, qui masquent ceux embarqués : pour tester ceux de Brume, lancer `open --env ZDOTDIR=<dossier vide> /Applications/Brume.app`.
- Tests : `bash run-tests.sh`. `swift test` nu ne trouve pas Swift Testing avec les CLT.

## Contraintes

- Moteur : libghostty-spm, copié dans `Vendor/` (gitignoré) par `setup.sh` qui applique `Patches/`. Ne jamais éditer `Vendor/` à la main : tout changement passe par un patch.
- Les `.bundle` de ressources SwiftPM vont dans `Contents/Resources` : codesign refuse tout contenu à la racine de l'app, et c'est ce que le patch fait lire au paquet.
- L'intégration shell du paquet est une réécriture qui ignore `sudo` et `path` de Ghostty : activer une option dans la config ne suffit pas, vérifier `shell-integration/zsh/ghostty-integration`. `ssh-*` y est ajouté par `Patches/`.
- Les raccourcis Cmd par défaut de Ghostty (Cmd+D, Cmd+F, Cmd+T...) sont avalés par le terminal avant le menu, et le paquet ne transmet pas leurs actions : un raccourci de l'app doit être libéré par `keybind = <touche>=unbind` (voir `TerminalWorkspace.swift`).
- Une vue terminal recréée par SwiftUI tue son shell : garder son identité (volets à plat dans un `ForEach` par identifiant, jamais déplacés d'un conteneur à l'autre).
- Tout code repris de Muxy (MIT) garde sa mention de copyright dans le dépôt.
- Pas de `Image(systemName:)` : passer par `SystemSymbol` (`DesignSystem/`). Chargés après le moteur, des symboles sortent vides, au hasard du lancement.
- Le thème du moteur suit déjà l'apparence système : ne jamais régler l'apparence d'une fenêtre d'après la couleur du terminal, ça boucle et la fenêtre clignote.
- Jamais `windowBackgroundDragBehavior(.enabled)` : déplacer la fenêtre par le fond casse la sélection de texte du terminal.
