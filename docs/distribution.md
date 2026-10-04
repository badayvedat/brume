# Distribuer Brume

Rien n'est encore publié. Le choix retenu : un DMG propre, un bouton de téléchargement sur le site, une release GitHub, et Homebrew.

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
1. Créer un certificat « Developer ID Application » sur le compte développeur, puis signer l'app avec lui à la place de « Brume Dev » (`CERT_NAME` dans `scripts/build-app.sh`), avec le runtime renforcé (`codesign --options runtime --timestamp`).
2. Envoyer le DMG à Apple pour vérification : `xcrun notarytool submit .build/Brume.dmg --keychain-profile <profil> --wait`.
3. Agrafer le résultat au DMG : `xcrun stapler staple .build/Brume.dmg`.

## Publier une nouvelle version

1. **Version** : monter `VERSION` dans `scripts/build-app.sh` (0.1.0 → 0.1.1 pour un correctif, 0.2.0 pour une évolution).
2. **Tests** : `bash scripts/run-tests.sh`.
3. **DMG** : `bash scripts/make-dmg.sh`, qui produit `.build/Brume.dmg`. Avec la licence Apple : signer, faire vérifier et agrafer (voir plus haut).
4. **Essai** : ouvrir le DMG, glisser Brume dans Applications, le lancer. Idéalement sur une autre session ou un autre Mac.
5. **Release GitHub** : commiter, puis
   ```bash
   git tag v0.1.1 && git push origin v0.1.1
   gh release create v0.1.1 .build/Brume.dmg --title "Brume 0.1.1" --notes "Ce qui change"
   ```
   Le fichier garde le nom `Brume.dmg` à chaque version : le lien `https://github.com/<compte>/brume/releases/latest/download/Brume.dmg` mène donc toujours à la dernière.
6. **Site** : le bouton « Télécharger » pointe vers ce lien. Rien à changer à chaque version.
7. **Homebrew** : dans le dépôt `<compte>/homebrew-tap`, mettre à jour `Casks/brume.rb` avec la nouvelle version et l'empreinte du DMG (`shasum -a 256 .build/Brume.dmg`). On installe alors avec `brew install --cask <compte>/tap/brume`.

   ```ruby
   cask "brume" do
     version "0.1.1"
     sha256 "<empreinte du DMG>"

     url "https://github.com/<compte>/brume/releases/download/v#{version}/Brume.dmg"
     name "Brume"
     desc "Simple, beautiful terminal for macOS"
     homepage "https://github.com/<compte>/brume"

     depends_on macos: ">= :tahoe"
     depends_on arch: :arm64

     app "Brume.app"

     zap trash: "~/Library/Application Support/Brume"
   end
   ```

   Comme Muxy, on peut confier cette mise à jour à un workflow GitHub déclenché par chaque release.

## À savoir

- L'app ne tourne que sur les Mac Apple Silicon (`arm64`) et demande macOS 26. Pour les Mac Intel, il faudrait une compilation pour les deux architectures, comme Ghostty.
- Identifiant de l'app : `app.brume.Brume` (`BUNDLE_ID` dans `scripts/build-app.sh`). Le changer fait redemander à macOS les autorisations de l'app.
- Le DMG embarque `LICENSE` et `THIRD_PARTY_LICENSES.md` dans l'app : la licence MIT des composants repris l'exige dès qu'on distribue.
