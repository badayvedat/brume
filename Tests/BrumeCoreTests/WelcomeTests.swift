@testable import BrumeCore
import Foundation
import Testing

struct WelcomeTests {
    @Test func oldSettingsWithoutWelcomeGetTheDefaultPage() {
        let settings = AppSettings.decoded(from: Data(#"{"restoresSession": false}"#.utf8))
        #expect(settings?.welcome == Welcome())
    }

    @Test func unreadableWelcomeValueKeepsItsDefault() {
        let settings = AppSettings.decoded(from: Data(#"{"welcome": {"visual": "rocket", "text": "yo"}}"#.utf8))
        #expect(settings?.welcome.visual == Welcome().visual)
        #expect(settings?.welcome.text == "yo")
    }

    @Test func oldVisualSizeBecomesTheSize() {
        let settings = AppSettings.decoded(from: Data(#"{"welcome": {"visualSize": "large", "textSize": "small"}}"#.utf8))
        #expect(settings?.welcome.size == .large)
    }

    @Test func fontKeepsOnlyWhatItCanDraw() {
        #expect(PixelFont.supported("Café ♥ dev_") == "CAFE ♥ DEV")
    }

    @Test func pixelArtIsDrawnTwoPixelsPerCell() throws {
        let logo = try #require(WelcomeBuilder.logo(for: .ghost, size: .medium, accent: .brume))
        let pixels = try #require(PixelArt.pixels(for: .ghost))
        #expect(logo.height == (pixels.count + 1) / 2)
        #expect(logo.text.split(separator: "\n").count == logo.height)
    }

    @Test func largeVisualIsOneAndAHalfTheMediumOne() throws {
        let medium = try #require(WelcomeBuilder.logo(for: .saturn, size: .medium, accent: .brume))
        let large = try #require(WelcomeBuilder.logo(for: .saturn, size: .large, accent: .brume))
        #expect(large.width == Int((Double(medium.width) * 1.5).rounded()))
    }

    @Test func everyDrawingHasRowsOfTheSameWidthAndASmallVersion() {
        for visual in WelcomeVisual.allCases where visual != .apple {
            for small in [false, true] {
                let pixels = PixelArt.pixels(for: visual, small: small)
                #expect(pixels != nil, "\(visual)")
                #expect(Set(pixels?.map(\.count) ?? []).count == 1, "\(visual)")
            }
        }
    }

    @Test func theAppleIsAlwaysTheOfficialOneAndNeverShrunk() throws {
        var welcome = Welcome()
        welcome.visual = .apple
        welcome.content = .visual
        welcome.size = .medium
        let variants = WelcomeBuilder.variants(for: welcome)
        #expect(variants.map(\.visualSize) == [.medium, .medium, nil, nil])
        let config = WelcomeBuilder.config(for: welcome, variant: variants[0], accent: .brume, language: .french, logoPath: "/tmp/logo")
        #expect(config.contains("\"macOS\""))
        #expect(!config.contains("macOS_small"))
    }

    @Test func variantsShrinkDownToNoVisual() {
        var welcome = Welcome()
        welcome.visual = .ghost
        welcome.content = .both
        welcome.text = "hello"
        welcome.size = .large
        let variants = WelcomeBuilder.variants(for: welcome)
        #expect(variants.map(\.visualSize) == [.large, .large, .medium, .medium, .small, .small, nil, nil])
        #expect(variants.map(\.textSize) == [.large, .large, .medium, .medium, .small, .small, .small, .small])
        #expect(variants.map(\.info) == Array(repeating: [WelcomeInfo.categories, .essential], count: 4).flatMap { $0 })
    }

    @Test func visualAloneKeepsTheSmallestText() {
        var welcome = Welcome()
        welcome.content = .visual
        welcome.text = "hello"
        welcome.size = .large
        let variants = WelcomeBuilder.variants(for: welcome)
        #expect(variants.first == WelcomeVariant(visualSize: .large, textSize: .small, info: .categories))
        #expect(variants.allSatisfy { $0.textSize == .small })
    }

    @Test func textAloneDoesNotTryVisualSizes() {
        var welcome = Welcome()
        welcome.content = .text
        welcome.text = "hello"
        welcome.size = .large
        let variants = WelcomeBuilder.variants(for: welcome)
        #expect(variants.first == WelcomeVariant(visualSize: nil, textSize: .large, info: .categories))
        #expect(variants.allSatisfy { $0.visualSize == nil })
    }

    @Test func emptyTextAndNoInfoShowsNothing() throws {
        var welcome = Welcome()
        welcome.content = .text
        welcome.text = "___"
        welcome.info = .none
        #expect(welcome.isEmpty)
        let files = WelcomeFiles(directory: FileManager.default.temporaryDirectory.appending(path: "brume-\(UUID())"))
        #expect(try files.save(welcome, accent: .brume, language: .french).isEmpty)
    }

    @Test func configIsValidJSONWithTheAccentForKeys() throws {
        for content in WelcomeContent.allCases {
            for visual in WelcomeVisual.allCases {
                for info in WelcomeInfo.allCases {
                    var welcome = Welcome()
                    welcome.content = content
                    welcome.text = "hello"
                    welcome.visual = visual
                    welcome.info = info
                    for variant in WelcomeBuilder.variants(for: welcome) {
                        let config = WelcomeBuilder.config(for: welcome, variant: variant, accent: .orange, language: .english, logoPath: "/tmp/logo.txt")
                        let json = try #require(try JSONSerialization.jsonObject(with: Data(config.utf8)) as? [String: Any])
                        #expect(json["modules"] != nil)
                        #expect(config.contains("38;2;249;115;22"))
                    }
                }
            }
        }
    }

    @Test func centeredInfoIsIndentedUnderAWiderWord() {
        var welcome = Welcome()
        welcome.content = .text
        welcome.text = "welcome"
        welcome.size = .large
        welcome.info = .essential
        let variant = WelcomeVariant(visualSize: nil, textSize: .large, info: .essential)
        welcome.alignment = .left
        let left = WelcomeBuilder.config(for: welcome, variant: variant, accent: .brume, language: .french, logoPath: "")
        welcome.alignment = .center
        let centered = WelcomeBuilder.config(for: welcome, variant: variant, accent: .brume, language: .french, logoPath: "")
        #expect(!left.contains(#""key" : "          "#))
        #expect(centered.contains(#""key" : "          "#))
    }

    @Test func largerSizeShortensTheDisplayedWordButKeepsTheText() {
        var welcome = Welcome()
        welcome.text = "abcdefghij"
        #expect(welcome.displayedText(at: .large) == "abcde")
        #expect(welcome.displayedText(at: .small) == "abcdefghij")
        #expect(welcome.text == "abcdefghij")
    }

    @Test func savingFewerVersionsRemovesTheOldOnes() throws {
        let files = WelcomeFiles(directory: FileManager.default.temporaryDirectory.appending(path: "brume-\(UUID())"))
        var welcome = Welcome()
        welcome.visual = .ghost
        welcome.size = .large
        let many = try files.save(welcome, accent: .brume, language: .french)
        welcome.size = .small
        let few = try files.save(welcome, accent: .brume, language: .french)
        #expect(few.count < many.count)
        let configs = try FileManager.default.contentsOfDirectory(atPath: files.directory.path).filter { $0.hasSuffix(".jsonc") }
        #expect(configs.count == few.count)
        try FileManager.default.removeItem(at: files.directory)
    }

    @Test func minimumSizeLeavesOutWhatMayBeMissing() {
        var welcome = Welcome()
        welcome.content = .visual
        let categories = WelcomeVariant(visualSize: nil, textSize: .small, info: .categories)
        // Trois cadres, deux lignes de couleurs : 22 lignes, moins les paquets et l'IP locale.
        #expect(WelcomeBuilder.minimumSize(for: welcome, variant: categories, language: .french) == (48, 20))
        let essential = WelcomeVariant(visualSize: nil, textSize: .small, info: .essential)
        #expect(WelcomeBuilder.minimumSize(for: welcome, variant: essential, language: .french).height == 8)
    }

    @Test func minimumSizePutsTheVisualBesideTheInfo() throws {
        var welcome = Welcome()
        welcome.visual = .ghost
        let variant = WelcomeVariant(visualSize: .medium, textSize: .small, info: .categories)
        let logo = try #require(WelcomeBuilder.logo(for: .ghost, size: .medium, accent: .brume))
        #expect(WelcomeBuilder.minimumSize(for: welcome, variant: variant, language: .english).width == logo.width + 4 + 48)
    }

    @Test func aVisualAloneTakesOnlyItsDrawnCells() throws {
        for visual in WelcomeVisual.allCases where visual != .apple {
            for size in WelcomeSize.allCases {
                var welcome = Welcome()
                welcome.visual = visual
                welcome.info = .none
                let variant = WelcomeVariant(visualSize: size, textSize: .small, info: .none)
                let logo = try #require(WelcomeBuilder.logo(for: visual, size: size, accent: .brume))
                let drawn = AnsiText.lines(logo.text).map { $0.map(\.text).joined() }
                let widths = drawn.map { $0.count - $0.reversed().prefix { $0 == " " }.count }
                let minimum = WelcomeBuilder.minimumSize(for: welcome, variant: variant, language: .french)
                #expect(minimum.width == widths.max(), "\(visual) \(size)")
                #expect(minimum.height == (widths.lastIndex { $0 > 0 } ?? -1) + 1, "\(visual) \(size)")
            }
        }
    }

    @Test func savedPagesKeepTheirMinimumSize() throws {
        let files = WelcomeFiles(directory: FileManager.default.temporaryDirectory.appending(path: "brume-\(UUID())"))
        let welcome = Welcome()
        let pages = try files.save(welcome, accent: .brume, language: .french)
        let sizes = WelcomeBuilder.variants(for: welcome).map { WelcomeBuilder.minimumSize(for: welcome, variant: $0, language: .french) }
        #expect(pages.map(\.minimumWidth) == sizes.map(\.width))
        #expect(pages.map(\.minimumHeight) == sizes.map(\.height))
        try FileManager.default.removeItem(at: files.directory)
    }

    @Test func spacesAloneAreNoText() {
        var welcome = Welcome()
        welcome.content = .text
        welcome.text = "   "
        #expect(!welcome.showsText)
    }

    @Test func letterSizesScaleTheFont() {
        #expect(PixelFont.banner("hi", scale: 1).count == PixelFont.height + 1)
        #expect(PixelFont.banner("hi", scale: 3).count == PixelFont.height * 3 + 1)
    }

    @Test func ansiStylesAreReadAndOtherSequencesIgnored() {
        let lines = AnsiText.lines("\u{1B}[1;38;2;255;0;0mOS\u{1B}[0m: \u{1B}[32G\u{1B}[91mmacOS\u{1B}[m\n\u{1B}[44m  ")
        #expect(lines.count == 2)
        #expect(lines[0][0] == AnsiSpan(text: "OS", foreground: .rgb("ff0000"), isBold: true))
        #expect(lines[0][1] == AnsiSpan(text: ": "))
        #expect(lines[0][2] == AnsiSpan(text: "macOS", foreground: .palette(9)))
        #expect(lines[1][0] == AnsiSpan(text: "  ", background: .palette(4)))
    }
}
