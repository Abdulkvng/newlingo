import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false

    private let colors: [Color] = [.lingoBlue, .scorePronunciation, .scoreFluency, .accentXp]
    private let count = 60

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let elapsed = now - particle.startTime
                    guard elapsed > 0, elapsed < particle.lifetime else { continue }

                    let progress = elapsed / particle.lifetime
                    let x = particle.startX + particle.velocityX * elapsed
                    let y = particle.startY + particle.velocityY * elapsed + 400 * elapsed * elapsed // gravity
                    let opacity = 1.0 - progress
                    let rotation = particle.rotation + particle.rotationSpeed * elapsed
                    let scale = particle.scale * (1.0 - progress * 0.3)

                    guard x > -20, x < size.width + 20, y < size.height + 20 else { continue }

                    context.opacity = opacity
                    context.translateBy(x: x, y: y)
                    context.rotate(by: .degrees(rotation))
                    context.scaleBy(x: scale, y: scale)

                    let rect = CGRect(x: -4, y: -6, width: 8, height: 12)
                    context.fill(
                        RoundedRectangle(cornerRadius: 2).path(in: rect),
                        with: .color(particle.color)
                    )

                    context.transform = .identity
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { emit() }
    }

    private func emit() {
        let now = Date().timeIntervalSinceReferenceDate
        particles = (0..<count).map { _ in
            ConfettiParticle(
                startX: CGFloat.random(in: 50...350),
                startY: CGFloat.random(in: -40...20),
                velocityX: CGFloat.random(in: -120...120),
                velocityY: CGFloat.random(in: -350 ... -100),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -400...400),
                scale: CGFloat.random(in: 0.6...1.2),
                color: colors.randomElement()!,
                lifetime: Double.random(in: 2.5...4.0),
                startTime: now + Double.random(in: 0...0.3)
            )
        }
    }
}

private struct ConfettiParticle {
    let startX: CGFloat
    let startY: CGFloat
    let velocityX: CGFloat
    let velocityY: CGFloat
    let rotation: Double
    let rotationSpeed: Double
    let scale: CGFloat
    let color: Color
    let lifetime: Double
    let startTime: TimeInterval
}
