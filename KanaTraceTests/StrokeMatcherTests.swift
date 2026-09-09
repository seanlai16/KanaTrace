import XCTest
@testable import KanaTrace

final class StrokeMatcherTests: XCTestCase {
    private var catalog: StrokeCatalog!

    override func setUpWithError() throws {
        catalog = try StrokeCatalog.load(from: StrokeResources.bundle)
    }

    func testIdenticalTemplateMatches() throws {
        let template = try stroke("あ", 0)
        let user = StrokeMatcher.normalizeToUnitSquare(template)
        XCTAssertTrue(StrokeMatcher.matches(user: user, template: user))
    }

    func testNoisyCopyOfARowStillMatches() throws {
        for glyph in ["あ", "い", "う", "え", "お"] {
            assertNoisyMatches(glyph)
        }
    }

    func testNoisyCopyOfKatakanaARowStillMatches() throws {
        for glyph in ["ア", "イ", "ウ", "エ", "オ"] {
            assertNoisyMatches(glyph)
        }
    }

    func testReversedStrokeFails() throws {
        let unit = StrokeMatcher.normalizeToUnitSquare(try stroke("あ", 0))
        let reversed = Array(unit.reversed())
        XCTAssertFalse(StrokeMatcher.matches(user: reversed, template: unit))
    }

    func testWrongGlyphStrokeFails() throws {
        let a = StrokeMatcher.normalizeToUnitSquare(try stroke("あ", 0))
        let i = StrokeMatcher.normalizeToUnitSquare(try stroke("い", 0))
        XCTAssertFalse(StrokeMatcher.matches(user: i, template: a))
    }

    func testShiDoesNotAcceptTsu() throws {
        try assertGlyphsDoNotMatch("シ", "ツ")
    }

    func testSoDoesNotAcceptN() throws {
        try assertGlyphsDoNotMatch("ソ", "ン")
    }

    func testTinyScribbleFails() {
        let template = [
            StrokePoint(x: 0.2, y: 0.2),
            StrokePoint(x: 0.8, y: 0.25)
        ]
        let user = [
            StrokePoint(x: 0.5, y: 0.5),
            StrokePoint(x: 0.52, y: 0.51)
        ]
        XCTAssertFalse(StrokeMatcher.matches(user: user, template: template))
    }

    func testResampleKeepsEndpoints() {
        let points = [
            StrokePoint(x: 0, y: 0),
            StrokePoint(x: 1, y: 0),
            StrokePoint(x: 1, y: 1)
        ]
        let sampled = StrokeMatcher.resample(points, count: 16)
        XCTAssertEqual(sampled.count, 16)
        XCTAssertEqual(sampled.first?.x ?? -1, 0, accuracy: 0.0001)
        XCTAssertEqual(sampled.first?.y ?? -1, 0, accuracy: 0.0001)
        XCTAssertEqual(sampled.last?.x ?? -1, 1, accuracy: 0.0001)
        XCTAssertEqual(sampled.last?.y ?? -1, 1, accuracy: 0.0001)
    }

    func testCatalogHasFortySixOfEachScript() {
        XCTAssertEqual(KanaCatalog.all(for: .hiragana).count, 46)
        XCTAssertEqual(KanaCatalog.all(for: .katakana).count, 46)
        for character in KanaCatalog.all(for: .hiragana) + KanaCatalog.all(for: .katakana) {
            XCTAssertFalse(catalog.strokes(for: character.glyph).isEmpty, character.glyph)
        }
    }

    private func assertNoisyMatches(_ glyph: String) {
        let strokes = catalog.strokes(for: glyph)
        XCTAssertFalse(strokes.isEmpty, glyph)
        for (index, template) in strokes.enumerated() {
            let unit = StrokeMatcher.normalizeToUnitSquare(template)
            let noisy = jitter(unit, amount: 0.03, seed: index + glyph.hashValue)
            XCTAssertTrue(
                StrokeMatcher.matches(user: noisy, template: unit),
                "\(glyph) stroke \(index) should match a slightly noisy copy"
            )
        }
    }

    private func assertGlyphsDoNotMatch(_ userGlyph: String, _ templateGlyph: String) throws {
        let userStrokes = catalog.strokes(for: userGlyph)
        let templateStrokes = catalog.strokes(for: templateGlyph)
        XCTAssertEqual(userStrokes.count, templateStrokes.count, "\(userGlyph) vs \(templateGlyph) stroke count")
        var acceptedAll = true
        for index in userStrokes.indices {
            let user = StrokeMatcher.normalizeToUnitSquare(userStrokes[index])
            let template = StrokeMatcher.normalizeToUnitSquare(templateStrokes[index])
            if !StrokeMatcher.matches(user: user, template: template) {
                acceptedAll = false
            }
        }
        XCTAssertFalse(
            acceptedAll,
            "\(userGlyph) should not be accepted as a complete \(templateGlyph)"
        )
    }

    private func stroke(_ glyph: String, _ index: Int) throws -> [StrokePoint] {
        let strokes = catalog.strokes(for: glyph)
        XCTAssertGreaterThan(strokes.count, index, glyph)
        return strokes[index]
    }

    private func jitter(_ points: [StrokePoint], amount: Double, seed: Int) -> [StrokePoint] {
        var state = UInt64(bitPattern: Int64(seed == 0 ? 1 : seed))
        func next() -> Double {
            state = state &* 6_364_136_223_846_793_005 &+ 1
            let unit = Double(state % 10_000) / 10_000
            return (unit * 2 - 1) * amount
        }
        return points.map { StrokePoint(x: $0.x + next(), y: $0.y + next()) }
    }
}
