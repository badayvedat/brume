# Licences tierces

Brume reprend du code et embarque des composants de projets libres. Chacun reste sous sa licence.

## Code repris dans ce dépôt

| Fichier | Origine | Licence |
|---|---|---|
| `Sources/Brume/Utils/WindowDragArea.swift` | [Muxy](https://github.com/muxy-app/muxy), `Muxy/Views/Components/Interaction/WindowDragView.swift` (commit `ab00859`) | MIT, texte ci-dessous |

```
MIT License

Copyright (c) 2026 Muxy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Composants embarqués dans l'app

Récupérés à des versions figées par `scripts/setup.sh`, hors du dépôt. Le texte de chaque licence est dans le dépôt d'origine.

| Composant | Rôle | Licence | Copyright |
|---|---|---|---|
| [Ghostty](https://github.com/ghostty-org/ghostty) | Moteur du terminal (GhosttyKit) | MIT | Mitchell Hashimoto, Ghostty contributors |
| [libghostty-spm](https://github.com/Lakr233/libghostty-spm) | Paquet Swift du moteur, vue terminal et thèmes | MIT | Lakr233 |
| [DisplayLink](https://github.com/Lakr233/DisplayLink) | Dépendance de libghostty-spm | MIT | Lakr Aream |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | Coloration des commandes | BSD 3 clauses | zsh-syntax-highlighting contributors |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Suggestions tirées de l'historique | MIT | Thiago de Arruda, Eric Freese |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | Écran de démarrage des terminaux | MIT | Linus Dierheimer |

## Polices

Dans `Resources/Fonts`, chacune avec son fichier de licence à côté.

| Police | Licence |
|---|---|
| Cascadia Code, Fira Code, Geist Mono, IBM Plex Mono, Inconsolata, JetBrains Mono, Roboto Mono, Source Code Pro, Space Mono | SIL Open Font License 1.1 |
| Ubuntu Mono | Ubuntu Font Licence 1.0 |
