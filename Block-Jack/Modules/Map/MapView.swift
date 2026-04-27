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
    // GeometryReader.size.height ScrollView içinde güvenilmez.
    private let mapHeight: CGFloat = 980

    var body: some View {
        ZStack {
            ThemeColors.surface.ignoresSafeArea()
            GridPattern()
                .stroke(ThemeColors.outlineVariant.opacity(0.15), lineWidth: 1)
                .ignoresSafeArea()
            ScanningLine().ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        // Yukseklik: sabit mapHeight kullan, geometry.size.height degil
                        drawConnections(width: width, height: mapHeight)
                        drawNodes(width: width, height: mapHeight)
                    }
                    .frame(height: mapHeight)
                    .padding(.top, 100)
                    .padding(.bottom, 60)
                }
                // Start node y=0.92 (alt) oldugu icin ScrollView alttan baslar
                .defaultScrollAnchor(.bottom)
                .onAppear {
                    AudioManager.shared.playMusic(.menu)
                    // Aktif node'a scroll
                    let target = viewModel.preferredFocusNodeId
                    guard let id = target else { return }
                    proxy.scrollTo(id, anchor: .center)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }

            VStack {
                statsHeaderHUD
                Spacer()
            }

            if let selected = viewModel.selectedNode {
                nodeSelectionPanel(for: selected)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2)
            }

            VStack {
                Spacer()
                HStack {
                    Button(action: { viewModel.handleExitPressed() }) {
                        HStack {
                            Image(systemName: viewModel.isChapterCleared ? "map.fill" : "chevron.left")
                            Text(
                                viewModel.isChapterCleared
                                ? userEnv.localizedString("DUNYA HARITASI", "WORLD MAP")
                                : userEnv.localizedString("ANA MENU", "MAIN MENU")
                            )
                        }
                        .font(.setCustomFont(name: .ManropeBold, size: 14))
                        .foregroundColor(
                            viewModel.isChapterCleared
                            ? ThemeColors.electricYellow
                            : ThemeColors.luminescentPrimary
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(ThemeColors.surfaceContainerLowest)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.05), radius: 5)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedNode?.id)
        // iOS geri gesture veya herhangi bir navigasyonla çıkılsa da
        // mevcut map durumu kaydedilir — ANA MENÜ basma zorunluluğu kalkar.
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
    }  // end body

    // MARK: - Subcomponents

    private var statsHeaderHUD: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(userEnv.localizedString("GÖREV SEKTÖRÜ", "MISSION SECTOR"))
                        .font(.luminescentHeader(size: 10))
                        .luminescentTracking()
                        .foregroundStyle(ThemeColors.luminescentPrimary)
                    Text(userEnv.localizedString("BÖLÜM \(viewModel.currentMap.chapterIndex)", "CHAPTER \(viewModel.currentMap.chapterIndex)"))
                        .font(.luminescentHeader(size: 22))
                        .foregroundStyle(Color.black.opacity(0.8))
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    currencyBadge(icon: "icon_gold", value: "\(userEnv.gold)", color: ThemeColors.electricYellow)
                    currencyBadge(icon: "icon_diamond", value: "\(userEnv.diamonds)", color: ThemeColors.luminescentPrimary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                ThemeColors.surfaceContainerLowest
                    .overlay(
                        VStack {
                            Spacer()
                            ThemeColors.outlineVariant.opacity(0.1).frame(height: 1)
                        }
                    )
            )
        }
    }
    
    private func currencyBadge(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(icon)
                .resizable()
                .frame(width: 16, height: 16)
            Text(value)
                .font(.setCustomFont(name: .InterBold, size: 14))
                .foregroundStyle(Color.black.opacity(0.7))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(ThemeColors.surfaceContainerLow)
        .cornerRadius(8)
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
            .stroke(ThemeColors.luminescentPrimary.opacity(0.1), lineWidth: 2)
            
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
            .stroke(ThemeColors.luminescentPrimary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
    }
    
    @ViewBuilder
    private func drawNodes(width: CGFloat, height: CGFloat) -> some View {
        ForEach(viewModel.currentMap.nodes) { node in
            let posX = node.position.x * width
            let posY = node.position.y * height
            
            MapNodeView(node: node, isSelected: viewModel.selectedNode?.id == node.id)
                .position(x: posX, y: posY)
                .id(node.id) // ScrollViewReader focus anchor
                .onTapGesture {
                    HapticManager.shared.play(.buttonTap)
                    viewModel.selectNode(node)
                }
            
            if viewModel.lastCompletedNodeId == node.id {
                FloatingIndicator()
                    .position(x: posX, y: posY - 40)
            }
        }
    }
    
    @ViewBuilder
    private func nodeSelectionPanel(for node: MapNode) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    Circle()
                        .fill(ThemeColors.surfaceContainerLow)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: iconForNodeType(node.type))
                                .font(.title2)
                                .foregroundColor(colorForNodeType(node.type))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(titleForNodeType(node.type, userEnv: userEnv))
                            .font(.setCustomFont(name: .ManropeExtraBold, size: 18))
                            .foregroundColor(Color.black.opacity(0.8))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Text(descForNodeType(node.type, userEnv: userEnv))
                            .font(.setCustomFont(name: .InterRegular, size: 14))
                            .foregroundColor(Color.black.opacity(0.5))
                            .lineLimit(3)
                            .minimumScaleFactor(0.85)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Button(action: {
                    // markNodeCompleted BURADA DEĞİL.
                    // Oyun kazanılıp HARİTAYA DÖN'e basılınca onAppear'da çağrılır.
                    // Force-close: onDisappear map'i accessible halde kaydeder,
                    // pending in-memory kaybolur → kullanıcı tekrar oynayabilir.
                    userEnv.pendingMapNodeId = node.id
                    onNodeSelected?(node)
                }) {
                    Text(node.isReplayable
                         ? userEnv.localizedString("YENİDEN BAŞLAT", "RESTART")
                         : userEnv.localizedString("GÖREVE BAŞLA", "START MISSION"))
                        .font(.luminescentHeader(size: 16))
                        .luminescentTracking()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(node.isAccessible || node.isReplayable ? AnyShapeStyle(ThemeColors.liquidChromeGradient) : AnyShapeStyle(Color.gray.opacity(0.3)))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .disabled(!node.isAccessible && !node.isReplayable)
            }
            .padding(24)
            .background(
                ThemeColors.surfaceContainerLowest
                    .overlay(VisualEffectBlur(blurStyle: .systemUltraThinMaterialLight))
            )
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            // Ambient Occlusion Shadow (Spec 4)
            .shadow(color: Color.black.opacity(0.06), radius: 60, x: 0, y: 30)
            .padding(20)
        }
    }
}

// Tech Detail: Scanning Line
struct ScanningLine: View {
    @State private var position: CGFloat = -100
    
    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(colors: [.clear, ThemeColors.luminescentPrimary.opacity(0.1), .clear], startPoint: .top, endPoint: .bottom)
                )
                .frame(height: 2)
                .offset(y: position)
                .onAppear {
                    withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                        position = geo.size.height + 100
                    }
                }
        }
    }
}

// MARK: - Map Node View
struct MapNodeView: View {
    let node: MapNode
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // Shadow layer
            Circle()
                .fill(Color.black.opacity(node.isAccessible ? 0.05 : 0))
                .frame(width: 54, height: 54)
                .offset(y: 4)
                .blur(radius: 4)
            
            // Base layer
            Circle()
                .fill(node.isAccessible ? ThemeColors.surfaceContainerLowest : ThemeColors.surfaceContainerLow.opacity(0.5))
                .frame(width: 50, height: 50)
            
            // Border layer
            Circle()
                .stroke(
                    isSelected ? ThemeColors.luminescentPrimary : colorForNodeType(node.type).opacity(node.isAccessible ? 0.3 : 0.1),
                    lineWidth: isSelected ? 3 : 1.5
                )
                .frame(width: 50, height: 50)
            
            // Icon
            VStack {
                Image(systemName: iconForNodeType(node.type))
                    .foregroundColor(node.isAccessible ? colorForNodeType(node.type) : Color.gray.opacity(0.3))
                    .font(.system(size: 20, weight: .bold))
            }
            
            if node.isCompleted {
                Circle()
                    .fill(Color.green)
                    .frame(width: 14, height: 14)
                    .overlay(Image(systemName: "checkmark").font(.system(size: 8, weight: .black)).foregroundColor(.white))
                    .offset(x: 18, y: -18)
            }
            
            if isSelected {
                PulsingCircle(color: ThemeColors.luminescentPrimary, size: 65)
            }
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Helpers

func colorForNodeType(_ type: NodeType) -> Color {
    switch type {
    case .normal:   return ThemeColors.luminescentPrimary
    case .elite:    return Color.orange
    case .challenge:return ThemeColors.neonPurple
    case .merchant: return Color.blue
    case .treasure: return Color.green
    case .rest:     return Color.cyan
    case .mystery:  return Color.purple
    case .boss:     return Color.red
    }
}

func iconForNodeType(_ type: NodeType) -> String {
    switch type {
    case .normal:   return "bolt.shield"
    case .elite:    return "flame"
    case .challenge:return "exclamationmark.triangle"
    case .merchant: return "cart"
    case .treasure: return "gift"
    case .rest:     return "leaf"
    case .mystery:  return "questionmark"
    case .boss:     return "skull"
    }
}

func titleForNodeType(_ type: NodeType, userEnv: UserEnvironment = .shared) -> String {
    switch type {
    case .normal:   return userEnv.localizedString("Sektörel Temizlik", "Standard Sweep")
    case .elite:    return userEnv.localizedString("Zorlu Müdahale", "Elite Encounter")
    case .challenge:return userEnv.localizedString("Challenge Protokolü", "Challenge Protocol")
    case .merchant: return userEnv.localizedString("Veri Tüccarı", "Merchant")
    case .treasure: return userEnv.localizedString("Sistem Ödülü", "Treasure")
    case .rest:     return userEnv.localizedString("Veri Yedekleme", "Safe Zone")
    case .mystery:  return userEnv.localizedString("Anomali Tespiti", "Mystery Signal")
    case .boss:     return userEnv.localizedString("Kritik Protokol", "Boss Protocol")
    }
}

func descForNodeType(_ type: NodeType, userEnv: UserEnvironment = .shared) -> String {
    switch type {
    case .normal:   return userEnv.localizedString("Standart glitch temizleme görevi.", "A standard cleanup mission.")
    case .elite:    return userEnv.localizedString("Yüksek yoğunluklu veri anomalisi.", "A high-intensity anomaly.")
    case .challenge:return userEnv.localizedString("Opsiyonel: Daha zor savaş, daha yüksek ödül.", "Optional: harder fight, higher rewards.")
    case .merchant: return userEnv.localizedString("Eski donanımları yeni modüllerle takas et.", "Trade old hardware for new modules.")
    case .treasure: return userEnv.localizedString("Sistem tarafından bırakılmış sahipsiz yetenekler.", "Abandoned upgrades left by the system.")
    case .rest:     return userEnv.localizedString("Sistem sağlığını onar veya modülleri optimize et.", "Repair systems or optimize modules.")
    case .mystery:  return userEnv.localizedString("Analiz edilemeyen dış kaynaklı bir sinyal.", "An unknown external signal.")
    case .boss:     return userEnv.localizedString("Ana sunucuyu ele geçiren karanlık protokol.", "A hostile protocol controlling the core server.")
    }
}

struct FloatingIndicator: View {
    @State private var offset: CGFloat = 0
    var body: some View {
        Circle()
            .fill(ThemeColors.luminescentPrimary)
            .frame(width: 8, height: 8)
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    offset = -5
                }
            }
    }
}

// Helpers are now in UIComponents.swift
