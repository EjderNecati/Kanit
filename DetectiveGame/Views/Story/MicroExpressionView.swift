import SwiftUI

struct MicroExpressionView: View {
    let expression: MicroExpression
    let onCatch: () -> Void
    @EnvironmentObject var loc: LocalizationManager

    @State private var isCaught = false
    @State private var timeRemaining: Double
    @State private var timer: Timer? = nil

    init(expression: MicroExpression, onCatch: @escaping () -> Void) {
        self.expression = expression
        self.onCatch = onCatch
        self._timeRemaining = State(initialValue: expression.timeWindow)
    }

    var body: some View {
        if !isCaught {
            Button(action: catchExpression) {
                HStack(spacing: 8) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.noirGold)

                    Text(loc.s(.catchExpression))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.noirGold)

                    // Zaman cubugu
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.noirMuted.opacity(0.3))
                            Capsule()
                                .fill(Color.noirGold.opacity(0.7))
                                .frame(width: geo.size.width * CGFloat(max(0, timeRemaining / expression.timeWindow)))
                        }
                    }
                    .frame(width: 40, height: 4)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.noirPrimary.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.noirGold.opacity(0.5), lineWidth: 1)
                        )
                        .shadow(color: .noirGold.opacity(0.3), radius: 6)
                )
            }
            .buttonStyle(.plain)
            .transition(.scale.combined(with: .opacity))
            .onAppear { startTimer() }
            .onDisappear { timer?.invalidate(); timer = nil }
        }

        if isCaught {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.noirGold)
                Text(expression.displayText)
                    .font(.noirCaption(12))
                    .foregroundColor(.noirText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.noirSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.noirGold.opacity(0.3), lineWidth: 0.5)
                    )
            )
            .transition(.opacity)
        }
    }

    private func catchExpression() {
        timer?.invalidate()
        timer = nil
        SoundEngine.shared.evidenceChime()
        withAnimation(.easeOut(duration: 0.3)) {
            isCaught = true
        }
        onCatch()

        // 3 saniye sonra caught mesajini gizle
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { isCaught = false }
        }
    }

    private func startTimer() {
        timeRemaining = expression.timeWindow
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { t in
            timeRemaining -= 0.1
            if timeRemaining <= 0 {
                t.invalidate()
                timer = nil
            }
        }
    }
}
