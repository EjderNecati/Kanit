import SwiftUI

struct SuspectListView: View {
    let caseData: Case
    let gameState: GameState

    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCharacter: Character? = nil

    var suspects: [Character] {
        caseData.characters.filter { $0.isSuspect }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(suspects) { character in
                            SuspectCardView(
                                character: character,
                                caseId: caseData.id,
                                notes: gameState.characterNotes[character.id] ?? []
                            ) {
                                selectedCharacter = character
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(loc.s(.suspectsLabel))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(loc.s(.close)) { dismiss() }
                        .foregroundColor(.noirSecondary)
                }
            }
            .toolbarBackground(Color.noirPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(item: $selectedCharacter) { character in
                SuspectProfileView(character: character, caseId: caseData.id, notes: gameState.characterNotes[character.id] ?? [])
            }
        }
    }
}

struct SuspectCardView: View {
    let character: Character
    let caseId: String
    let notes: [String]
    let action: () -> Void
    @EnvironmentObject var loc: LocalizationManager
    @State private var portraitImage: UIImage? = nil

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Portre
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
                                    .font(.system(size: 22, weight: .bold, design: .serif))
                                    .foregroundColor(.noirSecondary)
                            )
                    }
                }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.noirSecondary.opacity(0.4), lineWidth: 1.5)
                    )

                // Bilgiler
                VStack(alignment: .leading, spacing: 4) {
                    Text(character.name)
                        .font(.noirSubtitle(17))
                        .foregroundColor(.noirText)

                    Text(loc.s(.ageLabel(character.age, character.occupation)))
                        .font(.noirCaption(13))
                        .foregroundColor(.noirMuted)

                    if !notes.isEmpty {
                        Text(loc.s(.noteCount(notes.count)))
                            .font(.noirCaption(12))
                            .foregroundColor(.noirSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.noirMuted)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.noirPrimary.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.noirSecondary.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .task {
            portraitImage = await CaseLoader.loadBundleImageAsync(named: character.portraitImage, caseId: caseId)
        }
    }
}
