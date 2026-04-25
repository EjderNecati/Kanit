import SwiftUI

struct CameraTimelineView: View {
    let cameraData: CameraData
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedEventIndex: Int = 0

    private var selectedEvent: CameraEvent {
        cameraData.events[selectedEventIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.noirBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Kamera header
                    cameraHeader

                    // Olay detay karti
                    eventDetailCard

                    // Timeline
                    timelineSection

                    // Olay listesi
                    eventList
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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

    // MARK: - Camera Header

    private var cameraHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(cameraData.location)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.noirText)
                Text(cameraData.date)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.noirMuted)
            }

            Spacer()

            // REC indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text(loc.s(.cameraRec))
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(.red)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(Color.red.opacity(0.1))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.noirPrimary.opacity(0.6))
        .overlay(
            // Scanline efekti
            VStack(spacing: 3) {
                ForEach(0..<15, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.015))
                        .frame(height: 1)
                }
            }
        )
    }

    // MARK: - Event Detail

    private var eventDetailCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(selectedEvent.time)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.noirSecondary)

                if selectedEvent.isKey {
                    Text(loc.s(.keyEvent))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.noirBackground)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.noirSecondary))
                }

                Spacer()

                Text(selectedEvent.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.noirText)
            }

            Text(selectedEvent.detail)
                .font(.noirBody(13))
                .foregroundColor(.noirText.opacity(0.8))
                .lineSpacing(3)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.noirPrimary.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            selectedEvent.isKey
                                ? Color.noirSecondary.opacity(0.3)
                                : Color.white.opacity(0.05),
                            lineWidth: 0.5
                        )
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        GeometryReader { geo in
            let width = geo.size.width - 32
            ZStack(alignment: .leading) {
                // Arka plan cizgi
                Rectangle()
                    .fill(Color.noirMuted.opacity(0.2))
                    .frame(height: 3)
                    .padding(.horizontal, 16)

                // Event marker'lari
                ForEach(Array(cameraData.events.enumerated()), id: \.offset) { index, event in
                    let xPos = CGFloat(event.position) / 100.0 * width + 16
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedEventIndex = index
                        }
                    }) {
                        Circle()
                            .fill(markerColor(event: event, isSelected: index == selectedEventIndex))
                            .frame(
                                width: index == selectedEventIndex ? 14 : 10,
                                height: index == selectedEventIndex ? 14 : 10
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        index == selectedEventIndex
                                            ? Color.noirSecondary
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                                    .frame(width: 18, height: 18)
                            )
                    }
                    .buttonStyle(.plain)
                    .position(x: xPos, y: geo.size.height / 2)
                }
            }
        }
        .frame(height: 40)
        .padding(.top, 12)
    }

    private func markerColor(event: CameraEvent, isSelected: Bool) -> Color {
        if isSelected { return .noirSecondary }
        if event.isKey { return .noirAccent }
        return .noirMuted.opacity(0.5)
    }

    // MARK: - Event List

    private var eventList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 2) {
                ForEach(Array(cameraData.events.enumerated()), id: \.offset) { index, event in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedEventIndex = index
                        }
                    }) {
                        HStack(spacing: 10) {
                            // Saat
                            Text(event.time)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(index == selectedEventIndex ? .noirSecondary : .noirMuted)
                                .frame(width: 44, alignment: .leading)

                            // Key indicator
                            Circle()
                                .fill(event.isKey ? Color.noirSecondary : Color.noirMuted.opacity(0.3))
                                .frame(width: 6, height: 6)

                            // Label
                            Text(event.label)
                                .font(.system(size: 13, weight: index == selectedEventIndex ? .semibold : .regular))
                                .foregroundColor(index == selectedEventIndex ? .noirText : .noirMuted)

                            Spacer()

                            if event.isKey {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.noirSecondary.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            index == selectedEventIndex
                                ? Color.noirSecondary.opacity(0.08)
                                : Color.clear
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 8)
    }
}
