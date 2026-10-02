# Brume

Terminal macOS perso, simple et beau, qui remplace Ghostty. Étapes et avancement dans [suivi.md](suivi.md) : cocher en fin de tâche.

## Build

```bash
bash create-dev-cert.sh      # une fois par machine
bash setup.sh                # avant un `swift build` nu (build-app.sh le lance seul)
bash build-app.sh --debug    # build rapide, installe dans /Applications, relance
bash build-app.sh            # release
```

- Seulement les Command Line Tools sur la machine, pas de Xcode : tout passe par SwiftPM et `build-app.sh`. Jamais de `.xcodeproj` ni de `xcodebuild`.
- Signer avec le certificat stable « Brume Dev ». En ad-hoc, macOS redemande les permissions (Documents, Bureau...) à chaque build.
- Vérifier un rendu : `bash capture.sh` capture la seule fenêtre Brume, puis lire l'image. Pas de capture plein écran.
- Le `.zshrc` de Jérémy charge déjà ses greffons brew, qui masquent ceux embarqués : pour tester ceux de Brume, lancer `open --env ZDOTDIR=<dossier vide> /Applications/Brume.app`.
- `swift test` nu ne trouve pas Swift Testing avec les CLT : passer par un wrapper comme `../Yuzu/run-tests.sh`.

## Contraintes

- Moteur : libghostty-spm, copié dans `Vendor/` (gitignoré) par `setup.sh` qui applique `Patches/`. Ne jamais éditer `Vendor/` à la main : tout changement passe par un patch.
- Les `.bundle` de ressources SwiftPM vont dans `Contents/Resources` : codesign refuse tout contenu à la racine de l'app, et c'est ce que le patch fait lire au paquet.
- L'intégration shell du paquet est une réécriture qui ignore `sudo` et `path` de Ghostty : activer une option dans la config ne suffit pas, vérifier `shell-integration/zsh/ghostty-integration`. `ssh-*` y est ajouté par `Patches/`.
- Tout code repris de Muxy (MIT) garde sa mention de copyright dans le dépôt.
- Jamais `windowBackgroundDragBehavior(.enabled)` : déplacer la fenêtre par le fond casse la sélection de texte du terminal.
