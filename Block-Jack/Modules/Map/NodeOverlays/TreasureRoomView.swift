//
//  TreasureRoomView.swift
//  Block-Jack
//

import SwiftUI

struct TreasureRoomView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userEnv: UserEnvironment
    @State private var treasureOpened = false
    @State private var animateChest = false
    @State private var options: [PassivePerk] = []
    @State private var selectedPerk: PassivePerk?
    
    let slotId: Int
    
    var currentSlot: SaveSlot? {
        SaveManager.shared.slots.first(where: { $0.id == slotId })
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                Image("cyber_treasure_vault")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()

            Color.black.opacity(0.55).ignoresSafeArea()

            RadialGradient(
                colors: [ThemeColors.neonGreen.opacity(0.28), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 600
            )
            .ignoresSafeArea()

            AdaptiveOverlay(
                header: { headerSection },
                content: {
                    if !treasureOpened {
                        closedChestSection
                    } else if selectedPerk != nil {
                        rewardClaimedSection
                    } else {
                        perkOptionsSection
                    }
                },
                footer: { footerSection }
            )
        }
        .onAppear { generateOptions() }
    }
    
    private func generateOptions() {
        guard let slot = currentSlot else { return }
        
        // Havuz: Sadece slot'ta seviyesi en az 1 olan (unlocked) perkler.
        // Mevcut perkleri de dahil et (seviye atlamak için), ama tier 3+ olanları ele.
        let pool = PerkEngine.getPerkPool(lang: userEnv.language, perkLevels: slot.perkLevels).filter { perk in
            let metaLevel = slot.perkLevels[perk.id] ?? 0
            let currentRunTier = slot.activePassivePerks.first(where: { $0.id == perk.id })?.tier ?? 0
            return metaLevel >= 1 && currentRunTier < 3
        }
        self.options = Array(pool.shuffled().prefix(3))
    }
    
    // MARK: - Components
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            OverlayTitleBlock(
                userEnv.labelTreasureVaultCaps,
                subtitle: treasureOpened
                    ? userEnv.labelChooseReward
                    : userEnv.labelOldChestSitting,
                color: ThemeColors.neonGreen
            )
            Text("\(userEnv.labelSlotCaps) \(slotId)")
                .font(.setCustomFont(name: .InterBold, size: 10))
                .tracking(2)
                .foregroundStyle(ThemeColors.textMuted)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(ThemeColors.neonGreen.opacity(0.14))
                .clipShape(Capsule())
        }
    }

    private var closedChestSection: some View {
        Button(action: {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                treasureOpened = true
            }
            HapticManager.shared.play(.success)
        }) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(ThemeColors.neonGreen.opacity(0.1))
                        .frame(width: 170, height: 170)
                        .blur(radius: 20)

                    Image(systemName: "gift.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(ThemeColors.neonGreen)
                        .shadow(color: ThemeColors.neonGreen, radius: 20)
                        .scaleEffect(animateChest ? 1.1 : 1.0)
                }
                .phaseAnimator([0, -10, 0]) { content, offset in
                    content.offset(y: offset)
                } animation: { _ in
                    .easeInOut(duration: 2).repeatForever(autoreverses: true)
                }

                Text(userEnv.btnOpenChestCaps)
                    .font(.setCustomFont(name: .InterBlack, size: 18))
                    .foregroundColor(ThemeColors.cosmicBlack)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(ThemeColors.neonGreen)
                    .clipShape(Capsule())
                    .shadow(color: ThemeColors.neonGreen.opacity(0.5), radius: 10)
            }
        }
        .buttonStyle(.plain)
    }

    private var perkOptionsSection: some View {
        VStack(spacing: 14) {
            if options.isEmpty {
                Text(userEnv.labelCollectedAllPowers)
                    .font(.headline)
                    .foregroundColor(ThemeColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                ForEach(options) { perk in
                    let currentTier = currentSlot?.activePassivePerks.first(where: { $0.id == perk.id })?.tier ?? 0
                    let isOwned = currentTier > 0
                    
                    Button(action: {
                        SaveManager.shared.addPassivePerk(slotId: slotId, perk: perk)
                        withAnimation { selectedPerk = perk }
                        HapticManager.shared.play(.success)
                    }) {
                        HStack(spacing: 14) {
                            ZStack {
                                if perk.icon.hasPrefix("perk_") || perk.icon.hasPrefix("item_") {
                                    Image(perk.icon)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 44, height: 44)
                                } else {
                                    Image(systemName: perk.icon)
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundStyle(ThemeColors.neonGreen)
                                }
                            }
                            .frame(width: 60, height: 60)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(isOwned ? userEnv.formatPerkLevelUp(name: perk.name) : perk.name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                                Text(isOwned 
                                     ? userEnv.formatPerkUpgrade(from: currentTier, to: currentTier + 1)
                                     : perk.desc)
                                    .font(.caption)
                                    .foregroundColor(ThemeColors.textSecondary)
                                    .lineLimit(3)
                                    .minimumScaleFactor(0.85)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(ThemeColors.neonGreen.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            } // close else block
        }
        .padding(.horizontal, 20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var rewardClaimedSection: some View {
        VStack(spacing: 20) {
            if let icon = selectedPerk?.icon, icon.hasPrefix("perk_") || icon.hasPrefix("item_") {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .shadow(color: ThemeColors.neonGreen, radius: 20)
            } else {
                Image(systemName: selectedPerk?.icon ?? "gift.fill")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundStyle(ThemeColors.neonGreen)
                    .shadow(color: ThemeColors.neonGreen, radius: 20)
            }

            Text(userEnv.formatPerkClaimed(name: selectedPerk?.name ?? ""))
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .transition(.scale.combined(with: .opacity))
    }

    private var footerSection: some View {
        Button(action: {
            NotificationCenter.default.post(name: NSNotification.Name("mapOverlayDidDismiss"), object: nil)
            dismiss()
        }) {
            Text(selectedPerk != nil ? userEnv.btnContinue : userEnv.btnSkipCaps)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.1))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
