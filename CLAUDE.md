# Brume

Terminal macOS perso, simple et beau, qui remplace Ghostty. Étapes et avancement dans [suivi.md](suivi.md) : cocher en fin de tâche.

## Build

```bash
bash create-dev-cert.sh      # une fois par machine
bash build-app.sh --debug    # build rapide, installe dans /Applications, relance
bash build-app.sh            # release
```

- Seulement les Command Line Tools sur la machine, pas de Xcode : tout passe par SwiftPM et `build-app.sh`. Jamais de `.xcodeproj` ni de `xcodebuild`.
- Signer avec le certificat stable « Brume Dev ». En ad-hoc, macOS redemande les permissions (Documents, Bureau...) à chaque build.
- `swift test` nu ne trouve pas Swift Testing avec les CLT : passer par un wrapper comme `../Yuzu/run-tests.sh`.

## Contraintes

- GhosttyKit s'utilise précompilé (comme le `scripts/setup.sh` de Muxy) : le recompiler demanderait Xcode.
- Tout code repris de Muxy (MIT) garde sa mention de copyright dans le dépôt.
- Jamais `windowBackgroundDragBehavior(.enabled)` : déplacer la fenêtre par le fond casse la sélection de texte du terminal.
