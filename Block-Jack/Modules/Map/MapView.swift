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
            // 1. Atmosferik Arka Plan
            ZStack {
                Image("cyber_map_background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(Color.black.opacity(0.4))
                
                // Synthwave Grid
                Canvas { ctx, size in
                    let step: CGFloat = 40
                    for x in stride(from: 0, through: size.width, by: step) {
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        ctx.stroke(path, with: .color(ThemeColors.gridStroke.opacity(0.1)), lineWidth: 0.5)
                    }
                    for y in stride(from: 0, through: size.height, by: step) {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        ctx.stroke(path, with: .color(ThemeColors.gridStroke.opacity(0.1)), lineWidth: 0.5)
                    }
                }
                .opacity(0.5)
            }
            .ignoresSafeArea()
            
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                
                // 2. Bağlantı Çizgileri
                drawConnections(width: width, height: height)
                
                // 3. Düğümler
                drawNodes(width: width, height: height)
            }
            .padding(.top, 100)
            .padding(.bottom, 60)
            
            // 4. Stats HUD
            VStack {
                statsHeaderHUD
                Spacer()
            }
            
            // 5. Seçim Paneli
            if let selected = viewModel.selectedNode {
                nodeSelectionPanel(for: selected)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2)
            }
            
            // 6. Alt Navigasyon
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
                        .font(.setCustomFont(name: .InterBold, size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.1)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
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
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.selectedNode?.id)
    }
    
    // MARK: - Subcomponents
    
    private var statsHeaderHUD: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("GÖREV SEKTÖRÜ")
                        .font(.setCustomFont(name: .InterBlack, size: 10))
                        .foregroundStyle(ThemeColors.neonCyan)
                        .tracking(2)
                    Text("CHAPTER \(viewModel.currentMap.chapterIndex)")
                        .font(.setCustomFont(name: .InterExtraBold, size: 22))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    currencyBadge(icon: "icon_gold", value: "\(userEnv.gold)", color: ThemeColors.electricYellow)
                    currencyBadge(icon: "icon_diamond", value: "\(userEnv.diamonds)", color: ThemeColors.neonCyan)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(ThemeColors.neonPink)
                        Text("3")
                            .font(.setCustomFont(name: .InterBold, size: 16))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(ThemeColors.surfaceLight)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Rectangle()
                .fill(LinearGradient(colors: [ThemeColors.neonCyan.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
                .padding(.horizontal, 20)
        }
        .background(
            LinearGradient(colors: [Color.black, .clear], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
    
    private func currencyBadge(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(icon)
                .resizable()
                .frame(width: 16, height: 16)
            Text(value)
                .font(.setCustomFont(name: .InterBold, size: 14))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.3), lineWidth: 1))
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
            .stroke(ThemeColors.neonCyan.opacity(0.15), lineWidth: 4)
            .blur(radius: 3)
            
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
            .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
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
                .shadow(color: colorForNodeType(node.type).opacity(node.isAccessible ? 0.4 : 0), radius: 10)
            
            if viewModel.lastCompletedNodeId == node.id {
                VStack(spacing: 2) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(ThemeColors.neonCyan)
                    
                    Circle()
                        .fill(ThemeColors.neonCyan)
                        .frame(width: 6, height: 6)
                }
                .shadow(color: ThemeColors.neonCyan, radius: 8)
                .position(x: posX, y: posY - 45)
                .phaseAnimator([0, -8, 0]) { content, offset in
                    content.offset(y: offset)
                } animation: { _ in
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
                }
            }
        }
    }
    
    @ViewBuilder
    private func nodeSelectionPanel(for node: MapNode) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: iconForNodeType(node.type))
                        .font(.title)
                        .foregroundColor(colorForNodeType(node.type))
                        .frame(width: 50, height: 50)
                        .background(colorForNodeType(node.type).opacity(0.2))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text(titleForNodeType(node.type))
                            .font(.headline)
                            .foregroundColor(.white)
                        if viewModel.canReplay(node) {
                            Text("⚠️ Ödül yarıya iner")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                    Spacer()
                }
                
                Text(descForNodeType(node.type))
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: {
                    viewModel.markNodeCompleted(node.id)
                    onNodeSelected?(node)
                }) {
                    Text(node.isReplayable ? "TEKRAR GİR" : "İLERLE")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(node.isAccessible || node.isReplayable ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!node.isAccessible && !node.isReplayable)
            }
            .padding()
            .background(Color(white: 0.15))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding()
        }
    }
}

// MARK: - Map Node View
struct MapNodeView: View {
    let node: MapNode
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    colorForNodeType(node.type).opacity(node.isAccessible ? 0.6 : 0.2),
                    lineWidth: 1
                )
                .frame(width: 54, height: 54)
                .overlay(
                    Circle()
                        .stroke(colorForNodeType(node.type).opacity(0.2), lineWidth: 4)
                        .blur(radius: 2)
                )
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [colorForNodeType(node.type).opacity(0.4), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 25
                    )
                )
                .frame(width: 44, height: 44)
            
            VStack {
                Image(systemName: iconForNodeType(node.type))
                    .foregroundColor(node.isCompleted ? .white.opacity(0.5) : .white)
                    .font(.system(size: 20, weight: .bold))
                    .shadow(color: .black, radius: 2)
            }
            
            if node.isCompleted {
                Circle()
                    .fill(Color.green)
                    .frame(width: 14, height: 14)
                    .overlay(Image(systemName: "checkmark").font(.system(size: 8, weight: .black)).foregroundColor(.black))
                    .offset(x: 18, y: -18)
            }
            
            if isSelected {
                Circle()
                    .stroke(ThemeColors.neonCyan, lineWidth: 2)
                    .frame(width: 64, height: 64)
                    .phaseAnimator([1.0, 1.25]) { content, scale in
                        content.scaleEffect(scale).opacity(2.0 - scale)
                    } animation: { _ in
                        .linear(duration: 1.0).repeatForever(autoreverses: false)
                    }
            }
        }
        .opacity(node.isAccessible || node.isCompleted ? 1.0 : 0.4)
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Helpers

func colorForNodeType(_ type: NodeType) -> Color {
    switch type {
    case .normal:   return ThemeColors.textSecondary
    case .elite:    return ThemeColors.neonOrange
    case .merchant: return ThemeColors.electricYellow
    case .treasure: return Color.green
    case .rest:     return ThemeColors.neonCyan
    case .mystery:  return Color.purple
    case .boss:     return ThemeColors.neonPink
    }
}

func iconForNodeType(_ type: NodeType) -> String {
    switch type {
    case .normal:   return "bolt.shield.fill"
    case .elite:    return "flame.fill"
    case .merchant: return "cart.fill"
    case .treasure: return "gift.fill"
    case .rest:     return "tent.fill"
    case .mystery:  return "questionmark.diamond.fill"
    case .boss:     return "skull.fill"
    }
}

func titleForNodeType(_ type: NodeType) -> String {
    switch type {
    case .normal:   return "BÖLGESEL ÇATIŞMA"
    case .elite:    return "ELİT DÜŞMAN"
    case .merchant: return "TÜCCAR"
    case .treasure: return "HAZİNE ODASI"
    case .rest:     return "DİNLENME NOKTASI"
    case .mystery:  return "GİZEMLİ OLAY"
    case .boss:     return "BÖLÜM PATRONU"
    }
}

func descForNodeType(_ type: NodeType) -> String {
    switch type {
    case .normal:   return "Standart tur. Hedef skora ulaş ve altın kazan."
    case .elite:    return "Zorlu bir sınav. Daha yüksek risk, daha yüksek ödül."
    case .merchant: return "Topladığın altınlarla run boyunca geçerli jokerler satın al."
    case .treasure: return "Ücretsiz bir pasif perk veya büyük bir ödül."
    case .rest:     return "Canını fulle veya elindeki var olan bir perki yükselt."
    case .mystery:  return "Ne olacağı belirsiz! İyi de olabilir kötü de."
    case .boss:     return "Ağır modifiye edilmiş zindan. Geçersen sonraki bölüme atlarsın!"
    }
}
