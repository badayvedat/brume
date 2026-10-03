---
paths:
  - "Sources/**"
  - "Tests/**"
  - "Package.swift"
---

# Architecture

Même idée que l'archi Nuxt : depuis un bouton de l'interface, on remonte vite au store, puis au service qui fait le travail. Rester simple : pas de ViewModel par vue, pas de protocole ni d'injection de dépendances tant qu'il n'y a qu'une implémentation. Noms de fichiers et de types en anglais, commentaires en français.

| Nuxt | Brume |
|---|---|
| `server/services/XxxService.ts` | `BrumeCore/Services/XxxService.swift` : logique pure, testée |
| `shared/schemas/` (Zod) | `BrumeCore/Models/` : structs `Codable` |
| `shared/constants/` | `BrumeCore/Constants/` |
| store Pinia | `Brume/Stores/XxxStore.swift` : classe `@Observable`, une seule instance créée dans `BrumeApp`, passée par `.environment` |
| `pages/` + `components/<domaine>/` | `Brume/Features/<Domaine>/XxxView.swift` |
| composable `useXxx` | méthode du store, ou petit `@Observable` local à la feature |
| `app.vue`, `layouts/` | `Brume/App/` : point d'entrée, scènes, commandes clavier |
| composants communs | `Brume/DesignSystem/` |
| `utils/` | `BrumeCore/Utils/` (pur) ou `Brume/Utils/` (AppKit) |

```
Sources/
  BrumeCore/            # Foundation et CoreGraphics seulement, zéro SwiftUI/AppKit
  Brume/                # app SwiftUI
Tests/BrumeCoreTests/   # Swift Testing
```

## Règles

- Toute logique testable (presets, thèmes, réglages, complétion, parsing) vit dans `BrumeCore`, avec ses tests. `Brume` ne fait que l'UI et le câblage système (AppKit, moteur Ghostty, fichiers).
- Une vue passe par le store (`@Environment(XxxStore.self)`), le store appelle le service. Une vue n'appelle pas un service directement.
- Un état propre à une fenêtre (zones, onglets, terminaux : `TerminalWorkspace`) n'est pas un store d'app : il vit dans sa feature, créé en `@State` par la vue de la fenêtre et passé aux sous-vues. Il délègue sa logique à `BrumeCore` (`WindowLayout`).
- Seul `Brume/Features/Terminal/` importe `GhosttyTerminal` : le reste de l'app ne connaît pas le moteur.
- Tout texte d'interface passe par une clé `TextKey` (`BrumeCore/Constants/L10n.swift`), en français et en anglais : la langue se choisira dans les réglages.
- Un dossier, et un target SwiftPM, se créent avec leur premier fichier.
- Une vue qui dépasse ~200 lignes se découpe en sous-vues dans le même dossier de feature.
