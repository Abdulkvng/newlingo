import SwiftUI

// MARK: - Typography System (SF Pro Rounded + Instrument Serif)

struct LingoFont {
    // SF Pro Rounded — UI elements
    static func display(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func title(_ size: CGFloat = 24) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func headline(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func button(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    // Instrument Serif — hero, headings, editorial
    static func serif(_ size: CGFloat = 36) -> Font {
        .custom("InstrumentSerif-Regular", size: size)
    }
    static func serifItalic(_ size: CGFloat = 36) -> Font {
        .custom("InstrumentSerif-Italic", size: size)
    }
    static func prompt(_ size: CGFloat = 26) -> Font {
        .custom("InstrumentSerif-Regular", size: size)
    }
}

// MARK: - Color Palette (Curated, blue-complementary)

extension Color {
    // Primary
    static let lingoBlue = Color(hex: "007AFF")
    static let lingoBlueDark = Color(hex: "003DA5")
    static let lingoBlueDeep = Color(hex: "0055D4")
    static let lingoRed = Color(hex: "FF3B30")

    // Text
    static let lingoText = Color(hex: "1A1A1A")
    static let lingoTextSecondary = Color(hex: "6B7280")

    // Backgrounds
    static let lingoBg = Color(hex: "FAFAF8")
    static let lingoCardBg = Color.white

    // Score colors — muted, blue-complementary palette
    static let scoreGrammar = Color(hex: "4A90D9")       // soft blue
    static let scorePronunciation = Color(hex: "34B89A")  // teal-green
    static let scoreFluency = Color(hex: "6C5CE7")        // soft indigo
    static let scoreVocabulary = Color(hex: "E8915A")     // warm amber
    static let scoreClarity = Color(hex: "9B8EC4")        // lavender

    // Accents
    static let accentXp = Color(hex: "FFD60A")
    static let accentChallenge = Color(hex: "6C5CE7")     // indigo
    static let borderGray = Color(hex: "E5E7EB")

    // Helpers
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    static func scoreColor(for score: Int) -> Color {
        if score < 50 { return .lingoRed }
        if score < 80 { return .scoreVocabulary }
        return .scorePronunciation
    }

    static func skillColor(for skill: String) -> Color {
        switch skill.lowercased() {
        case "grammar": return .scoreGrammar
        case "pronunciation": return .scorePronunciation
        case "fluency": return .scoreFluency
        case "vocabulary": return .scoreVocabulary
        case "clarity": return .scoreClarity
        default: return .lingoBlue
        }
    }
}

// MARK: - Gradients

extension LinearGradient {
    static let lingoBg = LinearGradient(
        colors: [Color(hex: "FAFAF8"), Color(hex: "FAFAF8")],
        startPoint: .top, endPoint: .bottom
    )
    static let lingoBlue = LinearGradient(
        colors: [Color.lingoBlueDeep, Color.lingoBlueDark],
        startPoint: .top, endPoint: .bottom
    )
    static let xpGold = LinearGradient(
        colors: [Color(hex: "FFD60A"), Color(hex: "FFAA00")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let success = LinearGradient(
        colors: [Color(hex: "34B89A"), Color(hex: "2A9A7F")],
        startPoint: .top, endPoint: .bottom
    )
    static let recordingRed = LinearGradient(
        colors: [Color(hex: "FF3B30"), Color(hex: "CC2D26")],
        startPoint: .top, endPoint: .bottom
    )
}

// MARK: - Animation Presets

struct LingoAnimation {
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.75)
    static let bouncy = Animation.spring(response: 0.6, dampingFraction: 0.6)
    static let quick = Animation.spring(response: 0.3, dampingFraction: 0.8)
    static let smooth = Animation.easeInOut(duration: 0.3)

    static func stagger(index: Int, base: Double = 0.06) -> Animation {
        .spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * base)
    }
}

// MARK: - Haptics

struct LingoHaptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - Button Styles

struct LingoPrimaryButtonStyle: ButtonStyle {
    var disabled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LingoFont.serif(19))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                Group {
                    if disabled {
                        Color.gray.opacity(0.3)
                    } else {
                        LinearGradient.lingoBlue
                    }
                }
            )
            .cornerRadius(16)
            .shadow(
                color: disabled ? .clear : Color.lingoBlueDark.opacity(0.25),
                radius: configuration.isPressed ? 4 : 12,
                y: configuration.isPressed ? 2 : 6
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct LingoSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LingoFont.serif(18))
            .foregroundColor(.lingoBlueDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.lingoBlueDeep.opacity(0.06))
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Card Modifier

struct LingoCard: ViewModifier {
    var padding: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.lingoCardBg)
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
            .shadow(color: .black.opacity(0.02), radius: 2, x: 0, y: 1)
    }
}

extension View {
    func lingoCard(padding: CGFloat = 20) -> some View {
        modifier(LingoCard(padding: padding))
    }
}

// MARK: - Section Header (Serif two-line pattern)

struct LingoSectionHeader: View {
    let line1: String
    let line2: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(line1)
                .font(LingoFont.serif(22))
                .foregroundColor(.lingoText)
            Text(line2)
                .font(LingoFont.serifItalic(22))
                .foregroundColor(.lingoBlue)
        }
    }
}
