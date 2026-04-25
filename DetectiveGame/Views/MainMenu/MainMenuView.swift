import SwiftUI

struct MainMenuView: View {
    @ObservedObject var playerProfile: PlayerProfile
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var loc: LocalizationManager

    @State private var titleOpacity: Double = 0
    @State private var titleScale: Double = 0.92
    @State private var buttonsOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 30
    @State private var showContinue: Bool = false
    @State private var iconGlow: Bool = false
    @State private var bgImage: UIImage?

    var body: some View {
        ZStack {
            // MARK: - Arka plan gorsel + overlay (Vercel tarzi)
            if let bgImage = bgImage {
                Image(uiImage: bgImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .brightness(-0.3)
                    .saturation(0.7)
                    .ignoresSafeArea()
            } else {
                PaperBackground()
            }

            // Koyu gradient overlay
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.04, green: 0.04, blue: 0.06).opacity(0.4), location: 0),
                    .init(color: Color(red: 0.04, green: 0.04, blue: 0.06).opacity(0.1), location: 0.3),
                    .init(color: Color(red: 0.04, green: 0.04, blue: 0.06).opacity(0.05), location: 0.45),
                    .init(color: Color(red: 0.04, green: 0.04, blue: 0.06).opacity(0.2), location: 0.6),
                    .init(color: Color(red: 0.04, green: 0.04, blue: 0.06).opacity(0.85), location: 0.8),
                    .init(color: Color(red: 0.04, green: 0.04, blue: 0.06).opacity(0.98), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Vignette efekti
            RadialGradient(
                colors: [
                    Color.clear,
                    Color(red: 0.04, green: 0.04, blue: 0.06).opacity(0.75)
                ],
                center: .center,
                startRadius: 150,
                endRadius: 500
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Suzen toz parcaciklari
            FloatingDustView()

            // Ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.noirSecondary.opacity(0.04), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .position(x: 50, y: UIScreen.main.bounds.height * 0.2)
                .opacity(iconGlow ? 1.0 : 0.5)
                .allowsHitTesting(false)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.noirSecondary.opacity(0.04), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .position(x: UIScreen.main.bounds.width - 30, y: UIScreen.main.bounds.height * 0.85)
                .opacity(iconGlow ? 0.5 : 1.0)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                // MARK: - Logo / Baslik
                VStack(spacing: 12) {
                    // Buyutec ikonu + glow
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.noirSecondary.opacity(iconGlow ? 0.18 : 0.08),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)

                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 52, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.noirSecondary, Color.noirGold],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.noirSecondary.opacity(0.4), radius: 20)
                    }

                    // Oyun adi
                    Text("KANIT")
                        .font(.system(size: 44, weight: .black, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.96, green: 0.94, blue: 0.91), Color(red: 0.96, green: 0.94, blue: 0.91).opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .tracking(8)
                        .shadow(color: .black.opacity(0.8), radius: 30, y: 2)

                    // Suslemeli ayirici cizgi
                    HStack(spacing: 10) {
                        OrnamentalLine()
                        Circle()
                            .fill(Color.noirSecondary)
                            .frame(width: 5, height: 5)
                            .shadow(color: Color.noirSecondary.opacity(0.5), radius: 8)
                        OrnamentalLine(reversed: true)
                    }
                    .frame(width: 200)
                    .padding(.vertical, 8)

                    // Tagline
                    Text(loc.s(.tagline))
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                        .foregroundColor(Color(red: 0.98, green: 0.96, blue: 0.93))
                        .tracking(2)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black, radius: 2, y: 0)
                        .shadow(color: .black.opacity(0.9), radius: 8, y: 2)

                    // Alt tagline
                    Text(loc.language == .turkish
                         ? "Her ipucu seni gerçeğe bir adım daha yaklaştırır..."
                         : "Every clue brings you one step closer to the truth...")
                        .font(.system(size: 15, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(Color.noirSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                        .padding(.top, 4)
                        .shadow(color: .black, radius: 2, y: 0)
                        .shadow(color: .black.opacity(0.9), radius: 8, y: 2)
                }
                .opacity(titleOpacity)
                .scaleEffect(titleScale)

                Spacer()
                Spacer()

                // MARK: - Tek Premium Start Butonu
                StartButton(title: loc.s(.start)) {
                    navigationPath.append(AppRoute.caseSelection)
                }
                .opacity(buttonsOpacity)
                .offset(y: buttonsOffset)

                Spacer()

                // MARK: - Alt Bilgi (sadece dil)
                HStack {
                    Spacer()

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            loc.language = loc.language == .turkish ? .english : .turkish
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "globe")
                                .font(.system(size: 14))
                            Text(loc.language == .turkish ? "EN" : "TR")
                                .font(.noirCaption(13))
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.noirSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.noirPrimary.opacity(0.8))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.noirSecondary.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .opacity(buttonsOpacity)
            }
        }
        .onAppear {
            loadBackgroundImage()
            checkForSavedGames()
            animateEntrance()
        }
    }

    private func loadBackgroundImage() {
        if let url = Bundle.main.url(forResource: "landing-bg", withExtension: "jpg", subdirectory: "Cases/demo-case/images"),
           let data = try? Data(contentsOf: url) {
            bgImage = UIImage(data: data)
        }
    }

    private func checkForSavedGames() {
        showContinue = SaveManager.hasAnySave(for: playerProfile.unlockedCases)
    }

    private func animateEntrance() {
        withAnimation(.easeOut(duration: 1.2)) {
            titleOpacity = 1.0
            titleScale = 1.0
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
            buttonsOpacity = 1.0
            buttonsOffset = 0
        }
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(1.0)) {
            iconGlow = true
        }
    }
}

// MARK: - Suslemeli Cizgi

private struct OrnamentalLine: View {
    var reversed: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            if reversed {
                Circle()
                    .fill(Color.noirSecondary.opacity(0.6))
                    .frame(width: 3, height: 3)
            }
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: reversed
                            ? [Color.noirSecondary.opacity(0.5), Color.clear]
                            : [Color.clear, Color.noirSecondary.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
            if !reversed {
                Circle()
                    .fill(Color.noirSecondary.opacity(0.6))
                    .frame(width: 3, height: 3)
            }
        }
    }
}

// MARK: - Suzen Toz Parcaciklari

private struct FloatingDustView: View {
    @State private var particles: [DustParticle] = []
    @State private var animate = false

    private struct DustParticle: Identifiable {
        let id = UUID()
        let x: CGFloat
        let startY: CGFloat
        let size: CGFloat
        let opacity: Double
        let duration: Double
        let delay: Double
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { p in
                Circle()
                    .fill(Color.noirSecondary.opacity(p.opacity))
                    .frame(width: p.size, height: p.size)
                    .position(
                        x: p.x * geo.size.width,
                        y: animate
                            ? p.startY * geo.size.height - 60
                            : p.startY * geo.size.height + 60
                    )
                    .animation(
                        .easeInOut(duration: p.duration)
                            .repeatForever(autoreverses: true)
                            .delay(p.delay),
                        value: animate
                    )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            if particles.isEmpty {
                particles = (0..<20).map { _ in
                    DustParticle(
                        x: CGFloat.random(in: 0.05...0.95),
                        startY: CGFloat.random(in: 0.1...0.9),
                        size: CGFloat.random(in: 1.0...2.5),
                        opacity: Double.random(in: 0.08...0.25),
                        duration: Double.random(in: 6...12),
                        delay: Double.random(in: 0...4)
                    )
                }
            }
            animate = true
        }
    }
}

// MARK: - Menu Butonu

enum MenuButtonStyle {
    case primary
    case standard
    case credit
}

struct MenuButton: View {
    let title: String
    let icon: String
    var style: MenuButtonStyle = .standard
    let action: () -> Void

    @State private var isPressed = false

    private var accentColor: Color {
        switch style {
        case .primary: return .noirSecondary
        case .standard: return .noirSecondary
        case .credit: return .noirCredit
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.9), accentColor.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3)
                    .padding(.vertical, 8)

                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(accentColor)
                        .frame(width: 24)

                    Text(title)
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundColor(.noirText)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.noirMuted.opacity(0.5))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0.04, green: 0.04, blue: 0.06).opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(accentColor.opacity(0.15), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 32)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Premium Start Butonu

struct StartButton: View {
    let title: String
    let action: () -> Void

    @State private var isPressed = false
    @State private var breathe = false

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .tracking(4)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.99, green: 0.96, blue: 0.88),
                                Color.noirSecondary
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.noirSecondary.opacity(0.9))
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    Capsule()
                        .fill(Color.noirSecondary.opacity(breathe ? 0.22 : 0.12))
                        .blur(radius: 12)
                        .scaleEffect(breathe ? 1.08 : 1.0)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.09, green: 0.08, blue: 0.11),
                                    Color(red: 0.05, green: 0.05, blue: 0.07)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.noirSecondary.opacity(0.7),
                                    Color.noirGold.opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.5), radius: 10, y: 4)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .fixedSize()
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }
}
