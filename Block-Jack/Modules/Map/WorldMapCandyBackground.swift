//
//  WorldMapCandyBackground.swift
//  Block-Jack
//
//  Dünya 3 — CANDY LAB arkaplanı. Neon şeker laboratuvarı estetiği:
//  yumuşak pastel grid + sakız pembe / mint vurgular.
//

import SwiftUI

struct WorldMapCandyBackground: View {
    private let tileSize: CGFloat = 9
    private let noiseSeed: Int = 33

    var body: some View {
        Canvas { ctx, size in
            drawTiles(ctx: ctx, size: size)
            drawBubbles(ctx: ctx, size: size)
            drawSprinkles(ctx: ctx, size: size)
        }
        .drawingGroup(opaque: true)
        .background(Color(hex: "#07081A"))
        .ignoresSafeArea()
    }

    private func drawTiles(ctx: GraphicsContext, size: CGSize) {
        let colors: [Color] = [
            Color(hex: "#121338"),
            Color(hex: "#0E2239"),
            Color(hex: "#1B1241"),
            Color(hex: "#16204A")
        ]

        var col = 0
        var x: CGFloat = 0
        while x < size.width {
            var row = 0
            var y: CGFloat = 0
            while y < size.height {
                let v = sin(Double(x) * 0.18) * cos(Double(y) * 0.16)
                if v > -0.05 {
                    let idx = abs((col + row + ((col * row) % 5))) % colors.count
                    let rect = CGRect(x: x, y: y, width: tileSize, height: tileSize)
                    ctx.fill(Path(rect), with: .color(colors[idx].opacity(0.8)))
                }
                y += tileSize
                row += 1
            }
            x += tileSize
            col += 1
        }
    }

    private func drawBubbles(ctx: GraphicsContext, size: CGSize) {
        let count = 14
        let w = Int(max(size.width, 1))
        let h = Int(max(size.height, 1))
        for i in 0..<count {
            let seed = i &+ noiseSeed
            let sx = CGFloat((seed &* 97) % w)
            let sy = CGFloat((seed &* 53) % h)
            let r = CGFloat(18 + ((seed &* 7) % 46))
            let bubble = Path(ellipseIn: CGRect(x: sx, y: sy, width: r, height: r))
            let c = (i % 2 == 0) ? Color(hex: "#FF4FD8") : Color(hex: "#38FFD2")
            ctx.stroke(bubble, with: .color(c.opacity(0.15)), lineWidth: 1)
        }
    }

    private func drawSprinkles(ctx: GraphicsContext, size: CGSize) {
        let count = 80
        let w = Int(max(size.width, 1))
        let h = Int(max(size.height, 1))
        for i in 0..<count {
            let seed = i &+ (noiseSeed &* 5)
            let sx = CGFloat((seed &* 131) % w)
            let sy = CGFloat((seed &* 41) % h)
            let len: CGFloat = (i % 6 == 0) ? 5 : 3
            let rect = CGRect(x: sx, y: sy, width: len, height: 1)
            let c: Color
            switch i % 3 {
            case 0: c = Color(hex: "#FF4FD8")
            case 1: c = Color(hex: "#38FFD2")
            default: c = Color(hex: "#FFE66B")
            }
            ctx.fill(Path(rect), with: .color(c.opacity(0.18)))
        }
    }
}

#Preview {
    ZStack {
        WorldMapCandyBackground()
        WorldMapNeonScanline()
    }
}

