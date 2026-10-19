# Sélection au clavier dans la commande

Dans le zsh local intégré à Brume, en mode Emacs ou insertion vi :

- ⇧← / ⇧→ sélectionne par caractère depuis le curseur ;
- ⌥⇧← / ⌥⇧→ étend la sélection par mot, selon les limites de mots de zsh ;
- ⌘⇧← / ⌘⇧→ étend la sélection jusqu'au début / à la fin de la ligne ;
- changer de direction réduit la sélection, puis l'étend de l'autre côté ;
- taper ou coller remplace le texte sélectionné ; Retour arrière et les commandes de suppression effacent la sélection, sans supprimer un caractère supplémentaire ;
- une flèche sans Maj annule la sélection. ⌘← / ⌘→ reste le déplacement au début / à la fin de ligne.

Le moteur transmet des séquences CSI distinctes au shell. Le patch `libghostty-spm-zsh-selection.patch` utilise le curseur, la marque et la région native de ZLE : la sélection suit donc le tampon éditable, pas les cellules de sortie du terminal.

## Portée

C'est une région zsh, pas une sélection du terminal : les commandes ZLE comme `kill-region` peuvent l'utiliser, mais ⌘C ne la copie pas. Le remplacement passe par les widgets ZLE standard d'insertion, de collage et de suppression, en conservant les personnalisations et greffons déjà chargés pour l'édition sans sélection. Un widget personnalisé distinct qui modifie lui-même le tampon ne remplace pas automatiquement la sélection ; à intégrer si un cas réel le demande. Les autres shells, les sessions SSH et les applications plein écran conservent leur propre gestion de ces touches. La copie vers le presse-papiers macOS demanderait une intégration supplémentaire ; à revoir si elle est souhaitée, sans détourner les touches des programmes en cours.

## Vérification

Après `bash scripts/setup.sh`, lancer `expect scripts/test-shell-selection.exp`. Le test pilote un vrai zsh interactif avec les greffons embarqués, envoie les séquences de touches et vérifie le curseur, la marque, le texte sélectionné et les modifications du tampon dans les deux modes d'édition.
