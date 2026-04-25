import SwiftUI

// MARK: - Navigation Routes

enum AppRoute: Hashable {
    case caseSelection
    case caseIntro(Case)
    case playCase(Case)
    case continueGame
    case store
    case ending(Ending, Case)

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        switch self {
        case .caseSelection: hasher.combine("caseSelection")
        case .caseIntro(let c): hasher.combine("caseIntro"); hasher.combine(c.id)
        case .playCase(let c): hasher.combine("playCase"); hasher.combine(c.id)
        case .continueGame: hasher.combine("continueGame")
        case .store: hasher.combine("store")
        case .ending(let e, let c): hasher.combine("ending"); hasher.combine(e.id); hasher.combine(c.id)
        }
    }

    static func == (lhs: AppRoute, rhs: AppRoute) -> Bool {
        switch (lhs, rhs) {
        case (.caseSelection, .caseSelection): return true
        case (.caseIntro(let a), .caseIntro(let b)): return a.id == b.id
        case (.playCase(let a), .playCase(let b)): return a.id == b.id
        case (.continueGame, .continueGame): return true
        case (.store, .store): return true
        case (.ending(let a1, let a2), .ending(let b1, let b2)): return a1.id == b1.id && a2.id == b2.id
        default: return false
        }
    }
}

// MARK: - Root Content View

struct ContentView: View {
    @StateObject private var playerProfile = SaveManager.loadPlayerProfile()
    @StateObject private var localization = LocalizationManager()
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            MainMenuView(playerProfile: playerProfile, navigationPath: $navigationPath)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .caseSelection:
                        CaseSelectionView(playerProfile: playerProfile, navigationPath: $navigationPath)

                    case .caseIntro(let caseData):
                        CaseIntroView(caseData: caseData, playerProfile: playerProfile, navigationPath: $navigationPath)

                    case .playCase(let caseData):
                        GameSessionView(
                            caseData: caseData,
                            playerProfile: playerProfile,
                            navigationPath: $navigationPath
                        )

                    case .continueGame:
                        if let saved = SaveManager.findAnySave(for: playerProfile.unlockedCases),
                           let caseData = CaseLoader.loadCase(id: saved.caseId, language: localization.language) {
                            GameSessionView(
                                caseData: caseData,
                                playerProfile: playerProfile,
                                navigationPath: $navigationPath,
                                savedState: saved.state
                            )
                        }

                    case .store:
                        StoreView(playerProfile: playerProfile)

                    case .ending(let ending, let caseData):
                        EndingView(
                            ending: ending,
                            caseData: caseData,
                            gameState: SaveManager.loadGameState(for: caseData.id),
                            playerProfile: playerProfile,
                            navigationPath: $navigationPath
                        )
                    }
                }
        }
        .environmentObject(localization)
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            SaveManager.savePlayerProfile(playerProfile)
        }
    }
}

// MARK: - Oyun Oturumu (StoryEngine yasam dongusu korumasi)

struct GameSessionView: View {
    let caseData: Case
    @ObservedObject var playerProfile: PlayerProfile
    @Binding var navigationPath: NavigationPath
    var savedState: GameState? = nil

    @StateObject private var storyEngine: StoryEngine

    init(caseData: Case, playerProfile: PlayerProfile, navigationPath: Binding<NavigationPath>, savedState: GameState? = nil) {
        self.caseData = caseData
        self.playerProfile = playerProfile
        self._navigationPath = navigationPath
        self.savedState = savedState
        self._storyEngine = StateObject(wrappedValue: StoryEngine(playerProfile: playerProfile))
    }

    var body: some View {
        StoryView(storyEngine: storyEngine, playerProfile: playerProfile, navigationPath: $navigationPath)
            .onAppear {
                guard storyEngine.currentCase == nil else { return }
                if let saved = savedState {
                    storyEngine.resumeCase(caseData, state: saved)
                } else if let existingSave = SaveManager.loadGameState(for: caseData.id) {
                    // Otomatik devam et: bu vaka icin kayit varsa kaldigi yerden devam
                    storyEngine.resumeCase(caseData, state: existingSave)
                } else {
                    storyEngine.startCase(caseData)
                }
            }
    }
}

// MARK: - Vaka Giris Ekrani

struct CaseIntroView: View {
    let caseData: Case
    let playerProfile: PlayerProfile
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var loc: LocalizationManager

    @State private var showTitle = false
    @State private var showDetails = false
    @State private var showButton = false
    @State private var coverImage: UIImage? = nil
    @State private var portraitImages: [String: UIImage] = [:]
    @State private var buttonGlow = false
    @State private var hasSave: Bool = false
    @State private var showRestartConfirm = false
    @State private var showInsufficientForRestart = false

    private var suspects: [Character] {
        caseData.characters.filter(\.isSuspect)
    }

    /// Vaka numarasi: "istanbul-001" -> "001"
    private var caseNumber: String {
        let parts = caseData.id.split(separator: "-")
        return parts.count > 1 ? String(parts.last!) : caseData.id
    }

    /// Subtitle'dan yili kaldir, sadece sehir
    private func cityOnly(from subtitle: String) -> String {
        if let commaIdx = subtitle.firstIndex(of: ",") {
            return String(subtitle[..<commaIdx]).trimmingCharacters(in: .whitespaces)
        }
        return subtitle.filter { !$0.isNumber }.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        ZStack {
            Color.noirBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 1. Kapak gorseli + overlay katmanlari
                    coverSection

                    // 2. Icerik
                    VStack(spacing: 0) {
                        // Sehir kutusu (dosya no ve yil kaldirildi)
                        Text(cityOnly(from: caseData.subtitle).uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.noirSecondary)
                            .tracking(2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.noirPrimary.opacity(0.7))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.noirSecondary.opacity(0.3), lineWidth: 0.5)
                                    )
                            )
                            .opacity(showTitle ? 1 : 0)
                            .offset(y: showTitle ? 0 : 10)

                        // Baslik
                        Text(caseData.title)
                            .font(.system(size: 34, weight: .bold, design: .serif))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color.noirText.opacity(0.9)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .multilineTextAlignment(.center)
                            .shadow(color: Color.noirSecondary.opacity(0.1), radius: 6, y: 2)
                            .padding(.top, 10)
                            .opacity(showTitle ? 1 : 0)
                            .offset(y: showTitle ? 0 : 14)

                        // Bilgi hapları: zorluk + supheli sayisi
                        HStack(spacing: 10) {
                            // Zorluk hapi
                            HStack(spacing: 3) {
                                ForEach(0..<5) { i in
                                    Image(systemName: i < caseData.difficulty ? "star.fill" : "star")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(i < caseData.difficulty ? .noirSecondary : .noirSecondary.opacity(0.25))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.noirPrimary.opacity(0.7))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.noirSecondary.opacity(0.15), lineWidth: 1)
                                    )
                            )

                            // Supheli hapi
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 10))
                                Text(loc.s(.suspectCount(suspects.count)))
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(.noirMuted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.noirPrimary.opacity(0.7))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.noirMuted.opacity(0.12), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.top, 16)
                        .opacity(showTitle ? 1 : 0)

                        // Dekoratif ayirici
                        CaseIntroDivider()
                            .padding(.top, 20)
                            .opacity(showDetails ? 1 : 0)

                        // Aciklama
                        Text(caseData.description)
                            .font(.noirBody(15))
                            .foregroundColor(.noirText.opacity(0.7))
                            .lineSpacing(5)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 18)
                            .opacity(showDetails ? 1 : 0)
                            .offset(y: showDetails ? 0 : 8)

                        // Dekoratif ayirici
                        CaseIntroDivider()
                            .padding(.top, 18)
                            .opacity(showDetails ? 1 : 0)

                        // Supheli portreleri
                        suspectPortraitsSection
                            .padding(.top, 18)
                            .opacity(showDetails ? 1 : 0)
                            .offset(y: showDetails ? 0 : 8)

                        // Baslat butonu
                        startButton
                            .padding(.top, 30)
                            .padding(.bottom, 44)
                            .opacity(showButton ? 1 : 0)
                            .offset(y: showButton ? 0 : 16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, -16)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            coverImage = await CaseLoader.loadBundleImageAsync(named: caseData.coverImage, caseId: caseData.id)
            await loadPortraits()
        }
        .onAppear {
            hasSave = SaveManager.hasSave(for: caseData.id)
            withAnimation(.easeOut(duration: 0.8).delay(0.15)) {
                showTitle = true
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.45)) {
                showDetails = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.75)) {
                showButton = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(1.2)) {
                buttonGlow = true
            }
        }
    }

    // MARK: - Kapak Gorseli

    private var coverSection: some View {
        ZStack(alignment: .topLeading) {
            if let coverImage = coverImage {
                Image(uiImage: coverImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .overlay(
                        // Sinematik overlay: vignette + alt fade
                        ZStack {
                            // Alt fade - noir arka plana gecis
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.15),
                                    Color.clear,
                                    Color.noirBackground.opacity(0.4),
                                    Color.noirBackground
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )

                            // Hafif soguk film tonu
                            Color(hex: "0A1628").opacity(0.12)
                        }
                    )
                    .overlay(alignment: .topTrailing) {
                        // GİZLİ / CLASSIFIED damga
                        Text(loc.s(.classified))
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.noirAccent.opacity(0.7))
                            .tracking(2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.noirAccent.opacity(0.5), lineWidth: 1)
                            )
                            .rotationEffect(.degrees(-5))
                            .padding(.top, 60)
                            .padding(.trailing, 20)
                    }
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.noirPrimary, Color.noirBackground],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .aspectRatio(16/9, contentMode: .fit)
            }
        }
    }

    // MARK: - Supheli Portreleri

    private var suspectPortraitsSection: some View {
        VStack(spacing: 12) {
            Text(loc.s(.suspectHeader))
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.noirSecondary.opacity(0.5))
                .tracking(3)

            // Yatay portre sirasi (isimli)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(suspects) { char in
                        VStack(spacing: 6) {
                            ZStack {
                                // Dis halka
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.noirSecondary.opacity(0.5), Color.noirSecondary.opacity(0.15)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1.5
                                    )
                                    .frame(width: 56, height: 56)

                                if let img = portraitImages[char.id] {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.noirSurface, Color.noirPrimary],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Text(String(char.name.prefix(1)).uppercased())
                                                .font(.system(size: 20, weight: .bold, design: .serif))
                                                .foregroundColor(.noirSecondary)
                                        )
                                }
                            }

                            Text(char.name.split(separator: " ").first.map(String.init) ?? char.name)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.noirMuted)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Baslat / Devam Butonu (+ Bastan Basla)

    private var startButton: some View {
        VStack(spacing: 10) {
            Button(action: {
                navigationPath.append(AppRoute.playCase(caseData))
            }) {
                HStack(spacing: 10) {
                    Image(systemName: hasSave ? "play.fill" : "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                    Text(hasSave ? loc.s(.continueInvestigation) : loc.s(.startInvestigation))
                        .font(.system(size: 17, weight: .bold, design: .serif))
                }
                .foregroundColor(.noirText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.noirSecondary.opacity(0.4), Color.noirSecondary.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    Color.noirSecondary.opacity(buttonGlow ? 0.6 : 0.35),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: Color.noirSecondary.opacity(buttonGlow ? 0.35 : 0.15),
                            radius: buttonGlow ? 8 : 4,
                            y: 3
                        )
                )
            }
            .buttonStyle(.plain)

            // Bastan basla (sadece kayit varsa)
            if hasSave {
                Button(action: {
                    if playerProfile.credits >= 1 {
                        showRestartConfirm = true
                    } else {
                        showInsufficientForRestart = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 13, weight: .semibold))
                        Text(loc.s(.startOver))
                            .font(.system(size: 14, weight: .semibold, design: .serif))
                        Spacer()
                        HStack(spacing: 4) {
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
                    .foregroundColor(.noirMuted)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.noirPrimary.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.noirMuted.opacity(0.15), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .alert(loc.s(.restartConfirmTitle), isPresented: $showRestartConfirm) {
            Button(loc.s(.yesRestart), role: .destructive) {
                performRestartFromIntro()
            }
            Button(loc.s(.cancel), role: .cancel) {}
        } message: {
            Text(loc.s(.restartConfirmMsg))
        }
        .alert(loc.s(.insufficientTitle), isPresented: $showInsufficientForRestart) {
            Button(loc.s(.goToStore)) {
                navigationPath.append(AppRoute.store)
            }
            Button(loc.s(.cancel), role: .cancel) {}
        } message: {
            Text(loc.s(.insufficientMsg))
        }
    }

    private func performRestartFromIntro() {
        guard playerProfile.spendCredits(1) else {
            showInsufficientForRestart = true
            return
        }
        SaveManager.savePlayerProfile(playerProfile)
        SaveManager.deleteSave(for: caseData.id)
        hasSave = false
        navigationPath.append(AppRoute.playCase(caseData))
    }

    // MARK: - Portre yukleyici

    private func loadPortraits() async {
        await withTaskGroup(of: (String, UIImage?).self) { group in
            for char in suspects where portraitImages[char.id] == nil {
                let charId = char.id
                let imageName = char.portraitImage
                let caseId = caseData.id
                group.addTask {
                    let img = await CaseLoader.loadBundleImageAsync(named: imageName, caseId: caseId)
                    return (charId, img)
                }
            }
            for await (charId, img) in group {
                portraitImages[charId] = img
            }
        }
    }
}

// MARK: - Dekoratif Ayirici Cizgi

private struct CaseIntroDivider: View {
    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.noirSecondary.opacity(0.25)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)

            Image(systemName: "diamond.fill")
                .font(.system(size: 5))
                .foregroundColor(.noirSecondary.opacity(0.35))

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.noirSecondary.opacity(0.25), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
        }
        .padding(.horizontal, 36)
    }
}
