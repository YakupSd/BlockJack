//
//  ScoreHUDView.swift
//  Block-Jack
//
//  UI Revize — Tek yatay satır skor/streak/çarpan paneli.
//  Sol: PUAN: 0 / 625 (büyük rakam + küçük hedef)
//  Sağ: Streak ×N pill + Çarpan ×N badge
//

import SwiftUI

struct ScoreHUDView: View {
    @ObservedObject var vm: GameViewModel
    @EnvironmentObject var userEnv: UserEnvironment
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // SOL: Puan
            scoreBlock
            
            Spacer(minLength: 6)
            
            // SAĞ: Streak ve Çarpan
            HStack(spacing: 8) {
                if vm.run.streak > 0 {
                    streakPill
                        .transition(.scale.combined(with: .opacity))
                }
                multiplierBadge
            }
        }
        .padding(.horizontal, GameLayout.horizontalPadding)
        .frame(height: GameLayout.scoreHeight)
    }
    
    // MARK: - Score block
    @ViewBuilder
    private var scoreBlock: some View {
        let reached = vm.run.currentScore >= vm.run.currentRoundTargetScore
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(userEnv.localizedString("PUAN", "SCORE"))
                .font(.setCustomFont(name: .InterBold, size: 9))
                .foregroundStyle(ThemeColors.textMuted)
                .tracking(1.2)
                .baselineOffset(2)
            
            Text(vm.run.currentScore.formatted())
                .font(.setCustomFont(name: .InterBlack, size: 20))
                .foregroundStyle(reached ? ThemeColors.electricYellow : .white)
                .contentTransition(.numericText())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text("/ \(vm.run.currentRoundTargetScore.formatted())")
                .font(.setCustomFont(name: .InterBold, size: 11))
                .foregroundStyle(ThemeColors.textMuted.opacity(0.9))
                .monospacedDigit()
                .lineLimit(1)
        }
        .shadow(color: reached ? ThemeColors.electricYellow.opacity(0.4) : .clear, radius: 6)
        .layoutPriority(1)
    }
    
    // MARK: - Streak pill
    @ViewBuilder
    private var streakPill: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(ThemeColors.neonCyan)
                .frame(width: 5, height: 5)
                .shadow(color: ThemeColors.neonCyan, radius: 3)
            
            Text("Streak ×\(vm.run.streak)")
                .font(.setCustomFont(name: .InterBold, size: 10))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(ThemeColors.neonCyan.opacity(0.15))
        )
        .overlay(
            Capsule().stroke(ThemeColors.neonCyan.opacity(0.4), lineWidth: 1)
        )
    }
    
    // MARK: - Multiplier badge
    @ViewBuilder
    private var multiplierBadge: some View {
        let mult = vm.currentMultiplier
        VStack(spacing: -1) {
            Text(userEnv.localizedString("Çarpan", "Mult"))
                .font(.setCustomFont(name: .InterBold, size: 7))
                .foregroundStyle(ThemeColors.electricYellow.opacity(0.85))
                .tracking(1)
            
            Text(String(format: "×%.1f", mult))
                .font(.setCustomFont(name: .InterBlack, size: 13))
                .foregroundStyle(ThemeColors.electricYellow)
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8).fill(ThemeColors.electricYellow.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(ThemeColors.electricYellow.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Score Popup Overlay (korundu — eski davranış)
struct ScorePopupView: View {
    let popup: ScorePopup

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = Double.random(in: -15...15)

    var body: some View {
        Text(popup.text)
            .font(.setCustomFont(name: .InterExtraBold, size: 24))
            .foregroundStyle(popup.color)
            .shadow(color: popup.color, radius: 10)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.2
                }
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
        .environmentObject(UserEnvironment.shared)
    }
}
