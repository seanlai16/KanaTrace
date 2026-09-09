import Foundation
import Observation

@MainActor
@Observable
final class PracticeSessionViewModel {
    let characters: [KanaCharacter]
    private let catalog: StrokeCatalog
    private let matcherThresholds: StrokeMatcher.Thresholds
    private let haptics: any HapticTriggering

    private(set) var index = 0
    private(set) var strokeIndex = 0
    private(set) var acceptedStrokes: [[StrokePoint]] = []
    private(set) var currentStroke: [StrokePoint] = []
    private(set) var hintEnabled = false
    private(set) var isRevealed = false
    private(set) var lastStrokeRejected = false
    private(set) var shouldDismiss = false
    private(set) var canvasSize = (width: 1.0, height: 1.0)

    init(
        characters: [KanaCharacter],
        catalog: StrokeCatalog,
        thresholds: StrokeMatcher.Thresholds = StrokeMatcher.Thresholds(),
        haptics: any HapticTriggering = SystemHapticTrigger()
    ) {
        self.characters = characters
        self.catalog = catalog
        self.matcherThresholds = thresholds
        self.haptics = haptics
    }

    var current: KanaCharacter { characters[index] }

    var progressLabel: String { "\(index + 1) / \(characters.count)" }

    var isLastCharacter: Bool { index >= characters.count - 1 }

    var viewBox: Double { catalog.viewBox }

    var templates: [[StrokePoint]] {
        catalog.strokes(for: current.glyph)
    }

    var hintTemplate: [StrokePoint]? {
        guard hintEnabled, !isRevealed, strokeIndex < templates.count else { return nil }
        return templates[strokeIndex]
    }

    func updateCanvasSize(_ size: CGSize) {
        canvasSize = (Double(size.width), Double(size.height))
    }

    func useHint() {
        guard !isRevealed else { return }
        hintEnabled = true
        haptics.trigger(.light)
    }

    func beginStroke(at point: StrokePoint) {
        guard !isRevealed else { return }
        lastStrokeRejected = false
        currentStroke = [point]
    }

    func addPoint(_ point: StrokePoint) {
        guard !isRevealed, !currentStroke.isEmpty else { return }
        if let last = currentStroke.last, last.distance(to: point) < 0.8 { return }
        currentStroke.append(point)
    }

    func endStroke() {
        guard !isRevealed, currentStroke.count >= 2 else {
            currentStroke = []
            return
        }
        guard strokeIndex < templates.count else {
            currentStroke = []
            return
        }
        let user = StrokeMatcher.normalizeToCanvas(currentStroke, size: canvasSize)
        let template = StrokeMatcher.normalizeToUnitSquare(templates[strokeIndex], viewBox: catalog.viewBox)
        if StrokeMatcher.matches(user: user, template: template, thresholds: matcherThresholds) {
            acceptedStrokes.append(currentStroke)
            currentStroke = []
            lastStrokeRejected = false
            haptics.trigger(.success)
            if strokeIndex + 1 >= templates.count {
                isRevealed = true
                hintEnabled = false
            } else {
                strokeIndex += 1
            }
        } else {
            currentStroke = []
            lastStrokeRejected = true
            haptics.trigger(.error)
        }
    }

    func continueOrFinish() {
        guard isRevealed else { return }
        if isLastCharacter {
            shouldDismiss = true
            return
        }
        index += 1
        resetCurrentCharacter()
    }

    func close() {
        shouldDismiss = true
    }

    private func resetCurrentCharacter() {
        strokeIndex = 0
        acceptedStrokes = []
        currentStroke = []
        hintEnabled = false
        isRevealed = false
        lastStrokeRejected = false
    }
}
