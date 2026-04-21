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
            case .normal, .elite, .boss:
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
    
    var body: some View {
        ZStack {
            // 1. Architectural Surface Background
            ThemeColors.surface
                .ignoresSafeArea()
            
            // Subtle Grid Pattern (Luminescent Style)
            GridPattern()
                .stroke(ThemeColors.outlineVariant.opacity(0.15), lineWidth: 1)
                .ignoresSafeArea()
            
            // Scanning Line Overlay (Tech Detail)
            ScanningLine()
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                
                // 2. Ethereal Connection Lines
                drawConnections(width: width, height: height)
                
                // 3. Tech Nodes
                drawNodes(width: width, height: height)
            }
            .padding(.top, 100)
            .padding(.bottom, 60)
            
            // 4. Pearl HUD
            VStack {
                statsHeaderHUD
                Spacer()
            }
            
            // 5. Selection Panel (Pearl/Glass container)
            if let selected = viewModel.selectedNode {
                nodeSelectionPanel(for: selected)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2)
            }
            
            // 6. Navigation
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        viewModel.saveAndReturnToDashboard()
                        MainViewsRouter.shared.popToDashboard()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("ANA MENÜ")
                        }
                        .font(.setCustomFont(name: .ManropeBold, size: 14))
                        .foregroundColor(ThemeColors.luminescentPrimary)
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
        .onAppear {
            AudioManager.shared.playMusic(.menu)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedNode?.id)
    }
    
    // MARK: - Subcomponents
    
    private var statsHeaderHUD: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("GÖREV SEKTÖRÜ")
                        .font(.luminescentHeader(size: 10))
                        .luminescentTracking()
                        .foregroundStyle(ThemeColors.luminescentPrimary)
                    Text("BÖLÜM \(viewModel.currentMap.chapterIndex)")
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
                        Text(titleForNodeType(node.type))
                            .font(.setCustomFont(name: .ManropeExtraBold, size: 18))
                            .foregroundColor(Color.black.opacity(0.8))
                        
                        Text(descForNodeType(node.type))
                            .font(.setCustomFont(name: .InterRegular, size: 14))
                            .foregroundColor(Color.black.opacity(0.5))
                    }
                    Spacer()
                }
                
                Button(action: {
                    viewModel.markNodeCompleted(node.id)
                    onNodeSelected?(node)
                }) {
                    Text(node.isReplayable ? "YENİDEN BAŞLAT" : "GÖREVE BAŞLA")
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
    case .merchant: return "cart"
    case .treasure: return "gift"
    case .rest:     return "leaf"
    case .mystery:  return "questionmark"
    case .boss:     return "skull"
    }
}

func titleForNodeType(_ type: NodeType) -> String {
    switch type {
    case .normal:   return "Sektörel Temizlik"
    case .elite:    return "Zorlu Müdahale"
    case .merchant: return "Veri Tüccarı"
    case .treasure: return "Sistem Ödülü"
    case .rest:     return "Veri Yedekleme"
    case .mystery:  return "Anomali Tespiti"
    case .boss:     return "Kritik Protokol"
    }
}

func descForNodeType(_ type: NodeType) -> String {
    switch type {
    case .normal:   return "Standart glitch temizleme görevi."
    case .elite:    return "Yüksek yoğunluklu veri anomalisi."
    case .merchant: return "Eski donanımları yeni modüllerle takas et."
    case .treasure: return "Sistem tarafından bırakılmış sahipsiz yetenekler."
    case .rest:     return "Sistem sağlığını onar veya modülleri optimize et."
    case .mystery:  return "Analiz edilemeyen dış kaynaklı bir sinyal."
    case .boss:     return "Ana sunucuyu ele geçiren karanlık protokol."
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
