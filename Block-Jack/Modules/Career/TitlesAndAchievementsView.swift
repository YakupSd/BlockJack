//
//  TitlesAndAchievementsView.swift
//  Block-Jack
//

import SwiftUI

struct TitlesAndAchievementsView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @ObservedObject var careerVM: CareerStatsViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Unlocked Titles Count
            VStack(spacing: 8) {
                HStack {
                    Text(userEnv.labelUnlockedCaps)
                        .font(.setCustomFont(name: .InterMedium, size: 13))
                        .foregroundStyle(ThemeColors.textMuted)
                    Spacer()
                    Text("\(careerVM.careerStats.unlockedTitles.count) / \(SpecialTitle.allCases.count)")
                        .font(.setCustomFont(name: .InterBold, size: 13))
                        .foregroundStyle(ThemeColors.neonCyan)
                }
            }
            .padding(.bottom, 8)
            
            // All Titles
            ForEach(SpecialTitle.allCases, id: \.rawValue) { title in
                let status = careerVM.getTitleStatus(for: title)
                
                TitleCard(
                    title: title,
                    isUnlocked: status.unlocked,
                    progress: status.progress
                )
            }
            
            Spacer(minLength: 20)
        }
    }
}

// MARK: - Title Card
struct TitleCard: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let title: SpecialTitle
    let isUnlocked: Bool
    let progress: String
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Icon
                Text(title.icon)
                    .font(.system(size: 24))
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(isUnlocked ? ThemeColors.electricYellow.opacity(0.2) : ThemeColors.surfaceDark)
                    )
                    .overlay(
                        Circle()
                            .stroke(isUnlocked ? ThemeColors.electricYellow : ThemeColors.gridStroke, lineWidth: 1)
                    )
                
                // Title Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title.title(lang: userEnv.language))
                            .font(.setCustomFont(name: .InterBold, size: 13))
                            .foregroundStyle(isUnlocked ? ThemeColors.electricYellow : ThemeColors.neonCyan)
                        
                        if isUnlocked {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(ThemeColors.electricYellow)
                                .font(.system(size: 10))
                        }
                    }
                    
                    Text(title.description(lang: userEnv.language))
                        .font(.setCustomFont(name: .InterMedium, size: 11))
                        .foregroundStyle(ThemeColors.textMuted)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Progress
                VStack(alignment: .trailing, spacing: 4) {
                    Text(progress)
                        .font(.setCustomFont(name: .InterBold, size: 12))
                        .foregroundStyle(isUnlocked ? ThemeColors.electricYellow : ThemeColors.neonCyan)
                    
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(ThemeColors.textMuted)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isUnlocked ? ThemeColors.surfaceDark : ThemeColors.cosmicBlack.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isUnlocked ? ThemeColors.electricYellow.opacity(0.5) : ThemeColors.gridStroke.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    TitlesAndAchievementsView(careerVM: CareerStatsViewModel())
        .environmentObject(UserEnvironment.shared)
}
