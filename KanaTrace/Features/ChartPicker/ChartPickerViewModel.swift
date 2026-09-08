import Foundation
import Observation

@MainActor
@Observable
final class ChartPickerViewModel {
    var selectedIDs: Set<String>

    init(selectedIDs: Set<String> = []) {
        self.selectedIDs = selectedIDs
    }

    var canStart: Bool { !selectedIDs.isEmpty }

    var selectedCount: Int { selectedIDs.count }

    func isSelected(_ character: HiraganaCharacter) -> Bool {
        selectedIDs.contains(character.id)
    }

    func isRowFullySelected(_ row: HiraganaRow) -> Bool {
        let ids = row.characters.map(\.id)
        return !ids.isEmpty && ids.allSatisfy(selectedIDs.contains)
    }

    func toggle(_ character: HiraganaCharacter) {
        if selectedIDs.contains(character.id) {
            selectedIDs.remove(character.id)
        } else {
            selectedIDs.insert(character.id)
        }
    }

    func toggle(row: HiraganaRow) {
        let ids = row.characters.map(\.id)
        if isRowFullySelected(row) {
            selectedIDs.subtract(ids)
        } else {
            selectedIDs.formUnion(ids)
        }
    }

    func practiceQueue() -> [HiraganaCharacter] {
        HiraganaCatalog.all.filter { selectedIDs.contains($0.id) }
    }

    var storedSelection: String {
        get { selectedIDs.sorted().joined() }
        set { selectedIDs = Set(newValue.map { String($0) }) }
    }
}
