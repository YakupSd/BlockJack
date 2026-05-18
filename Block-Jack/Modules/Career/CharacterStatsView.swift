//
//  CharacterStatsView.swift
//  Block-Jack
//

import SwiftUI

struct CharacterStatsView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @ObservedObject var careerVM: CareerStatsViewModel
    
    var sortedCharacters: [(String, CharacterCareerStats)] {
        careerVM.careerStats.characterStats
            .sorted { $0.value.runsCompleted > $1.value.runsCompleted }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if sortedCharacters.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "controller.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(ThemeColors.textMuted)
                    Text(userEnv.labelNoCharactersPlayed)
                        .font(.setCustomFont(name: .InterMedium, size: 14))
                        .foregroundStyle(ThemeColors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
            } else {
                ForEach(sortedCharacters, id: \.0) { charID, stats in
                    CharacterStatRow(
                        characterID: charID,
                        stats: stats,
                        careerVM: careerVM
                    )
                }
            }
            
            Spacer(minLength: 20)
        }
    }
}

// MARK: - Character Stat Row
struct CharacterStatRow: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let characterID: String
    let stats: CharacterCareerStats
    let careerVM: CareerStatsViewModel
    
    var character: GameCharacter? {
        GameCharacter.roster.first { $0.id == characterID }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with Character Info
            HStack(spacing: 12) {
                if let character = character {
                    Image(character.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(ThemeColors.surfaceDark))
                        .overlay(Circle().stroke(ThemeColors.gridStroke, lineWidth: 1))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(character.name)
                            .font(.setCustomFont(name: .InterBold, size: 14))
                            .foregroundStyle(ThemeColors.neonCyan)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(ThemeColors.electricYellow)
                                .font(.system(size: 10))
                            Text(stats.masteryLevel.title(lang: userEnv.language))
                                .font(.setCustomFont(name: .InterMedium, size: 10))
                                .foregroundStyle(ThemeColors.electricYellow)
                        }
                    }
                } else {
                    Text("Unknown Character")
                        .font(.setCustomFont(name: .InterMedium, size: 12))
                        .foregroundStyle(ThemeColors.textMuted)
                }
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(ThemeColors.surfaceDark)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ThemeColors.gridStroke, lineWidth: 1))
            )
            
            // Stats Grid
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    StatDetailBox(
                        label: userEnv.labelRunsCountCaps,
                        value: "\(stats.runsCompleted)"
                    )
                    
                    StatDetailBox(
                        label: userEnv.labelAvgScoreCaps,
                        value: "\(stats.averageScore)"
                    )
                }
                
                HStack(spacing: 8) {
                    StatDetailBox(
                        label: userEnv.labelHighestScoreCaps,
                        value: "\(stats.highestScore)"
                    )
                    
                    StatDetailBox(
                        label: userEnv.labelDamageCaps,
                        value: careerVM.getFormattedDamage(stats.totalDamageDealt)
                    )
                }
            }
            
            // Mastery Progress
            VStack(spacing: 6) {
                HStack {
                    Text("Mastery XP")
                        .font(.setCustomFont(name: .InterMedium, size: 11))
                        .foregroundStyle(ThemeColors.textMuted)
                    Spacer()
                    Text("\(stats.masteryXP)")
                        .font(.setCustomFont(name: .InterBold, size: 11))
                        .foregroundStyle(ThemeColors.neonCyan)
                }
                
                ProgressView(value: getCharacterMasteryProgress())
                    .tint(ThemeColors.neonCyan)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ThemeColors.surfaceDark.opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ThemeColors.gridStroke.opacity(0.5), lineWidth: 1))
        )
    }
    
    private func getCharacterMasteryProgress() -> Double {
        let currentLevel = stats.masteryLevel
        let nextLevel = MasteryLevel.levels.first { $0.level == currentLevel.level + 1 }
        
        let currentXP = currentLevel.requiredXP
        let nextXP = nextLevel?.requiredXP ?? (currentLevel.requiredXP + 50000)
        
        let progress = Double(stats.masteryXP - currentXP) / Double(nextXP - currentXP)
        return min(max(progress, 0), 1)
    }
}

// MARK: - Stat Detail Box
struct StatDetailBox: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.setCustomFont(name: .InterMedium, size: 10))
                .foregroundStyle(ThemeColors.textMuted)
            
            Text(value)
                .font(.setCustomFont(name: .InterBold, size: 14))
                .foregroundStyle(ThemeColors.neonCyan)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(ThemeColors.cosmicBlack.opacity(0.3))
        )
    }
}

#Preview {
    CharacterStatsView(careerVM: CareerStatsViewModel())
        .environmentObject(UserEnvironment.shared)
}
