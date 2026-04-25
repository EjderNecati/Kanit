import SwiftUI

struct HeadquartersView: View {
    let caseData: Case
    let gameState: GameState
    var playerProfile: PlayerProfile? = nil
    var onAccuse: (() -> Void)? = nil
    var onNavigateToScene: ((String) -> Void)? = nil
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @State private var portraitImages: [String: UIImage] = [:]
    @State private var coverImage: UIImage? = nil
    @State private var selectedCharacter: Character? = nil
    @State private var expandedEvidenceId: String? = nil
    @State private var showPhone = false
    @State private var showCamera = false
    @State private var showLab = false
    @State private var showNewspaper = false
    @State private var showNetwork = false
    @State private var showInsufficientCredits = false
    @State private var showCrossReference = false
    @State private var pendingSceneId: String? = nil

    private var canAccuse: Bool {
        gameState.collectedEvidence.count >= 5
    }

    private var collectedEvidenceItems: [Evidence] {
        gameState.collectedEvidence.compactMap { evidenceId in
            caseData.evidence.first { $0.id == evidenceId }
        }
    }

    private var suspects: [Character] {
        caseData.characters.filter(\.isSuspect)
    }

    /// Web oyunundaki gibi ilerlemeye gore partner ipucu
    private var partnerHint: String {
        let evCount = gameState.collectedEvidence.count
        let totalEvidence = caseData.evidence.count
        if evCount == 0 { return loc.s(.partnerHint0) }
        if evCount < 3 { return loc.s(.partnerHint1) }
        if evCount < totalEvidence / 2 { return loc.s(.partnerHint2) }
        return loc.s(.partnerHint3)
    }

    /// Ayni supheliye bagli birden fazla delil = cross-reference
    private var crossReferenceCount: Int {
        var charEvidenceCount: [String: Int] = [:]
        for ev in collectedEvidenceItems {
            if let charId = ev.linkedCharacterId {
                charEvidenceCount[charId, default: 0] += 1
            }
        }
        return charEvidenceCount.values.filter { $0 > 1 }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.noirBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 1. Header: Gorsel + Vaka bilgisi
                        headerSection

                        // Icerik
                        VStack(spacing: 16) {
                            // 2. Partner ipucu (web: hq-partner)
                            partnerSection

                            // 2.5. Itibar + Zaman gostergesi
                            reputationAndTimeSection

                            // 3. Durum ozeti
                            statusSection

                            // 5. Supheliler - liste (web: hqActions)
                            suspectsSection

                            // 6. Sorusturma lokasyonlari (web: hqLocations)
                            if let locations = caseData.hqLocations, !locations.isEmpty {
                                locationsSection(locations)
                            }

                            // 7. Sorusturma Araclari (telefon, kamera, vb.)
                            if hasAnyTools {
                                toolsSection
                            }

                            // 8. Flashback'ler
                            if let triggers = caseData.flashbackTriggers, !triggers.isEmpty {
                                flashbackSection(triggers)
                            }

                            // 9. Suclama butonu (web: hq-accuse-btn, 5+ delil)
                            accusationSection

                            // 9. Devam butonu
                            continueButton
                                .padding(.bottom, 30)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
                .clipped()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(loc.s(.headquarters))
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundColor(.noirText)
                }
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
        .onDisappear {
            // Sheet gercekten kapandiktan sonra navigasyonu yap.
            // 0.3s asyncAfter race'inin yerine: sabit delay yerine sheet'in
            // kendi dismiss sinyalini kullaniyoruz, boylece hizli tekrar tap
            // edildiginde eski navigasyon yanlis sira ile firmiyor.
            if let sceneId = pendingSceneId {
                pendingSceneId = nil
                onNavigateToScene?(sceneId)
            }
        }
        .sheet(item: $selectedCharacter) { character in
            SuspectProfileView(
                character: character,
                caseId: caseData.id,
                notes: gameState.characterNotes[character.id] ?? []
            )
        }
        .sheet(isPresented: $showPhone) {
            if let phoneData = caseData.phoneData {
                PhoneModalView(phoneData: phoneData, caseId: caseData.id)
            }
        }
        .sheet(isPresented: $showCamera) {
            if let cameraData = caseData.cameraData {
                CameraTimelineView(cameraData: cameraData)
            }
        }
        .sheet(isPresented: $showLab) {
            if let labAnalyses = caseData.labAnalyses {
                LabAnalysisView(labAnalyses: labAnalyses, gameState: gameState)
            }
        }
        .sheet(isPresented: $showNewspaper) {
            if let articles = caseData.newspaperArticles {
                NewspaperView(articles: articles, gameState: gameState)
            }
        }
        .sheet(isPresented: $showNetwork) {
            if let network = caseData.suspectNetwork {
                SuspectNetworkView(
                    network: network,
                    gameState: gameState,
                    characters: caseData.characters,
                    caseId: caseData.id
                )
            }
        }
        .alert(loc.s(.insufficientTitle), isPresented: $showInsufficientCredits) {
            Button(loc.s(.ok)) {}
        } message: {
            Text(loc.s(.insufficientMsg))
        }
        .task {
            coverImage = await CaseLoader.loadBundleImageAsync(named: caseData.coverImage, caseId: caseData.id)
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

    // MARK: - 1. Header

    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Gorsel: sabit yukseklik, genislik parent'a bagli, tasma yok
            Color.clear
                .frame(height: 180)
                .background(
                    Group {
                        if let coverImage = coverImage {
                            Image(uiImage: coverImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            AtmosphericBackground(backgroundName: "karakol")
                        }
                    }
                )
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [Color.clear, Color.noirBackground.opacity(0.6), Color.noirBackground],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(caseData.city.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.noirSecondary)
                    .tracking(2)

                Text(caseData.title)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(.noirText)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    // MARK: - 2. Partner Ipucu (web: hq-partner)

    private var partnerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            // Partner avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.noirSurface, Color.noirPrimary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                Image(systemName: "shield.checkered")
                    .font(.system(size: 20))
                    .foregroundColor(.noirSecondary)
                Circle()
                    .stroke(Color.noirSecondary.opacity(0.3), lineWidth: 1)
                    .frame(width: 44, height: 44)
            }

            // Ipucu balonu
            VStack(alignment: .leading, spacing: 4) {
                Text(partnerHint)
                    .font(.noirBody(14))
                    .foregroundColor(.noirText.opacity(0.85))
                    .italic()
                    .lineSpacing(3)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: "1A1A2E").opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.noirSecondary.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.noirPrimary.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.noirSecondary.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - 2.5. Itibar (zaman gostergesi UI'dan kaldirildi, icsel takip devam ediyor)

    private var reputationAndTimeSection: some View {
        VStack(spacing: 12) {
            // Itibar bari
            let level = gameState.reputationLevel
            VStack(spacing: 6) {
                HStack {
                    Text(level.icon)
                        .font(.system(size: 14))
                    Text(loc.language == .turkish ? level.title : level.titleEN)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(level.color)
                    Spacer()
                    Text("\(gameState.reputation)/100")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.noirMuted)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.noirPrimary.opacity(0.6))
                            .frame(height: 6)
                        Capsule()
                            .fill(level.color)
                            .frame(width: geo.size.width * CGFloat(gameState.reputation) / 100.0, height: 6)
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.noirPrimary.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(level.color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 16)
    }

    // MARK: - 3. Durum Ozeti

    private var statusSection: some View {
        HStack(spacing: 8) {
            HQStatPill(
                icon: "doc.text.magnifyingglass",
                value: "\(gameState.collectedEvidence.count)",
                label: loc.s(.evidenceLabel),
                color: .noirSecondary
            )
            HQStatPill(
                icon: "map.fill",
                value: "\(gameState.visitedScenes.count)",
                label: loc.s(.hqScenes),
                color: .noirCredit
            )
            HQStatPill(
                icon: "hand.point.up.fill",
                value: "\(gameState.choiceHistory.count)",
                label: loc.s(.hqChoices),
                color: .noirAccent
            )
        }
    }

    // MARK: - 4. Delil Tahtasi

    private var evidenceBoardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pin.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.noirSecondary)
                Text(loc.s(.evidenceBoard))
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(.noirSecondary)
                Spacer()
                Text("\(collectedEvidenceItems.count)/\(caseData.evidence.count)")
                    .font(.noirCaption(12))
                    .foregroundColor(.noirMuted)
            }

            // Cross-reference ozeti
            if crossReferenceCount > 0 {
                Button(action: { showCrossReference = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                            .font(.system(size: 11))
                            .foregroundColor(.noirSecondary)
                        Text(loc.s(.connectionsFound(crossReferenceCount)))
                            .font(.noirCaption(11))
                            .foregroundColor(.noirSecondary)
                    }
                }
                .buttonStyle(.plain)
            }

            if collectedEvidenceItems.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 28))
                            .foregroundColor(.noirMuted.opacity(0.25))
                        Text(loc.s(.noEvidence))
                            .font(.noirCaption(13))
                            .foregroundColor(.noirMuted.opacity(0.4))
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(collectedEvidenceItems) { evidence in
                        HQEvidenceCard(
                            evidence: evidence,
                            caseData: caseData,
                            isExpanded: expandedEvidenceId == evidence.id
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                expandedEvidenceId = expandedEvidenceId == evidence.id ? nil : evidence.id
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.noirPrimary.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.noirSecondary.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - 5. Supheliler (web: hqActions - liste yapisi)

    private var suspectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.noirSecondary)
                Text(loc.s(.investigation))
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(.noirSecondary)
                Spacer()
                Text(loc.s(.suspectCount(suspects.count)))
                    .font(.noirCaption(12))
                    .foregroundColor(.noirMuted)
            }

            // Supheli listesi (web gibi detayli satir)
            VStack(spacing: 8) {
                ForEach(suspects) { char in
                    let availability = checkSuspectAvailability(char.id)
                    let exhausted = gameState.exhaustedCharacters.contains(char.id)
                    HQSuspectRow(
                        character: char,
                        portraitImage: portraitImages[char.id],
                        notes: gameState.characterNotes[char.id] ?? [],
                        linkedEvidenceCount: linkedEvidenceCount(for: char.id),
                        unavailableMessage: availability.available ? nil : availability.message,
                        isExhausted: exhausted,
                        onTapProfile: { selectedCharacter = char },
                        onTapInterrogate: availability.available && onNavigateToScene != nil ? {
                            navigateToScene(findInterrogationScene(for: char.id))
                        } : nil
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.noirPrimary.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.noirSecondary.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - 6. Sorusturma Lokasyonlari (web: hqLocations)

    private func locationsSection(_ locations: [HQLocation]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "map.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.noirSecondary)
                Text(loc.s(.hqLocations))
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(.noirSecondary)
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(locations, id: \.sceneId) { location in
                    let isVisited = gameState.visitedScenes.contains(location.sceneId)

                    Button(action: {
                        navigateToScene(location.sceneId)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: location.icon)
                                .font(.system(size: 16))
                                .foregroundColor(isVisited ? .noirSecondary : .noirMuted)
                                .frame(width: 28)

                            Text(location.label)
                                .font(.noirSubtitle(14))
                                .foregroundColor(.noirText)

                            Spacer()

                            if isVisited {
                                Text(loc.s(.visited))
                                    .font(.noirCaption(10))
                                    .foregroundColor(.noirSecondary.opacity(0.7))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(Color.noirSecondary.opacity(0.12))
                                    )
                            }

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.noirMuted.opacity(0.4))
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.noirPrimary.opacity(isVisited ? 0.4 : 0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(
                                            isVisited ? Color.noirSecondary.opacity(0.15) : Color.noirSecondary.opacity(0.08),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.noirPrimary.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.noirSecondary.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - 7. Sorusturma Araclari

    private var hasAnyTools: Bool {
        caseData.phoneData != nil || caseData.cameraData != nil ||
        (caseData.labAnalyses != nil && !caseData.labAnalyses!.isEmpty) ||
        (caseData.newspaperArticles != nil && !caseData.newspaperArticles!.isEmpty) ||
        caseData.suspectNetwork != nil
    }

    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.noirSecondary)
                Text(loc.s(.toolsSection))
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(.noirSecondary)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if caseData.phoneData != nil {
                        toolButton(
                            icon: "iphone",
                            label: loc.s(.phoneTitle),
                            action: { showPhone = true }
                        )
                    }
                    if caseData.cameraData != nil {
                        toolButton(
                            icon: "video.fill",
                            label: loc.s(.cameraTitle),
                            action: { showCamera = true }
                        )
                    }
                    if let labs = caseData.labAnalyses, !labs.isEmpty {
                        toolButton(
                            icon: "flask.fill",
                            label: loc.s(.labTitle),
                            action: { showLab = true }
                        )
                    }
                    if let articles = caseData.newspaperArticles, !articles.isEmpty {
                        toolButton(
                            icon: "newspaper.fill",
                            label: loc.s(.newspaperTitle),
                            action: { showNewspaper = true }
                        )
                    }
                    if caseData.suspectNetwork != nil {
                        toolButton(
                            icon: "circle.grid.cross.fill",
                            label: loc.s(.networkTitle),
                            action: { showNetwork = true }
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.noirPrimary.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.noirSecondary.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func toolButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(.noirSecondary)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(Color.noirSecondary.opacity(0.1))
                            .overlay(
                                Circle()
                                    .stroke(Color.noirSecondary.opacity(0.2), lineWidth: 0.5)
                            )
                    )

                Text(label)
                    .font(.noirCaption(10))
                    .foregroundColor(.noirMuted)
                    .lineLimit(1)
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 8. Flashback'ler

    private func flashbackSection(_ triggers: [FlashbackTrigger]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "film.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.noirSecondary)
                Text(loc.s(.flashbacksTitle))
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(.noirSecondary)
                Spacer()
            }

            ForEach(triggers) { trigger in
                let isTriggered = gameState.triggeredFlashbacks.contains(trigger.id)
                let hasEvidence = trigger.requires.allSatisfy { gameState.collectedEvidence.contains($0) }

                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: isTriggered ? "checkmark.circle.fill" : hasEvidence ? "play.circle.fill" : "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(
                            isTriggered ? .noirSuccess :
                            hasEvidence ? .noirSecondary :
                            .noirMuted.opacity(0.4)
                        )
                        .frame(width: 28)

                    // Info
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Flashback #\(triggers.firstIndex(where: { $0.id == trigger.id }).map { $0 + 1 } ?? 0)")
                            .font(.noirSubtitle(14))
                            .foregroundColor(hasEvidence || isTriggered ? .noirText : .noirMuted.opacity(0.5))

                        if isTriggered {
                            Text(loc.s(.flashbackTriggered))
                                .font(.noirCaption(11))
                                .foregroundColor(.noirSuccess)
                        } else if hasEvidence {
                            Text(loc.s(.flashbackStart))
                                .font(.noirCaption(11))
                                .foregroundColor(.noirSecondary)
                        } else {
                            let found = trigger.requires.filter { gameState.collectedEvidence.contains($0) }.count
                            Text(loc.s(.flashbackRequires) + " (\(found)/\(trigger.requires.count))")
                                .font(.noirCaption(11))
                                .foregroundColor(.noirMuted.opacity(0.5))
                        }
                    }

                    Spacer()

                    // Action
                    if hasEvidence && !isTriggered {
                        flashbackButton(trigger: trigger)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.noirPrimary.opacity(isTriggered ? 0.3 : hasEvidence ? 0.6 : 0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    isTriggered ? Color.noirSuccess.opacity(0.15) :
                                    hasEvidence ? Color.noirSecondary.opacity(0.15) :
                                    Color.noirMuted.opacity(0.08),
                                    lineWidth: 1
                                )
                        )
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.noirPrimary.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.noirSecondary.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func flashbackButton(trigger: FlashbackTrigger) -> some View {
        let cost = trigger.creditCost ?? 3
        return Button(action: {
            if let profile = playerProfile {
                guard profile.spendCredits(cost) else {
                    showInsufficientCredits = true
                    return
                }
            }
            gameState.triggeredFlashbacks.append(trigger.id)
            navigateToScene(trigger.sceneId)
        }) {
            HStack(spacing: 4) {
                Text(loc.s(.flashbackStart))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.noirSecondary)
                Image(systemName: "diamond.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.noirCredit)
                Text("\(cost)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.noirCredit)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .stroke(Color.noirSecondary.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 9. Suclama Butonu (web: hq-accuse-btn)

    private var accusationSection: some View {
        VStack(spacing: 8) {
            if canAccuse, let onAccuse = onAccuse {
                Button(action: {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onAccuse()
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 18, weight: .semibold))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loc.s(.makeAccusation))
                                .font(.system(size: 17, weight: .bold, design: .serif))
                            Text(loc.s(.nEvidenceReady(gameState.collectedEvidence.count)))
                                .font(.noirCaption(12))
                                .opacity(0.7)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.noirText)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.noirAccent.opacity(0.5), Color.noirAccent.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.noirAccent.opacity(0.6), lineWidth: 1)
                            )
                            .shadow(color: Color.noirAccent.opacity(0.3), radius: 6, y: 3)
                    )
                }
                .buttonStyle(.plain)
            } else {
                // Yetersiz delil bilgisi
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.noirMuted.opacity(0.4))
                    Text(loc.s(.needMoreEvidence(gameState.collectedEvidence.count)))
                        .font(.noirCaption(13))
                        .foregroundColor(.noirMuted.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.noirPrimary.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.noirMuted.opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
    }

    // MARK: - 8. Devam Butonu

    private var continueButton: some View {
        Button(action: { dismiss() }) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                Text(loc.s(.continueInvestigation))
                    .font(.system(size: 17, weight: .bold, design: .serif))
            }
            .foregroundColor(.noirText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.noirSecondary.opacity(0.4), Color.noirSecondary.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.noirSecondary.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: Color.noirSecondary.opacity(0.3), radius: 4, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Yardimci Metodlar

    /// Bu karaktere bagli toplanan delil sayisi
    private func linkedEvidenceCount(for characterId: String) -> Int {
        collectedEvidenceItems.filter { $0.linkedCharacterId == characterId }.count
    }

    /// Supheli musaitlik sistemi devre disi - her zaman musait
    private func checkSuspectAvailability(_ characterId: String) -> (available: Bool, message: String?) {
        return (true, nil)
    }

    private func findInterrogationScene(for characterId: String) -> String? {
        caseData.scenes.first { $0.characterId == characterId && $0.type == .dialogue }?.id
    }

    /// Sheet'i kapat ve sahneye git.
    /// Sheet'in dismiss animasyonu bitince onDisappear tetiklenip pendingSceneId ile
    /// navigasyonu yapar; boylece sabit delay kaynakli race condition olmaz.
    private func navigateToScene(_ sceneId: String?) {
        guard let sceneId = sceneId, onNavigateToScene != nil else { return }
        pendingSceneId = sceneId
        dismiss()
    }
}

// MARK: - Supheli Satiri (web hq-action-btn yapisi)

private struct HQSuspectRow: View {
    let character: Character
    let portraitImage: UIImage?
    let notes: [String]
    let linkedEvidenceCount: Int
    var unavailableMessage: String? = nil
    var isExhausted: Bool = false
    let onTapProfile: () -> Void
    var onTapInterrogate: (() -> Void)? = nil
    @EnvironmentObject var loc: LocalizationManager

    private var hasNewEvidence: Bool {
        linkedEvidenceCount > 0 && notes.isEmpty && !isExhausted
    }

    private var ringColor: Color {
        if isExhausted { return .noirMuted.opacity(0.35) }
        if hasNewEvidence { return .noirAccent }
        if !notes.isEmpty { return .noirSecondary }
        return .noirMuted.opacity(0.4)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Portre
            Button(action: onTapProfile) {
                Group {
                    if let img = portraitImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.noirSurface, Color.noirPrimary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Text(String(character.name.prefix(1)).uppercased())
                                    .font(.system(size: 18, weight: .bold, design: .serif))
                                    .foregroundColor(.noirSecondary)
                            )
                    }
                }
                .frame(width: 46, height: 46)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(ringColor, lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)

            // Bilgiler
            Button(action: onTapProfile) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(character.name)
                            .font(.noirSubtitle(15))
                            .foregroundColor(.noirText)

                        if hasNewEvidence {
                            Text(loc.s(.hqNewEvidence))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.noirBackground)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(Color.noirAccent)
                                )
                        }
                    }

                    Text(character.occupation)
                        .font(.noirCaption(12))
                        .foregroundColor(.noirMuted)

                    if isExhausted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                            Text(loc.s(.interrogationComplete))
                                .font(.noirCaption(11))
                        }
                        .foregroundColor(.noirMuted.opacity(0.7))
                    } else if !notes.isEmpty {
                        Text(loc.s(.interrogated(notes.count)))
                            .font(.noirCaption(11))
                            .foregroundColor(.noirSecondary)
                    } else {
                        Text(loc.s(.notInterrogated))
                            .font(.noirCaption(11))
                            .foregroundColor(.noirMuted.opacity(0.5))
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Musait degil mesaji
            if let msg = unavailableMessage {
                Text(msg)
                    .font(.noirCaption(10))
                    .foregroundColor(.noirMuted.opacity(0.6))
                    .italic()
                    .frame(maxWidth: 100)
                    .multilineTextAlignment(.trailing)
            }
            // Sorgula butonu veya chevron
            else if let onTapInterrogate = onTapInterrogate {
                Button(action: onTapInterrogate) {
                    Text(loc.s(.interrogate))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isExhausted ? .noirMuted.opacity(0.5) : .noirSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .stroke(
                                    isExhausted
                                        ? Color.noirMuted.opacity(0.25)
                                        : Color.noirSecondary.opacity(0.4),
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.noirMuted.opacity(0.4))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.noirPrimary.opacity(isExhausted ? 0.3 : 0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            isExhausted
                                ? Color.noirMuted.opacity(0.12)
                                : (hasNewEvidence ? Color.noirAccent.opacity(0.2) : Color.noirSecondary.opacity(0.08)),
                            lineWidth: 1
                        )
                )
        )
        .opacity(isExhausted ? 0.75 : 1.0)
    }
}

// MARK: - Durum Hapi

private struct HQStatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(.noirText)
            }
            Text(label)
                .font(.noirCaption(9))
                .foregroundColor(.noirMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.noirPrimary.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Delil Kart

private struct HQEvidenceCard: View {
    let evidence: Evidence
    let caseData: Case
    let isExpanded: Bool
    let onTap: () -> Void
    @EnvironmentObject var loc: LocalizationManager

    /// Delil ID'sine gore ikon belirle
    private var evidenceIcon: String {
        let id = evidence.id.lowercased()
        if id.contains("kamera") || id.contains("guvenlik") || id.contains("camera") || id.contains("security") {
            return "video.fill"
        }
        if id.contains("mesaj") || id.contains("message") || id.contains("eposta") || id.contains("email") {
            return "message.fill"
        }
        if id.contains("rapor") || id.contains("report") || id.contains("otopsi") || id.contains("autopsy") {
            return "doc.text.fill"
        }
        if id.contains("telefon") || id.contains("phone") || id.contains("internet") {
            return "phone.fill"
        }
        if id.contains("bileti") || id.contains("ticket") || id.contains("ucak") || id.contains("flight") {
            return "airplane"
        }
        if id.contains("sigorta") || id.contains("insurance") || id.contains("eczane") || id.contains("pharmacy") {
            return "cross.case.fill"
        }
        if id.contains("parmak") || id.contains("fingerprint") || id.contains("dna") {
            return "hand.raised.fill"
        }
        return "doc.text.magnifyingglass"
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: evidenceIcon)
                        .font(.system(size: 16))
                        .foregroundColor(.noirSecondary)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(evidence.title)
                            .font(.noirSubtitle(14))
                            .foregroundColor(.noirText)
                            .lineLimit(isExpanded ? nil : 1)

                        // Bagli karakter gosterimi (kart basliginda)
                        if !isExpanded, let charId = evidence.linkedCharacterId,
                           let character = caseData.characters.first(where: { $0.id == charId }) {
                            Text(character.name)
                                .font(.noirCaption(10))
                                .foregroundColor(.noirSecondary.opacity(0.7))
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.noirMuted.opacity(0.5))
                }

                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                            .background(Color.noirSecondary.opacity(0.2))
                            .padding(.top, 8)

                        Text(evidence.description)
                            .font(.noirBody(13))
                            .foregroundColor(.noirText.opacity(0.8))
                            .lineSpacing(3)

                        if let charId = evidence.linkedCharacterId,
                           let character = caseData.characters.first(where: { $0.id == charId }) {
                            HStack(spacing: 5) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.noirSecondary)
                                Text(loc.s(.linkedSuspect(character.name)))
                                    .font(.noirCaption(12))
                                    .foregroundColor(.noirSecondary)
                            }
                            .padding(.top, 2)
                        }

                        // Eliminates bilgisi
                        if let eliminates = evidence.eliminates {
                            ForEach(eliminates, id: \.self) { suspectId in
                                if let character = caseData.characters.first(where: { $0.id == suspectId }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(.green.opacity(0.8))
                                        Text(loc.s(.eliminatesSuspect(character.name)))
                                            .font(.noirCaption(12))
                                            .foregroundColor(.green.opacity(0.8))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.noirPrimary.opacity(isExpanded ? 0.8 : 0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                isExpanded ? Color.noirSecondary.opacity(0.25) : Color.noirSecondary.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
