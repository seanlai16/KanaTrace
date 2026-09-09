import XCTest
@testable import KanaTrace

final class ChartPickerViewModelTests: XCTestCase {
    @MainActor
    func testStartDisabledUntilSelection() {
        let model = ChartPickerViewModel()
        XCTAssertFalse(model.canStart)
        model.toggle(KanaCatalog.all(for: .hiragana)[0])
        XCTAssertTrue(model.canStart)
        XCTAssertEqual(model.practiceQueue().map(\.glyph), ["あ"])
    }

    @MainActor
    func testRowToggleSelectsInChartOrder() {
        let model = ChartPickerViewModel()
        let aRow = KanaCatalog.rows(for: .hiragana)[0]
        model.toggle(row: aRow)
        XCTAssertTrue(model.isRowFullySelected(aRow))
        XCTAssertEqual(model.practiceQueue().map(\.glyph), ["あ", "い", "う", "え", "お"])
        model.toggle(row: aRow)
        XCTAssertFalse(model.canStart)
    }

    @MainActor
    func testMixedRowsStayInGojūonOrder() {
        let model = ChartPickerViewModel()
        model.toggle(KanaCatalog.character(glyph: "ん", script: .hiragana)!)
        model.toggle(KanaCatalog.character(glyph: "か", script: .hiragana)!)
        model.toggle(KanaCatalog.character(glyph: "あ", script: .hiragana)!)
        XCTAssertEqual(model.practiceQueue().map(\.glyph), ["あ", "か", "ん"])
    }

    @MainActor
    func testYaRowSkipsEmptyColumns() {
        let model = ChartPickerViewModel()
        model.toggle(row: KanaCatalog.rows(for: .hiragana).first { $0.id == "ya" }!)
        XCTAssertEqual(model.practiceQueue().map(\.glyph), ["や", "ゆ", "よ"])
    }

    @MainActor
    func testKatakanaARowOrder() {
        let model = ChartPickerViewModel(script: .katakana)
        model.toggle(row: KanaCatalog.rows(for: .katakana)[0])
        XCTAssertEqual(model.practiceQueue().map(\.glyph), ["ア", "イ", "ウ", "エ", "オ"])
    }

    @MainActor
    func testScriptSwitchKeepsIndependentSelections() {
        let model = ChartPickerViewModel()
        model.toggle(KanaCatalog.character(glyph: "あ", script: .hiragana)!)
        model.script = .katakana
        XCTAssertFalse(model.canStart)
        XCTAssertTrue(model.practiceQueue().isEmpty)
        model.toggle(KanaCatalog.character(glyph: "カ", script: .katakana)!)
        XCTAssertEqual(model.practiceQueue().map(\.glyph), ["カ"])
        model.script = .hiragana
        XCTAssertEqual(model.practiceQueue().map(\.glyph), ["あ"])
    }

    @MainActor
    func testQueueNeverMixesScripts() {
        let model = ChartPickerViewModel()
        model.toggle(KanaCatalog.character(glyph: "あ", script: .hiragana)!)
        model.script = .katakana
        model.toggle(KanaCatalog.character(glyph: "ア", script: .katakana)!)
        XCTAssertEqual(model.practiceQueue().map(\.glyph), ["ア"])
        XCTAssertFalse(model.practiceQueue().map(\.glyph).contains("あ"))
    }
}
