import AppKit
import BrumeCore

/// Rend la fenêtre transparente et floute le bureau derrière, comme Ghostty et Monocode.
@MainActor
enum WindowTranslucency {
    private typealias SetBlur = @convention(c) (Int32, Int32, Int32) -> Int32
    private typealias Connection = @convention(c) () -> Int32

    // API privée du WindowServer, la seule qui floute le bureau à un rayon choisi.
    // Absente un jour : la fenêtre reste transparente, sans flou.
    private static let setBlur: SetBlur? = symbol("CGSSetWindowBackgroundBlurRadius")
    private static let connection: Connection? = symbol("CGSMainConnectionID")

    static func apply(_ translucency: Translucency, to window: NSWindow) {
        window.isOpaque = !translucency.isTranslucent
        // Un fond tout à fait clair laisse un liseré dans les coins arrondis, sous l'ombre.
        window.backgroundColor = translucency.isTranslucent ? .white.withAlphaComponent(0.001) : .windowBackgroundColor
        window.invalidateShadow()
        guard window.windowNumber > 0, let setBlur, let connection else { return }
        _ = setBlur(connection(), Int32(window.windowNumber), Int32(translucency.isTranslucent ? translucency.blur : 0))
    }

    private static func symbol<T>(_ name: String) -> T? {
        guard let pointer = dlsym(UnsafeMutableRawPointer(bitPattern: -2), name) else { return nil }
        return unsafeBitCast(pointer, to: T.self)
    }
}
