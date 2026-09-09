import SwiftUI

struct ChartPickerView: View {
    let catalog: StrokeCatalog
    @AppStorage("selectedHiragana") private var storedHiragana = ""
    @AppStorage("selectedKatakana") private var storedKatakana = ""
    @AppStorage("kanaScript") private var storedScript = KanaScript.hiragana.rawValue
    @State private var model: ChartPickerViewModel
    @State private var practiceQueue: [KanaCharacter]?

    init(catalog: StrokeCatalog, selectedIDs: Set<String> = []) {
        self.catalog = catalog
        _model = State(initialValue: ChartPickerViewModel(selectedIDs: selectedIDs))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                scriptPicker
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(model.rows) { row in
                            chartRow(row)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }

                startBar
            }
            .background(Color.paper.ignoresSafeArea())
            .navigationTitle(model.script.title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: restorePersistedState)
            .onChange(of: model.script) { _, script in
                storedScript = script.rawValue
            }
            .onChange(of: model.selectedIDs) { _, _ in
                persistCurrentSelection()
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

    private var scriptPicker: some View {
        Picker("Script", selection: scriptBinding) {
            ForEach(KanaScript.allCases) { script in
                Text(script.title).tag(script)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Script")
    }

    private var scriptBinding: Binding<KanaScript> {
        Binding(
            get: { model.script },
            set: { model.script = $0 }
        )
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

    private func restorePersistedState() {
        model.restoreSelection(storedHiragana, for: .hiragana)
        model.restoreSelection(storedKatakana, for: .katakana)
        if let script = KanaScript(rawValue: storedScript) {
            model.script = script
        }
    }

    private func persistCurrentSelection() {
        switch model.script {
        case .hiragana:
            storedHiragana = model.storedSelection(for: .hiragana)
        case .katakana:
            storedKatakana = model.storedSelection(for: .katakana)
        }
    }

    private func chartRow(_ row: KanaRow) -> some View {
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

    private func characterCell(_ character: KanaCharacter) -> some View {
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
    let characters: [KanaCharacter]
    var id: String { characters.map(\.glyph).joined() }
}
