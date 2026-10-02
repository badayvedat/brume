# Reprise de Muxy

Muxy (MIT, https://github.com/muxy-app/muxy, commit `ab00859`) sert de référence, pas de base : son code terminal vise son propre fork de Ghostty, incompatible avec libghostty-spm, et Muxy n'a pas de sidebar de sessions. Tout fichier repris garde sa mention de copyright.

## À reprendre, par étape du suivi

| Étape | Fichiers Muxy | Pour quoi |
|---|---|---|
| 3. Base | `Muxy/Info.plist` (clés `NS*UsageDescription`) | macOS attribue à l'app les accès demandés par le shell |
| 3. Base | `Views/Terminal/GhosttyTerminalNSView.swift` (`isAppShortcut`), `Views/MainWindow.swift` (`ShortcutInterceptingView`) | Intercepter les raccourcis de l'app avant le terminal |
| 4. Réglages | `Services/Terminal/GhosttyTransparentSurfaceConfig.swift`, `AppTransparencyService.swift`, `Views/Components/Support/AppTransparencyBackground.swift`, `MaterialMask.swift` | Opacité et flou : surface à `background-opacity = 0`, flou macOS dessous, coupé si « Réduire la transparence » |
| 4. Réglages | `Views/Settings/Shared/SettingsComponents.swift`, `BackgroundAppearanceSliders.swift` | Briques visuelles du panneau |
| 6. Vue agents | `Views/Components/Support/ReparentingNSViewHost.swift` | Garder la vue terminal vivante quand SwiftUI la déplace |
| 6. Vue agents | `Views/Components/Interaction/ResizeHandle.swift`, `Models/UI/SidebarMode.swift`, `Views/Components/Support/AppSidebarBackground.swift` | Sidebar redimensionnable et translucide |
| Plus tard | `Models/Workspace/SplitNode` (logique `areaFrames`, ratio 0,15 à 0,85) | Splits |

## Pièges

- `SettingsJSONStore`, `L10n` et `MuxyShared` tirent Sentry, Sparkle, les extensions et le protocole mobile : couper ces appels, ne jamais copier ces types.
- 87 singletons `static let shared` : réécrire avec les stores de Brume plutôt que recopier.
- Noms en dur à renommer : `Muxy_Muxy.bundle`, `app.muxy`, `Application Support/Muxy`, clés `muxy.*`.
