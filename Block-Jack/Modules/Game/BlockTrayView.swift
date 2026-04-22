//
//  BlockTrayView.swift
//  Block-Jack
//

import SwiftUI

// MARK: - Tek blok miniature görüntüsü
struct BlockTileView: View {
    let block: GameBlock
    let tileSize: CGFloat

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 2) {
                ForEach(0..<block.rows, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<block.cols, id: \.self) { col in
                            if block.shape[row][col] {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(block.color.color)
                                    .frame(width: tileSize, height: tileSize)
                                    .shadow(color: block.isSpecial
                                            ? block.ability.glowColor
                                            : block.color.color,
                                            radius: block.isSpecial ? 8 : 4)
                            } else {
                                Color.clear
                                    .frame(width: tileSize, height: tileSize)
                            }
                        }
                    }
                }
            }
            
            // Özel yetenek ikonunu üst sağ köşeye koy
            if block.isSpecial {
                Text(block.ability.icon)
                    .font(.system(size: tileSize * 0.9))
                    .offset(x: 4, y: -4)
            }
        }
    }
}

// MARK: - BlockTrayView (UI Revize — overflow fix)
/// Dinamik genişlik: ekran genişliğinde kaç slot varsa eşit paylaşılır.
/// Böylece 3 veya 4 slot da ekrana sorunsuz sığar, overflow yok.
struct BlockTrayView: View {
    @ObservedObject var vm: GameViewModel
    /// Drag sırasında her frame çağrılır — GameView @State dragPosition günceller
    var onDragChanged: ((CGPoint) -> Void)? = nil
    
    /// Slotlar arası boşluk
    private let slotSpacing: CGFloat = 8
    /// Kart içi yatay iç padding (kart kenarından slotlara)
    private let innerPadding: CGFloat = 10

    var body: some View {
        let totalSlots = vm.run.maxTraySlots
        
        GeometryReader { geo in
            let available = geo.size.width - (innerPadding * 2)
            let totalGaps = slotSpacing * CGFloat(max(0, totalSlots - 1))
            // Slot genişliği: mevcut alanı eşit böler. 3 slot için hesap: (W - 2*pad - 2*gap) / 3.
            let rawSlotWidth = (available - totalGaps) / CGFloat(totalSlots)
            // Kare slot, ancak yükseklik 72pt ile sınırlı (dikey bütçe doğru kalsın).
            let slotSize = min(72, max(48, rawSlotWidth))
            
            HStack(spacing: slotSpacing) {
                ForEach(vm.blockTray) { block in
                    traySlot(block: block, size: slotSize)
                }
                ForEach(vm.blockTray.count..<totalSlots, id: \.self) { _ in
                    emptySlot(size: slotSize)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, innerPadding)
            .padding(.vertical, 8)
        }
        .frame(height: GameLayout.trayHeight)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(ThemeColors.trayBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(ThemeColors.trayBorder, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Empty slot
    @ViewBuilder
    private func emptySlot(size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(ThemeColors.cellEmpty.opacity(0.6))
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(ThemeColors.cardBorder, style: StrokeStyle(lineWidth: 1, dash: [4]))
            )
    }
    
    // MARK: - Filled slot
    @ViewBuilder
    private func traySlot(block: GameBlock, size: CGFloat) -> some View {
        // Mini blok preview için tile boyutu — slot genişliğine göre adaptif
        // 4 sütunluk blok bile sığsın: tileSize = (size - 16) / max(cols).
        // Ama block boyutu değişken, sabit 10pt-14pt arası seçelim.
        let tileSize: CGFloat = max(9, min(14, (size - 24) / 5))
        let isActive = vm.draggingBlock?.id == block.id
        
        ZStack {
            // Slot arka plan
            if block.isSpecial {
                RoundedRectangle(cornerRadius: 10)
                    .fill(block.ability.glowColor.opacity(0.08))
                    .frame(width: size, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(block.ability.glowColor.opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: block.ability.glowColor.opacity(0.3), radius: 6)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(ThemeColors.cardBg)
                    .frame(width: size, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(ThemeColors.cardBorder, lineWidth: 1)
                    )
            }
            
            // Mini blok preview
            BlockTileView(block: block, tileSize: tileSize)
                .opacity(isActive ? 0.25 : 1.0)
            
            // Alt etiket
            if block.isSpecial {
                VStack {
                    Spacer()
                    Text(block.ability.displayName)
                        .font(.system(size: 7, weight: .black))
                        .foregroundStyle(block.ability.glowColor)
                        .tracking(1)
                        .padding(.bottom, 3)
                }
            } else if block.isRotatable {
                VStack {
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(ThemeColors.textMuted)
                        .padding(.bottom, 3)
                }
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                vm.rotateBlockInTray(id: block.id)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 10, coordinateSpace: .global)
                .onChanged { value in
                    if !vm.isDragging {
                        vm.draggingBlock = block
                        vm.isDragging = true
                        HapticManager.shared.playSelection()
                    }
                    onDragChanged?(value.location)
                    vm.dragLocation = value.location
                    let gridPos = vm.gridSpaceConverter?(value.location)
                    vm.updateDrag(location: value.location, gridPosition: gridPos)
                }
                .onEnded { value in
                    onDragChanged?(value.location)
                    vm.dragLocation = value.location
                    vm.handleDragEnd()
                }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isActive
                        ? (block.isSpecial ? block.ability.glowColor : ThemeColors.neonCyan)
                        : Color.clear,
                    lineWidth: 2
                )
        )
        // Aktif slot için hafif cyan glow (doc: "Aktif slot hafif cyan glowla vurgulanmış")
        .shadow(color: isActive ? ThemeColors.neonCyan.opacity(0.5) : .clear, radius: 8)
    }
}
