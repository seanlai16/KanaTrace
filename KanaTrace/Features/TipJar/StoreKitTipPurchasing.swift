import Foundation
import StoreKit

struct StoreKitTipPurchasing: TipPurchasing {
    func loadProducts() async throws -> [TipProduct] {
        let storeProducts = try await Product.products(for: Set(TipKind.productIDs))
        return TipKind.allCases.compactMap { kind in
            guard let product = storeProducts.first(where: { $0.id == kind.rawValue }) else {
                return nil
            }
            return TipProduct(id: product.id, title: kind.title, displayPrice: product.displayPrice)
        }
    }

    func purchase(productID: String) async throws -> TipPurchaseResult {
        let storeProducts = try await Product.products(for: [productID])
        guard let product = storeProducts.first else {
            return .failed
        }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return .success
        case .userCancelled:
            return .cancelled
        case .pending:
            return .failed
        @unknown default:
            return .failed
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw TipStoreError.unverified
        case .verified(let value):
            return value
        }
    }
}

enum TipStoreError: Error {
    case unverified
}
