import UIKit

enum HapticKind: Equatable, Sendable {
    case success
    case error
    case light
}

protocol HapticTriggering: Sendable {
    func trigger(_ kind: HapticKind)
}

struct SystemHapticTrigger: HapticTriggering {
    func trigger(_ kind: HapticKind) {
        switch kind {
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

struct NoOpHapticTrigger: HapticTriggering {
    func trigger(_ kind: HapticKind) {}
}
