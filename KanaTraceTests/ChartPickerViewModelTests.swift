import XCTest
@testable import KanaTrace

final class ChartPickerViewModelTests: XCTestCase {
    @MainActor
    func testStartDisabledUntilSelection() {
        let model = ChartPickerViewModel()
        XCTAssertFalse(model.canStart)
        model.toggle(HiraganaCatalog.all[0])
        XCTAssertTrue(model.canStart)
        XCTAssertEqual(model.practiceQueue().map(\.glyph), ["あ"])
    }

    @MainActor
    func testRowToggleSelectsInChartOrder() {
        let model = ChartPickerViewModel()
        let aRow = HiraganaCatalog.rows[0]
        model.toggle(row: aRow)
        XCTAssertTrue(model.isRowFullySelected(aRow))
        XCTAssertEqual(model.practiceQueue().map(\.glyph), ["あ", "い", "う", "え", "お"])
        model.toggle(row: aRow)
        XCTAssertFalse(model.canStart)
    }

    @MainActor
    func testMixedRowsStayInGojūonOrder() {
        let model = ChartPickerViewModel()
        model.toggle(HiraganaCatalog.character(glyph: "ん")!)
        model.toggle(HiraganaCatalog.character(glyph: "か")!)
        model.toggle(HiraganaCatalog.character(glyph: "あ")!)
        XCTAssertEqual(model.practiceQueue().map(\.glyph), ["あ", "か", "ん"])
    }

    @MainActor
    func testYaRowSkipsEmptyColumns() {
        let model = ChartPickerViewModel()
        model.toggle(row: HiraganaCatalog.rows.first { $0.id == "ya" }!)
        XCTAssertEqual(model.practiceQueue().map(\.glyph), ["や", "ゆ", "よ"])
    }
}
