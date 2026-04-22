//
//  WorldMapPixelBackgroundView.swift
//  Block-Jack
//
//  ⚠️ REFERENCE — Dünya 2 (Concrete Ruins) için `WorldMapConcreteBackground`
//  bu dosyanın piksel-retro Canvas dilini referans alarak beton/pas paletine
//  uyarlandı. Bu dosya "orijinal palet" olarak korunuyor; ileride başka bir
//  dünya (ör. Candy Lab) için alternatif piksel varyant üretilirse buradan
//  türetilir. Üretim render yolunda değildir.
//
//  Harita için piksel-retro arkaplan. Canvas ile çizilir (perf için drawingGroup).
//  Hiçbir veri veya game logic'e bağlı değil — sadece dekoratif.
//

import SwiftUI

struct WorldMapPixelBackgroundView: View {
    // Çini boyutu. 8 klasik chip-tune estetiği — SE'de bile akıcı kalır.
    private let tileSize: CGFloat = 8

    // Deterministik yıldızlar (random animasyon değil — GPU/CPU yükünü sabit tutar).
    private let starSeed: Int = 41

    var body: some View {
        Canvas { ctx, size in
            drawTiles(ctx: ctx, size: size)
            drawStars(ctx: ctx, size: size)
        }
        .drawingGroup(opaque: true)
        .background(ThemeColors.mapBg)
        .ignoresSafeArea()
    }

    private func drawTiles(ctx: GraphicsContext, size: CGSize) {
        let tiles: [Color] = [
            ThemeColors.mapTile1, ThemeColors.mapTile2,
            ThemeColors.mapTile3, ThemeColors.mapTile4
        ]
        var col = 0
        var x: CGFloat = 0
        while x < size.width {
            var row = 0
            var y: CGFloat = 0
            while y < size.height {
                // Noise benzeri deterministik desen — sin/cos ile
                let v = sin(Double(x) * 0.3) * cos(Double(y) * 0.2)
                if v > 0.3 {
                    let idx = (col + row) % tiles.count
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

    private func drawStars(ctx: GraphicsContext, size: CGSize) {
        // ~80 sabit yıldız (1x1 nokta)
        let count = 80
        let w = Int(max(size.width, 1))
        let h = Int(max(size.height, 1))
        for i in 0..<count {
            let seed = i &+ starSeed
            let sx = CGFloat((seed &* 73) % w)
            let sy = CGFloat((seed &* 47) % h)
            let kind = i % 3
            let color: Color
            switch kind {
            case 0: color = Color.white.opacity(0.14)
            case 1: color = Color(hex: "#4488ff").opacity(0.09)
            default: color = ThemeColors.pixelEye.opacity(0.08)
            }
            let rect = CGRect(x: sx, y: sy, width: 1, height: 1)
            ctx.fill(Path(rect), with: .color(color))
        }
    }
}

// MARK: - Yatay grid çini (hafif vignette efekti için opsiyonel overlay)
struct WorldMapScanlineOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let color = GraphicsContext.Shading.color(Color.black.opacity(0.08))
                let step: CGFloat = 3
                var y: CGFloat = 0
                while y < size.height {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                    ctx.fill(Path(rect), with: color)
                    y += step
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ZStack {
        WorldMapPixelBackgroundView()
        WorldMapScanlineOverlay()
    }
}
