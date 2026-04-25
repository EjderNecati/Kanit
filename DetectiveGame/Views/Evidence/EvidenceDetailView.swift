import SwiftUI

struct EvidenceDetailView: View {
    let evidenceId: String
    let caseData: Case

    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(spacing: 20) {
                // Delil ikonu
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.noirSecondary)
                    .padding(.top, 40)

                // Delil adi
                Text(evidenceId.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.noirTitle(24))
                    .foregroundColor(.noirText)

                // Aciklama
                Text(loc.s(.evidenceDetail))
                    .font(.noirBody(16))
                    .foregroundColor(.noirMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button(loc.s(.close)) { dismiss() }
                    .font(.noirChoice())
                    .foregroundColor(.noirSecondary)
                    .padding(.bottom, 40)
            }
        }
    }
}
