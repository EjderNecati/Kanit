import SwiftUI

// MARK: - Tutorial Adim Modeli

struct TutorialStep: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String
}

// MARK: - Tutorial Overlay (noir stili)

struct TutorialOverlay: View {
    let steps: [TutorialStep]
    let onFinish: () -> Void

    @EnvironmentObject var loc: LocalizationManager
    @State private var index: Int = 0
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Karartma
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture { } // Arka plana dokunus yutulsun

            VStack(spacing: 0) {
                Spacer()

                // Kart
                VStack(spacing: 18) {
                    // Step sayaci + Atla
                    HStack {
                        Text("\(index + 1) / \(steps.count)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.noirSecondary.opacity(0.7))
                            .tracking(2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.noirPrimary.opacity(0.7))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.noirSecondary.opacity(0.2), lineWidth: 0.5)
                                    )
                            )

                        Spacer()

                        Button(action: onFinish) {
                            Text(loc.s(.tutorialSkip))
                                .font(.system(size: 13, weight: .semibold, design: .serif))
                                .foregroundColor(.noirMuted)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .stroke(Color.noirMuted.opacity(0.25), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    // Ikon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.noirSecondary.opacity(0.25),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 4,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 90, height: 90)

                        Image(systemName: steps[index].icon)
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.noirSecondary, Color.noirGold],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    // Dekoratif cizgi
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.clear, Color.noirSecondary.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 0.5)
                        Circle()
                            .fill(Color.noirSecondary.opacity(0.7))
                            .frame(width: 4, height: 4)
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.noirSecondary.opacity(0.5), Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 0.5)
                    }
                    .frame(width: 160)

                    // Baslik
                    Text(steps[index].title)
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(.noirText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    // Aciklama
                    Text(steps[index].body)
                        .font(.noirBody(14))
                        .foregroundColor(.noirText.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4)

                    // Progress noktalari
                    HStack(spacing: 6) {
                        ForEach(0..<steps.count, id: \.self) { i in
                            Circle()
                                .fill(i == index ? Color.noirSecondary : Color.noirMuted.opacity(0.3))
                                .frame(width: i == index ? 8 : 6, height: i == index ? 8 : 6)
                                .animation(.easeInOut(duration: 0.2), value: index)
                        }
                    }
                    .padding(.top, 4)

                    // Butonlar
                    HStack(spacing: 10) {
                        if index > 0 {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    index -= 1
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text(loc.s(.tutorialPrev))
                                        .font(.system(size: 14, weight: .semibold, design: .serif))
                                }
                                .foregroundColor(.noirMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.noirPrimary.opacity(0.5))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(Color.noirMuted.opacity(0.2), lineWidth: 0.5)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        Button(action: {
                            if index == steps.count - 1 {
                                onFinish()
                            } else {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    index += 1
                                }
                            }
                        }) {
                            HStack(spacing: 6) {
                                Text(index == steps.count - 1 ? loc.s(.tutorialFinish) : loc.s(.tutorialNext))
                                    .font(.system(size: 14, weight: .bold, design: .serif))
                                if index < steps.count - 1 {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .bold))
                                } else {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 12, weight: .bold))
                                }
                            }
                            .foregroundColor(.noirText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.noirSecondary.opacity(0.5), Color.noirSecondary.opacity(0.25)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(Color.noirSecondary.opacity(0.55), lineWidth: 1)
                                    )
                                    .shadow(color: Color.noirSecondary.opacity(0.3), radius: 6, y: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
                .padding(22)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.noirBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.noirSecondary.opacity(0.45),
                                            Color.noirSecondary.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.6), radius: 24, y: 10)
                )
                .padding(.horizontal, 22)
                .scaleEffect(appeared ? 1.0 : 0.94)
                .opacity(appeared ? 1.0 : 0.0)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                appeared = true
            }
        }
    }
}

// MARK: - Tutorial Adim Kutuphanesi

enum TutorialLibrary {
    static func caseSelectionSteps(lang: AppLanguage) -> [TutorialStep] {
        if lang == .turkish {
            return [
                TutorialStep(
                    icon: "folder.fill",
                    title: "Hoş Geldin Dedektif",
                    body: "Burası Dosyalar ekranı. KANIT'taki tüm vakalar bu sayfada listelenir. Çözmek için birini seç ve soruşturmaya başla."
                ),
                TutorialStep(
                    icon: "star.fill",
                    title: "Zorluk Seviyesi",
                    body: "Her vaka kartının üstündeki yıldızlar zorluğu gösterir. 1 yıldız kolay, 4 yıldız oldukça çetin bir bulmaca demektir."
                ),
                TutorialStep(
                    icon: "mappin.and.ellipse",
                    title: "Şehir Etiketi",
                    body: "Kartın altındaki küçük etiket vakanın geçtiği şehri söyler: İstanbul, Londra, Girne, Napoli, Paris. Her şehir farklı bir hikaye."
                ),
                TutorialStep(
                    icon: "diamond.fill",
                    title: "Premium Vakalar",
                    body: "Üzerinde 'Premium' rozeti olan vakalar 2 krediye açılır. Vakayı açtıktan sonra ilk oynayışın ücretsizdir. Başa dönüp tekrar oynamak istersen her seferinde 1 kredi harcanır."
                ),
                TutorialStep(
                    icon: "hand.tap.fill",
                    title: "Vakayı Seç",
                    body: "Bir vakaya dokunursan dosya özetini görürsün. Ardından 'Soruşturmaya Başla' ile işe koyulursun. Daha önce oynadıysan kaldığın yerden devam edebilirsin."
                ),
                TutorialStep(
                    icon: "sparkles",
                    title: "Yeni Vakalar Geliyor",
                    body: "Dosyalar her güncellemeyle büyüyor. Yeni şehirler, yeni kurbanlar, yeni sırlar. Bizi takipte kal, bir sonraki vaka yolda."
                )
            ]
        } else {
            return [
                TutorialStep(
                    icon: "folder.fill",
                    title: "Welcome, Detective",
                    body: "This is the Case Files screen. Every case in KANIT is listed here. Pick one to start investigating."
                ),
                TutorialStep(
                    icon: "star.fill",
                    title: "Difficulty",
                    body: "The stars on each case card show the difficulty. 1 star is easy, 4 stars is a tough puzzle."
                ),
                TutorialStep(
                    icon: "mappin.and.ellipse",
                    title: "City Tag",
                    body: "The small tag on each card shows where the case takes place: Istanbul, London, Girne, Naples, Paris. A different story for every city."
                ),
                TutorialStep(
                    icon: "diamond.fill",
                    title: "Premium Cases",
                    body: "Cases with a 'Premium' badge unlock for 2 credits. Your first run after unlocking is free. Restarting the case later costs 1 credit each time."
                ),
                TutorialStep(
                    icon: "hand.tap.fill",
                    title: "Pick a Case",
                    body: "Tap a case to see the file summary. Then hit 'Start Investigation' to begin. If you've played it before, you can continue where you left off."
                ),
                TutorialStep(
                    icon: "sparkles",
                    title: "More Cases Coming",
                    body: "The file cabinet keeps growing with every update. New cities, new victims, new secrets. Stay tuned, the next case is on its way."
                )
            ]
        }
    }

    static func gameSteps(lang: AppLanguage) -> [TutorialStep] {
        if lang == .turkish {
            return [
                TutorialStep(
                    icon: "text.alignleft",
                    title: "Hikaye Akışı",
                    body: "Yazılar daktilo gibi akar. Sabırsızsan ekrana bir dokunuş, yazıyı anında tamamlar."
                ),
                TutorialStep(
                    icon: "list.bullet",
                    title: "Seçimler",
                    body: "Metnin altında beliren seçenekler seni yeni sahnelere, delillere ve şüphelilere götürür. Bazı seçimlerin geri dönüşü yoktur."
                ),
                TutorialStep(
                    icon: "rectangle.grid.2x2.fill",
                    title: "Alt Menü",
                    body: "Ekranın altında beş sekme var: Deliller, Şüpheliler, Notlarım, Mağaza ve Menü. Her biri soruşturmanı takip etmeni sağlar."
                ),
                TutorialStep(
                    icon: "building.columns.fill",
                    title: "Karargah",
                    body: "Sahnenin altındaki 'Karargaha Dön' butonu karargaha götürür. Oradan şüphelileri tekrar sorgulayabilir, lokasyonları tekrar ziyaret edebilirsin. Karakterle konuşmaya dönersen konuştuğun noktadan devam edersin, baştan başlamazsın."
                ),
                TutorialStep(
                    icon: "checkmark.seal.fill",
                    title: "Sorgulama Tamamlandı",
                    body: "Bir şüpheliye soracak her şeyi sorduğunda karargahta grileşir ve 'Sorgulama tamamlandı' yazar. Üzerine tıklayabilirsin ama yeni bir delil elinde olmadıkça sana söyleyecek yeni bir şeyleri yoktur: 'Söyleyecek bir şeyim kalmadı' der. Yeni delil bulduğunda daha önce soramadığın sorular açılabilir, o zaman kilitli görünen şüphelilere dönmek anlamlı olur."
                ),
                TutorialStep(
                    icon: "scalemass.fill",
                    title: "Suçlama",
                    body: "Sahnelerde 'Suçla' seçeneği yoktur. Suçlama yalnızca karargahtaki 'Suçlama Yap' butonundan başlatılır. Doğru katili doğru delillerle işaretlemelisin. Yanlış suçlamada vakayı kaybedersin."
                ),
                TutorialStep(
                    icon: "line.3.horizontal",
                    title: "Oyun Menüsü",
                    body: "Sağ alttaki Menü'den vakayı kaydedip çıkabilir, 1 kredi karşılığı başa dönebilir ya da bu tur gibi 'Nasıl Oynanır'ı tekrar okuyabilirsin."
                )
            ]
        } else {
            return [
                TutorialStep(
                    icon: "text.alignleft",
                    title: "Story Flow",
                    body: "Text appears like a typewriter. If you're impatient, a single tap completes the current line instantly."
                ),
                TutorialStep(
                    icon: "list.bullet",
                    title: "Choices",
                    body: "Options under the text take you to new scenes, clues, and suspects. Some choices cannot be undone."
                ),
                TutorialStep(
                    icon: "rectangle.grid.2x2.fill",
                    title: "Bottom Menu",
                    body: "Five tabs at the bottom: Evidence, Suspects, My Notes, Store, and Menu. Each one helps you keep track of your investigation."
                ),
                TutorialStep(
                    icon: "building.columns.fill",
                    title: "Headquarters",
                    body: "The 'Return to HQ' button under a scene takes you back to Headquarters. From there you can re-interrogate suspects and revisit locations. When you come back to a suspect, you pick up where you left off, not from the beginning."
                ),
                TutorialStep(
                    icon: "checkmark.seal.fill",
                    title: "Interrogation Complete",
                    body: "Once you've asked a suspect everything there is to ask, they turn grey in HQ with an 'Interrogation complete' label. You can still tap them, but unless you bring new evidence they have nothing new to say: 'I have nothing left to say'. When you discover new evidence, previously locked questions may open up, making it worth returning to a finished suspect."
                ),
                TutorialStep(
                    icon: "scalemass.fill",
                    title: "Accusation",
                    body: "Scenes do not have an 'Accuse' option. Accusations can only be made via the 'Make Accusation' button in HQ. Pick the right killer with the right evidence. A wrong accusation loses the case."
                ),
                TutorialStep(
                    icon: "line.3.horizontal",
                    title: "Game Menu",
                    body: "The Menu button opens save & exit, restart for 1 credit, or this 'How to Play' guide again."
                )
            ]
        }
    }
}

// MARK: - Tutorial Bayrak Yonetici (UserDefaults)

enum TutorialFlags {
    private static let caseSelectionKey = "tutorial_case_selection_seen"
    private static let gameKey = "tutorial_game_seen"

    static var hasSeenCaseSelection: Bool {
        UserDefaults.standard.bool(forKey: caseSelectionKey)
    }

    static func markCaseSelectionSeen() {
        UserDefaults.standard.set(true, forKey: caseSelectionKey)
    }

    static var hasSeenGame: Bool {
        UserDefaults.standard.bool(forKey: gameKey)
    }

    static func markGameSeen() {
        UserDefaults.standard.set(true, forKey: gameKey)
    }
}
