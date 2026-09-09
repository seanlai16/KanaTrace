import StoreKit
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
        Self.listenForTransactions()
    }

    var body: some Scene {
        WindowGroup {
            ChartPickerView(catalog: catalog)
                .preferredColorScheme(.light)
        }
    }

    private static func listenForTransactions() {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
            }
        }
    }
}
