import Foundation

public enum Easing {
    /// Lent au départ et à l'arrivée, comme les animations de macOS.
    public static func easeInOut(_ t: Double) -> Double {
        t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }
}
