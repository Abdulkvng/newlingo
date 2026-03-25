import SwiftUI

struct ChallengeWordsCard: View {
    let words: [ChallengeWordFeedback]
    @State private var appeared = false

    var body: some View {
        if !words.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                // Header with summary
                HStack {
                    Text("Challenge Words")
                        .font(LingoFont.serif(18))
                        .foregroundColor(.lingoText)

                    Spacer()

                    let usedCount = words.filter(\.used).count
                    Text("\(usedCount)/\(words.count)")
                        .font(LingoFont.caption(14))
                        .foregroundColor(usedCount == words.count ? .scorePronunciation : .lingoTextSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            (usedCount == words.count ? Color.scorePronunciation : Color.gray)
                                .opacity(0.1)
                        )
                        .cornerRadius(12)
                }

                ForEach(Array(words.enumerated()), id: \.element.word) { index, word in
                    HStack(alignment: .top, spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(word.used ? Color.scorePronunciation.opacity(0.15) : Color.gray.opacity(0.08))
                                .frame(width: 28, height: 28)

                            Image(systemName: word.used ? "checkmark" : "minus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(word.used ? .scorePronunciation : .lingoTextSecondary.opacity(0.4))
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(word.word)
                                .font(LingoFont.body())
                                .fontWeight(.semibold)
                                .foregroundColor(.lingoText)

                            Text(word.feedback)
                                .font(LingoFont.body(13))
                                .foregroundColor(.lingoTextSecondary)
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(x: appeared ? 0 : -10)
                    .animation(LingoAnimation.stagger(index: index, base: 0.08), value: appeared)
                }
            }
            .lingoCard()
            .onAppear {
                withAnimation { appeared = true }
            }
        }
    }
}
