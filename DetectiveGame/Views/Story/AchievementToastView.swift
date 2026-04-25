import SwiftUI

struct AchievementToastView: View {
    let achievement: Achievement
    @EnvironmentObject var loc: LocalizationManager
    @State private var glowPulse = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.system(size: 24))
                .foregroundColor(.noirGold)

            VStack(alignment: .leading, spacing: 2) {
                Text(loc.s(.achievementUnlocked))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.noirGold)
                    .tracking(1)

                Text(achievement.title)
                    .font(.noirSubtitle(15))
                    .foregroundColor(.noirText)

                Text(achievement.description)
                    .font(.noirCaption(11))
                    .foregroundColor(.noirMuted)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.noirSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            Color.noirGold.opacity(glowPulse ? 0.8 : 0.4),
                            lineWidth: 1.5
                        )
                )
                .shadow(
                    color: .noirGold.opacity(glowPulse ? 0.5 : 0.2),
                    radius: glowPulse ? 10 : 5
                )
        )
        .padding(.horizontal, 20)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}
