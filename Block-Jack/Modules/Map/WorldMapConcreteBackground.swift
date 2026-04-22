//
//  WorldMapConcreteBackground.swift
//  Block-Jack
//
//  Dünya 2 — CONCRETE RUINS arkaplanı. Endüstriyel harabeler estetiği:
//  beton çinili zemin + pas turuncusu sızıntılar + yosun yeşili vurgular.
//  Pixel-retro dil korunuyor; sadece palet değişiyor.
//
//  Sadece view katmanı — hiçbir game logic / veriye bağlı değildir.
//

import SwiftUI

struct WorldMapConcreteBackground: View {
    /// Çini boyutu. 8px ile 12 arası deneyip 10 geldi — beton hissi biraz
    /// daha iri taşlı olsun diye. Dünya 1 neon griddeki 8'ten farklılaştı.
    private let tileSize: CGFloat = 10

    /// Deterministik "damla" ve çatlak seed'i. Her frame aynı deseni üretir.
    private let noiseSeed: Int = 17

    var body: some View {
        Canvas { ctx, size in
            drawConcreteTiles(ctx: ctx, size: size)
            drawRustDrips(ctx: ctx, size: size)
            drawMossSpecks(ctx: ctx, size: size)
        }
        .drawingGroup(opaque: true)
        .background(ThemeColors.ruinBg)
        .ignoresSafeArea()
    }

    // MARK: - Beton çini deseni
    private func drawConcreteTiles(ctx: GraphicsContext, size: CGSize) {
        let tiles: [Color] = [
            ThemeColors.ruinTile1, ThemeColors.ruinTile2,
            ThemeColors.ruinTile3, ThemeColors.ruinTile4
        ]
        var col = 0
        var x: CGFloat = 0
        while x < size.width {
            var row = 0
            var y: CGFloat = 0
            while y < size.height {
                // Neon variant'taki sin/cos noise ile benzer ama threshold
                // yüksek tutuldu — daha yoğun "kapalı" beton görünümü.
                let v = sin(Double(x) * 0.22) * cos(Double(y) * 0.18)
                if v > 0.15 {
                    let idx = (col + row + ((col * row) % 3)) % tiles.count
                    let rect = CGRect(x: x, y: y, width: tileSize, height: tileSize)
                    ctx.fill(Path(rect), with: .color(tiles[idx]))
                }
                y += tileSize
                row += 1
            }
            x += tileSize
            col += 1
        }
    }

    // MARK: - Pas turuncusu dikey damlalar (sızıntı hissi)
    private func drawRustDrips(ctx: GraphicsContext, size: CGSize) {
        let count = 14
        let w = Int(max(size.width, 1))
        let h = Int(max(size.height, 1))
        for i in 0..<count {
            let seed = i &+ noiseSeed
            let sx = CGFloat((seed &* 131) % w)
            let startY = CGFloat((seed &* 61) % (h / 2))
            let length = CGFloat(40 + ((seed &* 7) % 120))
            let rect = CGRect(x: sx, y: startY, width: 1, height: length)
            ctx.fill(Path(rect), with: .color(ThemeColors.ruinRustAccent.opacity(0.18)))
        }
    }

    // MARK: - Yosun benekleri
    private func drawMossSpecks(ctx: GraphicsContext, size: CGSize) {
        let count = 60
        let w = Int(max(size.width, 1))
        let h = Int(max(size.height, 1))
        for i in 0..<count {
            let seed = i &+ (noiseSeed &* 3)
            let sx = CGFloat((seed &* 79) % w)
            let sy = CGFloat((seed &* 41) % h)
            let sizePx: CGFloat = (i % 5 == 0) ? 2 : 1
            let rect = CGRect(x: sx, y: sy, width: sizePx, height: sizePx)
            ctx.fill(Path(rect), with: .color(ThemeColors.ruinMossAccent.opacity(0.22)))
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        WorldMapConcreteBackground()
        WorldMapScanlineOverlay()
    }
}
