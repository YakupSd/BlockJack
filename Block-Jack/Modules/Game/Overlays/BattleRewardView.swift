//
//  BattleRewardView.swift
//  Block-Jack
//
//  Tur sonu ödül ekranı. 2-3 kart arasından seç.
//  Layout AdaptiveOverlay ile SE/14 dahil tüm boyutlara uyumlu.
//

import SwiftUI

struct BattleRewardView: View {
    let slotId: Int
    var isChallenge: Bool = false
    let onClaim: () -> Void

    @EnvironmentObject var userEnv: UserEnvironment
    @State private var rewards: [RewardOption] = []
    @State private var selectedIndex: Int? = nil
    @State private var hasClaimed = false

    struct RewardOption: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let desc: String
        let color: Color
        let action: (Int) -> Void
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            AdaptiveOverlay(
                header: {
                    OverlayTitleBlock(
                        userEnv.localizedString("TUR TAMAMLANDI!", "ROUND COMPLETE!"),
                        subtitle: isChallenge
                        ? userEnv.localizedString("BONUS ÖDÜL AKTİF (Challenge/Contract).", "BONUS REWARD ACTIVE (Challenge/Contract).")
                        : userEnv.localizedString("Ganimeti topla ve güçlen.", "Claim your loot and power up."),
                        color: ThemeColors.electricYellow
                    )
                },
                content: {
                    if rewards.isEmpty {
                        ProgressView()
                            .tint(ThemeColors.electricYellow)
                            .padding(.vertical, 30)
                    } else {
                        rewardList
                    }
                },
                footer: {
                    if hasClaimed {
                        Button(action: {
                            NotificationCenter.default.post(name: NSNotification.Name("mapOverlayDidDismiss"), object: nil)
                            onClaim()
                        }) {
                            Text(userEnv.localizedString("DEVAM ET", "CONTINUE"))
                                .font(.custom("Outfit-Bold", size: 18))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(ThemeColors.electricYellow)
                                .foregroundColor(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        // Footer slot'u boş ama yer tutsun — layout sıçramasın
                        Color.clear.frame(height: 44)
                    }
                }
            )
        }
        .onAppear { generateRewards() }
    }

    // MARK: - Ödül listesi

    private var rewardList: some View {
        VStack(spacing: 14) {
            ForEach(Array(rewards.enumerated()), id: \.element.id) { index, reward in
                RewardCard(
                    reward: reward,
                    isSelected: selectedIndex == index,
                    disabled: hasClaimed
                ) {
                    selectedIndex = index
                    claimReward(reward)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Ödül üretimi

    private func generateRewards() {
        var options: [RewardOption] = []

        let goldAmount = isChallenge ? Int.random(in: 220...480) : Int.random(in: 100...250)
        options.append(RewardOption(
            title: "Veri Önbelleği",
            icon: "💰",
            desc: "+\(goldAmount) Altın kazan.",
            color: ThemeColors.electricYellow,
            action: { id in
                SaveManager.shared.updateGold(slotId: id, amount: goldAmount)
            }
        ))

        if isChallenge {
            let diamondAmount = Int.random(in: 8...18)
            options.append(RewardOption(
                title: "Elmas Önbelleği",
                icon: "💎",
                desc: "+\(diamondAmount) Elmas kazan.",
                color: ThemeColors.neonCyan,
                action: { _ in
                    UserEnvironment.shared.earn(diamonds: diamondAmount)
                }
            ))
        }

        if let randomPotion = ConsumableItem.shopPool.randomElement() {
            options.append(RewardOption(
                title: randomPotion.name,
                icon: randomPotion.icon,
                desc: randomPotion.desc,
                color: ThemeColors.neonCyan,
                action: { id in
                    SaveManager.shared.addConsumable(slotId: id, item: randomPotion)
                }
            ))
        }

        let rand = Double.random(in: 0...1)
        if rand < 0.3 {
            options.append(RewardOption(
                title: "Yedek Batarya",
                icon: "❤️",
                desc: "+1 Yaşam Puanı kazan.",
                color: ThemeColors.neonPink,
                action: { id in
                    SaveManager.shared.updateLives(slotId: id, amount: 1)
                }
            ))
        } else {
            let slot = SaveManager.shared.slots.first(where: { $0.id == slotId })
            let unlockedIds = Set(slot?.unlockedPerkIDs.isEmpty == false ? slot!.unlockedPerkIDs : StartingPerk.defaultUnlockedIDs)
            
            // Sadece açık olan perkler havuzda
            let availablePerks = PerkEngine.perkPool.filter { unlockedIds.contains($0.id) }
            
            if let perk = availablePerks.randomElement() {
                let isOwned = slot?.activePassivePerks.contains { $0.id == perk.id } ?? false
                let tier = slot?.activePassivePerks.first(where: { $0.id == perk.id })?.tier ?? 1

                options.append(RewardOption(
                    title: isOwned ? "LEVEL UP: \(perk.name)" : perk.name,
                    icon: perk.icon,
                    desc: isOwned
                        ? "Mevcut perki L\(tier + 1) seviyesine yükselt."
                        : "YENİ PERK: \(perk.desc)",
                    color: isOwned ? ThemeColors.neonCyan : ThemeColors.neonPurple,
                    action: { id in
                        SaveManager.shared.addPassivePerk(slotId: id, perk: perk)
                    }
                ))
            }
        }

        self.rewards = options.shuffled()
    }

    private func claimReward(_ reward: RewardOption) {
        reward.action(slotId)
        withAnimation(.spring()) { hasClaimed = true }
        HapticManager.shared.play(.success)
    }
}

// MARK: - Reward Card

struct RewardCard: View {
    let reward: BattleRewardView.RewardOption
    let isSelected: Bool
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(reward.icon)
                    .font(.system(size: 36))
                    .frame(width: 68, height: 68)
                    .background(reward.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(reward.title)
                        .font(.custom("Outfit-Bold", size: 17))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .multilineTextAlignment(.leading)
                    Text(reward.desc)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(reward.color)
                        .font(.title2)
                }
            }
            .padding(14)
            .background(isSelected ? reward.color.opacity(0.15) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        isSelected ? reward.color : Color.white.opacity(0.1),
                        lineWidth: 2
                    )
            )
        }
        .disabled(disabled)
        .buttonStyle(.plain)
    }
}
