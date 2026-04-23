//
//  WorldMapAbyssBackground.swift
//  Block-Jack
//
//  Dünya 4 — DEEP ABYSS arkaplanı. Derin deniz / void hissi:
//  koyu mavi zemin + biyolüminesans noktalar + dalga çizgileri.
//

import SwiftUI

struct WorldMapAbyssBackground: View {
    private let tileSize: CGFloat = 11
    private let noiseSeed: Int = 71

    var body: some View {
        Canvas { ctx, size in
            drawVoidTiles(ctx: ctx, size: size)
            drawWaveLines(ctx: ctx, size: size)
            drawBioSpecks(ctx: ctx, size: size)
        }
        .drawingGroup(opaque: true)
        .background(Color(hex: "#030612"))
        .ignoresSafeArea()
    }

    private func drawVoidTiles(ctx: GraphicsContext, size: CGSize) {
        let colors: [Color] = [
            Color(hex: "#06102A"),
            Color(hex: "#08183B"),
            Color(hex: "#040B20"),
            Color(hex: "#07133A")
        ]

        var col = 0
        var x: CGFloat = 0
        while x < size.width {
            var row = 0
            var y: CGFloat = 0
            while y < size.height {
                let v = sin(Double(x) * 0.14) * cos(Double(y) * 0.12)
                if v > 0.05 {
                    let idx = abs((col + row + ((col * row) % 7))) % colors.count
                    let rect = CGRect(x: x, y: y, width: tileSize, height: tileSize)
                    ctx.fill(Path(rect), with: .color(colors[idx].opacity(0.85)))
                }
                y += tileSize
                row += 1
            }
            x += tileSize
            col += 1
        }
    }

    private func drawWaveLines(ctx: GraphicsContext, size: CGSize) {
        let lineCount = 9
        for i in 0..<lineCount {
            let y = size.height * (CGFloat(i) / CGFloat(lineCount)) + 20
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            let amp: CGFloat = 10 + CGFloat(i) * 1.5
            let freq = 0.018 + Double(i) * 0.001
            var x: CGFloat = 0
            while x <= size.width {
                let yy = y + sin(Double(x) * freq) * Double(amp)
                path.addLine(to: CGPoint(x: x, y: yy))
                x += 12
            }
            ctx.stroke(path, with: .color(Color(hex: "#2BE7FF").opacity(0.05)), lineWidth: 1)
        }
    }

    private func drawBioSpecks(ctx: GraphicsContext, size: CGSize) {
        let count = 110
        let w = Int(max(size.width, 1))
        let h = Int(max(size.height, 1))
        for i in 0..<count {
            let seed = i &+ (noiseSeed &* 3)
            let sx = CGFloat((seed &* 89) % w)
            let sy = CGFloat((seed &* 47) % h)
            let s: CGFloat = (i % 9 == 0) ? 2 : 1
            let rect = CGRect(x: sx, y: sy, width: s, height: s)
            let c = (i % 4 == 0) ? Color(hex: "#38FFD2") : Color(hex: "#2BE7FF")
            ctx.fill(Path(rect), with: .color(c.opacity(0.16)))
        }
    }
}

#Preview {
    ZStack {
        WorldMapAbyssBackground()
        WorldMapNeonScanline()
    }
}

