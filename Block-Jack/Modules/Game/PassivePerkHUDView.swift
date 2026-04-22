//
//  PassivePerkHUDView.swift
//  Block-Jack
//

import SwiftUI

struct PassivePerkHUDView: View {
    @ObservedObject var vm: GameViewModel
    @EnvironmentObject var userEnv: UserEnvironment
    
    var body: some View {
        HStack(spacing: 8) {
            // Sol etiket
            Text(userEnv.localizedString("PERKLER", "PERKS"))
                .font(.setCustomFont(name: .InterBlack, size: 9))
                .foregroundStyle(ThemeColors.textMuted)
                .tracking(1.3)
            
            // Dikey ayırıcı
            RoundedRectangle(cornerRadius: 1)
                .fill(ThemeColors.cardBorder)
                .frame(width: 1, height: 16)
            
            // Perk listesi
            if vm.run.activePassivePerks.isEmpty {
                Text(userEnv.localizedString("Aktif perk yok", "No active perk"))
                    .font(.setCustomFont(name: .InterMedium, size: 9))
                    .foregroundColor(ThemeColors.textMuted)
                    .lineLimit(1)
                Spacer(minLength: 0)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(vm.run.activePassivePerks) { perk in
                            PerkHUDIcon(
                                perk: perk,
                                isInteractable: perk.id == "sculptor",
                                vm: vm
                            )
                        }
                    }
                    .padding(.trailing, 4)
                }
            }
        }
        .padding(.horizontal, GameLayout.horizontalPadding)
        .frame(height: GameLayout.perkStripHeight)
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
                // Synergy Glow (Breathing)
                if hasSynergy {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(ThemeColors.neonPurple, lineWidth: 1.5)
                        .blur(radius: 3)
                        .scaleEffect(1.1)
                        .frame(width: 34, height: 34)
                        .phaseAnimator([0.4, 1.0]) { content, opacity in
                            content.opacity(opacity)
                        } animation: { _ in
                            .easeInOut(duration: 1.5).repeatForever()
                        }
                }

                if isInteractable && vm.selectedBlock != nil {
                    Circle()
                        .fill(ThemeColors.neonCyan.opacity(0.2))
                        .blur(radius: 4)
                        .scaleEffect(isAnimating ? 1.5 : 1.0)
                        .frame(width: 34, height: 34)
                }
                
                ZStack {
                    // TECH CHIP BACKGROUND (UI Revize: daha kompakt 32pt)
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ThemeColors.perkBg)
                        .frame(width: 32, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    isInteractable && vm.selectedBlock != nil ? ThemeColors.neonCyan : ThemeColors.cardBorder,
                                    lineWidth: 1
                                )
                        )
                    
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isInteractable && vm.selectedBlock != nil ? ThemeColors.neonCyan : ThemeColors.textMuted.opacity(0.2),
                            style: StrokeStyle(lineWidth: 1, dash: [2, 8])
                        )
                        .frame(width: 32, height: 32)

                    if perk.icon.hasPrefix("item_") || perk.icon.hasPrefix("port_") {
                        Image(perk.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                    } else {
                        Text(perk.icon)
                            .font(.system(size: 16))
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                    }
                }
            }
        }
        .disabled(!isInteractable)
        .overlay(
            ZStack(alignment: .topTrailing) {
                if perk.tier > 1 {
                    Text("L\(perk.tier)")
                        .font(.system(size: 7, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(ThemeColors.electricYellow)
                        .cornerRadius(3)
                        .offset(x: 6, y: -6)
                }
                
                if hasSynergy {
                    Image(systemName: "bolt.horizontal.circle.fill")
                        .font(.system(size: 9))
                        .foregroundColor(ThemeColors.neonPurple)
                        .background(Color.black.clipShape(Circle()))
                        .offset(x: -10, y: -10)
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
