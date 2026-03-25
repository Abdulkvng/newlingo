import SwiftUI

struct ProficiencyPicker: View {
    @Binding var selected: ProficiencyLevel
    @Namespace private var pickerAnimation

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ProficiencyLevel.allCases, id: \.self) { level in
                Button(action: {
                    LingoHaptics.selection()
                    withAnimation(LingoAnimation.quick) {
                        selected = level
                    }
                }) {
                    Text(level.rawValue)
                        .font(LingoFont.body(14))
                        .foregroundColor(selected == level ? .lingoBlueDeep : .lingoTextSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background {
                            if selected == level {
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                                    .matchedGeometryEffect(id: "picker", in: pickerAnimation)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.gray.opacity(0.12))
        .cornerRadius(14)
    }
}
