import BrumeCore
import Testing

struct TranslucencyTests {
    @Test func valuesStayInRange() {
        var translucency = Translucency(opacity: 0, blur: 200)
        #expect(translucency.opacity == Translucency.opacityRange.lowerBound)
        #expect(translucency.blur == Translucency.blurRange.upperBound)
        translucency.opacity = 2
        #expect(translucency.opacity == 1)
        #expect(!translucency.isTranslucent)
    }

    @Test func presetIsFoundFromItsValues() {
        #expect(TranslucencyPreset(matching: TranslucencyPreset.glass.translucency) == .glass)
        #expect(TranslucencyPreset(matching: Translucency(opacity: 0.5, blur: 10)) == nil)
        #expect(TranslucencyPreset(matching: Translucency(opacity: 1, blur: 30)) == .normal)
    }

    @Test func fadeGoesFromOneStyleToTheOther() {
        let normal = TranslucencyPreset.normal.translucency
        let glass = TranslucencyPreset.glass.translucency
        #expect(normal.interpolated(to: glass, at: 0) == normal)
        #expect(normal.interpolated(to: glass, at: 1) == glass)
        #expect(normal.interpolated(to: glass, at: 0.5) == Translucency(opacity: 0.86, blur: 12))
    }
}
