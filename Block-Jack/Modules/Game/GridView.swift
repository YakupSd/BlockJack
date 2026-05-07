//
//  GridView.swift
//  Block-Jack
//

import SwiftUI

// Phase 8.1: Cascaded flash support
struct FlashCell: Equatable {
    let pos: GridPosition
    let delay: Double
}

struct GridView: View {
    @ObservedObject var board: BoardViewModel
    let cellSize: CGFloat
    var onDrop: ((GridPosition) -> Void)? = nil
    var draggingBlock: GameBlock? = nil
    
    // Boss: Phantom logic
    var isPhantomMode: Bool = false
    var isPhantomVisible: Bool = true
    
    // Phase 8.1: Cascaded Clear Effect
    var flashPositions: [GridPosition] = []
    
    // Performans: 169 tane .onChange yerine tek bir trigger.
    @State private var lastFlashDate = Date.distantPast
    @State private var activeFlashes: Set<GridPosition> = []

    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<BoardViewModel.size, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<BoardViewModel.size, id: \.self) { col in
                        let pos = GridPosition(row: row, col: col)
                        CellView(
                            cell: board.grid[row][col],
                            pos: pos,
                            cellSize: cellSize,
                            isGhost: board.ghostCells.contains(pos),
                            isGhostValid: board.isGhostValid,
                            isHint: board.hintPositions.contains(pos),
                            isZoneHint: board.hintZonePositions.contains(pos),
                            isBestPlacement: board.bestPlacementCells.contains(pos),
                            isPhantomMode: isPhantomMode,
                            isPhantomVisible: isPhantomVisible,
                            isFlashing: activeFlashes.contains(pos)
                        )
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(ThemeColors.cellEmpty.opacity(0.01))
        )
        .overlay(
            zoneOverlay
                .allowsHitTesting(false)
        )
        .onChange(of: flashPositions) { oldValue, newPositions in
            guard !newPositions.isEmpty else { return }
            triggerFlashCascade(positions: newPositions)
        }
    }

    private func triggerFlashCascade(positions: [GridPosition]) {
        // Tek seferlik cascade tetiklemesi
        for (index, pos) in positions.enumerated() {
            let delay = Double(index) * 0.02
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.1)) {
                    _ = activeFlashes.insert(pos)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeIn(duration: 0.1)) {
                        _ = activeFlashes.remove(pos)
                    }
                }
            }
        }
    }

    // --- CellView: Performans için alt view'e bölündü ---
    struct CellView: View {
        let cell: GameCell
        let pos: GridPosition
        let cellSize: CGFloat
        let isGhost: Bool
        let isGhostValid: Bool
        let isHint: Bool
        let isZoneHint: Bool
        let isBestPlacement: Bool
        let isPhantomMode: Bool
        let isPhantomVisible: Bool
        let isFlashing: Bool

        var body: some View {
            ZStack {
                // Hücre arka planı
                RoundedRectangle(cornerRadius: 3)
                    .fill(cellBackground)
                    .frame(width: cellSize, height: cellSize)
                    .opacity(isPhantomMode && cell.isOccupied ? (isPhantomVisible ? 1.0 : 0.05) : 1.0)
                
                // Hints (Sarı/Pembe Nabız) - Sadece aktifken render edilir
                if isHint {
                    hintOverlay(color: ThemeColors.electricYellow)
                }
                if isZoneHint {
                    hintOverlay(color: ThemeColors.neonPink, isZone: true)
                }

                // Dolu hücre kenar vurgusu
                if case .filled(let color) = cell.state {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(color.color.opacity(0.5), lineWidth: 1)
                        .frame(width: cellSize, height: cellSize)
                        .opacity(isPhantomMode ? (isPhantomVisible ? 1.0 : 0.0) : 1.0)
                }
                
                // Modifiers (Gold, Star, Bolt, etc.)
                modifierOverlay

                // Tactical Lens
                if isBestPlacement && !isGhost {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(ThemeColors.success.opacity(0.7), lineWidth: 1.5)
                        .frame(width: cellSize, height: cellSize)
                }

                // Kilitli / Heavy
                if cell.isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: cellSize * 0.4))
                        .foregroundStyle(ThemeColors.textMuted)
                }
                if case .heavy(let hits) = cell.state {
                    Text("\(hits)")
                        .font(.setCustomFont(name: .InterBold, size: cellSize * 0.35))
                        .foregroundStyle(ThemeColors.neonOrange)
                }
                
                // Ghost
                if isGhost {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(isGhostValid ? ThemeColors.neonCyan : ThemeColors.neonPink, lineWidth: 2)
                        .frame(width: cellSize, height: cellSize)
                }
                
                // Flash Effect
                if isFlashing {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(cell.isSynergySubject ? AnyShapeStyle(AngularGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red], center: .center)) : AnyShapeStyle(Color.white))
                        .blendMode(.screen)
                        .allowsHitTesting(false)
                }
            }
            .scaleEffect(isFlashing ? 1.1 : 1.0)
        }

        @ViewBuilder
        private func hintOverlay(color: Color, isZone: Bool = false) -> some View {
            RoundedRectangle(cornerRadius: 3)
                .fill(color.opacity(0.3))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(color, lineWidth: isZone ? 2 : 1))
                .shadow(color: color.opacity(0.5), radius: isZone ? 6 : 4)
                .frame(width: cellSize, height: cellSize)
        }

        @ViewBuilder
        private var modifierOverlay: some View {
            if let mod = cell.modifier {
                switch mod {
                case .bonus(let type):
                    Image(systemName: bonusIcon(type))
                        .font(.system(size: cellSize * 0.45))
                        .foregroundStyle(ThemeColors.electricYellow)
                case .cursed:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: cellSize * 0.45))
                        .foregroundStyle(ThemeColors.neonPink)
                case .staticCharge:
                    Image(systemName: "bolt.fill")
                        .font(.system(size: cellSize * 0.5))
                        .foregroundStyle(ThemeColors.electricYellow)
                default: EmptyView()
                }
            }
        }

        private func bonusIcon(_ type: BonusType) -> String {
            switch type {
            case .gold: return "centsign.circle.fill"
            case .star: return "star.fill"
            case .timeBoost: return "clock.fill"
            }
        }

        private var cellBackground: Color {
            if isGhost {
                return (isGhostValid ? ThemeColors.neonCyan : ThemeColors.neonPink).opacity(0.4)
            }
            if let mod = cell.modifier, !cell.isOccupied {
                switch mod {
                case .locked: return ThemeColors.locked
                case .bonus: return ThemeColors.electricYellow.opacity(0.2)
                case .cursed: return ThemeColors.neonPink.opacity(0.2)
                case .staticCharge: return ThemeColors.electricYellow.opacity(0.15)
                default: break
                }
            }
            switch cell.state {
            case .empty: return zoneColor(row: pos.row, col: pos.col)
            case .filled(let color): return color.color
            case .locked: return ThemeColors.locked
            case .heavy: return ThemeColors.neonOrange.opacity(0.6)
            }
        }

        private func zoneColor(row: Int, col: Int) -> Color {
            if row < 4 && col < 4 { return ThemeColors.zoneTL }
            if row < 4 && col >= 9 { return ThemeColors.zoneTR }
            if row >= 9 && col < 4 { return ThemeColors.zoneBL }
            if row >= 9 && col >= 9 { return ThemeColors.zoneBR }
            if (row >= 4 && row < 9) && (col >= 4 && col < 9) { return ThemeColors.zoneCenter }
            return ThemeColors.cellEmpty
        }
    }

    private var zoneOverlay: some View {
        let step = cellSize + 2
        return Group {
            zoneRect(x: 0, y: 0, w: 4, h: 4, step: step, color: ThemeColors.electricYellow)
            zoneRect(x: 9 * step, y: 0, w: 4, h: 4, step: step, color: ThemeColors.electricYellow)
            zoneRect(x: 0, y: 9 * step, w: 4, h: 4, step: step, color: ThemeColors.electricYellow)
            zoneRect(x: 9 * step, y: 9 * step, w: 4, h: 4, step: step, color: ThemeColors.electricYellow)
            zoneRect(x: 4 * step, y: 4 * step, w: 5, h: 5, step: step, color: ThemeColors.neonPurple)
        }
    }
    
    private func zoneRect(x: CGFloat, y: CGFloat, w: Int, h: Int, step: CGFloat, color: Color) -> some View {
        let width = CGFloat(w) * step - 2
        let height = CGFloat(h) * step - 2
        return RoundedRectangle(cornerRadius: 8)
            .stroke(color.opacity(0.3), lineWidth: 1)
            .frame(width: width, height: height)
            .position(x: x + width/2, y: y + height/2)
    }
}

#Preview {
    GridView(board: BoardViewModel(), cellSize: 38)
        .padding()
        .background(ThemeColors.cosmicBlack)
}
