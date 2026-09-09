import Foundation
import Observation

@MainActor
@Observable
final class ChartPickerViewModel {
    var script: KanaScript
    private var selections: [KanaScript: Set<String>]

    init(script: KanaScript = .hiragana, selectedIDs: Set<String> = []) {
        self.script = script
        self.selections = selectedIDs.isEmpty ? [:] : [script: selectedIDs]
    }

    var rows: [KanaRow] { KanaCatalog.rows(for: script) }

    var selectedIDs: Set<String> { selections[script, default: []] }

    var canStart: Bool { !selectedIDs.isEmpty }

    var selectedCount: Int { selectedIDs.count }

    func isSelected(_ character: KanaCharacter) -> Bool {
        selectedIDs.contains(character.id)
    }

    func isRowFullySelected(_ row: KanaRow) -> Bool {
        let ids = row.characters.map(\.id)
        return !ids.isEmpty && ids.allSatisfy(selectedIDs.contains)
    }

    func toggle(_ character: KanaCharacter) {
        var ids = selectedIDs
        if ids.contains(character.id) {
            ids.remove(character.id)
        } else {
            ids.insert(character.id)
        }
        selections[script] = ids
    }

    func toggle(row: KanaRow) {
        var ids = selectedIDs
        let rowIDs = row.characters.map(\.id)
        if isRowFullySelected(row) {
            ids.subtract(rowIDs)
        } else {
            ids.formUnion(rowIDs)
        }
        selections[script] = ids
    }

    func practiceQueue() -> [KanaCharacter] {
        KanaCatalog.all(for: script).filter { selectedIDs.contains($0.id) }
    }

    func storedSelection(for script: KanaScript) -> String {
        selections[script, default: []].sorted().joined()
    }

    func restoreSelection(_ stored: String, for script: KanaScript) {
        guard selections[script] == nil || selections[script]?.isEmpty == true, !stored.isEmpty else { return }
        selections[script] = Set(stored.map { String($0) })
    }
}
