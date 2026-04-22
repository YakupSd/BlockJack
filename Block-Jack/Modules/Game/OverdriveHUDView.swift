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
    /// Overdrive targeting drag sırasında GameView @State dragPosition günceller
    var onDragChanged: ((CGPoint) -> Void)? = nil
    
    // Core animation states
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 1.0
    @State private var glowRadius: CGFloat = 8
    @State private var tierTransitionFlash: Bool = false
    
    var body: some View {
        if let charId = vm.activeCharacterId, let char = GameCharacter.roster.first(where: { $0.id == charId }) {
            let isReady = vm.currentOverdriveTier != .none
            let chargePct = min(1.0, vm.overdriveCharge / 3.0)
            let tierColor = self.tierColor(for: vm.currentOverdriveTier)
            
            // UI Revize: Tek yatay kart — [avatar]  OVERDRIVE TIER N  [bar]  %XX
            HStack(spacing: 10) {
                // Avatar (drag/tap ile overdrive tetikleyen alan)
                ZStack {
                    if vm.run.streak >= 3 {
                        StreakFireHUDView(streak: vm.run.streak)
                            .transition(.opacity.combined(with: .scale))
                    }
                    
                    Circle()
                        .fill(isReady ? tierColor.opacity(0.9) : ThemeColors.surfaceDark)
                        .frame(width: 36, height: 36)
                        .shadow(color: isReady ? tierColor : .clear, radius: isReady ? glowRadius * 0.7 : 0)
                        .scaleEffect(isReady ? pulseScale : 1.0)
                    
                    if tierTransitionFlash {
                        Circle()
                            .stroke(tierColor, lineWidth: 2)
                            .frame(width: 48, height: 48)
                            .scaleEffect(1.4)
                            .opacity(0.0)
                            .animation(.easeOut(duration: 0.5), value: tierTransitionFlash)
                    }
                    
                    Image(char.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())
                        .opacity(isReady ? 1.0 : 0.45)
                        .grayscale(isReady ? 0 : 1)
                    
                    // 3 segment ring — çevresinde şarj göstergesi
                    ForEach(0..<3) { i in
                        Circle()
                            .trim(from: segmentStart(for: i), to: segmentEnd(for: i))
                            .stroke(ThemeColors.gridStroke.opacity(0.3), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))
                    }
                    ForEach(0..<3) { i in
                        if vm.overdriveCharge >= Double(i) {
                            let localCharge = min(1.0, vm.overdriveCharge - Double(i))
                            let fillEnd = segmentStart(for: i) + (CGFloat(localCharge) * (segmentEnd(for: i) - segmentStart(for: i)))
                            Circle()
                                .trim(from: segmentStart(for: i), to: fillEnd)
                                .stroke(
                                    colorForSegment(i).shadow(.drop(color: colorForSegment(i), radius: 3)),
                                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                                )
                                .frame(width: 40, height: 40)
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 0.3), value: vm.overdriveCharge)
                        }
                    }
                }
                .frame(width: 42, height: 42)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .onChanged { value in
                            if char.id == "architect" || char.id == "block_e" {
                                if !vm.isTargetingOverdrive && isReady {
                                    HapticManager.shared.play(.selection)
                                    vm.activateOverdrive()
                                }
                                if vm.isTargetingOverdrive {
                                    vm.dragLocation = value.location
                                    onDragChanged?(value.location)
                                }
                            } else {
                                guard isReady else { return }
                                vm.dragLocation = value.location
                                onDragChanged?(value.location)
                            }
                        }
                        .onEnded { value in
                            if char.id == "architect" || char.id == "block_e" {
                                if vm.isTargetingOverdrive {
                                    vm.dragLocation = value.location
                                    onDragChanged?(value.location)
                                    vm.handleOverdriveDrop()
                                }
                            } else {
                                guard isReady else { return }
                                vm.activateOverdrive()
                            }
                        }
                )
                
                // Metin + progress
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("OVERDRIVE")
                            .font(.setCustomFont(name: .InterBlack, size: 10))
                            .foregroundStyle(isReady ? tierColor : ThemeColors.neonPurple)
                            .tracking(1.2)
                        
                        if isReady {
                            Text("TIER \(vm.currentOverdriveTier.rawValue)")
                                .font(.setCustomFont(name: .InterBlack, size: 9))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(
                                    Capsule().fill(tierColor.opacity(0.22))
                                )
                                .overlay(
                                    Capsule().stroke(tierColor.opacity(0.5), lineWidth: 0.8)
                                )
                        }
                    }
                    
                    Text(isReady
                         ? OverdriveEngine.tierDescription(charId: char.id, tier: vm.currentOverdriveTier)
                         : "Hamleler şarj eder")
                        .font(.setCustomFont(name: .InterMedium, size: 9))
                        .foregroundStyle(ThemeColors.textMuted)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(height: 11)
                    
                    // Yatay progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(ThemeColors.surfaceDark)
                            Capsule()
                                .fill(isReady ? tierColor : ThemeColors.neonPurple)
                                .frame(width: max(0, geo.size.width * chargePct))
                                .animation(.spring(response: 0.3), value: chargePct)
                        }
                    }
                    .frame(height: 3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Yüzde
                Text("\(Int(chargePct * 100))%")
                    .font(.setCustomFont(name: .InterBlack, size: 12))
                    .foregroundStyle(isReady ? tierColor : ThemeColors.neonPurple)
                    .frame(minWidth: 36, alignment: .trailing)
                    .monospacedDigit()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(height: GameLayout.overdriveHeight)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(ThemeColors.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isReady ? tierColor.opacity(0.5) : ThemeColors.neonPurple.opacity(0.3), lineWidth: 1)
                    )
            )
            .onChange(of: vm.currentOverdriveTier) { oldValue, newTier in
                if newTier != .none {
                    withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        pulseScale = 1.07
                        pulseOpacity = 0.6
                        glowRadius = 14
                    }
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
