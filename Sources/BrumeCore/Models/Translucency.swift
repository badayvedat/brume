/// La fenêtre posée sur le bureau : la couleur du fond en voile, le bureau flouté dessous.
public struct Translucency: Hashable, Sendable {
    /// Part de la couleur du fond dans le voile. 1 : fenêtre opaque.
    public var opacity: Double
    /// Rayon du flou du bureau, en points.
    public var blur: Int

    public init(opacity: Double, blur: Int) {
        self.opacity = opacity
        self.blur = blur
    }

    public static let opaque = Translucency(opacity: 1, blur: 0)

    public var isTranslucent: Bool {
        opacity < 1
    }

    /// Une étape du fondu vers `target`, `progress` allant de 0 à 1.
    public func interpolated(to target: Translucency, at progress: Double) -> Translucency {
        Translucency(
            opacity: opacity + (target.opacity - opacity) * progress,
            blur: Int((Double(blur) + Double(target.blur - blur) * progress).rounded())
        )
    }
}
