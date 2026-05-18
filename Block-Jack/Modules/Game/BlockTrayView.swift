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
struct BlockTrayView: View {
    @ObservedObject var vm: GameViewModel
    var onDragChanged: ((CGPoint) -> Void)? = nil
    
    private let slotSpacing: CGFloat = 8
    private let innerPadding: CGFloat = 10

    var body: some View {
        let totalSlots = vm.run.maxTraySlots
        
        GeometryReader { geo in
            let available = geo.size.width - (innerPadding * 2)
            let totalGaps = slotSpacing * CGFloat(max(0, totalSlots - 1))
            let rawSlotWidth = (available - totalGaps) / CGFloat(totalSlots)
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
        .overlay(alignment: .topTrailing) {
            if vm.isDeadlocked {
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("DEADLOCK!")
                            .font(.setCustomFont(name: .InterBlack, size: 10))
                            .tracking(1)
                    }
                    .foregroundStyle(ThemeColors.neonPink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(ThemeColors.hudBg))
                    .overlay(Capsule().stroke(ThemeColors.neonPink.opacity(0.6), lineWidth: 1))
                }
                .padding(.trailing, 8)
                .padding(.top, 8)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .overlay(alignment: .trailing) {
            if vm.isDeadlocked {
                refreshButton
                    .padding(.trailing, 8)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Refresh Button
    @ViewBuilder
    private var refreshButton: some View {
        Button {
            vm.refreshTrayWithCost()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .black))
                Text("REFRESH")
                    .font(.setCustomFont(name: .InterBlack, size: 8))
                Text("100 G")
                    .font(.setCustomFont(name: .InterBold, size: 7))
                    .opacity(0.8)
            }
            .foregroundColor(vm.canRefreshTray ? ThemeColors.neonOrange : .gray)
            .frame(width: 54, height: 54)
            .background(
                Circle()
                    .fill(ThemeColors.hudBg)
                    .shadow(color: vm.canRefreshTray ? ThemeColors.neonOrange.opacity(0.4) : .clear, radius: 8)
            )
            .overlay(
                Circle()
                    .stroke(vm.canRefreshTray ? ThemeColors.neonOrange : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(!vm.canRefreshTray)
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
        let tileSize: CGFloat = max(9, min(14, (size - 24) / 5))
        let isActive = vm.draggingBlock?.id == block.id
        @State var showActions = false
        
        ZStack(alignment: .topTrailing) {
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
            
            BlockTileView(block: block, tileSize: tileSize)
                .opacity(isActive ? 0.25 : 1.0)
            
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
            
            // Action menu button
            VStack(spacing: 0) {
                Menu {
                    Section("BLOK İŞLEMLERİ") {
                        Button(role: .destructive) {
                            HapticManager.shared.play(.buttonTap)
                            vm.discardBlockFromTray(blockId: block.id)
                        } label: {
                            Label("Çöpe At (25G)", systemImage: "trash.fill")
                        }
                        
                        Button {
                            HapticManager.shared.play(.buttonTap)
                            vm.rerollBlockInTray(blockId: block.id)
                        } label: {
                            Label("Yenile (50G)", systemImage: "arrow.2.squarepath")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ThemeColors.neonOrange)
                        .padding(3)
                        .background(Circle().fill(ThemeColors.hudBg))
                }
            }
            .offset(x: -2, y: 2)
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
        .shadow(color: isActive ? ThemeColors.neonCyan.opacity(0.5) : .clear, radius: 8)
    }
}
