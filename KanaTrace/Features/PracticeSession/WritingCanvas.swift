import SwiftUI

struct WritingCanvas: View {
    var viewModel: PracticeSessionViewModel

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.paperRaised)
                canvasGuides
                hintLayer
                inkLayer
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(viewModel.lastStrokeRejected ? Color.reject : Color.inkFaint, lineWidth: 1.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .gesture(drawGesture)
            .onAppear { viewModel.updateCanvasSize(geo.size) }
            .onChange(of: geo.size) { _, size in
                viewModel.updateCanvasSize(size)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var canvasGuides: some View {
        Canvas { context, size in
            let inset: CGFloat = 28
            let box = Path(roundedRect: CGRect(x: inset, y: inset, width: size.width - inset * 2, height: size.height - inset * 2), cornerRadius: 8)
            context.stroke(box, with: .color(.inkFaint.opacity(0.7)), style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
            var mid = Path()
            mid.move(to: CGPoint(x: size.width / 2, y: inset))
            mid.addLine(to: CGPoint(x: size.width / 2, y: size.height - inset))
            mid.move(to: CGPoint(x: inset, y: size.height / 2))
            mid.addLine(to: CGPoint(x: size.width - inset, y: size.height / 2))
            context.stroke(mid, with: .color(.inkFaint.opacity(0.45)), style: StrokeStyle(lineWidth: 0.8, dash: [4, 6]))
        }
        .allowsHitTesting(false)
    }

    private var hintLayer: some View {
        Canvas { context, size in
            guard let template = viewModel.hintTemplate else { return }
            let points = template.map { canvasPoint($0, in: size, viewBox: viewModel.viewBox) }
            guard let path = polyline(points) else { return }
            context.stroke(
                path,
                with: .color(.vermillion.opacity(0.85)),
                style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)
            )
            if let start = points.first {
                let dot = Path(ellipseIn: CGRect(x: start.x - 7, y: start.y - 7, width: 14, height: 14))
                context.fill(dot, with: .color(.vermillion))
            }
            if points.count >= 2 {
                let a = points[points.count - 2]
                let b = points[points.count - 1]
                context.fill(arrowHead(from: a, to: b), with: .color(.vermillion))
            }
        }
        .allowsHitTesting(false)
    }

    private var inkLayer: some View {
        Canvas { context, size in
            for stroke in viewModel.acceptedStrokes {
                if let path = polyline(stroke.map { CGPoint(x: $0.x, y: $0.y) }) {
                    context.stroke(
                        path,
                        with: .color(.ink),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round)
                    )
                }
            }
            if let path = polyline(viewModel.currentStroke.map { CGPoint(x: $0.x, y: $0.y) }) {
                context.stroke(
                    path,
                    with: .color(.ink),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .allowsHitTesting(false)
    }

    private var drawGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let point = StrokePoint(x: value.location.x, y: value.location.y)
                if viewModel.currentStroke.isEmpty {
                    viewModel.beginStroke(at: point)
                } else {
                    viewModel.addPoint(point)
                }
            }
            .onEnded { _ in
                viewModel.endStroke()
            }
    }

    private func canvasPoint(_ point: StrokePoint, in size: CGSize, viewBox: Double) -> CGPoint {
        CGPoint(
            x: point.x / viewBox * size.width,
            y: point.y / viewBox * size.height
        )
    }

    private func polyline(_ points: [CGPoint]) -> Path? {
        guard let first = points.first else { return nil }
        var path = Path()
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        return path
    }

    private func arrowHead(from: CGPoint, to: CGPoint) -> Path {
        let angle = atan2(to.y - from.y, to.x - from.x)
        let length: CGFloat = 16
        let left = CGPoint(
            x: to.x - length * cos(angle - .pi / 6),
            y: to.y - length * sin(angle - .pi / 6)
        )
        let right = CGPoint(
            x: to.x - length * cos(angle + .pi / 6),
            y: to.y - length * sin(angle + .pi / 6)
        )
        var path = Path()
        path.move(to: to)
        path.addLine(to: left)
        path.addLine(to: right)
        path.closeSubpath()
        return path
    }
}
