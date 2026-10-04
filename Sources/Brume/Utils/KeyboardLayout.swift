import AppKit
import BrumeCore
import Carbon.HIToolbox
import SwiftUI

/// Les raccourcis selon le clavier du Mac. macOS adapte les raccourcis des menus au clavier :
/// sur un clavier français, ⇧⌘[ devient ⇧⌘^ (la touche à la place du [ américain). Les réglages
/// affichent et comparent les raccourcis par défaut comme le menu les montre.
@MainActor
enum KeyboardLayout {
    private struct Key {
        let plain: String
        let shifted: String
    }

    private static var cache: (source: String, keys: [UInt16: Key])?

    /// Ce que tape chaque touche, seule et avec ⇧, sur le clavier choisi.
    private static var keys: [UInt16: Key] {
        let source = currentSource
        if let cache, cache.source == source { return cache.keys }
        var keys: [UInt16: Key] = [:]
        for code in UInt16(0) ..< 128 where namedKeys[code] == nil {
            guard let event = NSEvent.keyEvent(
                with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil,
                characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: code
            ),
                let plain = event.characters(byApplyingModifiers: []), plain.count == 1,
                let shifted = event.characters(byApplyingModifiers: .shift), shifted.count == 1
            else { continue }
            keys[code] = Key(plain: plain, shifted: shifted)
        }
        cache = (source, keys)
        return keys
    }

    private static var currentSource: String {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let id = TISGetInputSourceProperty(source, kTISPropertyInputSourceID)
        else { return "" }
        return Unmanaged<CFString>.fromOpaque(id).takeUnretainedValue() as String
    }

    private static let namedKeys: [UInt16: String] = [
        36: "return", 76: "return", 48: "tab", 49: "space", 51: "delete", 117: "forwardDelete", 53: "escape",
        123: "left", 124: "right", 125: "down", 126: "up", 115: "home", 119: "end", 116: "pageUp", 121: "pageDown",
        122: "f1", 120: "f2", 99: "f3", 118: "f4", 96: "f5", 97: "f6", 98: "f7", 100: "f8", 101: "f9", 109: "f10", 103: "f11", 111: "f12",
    ]

    /// La rangée des chiffres : sur un clavier français, ⌘ et la touche & donnent ⌘1, comme dans le menu.
    private static let digitRow: [UInt16: String] = [
        18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7", 28: "8", 25: "9", 29: "0",
    ]

    /// La place des signes sur un clavier américain, d'où macOS part pour les adapter.
    private static let usKeys: [Character: UInt16] = [
        "-": 27, "=": 24, "[": 33, "]": 30, "\\": 42, ";": 41, "'": 39, ",": 43, ".": 47, "/": 44, "`": 50,
    ]

    /// La combinaison tapée, ou nil pour une touche qui n'écrit rien sur ce clavier.
    static func shortcut(from event: NSEvent) -> Shortcut? {
        let flags = event.modifierFlags
        var modifiers: Shortcut.Modifiers = []
        for (flag, modifier) in [(NSEvent.ModifierFlags.control, Shortcut.Modifiers.control), (.option, .option), (.shift, .shift), (.command, .command)]
            where flags.contains(flag) {
            modifiers.insert(modifier)
        }
        if let name = namedKeys[event.keyCode] { return Shortcut(name, modifiers) }
        if let digit = digitRow[event.keyCode] { return Shortcut(digit, modifiers) }
        guard let plain = keys[event.keyCode]?.plain else { return nil }
        return withoutShift(Shortcut(plain.lowercased(), modifiers))
    }

    /// Ce que macOS fait d'un raccourci par défaut, au plus près : un signe qui s'écrit sur ce clavier
    /// reste tel quel, sinon il prend la touche du clavier américain. Les chiffres restent des chiffres.
    static func localized(_ shortcut: Shortcut) -> Shortcut {
        guard shortcut.key.count == 1, let character = shortcut.key.first, !character.isLetter, !shortcut.isDigit,
              !keys.values.contains(where: { $0.plain == shortcut.key || $0.shifted == shortcut.key }),
              let code = usKeys[character], let key = keys[code]
        else { return shortcut }
        return Shortcut(key.plain, shortcut.modifiers)
    }

    /// ⇧⌘= et ⌘+ sont la même combinaison sur un clavier où + s'écrit avec ⇧.
    static func normalized(_ shortcut: Shortcut) -> Shortcut {
        withoutShift(localized(shortcut))
    }

    private static func withoutShift(_ shortcut: Shortcut) -> Shortcut {
        guard shortcut.modifiers.contains(.shift), shortcut.key.count == 1, shortcut.key.first?.isLetter == false, !shortcut.isDigit,
              let key = keys.values.first(where: { $0.plain == shortcut.key }), key.shifted != key.plain
        else { return shortcut }
        return Shortcut(key.shifted, shortcut.modifiers.subtracting(.shift))
    }

    static func label(_ shortcut: Shortcut) -> String {
        localized(shortcut).label
    }

    /// Un raccourci tapé dans les réglages s'applique tel quel ; ceux par défaut et les chiffres,
    /// macOS les adapte au clavier.
    static func keyboardShortcut(_ shortcut: Shortcut, isCustom: Bool) -> KeyboardShortcut {
        KeyboardShortcut(
            keyEquivalent(shortcut.key),
            modifiers: eventModifiers(shortcut.modifiers),
            localization: isCustom && !shortcut.isDigit ? .custom : .automatic
        )
    }

    static func eventModifiers(_ modifiers: Shortcut.Modifiers) -> SwiftUI.EventModifiers {
        var result: SwiftUI.EventModifiers = []
        if modifiers.contains(.control) { result.insert(.control) }
        if modifiers.contains(.option) { result.insert(.option) }
        if modifiers.contains(.shift) { result.insert(.shift) }
        if modifiers.contains(.command) { result.insert(.command) }
        return result
    }

    static func modifierFlags(_ modifiers: Shortcut.Modifiers) -> NSEvent.ModifierFlags {
        var result: NSEvent.ModifierFlags = []
        if modifiers.contains(.control) { result.insert(.control) }
        if modifiers.contains(.option) { result.insert(.option) }
        if modifiers.contains(.shift) { result.insert(.shift) }
        if modifiers.contains(.command) { result.insert(.command) }
        return result
    }

    private static func keyEquivalent(_ key: String) -> KeyEquivalent {
        switch key {
        case "return": .return
        case "tab": .tab
        case "space": .space
        case "delete": .delete
        case "forwardDelete": .deleteForward
        case "escape": .escape
        case "left": .leftArrow
        case "right": .rightArrow
        case "up": .upArrow
        case "down": .downArrow
        case "home": .home
        case "end": .end
        case "pageUp": .pageUp
        case "pageDown": .pageDown
        default:
            if key.count > 1, key.first == "f", let number = Int(key.dropFirst()), let scalar = UnicodeScalar(NSF1FunctionKey + number - 1) {
                KeyEquivalent(Character(scalar))
            } else {
                KeyEquivalent(key.first ?? " ")
            }
        }
    }
}
