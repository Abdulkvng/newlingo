import SwiftUI

struct ScoreTrendChart: View {
    let sessions: [SessionResult]
    @State private var animateChart = false
    @State private var pulseLastPoint = false

    private var scores: [Int] {
        sessions.reversed().map { $0.feedback.overallScore }
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let padding: CGFloat = 32
            let chartWidth = width - padding * 2
            let chartHeight = height - padding * 2

            ZStack(alignment: .topLeading) {
                // Y-axis grid (dashed)
                ForEach([0, 25, 50, 75, 100], id: \.self) { value in
                    let y = padding + chartHeight * (1 - CGFloat(value) / 100)
                    Path { path in
                        path.move(to: CGPoint(x: padding, y: y))
                        path.addLine(to: CGPoint(x: width - padding, y: y))
                    }
                    .stroke(Color.gray.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                    Text("\(value)")
                        .font(LingoFont.caption(9))
                        .foregroundColor(.lingoTextSecondary)
                        .position(x: padding - 16, y: y)
                }

                if scores.count >= 2 {
                    // Gradient fill
                    fillPath(chartWidth: chartWidth, chartHeight: chartHeight, padding: padding)
                        .fill(
                            LinearGradient(
                                colors: [Color.lingoBlue.opacity(0.2), Color.lingoBlue.opacity(0)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .opacity(animateChart ? 1 : 0)

                    // Line (animated draw)
                    linePath(chartWidth: chartWidth, chartHeight: chartHeight, padding: padding)
                        .trim(from: 0, to: animateChart ? 1 : 0)
                        .stroke(
                            Color.lingoBlue,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )

                    // Points
                    ForEach(0..<scores.count, id: \.self) { index in
                        let x = padding + chartWidth * CGFloat(index) / CGFloat(scores.count - 1)
                        let y = padding + chartHeight * (1 - CGFloat(scores[index]) / 100)
                        let isLast = index == scores.count - 1

                        Circle()
                            .fill(Color.lingoBlue)
                            .frame(width: isLast ? 10 : 6, height: isLast ? 10 : 6)
                            .overlay(
                                isLast
                                    ? Circle()
                                        .stroke(Color.lingoBlue.opacity(0.3), lineWidth: 2)
                                        .frame(width: 18, height: 18)
                                        .scaleEffect(pulseLastPoint ? 1.3 : 1.0)
                                        .opacity(pulseLastPoint ? 0 : 0.5)
                                    : nil
                            )
                            .position(x: x, y: y)
                            .opacity(animateChart ? 1 : 0)
                            .animation(LingoAnimation.stagger(index: index, base: 0.08), value: animateChart)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animateChart = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(1.0)) {
                pulseLastPoint = true
            }
        }
    }

    private func linePath(chartWidth: CGFloat, chartHeight: CGFloat, padding: CGFloat) -> Path {
        Path { path in
            for (index, score) in scores.enumerated() {
                let x = padding + chartWidth * CGFloat(index) / CGFloat(scores.count - 1)
                let y = padding + chartHeight * (1 - CGFloat(score) / 100)
                if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
        }
    }

    private func fillPath(chartWidth: CGFloat, chartHeight: CGFloat, padding: CGFloat) -> Path {
        Path { path in
            for (index, score) in scores.enumerated() {
                let x = padding + chartWidth * CGFloat(index) / CGFloat(scores.count - 1)
                let y = padding + chartHeight * (1 - CGFloat(score) / 100)
                if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            path.addLine(to: CGPoint(x: padding + chartWidth, y: padding + chartHeight))
            path.addLine(to: CGPoint(x: padding, y: padding + chartHeight))
            path.closeSubpath()
        }
    }
}
