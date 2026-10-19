# Sélection au clavier dans la commande

Dans le zsh local intégré à Brume, en mode Emacs ou insertion vi :

- ⇧← / ⇧→ sélectionne par caractère depuis le curseur ;
- ⌥⇧← / ⌥⇧→ étend la sélection par mot, selon les limites de mots de zsh ;
- ⌘⇧← / ⌘⇧→ étend la sélection jusqu'au début / à la fin de la ligne ;
- changer de direction réduit la sélection, puis l'étend de l'autre côté ;
- une flèche sans Maj annule la sélection. ⌘← / ⌘→ reste le déplacement au début / à la fin de ligne.

Le moteur transmet des séquences CSI distinctes au shell. Le patch `libghostty-spm-zsh-selection.patch` utilise le curseur, la marque et la région native de ZLE : la sélection suit donc le tampon éditable, pas les cellules de sortie du terminal.

## Portée

C'est une région zsh, pas une sélection du terminal : les commandes ZLE comme `kill-region` peuvent l'utiliser, mais ⌘C ne la copie pas et taper ne remplace pas automatiquement la région. Les autres shells, les sessions SSH et les applications plein écran conservent leur propre gestion de ces touches. Un comportement d'édition et de presse-papiers identique à un champ macOS demanderait une intégration supplémentaire ; à revoir si cette édition complète est souhaitée, sans détourner les touches des programmes en cours.

## Vérification

Après `bash scripts/setup.sh`, lancer `expect scripts/test-shell-selection.exp`. Le test pilote un vrai zsh interactif avec les greffons embarqués, envoie les séquences de touches et vérifie le curseur, la marque et le texte sélectionné dans les deux modes d'édition.
