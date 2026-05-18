//
//  LeaderboardRowView.swift
//  Block-Jack
//
//  Leaderboard satır tasarımı — rank, bayrak, username, skor, badge.
//  Top 3 özel stil, geri kalan standart.
//

import SwiftUI

// MARK: - Leaderboard Row

struct LeaderboardRowView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let entry: LeaderboardEntry
    let isCurrentPlayer: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            rankBadge
            
            // Bayrak + Username
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.flagEmoji)
                        .font(.system(size: 14))
                    
                    Text(entry.username)
                        .font(.setCustomFont(name: .InterBold, size: 14))
                        .foregroundStyle(isCurrentPlayer ? ThemeColors.electricYellow : .white)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    // Chapter
                    Label(userEnv.labelChShortTemplate.replacingOccurrences(of: "{{value}}", with: "\(entry.chapter)"), systemImage: "map.fill")
                        .font(.setCustomFont(name: .InterMedium, size: 10))
                        .foregroundStyle(ThemeColors.neonPurple)
                    
                    // Karakter
                    if let char = entry.character {
                        HStack(spacing: 3) {
                            Image(char.icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .clipShape(Circle())
                            Text(char.name)
                                .font(.setCustomFont(name: .InterMedium, size: 9))
                                .foregroundStyle(ThemeColors.textMuted)
                                .lineLimit(1)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Skor + Badge
            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.score.formatted())
                    .font(.setCustomFont(name: .InterBlack, size: 18))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                
                badgeChip
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(rowBorder)
    }
    
    // MARK: - Rank Badge
    
    @ViewBuilder
    private var rankBadge: some View {
        if entry.rank <= 3 {
            ZStack {
                // Background glow
                Circle()
                    .fill(rankColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                // Border glow
                Circle()
                    .stroke(rankColor.opacity(0.2), lineWidth: 2)
                    .frame(width: 44, height: 44)
                
                // Content
                if entry.rank == 1 {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(rankColor)
                        .shadow(color: rankColor.opacity(0.6), radius: 8)
                } else {
                    Text("#\(entry.rank)")
                        .font(.setCustomFont(name: .InterBlack, size: 16))
                        .foregroundStyle(rankColor)
                }
            }
        } else {
            Text("#\(entry.rank)")
                .font(.setCustomFont(name: .InterBold, size: 14))
                .foregroundStyle(ThemeColors.textMuted)
                .frame(width: 38)
        }
    }
    
    // MARK: - Badge Chip
    
    @ViewBuilder
    private var badgeChip: some View {
        let color = badgeColor
        Text(entry.badge)
            .font(.setCustomFont(name: .InterBlack, size: 8))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(color.opacity(0.3), lineWidth: 0.5)
            )
    }
    
    // MARK: - Styling
    
    private var rankColor: Color {
        switch entry.rank {
        case 1: return ThemeColors.electricYellow
        case 2: return ThemeColors.neonCyan
        case 3: return ThemeColors.neonOrange
        default: return ThemeColors.textMuted
        }
    }
    
    private var badgeColor: Color {
        switch entry.badge {
        case "RARE":   return ThemeColors.electricYellow
        case "EXPERT": return ThemeColors.neonCyan
        default:       return ThemeColors.textMuted
        }
    }
    
    private var rowBackground: some View {
        Group {
            if isCurrentPlayer {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [ThemeColors.electricYellow.opacity(0.15), ThemeColors.electricYellow.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else if entry.rank == 1 {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [ThemeColors.electricYellow.opacity(0.08), ThemeColors.electricYellow.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else if entry.rank <= 3 {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [rankColor.opacity(0.08), rankColor.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
            }
        }
    }
    
    private var rowBorder: some View {
        Group {
            if isCurrentPlayer {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [ThemeColors.electricYellow.opacity(0.5), ThemeColors.electricYellow.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .shadow(color: ThemeColors.electricYellow.opacity(0.3), radius: 10)
            } else if entry.rank == 1 {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [ThemeColors.electricYellow.opacity(0.4), ThemeColors.electricYellow.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .shadow(color: ThemeColors.electricYellow.opacity(0.2), radius: 6)
            } else if entry.rank <= 3 {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(rankColor.opacity(0.3), lineWidth: 1)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            }
        }
    }
}

// MARK: - My Rank Card

struct MyRankCardView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let rank: MyRankResponse
    
    var body: some View {
        ZStack {
            // Background Glow
            Circle()
                .fill(ThemeColors.electricYellow.opacity(0.15))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .offset(y: -20)

            VStack(spacing: 24) {
                // Büyük skor
                VStack(spacing: 8) {
                    Text(rank.flagEmoji)
                        .font(.system(size: 44))
                        .shadow(radius: 10)
                    
                    Text(rank.username)
                        .font(.setCustomFont(name: .InterBlack, size: 24))
                        .foregroundStyle(.white)
                    
                    Text(rank.score.formatted())
                        .font(.setCustomFont(name: .InterBlack, size: 48))
                        .foregroundStyle(ThemeColors.electricYellow)
                        .monospacedDigit()
                        .shadow(color: ThemeColors.electricYellow.opacity(0.6), radius: 20)
                }
                
                // Rank kartları
                HStack(spacing: 16) {
                    rankCard(
                        title: userEnv.labelGlobal.uppercased(),
                        icon: "globe",
                        rank: rank.globalRank,
                        color: ThemeColors.neonCyan
                    )
                    
                    rankCard(
                        title: rank.countryCode,
                        icon: "flag.fill",
                        rank: rank.localRank,
                        color: ThemeColors.neonPurple
                    )
                }
                
                HStack(spacing: 12) {
                    // Badge
                    HStack(spacing: 8) {
                        Image(systemName: "rosette")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(badgeColor)
                        
                        Text(rank.badge)
                            .font(.setCustomFont(name: .InterBlack, size: 14))
                            .foregroundStyle(badgeColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(badgeColor.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(badgeColor.opacity(0.3), lineWidth: 1))
                    
                    // Chapter
                    HStack(spacing: 6) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(ThemeColors.neonPurple)
                        Text(userEnv.labelChapterTemplate.replacingOccurrences(of: "{{value}}", with: "\(rank.chapter)"))
                            .font(.setCustomFont(name: .InterBold, size: 13))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Capsule())
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(
                            colors: [ThemeColors.electricYellow.opacity(0.4), .clear, ThemeColors.neonCyan.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
        }
    }
    
    @ViewBuilder
    private func rankCard(title: String, icon: String, rank: Int, color: Color) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
                Text(title)
                    .font(.setCustomFont(name: .InterBold, size: 11))
                    .foregroundStyle(ThemeColors.textMuted)
            }
            
            Text("#\(rank)")
                .font(.setCustomFont(name: .InterBlack, size: 32))
                .foregroundStyle(color)
                .monospacedDigit()
                .shadow(color: color.opacity(0.3), radius: 8)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }
    
    private var badgeColor: Color {
        switch rank.badge {
        case "RARE":   return ThemeColors.electricYellow
        case "EXPERT": return ThemeColors.neonCyan
        default:       return ThemeColors.textMuted
        }
    }
}

// MARK: - Score Submit Result Banner

struct ScoreSubmitBanner: View {
    let result: ScoreSubmitResponse
    var onDismiss: (() -> Void)? = nil
    @EnvironmentObject var userEnv: UserEnvironment
    @State private var showRegistration = false
    
    var body: some View {
        VStack(spacing: 14) {
            // YENİ REKOR
            if result.isPersonalBest {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(ThemeColors.electricYellow)
                    Text(userEnv.labelNewRecordCaps)
                        .font(.setCustomFont(name: .InterBlack, size: 16))
                        .foregroundStyle(ThemeColors.electricYellow)
                }
            }
            
            // Rank info
            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    Text(userEnv.labelGlobal)
                        .font(.setCustomFont(name: .InterMedium, size: 10))
                        .foregroundStyle(ThemeColors.textMuted)
                    Text("#\(result.globalRank)")
                        .font(.setCustomFont(name: .InterBlack, size: 20))
                        .foregroundStyle(ThemeColors.neonCyan)
                }
                
                VStack(spacing: 2) {
                    Text(userEnv.labelCountry)
                        .font(.setCustomFont(name: .InterMedium, size: 10))
                        .foregroundStyle(ThemeColors.textMuted)
                    Text("#\(result.localRank)")
                        .font(.setCustomFont(name: .InterBlack, size: 20))
                        .foregroundStyle(ThemeColors.neonPurple)
                }
            }
            
            // Registration CTA (for unregistered users)
            if !userEnv.isRegistered {
                Button {
                    HapticManager.shared.play(.buttonTap)
                    showRegistration = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 13))
                        Text(userEnv.btnSaveScore)
                            .font(.setCustomFont(name: .InterBold, size: 12))
                    }
                    .foregroundStyle(ThemeColors.cosmicBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(ThemeColors.electricYellow)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(result.isPersonalBest ? ThemeColors.electricYellow.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
        )
        .onTapGesture { 
            if userEnv.isRegistered {
                onDismiss?()
            }
        }
        .sheet(isPresented: $showRegistration) {
            PlayerRegistrationView()
                .environmentObject(userEnv)
        }
    }
}

// MARK: - Loading / Empty / Error States

struct LeaderboardStateView: View {
    let state: LeaderboardState
    let retryAction: () -> Void
    @EnvironmentObject var userEnv: UserEnvironment
    
    var body: some View {
        VStack(spacing: 16) {
            switch state {
            case .loading:
                ProgressView()
                    .tint(ThemeColors.neonCyan)
                    .scaleEffect(1.2)
                Text(userEnv.labelLoadingEllipsis)
                    .font(.setCustomFont(name: .InterMedium, size: 13))
                    .foregroundStyle(ThemeColors.textMuted)
                
            case .empty:
                Image(systemName: "list.number")
                    .font(.system(size: 40))
                    .foregroundStyle(ThemeColors.textMuted)
                Text(userEnv.labelNoScoresYet)
                    .font(.setCustomFont(name: .InterMedium, size: 13))
                    .foregroundStyle(ThemeColors.textMuted)
                
            case .offline:
                Image(systemName: "wifi.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(ThemeColors.textMuted)
                Text(userEnv.labelNoInternetConnection)
                    .font(.setCustomFont(name: .InterMedium, size: 13))
                    .foregroundStyle(ThemeColors.textMuted)
                retryButton
                
            case .error(let msg):
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(ThemeColors.neonOrange)
                Text(msg)
                    .font(.setCustomFont(name: .InterMedium, size: 13))
                    .foregroundStyle(ThemeColors.textMuted)
                    .multilineTextAlignment(.center)
                retryButton
                
            default:
                EmptyView()
            }
        }
        .padding(.vertical, 40)
    }
    
    private var retryButton: some View {
        Button {
            HapticManager.shared.play(.buttonTap)
            retryAction()
        } label: {
            Text(userEnv.btnRetry)
                .font(.setCustomFont(name: .InterBold, size: 12))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(ThemeColors.neonCyan.opacity(0.2))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(ThemeColors.neonCyan.opacity(0.4), lineWidth: 1))
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        ThemeColors.cosmicBlack.ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 12) {
                LeaderboardRowView(
                    entry: LeaderboardEntry(rank: 1, username: "YakupSd", countryCode: "TR", score: 18909, chapter: 4, characterID: 0, badge: "RARE"),
                    isCurrentPlayer: true
                )
                LeaderboardRowView(
                    entry: LeaderboardEntry(rank: 2, username: "Player2", countryCode: "US", score: 15000, chapter: 3, characterID: 1, badge: "RARE"),
                    isCurrentPlayer: false
                )
                LeaderboardRowView(
                    entry: LeaderboardEntry(rank: 4, username: "Player4", countryCode: "DE", score: 8200, chapter: 2, characterID: 2, badge: "EXPERT"),
                    isCurrentPlayer: false
                )
            }
            .padding(16)
        }
    }
}
