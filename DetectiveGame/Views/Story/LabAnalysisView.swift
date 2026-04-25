import SwiftUI

struct LabAnalysisView: View {
    let labAnalyses: [LabAnalysis]
    let gameState: GameState
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedAnalysis: LabAnalysis? = nil
    @State private var currentStep = 0
    @State private var isAnalyzing = false
    @State private var isComplete = false
    @State private var progress: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.noirBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if let analysis = selectedAnalysis {
                            analysisProgressView(analysis)
                        } else {
                            analysisListView
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(loc.s(.labTitle))
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

    // MARK: - Analysis List

    private var analysisListView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "flask.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.noirSecondary)
                Text(loc.s(.labSelectAnalysis))
                    .font(.noirBody(15))
                    .foregroundColor(.noirMuted)
            }

            ForEach(labAnalyses) { analysis in
                let isCompleted = gameState.completedLabAnalyses.contains(analysis.id)

                Button(action: {
                    if !isCompleted {
                        selectedAnalysis = analysis
                        startAnalysis(analysis)
                    }
                }) {
                    HStack(spacing: 14) {
                        Image(systemName: analysis.sampleIcon)
                            .font(.system(size: 22))
                            .foregroundColor(isCompleted ? .noirSuccess : .noirSecondary)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(isCompleted ? Color.noirSuccess.opacity(0.15) : Color.noirSecondary.opacity(0.1))
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(analysis.title)
                                .font(.noirSubtitle(15))
                                .foregroundColor(.noirText)

                            if isCompleted {
                                Text(loc.s(.labComplete))
                                    .font(.noirCaption(12))
                                    .foregroundColor(.noirSuccess)
                            } else {
                                Text("\(analysis.steps.count) \(loc.s(.labAnalyzing))")
                                    .font(.noirCaption(12))
                                    .foregroundColor(.noirMuted)
                            }
                        }

                        Spacer()

                        if isCompleted {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.noirSuccess)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.noirMuted.opacity(0.4))
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.noirPrimary.opacity(isCompleted ? 0.3 : 0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        isCompleted ? Color.noirSuccess.opacity(0.2) : Color.noirSecondary.opacity(0.1),
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(isCompleted)
            }
        }
    }

    // MARK: - Analysis Progress

    private func analysisProgressView(_ analysis: LabAnalysis) -> some View {
        VStack(spacing: 24) {
            // Sample icon
            Image(systemName: analysis.sampleIcon)
                .font(.system(size: 40))
                .foregroundColor(.noirSecondary)
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(Color.noirSecondary.opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(Color.noirSecondary.opacity(0.3), lineWidth: 1)
                        )
                )

            Text(analysis.title)
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundColor(.noirText)

            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.noirPrimary)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color.noirSecondary, Color.noirGold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 8)

                Text(isComplete ? "100%" : "\(Int(progress * 100))%")
                    .font(.noirCaption(12))
                    .foregroundColor(.noirMuted)
            }

            // Steps
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(analysis.steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 12) {
                        // Status icon
                        Group {
                            if index < currentStep {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.noirSuccess)
                            } else if index == currentStep && isAnalyzing {
                                Image(systemName: "arrow.trianglehead.2.counterclockwise")
                                    .foregroundColor(.noirSecondary)
                                    .rotationEffect(.degrees(isAnalyzing ? 360 : 0))
                                    .animation(
                                        .linear(duration: 1).repeatForever(autoreverses: false),
                                        value: isAnalyzing
                                    )
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.noirMuted.opacity(0.3))
                            }
                        }
                        .font(.system(size: 16))
                        .frame(width: 20)

                        Text(step)
                            .font(.noirBody(14))
                            .foregroundColor(
                                index <= currentStep ? .noirText : .noirMuted.opacity(0.4)
                            )

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.noirPrimary.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.noirSecondary.opacity(0.1), lineWidth: 1)
                    )
            )

            // Result card (when complete)
            if isComplete {
                resultCard(analysis)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Result Card

    private func resultCard(_ analysis: LabAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.noirSuccess)
                Text(analysis.resultTitle)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(.noirSuccess)
            }

            Text(analysis.resultText)
                .font(.noirBody(14))
                .foregroundColor(.noirText.opacity(0.85))
                .lineSpacing(3)

            Divider()
                .background(Color.noirSuccess.opacity(0.2))

            HStack(spacing: 6) {
                Image(systemName: "note.text")
                    .font(.system(size: 12))
                    .foregroundColor(.noirSecondary)
                Text(analysis.resultNote)
                    .font(.noirCaption(12))
                    .foregroundColor(.noirSecondary)
                    .italic()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.noirSuccess.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.noirSuccess.opacity(0.25), lineWidth: 1)
                )
        )
    }

    // MARK: - Logic

    private func startAnalysis(_ analysis: LabAnalysis) {
        isAnalyzing = true
        isComplete = false
        currentStep = 0
        progress = 0

        let stepCount = analysis.steps.count
        let stepDuration = Double(analysis.duration) / Double(stepCount) / 1000.0

        func advanceStep() {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration) {
                if currentStep < stepCount - 1 {
                    withAnimation {
                        currentStep += 1
                        progress = Double(currentStep + 1) / Double(stepCount)
                    }
                    advanceStep()
                } else {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        progress = 1.0
                        isAnalyzing = false
                        isComplete = true
                    }
                    // Update game state
                    gameState.completedLabAnalyses.append(analysis.id)
                    gameState.addNote(for: "lab", note: analysis.resultNote)
                }
            }
        }

        withAnimation {
            progress = 1.0 / Double(stepCount)
        }
        advanceStep()
    }
}
