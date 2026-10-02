import CoreGraphics

/// Place de la vue dans l'historique, en lignes, telle que le moteur la donne.
public struct ScrollbarPosition: Equatable, Sendable {
    public let total: Int
    /// Lignes au-dessus de la vue.
    public let offset: Int
    public let visible: Int

    public init(total: Int, offset: Int, visible: Int) {
        self.total = total
        self.offset = offset
        self.visible = visible
    }

    public var isScrollable: Bool {
        visible > 0 && total > visible
    }

    /// 0 : collé en bas.
    public var rowsBelow: Int {
        max(total - offset - visible, 0)
    }

    public func documentHeight(viewport height: CGFloat) -> CGFloat {
        CGFloat(total) * rowHeight(viewport: height)
    }

    /// Origine du défilement façon AppKit, comptée depuis le bas.
    public func scrollOrigin(viewport height: CGFloat) -> CGFloat {
        CGFloat(rowsBelow) * rowHeight(viewport: height)
    }

    /// La ligne à mettre en haut de la vue quand la barre est glissée jusqu'à `origin`.
    public func row(atScrollOrigin origin: CGFloat, viewport height: CGFloat) -> Int {
        let below = Int((origin / rowHeight(viewport: height)).rounded())
        return min(max(total - visible - below, 0), max(total - visible, 0))
    }

    /// Vrai quand la vue a bougé dans l'historique. La sortie d'une commande décale
    /// `offset` sans bouger la vue (collée en bas) : la barre ne doit pas clignoter.
    public func hasScrolled(from previous: ScrollbarPosition?) -> Bool {
        guard let previous else { return false }
        return offset != previous.offset && rowsBelow != previous.rowsBelow
    }

    private func rowHeight(viewport height: CGFloat) -> CGFloat {
        height / CGFloat(max(visible, 1))
    }
}
