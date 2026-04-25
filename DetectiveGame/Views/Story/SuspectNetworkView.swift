import SwiftUI

struct SuspectNetworkView: View {
    let network: SuspectNetwork
    let gameState: GameState
    let characters: [Character]
    let caseId: String
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedNode: NetworkNode? = nil
    @State private var portraits: [String: UIImage] = [:]

    private var charactersById: [String: Character] {
        Dictionary(uniqueKeysWithValues: characters.map { ($0.id, $0) })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.noirBackground.ignoresSafeArea()

                GeometryReader { geo in
                    let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2 - 60)
                    let radius = min(geo.size.width, geo.size.height) * 0.34

                    ZStack {
                        // Connections
                        ForEach(network.connections) { conn in
                            connectionLine(conn, center: center, radius: radius, size: geo.size)
                        }

                        // Nodes
                        ForEach(network.nodes) { node in
                            let pos = nodePosition(node, center: center, radius: radius)
                            nodeView(node)
                                .position(pos)
                        }
                    }
                }

                // Selected node detail
                if let node = selectedNode {
                    VStack {
                        Spacer()
                        nodeDetailCard(node)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .padding(16)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(loc.s(.networkTitle))
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
        .task {
            await loadPortraits()
        }
    }

    // MARK: - Portrait Loading

    private func loadPortraits() async {
        await withTaskGroup(of: (String, UIImage?).self) { group in
            for node in network.nodes {
                guard let character = charactersById[node.id] else { continue }
                if portraits[node.id] != nil { continue }
                let imgName = character.portraitImage
                let nodeId = node.id
                group.addTask {
                    let img = await CaseLoader.loadBundleImageAsync(named: imgName, caseId: caseId)
                    return (nodeId, img)
                }
            }
            for await (nodeId, img) in group {
                if let img = img {
                    portraits[nodeId] = img
                }
            }
        }
    }

    // MARK: - Node Position

    private func nodePosition(_ node: NetworkNode, center: CGPoint, radius: CGFloat) -> CGPoint {
        let centerNodes = network.nodes.filter { $0.type == "victim" || $0.type == "arrested" }
        let suspects = network.nodes.filter { $0.type == "suspect" }
        let npcs = network.nodes.filter { $0.type == "npc" }

        // Victim / arrested at center, stacked vertically if more than one
        if node.type == "victim" || node.type == "arrested" {
            let idx = centerNodes.firstIndex(where: { $0.id == node.id }) ?? 0
            let count = centerNodes.count
            if count == 1 {
                return center
            }
            // Stack vertically with spacing
            let total = CGFloat(count - 1)
            let offsetY = (CGFloat(idx) - total / 2) * 54
            return CGPoint(x: center.x, y: center.y + offsetY)
        }

        // Suspects in inner ring
        if node.type == "suspect" {
            let idx = suspects.firstIndex(where: { $0.id == node.id }) ?? 0
            let step = (2 * .pi) / CGFloat(max(suspects.count, 1))
            let angle = step * CGFloat(idx) - .pi / 2
            return CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
        }

        // NPCs in outer ring
        let idx = npcs.firstIndex(where: { $0.id == node.id }) ?? 0
        let step = (2 * .pi) / CGFloat(max(npcs.count, 1))
        let angle = step * CGFloat(idx) - .pi / 2
        return CGPoint(
            x: center.x + radius * 1.45 * cos(angle),
            y: center.y + radius * 1.45 * sin(angle)
        )
    }

    // MARK: - Node View

    private func nodeView(_ node: NetworkNode) -> some View {
        let size = nodeSize(node)
        let color = nodeColor(node)
        let isSelected = selectedNode?.id == node.id
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedNode = isSelected ? nil : node
            }
        }) {
            VStack(spacing: 6) {
                ZStack {
                    // Outer glow ring when selected
                    if isSelected {
                        Circle()
                            .stroke(color.opacity(0.5), lineWidth: 8)
                            .frame(width: size + 10, height: size + 10)
                            .blur(radius: 4)
                    }

                    // Portrait or letter avatar
                    Group {
                        if let img = portraits[node.id] {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Circle()
                                .fill(color.opacity(0.18))
                                .overlay(
                                    Text(String(node.label.prefix(1)).uppercased())
                                        .font(.system(size: size * 0.42, weight: .bold, design: .serif))
                                        .foregroundColor(color)
                                )
                        }
                    }
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(color, lineWidth: isSelected ? 3 : 2)
                    )

                    // Type indicator badge (top-right)
                    if let icon = typeIcon(node) {
                        Image(systemName: icon)
                            .font(.system(size: size * 0.22, weight: .bold))
                            .foregroundColor(.white)
                            .padding(size * 0.12)
                            .background(
                                Circle().fill(color)
                            )
                            .overlay(
                                Circle().stroke(Color.noirBackground, lineWidth: 1.5)
                            )
                            .offset(x: size * 0.32, y: -size * 0.32)
                    }
                }

                Text(node.label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.noirText)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.noirBackground.opacity(0.85))
                    )
                    .frame(maxWidth: size + 20)
            }
        }
        .buttonStyle(.plain)
    }

    private func nodeColor(_ node: NetworkNode) -> Color {
        switch node.type {
        case "victim": return .red
        case "arrested": return .noirGold
        case "suspect": return .noirAccent
        case "npc": return .noirMuted
        default: return .noirMuted
        }
    }

    private func nodeSize(_ node: NetworkNode) -> CGFloat {
        switch node.type {
        case "victim", "arrested": return 76
        case "suspect": return 62
        default: return 48
        }
    }

    private func typeIcon(_ node: NetworkNode) -> String? {
        switch node.type {
        case "victim": return "xmark"
        case "arrested": return "lock.fill"
        case "suspect": return nil
        case "npc": return nil
        default: return nil
        }
    }

    private func typeLabel(_ node: NetworkNode) -> String {
        let isTR = loc.language == .turkish
        switch node.type {
        case "victim": return isTR ? "Kurban" : "Victim"
        case "arrested": return isTR ? "Tutuklu" : "Arrested"
        case "suspect": return isTR ? "Şüpheli" : "Suspect"
        case "npc": return isTR ? "Bağlantı" : "Contact"
        default: return node.type.capitalized
        }
    }

    // MARK: - Connection Line

    private func connectionLine(_ conn: NetworkConnection, center: CGPoint, radius: CGFloat, size: CGSize) -> some View {
        let fromNode = network.nodes.first { $0.id == conn.from }
        let toNode = network.nodes.first { $0.id == conn.to }

        guard let from = fromNode, let to = toNode else {
            return AnyView(EmptyView())
        }

        let fromPos = nodePosition(from, center: center, radius: radius)
        let toPos = nodePosition(to, center: center, radius: radius)
        let isHidden = !conn.requires.isEmpty && !conn.requires.allSatisfy { gameState.collectedEvidence.contains($0) }

        // Highlight only when one endpoint is selected
        let isRelated = selectedNode.map { $0.id == conn.from || $0.id == conn.to } ?? false
        let hasSelection = selectedNode != nil
        let showLabel = isRelated && !isHidden

        let baseColor = connectionColor(conn)
        let lineOpacity: Double = {
            if isHidden { return hasSelection ? 0.08 : 0.15 }
            if !hasSelection { return 0.35 }
            return isRelated ? 0.85 : 0.12
        }()
        let lineWidth: CGFloat = {
            if isHidden { return 1 }
            return isRelated ? max(CGFloat(conn.strength) + 0.5, 2) : max(CGFloat(conn.strength), 1.2)
        }()

        return AnyView(
            ZStack {
                Path { path in
                    path.move(to: fromPos)
                    path.addLine(to: toPos)
                }
                .stroke(
                    isHidden ? Color.noirMuted.opacity(lineOpacity) : baseColor.opacity(lineOpacity),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round,
                        dash: isHidden ? [4, 6] : []
                    )
                )

                // Label only for selected node's connections
                if showLabel {
                    let mid = CGPoint(
                        x: (fromPos.x + toPos.x) / 2,
                        y: (fromPos.y + toPos.y) / 2
                    )
                    Text(conn.label)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(baseColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.noirBackground)
                                .overlay(
                                    Capsule().stroke(baseColor.opacity(0.5), lineWidth: 0.8)
                                )
                        )
                        .position(mid)
                }
            }
        )
    }

    private func connectionColor(_ conn: NetworkConnection) -> Color {
        switch conn.type {
        case "family": return .blue
        case "business": return .green
        case "romantic": return .pink
        case "suspicious": return .orange
        case "rivalry": return .purple
        default: return .noirMuted
        }
    }

    // MARK: - Node Detail Card

    private func nodeDetailCard(_ node: NetworkNode) -> some View {
        let connections = network.connections.filter {
            ($0.from == node.id || $0.to == node.id) &&
            ($0.requires.isEmpty || $0.requires.allSatisfy { gameState.collectedEvidence.contains($0) })
        }
        let color = nodeColor(node)
        let character = charactersById[node.id]

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Group {
                    if let img = portraits[node.id] {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Circle()
                            .fill(color.opacity(0.18))
                            .overlay(
                                Text(String(node.label.prefix(1)).uppercased())
                                    .font(.system(size: 20, weight: .bold, design: .serif))
                                    .foregroundColor(color)
                            )
                    }
                }
                .frame(width: 54, height: 54)
                .clipShape(Circle())
                .overlay(Circle().stroke(color, lineWidth: 2))

                VStack(alignment: .leading, spacing: 2) {
                    Text(node.label)
                        .font(.noirSubtitle(17))
                        .foregroundColor(.noirText)
                    Text(typeLabel(node))
                        .font(.noirCaption(11))
                        .foregroundColor(color)
                    if let occ = character?.occupation, !occ.isEmpty {
                        Text(occ)
                            .font(.noirCaption(11))
                            .foregroundColor(.noirMuted)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Button(action: {
                    withAnimation { selectedNode = nil }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.noirMuted)
                        .padding(6)
                        .background(Circle().fill(Color.noirSecondary.opacity(0.2)))
                }
            }

            if !connections.isEmpty {
                Divider().background(Color.noirSecondary.opacity(0.2))

                ForEach(connections) { conn in
                    let otherNodeId = conn.from == node.id ? conn.to : conn.from
                    let otherNode = network.nodes.first { $0.id == otherNodeId }

                    HStack(spacing: 10) {
                        Circle()
                            .fill(connectionColor(conn))
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(conn.label)
                                .font(.noirCaption(12))
                                .foregroundColor(.noirText.opacity(0.85))
                            if let other = otherNode {
                                Text(other.label)
                                    .font(.noirCaption(10))
                                    .foregroundColor(.noirMuted)
                            }
                        }

                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.noirSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.noirSecondary.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
        )
    }
}
