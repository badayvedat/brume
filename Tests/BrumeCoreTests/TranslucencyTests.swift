import BrumeCore
import Testing

struct TranslucencyTests {
    @Test func glassFollowsItsSettingsAndOpaqueIgnoresThem() {
        var appearance = Appearance()
        appearance.glassOpacity = 0.6
        appearance.glassBlur = 20
        #expect(appearance.translucency == Translucency(opacity: 0.6, blur: 20))
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
