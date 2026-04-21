//
//  ScoreHUDView.swift
//  Block-Jack
//

import SwiftUI

struct ScoreHUDView: View {
    @ObservedObject var vm: GameViewModel
    @EnvironmentObject var userEnv: UserEnvironment

    var body: some View {
        ZStack {
            HStack(alignment: .center, spacing: 12) {
                // Sol: Skor Paneli
                VStack(alignment: .leading, spacing: 2) {
                    Text(userEnv.localizedString("PUAN", "SCORE"))
                        .font(.setCustomFont(name: .InterBold, size: 9))
                        .foregroundStyle(ThemeColors.textMuted)
                        .tracking(1)
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text(vm.run.currentScore.formatted())
                            .font(.setCustomFont(name: .InterBlack, size: 24))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .scaleEffect(vm.shakeAmount > 0 ? 1.1 : 1.0)
                        
                        Text("/ \(vm.run.currentRoundTargetScore.formatted())")
                            .font(.setCustomFont(name: .InterBold, size: 11))
                            .foregroundStyle(ThemeColors.textSecondary)
                            .padding(.bottom, 3)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(vm.run.currentScore >= vm.run.currentRoundTargetScore ? ThemeColors.electricYellow : ThemeColors.neonCyan.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: vm.run.currentScore >= vm.run.currentRoundTargetScore ? ThemeColors.electricYellow.opacity(0.3) : Color.clear, radius: 10)
                .phaseAnimator([0.8, 1.1], trigger: vm.run.currentScore) { content, scale in
                    content.scaleEffect(vm.run.currentScore >= vm.run.currentRoundTargetScore ? scale : 1.0)
                } animation: { _ in
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                }
                
                Spacer()
                
                // Sağ: Round & Hamle Paneli
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 6) {
                        if vm.run.round.isBossRound {
                            Text("BOSS")
                                .font(.setCustomFont(name: .InterBlack, size: 8))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(ThemeColors.neonPink)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        
                        Text("CHAPTER \((vm.run.currentChapterMap?.chapterIndex ?? 0) + 1)")
                            .font(.setCustomFont(name: .InterBlack, size: 13))
                            .foregroundStyle(vm.run.round.isBossRound ? ThemeColors.neonPink : ThemeColors.neonCyan)
                    }
                    
                    Text("ROUND \(vm.run.currentRound)")
                        .font(.setCustomFont(name: .InterBold, size: 10))
                        .foregroundStyle(ThemeColors.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            vm.timer.timeRemaining < 15 ? ThemeColors.neonPink : (vm.run.round.isBossRound ? ThemeColors.neonPink.opacity(0.3) : ThemeColors.gridStroke.opacity(0.3)),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: vm.timer.timeRemaining < 15 ? ThemeColors.neonPink.opacity(0.4) : Color.clear, radius: 8)
                .phaseAnimator([0.7, 1.0]) { content, opacity in
                    content.opacity(vm.timer.timeRemaining < 15 ? opacity : 1.0)
                } animation: { _ in
                    .easeInOut(duration: 0.3).repeatForever(autoreverses: true)
                }
            }
            .padding(.horizontal, 20)
            
            // ORTA: Streak Ring
            if vm.run.streak > 1 {
                streakRingView
            }
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var streakRingView: some View {
        ZStack {
            // Rotating Outer Ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [ThemeColors.neonPurple, ThemeColors.neonPink, ThemeColors.neonPurple],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [4, 8])
                )
                .frame(width: 64, height: 64)
                .phaseAnimator([0, 360]) { content, phase in
                    content.rotationEffect(.degrees(phase))
                } animation: { _ in
                    .linear(duration: 4).repeatForever(autoreverses: false)
                }
            
            // Inner Glow / Circle
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 56, height: 56)
                .overlay(Circle().stroke(ThemeColors.neonPurple.opacity(0.4), lineWidth: 1))
                .shadow(color: ThemeColors.neonPurple.opacity(0.3), radius: 8)
            
            VStack(spacing: -2) {
                Text("\(String(format: "%.1f", 1.0 + Double(vm.run.streak) * 0.1))x")
                    .font(.setCustomFont(name: .InterBlack, size: 16))
                    .foregroundStyle(.white)
                
                Text("COMBO")
                    .font(.setCustomFont(name: .InterBlack, size: 7))
                    .foregroundStyle(ThemeColors.neonPurple)
                    .tracking(1)
            }
        }
        .transition(.scale(scale: 0.5).combined(with: .opacity))
        .zIndex(10)
    }
}

// MARK: - Score Popup Overlay
struct ScorePopupView: View {
    let popup: ScorePopup

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = Double.random(in: -15...15) // AAA: Dynamic rotation

    var body: some View {
        Text(popup.text)
            .font(.setCustomFont(name: .InterExtraBold, size: 24))
            .foregroundStyle(popup.color)
            .shadow(color: popup.color, radius: 10)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation)) // AAA: Apply rotation
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                // Pop-in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.2
                }
                // Float away
                withAnimation(.easeOut(duration: 1.2).delay(0.2)) {
                    offset = -80
                    opacity = 0
                    scale = 1.0
                }
            }
    }
}

#Preview {
    ZStack {
        ThemeColors.cosmicBlack.ignoresSafeArea()
        ScoreHUDView(vm: {
            let vm = GameViewModel(slotId: 1)
            vm.run.currentScore = 12450
            vm.run.streak = 5
            return vm
        }())
    }
}
