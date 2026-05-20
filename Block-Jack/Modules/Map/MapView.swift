//
//  MapView.swift
//  Block-Jack
//

import SwiftUI

struct MapView: View {
    @StateObject private var viewModel: MapViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userEnv: UserEnvironment
    
    let slotId: Int
    
    // Yönlendirme
    var onNodeSelected: ((MapNode) -> Void)?
    
    init(slotId: Int, onNodeSelected: ((MapNode) -> Void)? = nil) {
        self.slotId = slotId
        self._viewModel = StateObject(wrappedValue: MapViewModel(slotId: slotId))
        
        self.onNodeSelected = onNodeSelected ?? { node in
            // Default yönlendirme
            switch node.type {
            case .normal, .elite, .challenge, .boss:
                MainViewsRouter.shared.pushToGame(slotId: slotId, nodeType: node.type)
            case .merchant:
                MainViewsRouter.shared.pushToMerchant(slotId: slotId)
            case .treasure:
                MainViewsRouter.shared.pushToTreasure(slotId: slotId)
            case .rest:
                MainViewsRouter.shared.pushToRest(slotId: slotId)
            case .mystery:
                MainViewsRouter.shared.pushToMystery(slotId: slotId)
            }
        }
    }
    // Haritanın sabit içerik yüksekliği — node pozisyonları bu sabitle normalize edilir.
    private let mapHeight: CGFloat = 980

    var body: some View {
        ZStack {
            // MARK: - Tactical Background
            ThemeColors.mapBg.ignoresSafeArea()
            
            GridPattern()
                .stroke(ThemeColors.mapHudBorder.opacity(0.15), lineWidth: 1)
                .ignoresSafeArea()
            
            ScanningLineV2().ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack {
                        // Ambience glows
                        Circle()
                            .fill(ThemeColors.luminescentPrimary.opacity(0.05))
                            .frame(width: 400)
                            .blur(radius: 100)
                            .offset(y: 200)

                        GeometryReader { geometry in
                            let width = geometry.size.width
                            drawConnections(width: width, height: mapHeight)
                            drawNodes(width: width, height: mapHeight)
                        }
                        .frame(height: mapHeight)
                    }
                    .padding(.top, 140)
                    .padding(.bottom, 100)
                }
                .defaultScrollAnchor(.bottom)
                .onAppear {
                    AudioManager.shared.playMusic(.menu)
                    let target = viewModel.preferredFocusNodeId
                    guard let id = target else { return }
                    proxy.scrollTo(id, anchor: .center)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeOut(duration: 0.6)) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }

            // MARK: - HUD & Overlays
            VStack(spacing: 0) {
                tacticalHeaderHUD
                Spacer()
            }

            if let selected = viewModel.selectedNode {
                tacticalNodePanel(for: selected)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2)
            }

            VStack {
                Spacer()
                HStack {
                    Button(action: { viewModel.handleExitPressed() }) {
                        HStack(spacing: 8) {
                            Image(systemName: viewModel.isChapterCleared ? "map.fill" : "arrow.left")
                                .font(.system(size: 14, weight: .bold))
                            Text(
                                viewModel.isChapterCleared
                                ? userEnv.labelWorldSelectionCaps
                                : userEnv.labelMainMenuCaps
                            )
                        }
                        .font(.setCustomFont(name: .InterBold, size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.05))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedNode?.id)
        .onDisappear {
            guard !viewModel.isChapterCleared else { return }
            SaveManager.shared.updateMapState(
                slotId: viewModel.slotId,
                map: viewModel.currentMap,
                completedNodes: []
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("mapOverlayDidDismiss"))) { _ in
            if let nodeId = userEnv.pendingMapNodeId {
                userEnv.pendingMapNodeId = nil
                viewModel.markNodeCompleted(nodeId)
            }
        }
    }

    // MARK: - Tactical HUD
    private var tacticalHeaderHUD: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Circle().fill(ThemeColors.neonCyan).frame(width: 6, height: 6)
                        Text(userEnv.labelSystemAnalysisCaps)
                            .font(.setCustomFont(name: .InterBold, size: 10))
                            .foregroundStyle(ThemeColors.neonCyan)
                            .tracking(2)
                    }
                    
                    Text(userEnv.formatChapterIndex(index: viewModel.currentMap.chapterIndex))
                        .font(.setCustomFont(name: .InterBlack, size: 24))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    resourceTag(icon: "icon_gold", value: "\(userEnv.gold)", color: ThemeColors.electricYellow)
                    resourceTag(icon: "icon_diamond", value: "\(userEnv.diamonds)", color: ThemeColors.neonCyan)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 20)
            .background(
                LinearGradient(colors: [ThemeColors.mapBg, ThemeColors.mapBg.opacity(0)], startPoint: .top, endPoint: .bottom)
            )
        }
    }
    
    private func resourceTag(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(icon)
                .resizable()
                .frame(width: 14, height: 14)
            Text(value)
                .font(.setCustomFont(name: .InterBold, size: 14))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.3), lineWidth: 1))
    }
    
    // MARK: - Tactical Node Panel
    @ViewBuilder
    private func tacticalNodePanel(for node: MapNode) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                // Header of Panel
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(colorForNodeType(node.type).opacity(0.1))
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: iconForNodeType(node.type))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(colorForNodeType(node.type))
                            .shadow(color: colorForNodeType(node.type).opacity(0.5), radius: 10)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(titleForNodeType(node.type, userEnv: userEnv).uppercased())
                            .font(.setCustomFont(name: .InterBlack, size: 18))
                            .foregroundColor(.white)
                            .tracking(1)

                        Text(descForNodeType(node.type, userEnv: userEnv))
                            .font(.setCustomFont(name: .InterMedium, size: 13))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(3)
                    }
                    Spacer()
                    
                    Button(action: {
                        HapticManager.shared.play(.buttonTap)
                        viewModel.selectedNode = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.4))
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .buttonStyle(.plain)
                }
                
                // Action Button
                Button(action: {
                    userEnv.pendingMapNodeId = node.id
                    onNodeSelected?(node)
                }) {
                    ZStack {
                        let isAvailable = node.isAccessible || node.isReplayable
                        let accent = colorForNodeType(node.type)
                        
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isAvailable ? accent : Color.white.opacity(0.05))
                            .frame(height: 56)
                        
                        HStack {
                            Text(node.isReplayable
                                 ? userEnv.btnRefreshDataCaps
                                 : userEnv.btnInitializeLinkCaps)
                                .font(.setCustomFont(name: .InterBlack, size: 14))
                                .tracking(2)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .black))
                        }
                        .foregroundColor(isAvailable ? .black : .white.opacity(0.2))
                    }
                }
                .disabled(!node.isAccessible && !node.isReplayable)
            }
            .padding(32)
            .background(
                ThemeColors.mapBg.opacity(0.9)
                    .overlay(VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark))
            )
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .padding(16)
            .shadow(color: .black.opacity(0.5), radius: 40)
        }
    }

    @ViewBuilder
    private func drawConnections(width: CGFloat, height: CGFloat) -> some View {
        Group {
            Path { path in
                for node in viewModel.currentMap.nodes {
                    let startPoint = CGPoint(x: node.position.x * width, y: node.position.y * height)
                    for connectedId in node.connections {
                        if let targetNode = viewModel.currentMap.nodes.first(where: { $0.id == connectedId }) {
                            let endPoint = CGPoint(x: targetNode.position.x * width, y: targetNode.position.y * height)
                            path.move(to: startPoint)
                            path.addLine(to: endPoint)
                        }
                    }
                }
            }
            .stroke(Color.white.opacity(0.05), lineWidth: 3)
            
            Path { path in
                for node in viewModel.currentMap.nodes {
                    let startPoint = CGPoint(x: node.position.x * width, y: node.position.y * height)
                    for connectedId in node.connections {
                        if let targetNode = viewModel.currentMap.nodes.first(where: { $0.id == connectedId }) {
                            let endPoint = CGPoint(x: targetNode.position.x * width, y: targetNode.position.y * height)
                            path.move(to: startPoint)
                            path.addLine(to: endPoint)
                        }
                    }
                }
            }
            .stroke(ThemeColors.neonCyan.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
    }
    
    @ViewBuilder
    private func drawNodes(width: CGFloat, height: CGFloat) -> some View {
        ForEach(viewModel.currentMap.nodes) { node in
            let posX = node.position.x * width
            let posY = node.position.y * height
            
            TacticalNodeView(node: node, isSelected: viewModel.selectedNode?.id == node.id)
                .position(x: posX, y: posY)
                .id(node.id)
                .onTapGesture {
                    HapticManager.shared.play(.buttonTap)
                    viewModel.selectNode(node)
                }
            
            if viewModel.lastCompletedNodeId == node.id {
                StatusPulse()
                    .position(x: posX, y: posY)
            }
        }
    }
}

// MARK: - Tactical Components
struct ScanningLineV2: View {
    @State private var position: CGFloat = -200
    
    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(colors: [.clear, ThemeColors.neonCyan.opacity(0.05), .clear], startPoint: .top, endPoint: .bottom)
                )
                .frame(height: 100)
                .offset(y: position)
                .onAppear {
                    withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                        position = geo.size.height + 200
                    }
                }
        }
    }
}

struct TacticalNodeView: View {
    let node: MapNode
    let isSelected: Bool
    
    var body: some View {
        let accent = colorForNodeType(node.type)
        let isAvailable = node.isAccessible || node.isReplayable
        
        ZStack {
            if isSelected {
                Circle()
                    .stroke(accent.opacity(0.3), lineWidth: 2)
                    .frame(width: 60, height: 60)
                    .scaleEffect(1.2)
                
                Circle()
                    .fill(accent.opacity(0.1))
                    .frame(width: 50, height: 50)
            }
            
            Circle()
                .fill(isAvailable ? ThemeColors.mapHudPanel : ThemeColors.mapBg)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(isAvailable ? accent.opacity(0.6) : Color.white.opacity(0.1), lineWidth: isSelected ? 3 : 1)
                )
                .shadow(color: isAvailable ? accent.opacity(0.3) : .clear, radius: 10)
            
            Image(systemName: iconForNodeType(node.type))
                .font(.system(size: 18, weight: .black))
                .foregroundColor(isAvailable ? accent : Color.white.opacity(0.1))
            
            if node.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(ThemeColors.neonGreen)
                    .background(Color.black.clipShape(Circle()))
                    .offset(x: 18, y: -18)
            }
        }
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}

struct StatusPulse: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.5
    
    var body: some View {
        Circle()
            .stroke(ThemeColors.neonCyan, lineWidth: 2)
            .frame(width: 70, height: 70)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                    scale = 1.5
                    opacity = 0
                }
            }
    }
}

// MARK: - Helpers
func colorForNodeType(_ type: NodeType) -> Color {
    switch type {
    case .normal:   return ThemeColors.neonCyan
    case .elite:    return Color(hex: "#FF8C00") // Dark Orange
    case .challenge:return ThemeColors.neonPurple
    case .merchant: return Color(hex: "#00BFFF") // Deep Sky Blue
    case .treasure: return ThemeColors.neonGreen
    case .rest:     return Color(hex: "#7FFFD4") // Aquamarine
    case .mystery:  return Color(hex: "#DA70D6") // Orchid
    case .boss:     return ThemeColors.neonPink
    }
}

func iconForNodeType(_ type: NodeType) -> String {
    switch type {
    case .normal:   return "cpu"
    case .elite:    return "flame.fill"
    case .challenge:return "exclamationmark.shield.fill"
    case .merchant: return "cart.fill"
    case .treasure: return "gift.fill"
    case .rest:     return "battery.100.bolt"
    case .mystery:  return "eye.trianglebadge.exclamationmark.fill"
    case .boss:     return "skull.fill"
    }
}

func titleForNodeType(_ type: NodeType, userEnv: UserEnvironment = .shared) -> String {
    switch type {
    case .normal:   return userEnv.labelNodeTitleNormal
    case .elite:    return userEnv.labelNodeTitleElite
    case .challenge:return userEnv.labelNodeTitleChallenge
    case .merchant: return userEnv.labelNodeTitleMerchant
    case .treasure: return userEnv.labelNodeTitleTreasure
    case .rest:     return userEnv.labelNodeTitleRest
    case .mystery:  return userEnv.labelNodeTitleMystery
    case .boss:     return userEnv.labelNodeTitleBoss
    }
}

func descForNodeType(_ type: NodeType, userEnv: UserEnvironment = .shared) -> String {
    switch type {
    case .normal:   return userEnv.labelNodeDescNormal
    case .elite:    return userEnv.labelNodeDescElite
    case .challenge:return userEnv.labelNodeDescChallenge
    case .merchant: return userEnv.labelNodeDescMerchant
    case .treasure: return userEnv.labelNodeDescTreasure
    case .rest:     return userEnv.labelNodeDescRest
    case .mystery:  return userEnv.labelNodeDescMystery
    case .boss:     return userEnv.labelNodeDescBoss
    }
}
