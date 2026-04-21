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

// MARK: - BlockTrayView (alt bar)
struct BlockTrayView: View {
    @ObservedObject var vm: GameViewModel
    /// Drag sırasında her frame çağrılır — GameView @State dragPosition günceller
    var onDragChanged: ((CGPoint) -> Void)? = nil

    var body: some View {
        HStack(spacing: vm.run.maxTraySlots > 3 ? 8 : 16) {
            ForEach(vm.blockTray) { block in
                traySlot(block: block)
            }
            
            // Boş slotlar
            ForEach(vm.blockTray.count..<vm.run.maxTraySlots, id: \.self) { _ in
                emptySlot()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ThemeColors.surfaceDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ThemeColors.gridStroke, lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func emptySlot() -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(ThemeColors.gridDark.opacity(0.4))
            .frame(width: 80, height: 80)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(ThemeColors.gridStroke.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
            )
    }

    @ViewBuilder
    private func traySlot(block: GameBlock) -> some View {
        ZStack {
            // Özel bloklar için neon glow arka plan
            if block.isSpecial {
                RoundedRectangle(cornerRadius: 10)
                    .fill(block.ability.glowColor.opacity(0.08))
                    .frame(width: 80, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(block.ability.glowColor.opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: block.ability.glowColor.opacity(0.3), radius: 8)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(ThemeColors.gridDark)
                    .frame(width: 80, height: 80)
            }
            
            // Eğer sürükleniyorsa yerinde gizle
            BlockTileView(block: block, tileSize: 14)
                .opacity(vm.draggingBlock?.id == block.id ? 0.25 : 1.0)
            
            // Özel blok adı etiketi (altta)
            if block.isSpecial {
                VStack {
                    Spacer()
                    Text(block.ability.displayName)
                        .font(.system(size: 7, weight: .black))
                        .foregroundStyle(block.ability.glowColor)
                        .tracking(1)
                        .padding(.bottom, 4)
                }
            } else if block.isRotatable {
                // Rotation Hint Icon
                VStack {
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(ThemeColors.textMuted)
                        .padding(.bottom, 4)
                }
            }
        }
        .frame(width: 80, height: 80)
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
                    // dragPosition callback — GameView @State'i günceller (overlay için)
                    onDragChanged?(value.location)
                    // Ghost/hint — vm.updateDrag throttle'lıdır, her framede render'a neden olmaz
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
                    vm.draggingBlock?.id == block.id
                        ? (block.isSpecial ? block.ability.glowColor : ThemeColors.neonCyan)
                        : Color.clear,
                    lineWidth: 2
                )
        )
    }
}
