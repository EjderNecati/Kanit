import SwiftUI

extension Color {
    // MARK: - Ana Renk Paleti (Noir Tema)

    /// Koyu lacivert - Primary
    static let noirPrimary = Color(hex: "1A1A2E")

    /// Altin/eski kagit - Secondary (zengin vintage altin)
    static let noirSecondary = Color(hex: "D4AF5C")

    /// Kirmizi - Accent (onemli ipuclari, tehlike)
    static let noirAccent = Color(hex: "E74C3C")

    /// Krem beyaz - Text
    static let noirText = Color(hex: "F5F0E8")

    /// Cok koyu - Background (derin siyah)
    static let noirBackground = Color(hex: "0D0D18")

    // MARK: - Yardimci Renkler

    /// Yari saydam koyu (metin kutusu arka plani)
    static let noirTextBox = Color(hex: "1A1A2E").opacity(0.85)

    /// Deaktif/soluk metin (sicak lavanta tonu)
    static let noirMuted = Color(hex: "8A8898")

    /// Basari/yesil
    static let noirSuccess = Color(hex: "2ECC71")

    /// Kredi/elmas rengi (celik mavisi)
    static let noirCredit = Color(hex: "5B8DBE")

    /// Parlak altin - vurgular/shimmer icin
    static let noirGold = Color(hex: "CFAA4C")

    /// Kart/panel yuzey rengi
    static let noirSurface = Color(hex: "161628")

    // MARK: - Hex Init

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
