//
//  PerkShopView.swift
//  Block-Jack
//
//  Slot bazlı Perk Shop. Kazanılan altınla kilitli perkleri kalıcı olarak
//  açar. Yeni kayıtta sıfırlanır — sadece o slota özgüdür.
//

import SwiftUI

struct PerkShopView: View {

    let slotId: Int
    @EnvironmentObject var userEnv: UserEnvironment
    @StateObject private var saveManager = SaveManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPerk: StartingPerk? = nil
    @State private var showInsufficientGold = false
    @State private var recentlyUnlocked: String? = nil

    private var slot: SaveSlot? {
        saveManager.slots.first { $0.id == slotId }
    }

    private var gold: Int { slot?.gold ?? 0 }

    private func isUnlocked(_ perk: StartingPerk) -> Bool {
        slot?.unlockedPerkIDs.contains(perk.id) ?? false
    }

    // Tier 1..5 gruplama
    private var tiers: [(Int, [StartingPerk])] {
        let all = StartingPerk.available
        let grouped = Dictionary(grouping: all, by: { $0.tier })
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        ZStack {
            // Arka plan
            LinearGradient(
                colors: [Color(hex: "#0A0B1A"), Color(hex: "#0D1230")],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(ThemeColors.textSecondary)
                            .padding(12)
                            .background(ThemeColors.surfaceDark)
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text(userEnv.localizedString("PERK DÜKKANI", "PERK SHOP"))
                        .font(.setCustomFont(name: .InterBlack, size: 18))
                        .tracking(4)
                        .foregroundStyle(ThemeColors.electricYellow)
                    Spacer()
                    // Gold badge
                    HStack(spacing: 6) {
                        Image("icon_gold")
                            .resizable()
                            .frame(width: 18, height: 18)
                        Text("\(gold)")
                            .font(.setCustomFont(name: .InterBold, size: 15))
                            .foregroundStyle(ThemeColors.electricYellow)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(ThemeColors.surfaceDark)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Insufficient gold banner
                if showInsufficientGold {
                    Text(userEnv.localizedString("⚠️ Yetersiz altın!", "⚠️ Not enough gold!"))
                        .font(.setCustomFont(name: .InterBold, size: 13))
                        .foregroundStyle(ThemeColors.neonPink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(ThemeColors.neonPink.opacity(0.12))
                        .clipShape(Capsule())
                        .transition(.opacity.combined(with: .scale))
                        .padding(.bottom, 8)
                }

                // Perk List
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(tiers, id: \.0) { tier, perks in
                            tierSection(tier: tier, perks: perks)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }

            // Detail panel
            if let perk = selectedPerk {
                detailPanel(perk)
            }
        }
        .navigationBarHidden(true)
        .animation(.spring(response: 0.3), value: showInsufficientGold)
        .animation(.spring(response: 0.3), value: selectedPerk?.id)
    }

    // MARK: - Tier Section

    private func tierSection(tier: Int, perks: [StartingPerk]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(tierLabel(tier))
                    .font(.setCustomFont(name: .InterBlack, size: 11))
                    .tracking(3)
                    .foregroundStyle(tierColor(tier))
                if tier == 1 {
                    Text(userEnv.localizedString("BAŞLANGIÇ", "STARTER"))
                        .font(.setCustomFont(name: .InterBold, size: 10))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(ThemeColors.success.opacity(0.25))
                        .clipShape(Capsule())
                }
                Spacer()
                if tier > 1 {
                    Image("icon_gold")
                        .resizable().frame(width: 13, height: 13)
                    Text("\(perks.first?.goldCost ?? 0)")
                        .font(.setCustomFont(name: .InterBold, size: 13))
                        .foregroundStyle(ThemeColors.electricYellow)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(perks) { perk in
                    perkCard(perk)
                }
            }
        }
    }

    // MARK: - Perk Card

    private func perkCard(_ perk: StartingPerk) -> some View {
        let unlocked = isUnlocked(perk)
        let isNew = recentlyUnlocked == perk.id

        return Button {
            HapticManager.shared.play(.selection)
            selectedPerk = perk
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(unlocked ? tierColor(perk.tier).opacity(0.15) : Color.white.opacity(0.04))
                        .frame(width: 56, height: 56)
                    perkIcon(perk)
                        .opacity(unlocked ? 1 : 0.35)
                    if !unlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .offset(x: 18, y: 18)
                    }
                    if isNew {
                        Circle()
                            .stroke(ThemeColors.electricYellow, lineWidth: 2)
                            .frame(width: 56, height: 56)
                    }
                }
                Text(perk.displayName(lang: userEnv.language))
                    .font(.setCustomFont(name: .InterBold, size: 12))
                    .foregroundStyle(unlocked ? .white : .white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(unlocked
                          ? tierColor(perk.tier).opacity(0.10)
                          : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(unlocked ? tierColor(perk.tier).opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Detail Panel

    private func detailPanel(_ perk: StartingPerk) -> some View {
        let unlocked = isUnlocked(perk)
        let canAfford = gold >= perk.goldCost

        return VStack {
            Spacer()
            VStack(spacing: 16) {
                HStack {
                    perkIcon(perk)
                        .scaleEffect(1.4)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(perk.displayName(lang: userEnv.language))
                            .font(.setCustomFont(name: .ManropeExtraBold, size: 18))
                            .foregroundStyle(.white)
                        Text(tierLabel(perk.tier))
                            .font(.setCustomFont(name: .InterBold, size: 11))
                            .tracking(2)
                            .foregroundStyle(tierColor(perk.tier))
                    }
                    Spacer()
                    Button { selectedPerk = nil } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(ThemeColors.textSecondary)
                            .padding(10)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }

                Text(perk.displayDesc(lang: userEnv.language))
                    .font(.setCustomFont(name: .InterMedium, size: 14))
                    .foregroundStyle(ThemeColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if unlocked {
                    Label(userEnv.localizedString("Açık", "Unlocked"), systemImage: "checkmark.circle.fill")
                        .font(.setCustomFont(name: .InterBold, size: 15))
                        .foregroundStyle(ThemeColors.success)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(ThemeColors.success.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else if perk.tier == 1 {
                    Text(userEnv.localizedString("Başlangıç perki — otomatik açık", "Starter perk — always free"))
                        .font(.setCustomFont(name: .InterMedium, size: 13))
                        .foregroundStyle(ThemeColors.textMuted)
                } else {
                    Button {
                        attemptUnlock(perk)
                    } label: {
                        HStack(spacing: 8) {
                            Image("icon_gold").resizable().frame(width: 18, height: 18)
                            Text("\(perk.goldCost) \(userEnv.localizedString("Altın ile Aç", "Gold to Unlock"))")
                                .font(.setCustomFont(name: .InterExtraBold, size: 16))
                                .foregroundStyle(canAfford ? ThemeColors.cosmicBlack : .white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(canAfford ? ThemeColors.electricYellow : Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!canAfford)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(hex: "#10142A"))
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.08), lineWidth: 1))
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
        }
        .ignoresSafeArea(edges: .bottom)
        .background(Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { selectedPerk = nil })
    }

    // MARK: - Actions

    private func attemptUnlock(_ perk: StartingPerk) {
        let success = SaveManager.shared.unlockPerk(slotId: slotId, perk: perk)
        if success {
            HapticManager.shared.play(.success)
            recentlyUnlocked = perk.id
            selectedPerk = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { recentlyUnlocked = nil }
        } else {
            HapticManager.shared.play(.error)
            withAnimation { showInsufficientGold = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showInsufficientGold = false }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func perkIcon(_ perk: StartingPerk) -> some View {
        if perk.icon.hasPrefix("item_") {
            Image(perk.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
        } else {
            Text(perk.icon)
                .font(.system(size: 28))
        }
    }

    private func tierLabel(_ tier: Int) -> String {
        switch tier {
        case 1: return userEnv.localizedString("TIER 1 — ÜCRETSİZ", "TIER 1 — FREE")
        case 2: return "TIER 2 — 200 🪙"
        case 3: return "TIER 3 — 400 🪙"
        case 4: return "TIER 4 — 600 🪙"
        default: return "TIER 5 — 800 🪙"
        }
    }

    private func tierColor(_ tier: Int) -> Color {
        switch tier {
        case 1: return ThemeColors.success
        case 2: return ThemeColors.neonCyan
        case 3: return ThemeColors.electricYellow
        case 4: return Color.orange
        default: return ThemeColors.neonPink
        }
    }
}
