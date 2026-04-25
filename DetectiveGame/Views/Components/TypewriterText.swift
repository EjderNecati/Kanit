import SwiftUI

struct TypewriterText: View {
    let fullText: String
    let font: Font
    let color: Color
    var speed: Double = 0.04
    var onComplete: (() -> Void)? = nil

    @State private var displayedCount: Int = 0
    @State private var isComplete: Bool = false
    @State private var timer: Timer? = nil

    var body: some View {
        Text(String(fullText.prefix(displayedCount)))
            .font(font)
            .foregroundColor(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .onAppear {
                startTyping()
            }
            .onDisappear {
                stopTimer()
            }
            .onTapGesture {
                skipToEnd()
            }
            .onChange(of: fullText) { _ in
                stopTimer()
                displayedCount = 0
                isComplete = false
                startTyping()
            }
    }

    private func startTyping() {
        guard !fullText.isEmpty else {
            isComplete = true
            onComplete?()
            return
        }

        displayedCount = 0
        isComplete = false

        timer = Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { t in
            let chunkSize = min(2, fullText.count - displayedCount)
            displayedCount += chunkSize

            if displayedCount >= fullText.count {
                t.invalidate()
                timer = nil
                isComplete = true
                onComplete?()
            }
        }
    }

    private func skipToEnd() {
        stopTimer()
        displayedCount = fullText.count
        isComplete = true
        onComplete?()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
