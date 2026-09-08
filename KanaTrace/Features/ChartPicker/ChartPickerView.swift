import SwiftUI

struct ChartPickerView: View {
    let catalog: StrokeCatalog
    @AppStorage("selectedHiragana") private var storedSelection = ""
    @State private var model: ChartPickerViewModel
    @State private var practiceQueue: [HiraganaCharacter]?

    init(catalog: StrokeCatalog, selectedIDs: Set<String> = []) {
        self.catalog = catalog
        _model = State(initialValue: ChartPickerViewModel(selectedIDs: selectedIDs))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(HiraganaCatalog.rows) { row in
                            chartRow(row)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }

                startBar
            }
            .background(Color.paper.ignoresSafeArea())
            .navigationTitle("Hiragana")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if model.selectedIDs.isEmpty, !storedSelection.isEmpty {
                    model.storedSelection = storedSelection
                }
            }
            .onChange(of: model.selectedIDs) { _, _ in
                storedSelection = model.storedSelection
            }
            .fullScreenCover(item: launchBinding) { launch in
                PracticeSessionView(
                    viewModel: PracticeSessionViewModel(
                        characters: launch.characters,
                        catalog: catalog
                    )
                )
            }
        }
        .tint(.indigo)
    }

    private var launchBinding: Binding<PracticeLaunch?> {
        Binding(
            get: {
                practiceQueue.map { PracticeLaunch(characters: $0) }
            },
            set: { launch in
                if launch == nil { practiceQueue = nil }
            }
        )
    }

    private func chartRow(_ row: HiraganaRow) -> some View {
        HStack(spacing: 6) {
            Button {
                model.toggle(row: row)
            } label: {
                Text(row.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(model.isRowFullySelected(row) ? Color.paperRaised : Color.ink)
                    .frame(width: 52, height: 52)
                    .background(model.isRowFullySelected(row) ? Color.indigo : Color.paperRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.inkFaint, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(row.title) row")
            .accessibilityAddTraits(model.isRowFullySelected(row) ? [.isSelected] : [])

            ForEach(0..<5, id: \.self) { column in
                if let character = row.columns[column] {
                    characterCell(character)
                } else {
                    Color.clear.frame(maxWidth: .infinity, minHeight: 52)
                }
            }
        }
    }

    private func characterCell(_ character: HiraganaCharacter) -> some View {
        let selected = model.isSelected(character)
        return Button {
            model.toggle(character)
        } label: {
            VStack(spacing: 2) {
                Text(character.glyph)
                    .font(.system(size: 26, weight: .medium))
                Text(character.romaji)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .opacity(0.7)
            }
            .foregroundStyle(selected ? Color.paperRaised : Color.ink)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(selected ? Color.indigo : Color.paperRaised)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(selected ? Color.indigo : Color.inkFaint, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(character.glyph), \(character.romaji)")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private var startBar: some View {
        VStack(spacing: 10) {
            Divider().overlay(Color.inkFaint)
            Text(model.canStart ? "\(model.selectedCount) selected" : "Select characters or a row")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.inkMuted)
            Button {
                let queue = model.practiceQueue()
                guard !queue.isEmpty else { return }
                practiceQueue = queue
            } label: {
                Text("Start practice")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(model.canStart ? Color.paperRaised : Color.inkMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(model.canStart ? Color.indigo : Color.inkFaint)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!model.canStart)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color.paper)
    }
}

private struct PracticeLaunch: Identifiable {
    let characters: [HiraganaCharacter]
    var id: String { characters.map(\.glyph).joined() }
}
