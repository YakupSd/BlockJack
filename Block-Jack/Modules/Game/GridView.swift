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

struct GridParticle: Identifiable, Equatable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    var color: Color
    var opacity: Double = 1.0
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
    @State private var activeFlashes: Set<GridPosition> = []
    @State private var flashOpacities: [GridPosition: Double] = [GridPosition: Double]()
    @State private var particles: [GridParticle] = []
    @State private var streakScale: Double = 1.0

    var body: some View {
        VStack(spacing: 2) {
            ForEach(board.grid.indices, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(board.grid[row].indices, id: \.self) { col in
                        cellView(row: row, col: col)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ThemeColors.gridDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ThemeColors.gridStroke, lineWidth: 1)
                )
        )
        .overlay(
            ZStack {
                // Zone Highlights
                zoneOverlay
            }
            .allowsHitTesting(false)
        )
        .overlay(
            ZStack {
                ForEach(particles) { p in
                    Rectangle()
                        .fill(p.color)
                        .frame(width: 4, height: 4)
                        .position(p.position)
                        .opacity(p.opacity)
                }
            }
            .allowsHitTesting(false)
        )
    }

    @ViewBuilder
    private func cellView(row: Int, col: Int) -> some View {
        let pos = GridPosition(row: row, col: col)
        let cell = board.grid[row][col]
        let isGhost = board.ghostCells.contains(pos)
        let isGhostValid = board.isGhostValid

        let isFlashing = activeFlashes.contains(pos)
        let flashOpacity = flashOpacities[pos] ?? 0.0
        
        ZStack {
            // Hücre arka planı
            RoundedRectangle(cornerRadius: 3)
                .fill(cellBackground(cell: cell, isGhost: isGhost, ghostValid: isGhostValid, row: row, col: col))
                .frame(width: cellSize, height: cellSize)
                .opacity(isPhantomMode && cell.isOccupied ? (isPhantomVisible ? 1.0 : 0.05) : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isPhantomVisible)
            
            // AAA: Clear Hint Glow
            if board.hintPositions.contains(pos) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(ThemeColors.electricYellow.opacity(0.35))
                    .frame(width: cellSize, height: cellSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(ThemeColors.electricYellow, lineWidth: 1.5)
                    )
                    .phaseAnimator([0.4, 0.8]) { content, opacity in
                        content.opacity(opacity)
                    } animation: { _ in
                        .easeInOut(duration: 0.4).repeatForever(autoreverses: true)
                    }
            }

            // Phase 8.4: Güçlendirilmiş dolu hücre glow
            if case .filled(let color) = cell.state {
                // İç parıltı
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [color.color.opacity(0.5), color.color.opacity(0.0)]),
                            center: .center,
                            startRadius: 0,
                            endRadius: cellSize * 0.8
                        )
                    )
                    .frame(width: cellSize, height: cellSize)
                    .allowsHitTesting(false)
                    .opacity(isPhantomMode ? (isPhantomVisible ? 1.0 : 0.0) : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isPhantomVisible)
                
                // Dış glow
                RoundedRectangle(cornerRadius: 3)
                    .stroke(color.color.opacity(0.4), lineWidth: 1)
                    .blur(radius: 2)
                    .frame(width: cellSize, height: cellSize)
                    .allowsHitTesting(false)
            }
            
            // Phase 5.3: Modifier Visuals
            if let mod = cell.modifier {
                switch mod {
                case .bonus(let type):
                    switch type {
                    case .gold:
                        Image(systemName: "centsign.circle.fill")
                            .font(.system(size: cellSize * 0.45))
                            .foregroundStyle(ThemeColors.electricYellow)
                            .shadow(color: ThemeColors.electricYellow, radius: 4)
                    case .star:
                        Image(systemName: "star.fill")
                            .font(.system(size: cellSize * 0.45))
                            .foregroundStyle(ThemeColors.electricYellow)
                            .shadow(color: ThemeColors.electricYellow, radius: 4)
                    case .timeBoost:
                        Image(systemName: "clock.fill")
                            .font(.system(size: cellSize * 0.45))
                            .foregroundStyle(ThemeColors.neonCyan)
                            .shadow(color: ThemeColors.neonCyan, radius: 4)
                    }
                case .cursed:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: cellSize * 0.45))
                        .foregroundStyle(ThemeColors.neonPink)
                        .shadow(color: ThemeColors.neonPink, radius: 10)
                        .symbolEffect(.pulse, isActive: true)
                case .locked:
                    EmptyView() // lock.fill zaten aşağıda cellState üzerinden gösteriliyor
                case .gravity:
                    EmptyView() // gravity visual henüz eklenmedi
                }
            }

            // Kilitli hücre ikonu
            if cell.isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: cellSize * 0.4))
                    .foregroundStyle(ThemeColors.textMuted)
            }

            // Heavy hücre sayacı
            if case .heavy(let hits) = cell.state {
                Text("\(hits)")
                    .font(.setCustomFont(name: .InterBold, size: cellSize * 0.35))
                    .foregroundStyle(ThemeColors.neonOrange)
            }
            
            // --- GHOST OVERLAY STROKE ---
            if isGhost {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isGhostValid ? ThemeColors.neonCyan : ThemeColors.neonPink, lineWidth: 2)
                    .shadow(color: isGhostValid ? ThemeColors.neonCyan : ThemeColors.neonPink, radius: 4)
                    .frame(width: cellSize, height: cellSize)
            }
            
            // Phase 8.1: Cascaded Neon Flash / Line Clear Burst
            if isFlashing {
                ZStack {
                    // Flash fill
                    if board.grid[row][col].isSynergySubject {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                AngularGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red], center: .center)
                            )
                            .opacity(flashOpacity)
                            .blur(radius: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white)
                            .opacity(flashOpacity)
                    }
                    
                    // Expanding Shockwave Ring
                    Circle()
                        .stroke(board.grid[row][col].isSynergySubject ? .white : ThemeColors.neonCyan, lineWidth: 2)
                        .scaleEffect(isFlashing ? 2.5 : 0.5)
                        .opacity(flashOpacity)
                }
                .blendMode(.screen)
                .allowsHitTesting(false)
            }
        }
        .scaleEffect(isFlashing ? 1.08 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isFlashing)
        .animation(.easeOut(duration: 0.15), value: cell.state)
        .onChange(of: flashPositions) { oldValue, newPositions in
            // Phase 8.1: Cascade - her pozisyon index'ine göre gecikmeli tetiklenir
            if let index = newPositions.firstIndex(of: pos) {
                let delay = Double(index) * 0.025 // 25ms cascade per cell
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: 0.08)) {
                        activeFlashes.insert(pos)
                        flashOpacities[pos] = 0.9
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        withAnimation(.easeOut(duration: 0.12)) {
                            activeFlashes.remove(pos)
                            flashOpacities[pos] = 0.0
                        }
                    }
                    // Phase 8.1: Emit particles
                    let synergyColor = board.grid[pos.row][pos.col].isSynergySubject
                    emitParticles(at: pos, color: synergyColor ? .clear : cellBackground(cell: cell, isGhost: false, ghostValid: true, row: pos.row, col: pos.col), isSynergy: synergyColor)
                }
            }
        }
    }
    
    // MARK: - Particle System
    
    private func emitParticles(at pos: GridPosition, color: Color, isSynergy: Bool = false) {
        let spacing: CGFloat = 2
        let step = cellSize + spacing
        let centerX = CGFloat(pos.col) * step + cellSize/2
        let centerY = CGFloat(pos.row) * step + cellSize/2
        let center = CGPoint(x: centerX, y: centerY)
        
        let wasEmpty = particles.isEmpty
        for _ in 0..<8 { // Azaltıldı: 15 → 8 (daha az render yükü)
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 2...6)
            let pColor = isSynergy ? [Color.red, .yellow, .green, .cyan, .purple].randomElement()! : color
            particles.append(GridParticle(
                position: center,
                velocity: CGPoint(x: CGFloat(Darwin.cos(angle)) * speed, y: CGFloat(Darwin.sin(angle)) * speed),
                color: pColor
            ))
        }
        // Partiküller yeni eklendiyse ve loop durmuşsa, yeniden başlat
        if wasEmpty { startParticleLoop() }
    }
    
    private func startParticleLoop() {
        func tick() {
            guard !particles.isEmpty else { return } // Boşsa durur — yeniden emitParticles başlatır
            for i in 0..<particles.count {
                particles[i].position.x += particles[i].velocity.x
                particles[i].position.y += particles[i].velocity.y
                particles[i].opacity -= 0.03
            }
            particles.removeAll { $0.opacity <= 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) {
                tick()
            }
        }
        tick()
    }



    private var zoneOverlay: some View {
        let step = cellSize + 2
        return Group {
            // Köşeler — 4x4
            zoneRect(x: 0, y: 0, w: 4, h: 4, step: step, label: nil, color: ThemeColors.electricYellow)
            zoneRect(x: 9 * step, y: 0, w: 4, h: 4, step: step, label: nil, color: ThemeColors.electricYellow)
            zoneRect(x: 0, y: 9 * step, w: 4, h: 4, step: step, label: nil, color: ThemeColors.electricYellow)
            zoneRect(x: 9 * step, y: 9 * step, w: 4, h: 4, step: step, label: nil, color: ThemeColors.electricYellow)
            // Merkez — 5x5
            zoneRect(x: 4 * step, y: 4 * step, w: 5, h: 5, step: step, label: nil, color: ThemeColors.neonPurple)
        }
    }
    
    @State private var zonePulse: Double = 0.6

    private func zoneRect(x: CGFloat, y: CGFloat, w: Int, h: Int, step: CGFloat, label: String?, color: Color) -> some View {
        let width = CGFloat(w) * step - 2
        let height = CGFloat(h) * step - 2
        return ZStack {
            // Dış glow nabız animasyonu
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(zonePulse * 0.3), lineWidth: 4)
                .blur(radius: 4)
                .frame(width: width, height: height)
            
            // Ana ince kenarlık
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(zonePulse), lineWidth: 1.2)
                .frame(width: width, height: height)
        }
        .position(x: x + width/2, y: y + height/2)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                zonePulse = 0.2
            }
        }
    }

    private func cellBackground(cell: GameCell, isGhost: Bool, ghostValid: Bool, row: Int, col: Int) -> Color {
        if isGhost {
            return ghostValid
                ? ThemeColors.neonCyan.opacity(0.4)
                : ThemeColors.neonPink.opacity(0.4)
        }
        
        // Highlight Scoring Zones (4x4 Corners, 5x5 Center)
        let isCornerZone = (row < 4 || row >= 9) && (col < 4 || col >= 9)
        let isCenterZone = (row >= 4 && row < 9) && (col >= 4 && col < 9)
        
        // Phase 5.3: Modifier Background overrides
        if let mod = cell.modifier, !cell.isOccupied {
            switch mod {
            case .locked: return ThemeColors.locked
            case .bonus: return ThemeColors.electricYellow.opacity(0.15)
            case .cursed: return ThemeColors.neonPink.opacity(0.15)
            default: break
            }
        }

        switch cell.state {
        case .empty:
            if isCenterZone {
                return ThemeColors.neonPurple.opacity(0.14)  // Merkez: mor
            }
            return isCornerZone 
                ? ThemeColors.electricYellow.opacity(0.14)   // Köşeler: sarı
                : ThemeColors.gridStroke.opacity(0.4)
        case .filled(let color):
            return color.color
        case .locked:
            return ThemeColors.locked
        case .heavy:
            return ThemeColors.neonOrange.opacity(0.6)
        }
    }
}

#Preview {
    GridView(board: BoardViewModel(), cellSize: 38)
        .padding()
        .background(ThemeColors.cosmicBlack)
}
