import SwiftUI

struct PaperBackground: View {
    var opacity: Double = 0.15
    var showVignette: Bool = true

    private struct GrainDot {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
    }

    @State private var dots: [GrainDot] = []

    var body: some View {
        ZStack {
            // Ana koyu arka plan
            Color.noirBackground
                .ignoresSafeArea()

            // Kagit dokusu efekti (grain) - onceden hesaplanmis
            Canvas { context, size in
                // Grain noktalar
                for dot in dots {
                    let rect = CGRect(
                        x: dot.x * size.width,
                        y: dot.y * size.height,
                        width: dot.size,
                        height: dot.size
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.white.opacity(dot.opacity))
                    )
                }
            }
            .ignoresSafeArea()
            .opacity(opacity)

            // Vignette efekti - kenarlardan kararan radial gradient
            if showVignette {
                Canvas { context, size in
                    let center = CGPoint(x: size.width * 0.5, y: size.height * 0.45)
                    let maxRadius = max(size.width, size.height) * 0.8
                    let vignetteGradient = Gradient(colors: [
                        Color.clear,
                        Color.clear,
                        Color.noirBackground.opacity(0.3),
                        Color.noirBackground.opacity(0.7)
                    ])
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .radialGradient(
                            vignetteGradient,
                            center: center,
                            startRadius: maxRadius * 0.3,
                            endRadius: maxRadius
                        )
                    )
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .onAppear {
            if dots.isEmpty {
                dots = (0..<30).map { _ in
                    GrainDot(
                        x: CGFloat.random(in: 0...1),
                        y: CGFloat.random(in: 0...1),
                        size: CGFloat.random(in: 0.5...2.0),
                        opacity: Double.random(in: 0.02...0.08)
                    )
                }
            }
        }
    }
}

/// Metin kutusu icin eski kagit gorunumlu arka plan
struct TextBoxBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [
                        Color.noirPrimary.opacity(0.9),
                        Color.noirPrimary.opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.noirSecondary.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 3, y: 3)
    }
}
