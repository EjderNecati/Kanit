import SwiftUI

struct TransitionView: View {
    let isActive: Bool

    var body: some View {
        if isActive {
            Color.black
                .ignoresSafeArea()
                .transition(.opacity)
        }
    }
}
