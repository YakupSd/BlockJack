//
//  CareerStatsView.swift
//  Block-Jack
//

import SwiftUI

struct CareerStatsView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @ObservedObject var careerVM: CareerStatsViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Overall Stats Grid
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    StatCard(
                        title: userEnv.labelTotalDamage,
                        value: careerVM.getFormattedDamage(careerVM.careerStats.totalDamageDealt),
                        icon: "💥",
                        color: ThemeColors.neonPink
                    )
                    
                    StatCard(
                        title: userEnv.labelTotalLinesCleared,
                        value: "\(careerVM.careerStats.totalLinesCleared)",
                        icon: "🧹",
                        color: ThemeColors.neonCyan
                    )
                }
                
                HStack(spacing: 12) {
                    StatCard(
                        title: userEnv.labelTotalBossesDefeated,
                        value: "\(careerVM.careerStats.totalBossesDefeated)",
                        icon: "⚔️",
                        color: ThemeColors.electricYellow
                    )
                    
                    StatCard(
                        title: userEnv.labelTotalRuns,
                        value: "\(careerVM.careerStats.totalRunsCompleted)",
                        icon: "🎮",
                        color: ThemeColors.neonPurple
                    )
                }
            }
            
            // Play Time
            VStack(spacing: 8) {
                HStack {
                    Text(userEnv.labelTotalPlaytime)
                        .font(.setCustomFont(name: .InterMedium, size: 13))
                        .foregroundStyle(ThemeColors.textMuted)
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(ThemeColors.neonCyan)
                    Text(careerVM.getFormattedPlayTime(careerVM.careerStats.totalPlayTime))
                        .font(.setCustomFont(name: .InterExtraBold, size: 24))
                        .foregroundStyle(ThemeColors.neonCyan)
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ThemeColors.surfaceDark)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ThemeColors.gridStroke, lineWidth: 1))
                )
            }
            
            // Favorite Character
            if !careerVM.careerStats.favoriteCharacterID.isEmpty {
                VStack(spacing: 8) {
                    HStack {
                        Text(userEnv.labelFavoriteCharacter)
                            .font(.setCustomFont(name: .InterMedium, size: 13))
                            .foregroundStyle(ThemeColors.textMuted)
                        Spacer()
                    }
                    
                    if let character = GameCharacter.roster.first(where: { $0.id == careerVM.careerStats.favoriteCharacterID }) {
                        HStack(spacing: 12) {
                            Image(character.icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .background(Circle().fill(ThemeColors.surfaceDark))
                                .overlay(Circle().stroke(ThemeColors.gridStroke, lineWidth: 1))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(character.name)
                                    .font(.setCustomFont(name: .InterBold, size: 14))
                                    .foregroundStyle(ThemeColors.neonCyan)
                                
                                if let stats = careerVM.getCharacterStats(for: character.id) {
                                    Text(userEnv.language == .turkish ? "\(stats.runsCompleted) koşu" : "\(stats.runsCompleted) runs")
                                        .font(.setCustomFont(name: .InterMedium, size: 11))
                                        .foregroundStyle(ThemeColors.textMuted)
                                }
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(ThemeColors.surfaceDark)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ThemeColors.gridStroke, lineWidth: 1))
                        )
                    }
                }
            }
            
            // Most Used Perk
            if !careerVM.careerStats.mostUsedPerkID.isEmpty {
                VStack(spacing: 8) {
                    HStack {
                        Text(userEnv.labelMostUsedPerk)
                            .font(.setCustomFont(name: .InterMedium, size: 13))
                            .foregroundStyle(ThemeColors.textMuted)
                        Spacer()
                    }
                    
                    if let perkStats = careerVM.getPerkStats(for: careerVM.careerStats.mostUsedPerkID) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(ThemeColors.neonPurple.opacity(0.2))
                                Image(careerVM.careerStats.mostUsedPerkID)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                            }
                            .frame(width: 50, height: 50)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(careerVM.careerStats.mostUsedPerkID.uppercased())
                                    .font(.setCustomFont(name: .InterBold, size: 14))
                                    .foregroundStyle(ThemeColors.neonPurple)
                                
                                Text(userEnv.language == .turkish ? "\(perkStats.timesUsed)x kullanıldı" : "Used \(perkStats.timesUsed)x")
                                    .font(.setCustomFont(name: .InterMedium, size: 11))
                                    .foregroundStyle(ThemeColors.textMuted)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(ThemeColors.surfaceDark)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ThemeColors.gridStroke, lineWidth: 1))
                        )
                    }
                }
            }
            
            Spacer(minLength: 20)
        }
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.setCustomFont(name: .InterMedium, size: 11))
                    .foregroundStyle(ThemeColors.textMuted)
                Spacer()
            }
            
            Text(value)
                .font(.setCustomFont(name: .InterExtraBold, size: 20))
                .foregroundStyle(color)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ThemeColors.surfaceDark)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
        )
    }
}

#Preview {
    CareerStatsView(careerVM: CareerStatsViewModel())
        .environmentObject(UserEnvironment.shared)
}
