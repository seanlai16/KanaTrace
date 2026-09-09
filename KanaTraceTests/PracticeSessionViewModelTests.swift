import XCTest
@testable import KanaTrace

@MainActor
final class PracticeSessionViewModelTests: XCTestCase {
    private var catalog: StrokeCatalog!

    override func setUpWithError() throws {
        catalog = try StrokeCatalog.load(from: StrokeResources.bundle)
    }

    func testHintStaysOnAndAdvancesWithAcceptedStrokes() {
        let a = KanaCatalog.character(glyph: "あ", script: .hiragana)!
        let model = PracticeSessionViewModel(
            characters: [a],
            catalog: catalog,
            haptics: NoOpHapticTrigger()
        )
        model.updateCanvasSize(CGSize(width: 109, height: 109))
        XCTAssertNil(model.hintTemplate)
        model.useHint()
        XCTAssertEqual(model.hintTemplate?.count, catalog.strokes(for: "あ")[0].count)

        writeTemplate(model, glyph: "あ", stroke: 0)
        XCTAssertEqual(model.strokeIndex, 1)
        XCTAssertTrue(model.hintEnabled)
        XCTAssertNotNil(model.hintTemplate)
    }

    func testRejectedStrokeDoesNotAdvance() {
        let a = KanaCatalog.character(glyph: "あ", script: .hiragana)!
        let model = PracticeSessionViewModel(
            characters: [a],
            catalog: catalog,
            haptics: NoOpHapticTrigger()
        )
        model.updateCanvasSize(CGSize(width: 109, height: 109))
        model.beginStroke(at: StrokePoint(x: 10, y: 10))
        model.addPoint(StrokePoint(x: 12, y: 80))
        model.endStroke()
        XCTAssertTrue(model.lastStrokeRejected)
        XCTAssertEqual(model.strokeIndex, 0)
        XCTAssertTrue(model.acceptedStrokes.isEmpty)
    }

    func testCompletingCharacterRevealsGlyphThenDoneDismisses() {
        let a = KanaCatalog.character(glyph: "あ", script: .hiragana)!
        let i = KanaCatalog.character(glyph: "い", script: .hiragana)!
        let model = PracticeSessionViewModel(
            characters: [a, i],
            catalog: catalog,
            haptics: NoOpHapticTrigger()
        )
        model.updateCanvasSize(CGSize(width: 109, height: 109))
        writeAllStrokes(model, glyph: "あ")
        XCTAssertTrue(model.isRevealed)
        XCTAssertEqual(model.current.glyph, "あ")

        model.continueOrFinish()
        XCTAssertEqual(model.current.glyph, "い")
        XCTAssertFalse(model.isRevealed)
        XCTAssertFalse(model.hintEnabled)

        writeAllStrokes(model, glyph: "い")
        model.continueOrFinish()
        XCTAssertTrue(model.shouldDismiss)
    }

    func testHintResetsOnNextCharacter() {
        let a = KanaCatalog.character(glyph: "あ", script: .hiragana)!
        let i = KanaCatalog.character(glyph: "い", script: .hiragana)!
        let model = PracticeSessionViewModel(
            characters: [a, i],
            catalog: catalog,
            haptics: NoOpHapticTrigger()
        )
        model.updateCanvasSize(CGSize(width: 109, height: 109))
        model.useHint()
        writeAllStrokes(model, glyph: "あ")
        model.continueOrFinish()
        XCTAssertFalse(model.hintEnabled)
        XCTAssertNil(model.hintTemplate)
    }

    private func writeAllStrokes(_ model: PracticeSessionViewModel, glyph: String) {
        let strokes = catalog.strokes(for: glyph)
        for index in strokes.indices {
            writeTemplate(model, glyph: glyph, stroke: index)
        }
    }

    private func writeTemplate(_ model: PracticeSessionViewModel, glyph: String, stroke: Int) {
        let points = catalog.strokes(for: glyph)[stroke]
        guard let first = points.first else { return }
        model.beginStroke(at: first)
        for point in points.dropFirst() {
            model.addPoint(point)
        }
        model.endStroke()
    }
}
