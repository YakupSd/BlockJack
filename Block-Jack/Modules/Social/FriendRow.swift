//
//  FriendRow.swift
//  Block-Jack
//

import SwiftUI

struct FriendRow: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let friend: FriendRelation
    let onDuel: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(ThemeColors.surfaceDark)
                    .frame(width: 48, height: 48)
                
                Text(String(friend.username.prefix(2)).uppercased())
                    .font(.setCustomFont(name: .InterBlack, size: 14))
                    .foregroundStyle(ThemeColors.neonCyan)
            }
            .overlay(
                Circle()
                    .fill(friend.isOnline ? ThemeColors.neonPurple : ThemeColors.textMuted.opacity(0.3))
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(ThemeColors.cosmicBlack, lineWidth: 2))
                    .offset(x: 18, y: -18)
            )
            
            // Bilgi
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.username)
                    .font(.setCustomFont(name: .InterBold, size: 16))
                    .foregroundStyle(.white)
                
                HStack(spacing: 8) {
                    if let rank = friend.globalRank {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 10))
                            Text("#\(rank)")
                                .font(.setCustomFont(name: .InterMedium, size: 12))
                        }
                        .foregroundStyle(ThemeColors.electricYellow)
                    }
                    
                    Text(friend.isOnline
                         ? userEnv.labelOnline
                         : userEnv.labelOffline)
                        .font(.setCustomFont(name: .InterMedium, size: 11))
                        .foregroundStyle(friend.isOnline ? ThemeColors.neonPurple : ThemeColors.textMuted)
                }
            }
            
            Spacer()
            
            // Duello butonu
            if friend.pendingDuelID != nil {
                HStack(spacing: 4) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 12))
                    Text(userEnv.labelPending)
                        .font(.setCustomFont(name: .InterBold, size: 11))
                }
                .foregroundStyle(ThemeColors.neonOrange)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(ThemeColors.neonOrange.opacity(0.1))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(ThemeColors.neonOrange.opacity(0.3), lineWidth: 1))
            } else {
                Button {
                    HapticManager.shared.play(.buttonTap)
                    onDuel()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 12))
                        Text(userEnv.btnDuel)
                            .font(.setCustomFont(name: .InterBlack, size: 12))
                    }
                    .foregroundStyle(ThemeColors.cosmicBlack)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(ThemeColors.neonOrange)
                    .clipShape(Capsule())
                    .shadow(color: ThemeColors.neonOrange.opacity(0.3), radius: 6)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20)
            .stroke(ThemeColors.gridStroke.opacity(0.5), lineWidth: 1))
    }
}

#Preview {
    FriendRow(
        friend: FriendRelation(
            friendID: "f1",
            username: "PIXEL_GOD",
            avatarSlot: 1,
            globalRank: 5,
            isOnline: true
        ),
        onDuel: { }
    )
    .environmentObject(UserEnvironment.shared)
    .padding()
}
