# Distribuer Brume

Publié depuis la 0.1.0 (2026-10-11), sans licence Apple : un DMG, une release GitHub et le dépôt Homebrew `jeremy-prt/homebrew-tap`. Reste à faire : la landing page et son bouton de téléchargement.

## Comment font les autres

| App | Licence Apple (99 $ par an) | Distribution |
|---|---|---|
| Ghostty | Oui : app signée et vérifiée par Apple | DMG sur son site, Homebrew officiel (`brew install --cask ghostty`) |
| Muxy | Oui : signée et vérifiée par Apple dans son workflow GitHub de release | Releases GitHub, son site, et son propre dépôt Homebrew (`brew tap muxy-app/tap`), mis à jour automatiquement à chaque release |
| Monocode | Oui : à l'ouverture, macOS n'affiche que « app téléchargée depuis Internet » | DMG sur son propre serveur |

## Avec ou sans licence Apple

| | Sans licence | Avec licence (Apple Developer Program, 99 $ par an) |
|---|---|---|
| Mettre le code en open source sur GitHub | Oui | Oui |
| Ouvrir l'app téléchargée | macOS la bloque la première fois : Réglages Système › Confidentialité et sécurité › « Ouvrir quand même », une seule fois | Ouverture normale, avec seulement l'avertissement « téléchargée depuis Internet » |
| Son propre dépôt Homebrew (« tap ») | Possible, avec le même blocage à la première ouverture | Possible, sans blocage |
| Homebrew officiel | Refusé : depuis le 1er septembre 2026, Homebrew désactive les apps qui échouent au contrôle Gatekeeper | Possible, à condition que l'app soit assez connue |

Avec la licence, trois étapes s'ajoutent au DMG. Les outils sont déjà dans les Command Line Tools :
1. Créer un certificat « Developer ID Application » sur le compte développeur, puis signer l'app avec lui à la place de « Brume Dev » (`CERT_NAME` dans `scripts/build-app.sh`), avec le runtime renforcé (`codesign --options runtime --timestamp`), sur chaque `codesign` du script, Sparkle compris.
2. Envoyer le DMG à Apple pour vérification : `xcrun notarytool submit .build/Brume.dmg --keychain-profile <profil> --wait`.
3. Agrafer le résultat au DMG : `xcrun stapler staple .build/Brume.dmg`.

Ces deux dernières étapes se placent dans `scripts/release.sh` entre le DMG et sa signature pour Sparkle : l'agrafe modifie le fichier, une signature calculée avant ne correspondrait plus.

## Publier une nouvelle version

Brume se met à jour par [Sparkle](https://sparkle-project.org) : une fois par jour, ou par « Rechercher les mises à jour… », l'app lit `appcast.xml` sur la branche `main` (`SUFeedURL` dans `scripts/build-app.sh`) et compare son numéro de build (`CFBundleVersion`, tiré de `BUILD_NUMBER`) au `sparkle:version` de chaque entrée. Une entrée plus récente lui propose le DMG de la release GitHub, dont elle vérifie la signature EdDSA avec la clé publique de l'Info.plist (`SUPublicEDKey`).

**Le flux ne marche que si le dépôt est public** : sinon `appcast.xml` et les DMG des releases répondent 404 aux apps installées.

1. **Changelog** : ajouter en tête de `CHANGELOG.md` une section datée, `## 0.2.0 - 2026-10-04`, avec ses listes sous `### Added`, `### Changed` et `### Fixed`. Elle sert de notes à la fenêtre de Sparkle et à la release GitHub.
2. **Préparer** : depuis `main`, arbre propre, `bash scripts/release.sh 0.2.0` (0.1.0 → 0.1.1 pour un correctif, 0.2.0 pour une évolution). Le script :
   - refuse un arbre sale, une branche autre que `main`, une version déjà taguée ou absente du changelog ;
   - monte `VERSION` et `BUILD_NUMBER` (+1) dans `scripts/build-app.sh` ;
   - lance les tests, puis `scripts/make-dmg.sh`, qui produit `.build/Brume.dmg` ;
   - signe le DMG avec `sign_update`, qui lit la clé privée EdDSA dans le trousseau : macOS peut demander d'y autoriser l'accès ;
   - ajoute l'entrée de la version en tête de `appcast.xml` : notes du changelog en HTML, URL du DMG, signature, taille, macOS 26 minimum ;
   - affiche les commandes de publication et le bloc Homebrew, sans rien lancer.

   En cas d'échec, il remet `scripts/build-app.sh` et `appcast.xml` comme avant.
3. **Essai** : ouvrir le DMG, glisser Brume dans Applications, le lancer. Idéalement sur une autre session ou un autre Mac.
4. **Publier** : lancer les commandes affichées, dans l'ordre : commit, tag, push du tag, `gh release create`, puis push de `main`. L'appcast ne passe en ligne qu'avec ce dernier push, une fois le DMG téléchargeable.
   Le fichier garde le nom `Brume.dmg` à chaque version : le lien `https://github.com/jeremy-prt/brume/releases/latest/download/Brume.dmg` mène donc toujours à la dernière.
5. **Site** : le bouton « Télécharger » pointe vers ce lien. Rien à changer à chaque version.
6. **Homebrew** : dans le dépôt `jeremy-prt/homebrew-tap`, mettre à jour `Casks/brume.rb` avec la version et l'empreinte du DMG affichées par le script. On installe alors avec `brew install --cask jeremy-prt/tap/brume`. Vérifier le fichier avec `brew style Casks/brume.rb` avant de pousser : Homebrew refuse la plateforme dans `desc`. `auto_updates` dit à Homebrew que Sparkle met l'app à jour lui-même.

   ```ruby
   cask "brume" do
     version "0.2.0"
     sha256 "<empreinte du DMG>"

     url "https://github.com/jeremy-prt/brume/releases/download/v#{version}/Brume.dmg"
     name "Brume"
     desc "Terminal, reimagined"
     homepage "https://github.com/jeremy-prt/brume"

     auto_updates true
     depends_on arch: :arm64
     depends_on macos: :tahoe

     app "Brume.app"

     zap trash: "~/Library/Application Support/Brume"
   end
   ```

   Comme Muxy, on peut confier cette mise à jour à un workflow GitHub déclenché par chaque release.

### Sparkle

- Le framework vient du paquet SwiftPM (`Package.swift`), à version figée ; `scripts/build-app.sh` le copie dans `Contents/Frameworks` et le signe. Les outils de publication (`sign_update`, `generate_appcast`, `generate_keys`) sont tirés de l'archive de la même release par `scripts/setup.sh`, dans `Vendor/sparkle/bin/`. Pour monter de version : changer les deux ensemble.
- La clé EdDSA est celle d'Orby : la publique dans `scripts/build-app.sh`, la privée dans le trousseau de Jérémy. Ne jamais en générer une autre : les apps déjà installées refuseraient toute mise à jour signée avec elle.
- `BUILD_NUMBER` ne redescend jamais et n'est monté que par `scripts/release.sh` : une version au numéro plus bas que celui installé n'est jamais proposée.
- Les deux interrupteurs des réglages (recherche et installation automatiques) sont gardés par Sparkle dans les défauts de l'app, pas dans `settings.json`.

## À savoir

- L'app ne tourne que sur les Mac Apple Silicon (`arm64`) et demande macOS 26. Pour les Mac Intel, il faudrait une compilation pour les deux architectures, comme Ghostty.
- Identifiant de l'app : `app.brume.Brume` (`BUNDLE_ID` dans `scripts/build-app.sh`). Le changer fait redemander à macOS les autorisations de l'app.
- Le DMG embarque `LICENSE` et `THIRD_PARTY_LICENSES.md` dans l'app : la licence MIT des composants repris l'exige dès qu'on distribue.
