import SwiftUI

extension Font {
    // MARK: - Noir Tema Fontlari

    /// Baslik fontu - bold sans-serif
    static func noirTitle(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    /// Alt baslik
    static func noirSubtitle(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    /// Ana metin - serif (hikaye metni icin)
    static func noirBody(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    /// Diyalog metni - serif italic
    static func noirDialogue(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    /// Secim butonu metni
    static func noirChoice(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .medium, design: .serif)
    }

    /// Kucuk etiket/badge metni
    static func noirCaption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    /// Typewriter efekti icin monospace
    static func noirTypewriter(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }
}
