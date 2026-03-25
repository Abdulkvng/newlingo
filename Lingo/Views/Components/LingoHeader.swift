import SwiftUI

struct LingoHeader: View {
    let title: String
    var onBack: (() -> Void)?
    var showProfileIcon: Bool = false
    var onProfileTap: (() -> Void)?

    var body: some View {
        ZStack {
            // Title — use serif for "Lingo" wordmark, rounded for other titles
            if title == "Lingo" {
                Text("Lingo")
                    .font(LingoFont.serif(22))
                    .foregroundColor(.lingoText)
            } else {
                Text(title)
                    .font(LingoFont.headline())
                    .foregroundColor(.lingoText)
            }

            HStack {
                if let onBack = onBack {
                    Button(action: {
                        LingoHaptics.impact(.light)
                        onBack()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.lingoTextSecondary)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                }

                Spacer()

                if showProfileIcon {
                    Button(action: { onProfileTap?() }) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.lingoBlue.opacity(0.8))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color.lingoBg)
        .overlay(
            Rectangle()
                .fill(Color.borderGray.opacity(0.4))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}
