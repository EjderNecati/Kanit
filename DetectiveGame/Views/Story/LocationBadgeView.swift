import SwiftUI

struct LocationBadgeView: View {
    let locationName: String
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.noirSecondary)

            Text(locationName.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.noirSecondary.opacity(0.9))
                .tracking(1.5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.noirPrimary.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.noirSecondary.opacity(0.3), lineWidth: 0.5)
                )
                .shadow(color: Color.noirSecondary.opacity(0.15), radius: 4, y: 2)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -10)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                isVisible = true
            }
            // 2.5 saniye sonra kaybol
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeIn(duration: 0.3)) {
                    isVisible = false
                }
            }
        }
    }
}
