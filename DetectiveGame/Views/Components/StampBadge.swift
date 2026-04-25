import SwiftUI

struct StampBadge: View {
    let text: String
    var color: Color = .noirAccent
    var rotation: Double = -10

    @State private var isVisible = false

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 22, weight: .black, design: .default))
            .tracking(2)
            .foregroundColor(color)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(maxWidth: 260)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(color, lineWidth: 3)
            )
            .shadow(color: color.opacity(0.25), radius: 3, x: 2, y: 2)
            .rotationEffect(.degrees(rotation))
            .padding(.horizontal, 30)
            .scaleEffect(isVisible ? 1.0 : 0.3)
            .opacity(isVisible ? 1.0 : 0)
            .onAppear {
                // Kucuk gecikme ile animasyon baslat - ilk render'da bozuk gorunmesini onle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        isVisible = true
                    }
                }
            }
    }
}

/// Vaka durum damgasi
struct CaseStamp: View {
    enum StampType {
        case classified
        case solved
        case coldCase

        var color: Color {
            switch self {
            case .classified: return .noirAccent
            case .solved: return .noirSuccess
            case .coldCase: return .noirMuted
            }
        }
    }

    let type: StampType
    @EnvironmentObject var loc: LocalizationManager

    var localizedText: String {
        switch type {
        case .classified: return loc.s(.classified)
        case .solved: return loc.s(.solvedStamp)
        case .coldCase: return loc.s(.coldCase)
        }
    }

    var body: some View {
        StampBadge(text: localizedText, color: type.color)
    }
}
