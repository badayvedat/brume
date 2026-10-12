# Premier lancement : neutraliser les configs existantes

Objectif : l'utilisateur installe le `.dmg` (ou le cask) et tout marche — suggestions, coloration, menu de complétion, `nano` en SSH — sans rien configurer. Aujourd'hui ce n'est vrai que sur un Mac vierge : une ancienne config de Ghostty ou des dotfiles bricolés coupent en silence une partie de l'intégration de Brume.

## Cas réel constaté

Mac qui utilisait Ghostty (et cmux) avant Brume, installation par `brew install --cask jeremy-prt/tap/brume`. Rien ne marchait comme sur un Mac vierge :

1. **Shell de login bash qui lance zsh.** `UserShell` à `/bin/bash`, et `~/.bash_profile` faisait `exec zsh`. Le moteur détecte bash et injecte l'intégration bash, que `exec zsh` jette : zsh démarre sans `ZDOTDIR` vers `shell-integration/zsh`, donc sans aucune intégration Brume.
2. **Intégration Ghostty sourcée à la main dans le `.zshrc`.** Le `.zshrc` chargeait `cmux.app/.../ghostty-integration.zsh` ou celle de `Ghostty.app`. Elle pose `_ghostty_integration_loaded` : `_ghostty_deferred_init` de Brume s'arrête alors (`(( ${+_ghostty_integration_loaded} )) && return 0`). Plus de fonction `ssh` (terminfo `xterm-ghostty` jamais copiée, `nano` cassé sur le serveur), plus de menu de complétion, plus d'écran d'accueil.
3. **Greffons brew chargés par le `.zshrc`.** `zsh-autosuggestions` et `zsh-syntax-highlighting` de Homebrew masquent ceux embarqués (voulu), mais leur version et leur ordre dépendent de la machine. `neofetch` en fin de `.zshrc` fait doublon avec l'écran d'accueil.
4. **Config Ghostty qui traîne.** `~/.config/ghostty/config` (lien vers `~/Library/Application Support/com.mitchellh.ghostty/config`) avec des `keybind = ...=unbind`, de l'opacité, etc. Brume ne la lit pas, mais l'utilisateur croit qu'elle s'applique et la retouche pour rien.
5. **`nano` de macOS.** `/usr/bin/nano` est UW Pico : pas de coloration ni de `.nanorc`. L'utilisateur pense que c'est le terminal qui bugue.

## D'abord rendre l'app robuste (sans toucher aux fichiers de l'utilisateur)

Ces corrections suppriment la cause au lieu de demander un nettoyage :

- **Garde propre à Brume.** Dans `ghostty-integration` (via `Patches/`), remplacer `_ghostty_integration_loaded` par une garde à nous (`_brume_integration_loaded`), ou ne sauter que la partie OSC 133/7 si l'intégration de Ghostty est déjà là. Les ajouts Brume (ssh, complétion, greffons, accueil) doivent tourner même si un `.zshrc` a sourcé l'intégration de Ghostty ou de cmux.
- **Bash qui `exec zsh`.** Dans l'intégration bash, si le shell est sur le point d'exécuter zsh, exporter `ZDOTDIR="$GHOSTTY_RESOURCES_DIR/shell-integration/zsh"` (et `GHOSTTY_ZSH_ZDOTDIR` si `ZDOTDIR` était posé) pour que zsh reprenne l'intégration. Plus simple : au lancement, si `UserShell` est bash mais que `~/.bash_profile` contient `exec zsh`, lancer directement `zsh -l` comme commande du terminal.

## Ensuite l'onboarding (premier lancement)

Ce que l'app ne peut pas contourner seule, une carte au premier lancement le propose, en un clic.

### Détection

| Élément | Signal |
|---|---|
| Shell de login | `dscl . -read ~ UserShell` ≠ `/bin/zsh`, surtout avec `exec zsh` dans `~/.bash_profile` |
| Intégration Ghostty / cmux dans le `.zshrc` | `ghostty-integration` ou `shell-integration` dans `~/.zshrc`, `~/.zprofile`, `~/.zshenv` |
| Greffons en double | `source .../zsh-autosuggestions` ou `zsh-syntax-highlighting` dans le `.zshrc` |
| Écran d'accueil en double | `neofetch` ou `fastfetch` exécuté dans le `.zshrc` |
| Config Ghostty orpheline | `~/.config/ghostty/`, `~/Library/Application Support/com.mitchellh.ghostty/` |
| `nano` de macOS | `command -v nano` résout vers `/usr/bin/nano` |

### Carte proposée

« Brume a trouvé une ancienne config de terminal qui l'empêche de fonctionner pleinement. » Liste de ce qui a été détecté, avec pour chaque ligne ce que Brume fera. Boutons « Nettoyer » et « Plus tard ». Rien n'est modifié sans ce clic.

### Nettoyage

- **Sauvegarde d'abord**, toujours : copie de chaque fichier touché dans `~/Library/Application Support/Brume/sauvegarde-<date>/`, avec un bouton « Restaurer » dans les réglages.
- **Commenter, pas supprimer** les lignes fautives des dotfiles, dans un bloc repérable (`# Désactivé par Brume, voir sauvegarde-<date>`). L'utilisateur garde la main et un autre terminal peut les réactiver.
- **Shell de login** : `chsh -s /bin/zsh` demande le mot de passe, et peut échouer sur un compte d'annuaire (Active Directory). Le proposer via la fenêtre d'autorisation de macOS ; à défaut, lancer `zsh -l` comme commande du terminal (voir plus haut) pour que ça marche quand même.
- **Config Ghostty** : la déplacer dans la sauvegarde plutôt que la supprimer, seulement si Ghostty n'est plus installé, ou après confirmation.
- **`nano`** : ne rien installer. Proposer `brew install nano` si Homebrew est présent, ou laisser de côté : en SSH, ce qui compte est la terminfo, gérée par la fonction `ssh`.

## Vérifier

Sur un compte macOS de test qui reprend les dotfiles ci-dessus (shell de login bash, `.zshrc` qui source l'intégration de Ghostty), ouvrir un terminal de Brume et vérifier :

```zsh
type ssh                                   # « ssh is a shell function from .../ghostty-integration »
echo ${+functions[_zsh_autosuggest_start]} # 1
echo $ZSH_HIGHLIGHT_VERSION                # non vide
zstyle -L ':completion:*' menu             # menu select
infocmp xterm-ghostty >/dev/null && echo ok
```
