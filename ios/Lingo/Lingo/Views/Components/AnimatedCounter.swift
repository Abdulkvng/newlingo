import SwiftUI

struct AnimatedCounter: View {
    let target: Int
    var duration: Double = 1.2
    var font: Font = LingoFont.display()
    var color: Color = .lingoText

    @State private var current: Int = 0
    @State private var timer: Timer?

    var body: some View {
        Text("\(current)")
            .font(font)
            .foregroundColor(color)
            .contentTransition(.numericText())
            .onAppear { startCounting() }
            .onDisappear { timer?.invalidate() }
    }

    private func startCounting() {
        guard target > 0 else { return }
        let steps = min(target, 40)
        let interval = duration / Double(steps)
        let increment = max(1, target / steps)
        var count = 0

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
            count += increment
            if count >= target {
                current = target
                t.invalidate()
            } else {
                current = count
            }
        }
    }
}
