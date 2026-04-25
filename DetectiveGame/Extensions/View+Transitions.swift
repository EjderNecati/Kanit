import SwiftUI

// MARK: - Ozel Gecis Animasyonlari

extension AnyTransition {
    /// Sahne gecisi - fade in/out
    static var sceneFade: AnyTransition {
        .opacity.animation(.easeInOut(duration: 0.5))
    }

    /// Alt'tan slide-up (delil popup, secenekler)
    static var slideUp: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }

    /// Seceneklerin staggered girisi icin
    static var choiceAppear: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        )
    }

    /// Dramatik fade-to-black (suclama sahnesi)
    static var dramaticFade: AnyTransition {
        .opacity.animation(.easeInOut(duration: 1.0))
    }
}

// MARK: - View Modifier'lar

extension View {
    /// Staggered animasyon (sirali gorunum)
    func staggeredAppear(index: Int, delay: Double = 0.1) -> some View {
        self
            .animation(
                .spring(response: 0.4, dampingFraction: 0.8)
                    .delay(Double(index) * delay),
                value: index
            )
    }

    /// Noir golge efekti
    func noirShadow() -> some View {
        self.shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 3)
    }

    /// Pulse animasyonu (delil bulma)
    func pulseAnimation(_ isAnimating: Bool) -> some View {
        self
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .animation(
                isAnimating
                    ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                    : .default,
                value: isAnimating
            )
    }

    /// Sinematik gorsel iyilestirme (noir ton, vignette)
    func cinematicEnhancement() -> some View {
        self
            .overlay(
                ZStack {
                    // Vignette + soguk mavi ton (tek katman)
                    RadialGradient(
                        colors: [
                            Color(hex: "0A1628").opacity(0.05),
                            Color(hex: "0A1628").opacity(0.1),
                            Color.black.opacity(0.2),
                            Color.black.opacity(0.45)
                        ],
                        center: .center,
                        startRadius: 150,
                        endRadius: 500
                    )
                }
                .allowsHitTesting(false)
            )
    }
}
