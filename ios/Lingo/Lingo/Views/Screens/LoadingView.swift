import SwiftUI

struct LoadingView: View {
    @State private var breathe = false
    @State private var messageIndex = 0
    @State private var dotPhase = 0

    private let messages = [
        "Listening to your pronunciation",
        "Analyzing grammar patterns",
        "Evaluating vocabulary usage",
        "Preparing your feedback"
    ]

    let messageTimer = Timer.publish(every: 2.5, on: .main, in: .common).autoconnect()
    let dotTimer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 44) {
            Spacer()

            // Breathing waveform icon
            ZStack {
                Circle()
                    .fill(Color.lingoBlue.opacity(0.04))
                    .frame(width: 120, height: 120)
                    .scaleEffect(breathe ? 1.08 : 0.92)

                Image(systemName: "waveform")
                    .font(.system(size: 38, weight: .medium))
                    .foregroundColor(.lingoBlueDeep)
                    .scaleEffect(breathe ? 1.05 : 0.95)
                    .opacity(breathe ? 1 : 0.6)
            }
            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: breathe)

            // Status message
            VStack(spacing: 16) {
                Text(messages[messageIndex])
                    .font(LingoFont.serifItalic(20))
                    .foregroundColor(.lingoTextSecondary)
                    .id(messageIndex)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 8)),
                        removal: .opacity.combined(with: .offset(y: -8))
                    ))
                    .animation(LingoAnimation.smooth, value: messageIndex)

                // Pulsing dots
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.lingoBlue.opacity(dotPhase == i ? 0.8 : 0.2))
                            .frame(width: 6, height: 6)
                            .scaleEffect(dotPhase == i ? 1.2 : 1)
                            .animation(LingoAnimation.quick, value: dotPhase)
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.lingoBg.ignoresSafeArea())
        .onAppear { breathe = true }
        .onReceive(messageTimer) { _ in
            messageIndex = (messageIndex + 1) % messages.count
        }
        .onReceive(dotTimer) { _ in
            dotPhase = (dotPhase + 1) % 3
        }
    }
}
