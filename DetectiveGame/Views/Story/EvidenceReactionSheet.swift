import SwiftUI

struct EvidenceReactionSheet: View {
    let caseData: Case
    let gameState: GameState
    let characterId: String
    let sceneId: String
    let onShowEvidence: (String) -> EvidenceReaction?
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedEvidence: Evidence? = nil
    @State private var reaction: EvidenceReaction? = nil

    private var availableEvidence: [Evidence] {
        gameState.collectedEvidence.compactMap { evidenceId in
            caseData.evidence.first { $0.id == evidenceId }
        }.filter { evidence in
            // Daha once gosterilmemis delilleri listele
            !gameState.hasShownEvidence(evidence.id, to: characterId)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.noirBackground.ignoresSafeArea()

                if let reaction = reaction {
                    // Tepki gorunumu
                    reactionView(reaction)
                } else {
                    // Delil secimi
                    evidenceListView
                }
            }
            .navigationTitle(loc.s(.showEvidence))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(loc.s(.close)) { dismiss() }
                        .foregroundColor(.noirSecondary)
                }
            }
            .toolbarBackground(Color.noirPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private var evidenceListView: some View {
        ScrollView {
            if availableEvidence.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.noirMuted.opacity(0.4))
                    Text(loc.s(.noEvidence))
                        .font(.noirBody(14))
                        .foregroundColor(.noirMuted)
                }
                .padding(.top, 60)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(availableEvidence) { evidence in
                        Button(action: {
                            selectedEvidence = evidence
                            reaction = onShowEvidence(evidence.id)
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 18))
                                    .foregroundColor(.noirSecondary)

                                Text(evidence.title)
                                    .font(.noirBody(15))
                                    .foregroundColor(.noirText)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.noirMuted)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.noirPrimary.opacity(0.7))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.noirSecondary.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
    }

    private func reactionView(_ reaction: EvidenceReaction) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Tepki baslik
                HStack(spacing: 8) {
                    reactionIcon(reaction.reaction)
                    Text(loc.s(.characterReaction))
                        .font(.noirSubtitle(16))
                        .foregroundColor(.noirSecondary)
                }
                .padding(.top, 16)

                // Diyalog
                Text(reaction.dialogue)
                    .font(.noirDialogue())
                    .foregroundColor(.noirText)
                    .lineSpacing(4)

                // Geri don butonu
                Button(action: {
                    self.reaction = nil
                    selectedEvidence = nil
                }) {
                    Text(loc.s(.back))
                        .font(.noirChoice(14))
                        .foregroundColor(.noirSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.noirPrimary.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.noirSecondary.opacity(0.25), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
    }

    private func reactionIcon(_ type: String) -> some View {
        let (icon, color): (String, Color) = {
            switch type {
            case "shocked": return ("exclamationmark.triangle", Color(hex: "E05050"))
            case "defensive": return ("shield.fill", Color(hex: "C0A040"))
            case "calm": return ("face.smiling", Color(hex: "50A070"))
            case "nervous": return ("exclamationmark.circle", Color(hex: "C06040"))
            default: return ("questionmark.circle", .noirMuted)
            }
        }()

        return Image(systemName: icon)
            .font(.system(size: 20))
            .foregroundColor(color)
    }
}
