//
//  AchievementToastView.swift
//  Block-Jack
//

import SwiftUI

struct AchievementToastView: View {
    let achievement: Achievement
    @EnvironmentObject var userEnv: UserEnvironment

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ThemeColors.electricYellow.opacity(0.18))
                    .frame(width: 40, height: 40)
                Image(systemName: achievement.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ThemeColors.electricYellow)
            }
            .overlay(Circle().stroke(ThemeColors.electricYellow.opacity(0.45), lineWidth: 1))

            VStack(alignment: .leading, spacing: 2) {
                Text(userEnv.localizedString("BAŞARI AÇILDI!", "ACHIEVEMENT UNLOCKED!"))
                    .font(.setCustomFont(name: .InterExtraBold, size: 10))
                    .tracking(1.6)
                    .foregroundStyle(ThemeColors.textMuted)

                Text(userEnv.localizedString(achievement.titleTR, achievement.titleEN))
                    .font(.setCustomFont(name: .InterBlack, size: 14))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if achievement.rewardGold > 0 || achievement.rewardDiamonds > 0 {
                    Text(rewardText)
                        .font(.setCustomFont(name: .InterBold, size: 11))
                        .foregroundStyle(ThemeColors.neonCyan)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }

            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 18))
                .foregroundStyle(ThemeColors.neonGreen)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ThemeColors.hudBg.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ThemeColors.electricYellow.opacity(0.35), lineWidth: 1)
                )
        )
        .shadow(color: ThemeColors.electricYellow.opacity(0.2), radius: 12)
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private var rewardText: String {
        var parts: [String] = []
        if achievement.rewardGold > 0 { parts.append("+\(achievement.rewardGold)🪙") }
        if achievement.rewardDiamonds > 0 { parts.append("+\(achievement.rewardDiamonds)💎") }
        return parts.joined(separator: "  ")
    }
}

