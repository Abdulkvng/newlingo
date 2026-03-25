import SwiftUI

struct ScoreCardView: View {
    let title: String
    let score: Int
    let feedback: String
    let color: Color
    var delay: Double = 0

    @State private var appeared = false
    @State private var animateBar = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 10, height: 10)
                    .overlay(Circle().fill(color).frame(width: 5, height: 5))

                Text(title)
                    .font(LingoFont.headline())
                    .foregroundColor(.lingoText)

                Spacer()

                AnimatedCounter(
                    target: appeared ? score : 0,
                    duration: 0.8,
                    font: LingoFont.serif(24),
                    color: Color.scoreColor(for: score)
                )
                .id("\(title)-\(appeared)")

                Text("%")
                    .font(LingoFont.caption())
                    .foregroundColor(Color.scoreColor(for: score))
            }

            // Animated progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gray.opacity(0.12))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(
                            width: animateBar ? geo.size.width * CGFloat(score) / 100 : 0,
                            height: 10
                        )
                }
            }
            .frame(height: 10)

            Text(feedback)
                .font(LingoFont.body(14))
                .foregroundColor(.lingoTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .lingoCard()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .onAppear {
            withAnimation(LingoAnimation.spring.delay(delay)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(delay + 0.3)) {
                animateBar = true
            }
        }
    }
}
