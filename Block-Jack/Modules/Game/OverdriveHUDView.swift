//
//  OverdriveHUDView.swift
//  Block-Jack
//

import SwiftUI

// MARK: - Phase 8.2: Streak Fire HUD Effect
struct StreakFireHUDView: View {
    let streak: Int
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<min(streak, 8), id: \.self) { i in
                Circle()
                    .fill(streak >= 5 ? ThemeColors.neonPink : ThemeColors.electricYellow)
                    .frame(width: 4, height: 4)
                    .offset(y: -28)
                    .rotationEffect(.degrees(Double(i) * (360.0 / Double(min(streak, 8)))) )
                    .rotationEffect(.degrees(animate ? 360 : 0))
                    .opacity(animate ? 0.8 : 0.2)
                    .blur(radius: 1)
                    .animation(
                        .linear(duration: 2.0)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.1),
                        value: animate
                    )
            }
            
            // Neon Fire / Glow
            if streak >= 3 {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [ThemeColors.electricYellow, ThemeColors.neonOrange, ThemeColors.neonPink, ThemeColors.electricYellow],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 58, height: 58)
                    .blur(radius: animate ? 4 : 2)
                    .opacity(0.6)
                    .rotationEffect(.degrees(animate ? 360 : 0))
                    .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: animate)
            }
        }
        .onAppear { animate = true }
    }
}

struct OverdriveHUDView: View {
    @ObservedObject var vm: GameViewModel
    @EnvironmentObject var userEnv: UserEnvironment
    
    // Core animation states
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 1.0
    @State private var glowRadius: CGFloat = 8
    @State private var tierTransitionFlash: Bool = false
    
    var body: some View {
        if let charId = vm.activeCharacterId, let char = GameCharacter.roster.first(where: { $0.id == charId }) {
            let isReady = vm.currentOverdriveTier != .none
            let chargePct = vm.overdriveCharge / 3.0 // 0.0 -> 1.0 overall
            let tierColor = self.tierColor(for: vm.currentOverdriveTier)
            
            VStack(spacing: 8) {
                // Tooltip showing active tier description
                if isReady {
                    Text(OverdriveEngine.tierDescription(charId: char.id, tier: vm.currentOverdriveTier))
                        .font(.caption)
                        .foregroundColor(tierColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color(white: 0.1).opacity(0.8))
                        .cornerRadius(8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                HStack(spacing: 12) {
                    // Start dragging or tapping logic
                    ZStack {
                        // Phase 8.2: Streak Fire HUD
                        if vm.run.streak >= 3 {
                            StreakFireHUDView(streak: vm.run.streak)
                                .transition(.opacity.combined(with: .scale))
                        }
                        
                        Circle()
                            .fill(isReady ? tierColor : ThemeColors.surfaceDark)
                            .frame(width: 50, height: 50)
                            .shadow(color: isReady ? tierColor : .clear, radius: isReady ? glowRadius : 0)
                            .scaleEffect(isReady ? pulseScale : 1.0)
                        
                        // Phase 8.3: Tier transition flash ring
                        if tierTransitionFlash {
                            Circle()
                                .stroke(tierColor, lineWidth: 3)
                                .frame(width: 65, height: 65)
                                .scaleEffect(1.4)
                                .opacity(0.0)
                                .animation(.easeOut(duration: 0.5), value: tierTransitionFlash)
                        }
                        
                        Image(char.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .opacity(isReady ? 1.0 : 0.4)
                            .grayscale(isReady ? 0 : 1)
                        
                        // 3 Segment Ring logic
                        // Draw empty segments first
                        ForEach(0..<3) { i in
                            Circle()
                                .trim(from: segmentStart(for: i), to: segmentEnd(for: i))
                                .stroke(ThemeColors.gridStroke.opacity(0.3), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 54, height: 54)
                                .rotationEffect(.degrees(-90))
                        }
                        
                        // Draw filled segments based on overdrive charge
                        ForEach(0..<3) { i in
                            if vm.overdriveCharge >= Double(i) {
                                let localCharge = min(1.0, vm.overdriveCharge - Double(i))
                                let fillEnd = segmentStart(for: i) + (CGFloat(localCharge) * (segmentEnd(for: i) - segmentStart(for: i)))
                                
                                Circle()
                                    .trim(from: segmentStart(for: i), to: fillEnd)
                                    .stroke(
                                        colorForSegment(i).shadow(.drop(color: colorForSegment(i), radius: 4)),
                                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                                    )
                                    .frame(width: 54, height: 54)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.spring(response: 0.3), value: vm.overdriveCharge)
                            }
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .global)
                            .onChanged { value in
                                guard isReady else { return }
                                // Targeted Overdrive Check
                                if char.id == "architect" || char.id == "block_e" {
                                    if !vm.isTargetingOverdrive {
                                        HapticManager.shared.play(.selection)
                                        vm.isTargetingOverdrive = true
                                    }
                                    vm.dragLocation = value.location
                                }
                            }
                            .onEnded { value in
                                guard isReady else { return }
                                
                                if char.id == "architect" || char.id == "block_e" {
                                    vm.dragLocation = value.location
                                    vm.handleOverdriveDrop()
                                } else {
                                    vm.activateOverdrive()
                                }
                            }
                    )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("OVERDRIVE: TIER \(vm.currentOverdriveTier.rawValue)")
                            .font(.setCustomFont(name: .InterBlack, size: 12))
                            .foregroundStyle(isReady ? tierColor : ThemeColors.textSecondary)
                        
                        Text(isReady ? "HAZIR (%.0f%%)".replacingOccurrences(of: "%.0f", with: String(Int((vm.overdriveCharge / 3.0) * 100))) : "\(Int((vm.overdriveCharge / 3.0) * 100))% ŞARJ")
                            .font(.setCustomFont(name: .InterMedium, size: 10))
                            .foregroundStyle(ThemeColors.textMuted)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isReady ? tierColor.opacity(0.5) : ThemeColors.gridStroke.opacity(0.3), lineWidth: 1))
            }
            .onChange(of: vm.currentOverdriveTier) { newTier in
                if newTier != .none {
                    // Phase 8.3: Tier ready pulse
                    withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        pulseScale = 1.07
                        pulseOpacity = 0.6
                        glowRadius = 14
                    }
                    // Flash ring burst on tier unlock
                    tierTransitionFlash = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        tierTransitionFlash = false
                    }
                } else {
                    withAnimation(.spring(response: 0.4)) {
                        pulseScale = 1.0
                        pulseOpacity = 1.0
                        glowRadius = 8
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    private func segmentStart(for index: Int) -> CGFloat {
        // Gap of 0.05 between the 3 segments
        let base = CGFloat(index) * 0.333
        return base + 0.02
    }
    
    private func segmentEnd(for index: Int) -> CGFloat {
        let base = CGFloat(index + 1) * 0.333
        return base - 0.02
    }
    
    private func tierColor(for tier: OverdriveTier) -> Color {
        switch tier {
        case .tier1: return ThemeColors.electricYellow
        case .tier2: return ThemeColors.neonOrange
        case .tier3: return ThemeColors.neonPink
        default: return ThemeColors.gridStroke
        }
    }
    
    private func colorForSegment(_ index: Int) -> Color {
        if index == 0 { return ThemeColors.electricYellow }
        if index == 1 { return ThemeColors.neonOrange }
        return ThemeColors.neonPink
    }
}
