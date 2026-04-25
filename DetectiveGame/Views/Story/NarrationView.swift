import SwiftUI

struct NarrationView: View {
    let scene: GameScene
    let caseId: String
    let choices: [Choice]
    let canAffordChoice: (Choice) -> Bool
    let onChoice: (Choice) -> Void
    var showHQButton: Bool = false
    var onReturnToHQ: (() -> Void)? = nil
    @EnvironmentObject var loc: LocalizationManager
    @State private var textComplete = false
    @State private var bgImage: UIImage? = nil

    var body: some View {
        ZStack {
            // Koyu arka plan
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

                        // Metin kutusu
                    VStack(alignment: .leading, spacing: 16) {
                        TypewriterText(
                            fullText: scene.text,
                            font: .noirBody(),
                            color: .noirText,
                            onComplete: { textComplete = true }
                        )
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // Secenekler (metin tamamlaninca goster)
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

                                // Karargaha Don butonu (HQ aciksa veya 0-choice dead-end sahnelerde her zaman goster)
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
