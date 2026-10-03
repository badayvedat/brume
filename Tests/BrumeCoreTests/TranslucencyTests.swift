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
    }
}
