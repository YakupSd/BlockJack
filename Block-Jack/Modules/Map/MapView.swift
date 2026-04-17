//
//  MapView.swift
//  Block-Jack
//

import SwiftUI

struct MapView: View {
    @StateObject private var viewModel: MapViewModel
    @Environment(\.dismiss) var dismiss
    
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
                // Savaş nodları
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
            // Arka Plan
            Color.black.ignoresSafeArea()
            
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                
                // 1. Bağlantı Çizgileri
                drawConnections(width: width, height: height)
                
                // 2. Düğümler
                drawNodes(width: width, height: height)
            }
            .padding()
            
            // 3. Seçim Paneli (Popup/Overlay)
            if let selected = viewModel.selectedNode {
                nodeSelectionPanel(for: selected)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
            
            // 4. Chapter Başlığı ve Kapat
            VStack {
                HStack {
                    Button(action: {
                        viewModel.saveAndReturnToDashboard()
                        MainViewsRouter.shared.popToDashboard()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    
                    Spacer()
                    
                    Text("BÖLÜM \(viewModel.currentMap.chapterIndex)")
                        .font(.custom("Outfit-Bold", size: 24, relativeTo: .title))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Sahte boşluk (ortalamak için)
                    Color.clear.frame(width: 50, height: 50)
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .animation(.spring(), value: viewModel.selectedNode?.id)
    }
    
    // MARK: - Drawing Components
    
    @ViewBuilder
    private func drawConnections(width: CGFloat, height: CGFloat) -> some View {
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
        .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 3, dash: [5, 5]))
    }
    
    @ViewBuilder
    private func drawNodes(width: CGFloat, height: CGFloat) -> some View {
        ForEach(viewModel.currentMap.nodes) { node in
            let posX = node.position.x * width
            let posY = node.position.y * height
            
            MapNodeView(node: node, isSelected: viewModel.selectedNode?.id == node.id)
                .position(x: posX, y: posY)
                .onTapGesture {
                    viewModel.selectNode(node)
                }
            
            // 2.1 Player Pointer
            if viewModel.lastCompletedNodeId == node.id {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(ThemeColors.neonCyan)
                    .shadow(color: ThemeColors.neonCyan, radius: 5)
                    .offset(y: -40)
                    .position(x: posX, y: posY)
                    .phaseAnimator([0, -5, 0]) { content, offset in
                        content.offset(y: offset)
                    } animation: { _ in
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
                    }
            }
        }
    }
    
    @ViewBuilder
    private func nodeSelectionPanel(for node: MapNode) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 16) {
                // Konum ve Başlık
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
                
                // Git Butonu
                Button(action: {
                    // Düğümü isCompleted işaretleyelim, daha sonra bunu event/game bitince de yapabiliriz ama
                    // şimdilik test aşamasında anında işaretlemekte fayda var:
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
            // Pulse animasyonu için (örneğin accessible ise)
            if node.isAccessible && !node.isCompleted {
                Circle()
                    .fill(colorForNodeType(node.type).opacity(0.3))
                    .frame(width: 60, height: 60)
            }
            
            Circle()
                .fill(Color(white: 0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Circle().stroke(
                        isSelected ? .white : colorForNodeType(node.type),
                        lineWidth: isSelected ? 4 : 2
                    )
                )
                .opacity(node.isAccessible || node.isCompleted ? 1.0 : 0.4)
            
            Image(systemName: iconForNodeType(node.type))
                .foregroundColor(node.isCompleted ? .gray : colorForNodeType(node.type))
                .font(.system(size: 20))
                .opacity(node.isAccessible || node.isCompleted ? 1.0 : 0.4)
            
            if node.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .background(Color.black.clipShape(Circle()))
                    .offset(x: 16, y: -16)
            }
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
    }
}

// MARK: - Helpers

func colorForNodeType(_ type: NodeType) -> Color {
    switch type {
    case .normal:   return .gray
    case .elite:    return .orange
    case .merchant: return .yellow
    case .treasure: return .green
    case .rest:     return .blue
    case .mystery:  return .purple
    case .boss:     return .red
    }
}

func iconForNodeType(_ type: NodeType) -> String {
    switch type {
    case .normal:   return "square.grid.2x2.fill"
    case .elite:    return "flame.fill"
    case .merchant: return "cart.fill"
    case .treasure: return "gift.fill"
    case .rest:     return "tent.fill"
    case .mystery:  return "questionmark.circle.fill"
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
    case .normal:   return "Standart tur. Hedef skoralaş ve altın kazan."
    case .elite:    return "Zorlu bir sınav. Daha yüksek risk, daha yüksek ödül."
    case .merchant: return "Topladığın altınlarla run boyunca geçerli jokerler satın al."
    case .treasure: return "Ücretsiz bir pasif perk veya büyük bir ödül."
    case .rest:     return "Canını fulle veya elindeki var olan bir perki yükselt."
    case .mystery:  return "Ne olacağı belirsiz! İyi de olabilir kötü de."
    case .boss:     return "Ağır modifiye edilmiş zindan. Geçersen sonraki bölüme atlarsın!"
    }
}
