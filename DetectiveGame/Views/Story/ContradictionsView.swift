import SwiftUI

struct ContradictionsView: View {
    let contradictions: [Contradiction]
    let gameState: GameState
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @State private var caughtId: String? = nil
    @State private var showCaughtAnimation = false

    private var discoveredCount: Int {
        contradictions.filter { gameState.discoveredContradictions.contains($0.id) }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.noirBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Counter
                        counterHeader

                        // Cards
                        ForEach(contradictions) { contra in
                            contradictionCard(contra)
                        }
                    }
                    .padding(20)
                }

                // Caught animation overlay
                if showCaughtAnimation {
                    caughtOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(loc.s(.contradictionsTitle))
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundColor(.noirText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.noirMuted.opacity(0.6))
                    }
                }
            }
            .toolbarBackground(Color.noirBackground.opacity(0.9), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Counter Header

    private var counterHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18))
                .foregroundColor(.noirGold)

            Text(loc.s(.contradictionsFound(discoveredCount)))
                .font(.noirSubtitle(15))
                .foregroundColor(.noirText)

            Spacer()

            Text("\(discoveredCount)/\(contradictions.count)")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(.noirGold)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.noirPrimary.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.noirGold.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Contradiction Card

    private func contradictionCard(_ contra: Contradiction) -> some View {
        let isDiscovered = gameState.discoveredContradictions.contains(contra.id)
        let hasRequiredEvidence = contra.requires.allSatisfy { gameState.collectedEvidence.contains($0) }

        return VStack(alignment: .leading, spacing: 0) {
            if isDiscovered {
                discoveredCard(contra)
            } else if hasRequiredEvidence {
                availableCard(contra)
            } else {
                lockedCard(contra)
            }
        }
    }

    // MARK: - Locked Card

    private func lockedCard(_ contra: Contradiction) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.noirMuted.opacity(0.4))
                Text(loc.s(.contradictionLocked))
                    .font(.noirSubtitle(14))
                    .foregroundColor(.noirMuted.opacity(0.5))
                Spacer()
            }

            // Blurred text placeholders
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.noirMuted.opacity(0.1))
                    .frame(height: 12)
                    .frame(maxWidth: .infinity)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.noirMuted.opacity(0.08))
                    .frame(height: 12)
                    .frame(width: 200, alignment: .leading)
            }

            // Required evidence hint
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundColor(.noirMuted.opacity(0.35))
                let found = contra.requires.filter { gameState.collectedEvidence.contains($0) }.count
                Text("\(found)/\(contra.requires.count)")
                    .font(.noirCaption(11))
                    .foregroundColor(.noirMuted.opacity(0.35))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.noirPrimary.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.noirMuted.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - Available Card

    private func availableCard(_ contra: Contradiction) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Statement 1
            statementView(contra.statement1, side: .leading)

            // VS divider
            HStack {
                Rectangle()
                    .fill(Color.noirAccent.opacity(0.3))
                    .frame(height: 0.5)
                Text(loc.s(.vs))
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.noirAccent)
                    .padding(.horizontal, 8)
                Rectangle()
                    .fill(Color.noirAccent.opacity(0.3))
                    .frame(height: 0.5)
            }

            // Statement 2
            statementView(contra.statement2, side: .trailing)

            // Catch button
            Button(action: { catchContradiction(contra) }) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                    Text(loc.s(.catchContradiction))
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.noirText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.noirAccent.opacity(0.5), Color.noirAccent.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.noirAccent.opacity(0.5), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.noirPrimary.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.noirAccent.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Discovered Card

    private func discoveredCard(_ contra: Contradiction) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.noirSuccess)
                Text(loc.s(.contradictionCaught))
                    .font(.noirSubtitle(14))
                    .foregroundColor(.noirSuccess)
                Spacer()
            }

            // Statement 1
            statementView(contra.statement1, side: .leading)

            HStack {
                Rectangle()
                    .fill(Color.noirSuccess.opacity(0.2))
                    .frame(height: 0.5)
                Text(loc.s(.vs))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.noirSuccess.opacity(0.6))
                    .padding(.horizontal, 6)
                Rectangle()
                    .fill(Color.noirSuccess.opacity(0.2))
                    .frame(height: 0.5)
            }

            // Statement 2
            statementView(contra.statement2, side: .trailing)

            // Result
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.noirGold)
                Text(contra.result.text)
                    .font(.noirBody(13))
                    .foregroundColor(.noirGold)
                    .italic()
                    .lineSpacing(2)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.noirGold.opacity(0.08))
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.noirSuccess.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.noirSuccess.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Statement View

    private func statementView(_ statement: ContraStatement, side: HorizontalAlignment) -> some View {
        VStack(alignment: side, spacing: 4) {
            Text(statement.source)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.noirSecondary)
                .tracking(0.5)

            Text("\"\(statement.text)\"")
                .font(.noirBody(14))
                .foregroundColor(.noirText.opacity(0.85))
                .italic()
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: side == .leading ? .leading : .trailing)
    }

    // MARK: - Caught Overlay

    private var caughtOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.noirGold)

                Text(loc.s(.contradictionCaught))
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(.noirText)
            }
            .scaleEffect(showCaughtAnimation ? 1.0 : 0.5)
            .opacity(showCaughtAnimation ? 1.0 : 0.0)
        }
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.3)) {
                showCaughtAnimation = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                caughtId = nil
            }
        }
    }

    // MARK: - Logic

    private func catchContradiction(_ contra: Contradiction) {
        guard !gameState.discoveredContradictions.contains(contra.id) else { return }

        gameState.discoveredContradictions.append(contra.id)
        caughtId = contra.id

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showCaughtAnimation = true
        }

        // Auto-dismiss overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showCaughtAnimation = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                caughtId = nil
            }
        }
    }
}
