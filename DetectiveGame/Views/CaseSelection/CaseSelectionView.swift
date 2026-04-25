import SwiftUI

struct CaseSelectionView: View {
    @ObservedObject var playerProfile: PlayerProfile
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var loc: LocalizationManager

    @State private var cases: [Case] = []
    @State private var headerAppeared = false
    @State private var showInsufficientCredits = false
    @State private var showTutorial = false
    @State private var pendingPurchaseCase: Case? = nil

    var body: some View {
        ZStack {
            // Arka plan
            PaperBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    // Baslik
                    headerSection

                    // Vaka kartlari — egitim ve diger vakalar ayri bolumlerde
                    VStack(spacing: 14) {
                        let trainingCases = cases.filter { $0.id == "istanbul-001" }
                        let otherCases = cases.filter { $0.id != "istanbul-001" }

                        if !trainingCases.isEmpty {
                            sectionLabel(
                                loc.language == .turkish ? "EĞİTİM" : "TRAINING",
                                icon: "graduationcap.fill"
                            )
                            .padding(.horizontal, 20)

                            ForEach(trainingCases, id: \.id) { caseData in
                                caseCard(caseData)
                                    .padding(.horizontal, 20)
                            }
                        }

                        if !trainingCases.isEmpty && !otherCases.isEmpty {
                            goldOrnamentalDivider(
                                loc.language == .turkish ? "VAKALAR" : "CASES"
                            )
                            .padding(.vertical, 8)
                        }

                        ForEach(otherCases, id: \.id) { caseData in
                            caseCard(caseData)
                                .padding(.horizontal, 20)
                        }
                    }

                    // Yakinda gelecek
                    comingSoonSection
                }
                .padding(.bottom, 60)
            }

            // Tutorial (ilk acilista)
            if showTutorial {
                TutorialOverlay(
                    steps: TutorialLibrary.caseSelectionSteps(lang: loc.language),
                    onFinish: {
                        TutorialFlags.markCaseSelectionSeen()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showTutorial = false
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    navigationPath.append(AppRoute.store)
                } label: {
                    CreditIndicator(playerProfile: playerProfile)
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            loadCases()
            withAnimation(.easeOut(duration: 0.8)) {
                headerAppeared = true
            }
            if !TutorialFlags.hasSeenCaseSelection {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showTutorial = true
                    }
                }
            }
        }
        .onChange(of: loc.language) { _ in
            loadCases()
        }
        .alert(
            loc.language == .turkish ? "Vakayı Aç" : "Unlock Case",
            isPresented: Binding(
                get: { pendingPurchaseCase != nil },
                set: { if !$0 { pendingPurchaseCase = nil } }
            )
        ) {
            Button(loc.language == .turkish ? "2 Kredi Harca ve Aç" : "Spend 2 Credits and Unlock") {
                if let c = pendingPurchaseCase {
                    if playerProfile.spendCredits(2) {
                        playerProfile.purchasePremiumCase(c.id)
                        SaveManager.savePlayerProfile(playerProfile)
                        navigationPath.append(AppRoute.caseIntro(c))
                    }
                    pendingPurchaseCase = nil
                }
            }
            Button(loc.s(.cancel), role: .cancel) {
                pendingPurchaseCase = nil
            }
        } message: {
            if let c = pendingPurchaseCase {
                Text(loc.language == .turkish
                     ? "\"\(c.title)\" vakasını açmak için 2 kredi harcanacak. Devam edilsin mi?"
                     : "Unlocking \"\(c.title)\" will cost 2 credits. Continue?")
            } else {
                Text("")
            }
        }
        .alert(loc.s(.insufficientTitle), isPresented: $showInsufficientCredits) {
            Button(loc.s(.goToStore)) {
                navigationPath.append(AppRoute.store)
            }
            Button(loc.s(.cancel), role: .cancel) {}
        } message: {
            Text(loc.language == .turkish
                 ? "Premium vakalar 2 kredi gerektirir."
                 : "Premium cases require 2 credits.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Dekoratif cizgi
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.noirSecondary)
                    .frame(width: 24, height: 2)
                Rectangle()
                    .fill(Color.noirSecondary.opacity(0.5))
                    .frame(width: 8, height: 2)
                Rectangle()
                    .fill(Color.noirSecondary.opacity(0.25))
                    .frame(width: 4, height: 2)
            }
            .opacity(headerAppeared ? 1 : 0)
            .offset(x: headerAppeared ? 0 : -20)

            Text(loc.s(.files))
                .font(.system(size: 36, weight: .bold, design: .serif))
                .foregroundColor(.noirText)
                .opacity(headerAppeared ? 1 : 0)
                .offset(y: headerAppeared ? 0 : 10)

            Text(loc.s(.selectCase))
                .font(.noirBody(15))
                .foregroundColor(.noirMuted)
                .opacity(headerAppeared ? 1 : 0)
                .offset(y: headerAppeared ? 0 : 10)

            // Istatistik satiri
            HStack(spacing: 16) {
                StatBadge(
                    icon: "folder.fill",
                    value: "\(cases.count)",
                    label: loc.s(.fileLabel)
                )
                StatBadge(
                    icon: "checkmark.seal.fill",
                    value: "\(playerProfile.completedCases.count)",
                    label: loc.s(.solved)
                )
                StatBadge(
                    icon: "lock.open.fill",
                    value: "\(playerProfile.unlockedCases.count)",
                    label: loc.s(.openLabel)
                )
            }
            .padding(.top, 8)
            .opacity(headerAppeared ? 1 : 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Case Card (ortak kullanim)

    @ViewBuilder
    private func caseCard(_ caseData: Case) -> some View {
        CaseCardView(
            caseData: caseData,
            isUnlocked: playerProfile.unlockedCases.contains(caseData.id),
            isCompleted: playerProfile.completedCases[caseData.id] != nil,
            isPurchased: playerProfile.hasPurchasedCase(caseData.id),
            action: {
                if playerProfile.unlockedCases.contains(caseData.id) {
                    if caseData.isPremium && !playerProfile.hasPurchasedCase(caseData.id) {
                        if !playerProfile.canAfford(2) {
                            showInsufficientCredits = true
                            return
                        }
                        pendingPurchaseCase = caseData
                        return
                    }
                    navigationPath.append(AppRoute.caseIntro(caseData))
                }
            }
        )
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        ))
    }

    // MARK: - Section Label (kucuk altin baslik)

    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.noirGold)

            Text(text)
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundColor(.noirGold)
                .tracking(3)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.noirGold.opacity(0.6), Color.noirGold.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
    }

    // MARK: - Altın Süslemeli Ayirici

    private func goldOrnamentalDivider(_ text: String) -> some View {
        HStack(spacing: 12) {
            // Sol cizgi (ortadan sola fade)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.noirGold.opacity(0), Color.noirGold.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Sol romb
            Image(systemName: "diamond.fill")
                .font(.system(size: 6))
                .foregroundColor(.noirGold.opacity(0.8))

            // Etiket
            Text(text)
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundColor(.noirGold)
                .tracking(4)
                .shadow(color: .black.opacity(0.5), radius: 2)

            // Sag romb
            Image(systemName: "diamond.fill")
                .font(.system(size: 6))
                .foregroundColor(.noirGold.opacity(0.8))

            // Sag cizgi
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.noirGold.opacity(0.7), Color.noirGold.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Coming Soon

    private var comingSoonSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.noirMuted.opacity(0.2))
                    .frame(height: 0.5)
                Image(systemName: "ellipsis")
                    .foregroundColor(.noirMuted.opacity(0.4))
                    .font(.system(size: 12))
                Rectangle()
                    .fill(Color.noirMuted.opacity(0.2))
                    .frame(height: 0.5)
            }
            .padding(.horizontal, 40)

            VStack(spacing: 8) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.noirSecondary.opacity(0.4))

                Text(loc.s(.comingSoon))
                    .font(.noirCaption(14))
                    .foregroundColor(.noirMuted.opacity(0.6))
                    .tracking(0.5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Load

    private func loadCases() {
        cases = CaseLoader.loadAllCases(language: loc.language)
        if cases.isEmpty {
            cases = [DemoCaseData.demoCase]
        }
    }
}

// MARK: - Stat Badge

private struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.noirSecondary)

            Text(value)
                .font(.noirCaption(13))
                .foregroundColor(.noirText)
                .fontWeight(.bold)

            Text(label)
                .font(.noirCaption(11))
                .foregroundColor(.noirMuted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.noirPrimary.opacity(0.6))
                .overlay(
                    Capsule()
                        .stroke(Color.noirSecondary.opacity(0.15), lineWidth: 0.5)
                )
        )
    }
}
