import SwiftUI

// MARK: - Sahne Mood Sistemi

enum SceneMood {
    case nightExterior
    case warmInterior
    case coldOfficial
    case medicalClinical
    case culturalElegant
    case casualPublic
    case industrial
    case securityTech
    case office
    case outdoorDay

    static func from(backgroundName: String) -> SceneMood {
        let name = backgroundName.lowercased()

        if name.contains("gece") || name == "blackmoor_dis" {
            return .nightExterior
        }
        if name.contains("yali") || name.contains("villa") || name.contains("malikane") || name.contains("salon") {
            return .warmInterior
        }
        if name.contains("karakol") || name.contains("emniyet") || name.contains("polis") || name.contains("mahkeme") {
            return .coldOfficial
        }
        if name.contains("hastane") || name.contains("eczane") || name == "ward" || name == "lab" {
            return .medicalClinical
        }
        if name.contains("galeri") || name.contains("chapel") || name.contains("kilise")
            || name.contains("gala") || name.contains("muzayede") || name.contains("restorasyon") {
            return .culturalElegant
        }
        if name.contains("kafe") || name.contains("otel") || name.contains("antikaci") || name.contains("restoran") {
            return .casualPublic
        }
        if name.contains("depo") || name.contains("santiye") || name.contains("nakliye")
            || name.contains("benzin") || name.contains("liman") {
            return .industrial
        }
        if name.contains("guvenlik") || name.contains("güvenlik") || name.contains("kumarhane")
            || name.contains("muhasebe") || name.contains("kasa") {
            return .securityTech
        }
        if name.contains("ofis") || name.contains("pemberton") {
            return .office
        }
        if name.contains("garden") || name.contains("minibus") {
            return .outdoorDay
        }

        return .nightExterior
    }

    var palette: MoodPalette {
        switch self {
        case .nightExterior:
            return MoodPalette(
                gradientColors: [Color(hex: "050510"), Color(hex: "0A1628"), Color(hex: "0F1B3D"), Color(hex: "080E1E")],
                gradientStart: .top,
                gradientEnd: .bottom,
                accentColor: Color(hex: "4A6FA5"),
                particleColor: Color(hex: "8AAAD0"),
                icon: "moon.stars"
            )
        case .warmInterior:
            return MoodPalette(
                gradientColors: [Color(hex: "1A150E"), Color(hex: "1E1610"), Color(hex: "1A1A2E"), Color(hex: "12100A")],
                gradientStart: .topLeading,
                gradientEnd: .bottomTrailing,
                accentColor: Color(hex: "C4A35A"),
                particleColor: Color(hex: "D4B96A"),
                icon: "lamp.desk"
            )
        case .coldOfficial:
            return MoodPalette(
                gradientColors: [Color(hex: "0E1018"), Color(hex: "12141E"), Color(hex: "1A1C2A"), Color(hex: "0C0E16")],
                gradientStart: .top,
                gradientEnd: .bottom,
                accentColor: Color(hex: "6A8CAA"),
                particleColor: Color(hex: "7A9CBA"),
                icon: "building.columns"
            )
        case .medicalClinical:
            return MoodPalette(
                gradientColors: [Color(hex: "0A1414"), Color(hex: "0D1A1A"), Color(hex: "101820"), Color(hex: "0A1210")],
                gradientStart: .topLeading,
                gradientEnd: .bottomTrailing,
                accentColor: Color(hex: "4A9A7A"),
                particleColor: Color(hex: "5AAA8A"),
                icon: "cross.case"
            )
        case .culturalElegant:
            return MoodPalette(
                gradientColors: [Color(hex: "120E1E"), Color(hex: "15102A"), Color(hex: "1A1A2E"), Color(hex: "100C1A")],
                gradientStart: .top,
                gradientEnd: .bottom,
                accentColor: Color(hex: "B8A040"),
                particleColor: Color(hex: "C8B050"),
                icon: "theatermasks"
            )
        case .casualPublic:
            return MoodPalette(
                gradientColors: [Color(hex: "141210"), Color(hex: "181410"), Color(hex: "1A1A2E"), Color(hex: "12100E")],
                gradientStart: .topLeading,
                gradientEnd: .bottomTrailing,
                accentColor: Color(hex: "C89840"),
                particleColor: Color(hex: "D8A850"),
                icon: "cup.and.saucer"
            )
        case .industrial:
            return MoodPalette(
                gradientColors: [Color(hex: "0E0E10"), Color(hex: "101215"), Color(hex: "1A1A1A"), Color(hex: "0C0C0E")],
                gradientStart: .top,
                gradientEnd: .bottom,
                accentColor: Color(hex: "8A6A40"),
                particleColor: Color(hex: "9A7A50"),
                icon: "shippingbox"
            )
        case .securityTech:
            return MoodPalette(
                gradientColors: [Color(hex: "060810"), Color(hex: "0A0C14"), Color(hex: "10141E"), Color(hex: "080A12")],
                gradientStart: .topLeading,
                gradientEnd: .bottomTrailing,
                accentColor: Color(hex: "40AA60"),
                particleColor: Color(hex: "50BA70"),
                icon: "video"
            )
        case .office:
            return MoodPalette(
                gradientColors: [Color(hex: "0E1018"), Color(hex: "10121E"), Color(hex: "1A1A2E"), Color(hex: "0C0E16")],
                gradientStart: .top,
                gradientEnd: .bottom,
                accentColor: Color(hex: "A08840"),
                particleColor: Color(hex: "B09850"),
                icon: "doc.text"
            )
        case .outdoorDay:
            return MoodPalette(
                gradientColors: [Color(hex: "0C120E"), Color(hex: "0E1510"), Color(hex: "141A28"), Color(hex: "0A100C")],
                gradientStart: .top,
                gradientEnd: .bottom,
                accentColor: Color(hex: "5A9A5A"),
                particleColor: Color(hex: "6AAA6A"),
                icon: "leaf"
            )
        }
    }
}

struct MoodPalette {
    let gradientColors: [Color]
    let gradientStart: UnitPoint
    let gradientEnd: UnitPoint
    let accentColor: Color
    let particleColor: Color
    let icon: String
}

// MARK: - Onceden hesaplanmis parcacik
private struct Particle {
    let x: CGFloat // 0...1 oraninda
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
}

// MARK: - Atmosferik Arka Plan

struct AtmosphericBackground: View {
    let backgroundName: String

    private var mood: SceneMood { .from(backgroundName: backgroundName) }
    private var palette: MoodPalette { mood.palette }

    // Parcaciklar bir kez hesaplanir, her frame'de tekrar hesaplanmaz
    @State private var particles: [Particle] = []

    var body: some View {
        // Tek Canvas - 6 katman yerine 1 katman (gradient + glow + parcacik)
        Canvas { context, size in
            let colors = palette.gradientColors
            // 1. Base gradient
            let baseGradient = Gradient(colors: colors)
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    baseGradient,
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )

            // 2. Radial glow (tek tane, hafif)
            let glowCenter = CGPoint(x: size.width * 0.8, y: size.height * 0.2)
            let glowGradient = Gradient(colors: [
                palette.accentColor.opacity(0.08),
                Color.clear
            ])
            context.fill(
                Path(ellipseIn: CGRect(
                    x: glowCenter.x - 200, y: glowCenter.y - 200,
                    width: 400, height: 400
                )),
                with: .radialGradient(
                    glowGradient,
                    center: glowCenter,
                    startRadius: 20,
                    endRadius: 200
                )
            )

            // 3. Parcaciklar (25 adet - azaltildi)
            let particleColor = palette.particleColor
            for p in particles {
                let rect = CGRect(
                    x: p.x * size.width,
                    y: p.y * size.height,
                    width: p.size,
                    height: p.size
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(particleColor.opacity(p.opacity))
                )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if particles.isEmpty {
                particles = (0..<25).map { _ in
                    Particle(
                        x: CGFloat.random(in: 0...1),
                        y: CGFloat.random(in: 0...1),
                        size: CGFloat.random(in: 0.5...2.5),
                        opacity: Double.random(in: 0.02...0.07)
                    )
                }
            }
        }
    }
}
