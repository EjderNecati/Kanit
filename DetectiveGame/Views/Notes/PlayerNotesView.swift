import SwiftUI

struct PlayerNotesView: View {
    @ObservedObject var gameState: GameState
    var currentSceneId: String?
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @State private var newNoteText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()

                VStack(spacing: 0) {
                    // Not ekleme alani
                    HStack(spacing: 10) {
                        TextField(loc.s(.addNote), text: $newNoteText)
                            .font(.noirBody(14))
                            .foregroundColor(.noirText)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.noirPrimary.opacity(0.5))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.noirSecondary.opacity(0.2), lineWidth: 1)
                                    )
                            )

                        Button(action: addNote) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.noirSecondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(newNoteText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(16)

                    // Not listesi
                    if gameState.playerNotes.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "pencil.line")
                                .font(.system(size: 40))
                                .foregroundColor(.noirMuted.opacity(0.4))
                            Text(loc.s(.noNotes))
                                .font(.noirBody(14))
                                .foregroundColor(.noirMuted)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(gameState.playerNotes.reversed()) { note in
                                    NoteCardView(note: note)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle(loc.s(.myNotes))
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

    private func addNote() {
        let trimmed = newNoteText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        gameState.addPlayerNote(trimmed, sceneId: currentSceneId)
        newNoteText = ""
    }
}

private struct NoteCardView: View {
    let note: PlayerNote

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: note.timestamp)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(note.text)
                .font(.noirBody(14))
                .foregroundColor(.noirText)
                .lineSpacing(3)

            HStack {
                Text(timeString)
                    .font(.noirCaption(11))
                    .foregroundColor(.noirMuted)


                Spacer()
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.noirPrimary.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.noirSecondary.opacity(0.15), lineWidth: 1)
                )
        )
    }
}
