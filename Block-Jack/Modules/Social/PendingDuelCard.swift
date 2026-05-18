//
//  PendingDuelCard.swift
//  Block-Jack
//

import SwiftUI

struct PendingDuelCard: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let duel: DuelChallenge
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(ThemeColors.electricYellow.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(ThemeColors.electricYellow)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(duel.challengerName) \(userEnv.labelChallengesYou)")
                        .font(.setCustomFont(name: .InterBold, size: 15))
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.system(size: 12))
                        Text("\(userEnv.labelStake) \(duel.stakeAmount)")
                            .font(.setCustomFont(name: .InterMedium, size: 13))
                    }
                    .foregroundStyle(ThemeColors.electricYellow)
                }
                
                Spacer()
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button {
                    HapticManager.shared.play(.error)
                    onDecline()
                } label: {
                    Text(userEnv.btnDecline)
                        .font(.setCustomFont(name: .InterBold, size: 14))
                        .foregroundStyle(ThemeColors.neonPink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(ThemeColors.neonPink.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ThemeColors.neonPink.opacity(0.3), lineWidth: 1))
                }
                
                Button {
                    HapticManager.shared.play(.success)
                    onAccept()
                } label: {
                    HStack(spacing: 6) {
                        Text(userEnv.btnAccept)
                            .font(.setCustomFont(name: .InterBlack, size: 14))
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(ThemeColors.cosmicBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(ThemeColors.neonPurple)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: ThemeColors.neonPurple.opacity(0.3), radius: 8)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24)
            .stroke(ThemeColors.electricYellow.opacity(0.4), lineWidth: 1.5))
    }
}

#Preview {
    PendingDuelCard(
        duel: DuelChallenge(
            challengerID: "opp1",
            challengerName: "BLOCKZILLA",
            challengedID: "player",
            challengedName: "Siz",
            stakeAmount: 500
        ),
        onAccept: { },
        onDecline: { }
    )
    .environmentObject(UserEnvironment.shared)
    .padding()
}
