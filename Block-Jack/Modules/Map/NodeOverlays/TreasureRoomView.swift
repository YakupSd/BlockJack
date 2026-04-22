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
        let currentPerkIds = Set(slot.activePassivePerks.map { $0.id })
        
        // Mevcut olmayanlar arasından 3 rastgele seç
        let pool = PerkEngine.perkPool.filter { !currentPerkIds.contains($0.id) }
        self.options = Array(pool.shuffled().prefix(3))
    }
    
    // MARK: - Components
    
    private var headerSection: some View {
        OverlayTitleBlock(
            "HAZİNE ODASI",
            subtitle: treasureOpened
                ? "Bir hediye seç!"
                : "Karanlık bir köşede eski bir sandık duruyor...",
            color: ThemeColors.neonGreen
        )
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

                Text(userEnv.localizedString("SANDIĞI AÇ", "OPEN CHEST"))
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
            ForEach(options) { perk in
                Button(action: {
                    SaveManager.shared.addPassivePerk(slotId: slotId, perk: perk)
                    withAnimation { selectedPerk = perk }
                    HapticManager.shared.play(.success)
                }) {
                    HStack(spacing: 14) {
                        Text(perk.icon)
                            .font(.system(size: 34))
                            .frame(width: 60, height: 60)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(perk.name)
                                .font(.headline)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            Text(perk.desc)
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
                    .shadow(color: ThemeColors.neonGreen.opacity(0.18), radius: 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var rewardClaimedSection: some View {
        VStack(spacing: 18) {
            Text(selectedPerk?.icon ?? "🎁")
                .font(.system(size: 80))
                .shadow(color: ThemeColors.neonGreen, radius: 20)

            Text("\(selectedPerk?.name ?? "") Elde Edildi!")
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
        Button(action: { dismiss() }) {
            Text(selectedPerk != nil ? "DEVAM ET" : "ATLA")
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
