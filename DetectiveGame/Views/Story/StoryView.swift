import SwiftUI

struct StoryView: View {
    @ObservedObject var storyEngine: StoryEngine
    @ObservedObject var playerProfile: PlayerProfile
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var loc: LocalizationManager

    @State private var showEvidenceGallery = false
    @State private var showSuspectList = false
    @State private var showMenu = false
    @State private var showHQ = false
    @State private var showPressEvent = false
    @State private var showNotes = false
    @State private var showHowToPlay = false
    @State private var showRestartConfirm = false
    @State private var showInsufficientForRestart = false
    @State private var showTutorial = false
    @State private var locationBadgeName: String? = nil

    /// Ilk sahneden sonra HQ butonu goster (accusation/ending haric)
    private var shouldShowHQButton: Bool {
        guard let state = storyEngine.gameState,
              let sceneType = storyEngine.currentScene?.type else { return false }
        return state.visitedScenes.count >= 1
            && sceneType != .accusation
            && sceneType != .ending
    }

    var body: some View {
        ZStack {
            // Temel arka plan (her zaman mevcut - siyah ekran onlenir)
            Color.noirBackground.ignoresSafeArea()

            // Ana sahne
            if let scene = storyEngine.currentScene, let currentCase = storyEngine.currentCase {
                sceneView(scene: scene, currentCase: currentCase)
                    .id(scene.id)
                    .transition(.opacity)
            }

            // Lokasyon badge
            if let name = locationBadgeName {
                VStack {
                    LocationBadgeView(locationName: name)
                        .padding(.top, 60)
                    Spacer()
                }
                .zIndex(9)
                .allowsHitTesting(false)
            }

            // Flashback VHS efekti
            if storyEngine.currentScene?.type == .flashback {
                VHSOverlay()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .zIndex(8)
            }

            // Yeni delil bildirimi
            if let evidence = storyEngine.newEvidenceFound {
                VStack {
                    EvidencePopup(evidence: evidence)
                        .transition(.slideUp)
                    Spacer()
                }
                .padding(.top, 60)
                .zIndex(10)
            }

            // Achievement toast
            if let achievement = storyEngine.currentAchievement {
                VStack {
                    Spacer()
                    AchievementToastView(achievement: achievement)
                        .transition(.slideUp)
                    Spacer().frame(height: 100)
                }
                .zIndex(11)
            }

            // Alt toolbar (her zaman mevcut, opacity ile gizle - layout thrashing onlenir)
            VStack {
                Spacer()
                GameToolbar(
                    evidenceCount: storyEngine.gameState?.collectedEvidence.count ?? 0,
                    evidenceLabel: loc.s(.evidenceLabel),
                    suspectsLabel: loc.s(.suspectsLabel),
                    notesLabel: loc.s(.myNotes),
                    storeLabel: loc.s(.store),
                    menuLabel: loc.s(.menu),
                    onEvidence: { showEvidenceGallery = true },
                    onSuspects: { showSuspectList = true },
                    onNotes: { showNotes = true },
                    onStore: {
                        if let gameState = storyEngine.gameState {
                            SaveManager.saveGameState(gameState)
                        }
                        navigationPath.append(AppRoute.store)
                    },
                    onMenu: { showMenu = true }
                )
            }
            .zIndex(5)
            .opacity(storyEngine.currentScene?.type != .ending && storyEngine.currentScene?.type != .accusation ? 1 : 0)
            .allowsHitTesting(storyEngine.currentScene?.type != .ending && storyEngine.currentScene?.type != .accusation)

            // Oyun ici tutorial (ilk vakada)
            if showTutorial {
                TutorialOverlay(
                    steps: TutorialLibrary.gameSteps(lang: loc.language),
                    onFinish: {
                        TutorialFlags.markGameSeen()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showTutorial = false
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .onAppear {
            if !TutorialFlags.hasSeenGame {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showTutorial = true
                    }
                }
            }
        }
        .sheet(isPresented: $showEvidenceGallery) {
            if let currentCase = storyEngine.currentCase, let gameState = storyEngine.gameState {
                EvidenceGalleryView(caseData: currentCase, gameState: gameState)
            }
        }
        .sheet(isPresented: $showSuspectList) {
            if let currentCase = storyEngine.currentCase, let gameState = storyEngine.gameState {
                SuspectListView(caseData: currentCase, gameState: gameState)
            }
        }
        .sheet(isPresented: $showHQ) {
            if let currentCase = storyEngine.currentCase, let gameState = storyEngine.gameState {
                HeadquartersView(
                    caseData: currentCase,
                    gameState: gameState,
                    playerProfile: playerProfile,
                    onAccuse: {
                        // HQ'dan suclama sahnesine git
                        storyEngine.goToScene("scene_accusation")
                    },
                    onNavigateToScene: { sceneId in
                        // HQ'dan sahneye git - karakter exhaustion dahil tum mantik StoryEngine'de
                        storyEngine.navigateFromHQ(to: sceneId)
                    }
                )
            }
        }
        .alert(loc.s(.insufficientTitle), isPresented: $storyEngine.showInsufficientCredits) {
            Button(loc.s(.goToStore)) {
                if let gameState = storyEngine.gameState {
                    SaveManager.saveGameState(gameState)
                }
                navigationPath.append(AppRoute.store)
            }
            Button(loc.s(.cancel), role: .cancel) {}
        } message: {
            Text(loc.s(.insufficientMsg))
        }
        .sheet(isPresented: $showMenu) {
            GameMenuSheet(
                onHowToPlay: {
                    showMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showHowToPlay = true
                    }
                },
                onRestart: {
                    showMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if playerProfile.credits >= 1 {
                            showRestartConfirm = true
                        } else {
                            showInsufficientForRestart = true
                        }
                    }
                },
                onSaveAndExit: {
                    if let gameState = storyEngine.gameState {
                        SaveManager.saveGameState(gameState)
                    }
                    SaveManager.savePlayerProfile(playerProfile)
                    showMenu = false
                    navigationPath = NavigationPath()
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showHowToPlay) {
            HowToPlaySheet()
        }
        .alert(loc.s(.restartConfirmTitle), isPresented: $showRestartConfirm) {
            Button(loc.s(.yesRestart), role: .destructive) {
                performRestart()
            }
            Button(loc.s(.cancel), role: .cancel) {}
        } message: {
            Text(loc.s(.restartConfirmMsg))
        }
        .alert(loc.s(.insufficientTitle), isPresented: $showInsufficientForRestart) {
            Button(loc.s(.goToStore)) {
                if let gameState = storyEngine.gameState {
                    SaveManager.saveGameState(gameState)
                }
                navigationPath.append(AppRoute.store)
            }
            Button(loc.s(.cancel), role: .cancel) {}
        } message: {
            Text(loc.s(.insufficientMsg))
        }
        .sheet(isPresented: $showNotes) {
            if let gameState = storyEngine.gameState {
                PlayerNotesView(gameState: gameState, currentSceneId: storyEngine.currentScene?.id)
            }
        }
        .sheet(isPresented: $showPressEvent) {
            if let event = storyEngine.pendingPressEvent {
                PressEventSheet(event: event) { choiceIndex in
                    storyEngine.answerPress(eventId: event.id, choiceIndex: choiceIndex)
                }
            }
        }
        .onChange(of: storyEngine.pendingPressEvent?.id) { newId in
            showPressEvent = newId != nil
        }
        .onChange(of: storyEngine.currentScene?.id) { _ in
            // Lokasyon badge goster
            if let scene = storyEngine.currentScene, let currentCase = storyEngine.currentCase,
               let locations = currentCase.hqLocations,
               let loc = locations.first(where: { $0.sceneId == scene.id }) {
                locationBadgeName = loc.label
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    locationBadgeName = nil
                }
            } else {
                locationBadgeName = nil
            }
        }
        // time-expired mekanigi devre disi: vakalarda zaman baskisi kaldirildi
    }

    // MARK: - Restart
    private func performRestart() {
        guard playerProfile.spendCredits(1) else {
            showInsufficientForRestart = true
            return
        }
        SaveManager.savePlayerProfile(playerProfile)
        if let currentCase = storyEngine.currentCase {
            SaveManager.deleteSave(for: currentCase.id)
            storyEngine.startCase(currentCase)
        }
    }

    // MARK: - Scene View Builder

    @ViewBuilder
    private func sceneView(scene: GameScene, currentCase: Case) -> some View {
        switch scene.type {
        case .narration, .investigation, .flashback:
            NarrationView(
                scene: scene,
                caseId: currentCase.id,
                choices: storyEngine.getAvailableChoices(),
                canAffordChoice: { storyEngine.canAffordChoice($0) },
                onChoice: { storyEngine.makeChoice($0) },
                showHQButton: shouldShowHQButton,
                onReturnToHQ: { showHQ = true }
            )
        case .dialogue:
            dialogueSceneView(scene: scene, currentCase: currentCase)
        case .accusation:
            AccusationView(
                storyEngine: storyEngine,
                playerProfile: playerProfile,
                navigationPath: $navigationPath
            )
        case .ending:
            if let ending = currentCase.endings.first(where: { $0.id == scene.id }) {
                EndingView(
                    ending: ending,
                    caseData: currentCase,
                    gameState: storyEngine.gameState,
                    playerProfile: playerProfile,
                    navigationPath: $navigationPath
                )
            }
        }
    }

    @ViewBuilder
    private func dialogueSceneView(scene: GameScene, currentCase: Case) -> some View {
        let character = scene.characterId.flatMap { storyEngine.findCharacter(id: $0) }
        DialogueView(
            scene: scene,
            character: character,
            caseId: currentCase.id,
            choices: storyEngine.getAvailableChoices(),
            canAffordChoice: { storyEngine.canAffordChoice($0) },
            onChoice: { storyEngine.makeChoice($0) },
            showHQButton: shouldShowHQButton,
            onReturnToHQ: { showHQ = true },
            revisitMessage: storyEngine.revisitMessage
        )
    }
}

// MARK: - Alt Toolbar

struct GameToolbar: View {
    let evidenceCount: Int
    let evidenceLabel: String
    let suspectsLabel: String
    let notesLabel: String
    let storeLabel: String
    let menuLabel: String
    let onEvidence: () -> Void
    let onSuspects: () -> Void
    let onNotes: () -> Void
    let onStore: () -> Void
    let onMenu: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Deliller
            ToolbarButton(icon: "doc.text.magnifyingglass", label: evidenceLabel, badge: evidenceCount) {
                onEvidence()
            }

            Spacer()

            // Supheliler
            ToolbarButton(icon: "person.2.fill", label: suspectsLabel, badge: nil) {
                onSuspects()
            }

            Spacer()

            // Notlar
            ToolbarButton(icon: "note.text", label: notesLabel, badge: nil) {
                onNotes()
            }

            Spacer()

            // Magaza
            ToolbarButton(icon: "bag.fill", label: storeLabel, badge: nil) {
                onStore()
            }

            Spacer()

            // Menu
            ToolbarButton(icon: "line.3.horizontal", label: menuLabel, badge: nil) {
                onMenu()
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 10)
        .padding(.bottom, 10)
        .background(
            ZStack {
                // Glass morphism: material + koyu overlay
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .padding(.top, -20)

                Color.noirBackground.opacity(0.6)
                    .padding(.top, -20)
            }
        )
        .overlay(alignment: .top) {
            // Ust kenar separator
            Rectangle()
                .fill(Color.noirSecondary.opacity(0.12))
                .frame(height: 0.5)
        }
    }
}

// Toolbar icin hafif kredi gostergesi (ObservedObject yok)
struct CreditIndicatorSimple: View {
    let credits: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "diamond.fill")
                .font(.system(size: 14))
                .foregroundColor(.noirCredit)
            Text("\(credits)")
                .font(.noirCaption(14))
                .foregroundColor(.noirText)
                .fontWeight(.bold)
        }
    }
}

struct ToolbarButton: View {
    let icon: String
    let label: String
    let badge: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.noirSecondary)

                    if let badge = badge, badge > 0 {
                        Text("\(badge)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(Circle().fill(Color.noirAccent))
                            .offset(x: 8, y: -6)
                    }
                }

                Text(label)
                    .font(.noirCaption(10))
                    .foregroundColor(.noirMuted)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Delil Popup Bildirimi

struct EvidencePopup: View {
    let evidence: Evidence
    @EnvironmentObject var loc: LocalizationManager
    @State private var glowPulse = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 24))
                .foregroundColor(.noirGold)

            VStack(alignment: .leading, spacing: 2) {
                Text(loc.s(.newEvidence))
                    .font(.noirCaption(12))
                    .foregroundColor(.noirGold)

                Text(evidence.title)
                    .font(.noirSubtitle(16))
                    .foregroundColor(.noirText)
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
                            Color.noirGold.opacity(glowPulse ? 0.7 : 0.4),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: .noirGold.opacity(glowPulse ? 0.4 : 0.15),
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

// MARK: - VHS Overlay (Flashback efekti)

struct VHSOverlay: View {
    @State private var scanlineOffset: CGFloat = -200

    var body: some View {
        ZStack {
            // Sepia tonu
            Color(red: 0.55, green: 0.43, blue: 0.3)
                .opacity(0.15)

            // Scanlines
            GeometryReader { geo in
                VStack(spacing: 2) {
                    ForEach(0..<Int(geo.size.height / 4), id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.03))
                            .frame(height: 1)
                        Spacer().frame(height: 3)
                    }
                }
            }

            // Moving scan bar
            GeometryReader { geo in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.06), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 60)
                    .offset(y: scanlineOffset)
                    .onAppear {
                        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                            scanlineOffset = geo.size.height + 60
                        }
                    }
            }

            // "FLASHBACK" label
            VStack {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("FLASHBACK")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(4)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()
            }
        }
    }
}

// MARK: - Oyun Menusu Sheet (noir stili)

struct GameMenuSheet: View {
    let onHowToPlay: () -> Void
    let onRestart: () -> Void
    let onSaveAndExit: () -> Void

    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.noirBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Baslik
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(Color.noirSecondary.opacity(0.6))
                            .frame(width: 20, height: 1)
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 12))
                            .foregroundColor(.noirSecondary.opacity(0.7))
                        Rectangle()
                            .fill(Color.noirSecondary.opacity(0.6))
                            .frame(width: 20, height: 1)
                    }
                    Text(loc.s(.gameMenu))
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(.noirText)
                        .tracking(3)
                }
                .padding(.top, 20)
                .padding(.bottom, 24)

                VStack(spacing: 12) {
                    MenuRow(
                        icon: "book.fill",
                        title: loc.s(.howToPlay),
                        accent: .noirSecondary,
                        action: onHowToPlay
                    )

                    MenuRow(
                        icon: "arrow.counterclockwise.circle.fill",
                        title: loc.s(.restartCase),
                        accent: .noirAccent,
                        trailing: {
                            HStack(spacing: 4) {
                                Image(systemName: "diamond.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.noirCredit)
                                Text("1")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.noirCredit)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.noirCredit.opacity(0.12))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.noirCredit.opacity(0.3), lineWidth: 0.5)
                                    )
                            )
                        },
                        action: onRestart
                    )

                    MenuRow(
                        icon: "arrow.left.square.fill",
                        title: loc.s(.saveAndExit),
                        accent: .noirSuccess,
                        action: onSaveAndExit
                    )
                }
                .padding(.horizontal, 20)

                Spacer()

                Button(action: { dismiss() }) {
                    Text(loc.s(.cancel))
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .foregroundColor(.noirMuted)
                        .padding(.vertical, 10)
                }
                .padding(.bottom, 20)
            }
        }
    }
}

private struct MenuRow<Trailing: View>: View {
    let icon: String
    let title: String
    let accent: Color
    @ViewBuilder var trailing: () -> Trailing
    let action: () -> Void

    init(
        icon: String,
        title: String,
        accent: Color,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() },
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.accent = accent
        self.trailing = trailing
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.9), accent.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3)
                    .padding(.vertical, 8)

                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(accent)
                        .frame(width: 24)

                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundColor(.noirText)

                    Spacer()

                    trailing()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.noirMuted.opacity(0.5))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.noirPrimary.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(accent.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Nasil Oynanir Sheet

struct HowToPlaySheet: View {
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.noirBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Dekoratif baslik bloklari
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 22))
                                .foregroundColor(.noirSecondary)
                            Text(loc.s(.howToPlay))
                                .font(.system(size: 28, weight: .bold, design: .serif))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.noirText, Color.noirSecondary],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .tracking(2)
                        }
                        .padding(.top, 8)

                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.noirSecondary.opacity(0.7), Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)

                        // Icerik bloklari (ikili baslik-paragraf)
                        ForEach(parsedSections(), id: \.heading) { section in
                            HowToPlayBlock(heading: section.heading, text: section.text)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.noirMuted.opacity(0.6))
                    }
                }
            }
            .toolbarBackground(Color.noirBackground.opacity(0.9), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private func parsedSections() -> [(heading: String, text: String)] {
        let raw = loc.s(.howToPlayContent)
        let blocks = raw.components(separatedBy: "\n\n")
        return blocks.compactMap { block -> (heading: String, text: String)? in
            let lines = block.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
            guard lines.count == 2 else {
                if let line = lines.first, !line.isEmpty {
                    return (heading: "", text: line)
                }
                return nil
            }
            return (heading: lines[0], text: lines[1])
        }
    }
}

private struct HowToPlayBlock: View {
    let heading: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !heading.isEmpty {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.noirSecondary)
                        .frame(width: 5, height: 5)
                    Text(heading)
                        .font(.system(size: 13, weight: .bold, design: .serif))
                        .foregroundColor(.noirSecondary)
                        .tracking(3)
                }
            }
            Text(text)
                .font(.noirBody(14))
                .foregroundColor(.noirText.opacity(0.85))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.noirPrimary.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.noirSecondary.opacity(0.12), lineWidth: 1)
                )
        )
    }
}
