//
//  PassivePerkHUDView.swift
//  Block-Jack
//

import SwiftUI

struct PassivePerkHUDView: View {
    @ObservedObject var vm: GameViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if vm.run.activePassivePerks.isEmpty {
                    // Boş durum - belki siluetler gösterilebilir
                    Text("AKTİF PERK YOK")
                        .font(.custom("Outfit-Medium", size: 10))
                        .foregroundColor(ThemeColors.textMuted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().stroke(ThemeColors.gridStroke.opacity(0.3), lineWidth: 1))
                } else {
                    ForEach(vm.run.activePassivePerks) { perk in
                        PerkHUDIcon(
                            perk: perk,
                            isInteractable: perk.id == "sculptor", // Şimdilik sadece sculptor etkileşimli
                            vm: vm
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 50)
        }
    }
}

struct PerkHUDIcon: View {
    let perk: PassivePerk
    let isInteractable: Bool
    @ObservedObject var vm: GameViewModel
    
    @State private var isAnimating = false
    @State private var showDetails = false
    
    var hasSynergy: Bool {
        vm.activeSynergies.contains(where: { $0.requiredPerkIds.contains(perk.id) })
    }
    
    var body: some View {
        Button(action: {
            if perk.id == "sculptor" {
                vm.rotateSelectedBlock()
                withAnimation(.spring()) { isAnimating = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { isAnimating = false }
            }
        }) {
            ZStack {
                // Synergy Glow
                // Synergy Glow (Breathing)
                if hasSynergy {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(ThemeColors.neonPurple, lineWidth: 2)
                        .blur(radius: 4)
                        .scaleEffect(1.1)
                        .phaseAnimator([0.4, 1.0]) { content, opacity in
                            content.opacity(opacity)
                        } animation: { _ in
                            .easeInOut(duration: 1.5).repeatForever()
                        }
                }

                // Glow if interactable and selected block exists
                if isInteractable && vm.selectedBlock != nil {
                    Circle()
                        .fill(ThemeColors.neonCyan.opacity(0.2))
                        .blur(radius: 5)
                        .scaleEffect(isAnimating ? 1.5 : 1.0)
                }
                
                ZStack {
                    // TECH CHIP BACKGROUND
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ThemeColors.surfaceMid)
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isInteractable && vm.selectedBlock != nil ? ThemeColors.neonCyan : ThemeColors.gridStroke.opacity(0.4),
                                    lineWidth: 1.5
                                )
                        )
                    
                    // Segmented Corners (Dashed overlay for tech look)
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isInteractable && vm.selectedBlock != nil ? ThemeColors.neonCyan : ThemeColors.textMuted.opacity(0.3),
                            style: StrokeStyle(lineWidth: 1, dash: [2, 10])
                        )
                        .frame(width: 44, height: 44)

                    if perk.icon.hasPrefix("item_") || perk.icon.hasPrefix("port_") {
                        Image(perk.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                    } else {
                        Text(perk.icon)
                            .font(.system(size: 22))
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                    }
                }
            }
        }
        .disabled(!isInteractable)
        .overlay(
            ZStack(alignment: .topTrailing) {
                // Tier Indicator
                if perk.tier > 1 {
                    Text("L\(perk.tier)")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(ThemeColors.electricYellow)
                        .cornerRadius(4)
                        .offset(x: 10, y: -10)
                }
                
                if hasSynergy {
                    // Synergy Icon Indicator
                    Image(systemName: "bolt.horizontal.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(ThemeColors.neonPurple)
                        .background(Color.black.clipShape(Circle()))
                        .offset(x: -14, y: -14)
                }
            }
        )
        .popover(isPresented: $showDetails) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ThemeColors.surfaceMid)
                            .frame(width: 54, height: 54)
                        Text(perk.icon).font(.title2)
                    }
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ThemeColors.neonCyan.opacity(0.5), lineWidth: 1))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(perk.name)
                            .font(.setCustomFont(name: .InterBlack, size: 18))
                            .foregroundStyle(.white)
                        
                        HStack {
                            Text("LEVEL \(perk.tier)")
                                .font(.setCustomFont(name: .InterBold, size: 10))
                                .foregroundStyle(ThemeColors.electricYellow)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(ThemeColors.electricYellow.opacity(0.1))
                                .clipShape(Capsule())
                            
                            if hasSynergy {
                                Text("SYNERGY ACTIVE")
                                    .font(.setCustomFont(name: .InterBold, size: 10))
                                    .foregroundStyle(ThemeColors.neonPurple)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(ThemeColors.neonPurple.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    Spacer()
                }
                
                Text(perk.desc)
                    .font(.setCustomFont(name: .InterMedium, size: 13))
                    .foregroundStyle(ThemeColors.textSecondary)
                    .lineSpacing(4)
                
                if !perk.synergyPartnerIds.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(vm.userEnv.localizedString("SİNERJİ ORTAKLARI", "SYNERGY PARTNERS"))
                            .font(.setCustomFont(name: .InterBold, size: 10))
                            .foregroundStyle(ThemeColors.textMuted)
                        
                        HStack(spacing: 8) {
                            ForEach(perk.synergyPartnerIds, id: \.self) { partnerId in
                                if let partner = PerkEngine.perkPool.first(where: { $0.id == partnerId }) {
                                    HStack(spacing: 4) {
                                        Text(partner.icon)
                                        Text(partner.name)
                                            .font(.setCustomFont(name: .InterBold, size: 10))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(ThemeColors.neonPurple.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ThemeColors.neonPurple.opacity(0.3), lineWidth: 1))
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(20)
            .presentationCompactAdaptation(.popover)
            .background(ThemeColors.backgroundGradient)
        }
        .disabled(!isInteractable && perk.id != "sculptor" && !showDetails) 
        .simultaneousGesture(TapGesture().onEnded {
            if perk.id != "sculptor" {
                showDetails = true
            }
        })
    }
}
