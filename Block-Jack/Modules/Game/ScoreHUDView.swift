//
//  ScoreHUDView.swift
//  Block-Jack
//

import SwiftUI

struct ScoreHUDView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        HStack(alignment: .top) {
            // Sol: Skor
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.run.currentScore.formatted())
                    .font(.setCustomFont(name: .InterBold, size: 28))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .scaleEffect(vm.shakeAmount > 0 ? 1.2 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.3), value: vm.run.currentScore)

                Text("/ \(vm.run.currentRoundTargetScore.formatted())")
                    .font(.setCustomFont(name: .InterRegular, size: 12))
                    .foregroundStyle(ThemeColors.textSecondary)
            }

            Spacer()

            // Orta: Streak
            if vm.run.streak > 1 {
                VStack(spacing: 2) {
                    Text("×\(String(format: "%.1f", 1.0 + Double(vm.run.streak) * 0.1))")
                        .font(.setCustomFont(name: .InterExtraBold, size: 22))
                        .foregroundStyle(ThemeColors.neonPurple)
                        .shadow(color: ThemeColors.neonPurple, radius: 6)

                    Text("STREAK")
                        .font(.setCustomFont(name: .InterMedium, size: 9))
                        .foregroundStyle(ThemeColors.textSecondary)
                        .tracking(2)
                }
                .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            // Sağ: Round + Hamle
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    if let modifier = vm.run.round.modifier {
                        Text("BOSS")
                            .font(.setCustomFont(name: .InterBold, size: 9))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(ThemeColors.neonPink)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    
                    Text("ROUND \(vm.run.currentRound)")
                        .font(.setCustomFont(name: .InterBold, size: 14))
                        .foregroundStyle(vm.run.round.modifier != nil ? ThemeColors.neonPink : ThemeColors.neonCyan)
                        .tracking(1)
                }

                if let modifier = vm.run.round.modifier {
                    Text(modifier.title)
                        .font(.setCustomFont(name: .InterBold, size: 10))
                        .foregroundStyle(ThemeColors.textSecondary)
                        .tracking(2)
                } else {
                    Text("\(vm.run.movesRemaining) hamle")
                        .font(.setCustomFont(name: .InterRegular, size: 12))
                        .foregroundStyle(ThemeColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

// MARK: - Score Popup Overlay
struct ScorePopupView: View {
    let popup: ScorePopup

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.5

    var body: some View {
        Text(popup.text)
            .font(.setCustomFont(name: .InterExtraBold, size: 24))
            .foregroundStyle(popup.color)
            .shadow(color: popup.color, radius: 10)
            .scaleEffect(scale)
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
