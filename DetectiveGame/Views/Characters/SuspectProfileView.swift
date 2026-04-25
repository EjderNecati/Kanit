import SwiftUI

struct SuspectProfileView: View {
    let character: Character
    let caseId: String
    let notes: [String]

    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @State private var portraitImage: UIImage? = nil

    var body: some View {
        ZStack {
            PaperBackground()

            ScrollView {
                VStack(spacing: 24) {
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
                                        .font(.system(size: 44, weight: .bold, design: .serif))
                                        .foregroundColor(.noirSecondary)
                                )
                        }
                    }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.noirSecondary.opacity(0.5), lineWidth: 2)
                        )
                        .noirShadow()
                        .padding(.top, 32)

                    // Isim
                    Text(character.name)
                        .font(.noirTitle(28))
                        .foregroundColor(.noirText)

                    // Bilgi kartlari
                    VStack(spacing: 12) {
                        ProfileInfoRow(label: loc.s(.ageWord), value: "\(character.age)")
                        ProfileInfoRow(label: loc.s(.occupationWord), value: character.occupation)
                        ProfileInfoRow(label: loc.s(.relationToVictim), value: character.relationToVictim)
                    }
                    .padding(.horizontal, 24)

                    // Alibi
                    VStack(alignment: .leading, spacing: 8) {
                        Text(loc.s(.statement))
                            .font(.noirSubtitle(16))
                            .foregroundColor(.noirSecondary)

                        Text("\"\(character.alibi)\"")
                            .font(.noirDialogue(16))
                            .foregroundColor(.noirText)
                            .italic()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.noirPrimary.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.noirSecondary.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 24)

                    // Notlar
                    if !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(loc.s(.notes))
                                .font(.noirSubtitle(16))
                                .foregroundColor(.noirSecondary)

                            ForEach(Array(notes.enumerated()), id: \.offset) { _, note in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "pencil.line")
                                        .font(.system(size: 12))
                                        .foregroundColor(.noirSecondary)
                                        .padding(.top, 3)

                                    Text(note)
                                        .font(.noirBody(14))
                                        .foregroundColor(.noirText)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.noirPrimary.opacity(0.6))
                        )
                        .padding(.horizontal, 24)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(loc.s(.close)) { dismiss() }
                .font(.noirCaption(14))
                .foregroundColor(.noirSecondary)
                .padding(16)
        }
        .task {
            portraitImage = await CaseLoader.loadBundleImageAsync(named: character.portraitImage, caseId: caseId)
        }
    }
}

struct ProfileInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.noirCaption(14))
                .foregroundColor(.noirMuted)
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(.noirBody(15))
                .foregroundColor(.noirText)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
