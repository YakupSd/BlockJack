//
//  WorldMapCoreBackground.swift
//  Block-Jack
//
//  Dünya 5 — CORE SINGULARITY arkaplanı. Yüksek teknoloji çekirdek:
//  koyu zemin + mor manyetik çizgiler + parlak çekirdek pulse.
//

import SwiftUI

struct WorldMapCoreBackground: View {
    private let tileSize: CGFloat = 8
    private let noiseSeed: Int = 101

    var body: some View {
        Canvas { ctx, size in
            drawCoreGrid(ctx: ctx, size: size)
            drawMagneticStreaks(ctx: ctx, size: size)
            drawCorePulse(ctx: ctx, size: size)
        }
        .drawingGroup(opaque: true)
        .background(Color(hex: "#02010A"))
        .ignoresSafeArea()
    }

    private func drawCoreGrid(ctx: GraphicsContext, size: CGSize) {
        let colors: [Color] = [
            Color(hex: "#110B2D"),
            Color(hex: "#09081C"),
            Color(hex: "#1A0B3D"),
            Color(hex: "#0C0A24")
        ]
        var col = 0
        var x: CGFloat = 0
        while x < size.width {
            var row = 0
            var y: CGFloat = 0
            while y < size.height {
                let v = sin(Double(x) * 0.24) * cos(Double(y) * 0.20)
                if v > 0.10 {
                    let idx = abs((col + row + ((col * row) % 4))) % colors.count
                    let rect = CGRect(x: x, y: y, width: tileSize, height: tileSize)
                    ctx.fill(Path(rect), with: .color(colors[idx].opacity(0.9)))
                }
                y += tileSize
                row += 1
            }
            x += tileSize
            col += 1
        }
    }

    private func drawMagneticStreaks(ctx: GraphicsContext, size: CGSize) {
        let count = 18
        let w = Int(max(size.width, 1))
        let h = Int(max(size.height, 1))
        for i in 0..<count {
            let seed = i &+ noiseSeed
            let sx = CGFloat((seed &* 137) % w)
            let sy = CGFloat((seed &* 59) % h)
            let length = CGFloat(60 + ((seed &* 11) % 160))
            let rect = CGRect(x: sx, y: sy, width: 1, height: length)
            let c = (i % 2 == 0) ? Color(hex: "#B14CFF") : Color(hex: "#FF4FD8")
            ctx.fill(Path(rect), with: .color(c.opacity(0.12)))
        }
    }

    private func drawCorePulse(ctx: GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width * 0.52, y: size.height * 0.42)
        let r: CGFloat = min(size.width, size.height) * 0.55

        // Outer glow rings (deterministic)
        for i in 0..<4 {
            let rr = r * (0.18 + CGFloat(i) * 0.06)
            let p = Path(ellipseIn: CGRect(x: center.x - rr, y: center.y - rr, width: rr * 2, height: rr * 2))
            ctx.stroke(p, with: .color(Color(hex: "#B14CFF").opacity(0.06)), lineWidth: 2)
        }
    }
}

#Preview {
    ZStack {
        WorldMapCoreBackground()
        WorldMapNeonScanline()
    }
}

