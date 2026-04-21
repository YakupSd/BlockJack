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
        case stats = "KAYITLAR"
        
        var icon: String {
            switch self {
            case .perks: return "square.grid.3x3.fill"
            case .bosses: return "person.badge.shield.checkmark.fill"
            case .stats: return "chart.bar.xaxis"
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
            
            Text("KOLEKSİYON")
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
                Text("TAMAMLANDI")
                    .font(.setCustomFont(name: .InterMedium, size: 8))
                    .foregroundStyle(ThemeColors.textMuted)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
    
    private var customTabBar: some View {
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
                            Text(tab.rawValue)
                                .font(.setCustomFont(name: .InterBold, size: 12))
                        }
                        .foregroundStyle(selectedTab == tab ? .white : ThemeColors.textMuted)
                        
                        // Indicator
                        Rectangle()
                            .fill(selectedTab == tab ? ThemeColors.electricYellow : Color.clear)
                            .frame(height: 3)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
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
                            Text("Bölüm sonunda karşılaş...")
                                .font(.setCustomFont(name: .InterMedium, size: 11))
                                .foregroundStyle(ThemeColors.textMuted)
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
            StatRow(title: "Toplam Skor", value: "\(userEnv.highScore.formatted())", icon: "crown.fill", color: ThemeColors.electricYellow)
            StatRow(title: "Toplam Altın Kazancı", value: "\(userEnv.totalGoldEarned.formatted())", icon: "dollarsign.circle.fill", color: ThemeColors.electricYellow)
            StatRow(title: "Temizlenen Satırlar", value: "\(userEnv.totalLinesCleared.formatted())", icon: "trapezoid.and.line.horizontal", color: ThemeColors.neonCyan)
            StatRow(title: "Yenilen Bosslar", value: "\(userEnv.totalBossesDefeated.formatted())", icon: "shield.fill", color: ThemeColors.neonPink)
            StatRow(title: "Keşfedilen Özellikler", value: "\(userEnv.discoveredPerkIDs.count) / \(PerkEngine.perkPool.count)", icon: "sparkles", color: ThemeColors.neonPurple)
        }
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
