import SwiftUI

struct DialogueView: View {
    let scene: GameScene
    let character: Character?
    let caseId: String
    let choices: [Choice]
    let canAffordChoice: (Choice) -> Bool
    let onChoice: (Choice) -> Void
    var showHQButton: Bool = false
    var onReturnToHQ: (() -> Void)? = nil
    var revisitMessage: String? = nil
    @EnvironmentObject var loc: LocalizationManager
    @State private var textComplete = false
    @State private var bgImage: UIImage? = nil

    var body: some View {
        ZStack {
            // Koyu arka plan (gorsel olmayan alan icin)
            Color.noirBackground.ignoresSafeArea()

            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Ust kisim: Gorsel (tam gozuken, kirpilmamis)
                        if let bgImage = bgImage {
                            Image(uiImage: bgImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .overlay(
                                    // Tek birlesik overlay: vignette + alt fade
                                    LinearGradient(
                                        colors: [Color.black.opacity(0.15), Color.black.opacity(0.1),
                                                 Color.noirBackground.opacity(0.6), Color.noirBackground],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .drawingGroup()
                        } else {
                            AtmosphericBackground(backgroundName: scene.background)
                                .frame(height: 280)
                        }

                        // Esnek bosluk: kisa metinlerde kutuyu alta iter
                        Spacer(minLength: 0)

                        // Karakter portresi
                    if let character = character {
                        CharacterPortrait(character: character, caseId: caseId)
                            .padding(.top, -30)
                            .padding(.bottom, 8)
                    }

                    // Diyalog kutusu
                    VStack(alignment: .leading, spacing: 16) {
                        // Revisit banner (opsiyonel)
                        if let msg = revisitMessage {
                            Text(msg)
                                .font(.noirBody(14))
                                .foregroundColor(.noirMuted.opacity(0.9))
                                .italic()
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                                .padding(.bottom, 2)
                        }

                        // Karakter adi
                        if let character = character {
                            Text(character.name)
                                .font(.noirSubtitle(16))
                                .foregroundColor(.noirSecondary)
                                .padding(.horizontal, 20)
                                .padding(.top, revisitMessage == nil ? 16 : 4)
                        }

                        // Diyalog metni
                        TypewriterText(
                            fullText: scene.text,
                            font: .noirDialogue(),
                            color: .noirText,
                            onComplete: { textComplete = true }
                        )
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)

                        // Secenekler
                        if textComplete {
                            VStack(spacing: 10) {
                                ForEach(Array(choices.enumerated()), id: \.element.id) { index, choice in
                                    ChoiceButtonView(
                                        choice: choice,
                                        canAfford: canAffordChoice(choice),
                                        index: index,
                                        action: { onChoice(choice) }
                                    )
                                }

                                // Karargaha Don butonu
                                if (showHQButton || choices.isEmpty), let onHQ = onReturnToHQ {
                                    Button(action: onHQ) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "building.columns.fill")
                                                .font(.system(size: 14))
                                            Text(loc.s(.returnToHQ))
                                                .font(.noirChoice(14))
                                        }
                                        .foregroundColor(.noirSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(Color.noirPrimary.opacity(0.6))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .stroke(Color.noirSecondary.opacity(0.25), lineWidth: 1)
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.top, 6)
                                }
                            }
                            .padding(.horizontal, 16)
                            .transition(.slideUp)
                        }
                    }
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.noirTextBox)
                            .padding(.horizontal, 8)
                    )
                    .padding(.bottom, 100)
                }
                .frame(minHeight: geo.size.height)
                }
            }
        }
        .task(id: scene.id) {
            textComplete = false
            bgImage = await CaseLoader.loadBundleImageAsync(named: scene.background, caseId: caseId)
        }
    }
}

// MARK: - Karakter Portresi

struct CharacterPortrait: View {
    let character: Character
    let caseId: String
    @State private var portraitImage: UIImage? = nil

    var body: some View {
        HStack {
            ZStack {
                // Dis glow katmani - genis, yumusak
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.noirSecondary.opacity(0.12), Color.noirSecondary.opacity(0)],
                            center: .center,
                            startRadius: 30,
                            endRadius: 55
                        )
                    )
                    .frame(width: 110, height: 110)

                // Ic glow katmani - yogun, dar
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.noirSecondary.opacity(0.25), Color.noirSecondary.opacity(0)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 44
                        )
                    )
                    .frame(width: 88, height: 88)

                if let portraitImage = portraitImage {
                    Image(uiImage: portraitImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                        .overlay(
                            // Gradient stroke: ustten parlak, alttan soluk
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.noirSecondary.opacity(0.7), Color.noirSecondary.opacity(0.2)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 2
                                )
                        )
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.noirSurface, Color.noirPrimary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .overlay(
                            Text(String(character.name.prefix(1)).uppercased())
                                .font(.system(size: 28, weight: .bold, design: .serif))
                                .foregroundColor(.noirSecondary)
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.noirSecondary.opacity(0.7), Color.noirSecondary.opacity(0.2)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 2
                                )
                        )
                }
            }
            .padding(.leading, 20)

            Spacer()
        }
        .task {
            portraitImage = await CaseLoader.loadBundleImageAsync(named: character.portraitImage, caseId: caseId)
        }
    }
}
