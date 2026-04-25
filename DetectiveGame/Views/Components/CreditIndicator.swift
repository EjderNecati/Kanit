import SwiftUI

struct CreditIndicator: View {
    @ObservedObject var playerProfile: PlayerProfile
    var showLabel: Bool = false
    @EnvironmentObject var loc: LocalizationManager

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "diamond.fill")
                .font(.system(size: 14))
                .foregroundColor(.noirCredit)

            Text("\(playerProfile.credits)")
                .font(.noirCaption(14))
                .foregroundColor(.noirText)
                .fontWeight(.bold)

            if showLabel {
                Text(loc.s(.credit))
                    .font(.noirCaption(12))
                    .foregroundColor(.noirMuted)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.noirPrimary.opacity(0.8))
                .overlay(
                    Capsule()
                        .stroke(Color.noirCredit.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

/// Seceneklerdeki kredi maliyeti gostergesi
struct CreditCostBadge: View {
    let cost: Int

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10))
            Text("\(cost)")
                .font(.noirCaption(12))
            Image(systemName: "diamond.fill")
                .font(.system(size: 10))
        }
        .foregroundColor(.noirCredit)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.noirCredit.opacity(0.15))
        )
    }
}
