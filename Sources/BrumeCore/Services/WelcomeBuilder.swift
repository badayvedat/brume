import Foundation

/// Le visuel de l'écran de démarrage, prêt pour fastfetch (logo `file-raw`) : des lignes de demi-blocs
/// colorés en ANSI, et sa taille en cases.
public struct WelcomeLogo: Hashable, Sendable {
    public let text: String
    public let width: Int
    public let height: Int
}

/// Une version de la page, à une taille de visuel (aucun visuel si nil) et de texte.
public struct WelcomeVariant: Hashable, Sendable {
    public let visualSize: WelcomeSize?
    public let textSize: WelcomeSize
}

/// Traduit les réglages de l'écran de démarrage en visuel et en config fastfetch, aux couleurs de Brume :
/// l'accent pour le visuel, le texte et les clés, des gris neutres pour le reste.
public enum WelcomeBuilder {
    /// La page à la taille choisie, puis de plus en plus petite, et enfin sans visuel : le shell
    /// prend la première qui tient dans le terminal.
    public static func variants(for welcome: Welcome) -> [WelcomeVariant] {
        var visual: WelcomeSize? = welcome.showsVisual ? welcome.size : nil
        var text = welcome.showsText ? welcome.size : .small
        var variants = [WelcomeVariant(visualSize: visual, textSize: text)]
        while visual != nil || text != .small {
            visual = visual?.smaller
            text = text.smaller ?? .small
            variants.append(WelcomeVariant(visualSize: visual, textSize: text))
        }
        return variants
    }

    /// Le visuel dessiné par Brume, ou nil quand fastfetch s'en charge (Apple).
    public static func logo(for visual: WelcomeVisual, size: WelcomeSize, accent: Accent) -> WelcomeLogo? {
        guard var pixels = PixelArt.pixels(for: visual, small: size == .small) else { return nil }
        if size == .large {
            pixels = enlarged(pixels, by: 1.5)
        }
        let lines = halfBlocks(pixels, colors: PixelArt.colors(accent)) { "\u{1B}[\($0)m" }
        return WelcomeLogo(text: lines.joined(separator: "\n") + "\n", width: pixels.map(\.count).max() ?? 0, height: lines.count)
    }

    /// Au plus proche voisin : une fois sur deux, un pixel en prend deux.
    static func enlarged(_ pixels: [String], by factor: Double) -> [String] {
        let rows = pixels.map(Array.init)
        let width = Int((Double(rows.first?.count ?? 0) * factor).rounded())
        let height = Int((Double(rows.count) * factor).rounded())
        return (0 ..< height).map { y in
            let row = rows[min(rows.count - 1, Int(Double(y) / factor))]
            return String((0 ..< width).map { row[min(row.count - 1, Int(Double($0) / factor))] })
        }
    }

    /// La config fastfetch d'une version de la page, en JSON. `logoPath` désigne le fichier où le
    /// visuel de `logo` est écrit, à la taille de la version.
    public static func config(
        for welcome: Welcome, variant: WelcomeVariant, accent: Accent, language: Language, logoPath: String
    ) -> String {
        let accentCode = "38;2;" + Hex.channels(accent.hex).map(String.init).joined(separator: ";")
        var root: [String: Any] = [
            "display": [
                "separator": "",
                "brightColor": false,
                "color": ["keys": accentCode, "title": accentCode, "output": "default"],
                "percent": ["color": ["green": "default", "yellow": "default"]],
                "size": ["ndigits": 1],
            ],
        ]

        var visualHeight = 0
        if let size = variant.visualSize, welcome.visual == .apple {
            // Les bandes arc-en-ciel d'origine, prises à la palette du terminal.
            root["logo"] = ["type": "builtin", "source": size == .small ? "macOS_small" : "macOS", "padding": ["right": 4]]
            visualHeight = size == .small ? 7 : 17
        } else if let size = variant.visualSize, let logo = logo(for: welcome.visual, size: size, accent: accent) {
            root["logo"] = ["type": "file-raw", "source": logoPath, "width": logo.width, "height": logo.height, "padding": ["right": 4]]
            visualHeight = logo.height
        } else {
            root["logo"] = ["type": "none"]
        }

        let labels = Labels(language: language)
        let info: (modules: [Any], width: Int) = switch welcome.info {
        case .none: ([], 0)
        case .essential: essential(labels, accentCode: accentCode)
        case .categories: (categories(labels), boxWidth)
        }

        var modules: [Any] = []
        if welcome.showsText {
            let pixels = PixelFont.banner(welcome.displayedText(at: variant.textSize), scale: variant.textSize.textScale)
            let lines = halfBlocks(pixels, colors: PixelArt.colors(accent)) { "{#\($0)}" }
            let textWidth = pixels.first?.count ?? 0
            // Le texte et les informations s'alignent l'un sur l'autre comme la page dans le terminal.
            let width = max(textWidth, info.width)
            func offset(_ part: Int) -> Int {
                switch welcome.alignment {
                case .left: 0
                case .center: (width - part) / 2
                case .right: width - part
                }
            }
            modules += indented(lines.map { ["type": "custom", "format": $0] }, by: offset(textWidth))
            if welcome.info != .none {
                modules.append("break")
                modules += indented(info.modules, by: offset(info.width))
            }
        } else {
            modules = info.modules
        }

        // Le visuel et la colonne de droite se centrent l'un sur l'autre en hauteur.
        let columnHeight = modules.reduce(0) { $0 + (($1 as? [String: Any])?["type"] as? String == "colors" ? 2 : 1) }
        if visualHeight > 0, var logo = root["logo"] as? [String: Any] {
            if visualHeight < columnHeight {
                logo["padding"] = ["right": 4, "top": (columnHeight - visualHeight) / 2]
                root["logo"] = logo
            } else {
                modules = Array(repeating: "break", count: (visualHeight - columnHeight) / 2) + modules
            }
        }
        root["modules"] = modules

        let data = try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        return data.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    }

    /// Décale des modules vers la droite : les clés et les lignes libres commencent par des espaces.
    private static func indented(_ modules: [Any], by count: Int) -> [Any] {
        guard count > 0 else { return modules }
        let pad = String(repeating: " ", count: count)
        return modules.map { module in
            guard var module = module as? [String: Any] else { return module }
            switch module["type"] as? String {
            case "custom": module["format"] = pad + (module["format"] as? String ?? "")
            case "colors": module["paddingLeft"] = (module["paddingLeft"] as? Int ?? 0) + count
            default: module["key"] = pad + (module["key"] as? String ?? "")
            }
            return module
        }
    }

    // MARK: - Informations

    private static let gray = "38;2;110;110;118"
    private static let boxWidth = 48

    private struct Labels {
        let language: Language

        func callAsFunction(_ key: TextKey) -> String {
            key.text(in: language)
        }

        var uptime: String {
            language == .french ? "{?days}{days} j {?}{hours} h {minutes} min" : "{?days}{days}d {?}{hours}h {minutes}m"
        }
    }

    private static func essential(_ text: Labels, accentCode: String) -> (modules: [Any], width: Int) {
        let rows: [(TextKey, [String: Any])] = [
            (.welcomeOS, ["type": "os", "format": "{name} {version}"]),
            (.welcomeHost, ["type": "host", "format": "{name}"]),
            (.welcomeCPU, ["type": "cpu", "format": "{name}"]),
            (.welcomeMemory, ["type": "memory"]),
            (.welcomeShell, ["type": "shell"]),
            (.welcomeUptime, ["type": "uptime", "format": text.uptime]),
        ]
        let keyWidth = rows.map { text($0.0).count }.max()! + 3
        let title: [String: Any] = [
            "type": "title",
            "color": ["user": "1;" + accentCode, "at": gray, "host": "default"],
        ]
        let width = keyWidth + 24
        let rule: [String: Any] = ["type": "custom", "format": String(repeating: "─", count: width), "outputColor": gray]
        return ([title, rule] + rows.map { keyed($0.1, key: text($0.0), width: keyWidth) }, width)
    }

    private static func categories(_ text: Labels) -> [Any] {
        let groups: [(TextKey, [(TextKey, [String: Any])])] = [
            (.welcomeHardware, [
                (.welcomeCPU, ["type": "cpu", "format": "{name}"]),
                (.welcomeGPU, ["type": "gpu", "format": "{name}"]),
                (.welcomeMemory, ["type": "memory"]),
                (.welcomeDisk, ["type": "disk", "folders": "/", "format": "{size-used} / {size-total} ({size-percentage})"]),
            ]),
            (.welcomeSoftware, [
                (.welcomeOS, ["type": "os", "format": "{name} {version}"]),
                (.welcomePackages, ["type": "packages"]),
                (.welcomeShell, ["type": "shell"]),
                (.welcomeTerminal, ["type": "terminal", "format": "{pretty-name}"]),
            ]),
            (.welcomeSession, [
                (.welcomeUser, ["type": "title", "format": "{user-name}@{host-name}"]),
                (.welcomeUptime, ["type": "uptime", "format": text.uptime]),
                (.welcomeLocalIP, ["type": "localip", "format": "{ipv4}"]),
            ]),
        ]
        let keyWidth = groups.flatMap { $0.1.map { text($0.0).count } }.max()! + 3
        var modules: [Any] = []
        for (index, group) in groups.enumerated() {
            if index > 0 { modules.append("break") }
            modules.append(boxTop(text(group.0)))
            modules += group.1.map { keyed($0.1, key: "  " + text($0.0), width: keyWidth + 2) }
            modules.append(["type": "custom", "format": "└" + String(repeating: "─", count: boxWidth - 2) + "┘", "outputColor": gray])
        }
        modules.append("break")
        modules.append(["type": "colors", "symbol": "block", "paddingLeft": 2])
        return modules
    }

    /// `┌──── Titre ────┐`, le titre en clair et en gras.
    private static func boxTop(_ title: String) -> [String: Any] {
        let line = boxWidth - 4 - title.count
        let left = line / 2
        let format = "┌" + String(repeating: "─", count: left) + " {#1;39}" + title + "{#22;" + gray + "} "
            + String(repeating: "─", count: line - left) + "┐"
        return ["type": "custom", "format": format, "outputColor": gray]
    }

    /// Les clés sont alignées par des espaces : `key.width` de fastfetch place la valeur par une
    /// position absolue, que le décalage de la page (centrée, à droite) ne suivrait pas.
    private static func keyed(_ module: [String: Any], key: String, width: Int) -> [String: Any] {
        var module = module
        module["key"] = key.padding(toLength: max(width, key.count + 1), withPad: " ", startingAt: 0)
        return module
    }

    // MARK: - Pixels

    /// Deux lignes de pixels par ligne de terminal : `▀` prend le pixel du haut en couleur de texte
    /// et celui du bas en fond. `style` écrit un style SGR : en séquence ANSI pour un logo, en
    /// `{#…}` pour un format de fastfetch.
    static func halfBlocks(_ pixels: [String], colors: [Character: String], style: (String) -> String) -> [String] {
        let width = pixels.map(\.count).max() ?? 0
        let rows = pixels.map { Array($0.padding(toLength: width, withPad: ".", startingAt: 0)) }
        func color(_ y: Int, _ x: Int) -> String? {
            y < rows.count ? colors[rows[y][x]] : nil
        }
        func code(_ hex: String, background: Bool = false) -> String {
            (background ? "48;2;" : "38;2;") + Hex.channels(hex).map(String.init).joined(separator: ";")
        }
        return stride(from: 0, to: rows.count, by: 2).map { y in
            var line = ""
            var current = ""
            for x in 0 ..< width {
                let (cell, sgr): (String, String) = switch (color(y, x), color(y + 1, x)) {
                case (nil, nil): (" ", "0")
                case let (top?, bottom?) where top == bottom: ("█", "0;" + code(top))
                case let (top?, nil): ("▀", "0;" + code(top))
                case let (nil, bottom?): ("▄", "0;" + code(bottom))
                case let (top?, bottom?): ("▀", "0;" + code(top) + ";" + code(bottom, background: true))
                }
                if sgr != current {
                    line += style(sgr)
                    current = sgr
                }
                line += cell
            }
            return line + style("0")
        }
    }
}
