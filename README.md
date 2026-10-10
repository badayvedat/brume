# Brume

Brume is the macOS terminal, reimagined. Built on the [Ghostty](https://ghostty.org) engine through the [libghostty-spm](https://github.com/Lakr233/libghostty-spm) package, it adds only the essentials: tabs at the top or in a sidebar, split terminals, a translucent window over the blurred desktop, and an interface in English and French.

## Install

Download `Brume.dmg` from the [latest release](../../releases/latest), open it and drag Brume to Applications.

Or with Homebrew:

```bash
brew install --cask jeremy-prt/tap/brume
```

Brume is not notarized by Apple yet. The first time you open it, macOS blocks it: go to **System Settings › Privacy & Security** and click **Open Anyway**. This is only needed once.

## Build from source

Requires macOS 26 and the Command Line Tools (Swift 6.2). Xcode is not needed: everything goes through SwiftPM.

```bash
bash scripts/create-dev-cert.sh                  # once per machine: local signing certificate
bash scripts/build-app.sh                        # release build, installs to /Applications and launches Brume
bash scripts/build-app.sh --debug                # faster debug build
bash scripts/build-app.sh --debug --no-install   # builds .build/app/Brume.app without installing it
bash scripts/run-tests.sh                        # tests
bash scripts/make-dmg.sh                         # release build packaged as .build/Brume.dmg
```

`scripts/setup.sh` downloads pinned dependencies into `Vendor/` (engine, zsh plugins, fastfetch) and applies `Patches/`. The other scripts run it on their own.

Without the certificate, the app is signed ad hoc and macOS asks for its permissions (Documents, Desktop...) again after every build.

## License

Brume is released under the [MIT License](LICENSE). Third-party code and components: [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).
