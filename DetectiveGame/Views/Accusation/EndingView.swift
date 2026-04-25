import SwiftUI

struct EndingView: View {
    let ending: Ending
    let caseData: Case
    let gameState: GameState?
    let playerProfile: PlayerProfile
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var loc: LocalizationManager

    @State private var showContent = false
    @State private var showStamp = false
    @State private var showStats = false
    @State private var starScales: [CGFloat] = [0, 0, 0]
    @State private var showPlayAgainConfirm = false
    @State private var showBackConfirm = false
    @State private var showInsufficientCredits = false

    private var clampedStars: Int { max(0, min(3, ending.starsEarned)) }

    var body: some View {
        ZStack {
            PaperBackground()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 60)

                    // Sonuc damgasi
                    if showStamp {
                        if ending.isCorrect {
                            CaseStamp(type: .solved)
                        } else {
                            StampBadge(text: loc.s(.failed), color: .noirAccent)
                        }
                    }

                    // Yildizlar - staggered animasyon
                    if showContent {
                        HStack(spacing: 8) {
                            ForEach(0..<3) { i in
                                let isFilled = i < clampedStars
                                Image(systemName: isFilled ? "star.fill" : "star")
                                    .font(.system(size: 32))
                                    .foregroundColor(isFilled ? .noirGold : .noirMuted.opacity(0.3))
                                    .shadow(
                                        color: isFilled ? Color.noirGold.opacity(0.5) : .clear,
                                        radius: 4
                                    )
                                    .scaleEffect(starScales[i])
                            }
                        }
                        .padding(.top, 16)
                    }

                    // Baslik
                    if showContent {
                        VStack(spacing: 8) {
                            Text(ending.title)
                                .font(.noirTitle(28))
                                .foregroundColor(.noirText)
                                .multilineTextAlignment(.center)

                            Text(ending.description)
                                .font(.noirBody(16))
                                .foregroundColor(.noirMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }

                    // Epilog
                    if showContent {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(loc.s(.epilogue))
                                .font(.noirSubtitle(16))
                                .foregroundColor(.noirSecondary)

                            Text(ending.epilogueText)
                                .font(.noirBody(15))
                                .foregroundColor(.noirText)
                                .lineSpacing(4)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.noirPrimary.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.noirSecondary.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                    }

                    // Istatistikler
                    if showStats, let gameState = gameState {
                        VStack(spacing: 12) {
                            StatRow(
                                label: loc.s(.collectedEvidence),
                                value: "\(gameState.collectedEvidence.count)"
                            )
                            StatRow(
                                label: loc.s(.visitedScenes),
                                value: "\(gameState.visitedScenes.count)/\(caseData.scenes.count)"
                            )
                            StatRow(
                                label: loc.s(.choicesMade),
                                value: "\(gameState.choiceHistory.count)"
                            )
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.noirPrimary.opacity(0.4))
                        )
                        .padding(.horizontal, 20)
                    }

                    // Butonlar
                    if showStats {
                        VStack(spacing: 12) {
                            // Tekrar Oyna (1 kredi)
                            Button(action: {
                                if playerProfile.credits >= 1 {
                                    showPlayAgainConfirm = true
                                } else {
                                    showInsufficientCredits = true
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text(loc.s(.playAgain))
                                        .font(.noirSubtitle(18))
                                    Spacer()
                                    HStack(spacing: 3) {
                                        Image(systemName: "diamond.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.noirCredit)
                                        Text("1")
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(.noirCredit)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(Color.noirCredit.opacity(0.12))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.noirCredit.opacity(0.3), lineWidth: 0.5)
                                            )
                                    )
                                }
                                .foregroundColor(.noirText)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.noirSecondary.opacity(0.3))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.noirSecondary.opacity(0.4), lineWidth: 1)
                                        )
                                )
                            }

                            // Suclama Ekranina Geri Don - sadece yanlis bilince gozuksun (2 kredi)
                            if !ending.isCorrect {
                                Button(action: {
                                    if playerProfile.credits >= 2 {
                                        showBackConfirm = true
                                    } else {
                                        showInsufficientCredits = true
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 13, weight: .semibold))
                                        Text(loc.s(.backToAccusation))
                                            .font(.system(size: 15, weight: .semibold, design: .serif))
                                        Spacer()
                                        HStack(spacing: 3) {
                                            Image(systemName: "diamond.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(.noirCredit)
                                            Text("2")
                                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                .foregroundColor(.noirCredit)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule()
                                                .fill(Color.noirCredit.opacity(0.12))
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color.noirCredit.opacity(0.3), lineWidth: 0.5)
                                                )
                                        )
                                    }
                                    .foregroundColor(.noirMuted)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.noirPrimary.opacity(0.5))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.noirMuted.opacity(0.2), lineWidth: 0.5)
                                            )
                                    )
                                }
                            }

                            // Ana Menu
                            Button(action: {
                                navigationPath = NavigationPath()
                                navigationPath.append(AppRoute.caseSelection)
                            }) {
                                Text(loc.s(.mainMenu))
                                    .font(.noirSubtitle(18))
                                    .foregroundColor(.noirMuted)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            animateEntrance()
        }
        .alert(loc.s(.playAgainConfirmTitle), isPresented: $showPlayAgainConfirm) {
            Button(loc.s(.yesPlayAgain), role: .destructive) {
                performPlayAgain()
            }
            Button(loc.s(.cancel), role: .cancel) {}
        } message: {
            Text(loc.s(.playAgainConfirmMsg))
        }
        .alert(loc.s(.backToAccusationConfirmTitle), isPresented: $showBackConfirm) {
            Button(loc.s(.yesGoBack)) {
                goBackToAccusation()
            }
            Button(loc.s(.cancel), role: .cancel) {}
        } message: {
            Text(loc.s(.backToAccusationConfirmMsg))
        }
        .alert(loc.s(.insufficientTitle), isPresented: $showInsufficientCredits) {
            Button(loc.s(.goToStore)) {
                navigationPath.append(AppRoute.store)
            }
            Button(loc.s(.cancel), role: .cancel) {}
        } message: {
            Text(loc.s(.insufficientMsg))
        }
    }

    private func animateEntrance() {
        withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
            showStamp = true
        }
        withAnimation(.easeOut(duration: 0.6).delay(1.2)) {
            showContent = true
        }
        // Yildiz staggered animasyonu
        for i in 0..<3 {
            let delay = 1.5 + Double(i) * 0.3
            let isFilled = i < clampedStars
            withAnimation(
                isFilled
                    ? .spring(response: 0.4, dampingFraction: 0.5).delay(delay)
                    : .easeOut(duration: 0.3).delay(delay)
            ) {
                starScales[i] = 1.0
            }
        }
        withAnimation(.easeOut(duration: 0.6).delay(2.8)) {
            showStats = true
        }
    }

    // MARK: - Tekrar Oyna (1 kredi)
    private func performPlayAgain() {
        guard playerProfile.spendCredits(1) else {
            showInsufficientCredits = true
            return
        }
        // Vakayi temiz sayfadan baslatmak icin ilerleme kayitlarini temizle
        playerProfile.completedCases.removeValue(forKey: caseData.id)
        playerProfile.accusationHistory.removeValue(forKey: caseData.id)
        SaveManager.savePlayerProfile(playerProfile)
        SaveManager.deleteSave(for: caseData.id)

        // Navigation'i sifirla ve vakayi yeniden baslat
        // Daha uzun delay: eski GameSessionView tamamen dismount olsun
        navigationPath = NavigationPath()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            navigationPath.append(AppRoute.playCase(caseData))
        }
    }

    // MARK: - Suclama Ekranina Geri Don (2 kredi, ilerleme silinmez)
    private func goBackToAccusation() {
        guard playerProfile.spendCredits(2) else {
            showInsufficientCredits = true
            return
        }
        SaveManager.savePlayerProfile(playerProfile)
        // Ending view'i pop et - altinda duran StoryView'in AccusationView'i tekrar gorunecek
        // (currentScene = scene_accusation'da kaldi)
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.noirBody(15))
                .foregroundColor(.noirMuted)

            Spacer()

            Text(value)
                .font(.noirSubtitle(16))
                .foregroundColor(.noirText)
        }
    }
}
