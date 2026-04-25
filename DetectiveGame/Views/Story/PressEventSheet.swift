import SwiftUI

struct PressEventSheet: View {
    let event: PressEvent
    let onChoose: (Int) -> Void
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.noirBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Baslik
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.noirSecondary)

                    Text(loc.s(.pressConference))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.noirSecondary)
                        .tracking(1)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // Muhabir bilgisi
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.noirMuted)
                    Text(event.reporterName)
                        .font(.noirCaption(12))
                        .foregroundColor(.noirText)
                    Text("·")
                        .foregroundColor(.noirMuted)
                    Text(event.outlet)
                        .font(.noirCaption(11))
                        .foregroundColor(.noirMuted)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Soru
                Text(event.question)
                    .font(.noirBody(16))
                    .foregroundColor(.noirText)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                // Secenekler
                VStack(spacing: 10) {
                    ForEach(Array(event.options.enumerated()), id: \.offset) { index, option in
                        Button(action: {
                            onChoose(index)
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                Text(option.text)
                                    .font(.noirChoice())
                                    .foregroundColor(.noirText)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                // Itibar etkisi gostergesi
                                HStack(spacing: 2) {
                                    Image(systemName: option.reputationDelta >= 0 ? "arrow.up" : "arrow.down")
                                        .font(.system(size: 10))
                                    Text("\(abs(option.reputationDelta))")
                                        .font(.system(size: 11, weight: .bold))
                                }
                                .foregroundColor(option.reputationDelta >= 0
                                    ? Color(hex: "50A070")
                                    : Color(hex: "E05050"))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.noirPrimary.opacity(0.7))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.noirSecondary.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)

                Spacer()
            }
        }
        .presentationDetents([.medium])
    }
}
