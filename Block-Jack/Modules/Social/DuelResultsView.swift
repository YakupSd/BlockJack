//
//  DuelResultsView.swift
//  Block-Jack
//

import SwiftUI

struct DuelResultsView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let duel: DuelChallenge
    
    var playerIsChallenger: Bool {
        duel.challengerID == "player" || duel.challengerID == "current_player"
    }
    
    var playerWon: Bool {
        guard let pScore = (playerIsChallenger ? duel.challengerScore : duel.challengedScore),
              let oScore = (playerIsChallenger ? duel.challengedScore : duel.challengerScore) else {
            return false
        }
        return pScore >= oScore
    }
    
    var playerScore: Int {
        playerIsChallenger ? duel.challengerScore ?? 0 : duel.challengedScore ?? 0
    }
    
    var opponentScore: Int {
        playerIsChallenger ? duel.challengedScore ?? 0 : duel.challengerScore ?? 0
    }
    
    var playerStats: DuelStats? {
        playerIsChallenger ? duel.challengerStats : duel.challengedStats
    }
    
    var opponentStats: DuelStats? {
        playerIsChallenger ? duel.challengedStats : duel.challengerStats
    }
    
    private var resultColor: Color {
        playerWon ? ThemeColors.neonPurple : ThemeColors.neonPink
    }
    
    var body: some View {
        ZStack {
            ThemeColors.backgroundGradient.ignoresSafeArea()
            backgroundGrid
            
            VStack(spacing: 0) {
                // MARK: - Top Bar
                HStack(spacing: 16) {
                    Button {
                        HapticManager.shared.play(.buttonTap)
                        MainViewsRouter.shared.nav?.popViewController(animated: true)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(ThemeColors.textSecondary)
                            .frame(width: 44, height: 44)
                            .background(ThemeColors.surfaceDark)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(ThemeColors.gridStroke, lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(userEnv.labelDuelResult)
                            .font(.setCustomFont(name: .InterBlack, size: 22))
                            .foregroundStyle(resultColor)
                            .shadow(color: resultColor.opacity(0.5), radius: 8)
                        Text(playerWon
                             ? userEnv.labelCongratulations
                             : userEnv.labelNextTime)
                            .font(.setCustomFont(name: .InterMedium, size: 12))
                            .foregroundStyle(ThemeColors.textMuted)
                            .tracking(2)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // MARK: - Result Header
                        VStack(spacing: 12) {
                            Image(systemName: playerWon ? "crown.fill" : "xmark.shield.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(resultColor)
                                .shadow(color: resultColor.opacity(0.5), radius: 15)
                            
                            Text(playerWon
                                 ? userEnv.labelYouWon
                                 : userEnv.labelYouLost)
                                .font(.setCustomFont(name: .InterBlack, size: 32))
                                .foregroundStyle(resultColor)
                            
                            if playerWon {
                                HStack(spacing: 6) {
                                    Image(systemName: "bitcoinsign.circle.fill")
                                        .font(.system(size: 16))
                                    Text("+\(duel.stakeAmount * 2)")
                                        .font(.setCustomFont(name: .InterBlack, size: 20))
                                }
                                .foregroundStyle(ThemeColors.electricYellow)
                            }
                        }
                        .padding(.vertical, 20)
                        
                        // MARK: - Score Comparison
                        HStack(spacing: 16) {
                            scoreCard(
                                title: userEnv.labelYourScore,
                                score: playerScore,
                                color: ThemeColors.neonCyan,
                                isWinner: playerWon
                            )
                            
                            scoreCard(
                                title: userEnv.labelOpponentScore,
                                score: opponentScore,
                                color: ThemeColors.neonPink,
                                isWinner: !playerWon
                            )
                        }
                        
                        // MARK: - Player Stats
                        if let stats = playerStats {
                            statsSection(
                                title: userEnv.labelYourStats,
                                stats: stats,
                                color: ThemeColors.neonCyan
                            )
                        }
                        
                        // MARK: - Opponent Stats
                        if let stats = opponentStats {
                            statsSection(
                                title: userEnv.labelOpponentStats,
                                stats: stats,
                                color: ThemeColors.neonPink
                            )
                        }
                        
                        // MARK: - Close
                        Button {
                            HapticManager.shared.play(.buttonTap)
                            MainViewsRouter.shared.nav?.popViewController(animated: true)
                        } label: {
                            Text(userEnv.btnGoBack)
                                .font(.setCustomFont(name: .InterBlack, size: 16))
                                .foregroundStyle(ThemeColors.cosmicBlack)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(ThemeColors.neonCyan)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Score Card
    private func scoreCard(title: String, score: Int, color: Color, isWinner: Bool) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.setCustomFont(name: .InterBold, size: 11))
                .foregroundStyle(ThemeColors.textMuted)
                .tracking(1)
            
            Text(score.formatted())
                .font(.setCustomFont(name: .InterBlack, size: 24))
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.3), radius: 5)
            
            if isWinner {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(ThemeColors.electricYellow)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20)
            .stroke(color.opacity(0.3), lineWidth: 1))
    }
    
    // MARK: - Stats Section
    private func statsSection(title: String, stats: DuelStats, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.setCustomFont(name: .InterBold, size: 13))
                .foregroundStyle(color)
                .tracking(2)
            
            VStack(spacing: 0) {
                duelStatRow(label: userEnv.labelLinesCleared, value: "\(stats.linesCleared)")
                Divider().background(ThemeColors.gridStroke.opacity(0.3))
                duelStatRow(label: userEnv.labelZones, value: "\(stats.zonesCleared)")
                Divider().background(ThemeColors.gridStroke.opacity(0.3))
                duelStatRow(label: userEnv.labelMaxCombo, value: "\(stats.maxCombo)")
                Divider().background(ThemeColors.gridStroke.opacity(0.3))
                duelStatRow(label: userEnv.labelBlocksPlaced, value: "\(stats.blocksPlaced)")
                Divider().background(ThemeColors.gridStroke.opacity(0.3))
                duelStatRow(label: userEnv.labelGold, value: "\(stats.goldEarned)")
                Divider().background(ThemeColors.gridStroke.opacity(0.3))
                duelStatRow(label: userEnv.labelDuration, value: "\(stats.durationSeconds)s")
            }
            .background(ThemeColors.surfaceDark.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(ThemeColors.gridStroke.opacity(0.3), lineWidth: 1))
        }
    }
    
    private func duelStatRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.setCustomFont(name: .InterMedium, size: 14))
                .foregroundStyle(ThemeColors.textSecondary)
            Spacer()
            Text(value)
                .font(.setCustomFont(name: .InterBold, size: 14))
                .foregroundStyle(ThemeColors.neonCyan)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var backgroundGrid: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 40
            let color = GraphicsContext.Shading.color(ThemeColors.gridStroke.opacity(0.12))
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
    }
}

#Preview {
    DuelResultsView(
        duel: DuelChallenge(
            challengerID: "player",
            challengerName: "Siz",
            challengedID: "opp1",
            challengedName: "BLOCKZILLA",
            stakeAmount: 500,
            status: .completed,
            challengerScore: 58_100,
            challengedScore: 41_500,
            challengerStats: DuelStats(finalScore: 58_100, linesCleared: 6, maxCombo: 12),
            challengedStats: DuelStats(finalScore: 41_500, linesCleared: 4, maxCombo: 8)
        )
    )
    .environmentObject(UserEnvironment.shared)
}
