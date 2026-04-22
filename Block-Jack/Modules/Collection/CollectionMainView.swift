//
//  CollectionMainView.swift
//  Block-Jack
//

import SwiftUI

struct CollectionMainView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab: CollectionTab = .perks
    
    enum CollectionTab: String, CaseIterable {
        case perks = "PERKLER"
        case bosses = "BOSS'LAR"
        case achievements = "BAŞARI"
        case leaderboard = "SKOR"
        case stats = "KAYIT"
        
        var icon: String {
            switch self {
            case .perks: return "square.grid.3x3.fill"
            case .bosses: return "person.badge.shield.checkmark.fill"
            case .achievements: return "trophy.fill"
            case .leaderboard: return "list.number"
            case .stats: return "chart.bar.xaxis"
            }
        }

        func displayName(for lang: AppLanguage) -> String {
            switch self {
            case .perks:        return lang == .turkish ? "PERKLER"    : "PERKS"
            case .bosses:       return lang == .turkish ? "BOSS'LAR"   : "BOSSES"
            case .achievements: return lang == .turkish ? "BAŞARI"     : "AWARDS"
            case .leaderboard:  return lang == .turkish ? "SKOR"       : "SCORES"
            case .stats:        return lang == .turkish ? "KAYIT"      : "STATS"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            ThemeColors.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                
                customTabBar
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        switch selectedTab {
                        case .perks:
                            perksTab
                        case .bosses:
                            bossesTab
                        case .achievements:
                            achievementsTab
                        case .leaderboard:
                            leaderboardTab
                        case .stats:
                            statsTab
                        }
                    }
                    .padding(24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        HStack {
            Button {
                HapticManager.shared.play(.buttonTap)
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(ThemeColors.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(ThemeColors.surfaceDark)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text(userEnv.localizedString("KOLEKSİYON", "COLLECTION"))
                .font(.setCustomFont(name: .InterBlack, size: 22))
                .foregroundStyle(ThemeColors.electricYellow)
                .tracking(2)
            
            Spacer()
            
            // Percentage
            VStack(alignment: .trailing, spacing: 2) {
                let totalItems = PerkEngine.perkPool.count + BossRegistry.shared.bossesSnapshot.count
                let discovered = userEnv.discoveredPerkIDs.count + userEnv.discoveredBossIDs.count
                let percent = totalItems > 0 ? (discovered * 100 / totalItems) : 0
                
                Text("\(percent)%")
                    .font(.setCustomFont(name: .InterBold, size: 16))
                    .foregroundStyle(ThemeColors.neonCyan)
                Text(userEnv.localizedString("TAMAMLANDI", "COMPLETED"))
                    .font(.setCustomFont(name: .InterMedium, size: 8))
                    .foregroundStyle(ThemeColors.textMuted)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
    
    private var customTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(CollectionTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                        HapticManager.shared.play(.selection)
                    } label: {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 14))
                                Text(tab.displayName(for: userEnv.language))
                                    .font(.setCustomFont(name: .InterBold, size: 11))
                            }
                            .foregroundStyle(selectedTab == tab ? .white : ThemeColors.textMuted)

                            Rectangle()
                                .fill(selectedTab == tab ? ThemeColors.electricYellow : Color.clear)
                                .frame(height: 3)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 14)
                    }
                }
            }
        }
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Tab Content
    
    private var perksTab: some View {
        let allPerks = PerkEngine.perkPool
        let columns = [GridItem(.adaptive(minimum: 80), spacing: 16)]
        
        return LazyVGrid(columns: columns, spacing: 20) {
            ForEach(allPerks) { perk in
                let isDiscovered = userEnv.discoveredPerkIDs.contains(perk.id)
                
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(ThemeColors.surfaceMid)
                            .frame(width: 80, height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isDiscovered ? ThemeColors.neonCyan : ThemeColors.gridStroke.opacity(0.3), lineWidth: 1.5)
                            )
                        
                        if isDiscovered {
                            if perk.icon.hasPrefix("item_") {
                                Image(perk.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 44, height: 44)
                            } else {
                                Text(perk.icon)
                                    .font(.system(size: 32))
                            }
                        } else {
                            Image(systemName: "questionmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(ThemeColors.textMuted.opacity(0.5))
                        }
                    }
                    .shadow(color: isDiscovered ? ThemeColors.neonCyan.opacity(0.2) : .clear, radius: 10)
                    
                    Text(isDiscovered ? perk.name : "???")
                        .font(.setCustomFont(name: .InterBold, size: 11))
                        .foregroundStyle(isDiscovered ? .white : ThemeColors.textMuted)
                        .lineLimit(1)
                }
            }
        }
    }
    
    private var bossesTab: some View {
        VStack(spacing: 20) {
            ForEach(BossRegistry.shared.bossesSnapshot) { boss in
                let isDiscovered = userEnv.discoveredBossIDs.contains(boss.id)
                
                HStack(spacing: 16) {
                    // Portrait
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(ThemeColors.surfaceDark)
                            .frame(width: 70, height: 70)
                        
                        if isDiscovered {
                            Image(boss.imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            Image(systemName: "person.fill.questionmark")
                                .font(.system(size: 30))
                                .foregroundStyle(ThemeColors.textMuted.opacity(0.3))
                        }
                    }
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(isDiscovered ? ThemeColors.neonPink : ThemeColors.gridStroke, lineWidth: 1))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isDiscovered ? boss.name : "GİZLİ VERİ")
                            .font(.setCustomFont(name: .InterBlack, size: 18))
                            .foregroundStyle(isDiscovered ? ThemeColors.neonPink : ThemeColors.textMuted)
                        
                        if isDiscovered {
                            Text(boss.modifier.title)
                                .font(.setCustomFont(name: .InterBold, size: 10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(ThemeColors.neonPink.opacity(0.2))
                                .foregroundStyle(ThemeColors.neonPink)
                                .cornerRadius(4)
                        } else {
                            // Kilitli boss için sadece "gizli" demek sıkıcı; karşılaşılacağı
                            // sektör aralığını hint olarak veriyoruz ki ilerleme görülebilsin.
                            Text(BossRegistry.shared.levelRangeLabel(for: boss.id))
                                .font(.setCustomFont(name: .InterBold, size: 10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(ThemeColors.textMuted.opacity(0.15))
                                .foregroundStyle(ThemeColors.textMuted)
                                .cornerRadius(4)
                        }
                    }
                    
                    Spacer()
                    
                    if isDiscovered {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(ThemeColors.neonCyan)
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
            }
        }
    }
    
    private var statsTab: some View {
        VStack(spacing: 16) {
            StatRow(title: userEnv.localizedString("En Yüksek Skor", "High Score"), value: "\(userEnv.highScore.formatted())", icon: "crown.fill", color: ThemeColors.electricYellow)
            StatRow(title: userEnv.localizedString("Toplam Altın Kazancı", "Total Gold Earned"), value: "\(userEnv.totalGoldEarned.formatted())", icon: "dollarsign.circle.fill", color: ThemeColors.electricYellow)
            StatRow(title: userEnv.localizedString("Temizlenen Satırlar", "Lines Cleared"), value: "\(userEnv.totalLinesCleared.formatted())", icon: "trapezoid.and.line.horizontal", color: ThemeColors.neonCyan)
            StatRow(title: userEnv.localizedString("Yenilen Bosslar", "Bosses Defeated"), value: "\(userEnv.totalBossesDefeated.formatted())", icon: "shield.fill", color: ThemeColors.neonPink)
            StatRow(title: userEnv.localizedString("Keşfedilen Perkler", "Perks Discovered"), value: "\(userEnv.discoveredPerkIDs.count) / \(PerkEngine.perkPool.count)", icon: "sparkles", color: ThemeColors.neonPurple)
            StatRow(title: userEnv.localizedString("Giriş Serisi", "Login Streak"), value: "\(userEnv.dailyStreak) \(userEnv.localizedString("gün", "days"))", icon: "calendar.badge.checkmark", color: ThemeColors.neonCyan)
        }
    }

    // MARK: - Phase 8: Achievements Tab

    private var achievementsTab: some View {
        VStack(spacing: 12) {
            ForEach(AchievementEngine.catalog) { ach in
                achievementRow(ach)
            }
        }
    }

    @ViewBuilder
    private func achievementRow(_ ach: Achievement) -> some View {
        let current = userEnv.achievementProgress[ach.id] ?? 0
        let isUnlocked = userEnv.unlockedAchievementIDs.contains(ach.id)
        let ratio = AchievementEngine.progressRatio(ach, current: current)
        let clamped = min(current, ach.goal)

        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? ThemeColors.electricYellow.opacity(0.15) : ThemeColors.surfaceDark)
                    .frame(width: 48, height: 48)
                Image(systemName: ach.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(isUnlocked ? ThemeColors.electricYellow : ThemeColors.textMuted)
            }
            .overlay(
                Circle()
                    .stroke(isUnlocked ? ThemeColors.electricYellow : ThemeColors.gridStroke.opacity(0.4), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(userEnv.localizedString(ach.titleTR, ach.titleEN))
                        .font(.setCustomFont(name: .InterBold, size: 14))
                        .foregroundStyle(isUnlocked ? .white : ThemeColors.textSecondary)
                    Spacer()
                    if isUnlocked {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(ThemeColors.neonCyan)
                            .font(.system(size: 14))
                    }
                }
                Text(userEnv.localizedString(ach.descTR, ach.descEN))
                    .font(.setCustomFont(name: .InterMedium, size: 11))
                    .foregroundStyle(ThemeColors.textMuted)
                    .lineLimit(2)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isUnlocked ? ThemeColors.electricYellow : ThemeColors.neonCyan)
                            .frame(width: max(0, geo.size.width * ratio), height: 6)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("\(clamped) / \(ach.goal)")
                        .font(.setCustomFont(name: .InterBold, size: 10))
                        .foregroundStyle(ThemeColors.textMuted)
                    Spacer()
                    if ach.rewardGold > 0 {
                        Label("\(ach.rewardGold)", systemImage: "dollarsign.circle.fill")
                            .font(.setCustomFont(name: .InterBold, size: 10))
                            .foregroundStyle(ThemeColors.electricYellow)
                    }
                    if ach.rewardDiamonds > 0 {
                        Label("\(ach.rewardDiamonds)", systemImage: "diamond.fill")
                            .font(.setCustomFont(name: .InterBold, size: 10))
                            .foregroundStyle(ThemeColors.neonCyan)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isUnlocked ? ThemeColors.electricYellow.opacity(0.35) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - Phase 8: Leaderboard Tab

    private var leaderboardTab: some View {
        VStack(spacing: 14) {
            if userEnv.topScores.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "list.number")
                        .font(.system(size: 40))
                        .foregroundStyle(ThemeColors.textMuted)
                    Text(userEnv.localizedString("Henüz bir sefer tamamlamadın.", "No completed runs yet."))
                        .font(.setCustomFont(name: .InterMedium, size: 13))
                        .foregroundStyle(ThemeColors.textMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
            } else {
                ForEach(Array(userEnv.topScores.enumerated()), id: \.element.id) { pair in
                    leaderboardRow(rank: pair.offset + 1, entry: pair.element)
                }
            }
        }
    }

    @ViewBuilder
    private func leaderboardRow(rank: Int, entry: LocalScoreEntry) -> some View {
        let date = Date(timeIntervalSince1970: entry.timestamp)
        let formatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "dd.MM.yy"
            return f
        }()

        HStack(spacing: 14) {
            Text("#\(rank)")
                .font(.setCustomFont(name: .InterBlack, size: 18))
                .foregroundStyle(rank == 1 ? ThemeColors.electricYellow : (rank == 2 ? ThemeColors.neonCyan : ThemeColors.textMuted))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.score.formatted())
                    .font(.setCustomFont(name: .InterBlack, size: 20))
                    .foregroundStyle(.white)
                HStack(spacing: 8) {
                    Label(userEnv.localizedString("Dünya \(entry.worldLevelReached)", "World \(entry.worldLevelReached)"), systemImage: "map.fill")
                        .font(.setCustomFont(name: .InterMedium, size: 10))
                        .foregroundStyle(ThemeColors.neonPurple)
                    Text(formatter.string(from: date))
                        .font(.setCustomFont(name: .InterMedium, size: 10))
                        .foregroundStyle(ThemeColors.textMuted)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 32)
            
            Text(title)
                .font(.setCustomFont(name: .InterMedium, size: 14))
                .foregroundStyle(ThemeColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.setCustomFont(name: .InterBold, size: 18))
                .foregroundStyle(.white)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    CollectionMainView()
        .environmentObject(UserEnvironment.shared)
}
