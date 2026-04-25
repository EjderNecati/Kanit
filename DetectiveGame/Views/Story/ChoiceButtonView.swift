import SwiftUI

struct ChoiceButtonView: View {
    let choice: Choice
    let canAfford: Bool
    let index: Int
    let action: () -> Void

    @State private var isAppeared = false
    @State private var isPressed = false

    private var accentColor: Color {
        if !canAfford { return .noirMuted }
        if choice.creditCost > 0 { return .noirCredit }
        return .noirSecondary
    }

    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 12) {
                // Secenek metni
                Text(choice.text)
                    .font(.noirChoice())
                    .foregroundColor(canAfford ? .noirText : .noirMuted)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Kredi maliyeti
                if choice.creditCost > 0 {
                    CreditCostBadge(cost: choice.creditCost)
                }
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.noirPrimary.opacity(canAfford ? 0.7 : 0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                canAfford ? Color.noirSecondary.opacity(0.4) : Color.noirMuted.opacity(0.2),
                                lineWidth: 1
                            )
                    )
            )
            // Sol border accent
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor.opacity(canAfford ? 0.8 : 0.3))
                    .frame(width: 3)
                    .padding(.vertical, 6)
                    .padding(.leading, 4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .opacity(isAppeared ? 1 : 0)
        .offset(y: isAppeared ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25).delay(Double(index) * 0.08)) {
                isAppeared = true
            }
        }
        .onDisappear {
            isAppeared = false
        }
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}
