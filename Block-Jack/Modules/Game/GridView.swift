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
    @State private var activeFlashes: Set<GridPosition> = []
    @State private var flashOpacities: [GridPosition: Double] = [GridPosition: Double]()

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
        // NOT: Buraya .padding() EKLENMEMELİ!
        // gridOrigin hesabı GameView'de bu view'in global frame origin'ini alır,
        // ekstra padding uygulamak drag/ghost/overdrive targeting koordinatlarını kaydırır.
        // Kart görünümü (cornerRadius + stroke) GameView tarafında dış wrapper'da verilir.
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(ThemeColors.cellEmpty.opacity(0.01))
        )
        .overlay(
            zoneOverlay
                .allowsHitTesting(false)
        )
        // Performans: GridView'in içindeki ikincil partikül loop'u kaldırıldı.
        // Clear VFX'leri artık yalnızca ClearParticleManager üzerinden tek merkezden
        // akıyor (GameView'de ClearParticleOverlayView). Her hücrenin ekstra
        // particle state'i ve DispatchQueue tick'i yok → ~60fps kazanç.
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
            // Performans: implicit .animation(value: isPhantomVisible) kaldırıldı.
            // Phantom efekti artık hücre başına 169 animasyon tracker kurmuyor;
            // sadece opacity değeri direkt değişiyor (zaten opacity değişimi
            // GPU'da ucuz + görsel olarak phantom için yeterli).
            RoundedRectangle(cornerRadius: 3)
                .fill(cellBackground(cell: cell, isGhost: isGhost, ghostValid: isGhostValid, row: row, col: col))
                .frame(width: cellSize, height: cellSize)
                .opacity(isPhantomMode && cell.isOccupied ? (isPhantomVisible ? 1.0 : 0.05) : 1.0)
            
            // Patlayacak alan uyarısı — satır/sütun clear.
            // "Kalacak iki kare var → oraya kapatırsam satır patlıyor" UX'i.
            // Sarı-turuncu nabız: fill + stroke + hafif scale, böylece göze
            // "burası temizlenecek" mesajı sert şekilde geliyor.
            if board.hintPositions.contains(pos) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(ThemeColors.electricYellow.opacity(0.38))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(ThemeColors.electricYellow, lineWidth: 2)
                    )
                    .shadow(color: ThemeColors.electricYellow.opacity(0.55), radius: 5)
                    .frame(width: cellSize, height: cellSize)
                    .phaseAnimator([0, 1]) { content, phase in
                        content
                            .opacity(0.55 + phase * 0.45)
                            .scaleEffect(1.0 + phase * 0.06)
                    } animation: { _ in
                        .easeInOut(duration: 0.45).repeatForever(autoreverses: true)
                    }
                    .allowsHitTesting(false)
            }

            // Patlayacak alan uyarısı — zone clear (4x4 köşe veya 5x5 merkez).
            // Zone clear satır/sütun'dan çok daha değerli olduğu için ayrı renk:
            // mor/pembe — göz "aha, büyük patlama" diye ayırt ediyor.
            if board.hintZonePositions.contains(pos) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(ThemeColors.neonPink.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(ThemeColors.neonPink, lineWidth: 2.2)
                    )
                    .shadow(color: ThemeColors.neonPink.opacity(0.65), radius: 7)
                    .frame(width: cellSize, height: cellSize)
                    .phaseAnimator([0, 1]) { content, phase in
                        content
                            .opacity(0.55 + phase * 0.45)
                            .scaleEffect(1.0 + phase * 0.08)
                    } animation: { _ in
                        .easeInOut(duration: 0.38).repeatForever(autoreverses: true)
                    }
                    .allowsHitTesting(false)
            }

            // Dolu hücre iç parlaklığı — SADELEŞTİRİLDİ:
            // Eskiden her dolu hücrede RadialGradient + stroke+blur(2) + ek
            // implicit animation vardı. 169 hücre × 2 GPU pass'i iPhone SE'de
            // fps'i yarıya düşürüyordu. Artık tek stroke overlay yeterli —
            // renk zaten fill'de var, kenar vurgusu yeterli.
            if case .filled(let color) = cell.state {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(color.color.opacity(0.55), lineWidth: 1)
                    .frame(width: cellSize, height: cellSize)
                    .opacity(isPhantomMode ? (isPhantomVisible ? 1.0 : 0.0) : 1.0)
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
                case .staticCharge:
                    Image(systemName: "bolt.fill")
                        .font(.system(size: cellSize * 0.5))
                        .foregroundStyle(ThemeColors.electricYellow)
                        .shadow(color: ThemeColors.electricYellow, radius: 6)
                        .symbolEffect(.pulse, isActive: true)
                }
            }
            
            // Tactical Lens: en iyi yerleşim önerisi — yumuşak yeşil iç halo.
            // hintPositions sarı, bu set yeşil → drag sırasında karışmıyor.
            if board.bestPlacementCells.contains(pos) && !isGhost {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(ThemeColors.success.opacity(0.85), lineWidth: 1.6)
                    .frame(width: cellSize, height: cellSize)
                    .phaseAnimator([0.45, 0.9]) { content, opacity in
                        content.opacity(opacity)
                    } animation: { _ in
                        .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
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
            // Performans: shadow kaldırıldı. Drag sırasında 169 hücrenin bazıları
            // her frame güncelleniyor; ghost cell'de .shadow(radius: 4) eklemek
            // drag boyunca sürekli GPU pass'i demek. Stroke + kalınlık yeterli.
            if isGhost {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isGhostValid ? ThemeColors.neonCyan : ThemeColors.neonPink, lineWidth: 2)
                    .frame(width: cellSize, height: cellSize)
            }
            
            // Phase 8.1: Cascaded Neon Flash / Line Clear Burst
            // Performans: expanding Circle shockwave + blur(4) kaldırıldı.
            // Clear burst'lerini ClearParticleManager zaten canlı tutuyor;
            // burada ekstra circle+blur tamamen gereksiz overhead idi.
            if isFlashing {
                Group {
                    if board.grid[row][col].isSynergySubject {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                AngularGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red], center: .center)
                            )
                            .opacity(flashOpacity)
                    } else {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white)
                            .opacity(flashOpacity)
                    }
                }
                .blendMode(.screen)
                .allowsHitTesting(false)
            }
        }
        .scaleEffect(isFlashing ? 1.08 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isFlashing)
        // Performans: .animation(value: cell.state) kaldırıldı.
        // 169 hücrede her biri için implicit animation tracker vardı;
        // state değişimi zaten scaleEffect animasyonuyla vurgulanıyor.
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
                    // Partikül emisyonu: merkezi ClearParticleManager'da
                    // yönetiliyor (GameView.onChange(vm.particleBurst)),
                    // burada ikinci bir particle sistemi artık yok.
                }
            }
        }
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
        // Performans: dış glow + blur(4) kaldırıldı, pulse amplitüdü düşürüldü.
        // Eskiden 5 zone × (blur(4) + pulse animation) = sürekli GPU pass'i vardı.
        // Artık tek stroke + hafif opacity pulse. Görsel kimlik korundu.
        return RoundedRectangle(cornerRadius: 8)
            .stroke(color.opacity(zonePulse), lineWidth: 1.2)
            .frame(width: width, height: height)
            .position(x: x + width/2, y: y + height/2)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    zonePulse = 0.35
                }
            }
    }

    private func cellBackground(cell: GameCell, isGhost: Bool, ghostValid: Bool, row: Int, col: Int) -> Color {
        if isGhost {
            return ghostValid
                ? ThemeColors.neonCyan.opacity(0.45)
                : ThemeColors.neonPink.opacity(0.45)
        }
        
        // Phase 5.3: Modifier Background overrides
        if let mod = cell.modifier, !cell.isOccupied {
            switch mod {
            case .locked: return ThemeColors.locked
            case .bonus: return ThemeColors.electricYellow.opacity(0.22)
            case .cursed: return ThemeColors.neonPink.opacity(0.22)
            case .staticCharge: return ThemeColors.electricYellow.opacity(0.18)
            default: break
            }
        }

        switch cell.state {
        case .empty:
            // UI Revize: Zone arka plan renkleri — göz dört köşeyi ve merkezi hızlıca ayırt eder.
            // Zone sınırları mevcut ScoreEngine mantığıyla aynı (4 köşe 4x4 + merkez 5x5),
            // sadece görsel arka plan farklılaştırılıyor — skor mantığı etkilenmez.
            return zoneColorForEmptyCell(row: row, col: col)
        case .filled(let color):
            return color.color
        case .locked:
            return ThemeColors.locked
        case .heavy:
            return ThemeColors.neonOrange.opacity(0.6)
        }
    }

    /// Boş hücrenin bulunduğu zone'a göre arka plan rengi.
    /// - Köşeler (4x4): sol-üst yeşilimsi, sağ-üst mor-mavi, sol-alt kırmızımsı, sağ-alt turkuaz.
    /// - Merkez (5x5): mor.
    /// - Diğerleri: koyu #111122 (cellEmpty).
    private func zoneColorForEmptyCell(row: Int, col: Int) -> Color {
        let isTopRow = row < 4
        let isBottomRow = row >= 9
        let isLeftCol = col < 4
        let isRightCol = col >= 9
        let isCenter = (row >= 4 && row < 9) && (col >= 4 && col < 9)
        
        if isTopRow && isLeftCol { return ThemeColors.zoneTL }
        if isTopRow && isRightCol { return ThemeColors.zoneTR }
        if isBottomRow && isLeftCol { return ThemeColors.zoneBL }
        if isBottomRow && isRightCol { return ThemeColors.zoneBR }
        if isCenter { return ThemeColors.zoneCenter }
        return ThemeColors.cellEmpty
    }
}

#Preview {
    GridView(board: BoardViewModel(), cellSize: 38)
        .padding()
        .background(ThemeColors.cosmicBlack)
}
