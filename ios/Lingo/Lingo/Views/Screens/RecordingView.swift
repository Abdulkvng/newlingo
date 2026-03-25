import SwiftUI

struct RecordingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var recorder = AudioRecorder()
    @State private var elapsed: TimeInterval = 0
    @State private var timer: Timer?
    @State private var breathe = false

    var body: some View {
        VStack(spacing: 0) {
            LingoHeader(title: "Recording", onBack: cancelRecording)

            VStack(spacing: 0) {
                // Prompt
                VStack(spacing: 14) {
                    Text(appState.currentPrompt)
                        .font(LingoFont.prompt(20))
                        .foregroundColor(.lingoText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 28)

                    // Challenge words
                    VStack(spacing: 8) {
                        Text("TRY USING")
                            .font(LingoFont.caption(10))
                            .foregroundColor(.accentChallenge)
                            .tracking(1.5)

                        FlowLayout(spacing: 8) {
                            ForEach(appState.challengeWords, id: \.self) { word in
                                Text(word)
                                    .font(LingoFont.body(13))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.accentChallenge)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(Color.accentChallenge.opacity(0.08))
                                    .cornerRadius(20)
                            }
                        }
                    }
                }
                .padding(.horizontal, 28)

                Spacer()

                // Recording visualization — single blue ring
                ZStack {
                    Circle()
                        .stroke(
                            Color.lingoBlue.opacity(0.08),
                            lineWidth: 2
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(1 + recorder.volume * 0.3)
                        .animation(.easeOut(duration: 0.12), value: recorder.volume)

                    // Stop button
                    Button(action: stopRecording) {
                        ZStack {
                            Circle()
                                .fill(Color.lingoRed)
                                .frame(width: 88, height: 88)
                                .shadow(color: .lingoRed.opacity(0.2), radius: 12, y: 4)
                                .scaleEffect(breathe ? 1.03 : 1.0)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white)
                                .frame(width: 28, height: 28)
                        }
                    }
                }

                Spacer()

                // Timer + instruction
                VStack(spacing: 10) {
                    Text(formatTime(elapsed))
                        .font(LingoFont.serif(24))
                        .foregroundColor(.lingoText)
                        .monospacedDigit()

                    if let error = recorder.error {
                        Text(error)
                            .font(LingoFont.body(14))
                            .foregroundColor(.lingoRed)
                            .multilineTextAlignment(.center)
                    }

                    Text("Tap to stop recording")
                        .font(LingoFont.body(14))
                        .foregroundColor(.lingoTextSecondary)
                }
                .padding(.bottom, 44)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.lingoBg.ignoresSafeArea())
        .onAppear {
            LingoHaptics.impact(.heavy)
            recorder.startRecording()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                elapsed += 0.1
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
        .onDisappear {
            timer?.invalidate()
            if recorder.isRecording { recorder.cancelRecording() }
        }
    }

    private func stopRecording() {
        LingoHaptics.notification(.success)
        timer?.invalidate()
        guard recorder.isRecording else { return }
        if let audioData = recorder.stopRecording() {
            Task { await appState.submitRecording(audioData: audioData) }
        }
    }

    private func cancelRecording() {
        timer?.invalidate()
        recorder.cancelRecording()
        appState.navigateTo(.prompt)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
