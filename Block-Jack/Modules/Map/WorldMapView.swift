//
//  WorldMapView.swift
//  Block-Jack
//

import SwiftUI

struct WorldMapView: View {
    @StateObject var vm: WorldMapViewModel
    @EnvironmentObject var userEnv: UserEnvironment
    @Environment(\.dismiss) private var dismiss
    @State private var scrollOffset: CGFloat = 0
    
    private let mapHeight: CGFloat = 1800

    var body: some View {
        ZStack {
            // MARK: - Deep Space Neural Background
            NeuralMapBackground(scrollOffset: scrollOffset)
                .ignoresSafeArea()

            // MARK: - Holographic Map Content
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack {
                        NeuralParticleLayer(scrollOffset: scrollOffset)
                        
                        TacticalMapCanvas(vm: vm, width: UIScreen.main.bounds.width)
                            .frame(height: mapHeight)
                            .padding(.top, 160)
                            .padding(.bottom, 160)
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: ScrollOffsetKey.self, value: geo.frame(in: .global).minY)
                        }
                    )
                }
                .onPreferenceChange(ScrollOffsetKey.self) { value in
                    self.scrollOffset = value
                }
                .onAppear {
                    // Initial focus on appear
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        focusOnPlayer(proxy: proxy)
                    }
                }
                .onChange(of: vm.playerLevelId) { oldValue, newValue in
                    // Re-focus when player level changes
                    focusOnPlayer(proxy: proxy)
                }
            }

            // MARK: - Fixed UI Layers
            VStack(spacing: 0) {
                WorldMapHUDView(vm: vm) {
                    HapticManager.shared.play(.buttonTap)
                    dismiss()
                }
                Spacer()
                WorldMapBottomBarView(vm: vm)
            }
            .ignoresSafeArea(edges: .bottom)
            
            TacticalScannerEffect()
        }
        .navigationBarHidden(true)
        .sheet(item: $vm.selectedLevel) { level in
            WorldMapDetailSheet(
                slotId: vm.slotId,
                level: level,
                onEnter: {
                    vm.selectedLevel = nil
                    vm.startLevel(level)
                },
                onDismiss: {
                    vm.selectedLevel = nil
                }
            )
            .presentationDetents([.fraction(0.65), .large])
            .presentationBackground(ThemeColors.mapBg.opacity(0.98))
            .environmentObject(userEnv)
        }
    }
    
    private func focusOnPlayer(proxy: ScrollViewProxy) {
        let target = "level_anchor_\(vm.playerLevelId)"
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            proxy.scrollTo(target, anchor: .center)
        }
    }
}

// MARK: - Tactical Map Canvas

struct TacticalMapCanvas: View {
    @ObservedObject var vm: WorldMapViewModel
    let width: CGFloat
    
    var body: some View {
        ZStack {
            SplinePathView(levels: vm.levels, positions: vm.nodePositions, width: width, height: 1800)
            
            ForEach(vm.levels) { level in
                if let pos = vm.nodePositions[level.id] {
                    // Invisible Scroll Anchor
                    Color.clear
                        .frame(width: 1, height: 1)
                        .id("level_anchor_\(level.id)")
                        .position(x: pos.x * width, y: pos.y * 1800)

                    TacticalOrbNode(
                        level: level,
                        isPlayerHere: level.id == vm.playerLevelId,
                        onTap: { vm.selectLevel(level) }
                    )
                    .position(x: pos.x * width, y: pos.y * 1800)
                }
            }
            
            if let playerPos = vm.nodePositions[vm.playerLevelId] {
                TacticalPlayerMarker()
                    .position(x: playerPos.x * width, y: playerPos.y * 1800)
                    .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Path Rendering
struct SplinePathView: View {
    let levels: [WorldLevel]
    let positions: [Int: CGPoint]
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            Canvas { ctx, size in
                var path = Path()
                let sortedIds = positions.keys.sorted()
                guard !sortedIds.isEmpty else { return }
                
                let points = sortedIds.compactMap { id -> CGPoint? in
                    guard let p = positions[id] else { return nil }
                    return CGPoint(x: p.x * size.width, y: p.y * size.height)
                }
                
                if points.count > 1 {
                    path.move(to: points[0])
                    for i in 1..<points.count {
                        let mid = CGPoint(
                            x: (points[i-1].x + points[i].x) / 2,
                            y: (points[i-1].y + points[i].y) / 2
                        )
                        path.addQuadCurve(to: mid, control: points[i-1])
                    }
                    path.addLine(to: points.last!)
                }
                
                ctx.stroke(path, with: .color(ThemeColors.neonPurple.opacity(0.1)), style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                ctx.stroke(path, with: .color(ThemeColors.neonCyan.opacity(0.3)), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [10, 8]))
                
                let dotCount = 12
                for i in 0..<dotCount {
                    let progress = (time * 0.15 + Double(i) / Double(dotCount)).truncatingRemainder(dividingBy: 1.0)
                    if let pos = path.trimmedPath(from: 0, to: progress).currentPoint {
                        ctx.fill(Path(ellipseIn: CGRect(x: pos.x - 3, y: pos.y - 3, width: 6, height: 6)), with: .color(ThemeColors.neonCyan))
                        ctx.addFilter(.blur(radius: 4))
                        ctx.fill(Path(ellipseIn: CGRect(x: pos.x - 4, y: pos.y - 4, width: 8, height: 8)), with: .color(ThemeColors.neonCyan.opacity(0.4)))
                    }
                }
            }
        }
    }
}

// MARK: - Node View
struct TacticalOrbNode: View {
    let level: WorldLevel
    let isPlayerHere: Bool
    let onTap: () -> Void
    
    @State private var rotation: Double = 0
    @State private var pulse: CGFloat = 1.0
    
    var body: some View {
        let isAvailable = level.status != .locked
        let accent = level.type == .boss ? ThemeColors.neonPink : (level.status == .completed ? ThemeColors.neonPurple : ThemeColors.neonCyan)
        
        Button(action: onTap) {
            ZStack {
                if isAvailable {
                    Circle()
                        .stroke(accent.opacity(0.2), lineWidth: 1)
                        .frame(width: 64, height: 64)
                        .scaleEffect(pulse)
                        .opacity(2.0 - pulse)
                }
                
                if isAvailable {
                    Circle()
                        .stroke(accent.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [15, 45]))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(rotation))
                }
                
                ZStack {
                    Circle()
                        .fill(isAvailable ? accent.opacity(0.1) : Color.white.opacity(0.05))
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .stroke(isAvailable ? accent : Color.white.opacity(0.1), lineWidth: isPlayerHere ? 3 : 1.5)
                        .frame(width: 40, height: 40)
                    
                    if level.type == .boss {
                        Image(systemName: "skull")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(accent)
                    } else {
                        Text("\(level.id)")
                            .font(.setCustomFont(name: .InterBlack, size: 14))
                            .foregroundColor(isAvailable ? .white : .white.opacity(0.3))
                    }
                }
                .shadow(color: isAvailable ? accent.opacity(0.5) : .clear, radius: 10)
                
                if level.status == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.black)
                        .padding(4)
                        .background(ThemeColors.neonGreen)
                        .clipShape(Circle())
                        .offset(x: 15, y: -15)
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            if isAvailable {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) { rotation = 360 }
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false)) { pulse = 1.5 }
            }
        }
    }
}

// MARK: - Player Marker
struct TacticalPlayerMarker: View {
    @State private var innerSpin: Double = 0
    @State private var outerSpin: Double = 0
    var body: some View {
        ZStack {
            Image(systemName: "scope")
                .font(.system(size: 80))
                .foregroundColor(ThemeColors.neonCyan.opacity(0.2))
                .rotationEffect(.degrees(outerSpin))
            Image(systemName: "triangle.fill")
                .font(.system(size: 12))
                .foregroundColor(ThemeColors.neonCyan)
                .rotationEffect(.degrees(180))
                .offset(y: -45)
                .rotationEffect(.degrees(innerSpin))
        }
        .onAppear {
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) { outerSpin = 360 }
            withAnimation(.spring(response: 2, dampingFraction: 0.5).repeatForever(autoreverses: true)) { innerSpin = 45 }
        }
    }
}

// MARK: - Backgrounds
struct NeuralMapBackground: View {
    let scrollOffset: CGFloat
    var body: some View {
        ZStack {
            ThemeColors.mapBg.ignoresSafeArea()
            Canvas { ctx, size in
                let w = size.width, h = size.height
                let spacing: CGFloat = 50
                let offset = (scrollOffset * 0.3).truncatingRemainder(dividingBy: spacing)
                ctx.addFilter(.blur(radius: 1))
                for x in stride(from: offset, through: w, by: spacing) {
                    var p = Path(); p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: h))
                    ctx.stroke(p, with: .color(Color.white.opacity(0.03)), lineWidth: 0.5)
                }
                for y in stride(from: offset, through: h, by: spacing) {
                    var p = Path(); p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: w, y: y))
                    ctx.stroke(p, with: .color(Color.white.opacity(0.03)), lineWidth: 0.5)
                }
            }
            RadialGradient(colors: [.clear, .black.opacity(0.8)], center: .center, startRadius: 200, endRadius: 600)
        }
    }
}

struct NeuralParticleLayer: View {
    let scrollOffset: CGFloat
    @State private var particles: [NeuralParticle] = (0..<30).map { _ in NeuralParticle() }
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                for p in particles {
                    let y = (p.y * size.height + scrollOffset * p.speed).truncatingRemainder(dividingBy: size.height)
                    let rect = CGRect(x: p.x * size.width, y: y, width: p.size, height: p.size)
                    ctx.fill(Path(rect), with: .color(ThemeColors.neonCyan.opacity(p.op)))
                }
            }
        }
    }
}

struct NeuralParticle {
    let x = CGFloat.random(in: 0...1), y = CGFloat.random(in: 0...1)
    let size = CGFloat.random(in: 1...3), speed = CGFloat.random(in: 0.1...0.5), op = Double.random(in: 0.1...0.4)
}

struct TacticalScannerEffect: View {
    @State private var y: CGFloat = -100
    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(LinearGradient(colors: [.clear, ThemeColors.neonCyan.opacity(0.1), .clear], startPoint: .top, endPoint: .bottom))
                .frame(height: 150)
                .offset(y: y)
                .onAppear {
                    withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) { y = geo.size.height + 100 }
                }
        }
        .allowsHitTesting(false)
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
