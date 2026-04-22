//
//  WorldCityNeonNode.swift
//  Block-Jack
//
//  Dünya 1 — NEON CYBERPUNK sektör node'u, yol bağlantıları, oyuncu işaretçisi.
//
//  Görsel dil:
//    • Hexagonal / diamond node — neon stroke + yumuşak dış glow
//    • Merkeze seviye numarası (boss ise kafatası) — neon glow font
//    • Aktif seviyede pulse ring, kilitli seviyede loş + kilit ikonu
//    • Yol: parlayan cyan/magenta, tamamlanmış path'lerde akıcı
//
//  Pixel variant (WorldCityNodeView) silinmedi — ileride başka dünya için
//  yedekte duruyor.
//

import SwiftUI

// MARK: - Neon City Node

struct WorldCityNeonNode: View {
    let level: WorldLevel
    let isPlayerHere: Bool
    let onTap: () -> Void

    @State private var pulse: Bool = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                nodeBadge
                label
            }
            // SE'de kolay dokunma — görsel büyümez, tap hedefi geniş
            .padding(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear {
            if level.status == .available { pulse = true }
        }
    }

    // MARK: Node badge (hexagonal)

    private var nodeBadge: some View {
        ZStack {
            // Dış glow — node'un aurasını çiziyor
            if level.status != .locked {
                HexagonShape()
                    .stroke(accent, lineWidth: 1.2)
                    .blur(radius: 6)
                    .opacity(level.type == .boss ? 0.9 : 0.55)
                    .frame(width: 46, height: 46)
            }

            // Ana gövde — neon border + koyu iç
            HexagonShape()
                .fill(bodyFill)
                .frame(width: 38, height: 38)
                .overlay(
                    HexagonShape()
                        .stroke(accent, lineWidth: level.type == .boss ? 2 : 1.5)
                        .opacity(level.status == .locked ? 0.45 : 1)
                )

            // Aktif seviye — ekstra ring pulse (kullanıcı bakışını çeker)
            if level.status == .available {
                HexagonShape()
                    .stroke(accent, lineWidth: 1)
                    .scaleEffect(pulse ? 1.35 : 1.0)
                    .opacity(pulse ? 0.0 : 0.75)
                    .frame(width: 38, height: 38)
                    .animation(
                        .easeOut(duration: 1.3).repeatForever(autoreverses: false),
                        value: pulse
                    )
            }

            // İç içerik — seviye numarası veya boss kafatası
            content

            // Kilit overlay
            if level.status == .locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: "#506080"))
            }

            // Oyuncu burada — chevron üstte (dekoratif, ayrı cursor zaten hover)
            if isPlayerHere {
                HexagonShape()
                    .stroke(ThemeColors.neonCyan.opacity(0.85), lineWidth: 1)
                    .frame(width: 52, height: 52)
                    .shadow(color: ThemeColors.neonCyan.opacity(0.8), radius: 8)
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if level.status == .locked {
            EmptyView()
        } else if level.type == .boss {
            // Boss — küçük kafatası sembolü
            Image(systemName: "skull.fill")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(accent)
                .shadow(color: accent.opacity(0.9), radius: 4)
        } else {
            Text("\(level.id)")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(accent)
                .shadow(color: accent.opacity(0.9), radius: 3)
        }
    }

    private var label: some View {
        Text(shortLabel)
            .font(.system(size: 9, weight: .black, design: .monospaced))
            .tracking(1.3)
            .foregroundStyle(labelColor)
            .shadow(color: accent.opacity(0.7), radius: 3)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }

    // MARK: Styling helpers

    private var shortLabel: String {
        if level.type == .boss { return "BOSS" }
        switch level.status {
        case .completed: return "CLEAR"
        case .available: return "S-\(level.id)"
        case .locked:    return "//LOCKED"
        }
    }

    private var accent: Color {
        if level.type == .boss { return ThemeColors.neonPink }
        switch level.status {
        case .completed: return ThemeColors.neonPurple
        case .available: return ThemeColors.neonCyan
        case .locked:    return Color(hex: "#3B4468")
        }
    }

    private var bodyFill: Color {
        if level.type == .boss { return Color(hex: "#1A0814").opacity(0.92) }
        switch level.status {
        case .completed: return Color(hex: "#150B28").opacity(0.88)
        case .available: return Color(hex: "#061A26").opacity(0.9)
        case .locked:    return Color(hex: "#0A0C18").opacity(0.85)
        }
    }

    private var labelColor: Color {
        level.status == .locked ? Color(hex: "#3B4468") : accent
    }
}

// MARK: - Neon Player Cursor

/// Sürekli hafif bob + rotate yapan neon diamond işaretçi. Aktif seviyenin
/// hemen üstünde hover eder — oyuncuya "buradasın" demek için.
struct WorldNeonPlayerCursor: View {
    @State private var bob: CGFloat = 0
    @State private var spin: Double = 0

    var body: some View {
        ZStack {
            DiamondShape()
                .stroke(ThemeColors.neonCyan, lineWidth: 1.5)
                .frame(width: 22, height: 22)
                .shadow(color: ThemeColors.neonCyan, radius: 8)

            DiamondShape()
                .fill(ThemeColors.neonCyan.opacity(0.25))
                .frame(width: 14, height: 14)
                .shadow(color: ThemeColors.neonCyan.opacity(0.85), radius: 5)
        }
        .rotationEffect(.degrees(spin))
        .offset(y: bob)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                bob = -4
            }
            withAnimation(.linear(duration: 3.2).repeatForever(autoreverses: false)) {
                spin = 360
            }
        }
    }
}

// MARK: - Neon Path Connections

/// Tamamlanan yol: neon magenta glow + akıcı görünüm.
/// Devam edecek yol: ince cyan kesik çizgiler.
/// Kilitli hedefe giden yol: koyu solid.
struct WorldNeonPathConnections: View {
    let levels: [WorldLevel]
    let positions: [Int: CGPoint]            // normalized 0..1
    let segments: [WorldPathSegment]

    var body: some View {
        Canvas { ctx, size in
            for seg in segments {
                guard let a = positions[seg.fromLevelId],
                      let b = positions[seg.toLevelId],
                      let fromLevel = levels.first(where: { $0.id == seg.fromLevelId }),
                      let toLevel = levels.first(where: { $0.id == seg.toLevelId })
                else { continue }

                let start = CGPoint(x: a.x * size.width, y: a.y * size.height)
                let end = CGPoint(x: b.x * size.width, y: b.y * size.height)

                let done = fromLevel.status == .completed
                let openNext = done && toLevel.status != .locked

                var path = Path()
                path.move(to: start)
                path.addLine(to: end)

                // Alt kat — koyu baz
                ctx.stroke(
                    path,
                    with: .color(Color(hex: "#0F1430")),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )

                // Ana çizgi
                if done {
                    // Tamamlanmış — parlak magenta
                    ctx.stroke(
                        path,
                        with: .color(ThemeColors.neonPurple.opacity(0.9)),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                } else if openNext {
                    // Şu an açık hedef — parlak cyan dashed
                    ctx.stroke(
                        path,
                        with: .color(ThemeColors.neonCyan.opacity(0.85)),
                        style: StrokeStyle(lineWidth: 1.8, lineCap: .round, dash: [6, 5])
                    )
                } else {
                    // Kilitli hedef — mat kesik
                    ctx.stroke(
                        path,
                        with: .color(Color(hex: "#1A2040").opacity(0.85)),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [3, 6])
                    )
                }

                // Tamamlanmış segmentte ortada küçük parlayan nokta
                if done {
                    let mid = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
                    let dot = Path(ellipseIn: CGRect(
                        x: mid.x - 3, y: mid.y - 3, width: 6, height: 6
                    ))
                    ctx.fill(dot, with: .color(ThemeColors.neonPink.opacity(0.9)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Shapes

/// Köşeli hexagonal şekil — node gövdesi için.
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = rect.midX
        let cy = rect.midY
        // Sivri tepe değil yatay altı-köşe (flat-top hex)
        let hx = w * 0.5
        let hy = h * 0.5
        let sideX = hx * 0.5

        path.move(to: CGPoint(x: cx - hx + sideX, y: cy - hy))
        path.addLine(to: CGPoint(x: cx + hx - sideX, y: cy - hy))
        path.addLine(to: CGPoint(x: cx + hx,        y: cy))
        path.addLine(to: CGPoint(x: cx + hx - sideX, y: cy + hy))
        path.addLine(to: CGPoint(x: cx - hx + sideX, y: cy + hy))
        path.addLine(to: CGPoint(x: cx - hx,        y: cy))
        path.closeSubpath()
        return path
    }
}

/// 45° döndürülmüş kare — player cursor için.
struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}
