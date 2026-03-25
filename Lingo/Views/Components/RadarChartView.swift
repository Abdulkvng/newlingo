import SwiftUI

struct RadarChartView: View {
    let feedback: AIFeedback
    @State private var animationProgress: CGFloat = 0

    private let labels = ["Grammar", "Pronunciation", "Fluency", "Vocabulary", "Clarity"]
    private let gridLevels = [20, 40, 60, 80, 100]

    private var scores: [Double] {
        [
            Double(feedback.grammar.score),
            Double(feedback.pronunciation.score),
            Double(feedback.fluency.score),
            Double(feedback.vocabulary.score),
            Double(feedback.clarity.score)
        ]
    }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 36

            ZStack {
                // Grid lines (subtle dashed)
                ForEach(gridLevels, id: \.self) { level in
                    polygonPath(center: center, radius: radius * CGFloat(level) / 100, sides: 5)
                        .stroke(Color.gray.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }

                // Axis lines
                ForEach(0..<5, id: \.self) { i in
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: pointOnCircle(center: center, radius: radius, index: i, total: 5))
                    }
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                }

                // Data polygon fill (animated)
                dataPath(center: center, radius: radius, progress: animationProgress)
                    .fill(
                        RadialGradient(
                            colors: [Color.lingoBlue.opacity(0.25), Color.lingoBlue.opacity(0.05)],
                            center: .center,
                            startRadius: 0,
                            endRadius: radius
                        )
                    )

                // Data polygon stroke (animated)
                dataPath(center: center, radius: radius, progress: animationProgress)
                    .stroke(Color.lingoBlue, lineWidth: 2.5)

                // Data points
                ForEach(0..<5, id: \.self) { i in
                    let r = radius * CGFloat(scores[i]) / 100 * animationProgress
                    let point = pointOnCircle(center: center, radius: r, index: i, total: 5)
                    Circle()
                        .fill(Color.lingoBlue)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .position(point)
                }

                // Labels with scores
                ForEach(0..<5, id: \.self) { i in
                    let labelPoint = pointOnCircle(center: center, radius: radius + 28, index: i, total: 5)
                    VStack(spacing: 1) {
                        Text(labels[i])
                            .font(LingoFont.caption(10))
                            .foregroundColor(.lingoText)
                        Text("\(Int(scores[i]))")
                            .font(LingoFont.caption(10))
                            .foregroundColor(Color.skillColor(for: labels[i]))
                    }
                    .position(labelPoint)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animationProgress = 1
            }
        }
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, index: Int, total: Int) -> CGPoint {
        let angle = (CGFloat(index) / CGFloat(total)) * 2 * .pi - .pi / 2
        return CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }

    private func polygonPath(center: CGPoint, radius: CGFloat, sides: Int) -> Path {
        Path { path in
            for i in 0..<sides {
                let point = pointOnCircle(center: center, radius: radius, index: i, total: sides)
                if i == 0 { path.move(to: point) }
                else { path.addLine(to: point) }
            }
            path.closeSubpath()
        }
    }

    private func dataPath(center: CGPoint, radius: CGFloat, progress: CGFloat) -> Path {
        Path { path in
            for i in 0..<5 {
                let r = radius * CGFloat(scores[i]) / 100 * progress
                let point = pointOnCircle(center: center, radius: r, index: i, total: 5)
                if i == 0 { path.move(to: point) }
                else { path.addLine(to: point) }
            }
            path.closeSubpath()
        }
    }
}
