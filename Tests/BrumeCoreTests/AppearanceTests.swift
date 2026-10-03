import BrumeCore
import Foundation
import Testing

struct AppearanceTests {
    let palette = Array(repeating: "000000", count: 16)

    @Test func hslGoesBothWays() {
        #expect(HSL(hue: 0, saturation: 0, lightness: 0.09).hex == "171717")
        #expect(HSL(hue: 240, saturation: 1, lightness: 0.5).hex == "0000ff")
        #expect(HSL(hex: "0000ff").hue == 240)
        #expect(HSL(hex: "00ff00").saturation == 1)
    }

    @Test func backgroundTakesTheAccentHueAndNeutralStaysGrey() {
        var appearance = Appearance()
        appearance.accent = .red
        let red = HSL(hex: appearance.terminalColors(palette: palette).background)
        #expect(red.hue < 10 || red.hue > 350)
        #expect(red.saturation > 0.2)
        appearance.accent = .black
        #expect(HSL(hex: appearance.terminalColors(palette: palette).background).saturation == 0)
    }

    @Test func strongerTintGivesAMoreColoredBackground() {
        var appearance = Appearance()
        appearance.tint = .low
        let low = HSL(hex: appearance.terminalColors(palette: palette).background).saturation
        appearance.tint = .high
        #expect(HSL(hex: appearance.terminalColors(palette: palette).background).saturation > low)
    }

    @Test func cursorTakesTheAccent() {
        var appearance = Appearance()
        appearance.accent = .pink
        #expect(appearance.terminalColors(palette: palette).cursor == "ec4899")
    }

    @Test func everyCommandColorsHasItsSource() {
        for colors in CommandColors.allCases {
            #expect((colors.ownPalette == nil) != (colors.ghosttyName == nil))
        }
        #expect(CommandColors.brume.ownPalette?.count == 16)
    }

    @Test func tenColorsToPickFrom() {
        #expect(Accent.allCases.count == 10)
        #expect(Appearance().accent == .brume)
    }
}

struct ThemeColorsTests {
    let black = ThemeColors(background: "000000", foreground: "ffffff", cursor: "ff0000", selection: "00ff00", selectionText: "ffffff", palette: ["0000ff"])
    let white = ThemeColors(background: "ffffff", foreground: "000000", cursor: "ff0000", selection: "00ff00", selectionText: "000000", palette: ["ff00ff"])

    @Test func fadeMixesEveryColor() {
        let half = black.interpolated(to: white, at: 0.5)
        #expect(half.background == "808080")
        #expect(half.cursor == "ff0000")
        #expect(half.palette == ["8000ff"])
    }

    @Test func fadeEndsOnTheTarget() {
        #expect(black.interpolated(to: white, at: 1) == white)
        #expect(Easing.easeInOut(0) == 0 && Easing.easeInOut(1) == 1)
    }
}
