import SwiftUI

struct CaseCardView: View {
    let caseData: Case
    let isUnlocked: Bool
    let isCompleted: Bool
    var isPurchased: Bool = false
    let action: () -> Void

    @EnvironmentObject var loc: LocalizationManager
    @State private var appeared = false
    @State private var coverImage: UIImage? = nil
    @State private var shimmerPhase: CGFloat = 0

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottom) {
                // Kapak gorseli - sabit yukseklik
                coverImageSection

                // Alt gradient + bilgi katmani
                infoOverlay
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(cardBorderGradient, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 6, y: 4)
        }
        .buttonStyle(.plain)
        .opacity(isUnlocked ? 1.0 : 0.6)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
            if isUnlocked && !isCompleted {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: false)) {
                    shimmerPhase = 1.0
                }
            }
        }
        .scaleEffect(appeared ? 1.0 : 0.96)
        .opacity(appeared ? 1.0 : 0.0)
        .task {
            coverImage = await CaseLoader.loadBundleImageAsync(named: caseData.coverImage, caseId: caseData.id)
        }
    }

    // MARK: - Cover Image

    private var coverImageSection: some View {
        ZStack {
            if let coverImage = coverImage {
                GeometryReader { geo in
                    Image(uiImage: coverImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }

                // Shimmer - sadece acik ve cozulmemis
                if isUnlocked && !isCompleted {
                    GeometryReader { geo in
                        let width = geo.size.width
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.noirGold.opacity(0.06),
                                Color.noirGold.opacity(0.12),
                                Color.noirGold.opacity(0.06),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: width * 0.4)
                        .rotationEffect(.degrees(25))
                        .offset(x: -width * 0.4 + shimmerPhase * width * 1.4)
                    }
                    .clipped()
                    .allowsHitTesting(false)
                }
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.noirSurface, Color.noirPrimary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(.noirMuted.opacity(0.2))
                    )
            }
        }
    }

    // MARK: - Info Overlay

    private var infoOverlay: some View {
        VStack(spacing: 0) {
            // Ust kisim: badge'ler
            HStack(spacing: 6) {
                // Zorluk
                HStack(spacing: 2) {
                    ForEach(0..<caseData.difficulty, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.noirSecondary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.5))
                )

                Spacer()

                // Durum badge
                if !isUnlocked {
                    statusBadge(icon: "lock.fill", text: loc.s(.locked), color: .noirMuted)
                } else if isCompleted {
                    statusBadge(icon: "checkmark.seal.fill", text: loc.s(.solved), color: .noirSuccess)
                } else if caseData.isPremium && isPurchased {
                    statusBadge(icon: "checkmark.seal.fill", text: loc.s(.premium), color: .noirSuccess)
                } else if caseData.isPremium {
                    statusBadge(icon: "diamond.fill", text: "2 \(loc.s(.credit))", color: .noirCredit)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            Spacer()

            // Alt: gradient + bilgi
            VStack(alignment: .leading, spacing: 6) {
                // Sehir kutusu (yil kaldirildi)
                Text(cityOnly(from: caseData.subtitle).uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.noirSecondary)
                    .tracking(2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.55))
                            .overlay(
                                Capsule()
                                    .stroke(Color.noirSecondary.opacity(0.35), lineWidth: 0.5)
                            )
                    )

                Text(caseData.title)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)

                Text(caseData.description)
                    .font(.noirCaption(12))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
            .padding(.top, 30)
            .background(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.7),
                        Color.black.opacity(0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    // MARK: - Helpers

    /// Subtitle'dan yilin cikartilmis hali (virgulden onceki kisim veya rakamlar silinmis)
    private func cityOnly(from subtitle: String) -> String {
        if let commaIdx = subtitle.firstIndex(of: ",") {
            return String(subtitle[..<commaIdx]).trimmingCharacters(in: .whitespaces)
        }
        return subtitle.filter { !$0.isNumber }.trimmingCharacters(in: .whitespaces)
    }


    private func statusBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(text)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.5))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }

    private var cardBorderGradient: LinearGradient {
        if isCompleted {
            return LinearGradient(
                colors: [Color.noirSuccess.opacity(0.35), Color.noirSuccess.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if caseData.isPremium {
            return LinearGradient(
                colors: [Color.noirSecondary.opacity(0.35), Color.noirSecondary.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.white.opacity(0.1), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
