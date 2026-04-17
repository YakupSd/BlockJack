//
//  BattleRewardView.swift
//  Block-Jack
//

import SwiftUI

struct BattleRewardView: View {
    let slotId: Int
    let onClaim: () -> Void
    
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
            
            VStack(spacing: 30) {
                VStack(spacing: 8) {
                    Text("TUR TAMAMLANDI!")
                        .font(.custom("Outfit-Bold", size: 36, relativeTo: .largeTitle))
                        .foregroundColor(ThemeColors.electricYellow)
                    
                    Text("Ganimeti topla ve güçlen.")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 40)
                
                Spacer()
                
                if rewards.isEmpty {
                    ProgressView()
                } else {
                    VStack(spacing: 16) {
                        ForEach(0..<rewards.count, id: \.self) { index in
                            RewardCard(
                                reward: rewards[index],
                                isSelected: selectedIndex == index,
                                disabled: hasClaimed
                            ) {
                                selectedIndex = index
                                claimReward(rewards[index])
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                if hasClaimed {
                    Button(action: onClaim) {
                        Text("DEVAM ET")
                            .font(.custom("Outfit-Bold", size: 20))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ThemeColors.electricYellow)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            generateRewards()
        }
    }
    
    private func generateRewards() {
        var options: [RewardOption] = []
        
        // 1. Gold Reward
        let goldAmount = Int.random(in: 100...250)
        options.append(RewardOption(
            title: "Veri Önbelleği",
            icon: "💰",
            desc: "+\(goldAmount) Altın kazan.",
            color: ThemeColors.electricYellow,
            action: { id in
                SaveManager.shared.updateGold(slotId: id, amount: goldAmount)
            }
        ))
        
        // 2. Consumable Reward
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
        
        // 3. Random Weak Perk or Life
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
            // Random perk pick
            if let perk = PerkEngine.perkPool.randomElement() {
                let slot = SaveManager.shared.slots.first(where: { $0.id == slotId })
                let isOwned = slot?.activePassivePerks.contains { $0.id == perk.id } ?? false
                let tier = slot?.activePassivePerks.first(where: { $0.id == perk.id })?.tier ?? 1
                
                options.append(RewardOption(
                    title: isOwned ? "LEVEL UP: \(perk.name)" : perk.name,
                    icon: perk.icon,
                    desc: isOwned ? "Mevcut perki L\(tier + 1) seviyesine yükselt." : "YENİ PERK: \(perk.desc)",
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
        withAnimation(.spring()) {
            hasClaimed = true
        }
        HapticManager.shared.play(.success)
    }
}

struct RewardCard: View {
    let reward: BattleRewardView.RewardOption
    let isSelected: Bool
    let disabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Text(reward.icon)
                    .font(.system(size: 40))
                    .frame(width: 80, height: 80)
                    .background(reward.color.opacity(0.1))
                    .cornerRadius(15)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(reward.title)
                        .font(.custom("Outfit-Bold", size: 20))
                        .foregroundColor(.white)
                    Text(reward.desc)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(reward.color)
                        .font(.title)
                }
            }
            .padding()
            .background(isSelected ? reward.color.opacity(0.15) : Color.white.opacity(0.05))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? reward.color : Color.white.opacity(0.1), lineWidth: 2)
            )
        }
        .disabled(disabled)
    }
}
