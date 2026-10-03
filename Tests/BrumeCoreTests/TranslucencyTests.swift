import BrumeCore
import Testing

struct TranslucencyTests {
    @Test func glassFollowsItsSettingsAndOpaqueIgnoresThem() {
        var appearance = Appearance()
        appearance.glassOpacity = .low
        appearance.glassBlur = .high
        #expect(appearance.translucency == Translucency(opacity: Strength.low.veilOpacity, blur: Strength.high.blurRadius))
        appearance.isGlass = false
        #expect(appearance.translucency == .opaque)
        #expect(!appearance.translucency.isTranslucent)
    }

    @Test func fadeGoesFromOneStyleToTheOther() {
        let glass = Translucency(opacity: 0.72, blur: 40)
        #expect(Translucency.opaque.interpolated(to: glass, at: 0) == .opaque)
        #expect(Translucency.opaque.interpolated(to: glass, at: 1) == glass)
        #expect(Translucency.opaque.interpolated(to: glass, at: 0.5) == Translucency(opacity: 0.86, blur: 20))
    }
}
