import SwiftUI

struct AccusationView: View {
    @ObservedObject var storyEngine: StoryEngine
    @ObservedObject var playerProfile: PlayerProfile
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var loc: LocalizationManager

    @State private var selectedSuspects: Set<String> = []
    @State private var showResult = false
    @State private var resultEnding: Ending? = nil
    @State private var showCreditAlert = false

    var suspects: [Character] {
        storyEngine.currentCase?.characters.filter { $0.isSuspect } ?? []
    }

    var collectedEvidence: [String] {
        storyEngine.gameState?.collectedEvidence ?? []
    }

    /// Vakada birden fazla suclu gerekiyor mu?
    private var isCoCulpritCase: Bool {
        (storyEngine.currentCase?.coCulprits?.count ?? 0) >= 2
    }

    private var requiredCount: Int {
        storyEngine.currentCase?.coCulprits?.count ?? 1
    }

    private var canSubmit: Bool {
        if isCoCulpritCase {
            return selectedSuspects.count == requiredCount
        }
        return !selectedSuspects.isEmpty
    }

    var body: some View {
        ZStack {
            PaperBackground()

            ScrollView {
                VStack(spacing: 28) {
                    // Geri butonu
                    HStack {
                        Button(action: goBack) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(loc.s(.back))
                                    .font(.noirBody(16))
                            }
                            .foregroundColor(.noirSecondary)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 50)

                    // Baslik
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.noirAccent)

                        Text(loc.s(.accusation))
                            .font(.noirTitle(32))
                            .foregroundColor(.noirText)
                            .tracking(4)

                        Text(loc.s(.selectKiller))
                            .font(.noirBody(16))
                            .foregroundColor(.noirMuted)
                    }
                    .padding(.top, 8)

                    // Supheli secimi
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(loc.s(.whoAccuse))
                                .font(.noirSubtitle(18))
                                .foregroundColor(.noirSecondary)
                            Spacer()
                            if isCoCulpritCase {
                                Text("\(selectedSuspects.count)/\(requiredCount)")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.noirSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.noirSecondary.opacity(0.12))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.noirSecondary.opacity(0.3), lineWidth: 0.5)
                                            )
                                    )
                            }
                        }

                        if isCoCulpritCase {
                            Text(loc.language == .turkish
                                 ? "Bu vakada birden fazla suçlu var. Hepsini seçmelisin."
                                 : "This case has multiple culprits. You must select them all.")
                                .font(.noirCaption(12))
                                .foregroundColor(.noirMuted)
                                .italic()
                        }

                        ForEach(suspects) { suspect in
                            SuspectSelectionRow(
                                character: suspect,
                                caseId: storyEngine.currentCase?.id ?? "",
                                isSelected: selectedSuspects.contains(suspect.id)
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    toggleSuspect(suspect.id)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Sucla butonu
                    if canSubmit {
                        Button(action: makeAccusation) {
                            HStack(spacing: 8) {
                                Image(systemName: "hand.point.right.fill")
                                Text(loc.s(.accuse))
                                    .tracking(2)
                            }
                            .font(.noirSubtitle(18))
                            .foregroundColor(.noirText)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.noirAccent)
                            )
                            .noirShadow()
                        }
                        .padding(.top, 8)
                    }

                    Spacer(minLength: 60)
                }
            }
        }
        .alert(loc.s(.insufficientTitle), isPresented: $showCreditAlert) {
            Button(loc.s(.ok)) {}
        } message: {
            Text(loc.language == .turkish
                 ? "Tekrar suçlama yapmak 1 kredi gerektirir."
                 : "Making another accusation requires 1 credit.")
        }
    }

    private func goBack() {
        guard let gameState = storyEngine.gameState else { return }
        // Son accusation olmayan sahneye don
        if let previousId = gameState.visitedScenes.last(where: { $0 != "scene_accusation" }) {
            storyEngine.goToScene(previousId)
        }
    }

    /// Co-culprit vakalarda maksimuma ulasinca yeni ekleme engellensin
    private func toggleSuspect(_ id: String) {
        if selectedSuspects.contains(id) {
            selectedSuspects.remove(id)
        } else {
            if isCoCulpritCase && selectedSuspects.count >= requiredCount {
                // Limit doldu: yeni secimi reddet
                return
            }
            if !isCoCulpritCase {
                // Tek supheli modu: onceki secimi temizle
                selectedSuspects.removeAll()
            }
            selectedSuspects.insert(id)
        }
    }

    private func makeAccusation() {
        guard !selectedSuspects.isEmpty else { return }
        let caseId = storyEngine.currentCase?.id ?? ""

        // Suclama yapmak ucretsiz - kullanici istedigi kadar suclayabilir
        playerProfile.recordAccusation(for: caseId)

        // Otomatik olarak tum toplanan delilleri gonder - kullanici delil secmiyor
        let ending = storyEngine.accuseSuspect(
            Array(selectedSuspects),
            withEvidence: collectedEvidence
        )

        if let ending = ending {
            resultEnding = ending

            // Sonucu kaydet
            playerProfile.completedCases[caseId] = ending.id
            if ending.isCorrect {
                playerProfile.totalCasesSolved += 1
            }
            SaveManager.savePlayerProfile(playerProfile)

            // Ending sahnesine git
            if storyEngine.findScene(id: ending.id) != nil {
                storyEngine.goToScene(ending.id)
            } else {
                // Ending sahnesi yoksa dogrudan ending view goster
                if let currentCase = storyEngine.currentCase {
                    navigationPath.append(AppRoute.ending(ending, currentCase))
                }
            }
        }
    }
}

// MARK: - Supheli Secim Satiri

struct SuspectSelectionRow: View {
    let character: Character
    let caseId: String
    let isSelected: Bool
    let action: () -> Void
    @State private var portraitImage: UIImage? = nil

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Group {
                    if let portraitImage = portraitImage {
                        Image(uiImage: portraitImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Circle()
                            .fill(Color.noirPrimary)
                            .overlay(
                                Text(String(character.name.prefix(1)).uppercased())
                                    .font(.system(size: 18, weight: .bold, design: .serif))
                                    .foregroundColor(.noirSecondary)
                            )
                    }
                }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())

                Text(character.name)
                    .font(.noirChoice())
                    .foregroundColor(.noirText)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .noirAccent : .noirMuted)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.noirPrimary.opacity(isSelected ? 0.8 : 0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.noirAccent.opacity(0.5) : Color.noirMuted.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .task {
            portraitImage = await CaseLoader.loadBundleImageAsync(named: character.portraitImage, caseId: caseId)
        }
    }
}

// MARK: - Delil Secim Satiri

struct EvidenceSelectionRow: View {
    let evidence: Evidence?
    let evidenceId: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .noirSecondary : .noirMuted)

                VStack(alignment: .leading, spacing: 3) {
                    Text(evidence?.title ?? evidenceId.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.noirChoice(15))
                        .foregroundColor(.noirText)

                    if let desc = evidence?.description {
                        Text(desc)
                            .font(.noirCaption(12))
                            .foregroundColor(.noirMuted)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.noirPrimary.opacity(isSelected ? 0.7 : 0.4))
            )
        }
        .buttonStyle(.plain)
    }
}
