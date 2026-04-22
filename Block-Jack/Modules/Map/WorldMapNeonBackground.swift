//
//  WorldMapNeonBackground.swift
//  Block-Jack
//
//  Dünya 1 — NEON CYBERPUNK temalı dünya haritası arkaplanı.
//
//  Görsel dil:
//    • Derin lacivert → koyu mor gradient (cosmos feel)
//    • Sabit synthwave grid — perspektifli yatay + dikey neon çizgiler
//    • Horizon'da cyan/magenta glow hattı (game içinde de kullanılan renkler)
//    • İnce scan/CRT efekti
//
//  Tüm çizim performans için tek `drawingGroup(opaque: true)` altında
//  cache'leniyor — ScrollView içinde frame başına yeniden hesap yapılmıyor.
//

import SwiftUI

struct WorldMapNeonBackground: View {
    var body: some View {
        ZStack {
            // Ana gradient: uzay / derin deniz hissi
            LinearGradient(
                colors: [
                    Color(hex: "#04060F"),
                    Color(hex: "#080A1C"),
                    Color(hex: "#0C0820"),
                    Color(hex: "#05050F")
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Uzak cyan haleler — nebula hissi (iki yumuşak radial)
            RadialGradient(
                colors: [ThemeColors.neonCyan.opacity(0.18), .clear],
                center: .init(x: 0.2, y: 0.25),
                startRadius: 0,
                endRadius: 260
            )
            .blendMode(.screen)

            RadialGradient(
                colors: [ThemeColors.neonPurple.opacity(0.22), .clear],
                center: .init(x: 0.85, y: 0.65),
                startRadius: 0,
                endRadius: 340
            )
            .blendMode(.screen)

            // Synthwave grid
            WorldMapNeonGrid()

            // Horizon neon çizgisi — iki ince parıldayan şerit
            WorldMapNeonHorizon()
        }
        .ignoresSafeArea()
        .drawingGroup(opaque: true) // tek bitmap render → scroll sırasında sıfır GPU yükü
    }
}

// MARK: - Synthwave Grid

/// Yatay perspektifli ızgara. Ekranın alt yarısında yoğunlaşır,
/// üst yarıda solar.
private struct WorldMapNeonGrid: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height

            // Dikey çizgiler — alt yarıda yoğun, perspektifli
            let cols = 18
            for i in 0...cols {
                let t = CGFloat(i) / CGFloat(cols)
                // Merkezden kenarlara açılan perspektif
                let bottomX = t * w
                let topX = w / 2 + (bottomX - w / 2) * 0.35

                var path = Path()
                path.move(to: CGPoint(x: topX, y: h * 0.45))
                path.addLine(to: CGPoint(x: bottomX, y: h))

                ctx.stroke(
                    path,
                    with: .color(ThemeColors.neonPurple.opacity(0.22)),
                    lineWidth: 0.7
                )
            }

            // Yatay çizgiler — horizona doğru sıklaşan
            let rows = 14
            for i in 0...rows {
                let t = CGFloat(i) / CGFloat(rows)
                // eased: horizona yaklaştıkça çizgiler sıklaşıyor
                let eased = pow(t, 1.8)
                let y = h * 0.45 + eased * (h * 0.55)

                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: w, y: y))

                let op = 0.10 + (1 - t) * 0.15
                ctx.stroke(
                    path,
                    with: .color(ThemeColors.neonCyan.opacity(op)),
                    lineWidth: 0.6
                )
            }

            // Üstteki statik yıldızlar — deterministic (random değil)
            // Böylece her render aynı sahne, flicker yok.
            let stars: [(CGFloat, CGFloat, Double)] = [
                (0.12, 0.08, 0.9), (0.28, 0.15, 0.5), (0.45, 0.06, 0.7),
                (0.62, 0.12, 0.8), (0.74, 0.04, 0.6), (0.88, 0.18, 0.8),
                (0.08, 0.22, 0.4), (0.35, 0.28, 0.7), (0.55, 0.32, 0.5),
                (0.72, 0.24, 0.9), (0.92, 0.32, 0.4), (0.18, 0.38, 0.6),
                (0.42, 0.4, 0.3), (0.65, 0.38, 0.5), (0.82, 0.42, 0.7)
            ]
            for (sx, sy, a) in stars {
                let rect = CGRect(x: sx * w, y: sy * h, width: 1.4, height: 1.4)
                ctx.fill(Path(rect), with: .color(.white.opacity(a)))
            }
        }
    }
}

// MARK: - Horizon Line

private struct WorldMapNeonHorizon: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Ana hat — cyan
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear,
                                     ThemeColors.neonCyan.opacity(0.0),
                                     ThemeColors.neonCyan.opacity(0.65),
                                     ThemeColors.neonCyan.opacity(0.0),
                                     .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1.5)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.45)

                // Alt glow — magenta
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear,
                                     ThemeColors.neonPink.opacity(0.35),
                                     .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 5)
                    .blur(radius: 8)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.45 + 3)
            }
        }
    }
}

// MARK: - Scanline / CRT Overlay

/// İnce statik scan bantları — ekranın hareketsiz dekoratif CRT hissi.
/// `.multiply` blend modunda `WorldMapView`'de kullanılır.
struct WorldMapNeonScanline: View {
    var body: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 3.5
            var y: CGFloat = 0
            while y < size.height {
                let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                ctx.fill(Path(rect), with: .color(Color.black.opacity(0.18)))
                y += spacing
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

#Preview {
    WorldMapNeonBackground()
        .overlay(WorldMapNeonScanline().blendMode(.multiply).opacity(0.55))
}
