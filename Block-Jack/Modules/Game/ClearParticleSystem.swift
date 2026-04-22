//
//  ClearParticleSystem.swift
//  Block-Jack
//

import SwiftUI
import Combine // ObservableObject default ObjectWillChangePublisher için

// MARK: - Partikül Modeli

struct ClearParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var radius: CGFloat
    var color: Color
    var alpha: Double
    var decay: Double       // Her frame'de ne kadar solar
    var gravity: CGFloat    // Aşağı çekilme
}

// MARK: - Patlama Türleri

enum BurstType {
    case lineClear(color: Color)   // Satır/Sütun → neon renk yatay/dikey saçılma
    case zoneBlast(color: Color)   // 4x4/5x5 → büyük radyal patlama
    case overdriveBoom             // Architect 3x3 → kırmızı-turuncu şok dalgası
}

// MARK: - ParticleManager
//
// Performans notu:
// Eskiden Timer.publish her 1/60 saniyede `@Published particles`'i güncelliyordu.
// Bu SwiftUI tarafında **her frame her observer view'ı invalidate** ediyordu
// (battle screen tüm HUD'ları yeniden çiziyordu). Artık:
//   • `particles` @Published DEĞİL — sadece model state
//   • Tick, view'a bağlı TimelineView üzerinden çalışır (sadece Canvas redraw eder)
//   • Emit/clear zamanı manuel objectWillChange — nadir publish
// Sonuç: partikül efektleri aktifken bile oyun kasma yapmaz.

final class ClearParticleManager: ObservableObject {
    // ÖNEMLİ: @Published DEĞİL — bkz. yukarıdaki not.
    var particles: [ClearParticle] = []
    
    /// Bir partikül adımı hesaplar. TimelineView'in her schedule'ında çağrılır,
    /// view invalidate tetiklemez (SwiftUI TimelineView zaten kendi redraw'ını yapar).
    func advance() {
        guard !particles.isEmpty else { return }
        particles = particles.compactMap { p in
            var p = p
            p.x  += p.vx
            p.y  += p.vy
            p.vy += p.gravity
            p.vx *= 0.97        // hava direnci
            p.alpha -= p.decay
            return p.alpha > 0 ? p : nil
        }
    }
    
    // MARK: - Burst Tetikleyiciler
    
    /// Satır/Sütun temizlendiğinde — temizlenen hücre merkezlerine atış
    func emitLineClear(positions: [GridPosition], cellSize: CGFloat, spacing: CGFloat, burstColor: Color) {
        let step = cellSize + spacing
        var newParticles: [ClearParticle] = []
        
        for pos in positions {
            let cx = CGFloat(pos.col) * step + cellSize / 2
            let cy = CGFloat(pos.row) * step + cellSize / 2
            
            // Her hücreden 6 partiküljj      
            for _ in 0..<6 {
                let angle = Double.random(in: 0...(2 * .pi))
                let speed = CGFloat.random(in: 1.5...5.0)
                newParticles.append(ClearParticle(
                    x: cx + CGFloat.random(in: -3...3),
                    y: cy + CGFloat.random(in: -3...3),
                    vx: CGFloat(cos(angle)) * speed,
                    vy: CGFloat(sin(angle)) * speed,
                    radius: CGFloat.random(in: 1.5...3.5),
                    color: Bool.random() ? burstColor : .white,
                    alpha: 1.0,
                    decay: Double.random(in: 0.025...0.045),
                    gravity: 0.05
                ))
            }
        }
        
        particles.append(contentsOf: newParticles)
    }
    
    /// Zone (4x4/5x5) dolunca — merkez noktan büyük radyal patlama
    func emitZoneBlast(centerX: CGFloat, centerY: CGFloat, radius: CGFloat, color: Color) {
        var newParticles: [ClearParticle] = []
        let count = 60
        
        for i in 0..<count {
            let angle = (Double(i) / Double(count)) * 2 * .pi + Double.random(in: -0.3...0.3)
            let speed = CGFloat.random(in: 3.0...8.0)
            let isAccent = i % 4 == 0
            
            // Büyük parlama
            newParticles.append(ClearParticle(
                x: centerX,
                y: centerY,
                vx: CGFloat(cos(angle)) * speed,
                vy: CGFloat(sin(angle)) * speed,
                radius: isAccent ? CGFloat.random(in: 4...7) : CGFloat.random(in: 2...4),
                color: isAccent ? .white : color,
                alpha: 1.0,
                decay: Double.random(in: 0.018...0.030),
                gravity: 0.04
            ))
        }
        
        // Küçük kıvılcımlar (daha uzağa giden)
        for _ in 0..<30 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 6.0...14.0)
            newParticles.append(ClearParticle(
                x: centerX + CGFloat.random(in: -radius * 0.3...radius * 0.3),
                y: centerY + CGFloat.random(in: -radius * 0.3...radius * 0.3),
                vx: CGFloat(cos(angle)) * speed,
                vy: CGFloat(sin(angle)) * speed - 2,
                radius: CGFloat.random(in: 1.0...2.5),
                color: color,
                alpha: 0.8,
                decay: Double.random(in: 0.015...0.025),
                gravity: 0.08
            ))
        }
        
        particles.append(contentsOf: newParticles)
    }
    
    /// Architect Overdrive 3x3 — şiddetli kırmızı-turuncu patlama
    func emitOverdriveBoom(centerX: CGFloat, centerY: CGFloat) {
        var newParticles: [ClearParticle] = []
        let boomColors: [Color] = [ThemeColors.neonPink, ThemeColors.neonOrange, .white, ThemeColors.electricYellow]
        
        for _ in 0..<80 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 4.0...16.0)
            let col = boomColors.randomElement()!
            
            newParticles.append(ClearParticle(
                x: centerX + CGFloat.random(in: -20...20),
                y: centerY + CGFloat.random(in: -20...20),
                vx: CGFloat(cos(angle)) * speed,
                vy: CGFloat(sin(angle)) * speed - 3,
                radius: CGFloat.random(in: 2...6),
                color: col,
                alpha: 1.0,
                decay: Double.random(in: 0.015...0.03),
                gravity: 0.1
            ))
        }
        
        particles.append(contentsOf: newParticles)
    }
    
    func clear() {
        particles.removeAll()
    }
}

// MARK: - Canvas Overlay View
//
// TimelineView(.animation) SwiftUI'nin render loop'una bağlanır (vsync'e yakın)
// ve Canvas'ı her frame redraw eder — ama bu redraw sadece Canvas context'ini
// etkiler, hiçbir observer view invalidate olmaz. ClearParticleManager
// observer olarak view ağacına dokunmaz, sadece emit/clear'da objectWillChange
// tetikleyebilir (nadir).

struct ClearParticleOverlayView: View {
    @ObservedObject var manager: ClearParticleManager
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { _ in
            Canvas { ctx, size in
                manager.advance()
                for p in manager.particles {
                    ctx.opacity = p.alpha
                    let rect = CGRect(
                        x: p.x - p.radius,
                        y: p.y - p.radius,
                        width: p.radius * 2,
                        height: p.radius * 2
                    )
                    ctx.fill(Circle().path(in: rect), with: .color(p.color))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
