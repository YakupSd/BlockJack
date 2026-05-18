//
//  ActiveDuelRow.swift
//  Block-Jack
//

import SwiftUI

struct ActiveDuelRow: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let duel: DuelChallenge
    
    private var opponentName: String {
        duel.challengedID == "player" || duel.challengedID == "current_player"
            ? duel.challengerName
            : duel.challengedName
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // VS Icon
            ZStack {
                Circle()
                    .fill(ThemeColors.neonOrange.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 22))
                    .foregroundStyle(ThemeColors.neonOrange)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("vs \(opponentName)")
                    .font(.setCustomFont(name: .InterBold, size: 16))
                    .foregroundStyle(.white)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.system(size: 10))
                        Text("\(duel.stakeAmount)")
                            .font(.setCustomFont(name: .InterMedium, size: 12))
                    }
                    .foregroundStyle(ThemeColors.electricYellow)
                    
                    Text(duel.status == .accepted
                         ? userEnv.labelYourTurn
                         : userEnv.labelOpponentPlaying)
                        .font(.setCustomFont(name: .InterMedium, size: 12))
                        .foregroundStyle(duel.status == .accepted ? ThemeColors.neonCyan : ThemeColors.neonOrange)
                }
            }
            
            Spacer()
            
            // Score if available
            if let score = duel.challengerScore ?? duel.challengedScore {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(score.formatted())
                        .font(.setCustomFont(name: .InterBlack, size: 18))
                        .foregroundStyle(ThemeColors.neonCyan)
                    Text(userEnv.labelScore)
                        .font(.setCustomFont(name: .InterMedium, size: 10))
                        .foregroundStyle(ThemeColors.textMuted)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(ThemeColors.textMuted)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20)
            .stroke(ThemeColors.neonOrange.opacity(0.3), lineWidth: 1))
    }
}

#Preview {
    ActiveDuelRow(
        duel: DuelChallenge(
            challengerID: "player",
            challengerName: "Siz",
            challengedID: "opp1",
            challengedName: "NEON_KID",
            stakeAmount: 500,
            status: .accepted,
            challengerScore: 48_320
        )
    )
    .environmentObject(UserEnvironment.shared)
    .padding()
}
