import SwiftUI

struct EvidenceGalleryView: View {
    let caseData: Case
    let gameState: GameState

    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    // Toplanan delilleri case evidence dizisinden al
    var collectedEvidenceItems: [Evidence] {
        gameState.collectedEvidence.compactMap { evidenceId in
            caseData.evidence.first { $0.id == evidenceId }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()

                if collectedEvidenceItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.noirMuted.opacity(0.4))

                        Text(loc.s(.noEvidence))
                            .font(.noirBody(16))
                            .foregroundColor(.noirMuted)

                        Text(loc.s(.searchScene))
                            .font(.noirCaption(14))
                            .foregroundColor(.noirMuted.opacity(0.6))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(collectedEvidenceItems) { item in
                                EvidenceCardView(evidence: item, caseData: caseData)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle(loc.s(.collectedEvidence))
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
}

struct EvidenceCardView: View {
    let evidence: Evidence
    let caseData: Case

    @EnvironmentObject var loc: LocalizationManager
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(.noirSecondary)

                Text(evidence.title)
                    .font(.noirSubtitle(16))
                    .foregroundColor(.noirText)

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14))
                    .foregroundColor(.noirMuted)
            }

            if isExpanded {
                Divider()
                    .background(Color.noirSecondary.opacity(0.3))

                Text(evidence.description)
                    .font(.noirBody(14))
                    .foregroundColor(.noirText.opacity(0.85))
                    .lineSpacing(3)

                // Bagli karakter
                if let charId = evidence.linkedCharacterId,
                   let character = caseData.characters.first(where: { $0.id == charId }) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.noirSecondary)
                        Text(loc.s(.linkedSuspect(character.name)))
                            .font(.noirCaption(13))
                            .foregroundColor(.noirSecondary)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.noirPrimary.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.noirSecondary.opacity(0.2), lineWidth: 1)
                )
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }
}
