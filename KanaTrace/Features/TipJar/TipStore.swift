import Foundation
import Observation

@MainActor
@Observable
final class TipStore {
    private let purchasing: any TipPurchasing

    private(set) var products: [TipProduct] = []
    private(set) var isLoading = false
    private(set) var purchasingID: String?
    private(set) var loadFailed = false

    var isUnavailable: Bool { !isLoading && (loadFailed || products.isEmpty) }

    init(purchasing: any TipPurchasing = StoreKitTipPurchasing()) {
        self.purchasing = purchasing
    }

    func load() async {
        isLoading = true
        loadFailed = false
        defer { isLoading = false }
        do {
            products = try await purchasing.loadProducts()
        } catch {
            products = []
            loadFailed = true
        }
    }

    func purchase(_ product: TipProduct) async -> TipPurchaseResult {
        purchasingID = product.id
        defer { purchasingID = nil }
        do {
            return try await purchasing.purchase(productID: product.id)
        } catch {
            return .failed
        }
    }
}
