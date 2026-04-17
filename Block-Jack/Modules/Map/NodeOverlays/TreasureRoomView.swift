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
            // Fix Background Scaling (Task 2)
            GeometryReader { geo in
                Image("cyber_treasure_vault")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()
            
            Color.black.opacity(0.5).ignoresSafeArea() // Görünürlük için karartma
            
            // Magic Glow
            RadialGradient(
                colors: [ThemeColors.neonGreen.opacity(0.3), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 600
            ).ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                headerSection
                
                Spacer()
                
                if !treasureOpened {
                    closedChestSection
                } else {
                    if let _ = selectedPerk {
                        rewardClaimedSection
                    } else {
                        perkOptionsSection
                    }
                }
                
                Spacer()
                
                // Footer
                footerSection
            }
            .padding(.top, 40)
        }
        .onAppear {
            generateOptions()
        }
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
        VStack(spacing: 12) {
            Text("HAZİNE ODASI")
                .font(.custom("Outfit-Bold", size: 32, relativeTo: .largeTitle))
                .foregroundColor(ThemeColors.neonGreen)
            
            Text(treasureOpened ? "Bir hediye seç!" : "Karanlık bir köşede eski bir sandık duruyor...")
                .font(.subheadline)
                .foregroundColor(ThemeColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var closedChestSection: some View {
        Button(action: {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                treasureOpened = true
            }
            HapticManager.shared.play(.success)
        }) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(ThemeColors.neonGreen.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .blur(radius: 20)
                    
                    Image(systemName: "gift.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(ThemeColors.neonGreen)
                        .shadow(color: ThemeColors.neonGreen, radius: 20)
                        .scaleEffect(treasureOpened ? 1.5 : 1.0)
                        .scaleEffect(animateChest ? 1.1 : 1.0)
                }
                .phaseAnimator([0, -10, 0]) { content, offset in
                    content.offset(y: offset)
                } animation: { _ in
                    .easeInOut(duration: 2).repeatForever(autoreverses: true)
                }
                
                Text(userEnv.localizedString("SANDIĞI AÇ", "OPEN CHEST"))
                    .font(.setCustomFont(name: .InterBlack, size: 20))
                    .foregroundColor(ThemeColors.cosmicBlack)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(ThemeColors.neonGreen)
                    .clipShape(Capsule())
                    .shadow(color: ThemeColors.neonGreen.opacity(0.5), radius: 10)
            }
        }
    }
    
    private var perkOptionsSection: some View {
        VStack(spacing: 16) {
            ForEach(options) { perk in
                Button(action: {
                    SaveManager.shared.addPassivePerk(slotId: slotId, perk: perk)
                    withAnimation { selectedPerk = perk }
                    HapticManager.shared.play(.success)
                }) {
                    HStack(spacing: 16) {
                        Text(perk.icon)
                            .font(.largeTitle)
                            .frame(width: 70, height: 70)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(perk.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(perk.desc)
                                .font(.caption)
                                .foregroundColor(ThemeColors.textSecondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(ThemeColors.neonGreen.opacity(0.4), lineWidth: 1))
                    .shadow(color: ThemeColors.neonGreen.opacity(0.2), radius: 10)
                }
            }
        }
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var rewardClaimedSection: some View {
        VStack(spacing: 24) {
            Text(selectedPerk?.icon ?? "🎁")
                .font(.system(size: 100))
                .shadow(color: ThemeColors.neonGreen, radius: 20)
            
            Text("\(selectedPerk?.name ?? "") Elde Edildi!")
                .font(.title2)
                .bold()
                .foregroundColor(.white)
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    private var footerSection: some View {
        Button(action: {
            dismiss()
        }) {
            Text(selectedPerk != nil ? "DEVAM ET" : "ATLA")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.1))
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .padding()
    }
}
