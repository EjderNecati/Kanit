import SwiftUI

struct PhoneModalView: View {
    let phoneData: PhoneData
    let caseId: String
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0 // 0=messages, 1=calls
    @State private var expandedThread: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.noirBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Telefon header
                    phoneHeader

                    // Tab bar
                    tabBar

                    // Icerik
                    ScrollView(showsIndicators: false) {
                        if selectedTab == 0 {
                            messagesContent
                        } else {
                            callsContent
                        }
                    }
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

    // MARK: - Phone Header

    private var phoneHeader: some View {
        VStack(spacing: 4) {
            Image(systemName: "iphone")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(.noirSecondary)

            Text(phoneData.owner)
                .font(.system(size: 16, weight: .bold, design: .serif))
                .foregroundColor(.noirText)

            Text(loc.s(.phoneTitle))
                .font(.noirCaption(11))
                .foregroundColor(.noirMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.noirPrimary.opacity(0.4))
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(title: loc.s(.messagesTab), icon: "message.fill", index: 0)
            tabButton(title: loc.s(.callsTab), icon: "phone.fill", index: 1)
        }
        .background(Color.noirPrimary.opacity(0.3))
    }

    private func tabButton(title: String, icon: String, index: Int) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = index }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(selectedTab == index ? .noirSecondary : .noirMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                selectedTab == index
                    ? Color.noirSecondary.opacity(0.1)
                    : Color.clear
            )
            .overlay(alignment: .bottom) {
                if selectedTab == index {
                    Rectangle()
                        .fill(Color.noirSecondary)
                        .frame(height: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Messages

    private var messagesContent: some View {
        LazyVStack(spacing: 12) {
            ForEach(phoneData.messages) { thread in
                VStack(spacing: 0) {
                    // Thread header
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            expandedThread = expandedThread == thread.id ? nil : thread.id
                        }
                    }) {
                        HStack(spacing: 10) {
                            // Avatar
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.noirSurface, Color.noirPrimary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(thread.contact.prefix(1)).uppercased())
                                        .font(.system(size: 16, weight: .bold, design: .serif))
                                        .foregroundColor(.noirSecondary)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(thread.contact)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.noirText)
                                Text(thread.date)
                                    .font(.noirCaption(11))
                                    .foregroundColor(.noirMuted)
                            }

                            Spacer()

                            Text(thread.time)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.noirMuted)

                            Image(systemName: expandedThread == thread.id ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10))
                                .foregroundColor(.noirMuted)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)

                    // Messages (expanded)
                    if expandedThread == thread.id {
                        VStack(spacing: 8) {
                            ForEach(Array(thread.messages.enumerated()), id: \.offset) { _, msg in
                                messageBubble(msg: msg, isOwner: isOwnerMessage(msg.from))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.bottom, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.noirPrimary.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                        )
                )
            }
        }
        .padding(16)
    }

    private func messageBubble(msg: PhoneMessage, isOwner: Bool) -> some View {
        HStack {
            if isOwner { Spacer(minLength: 60) }

            VStack(alignment: isOwner ? .trailing : .leading, spacing: 2) {
                Text(msg.text)
                    .font(.noirBody(13))
                    .foregroundColor(isOwner ? .noirText : .noirText.opacity(0.9))

                Text(msg.time)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.noirMuted.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isOwner
                          ? Color.noirSecondary.opacity(0.15)
                          : Color.noirSurface.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isOwner ? Color.noirSecondary.opacity(0.2) : Color.white.opacity(0.04),
                                lineWidth: 0.5
                            )
                    )
            )

            if !isOwner { Spacer(minLength: 60) }
        }
    }

    private func isOwnerMessage(_ from: String) -> Bool {
        // Owner'in ilk ismini kucuk harfle kontrol et
        let ownerFirst = phoneData.owner.split(separator: " ").first?.lowercased() ?? ""
        return from.lowercased() == ownerFirst
    }

    // MARK: - Calls

    private var callsContent: some View {
        LazyVStack(spacing: 2) {
            ForEach(Array(phoneData.callLog.enumerated()), id: \.offset) { _, call in
                HStack(spacing: 12) {
                    // Call type icon
                    callTypeIcon(call.type)
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(call.contact)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(call.type == "missed" ? .noirAccent : .noirText)

                        Text(callTypeLabel(call.type) + " - " + call.duration)
                            .font(.noirCaption(11))
                            .foregroundColor(.noirMuted)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(call.time)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.noirText)
                        Text(call.date)
                            .font(.noirCaption(10))
                            .foregroundColor(.noirMuted)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.noirPrimary.opacity(0.2))
            }
        }
        .padding(.vertical, 8)
    }

    private func callTypeIcon(_ type: String) -> some View {
        let (icon, color): (String, Color) = {
            switch type {
            case "incoming": return ("phone.arrow.down.left.fill", .noirSuccess)
            case "outgoing": return ("phone.arrow.up.right.fill", Color.blue)
            default: return ("phone.down.fill", .noirAccent)
            }
        }()

        return Image(systemName: icon)
            .font(.system(size: 14))
            .foregroundColor(color)
            .frame(width: 32, height: 32)
            .background(
                Circle().fill(color.opacity(0.12))
            )
    }

    private func callTypeLabel(_ type: String) -> String {
        switch type {
        case "incoming": return loc.s(.incomingCall)
        case "outgoing": return loc.s(.outgoingCall)
        default: return loc.s(.missedCall)
        }
    }
}
