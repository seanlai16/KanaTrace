import XCTest
@testable import KanaTrace

@MainActor
final class TipStoreTests: XCTestCase {
    func testLoadThreeProducts() async {
        let fake = FakeTipPurchasing(products: Self.threeTips)
        let store = TipStore(purchasing: fake)
        await store.load()
        XCTAssertEqual(store.products.map(\.id), TipKind.productIDs)
        XCTAssertFalse(store.isUnavailable)
    }

    func testLoadEmptyMarksUnavailable() async {
        let store = TipStore(purchasing: FakeTipPurchasing(products: []))
        await store.load()
        XCTAssertTrue(store.products.isEmpty)
        XCTAssertTrue(store.isUnavailable)
    }

    func testLoadFailureMarksUnavailable() async {
        let store = TipStore(purchasing: FakeTipPurchasing(loadError: TipStoreError.unverified))
        await store.load()
        XCTAssertTrue(store.isUnavailable)
    }

    func testPurchaseSuccess() async {
        let fake = FakeTipPurchasing(products: Self.threeTips, result: .success)
        let store = TipStore(purchasing: fake)
        await store.load()
        let result = await store.purchase(store.products[0])
        XCTAssertEqual(result, .success)
        XCTAssertNil(store.purchasingID)
        XCTAssertEqual(fake.lastPurchasedID, TipKind.coffee.rawValue)
    }

    func testPurchaseCancelled() async {
        let fake = FakeTipPurchasing(products: Self.threeTips, result: .cancelled)
        let store = TipStore(purchasing: fake)
        await store.load()
        let result = await store.purchase(store.products[1])
        XCTAssertEqual(result, .cancelled)
        XCTAssertNil(store.purchasingID)
    }

    func testPurchaseFailure() async {
        let fake = FakeTipPurchasing(products: Self.threeTips, purchaseError: TipStoreError.unverified)
        let store = TipStore(purchasing: fake)
        await store.load()
        let result = await store.purchase(store.products[2])
        XCTAssertEqual(result, .failed)
    }

    private static let threeTips = [
        TipProduct(id: TipKind.coffee.rawValue, title: "Coffee", displayPrice: "$0.99"),
        TipProduct(id: TipKind.latte.rawValue, title: "Latte", displayPrice: "$2.99"),
        TipProduct(id: TipKind.lunch.rawValue, title: "Lunch", displayPrice: "$4.99")
    ]
}

private struct FakeTipPurchasing: TipPurchasing {
    var products: [TipProduct]
    var result: TipPurchaseResult
    var loadError: Error?
    var purchaseError: Error?
    let lastPurchasedBox: LastPurchaseBox

    var lastPurchasedID: String? { lastPurchasedBox.id }

    init(
        products: [TipProduct] = [],
        result: TipPurchaseResult = .success,
        loadError: Error? = nil,
        purchaseError: Error? = nil
    ) {
        self.products = products
        self.result = result
        self.loadError = loadError
        self.purchaseError = purchaseError
        self.lastPurchasedBox = LastPurchaseBox()
    }

    func loadProducts() async throws -> [TipProduct] {
        if let loadError { throw loadError }
        return products
    }

    func purchase(productID: String) async throws -> TipPurchaseResult {
        lastPurchasedBox.id = productID
        if let purchaseError { throw purchaseError }
        return result
    }
}

private final class LastPurchaseBox: @unchecked Sendable {
    var id: String?
}
