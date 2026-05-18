//
//  DuelHistoryRow.swift
//  Block-Jack
//

import SwiftUI

struct DuelHistoryRow: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let duel: DuelChallenge
    
    var isWin: Bool {
        guard let cs = duel.challengerScore, let cd = duel.challengedScore else {
            return false
        }
        return cs >= cd
    }
    
    private var opponentName: String {
        duel.challengedID == "player" || duel.challengedID == "current_player"
            ? duel.challengerName
            : duel.challengedName
    }
    
    private var resultColor: Color {
        isWin ? ThemeColors.neonPurple : ThemeColors.neonPink
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Result Icon
            ZStack {
                Circle()
                    .fill(resultColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: isWin ? "crown.fill" : "xmark")
                    .font(.system(size: isWin ? 18 : 16, weight: .bold))
                    .foregroundStyle(resultColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("vs \(opponentName)")
                    .font(.setCustomFont(name: .InterBold, size: 15))
                    .foregroundStyle(.white)
                
                if let myScore = duel.challengerScore {
                    Text(myScore.formatted())
                        .font(.setCustomFont(name: .InterMedium, size: 13))
                        .foregroundStyle(ThemeColors.neonCyan)
                }
            }
            
            Spacer()
            
            // Result badge
            HStack(spacing: 6) {
                Image(systemName: isWin ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 14))
                Text(isWin
                     ? userEnv.labelWonWon
                     : userEnv.labelLostLost)
                    .font(.setCustomFont(name: .InterBlack, size: 12))
            }
            .foregroundStyle(resultColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(resultColor.opacity(0.1))
            .clipShape(Capsule())
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(ThemeColors.textMuted)
        }
        .padding(16)
        .background(ThemeColors.surfaceDark.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20)
            .stroke(resultColor.opacity(0.2), lineWidth: 1))
    }
}

#Preview {
    DuelHistoryRow(
        duel: DuelChallenge(
            challengerID: "player",
            challengerName: "Siz",
            challengedID: "opp1",
            challengedName: "PIXEL_GOD",
            stakeAmount: 500,
            status: .completed,
            challengerScore: 58_100,
            challengedScore: 41_500
        )
    )
    .environmentObject(UserEnvironment.shared)
    .padding()
}
