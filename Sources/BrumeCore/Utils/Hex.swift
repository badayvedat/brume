import Foundation

/// Les couleurs en `RRGGBB`, avec ou sans `#`, comme dans les thèmes de Ghostty.
public enum Hex {
    /// Rouge, vert, bleu de 0 à 255.
    public static func channels(_ hex: String) -> [Int] {
        let value = Int(hex.trimmingCharacters(in: ["#"]), radix: 16) ?? 0
        return [(value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF]
    }

    /// Depuis des composantes de 0 à 1, bornées.
    public static func string(_ components: [Double]) -> String {
        components.map { String(format: "%02x", Int(min(max(($0 * 255).rounded(), 0), 255))) }.joined()
    }
}
