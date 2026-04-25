import SwiftUI

struct CrossReferencePopup: View {
    let evidence1: Evidence
    let evidence2: Evidence
    @EnvironmentObject var loc: LocalizationManager
    @State private var glowPulse = false

    var body: some View {
        VStack(spacing: 8) {
            Text(loc.s(.connectionFound))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.noirSecondary)
                .tracking(1)

            HStack(spacing: 10) {
                // Delil 1
                VStack(spacing: 4) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(.noirSecondary)
                    Text(evidence1.title)
                        .font(.noirCaption(11))
                        .foregroundColor(.noirText)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                // Baglanti ikonu
                Image(systemName: "link")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.noirSecondary)

                // Delil 2
                VStack(spacing: 4) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(.noirSecondary)
                    Text(evidence2.title)
                        .font(.noirCaption(11))
                        .foregroundColor(.noirText)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.noirSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            Color.noirSecondary.opacity(glowPulse ? 0.7 : 0.4),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: .noirSecondary.opacity(glowPulse ? 0.4 : 0.15),
                    radius: glowPulse ? 8 : 4
                )
        )
        .padding(.horizontal, 20)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}
