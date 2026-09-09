import SwiftUI

@main
struct KanaTraceApp: App {
    private let catalog: StrokeCatalog

    init() {
        do {
            catalog = try StrokeCatalog.load(from: StrokeResources.bundle)
        } catch {
            fatalError("KanaStrokes.json is missing from the app bundle: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ChartPickerView(catalog: catalog)
                .preferredColorScheme(.light)
        }
    }
}
