//
//  WorldCityNodeView.swift
//  Block-Jack
//
//  ⚠️ RESERVE — Dünya 1 (Neon Cyberpunk) için KULLANILMIYOR.
//  Piksel-retro node + path + player sprite variant'ı. Gelecek dünyalarda
//  (muhtemelen Concrete Ruins veya Candy Lab) tema olarak geri gelecek.
//  Lütfen silmeyin. WorldMapView şu anda WorldCityNeonNode kullanıyor.
//
//  Piksel-retro sektör node'u + içindeki Canvas piksel ikonu + yol çizimi.
//

import SwiftUI

// MARK: - City Node View
struct WorldCityNodeView: View {
    let level: WorldLevel
    let isPlayerHere: Bool
    let onTap: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                nodeTile
                label
            }
            // Tap hedefi node görselinden daha geniş olsun (SE'de kolay dokunma)
            .padding(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear {
            if level.status == .available { pulse = true }
        }
    }

    // MARK: Node rozet
    private var nodeTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(nodeBg)
                .frame(width: 36, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(nodeBorder, lineWidth: level.status == .available ? 1.5 : 1)
                        .opacity(level.status == .locked ? 0.35 : 1)
                )
                .overlay(activePulseRing)

            // İkonun kendisi (piksel art Canvas)
            WorldCityPixelIcon(level: level)
                .frame(width: 28, height: 28)
                .opacity(level.status == .locked ? 0.35 : 1)

            if level.status == .locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(hex: "#667788"))
                    .offset(x: 10, y: 10)
            }

            // Oyuncu burada ise node'un etrafında cyan glow aura — ayrı bir
            // sprite zaten üstte hover ediyor, çift gösterim yerine yalnızca
            // ışıltı ile vurgu yapalım
            if isPlayerHere {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(ThemeColors.pixelEye.opacity(0.7), lineWidth: 1)
                    .frame(width: 44, height: 44)
                    .shadow(color: ThemeColors.pixelEye.opacity(0.7), radius: 6)
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private var activePulseRing: some View {
        if level.status == .available {
            RoundedRectangle(cornerRadius: 4)
                .stroke(ThemeColors.nodeCurrent, lineWidth: 1)
                .scaleEffect(pulse ? 1.22 : 1.0)
                .opacity(pulse ? 0.0 : 0.7)
                .frame(width: 36, height: 36)
                .animation(
                    .easeOut(duration: 1.2).repeatForever(autoreverses: false),
                    value: pulse
                )
        }
    }

    private var label: some View {
        Text(shortLabel)
            .font(.pixel(7))
            .foregroundColor(labelColor)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .shadow(color: .black.opacity(0.9), radius: 0, x: 1, y: 1)
    }

    // MARK: - Computed styles
    /// Label: "S-3", "S-15" vs. Boss seviyeleri için "BOSS".
    private var shortLabel: String {
        if level.type == .boss { return "BOSS" }
        return "S-\(level.id)"
    }

    private var nodeBg: Color {
        if level.type == .boss { return ThemeColors.nodeBgBoss }
        switch level.status {
        case .completed: return ThemeColors.nodeBgCompleted
        case .available: return ThemeColors.nodeBgCurrent
        case .locked:    return ThemeColors.nodeBgLocked
        }
    }

    private var nodeBorder: Color {
        if level.type == .boss { return ThemeColors.nodeBoss }
        switch level.status {
        case .completed: return ThemeColors.nodeCompleted
        case .available: return ThemeColors.nodeCurrent
        case .locked:    return ThemeColors.nodeLocked
        }
    }

    private var labelColor: Color {
        if level.type == .boss { return ThemeColors.nodeBoss }
        switch level.status {
        case .completed: return ThemeColors.nodeCompleted
        case .available: return ThemeColors.nodeCurrent
        case .locked:    return Color(hex: "#445566")
        }
    }
}

// MARK: - Pixel Icon (Canvas)
/// 7x7 pikselden oluşan basit retro şehir/boss ikonu. Her hücre 4pt.
struct WorldCityPixelIcon: View {
    let level: WorldLevel

    private let gridSize: Int = 7

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let cell = min(size.width, size.height) / CGFloat(gridSize)
                let pattern = pattern
                for (r, row) in pattern.enumerated() {
                    for (c, v) in row.enumerated() where v != 0 {
                        let rect = CGRect(
                            x: CGFloat(c) * cell,
                            y: CGFloat(r) * cell,
                            width: cell,
                            height: cell
                        )
                        ctx.fill(Path(rect), with: .color(color(for: v)))
                    }
                }
            }
        }
    }

    // 0 = boş, 1 = ana renk, 2 = detay rengi, 3 = gölge
    private var pattern: [[Int]] {
        if level.type == .boss {
            // Kurukafa silueti
            return [
                [0,0,1,1,1,0,0],
                [0,1,1,1,1,1,0],
                [1,1,2,1,2,1,1],
                [1,1,1,1,1,1,1],
                [0,1,3,3,3,1,0],
                [0,0,1,0,1,0,0],
                [0,1,0,1,0,1,0],
            ]
        }
        switch level.id % 4 {
        case 0:
            // Kule
            return [
                [0,0,1,1,1,0,0],
                [0,0,1,2,1,0,0],
                [0,0,1,1,1,0,0],
                [0,1,1,1,1,1,0],
                [0,1,2,1,2,1,0],
                [1,1,1,1,1,1,1],
                [1,3,1,1,1,3,1],
            ]
        case 1:
            // Depo (kare ev)
            return [
                [0,0,1,1,1,0,0],
                [0,1,1,1,1,1,0],
                [1,1,1,1,1,1,1],
                [1,2,2,1,2,2,1],
                [1,1,1,1,1,1,1],
                [1,1,3,3,3,1,1],
                [0,0,0,0,0,0,0],
            ]
        case 2:
            // Fabrika — iki baca
            return [
                [0,1,0,0,0,1,0],
                [0,1,0,0,0,1,0],
                [0,1,1,1,1,1,0],
                [1,1,2,1,2,1,1],
                [1,1,1,1,1,1,1],
                [1,3,1,3,1,3,1],
                [0,0,0,0,0,0,0],
            ]
        default:
            // Siber kent — uzun binalar
            return [
                [0,1,0,0,0,1,0],
                [0,1,0,1,0,1,0],
                [1,1,0,1,0,1,1],
                [1,2,1,1,1,2,1],
                [1,1,1,2,1,1,1],
                [1,3,1,1,1,3,1],
                [0,0,0,0,0,0,0],
            ]
        }
    }

    private func color(for v: Int) -> Color {
        let base: Color
        if level.type == .boss {
            base = ThemeColors.nodeBoss
        } else {
            switch level.status {
            case .completed: base = ThemeColors.nodeCompleted
            case .available: base = ThemeColors.nodeCurrent
            case .locked:    base = Color(hex: "#5a6480")
            }
        }
        switch v {
        case 1: return base
        case 2: return base.opacity(0.55)  // pencere/detay
        case 3: return base.opacity(0.3)   // gölge
        default: return .clear
        }
    }
}

// MARK: - Player Sprite
struct WorldMapPlayerSprite: View {
    @State private var bob: CGFloat = 0

    var body: some View {
        Canvas { ctx, size in
            let cell = min(size.width, size.height) / 7.0
            // 7x7 minik oyuncu (retro saç + vücut)
            let p: [[Int]] = [
                [0,0,1,1,1,0,0],
                [0,1,2,2,2,1,0],
                [0,1,2,1,2,1,0],
                [0,0,1,1,1,0,0],
                [0,3,3,3,3,3,0],
                [0,3,3,3,3,3,0],
                [0,3,0,0,0,3,0],
            ]
            for (r, row) in p.enumerated() {
                for (c, v) in row.enumerated() where v != 0 {
                    let rect = CGRect(x: CGFloat(c) * cell, y: CGFloat(r) * cell, width: cell, height: cell)
                    let color: Color
                    switch v {
                    case 1: color = ThemeColors.pixelHair
                    case 2: color = ThemeColors.pixelSkin
                    default: color = ThemeColors.pixelBody
                    }
                    ctx.fill(Path(rect), with: .color(color))
                }
            }
        }
        .frame(width: 22, height: 22)
        .offset(y: bob)
        .shadow(color: ThemeColors.pixelEye.opacity(0.5), radius: 4)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                bob = -3
            }
        }
    }
}

// MARK: - Path Connections
struct WorldPathConnectionsView: View {
    let levels: [WorldLevel]
    let positions: [Int: CGPoint]            // normalized
    let segments: [WorldPathSegment]

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                for seg in segments {
                    guard let a = positions[seg.fromLevelId],
                          let b = positions[seg.toLevelId],
                          let fromLevel = levels.first(where: { $0.id == seg.fromLevelId })
                    else { continue }

                    let start = CGPoint(x: a.x * size.width, y: a.y * size.height)
                    let end = CGPoint(x: b.x * size.width, y: b.y * size.height)

                    // Segment "tamamlandı" sayılır eğer kaynak seviye tamamlandıysa.
                    // (hedef kilitli olsa bile kaynak tamamlandıysa yol yeşil kalır — aradaki
                    // segmentin geçilmiş olduğu doğru; sadece hedef daha açılmamış olur)
                    let done = fromLevel.status == .completed

                    var path = Path()
                    path.move(to: start)
                    path.addLine(to: end)

                    // Ana alt kat — koyu solid
                    ctx.stroke(
                        path,
                        with: .color(done ? ThemeColors.nodeCompleted.opacity(0.45) : ThemeColors.mapRoadDark),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    // Üst katman — kesikli noktalar
                    ctx.stroke(
                        path,
                        with: .color(done ? ThemeColors.nodeCompleted : ThemeColors.mapRoadDash),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 4])
                    )

                    if done {
                        let mid = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
                        let dot = Path(ellipseIn: CGRect(x: mid.x - 2.5, y: mid.y - 2.5, width: 5, height: 5))
                        ctx.fill(dot, with: .color(ThemeColors.nodeCompleted.opacity(0.9)))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}
