import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.4), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: phase * geo.size.width)
                    .animation(
                        .linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: phase
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onAppear { phase = 1.5 }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

struct ShimmerPlaceholder: View {
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 10

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.12))
            .frame(height: height)
            .shimmer()
    }
}
