import Foundation

enum TipKind: String, CaseIterable, Identifiable, Sendable {
    case coffee = "com.seanlai.KanaTrace.tip.coffee"
    case latte = "com.seanlai.KanaTrace.tip.latte"
    case lunch = "com.seanlai.KanaTrace.tip.lunch"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .coffee: return "Coffee"
        case .latte: return "Latte"
        case .lunch: return "Lunch"
        }
    }

    static var productIDs: [String] { allCases.map(\.rawValue) }
}

struct TipProduct: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var displayPrice: String

    var kind: TipKind? { TipKind(rawValue: id) }
}

enum TipPurchaseResult: Equatable, Sendable {
    case success
    case cancelled
    case failed
}

protocol TipPurchasing: Sendable {
    func loadProducts() async throws -> [TipProduct]
    func purchase(productID: String) async throws -> TipPurchaseResult
}
