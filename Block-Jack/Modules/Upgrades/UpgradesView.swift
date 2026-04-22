//
//  UpgradesView.swift
//  Block-Jack
//

import SwiftUI

struct UpgradesView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @State private var selectedTab: Int = 0 // 0 = Elmas, 1 = Altın

    /// Slot Hub'dan açıldığında hangi slot için alışveriş yapıldığını
    /// başlıkta göstermek için tutulur. nil ise "hesap seviyesi" kabul
    /// edilir (eski erişim yolu). Satın alma hesap-global olduğu için
    /// aslında yalnızca UI göstergesi.
    let slotId: Int?

    init(slotId: Int? = nil) { self.slotId = slotId }

    var body: some View {
        ZStack {
            ThemeColors.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    Button {
                        HapticManager.shared.play(.buttonTap)
                        MainViewsRouter.shared.dismissModal()
                    } label: {
                        Image("ui_close")
                            .resizable()
                            .frame(width: 44, height: 44)
                            .background(ThemeColors.surfaceDark)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(ThemeColors.gridStroke, lineWidth: 1))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text(userEnv.localizedString("MARKET", "UPGRADES"))
                            .font(.setCustomFont(name: .InterBlack, size: 24))
                            .foregroundStyle(ThemeColors.electricYellow)
                            .tracking(2)
                        if let slotId = slotId {
                            Text(userEnv.localizedString("SLOT \(slotId)", "SLOT \(slotId)"))
                                .font(.setCustomFont(name: .InterBold, size: 10))
                                .tracking(2)
                                .foregroundStyle(ThemeColors.textMuted)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(ThemeColors.electricYellow.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    Spacer()

                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // MARK: - Currency Row
                HStack(spacing: 20) {
                    // Gold
                    HStack(spacing: 6) {
                        Image("icon_gold")
                            .resizable()
                            .frame(width: 26, height: 26)
                        Text("\(userEnv.gold)")
                            .font(.setCustomFont(name: .InterExtraBold, size: 20))
                            .foregroundStyle(ThemeColors.electricYellow)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 16)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(ThemeColors.electricYellow.opacity(0.3), lineWidth: 1))
                    
                    // Diamond
                    HStack(spacing: 6) {
                        Image("icon_diamond")
                            .resizable()
                            .frame(width: 26, height: 26)
                        Text("\(userEnv.diamonds)")
                            .font(.setCustomFont(name: .InterExtraBold, size: 20))
                            .foregroundStyle(ThemeColors.neonCyan)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 16)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(ThemeColors.neonCyan.opacity(0.3), lineWidth: 1))
                }
                .padding(.bottom, 16)
                
                // MARK: - Tab Selector
                HStack(spacing: 8) {
                    tabButton(title: userEnv.localizedString("ALTIN", "GOLD"), icon: "icon_gold", index: 1, accentColor: ThemeColors.electricYellow)
                    tabButton(title: userEnv.localizedString("ELMAS", "DIAMOND"), icon: "icon_diamond", index: 0, accentColor: ThemeColors.neonCyan)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                // MARK: - Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 14) {
                        if selectedTab == 0 {
                            // --- Diamond Tab ---
                            sectionHeader(title: userEnv.localizedString("KALİCİ GELİŞTİRMELER", "PERMANENT UPGRADES"),
                                          subtitle: userEnv.localizedString("Tek seferlik satın al, sonsuza kadar aktif.", "Buy once, active forever."))
                            upgradeRow(.goldEye, icon: "upg_gold_eye", titleTR: "Altın Göz", titleEN: "Gold Eye", descTR: "Pasif: Her tur sonu +%10 bonus altın.", descEN: "Passive: +10% bonus gold at round end.")
                            upgradeRow(.ironWill, icon: "shield.fill", titleTR: "Iron Will", titleEN: "Iron Will", descTR: "Başlangıç süresini +10 saniye artırır.", descEN: "Starting time +10 seconds permanently.")
                            upgradeRow(.luckyDice, icon: "dice.fill", titleTR: "Şanslı Zar", titleEN: "Lucky Dice", descTR: "The Gambler'ın şansı +%3 artar.", descEN: "Gambler's trigger chance +3%.")
                            upgradeRow(.extraSlot, icon: "bag.fill", titleTR: "Ekstra Slot", titleEN: "Extra Slot", descTR: "Maksimum envanter 3'ten 4'e çıkar.", descEN: "Max inventory slots from 3 to 4.")
                        } else {
                            // --- Gold Tab ---
                            sectionHeader(title: userEnv.localizedString("PASSİF GÜÇLENDİRMELER", "PASSIVE BOOSTS"),
                                          subtitle: userEnv.localizedString("Seviye atla, etkisi artsın. Max. Seviye: 5", "Level up for stronger effect. Max Level: 5"))
                            ForEach(GoldUpgrade.allCases, id: \.rawValue) { upgrade in
                                goldUpgradeRow(upgrade)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Section Header
    @ViewBuilder
    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.setCustomFont(name: .InterBold, size: 13))
                .foregroundStyle(ThemeColors.textSecondary)
                .tracking(2)
            Text(subtitle)
                .font(.setCustomFont(name: .InterMedium, size: 11))
                .foregroundStyle(ThemeColors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
    
    // MARK: - Tab Button
    @ViewBuilder
    private func tabButton(title: String, icon: String, index: Int, accentColor: Color) -> some View {
        let isSelected = selectedTab == index
        Button {
            HapticManager.shared.play(.selection)
            withAnimation(.spring(response: 0.3)) {
                selectedTab = index
            }
        } label: {
            HStack(spacing: 6) {
                Image(icon)
                    .resizable()
                    .frame(width: 18, height: 18)
                Text(title)
                    .font(.setCustomFont(name: .InterBold, size: 13))
            }
            .foregroundStyle(isSelected ? ThemeColors.cosmicBlack : accentColor)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? accentColor : accentColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.clear : accentColor.opacity(0.4), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Diamond Upgrade Row
    @ViewBuilder
    private func upgradeRow(_ upgrade: MetaUpgrade, icon: String, titleTR: String, titleEN: String, descTR: String, descEN: String) -> some View {
        let isUnlocked = userEnv.unlockedUpgradeIDs.contains(upgrade.rawValue)
        let canAfford = userEnv.diamonds >= upgrade.cost
        
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isUnlocked ? ThemeColors.neonCyan.opacity(0.1) : ThemeColors.gridDark)
                    .frame(width: 54, height: 54)
                
                if icon.contains("upg_") {
                    Image(icon)
                        .resizable()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(isUnlocked ? ThemeColors.neonCyan : ThemeColors.textSecondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(userEnv.localizedString(titleTR, titleEN))
                        .font(.setCustomFont(name: .InterBold, size: 15))
                        .foregroundStyle(.white)
                    if isUnlocked {
                        Text(userEnv.localizedString("AKTİF", "ACTIVE"))
                            .font(.setCustomFont(name: .InterBold, size: 9))
                            .foregroundStyle(ThemeColors.neonCyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ThemeColors.neonCyan.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                Text(userEnv.localizedString(descTR, descEN))
                    .font(.setCustomFont(name: .InterMedium, size: 12))
                    .foregroundStyle(ThemeColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Button {
                if !isUnlocked {
                    HapticManager.shared.play(.buttonTap)
                    if userEnv.spend(diamonds: upgrade.cost) {
                        userEnv.unlockedUpgradeIDs.append(upgrade.rawValue)
                        HapticManager.shared.play(.success)
                    } else {
                        HapticManager.shared.play(.error)
                    }
                }
            } label: {
                if isUnlocked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(ThemeColors.cosmicBlack)
                        .frame(width: 32, height: 32)
                        .background(ThemeColors.neonCyan)
                        .clipShape(Circle())
                } else {
                    VStack(spacing: 2) {
                        Text("\(upgrade.cost)")
                            .font(.setCustomFont(name: .InterBold, size: 13))
                        Image("icon_diamond")
                            .resizable()
                            .frame(width: 12, height: 12)
                    }
                    .foregroundStyle(canAfford ? ThemeColors.cosmicBlack : ThemeColors.textMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(canAfford ? ThemeColors.neonCyan : ThemeColors.gridDark)
                    .clipShape(Capsule())
                }
            }
            .disabled(isUnlocked)
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isUnlocked ? ThemeColors.neonCyan.opacity(0.5) : ThemeColors.gridStroke.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: isUnlocked ? ThemeColors.neonCyan.opacity(0.12) : .clear, radius: 10)
    }
    
    // MARK: - Gold Upgrade Row (Leveled)
    @ViewBuilder
    private func goldUpgradeRow(_ upgrade: GoldUpgrade) -> some View {
        let level = userEnv.goldLevel(for: upgrade)
        let isMaxed = level >= upgrade.maxLevel
        let nextLevel = level + 1
        let cost = upgrade.cost(for: nextLevel)
        let canAfford = userEnv.gold >= cost
        
        HStack(spacing: 14) {
            // Icon + Level Badge
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(level > 0 ? ThemeColors.electricYellow.opacity(0.12) : ThemeColors.gridDark)
                        .frame(width: 54, height: 54)
                    Image(systemName: upgrade.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(level > 0 ? ThemeColors.electricYellow : ThemeColors.textSecondary)
                }
                
                if level > 0 {
                    Text("Lv\(level)")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(ThemeColors.cosmicBlack)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(ThemeColors.electricYellow)
                        .clipShape(Capsule())
                        .offset(x: 4, y: 4)
                }
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(userEnv.localizedString(upgrade.titleTR, upgrade.titleEN))
                        .font(.setCustomFont(name: .InterBold, size: 15))
                        .foregroundStyle(.white)
                    if isMaxed {
                        Text("MAX")
                            .font(.setCustomFont(name: .InterBold, size: 9))
                            .foregroundStyle(ThemeColors.electricYellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ThemeColors.electricYellow.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                
                if level > 0 {
                    Text(userEnv.localizedString(upgrade.descTR(level: level), upgrade.descEN(level: level)))
                        .font(.setCustomFont(name: .InterMedium, size: 11))
                        .foregroundStyle(ThemeColors.electricYellow.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if !isMaxed {
                    Text(userEnv.localizedString("Sonraki: \(upgrade.descTR(level: nextLevel))", "Next: \(upgrade.descEN(level: nextLevel))"))
                        .font(.setCustomFont(name: .InterMedium, size: 11))
                        .foregroundStyle(ThemeColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Level progress dots
                HStack(spacing: 4) {
                    ForEach(1...upgrade.maxLevel, id: \.self) { i in
                        Circle()
                            .fill(i <= level ? ThemeColors.electricYellow : ThemeColors.gridDark)
                            .frame(width: 7, height: 7)
                            .overlay(Circle().stroke(ThemeColors.gridStroke, lineWidth: 0.5))
                    }
                }
                .padding(.top, 2)
            }
            
            Spacer()
            
            // Buy Button
            Button {
                if !isMaxed {
                    HapticManager.shared.play(.buttonTap)
                    if userEnv.upgradeGold(upgrade) {
                        HapticManager.shared.play(.success)
                    } else {
                        HapticManager.shared.play(.error)
                    }
                }
            } label: {
                if isMaxed {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeColors.electricYellow)
                        .frame(width: 36, height: 36)
                        .background(ThemeColors.electricYellow.opacity(0.15))
                        .clipShape(Circle())
                } else {
                    VStack(spacing: 2) {
                        Text("\(cost)")
                            .font(.setCustomFont(name: .InterBold, size: 13))
                        Image("icon_gold")
                            .resizable()
                            .frame(width: 12, height: 12)
                    }
                    .foregroundStyle(canAfford ? ThemeColors.cosmicBlack : ThemeColors.textMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(canAfford ? ThemeColors.electricYellow : ThemeColors.gridDark)
                    .clipShape(Capsule())
                }
            }
            .disabled(isMaxed)
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(level > 0 ? ThemeColors.electricYellow.opacity(0.4) : ThemeColors.gridStroke.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: level > 0 ? ThemeColors.electricYellow.opacity(0.1) : .clear, radius: 8)
    }
}

#Preview {
    UpgradesView()
        .environmentObject(UserEnvironment.shared)
}
