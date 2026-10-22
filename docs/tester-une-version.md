# Tester une nouvelle version sur son Mac

Pas besoin de désinstaller l'ancienne version : glisser la nouvelle dans Applications la remplace. Les réglages, la session et les onglets ne sont pas dans l'app mais dans `~/Library/Application Support/Brume/` : ils restent d'une version à l'autre.

## Installer la nouvelle version

1. `bash scripts/make-dmg.sh`, puis `cp .build/Brume.dmg ~/Downloads/`.
2. Quitter Brume (⌘Q). Le Finder ne peut pas remplacer une app ouverte.
3. Double-cliquer `Brume.dmg` dans Téléchargements, glisser Brume sur Applications, puis choisir « Remplacer ».
4. Éjecter le DMG (le bouton ⏏ dans la barre latérale du Finder), lancer Brume et tester.

Pendant le développement, `bash scripts/build-app.sh --debug` fait la même chose en une commande : il remplace l'app dans Applications et la relance. Le DMG sert à vérifier ce que recevra un utilisateur.

## Repartir de zéro

Pour tester comme un nouvel utilisateur :
- Mettre `/Applications/Brume.app` à la corbeille.
- Mettre aussi `~/Library/Application Support/Brume/` à la corbeille, seulement si on veut perdre ses réglages et sa session.

## Ce que voit quelqu'un qui télécharge l'app

Un DMG fabriqué sur sa propre machine n'est pas marqué « téléchargé depuis Internet » : macOS l'ouvre sans rien demander. Pour voir le blocage qu'aura un utilisateur, marquer le DMG avant de l'ouvrir :

```bash
xattr -w com.apple.quarantine "0081;$(printf %x $(date +%s));Safari;" ~/Downloads/Brume.dmg
```

Tant que l'app n'est pas vérifiée par Apple (voir `distribution.md`), macOS bloque la première ouverture : Réglages Système › Confidentialité et sécurité › « Ouvrir quand même ».

## Coller une image dans un assistant CLI

Copier une capture dans le presse-papiers, puis utiliser ⌘V ou « Coller » au clic droit dans Claude Code, pi ou Codex. Brume transmet Ctrl+V quand le presse-papiers contient une image sans URL de fichier : le CLI lit lui-même le presse-papiers macOS. Brume ne crée aucun fichier et ne modifie pas le presse-papiers. Vérifier aussi qu'un texte se colle normalement et qu'un fichier copié dans le Finder se colle toujours comme chemin.

Cette prise en charge vise les CLI locaux qui utilisent Ctrl+V pour lire une image. Elle ne transfère pas les images à travers SSH et ne remplace pas les raccourcis personnalisés du CLI. Un transfert distant demanderait un protocole de presse-papiers binaire pris en charge par le CLI et le moteur ; revoir cette limite quand un assistant ciblé le proposera.

## Si macOS redemande des autorisations

macOS lie les autorisations (Documents, Bureau...) à l'identifiant de l'app et à sa signature. Il les redemande si l'un des deux change : nouvel identifiant, ou build signé sans le certificat « Brume Dev ».
