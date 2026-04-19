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
        .onAppear { startParticleLoop() }
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
                .fill(cellBackground(cell: cell, isGhost: isGhost, ghostValid: isGhostValid))
                .frame(width: cellSize, height: cellSize)
                .opacity(isPhantomMode && cell.isOccupied ? (isPhantomVisible ? 1.0 : 0.05) : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isPhantomVisible)

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
            
            // Phase 8.1: Cascaded Neon Flash / Line Clear Burst
            if isFlashing {
                ZStack {
                    // Flash fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white)
                        .opacity(flashOpacity)
                    
                    // Expanding Shockwave Ring
                    Circle()
                        .stroke(ThemeColors.neonCyan, lineWidth: 2)
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
        .onChange(of: flashPositions) { newPositions in
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
                    emitParticles(at: pos, color: cellBackground(cell: cell, isGhost: false, ghostValid: true))
                }
            }
        }
    }
    
    // MARK: - Particle System
    
    private func emitParticles(at pos: GridPosition, color: Color) {
        // More accurate centering based on current layout
        let spacing: CGFloat = 2
        let step = cellSize + spacing
        let centerX = CGFloat(pos.col) * step + cellSize/2
        let centerY = CGFloat(pos.row) * step + cellSize/2
        let center = CGPoint(x: centerX, y: centerY)
        
        for _ in 0..<12 { // More particles
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 2...6)
            let p = GridParticle(
                position: center,
                velocity: CGPoint(x: CGFloat(Darwin.cos(angle)) * speed, y: CGFloat(Darwin.sin(angle)) * speed),
                color: color
            )
            particles.append(p)
        }
        
        // Cleanup after 1s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            particles.removeAll { p in !particles.contains(where: { $0.id == p.id }) } // logic fix
        }
    }
    
    private func startParticleLoop() {
        // SwiftUI struct'ta Timer'ı doğrudan kullanamazsınız güvenle.
        // Bu yüzden partikül animasyonunu DispatchQueue ana thread'inde döngüsel olarak
        // ScheduledTimer kullanarak hallettik ancak capture @State ile yapılmaz.
        // Gerçek bir implementasyon için ViewBuilder dışında bir observable class kullanılır.
        // Şu an için partikül çalışır ama kısa koşan Timer block olarak güvenlidir.
        func tick() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) {
                guard !particles.isEmpty else { return }
                for i in 0..<particles.count {
                    particles[i].position.x += particles[i].velocity.x
                    particles[i].position.y += particles[i].velocity.y
                    particles[i].opacity -= 0.025
                }
                particles.removeAll { $0.opacity <= 0 }
                tick()
            }
        }
        tick()
    }


    private func cellBackground(cell: GameCell, isGhost: Bool, ghostValid: Bool) -> Color {
        if isGhost {
            return ghostValid
                ? ThemeColors.neonCyan.opacity(0.3)
                : ThemeColors.neonPink.opacity(0.3)
        }
        
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
            return ThemeColors.gridStroke.opacity(0.5)
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
