//
//  WorldMapView.swift
//  Block-Jack
//

import SwiftUI

struct WorldMapView: View {
    @StateObject var vm: WorldMapViewModel
    @EnvironmentObject var userEnv: UserEnvironment
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Arka Plan
            ThemeColors.backgroundGradient.ignoresSafeArea()
            
            // Phase 11: Parallax Starfield
            WorldMapParallaxView()
            
            // Neon Izgara (Derinlik hissi için)
            Canvas { ctx, size in
                let spacing: CGFloat = 80
                let color = GraphicsContext.Shading.color(ThemeColors.neonCyan.opacity(0.08))
                for x in stride(from: 0, through: size.width, by: spacing) {
                    var p = Path(); p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height))
                    ctx.stroke(p, with: color, lineWidth: 0.5)
                }
                for y in stride(from: 0, through: size.height, by: spacing) {
                    var p = Path(); p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y))
                    ctx.stroke(p, with: color, lineWidth: 0.5)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(vm.levels.reversed().enumerated()), id: \.element.id) { index, level in
                            LevelNodeView(level: level, isLast: index == vm.levels.count - 1) {
                                vm.startLevel(level)
                            }
                        }
                    }
                    .padding(.vertical, 100)
                    .padding(.horizontal, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var header: some View {
        HStack {
            Button {
                HapticManager.shared.play(.buttonTap)
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(ThemeColors.gridStroke, lineWidth: 1))
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(userEnv.localizedString("SEFER", "CAMPAIGN"))
                    .font(.setCustomFont(name: .InterBlack, size: 24))
                    .foregroundStyle(ThemeColors.neonCyan)
                    .shadow(color: ThemeColors.neonCyan.opacity(0.5), radius: 10)
                
                Text(userEnv.localizedString("SEKTÖR ANALİZİ", "SECTOR ANALYSIS"))
                    .font(.setCustomFont(name: .InterMedium, size: 10))
                    .foregroundStyle(ThemeColors.textMuted)
                    .tracking(4)
            }
            
            Spacer()
            
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask(LinearGradient(colors: [.black, .black, .clear], startPoint: .top, endPoint: .bottom))
                .ignoresSafeArea()
        )
    }
}

// MARK: - Parallax Background
struct WorldMapParallaxView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<20) { i in
                Circle()
                    .fill(ThemeColors.neonCyan.opacity(0.4))
                    .frame(width: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat.random(in: 0...400),
                        y: CGFloat.random(in: 0...800)
                    )
                    .opacity(animate ? 0.2 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 2...5))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...2)),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

// MARK: - Level Node View
struct LevelNodeView: View {
    let level: WorldLevel
    let isLast: Bool
    let action: () -> Void
    
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Seviye Düğümü
            Button(action: action) {
                nodeContent
            }
            .disabled(level.status == .locked)
            .scaleEffect(level.status == .available ? pulseScale : 1.0)
            
            // Bağlantı Hattı (Neon Pipe)
            if !isLast {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                connectionColor.opacity(0.8),
                                connectionColor.opacity(0.2)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4, height: 60)
                    .shadow(color: connectionColor.opacity(0.4), radius: 4)
            }
        }
        .onAppear {
            if level.status == .available {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulseScale = 1.05
                }
            }
        }
    }
    
    private var nodeContent: some View {
        HStack(spacing: 20) {
            // Node Icon
            ZStack {
                // Glow
                if level.status != .locked {
                    Circle()
                        .fill(mainColor.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .blur(radius: 20)
                }
                
                // Outer Ring
                Circle()
                    .stroke(mainColor.opacity(level.status == .locked ? 0.2 : 0.6), lineWidth: 2)
                    .frame(width: 64, height: 64)
                
                // Inner Glass
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 50, height: 50)
                    .shadow(color: mainColor.opacity(level.status == .locked ? 0 : 0.3), radius: 10)
                
                if level.type == .boss {
                    Image(systemName: "skull.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(level.status == .locked ? .gray : ThemeColors.neonPink)
                } else if level.status == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(ThemeColors.neonCyan)
                } else {
                    Text("\(level.id)")
                        .font(.setCustomFont(name: .InterBlack, size: 20))
                        .foregroundStyle(level.status == .locked ? .gray : .white)
                }
            }
            
            // Node Info
            VStack(alignment: .leading, spacing: 4) {
                Text(level.title.uppercased())
                    .font(.setCustomFont(name: .InterBlack, size: 16))
                    .foregroundStyle(level.status == .locked ? .gray : .white)
                
                Text(statusText)
                    .font(.setCustomFont(name: .InterBold, size: 10))
                    .foregroundStyle(statusColor)
                    .tracking(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(level.status == .available ? mainColor.opacity(0.05) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(level.status == .available ? mainColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .opacity(level.status == .locked ? 0.6 : 1.0)
    }
    
    private var mainColor: Color {
        if level.type == .boss { return ThemeColors.neonPink }
        switch level.status {
        case .locked: return Color.gray
        case .available: return ThemeColors.neonCyan
        case .completed: return ThemeColors.electricYellow
        }
    }
    
    private var connectionColor: Color {
        level.status == .completed ? ThemeColors.electricYellow : ThemeColors.gridStroke.opacity(0.3)
    }
    
    private var statusText: String {
        switch level.status {
        case .locked: return "LOCKED"
        case .available: return "READY TO SYNC"
        case .completed: return "STABILIZED"
        }
    }
    
    private var statusColor: Color {
        switch level.status {
        case .locked: return .red.opacity(0.7)
        case .available: return ThemeColors.neonCyan
        case .completed: return ThemeColors.electricYellow
        }
    }
}
