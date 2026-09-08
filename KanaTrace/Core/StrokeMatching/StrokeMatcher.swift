import Foundation

struct StrokePoint: Equatable, Sendable {
    var x: Double
    var y: Double

    func distance(to other: StrokePoint) -> Double {
        hypot(x - other.x, y - other.y)
    }

    static func - (lhs: StrokePoint, rhs: StrokePoint) -> StrokePoint {
        StrokePoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}

enum StrokeMatcher {
    static let sampleCount = 32
    static let minNormalizedLength = 0.08
    static let viewBox: Double = 109

    struct Thresholds: Equatable, Sendable {
        /// Combined cost must stay under this to accept.
        var maxCost: Double = 0.40
        /// BBox-normalized shape distance.
        var maxShape: Double = 0.34
        var maxStart: Double = 0.46
        var maxEnd: Double = 0.50
        /// Reject reversed strokes unless the template is almost a dot.
        var minDirection: Double = 0.05
        var shortVector: Double = 0.10
    }

    static let `default` = Thresholds()

    static func pathLength(_ points: [StrokePoint]) -> Double {
        zip(points, points.dropFirst()).reduce(0) { $0 + $1.0.distance(to: $1.1) }
    }

    static func resample(_ points: [StrokePoint], count: Int = sampleCount) -> [StrokePoint] {
        guard count >= 2 else { return points }
        guard points.count >= 2 else { return points }
        let total = pathLength(points)
        if total == 0 {
            return Array(repeating: points[0], count: count)
        }
        var output: [StrokePoint] = []
        output.reserveCapacity(count)
        var segment = 0
        var traveled: [Double] = [0]
        for (a, b) in zip(points, points.dropFirst()) {
            traveled.append(traveled[traveled.count - 1] + a.distance(to: b))
        }
        for i in 0..<count {
            let target = total * Double(i) / Double(count - 1)
            while segment + 1 < traveled.count, traveled[segment + 1] < target {
                segment += 1
            }
            let next = min(segment + 1, traveled.count - 1)
            let startLen = traveled[segment]
            let endLen = traveled[next]
            let span = endLen - startLen
            let t = span == 0 ? 0 : (target - startLen) / span
            let a = points[segment]
            let b = points[next]
            output.append(
                StrokePoint(
                    x: a.x + (b.x - a.x) * t,
                    y: a.y + (b.y - a.y) * t
                )
            )
        }
        return output
    }

    /// User and template must already live in the same 0...1 square.
    static func cost(user: [StrokePoint], template: [StrokePoint]) -> Double? {
        guard pathLength(user) >= minNormalizedLength else { return nil }
        guard template.count >= 2 else { return nil }
        let u = resample(user)
        let t = resample(template)
        let shape = meanDistance(normalize(u), normalize(t))
        let start = u[0].distance(to: t[0])
        let end = u[u.count - 1].distance(to: t[t.count - 1])
        let userVector = u[u.count - 1] - u[0]
        let templateVector = t[t.count - 1] - t[0]
        let templateSpan = hypot(templateVector.x, templateVector.y)
        let direction: Double
        if templateSpan < Thresholds().shortVector {
            direction = 1
        } else {
            direction = dotUnit(userVector, templateVector)
        }
        let lengthRatio = {
            let uLen = pathLength(u)
            let tLen = pathLength(t)
            let longest = max(uLen, tLen)
            return longest == 0 ? 0 : min(uLen, tLen) / longest
        }()
        let directionPenalty = direction < 0 ? 0.55 : (1 - direction) * 0.18
        let lengthPenalty = (1 - lengthRatio) * 0.16
        return shape * 0.42 + start * 0.18 + end * 0.18 + directionPenalty + lengthPenalty
    }

    static func matches(
        user: [StrokePoint],
        template: [StrokePoint],
        thresholds: Thresholds = Thresholds()
    ) -> Bool {
        guard let scored = cost(user: user, template: template) else { return false }
        let u = resample(user)
        let t = resample(template)
        let shape = meanDistance(normalize(u), normalize(t))
        let start = u[0].distance(to: t[0])
        let end = u[u.count - 1].distance(to: t[t.count - 1])
        let templateVector = t[t.count - 1] - t[0]
        let templateSpan = hypot(templateVector.x, templateVector.y)
        let direction = dotUnit(u[u.count - 1] - u[0], templateVector)
        if shape > thresholds.maxShape { return false }
        if start > thresholds.maxStart { return false }
        if end > thresholds.maxEnd { return false }
        if templateSpan >= thresholds.shortVector, direction < thresholds.minDirection {
            return false
        }
        return scored <= thresholds.maxCost
    }

    static func normalizeToUnitSquare(_ points: [StrokePoint], viewBox: Double = viewBox) -> [StrokePoint] {
        guard viewBox > 0 else { return points }
        return points.map { StrokePoint(x: $0.x / viewBox, y: $0.y / viewBox) }
    }

    static func normalizeToCanvas(_ points: [StrokePoint], size: (width: Double, height: Double)) -> [StrokePoint] {
        let w = max(size.width, 1)
        let h = max(size.height, 1)
        return points.map { StrokePoint(x: $0.x / w, y: $0.y / h) }
    }

    private static func meanDistance(_ a: [StrokePoint], _ b: [StrokePoint]) -> Double {
        let n = min(a.count, b.count)
        guard n > 0 else { return 1 }
        var sum = 0.0
        for i in 0..<n {
            sum += a[i].distance(to: b[i])
        }
        return sum / Double(n)
    }

    private static func normalize(_ points: [StrokePoint]) -> [StrokePoint] {
        guard let first = points.first else { return points }
        var minX = first.x
        var minY = first.y
        var maxX = first.x
        var maxY = first.y
        for p in points {
            minX = min(minX, p.x)
            minY = min(minY, p.y)
            maxX = max(maxX, p.x)
            maxY = max(maxY, p.y)
        }
        let scale = max(maxX - minX, maxY - minY, 0.001)
        return points.map { StrokePoint(x: ($0.x - minX) / scale, y: ($0.y - minY) / scale) }
    }

    private static func dotUnit(_ a: StrokePoint, _ b: StrokePoint) -> Double {
        let la = hypot(a.x, a.y)
        let lb = hypot(b.x, b.y)
        if la == 0 || lb == 0 { return 1 }
        return (a.x * b.x + a.y * b.y) / (la * lb)
    }
}
