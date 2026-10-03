/// Une couleur ANSI : une des 16 du thème, ou une couleur exacte en `RRGGBB`.
public enum AnsiColor: Hashable, Sendable {
    case palette(Int)
    case rgb(String)
}

public struct AnsiSpan: Hashable, Sendable {
    public var text: String
    public var foreground: AnsiColor?
    public var background: AnsiColor?
    public var isBold = false

    public init(text: String, foreground: AnsiColor? = nil, background: AnsiColor? = nil, isBold: Bool = false) {
        self.text = text
        self.foreground = foreground
        self.background = background
        self.isBold = isBold
    }
}

/// Lit la sortie colorée de fastfetch pour l'aperçu des réglages : seuls les styles SGR (`ESC [ … m`)
/// comptent, les autres séquences sont ignorées.
public enum AnsiText {
    public static func lines(_ output: String) -> [[AnsiSpan]] {
        var lines: [[AnsiSpan]] = [[]]
        var style = AnsiSpan(text: "")
        var scalars = output.unicodeScalars.makeIterator()

        func append(_ scalar: Unicode.Scalar) {
            if var last = lines[lines.count - 1].last,
               last.foreground == style.foreground, last.background == style.background, last.isBold == style.isBold {
                last.text.unicodeScalars.append(scalar)
                lines[lines.count - 1][lines[lines.count - 1].count - 1] = last
            } else {
                var span = style
                span.text = String(scalar)
                lines[lines.count - 1].append(span)
            }
        }

        while let scalar = scalars.next() {
            switch scalar {
            case "\u{1B}":
                guard scalars.next() == "[" else { continue }
                var parameters = ""
                while let next = scalars.next() {
                    if (0x40 ... 0x7E).contains(next.value) {
                        if next == "m" { apply(parameters, to: &style) }
                        break
                    }
                    parameters.unicodeScalars.append(next)
                }
            case "\n":
                lines.append([])
            case "\r":
                continue
            default:
                append(scalar)
            }
        }
        if lines.last?.isEmpty == true, lines.count > 1 { lines.removeLast() }
        return lines
    }

    private static func apply(_ parameters: String, to style: inout AnsiSpan) {
        var codes = parameters.split(separator: ";", omittingEmptySubsequences: false).map { Int($0) ?? 0 }.makeIterator()
        while let code = codes.next() {
            switch code {
            case 0:
                style = AnsiSpan(text: "")
            case 1:
                style.isBold = true
            case 22:
                style.isBold = false
            case 30 ... 37:
                style.foreground = .palette(code - 30)
            case 90 ... 97:
                style.foreground = .palette(code - 90 + 8)
            case 39:
                style.foreground = nil
            case 40 ... 47:
                style.background = .palette(code - 40)
            case 100 ... 107:
                style.background = .palette(code - 100 + 8)
            case 49:
                style.background = nil
            case 38, 48:
                var color: AnsiColor?
                switch codes.next() {
                case 5:
                    color = codes.next().map(AnsiColor.palette)
                case 2:
                    if let r = codes.next(), let g = codes.next(), let b = codes.next() {
                        color = .rgb(Hex.string([r, g, b].map { Double($0) / 255 }))
                    }
                default:
                    break
                }
                if code == 38 { style.foreground = color } else { style.background = color }
            default:
                break
            }
        }
    }
}
