# Brume

Brume est un terminal pour macOS, simple et beau, bâti sur le moteur de [Ghostty](https://ghostty.org) grâce au paquet [libghostty-spm](https://github.com/Lakr233/libghostty-spm). Il y ajoute l'essentiel et rien de plus : onglets en haut ou en barre latérale, splits, fenêtre transparente sur le bureau flouté, interface en français et en anglais.

## Compiler

Il faut macOS 26 et les Command Line Tools (Swift 6.2). Xcode n'est pas nécessaire : tout passe par SwiftPM.

```bash
bash scripts/create-dev-cert.sh                  # une fois par machine : certificat de signature local
bash scripts/build-app.sh                        # release, installe dans /Applications et lance Brume
bash scripts/build-app.sh --debug                # build rapide
bash scripts/build-app.sh --debug --no-install   # fabrique .build/app/Brume.app sans l'installer
bash scripts/run-tests.sh                        # tests
```

`scripts/setup.sh` télécharge les dépendances à des versions figées dans `Vendor/` (moteur, greffons zsh, fastfetch) et applique `Patches/`. Les autres scripts le lancent d'eux-mêmes : il ne sert à la main qu'avant un `swift build` nu.

Sans le certificat, l'app est signée en ad-hoc et macOS redemande ses autorisations (Documents, Bureau...) à chaque build.

## Licences

Code repris et composants tiers : [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).
