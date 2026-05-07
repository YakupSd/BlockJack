//
//  WorldCityNeonNode.swift
//  Block-Jack
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
            VStack(spacing: 8) {
                nodeBadge
                label
            }
            .padding(10)
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
            // Glow layer
            if level.status != .locked {
                HexagonShape()
                    .stroke(accent, lineWidth: 2)
                    .blur(radius: 8)
                    .opacity(level.status == .available ? 0.6 : 0.3)
                    .frame(width: 48, height: 48)
            }

            // Main body
            HexagonShape()
                .fill(bodyFill)
                .frame(width: 42, height: 42)
                .overlay(
                    HexagonShape()
                        .stroke(accent.opacity(level.status == .locked ? 0.2 : 0.8), lineWidth: isPlayerHere ? 3 : 1.5)
                )

            // Animated Pulse for active level
            if level.status == .available {
                HexagonShape()
                    .stroke(accent, lineWidth: 1.5)
                    .scaleEffect(pulse ? 1.4 : 1.0)
                    .opacity(pulse ? 0 : 0.8)
                    .frame(width: 42, height: 42)
                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulse)
            }

            // Icon/Text
            content
            
            if level.status == .locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if level.status == .locked {
            EmptyView()
        } else if level.type == .boss {
            Image(systemName: "skull.fill")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(accent)
                .shadow(color: accent.opacity(0.8), radius: 5)
        } else {
            Text("\(level.id)")
                .font(.setCustomFont(name: .InterBlack, size: 16))
                .foregroundStyle(accent)
                .shadow(color: accent.opacity(0.8), radius: 3)
        }
    }

    private var label: some View {
        Text(shortLabel)
            .font(.setCustomFont(name: .InterBold, size: 9))
            .tracking(1.5)
            .foregroundStyle(labelColor)
            .opacity(level.status == .locked ? 0.4 : 1.0)
    }

    // MARK: Styling helpers
    private var shortLabel: String {
        if level.type == .boss { return "CRITICAL" }
        switch level.status {
        case .completed: return "CLEARED"
        case .available: return "ACTIVE"
        case .locked:    return "LOCKED"
        }
    }

    private var accent: Color {
        if level.type == .boss { return ThemeColors.neonPink }
        switch level.status {
        case .completed: return ThemeColors.neonPurple
        case .available: return ThemeColors.neonCyan
        case .locked:    return Color.white.opacity(0.1)
        }
    }

    private var bodyFill: Color {
        if level.status == .locked { return Color.black.opacity(0.2) }
        return accent.opacity(0.05)
    }

    private var labelColor: Color {
        level.status == .locked ? .white.opacity(0.3) : accent
    }
}

// MARK: - Neon Player Cursor
struct WorldNeonPlayerCursor: View {
    @State private var bob: CGFloat = 0
    @State private var spin: Double = 0

    var body: some View {
        ZStack {
            DiamondShape()
                .stroke(ThemeColors.neonCyan, lineWidth: 2)
                .frame(width: 24, height: 24)
                .shadow(color: ThemeColors.neonCyan, radius: 10)

            DiamondShape()
                .fill(ThemeColors.neonCyan.opacity(0.3))
                .frame(width: 14, height: 14)
        }
        .rotationEffect(.degrees(spin))
        .offset(y: bob)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                bob = -6
            }
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                spin = 360
            }
        }
    }
}

// MARK: - Neon Path Connections
struct WorldNeonPathConnections: View {
    let levels: [WorldLevel]
    let positions: [Int: CGPoint]
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

                let isCompleted = fromLevel.status == .completed
                let isAccessible = isCompleted && toLevel.status != .locked

                var path = Path()
                path.move(to: start)
                path.addLine(to: end)

                // Outer glow
                if isCompleted {
                    ctx.stroke(path, with: .color(ThemeColors.neonPurple.opacity(0.2)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                }

                // Main line
                if isCompleted {
                    ctx.stroke(path, with: .color(ThemeColors.neonPurple), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                } else if isAccessible {
                    ctx.stroke(path, with: .color(ThemeColors.neonCyan.opacity(0.5)), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [8, 6]))
                } else {
                    ctx.stroke(path, with: .color(Color.white.opacity(0.05)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                }
                
                // Flowing dot for completed segments
                if isCompleted {
                    let mid = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
                    ctx.fill(Path(ellipseIn: CGRect(x: mid.x - 3, y: mid.y - 3, width: 6, height: 6)), with: .color(ThemeColors.neonPink))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Shapes
