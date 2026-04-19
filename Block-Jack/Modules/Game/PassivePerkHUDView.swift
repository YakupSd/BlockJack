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
                if hasSynergy {
                    Circle()
                        .stroke(ThemeColors.neonPurple, lineWidth: 2)
                        .blur(radius: 4)
                        .scaleEffect(1.2)
                        .phaseAnimator([1.0, 1.2]) { content, scale in
                            content.scaleEffect(scale).opacity(1.5 - scale)
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
                
                Circle()
                    .fill(ThemeColors.surfaceMid)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(
                                isInteractable && vm.selectedBlock != nil ? ThemeColors.neonCyan : ThemeColors.gridStroke.opacity(0.5),
                                lineWidth: 1.5
                            )
                    )
                
                if perk.icon.hasPrefix("item_") || perk.icon.hasPrefix("port_") {
                    Image(perk.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                } else {
                    Text(perk.icon)
                        .font(.system(size: 20))
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
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
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle().fill(ThemeColors.surfaceMid).frame(width: 44, height: 44)
                        Text(perk.icon).font(.title3)
                    }
                    VStack(alignment: .leading) {
                        Text(perk.name).font(.headline).foregroundStyle(.white)
                        Text("Tier \(perk.tier)").font(.caption).foregroundStyle(ThemeColors.electricYellow)
                    }
                    Spacer()
                }
                
                Text(perk.desc)
                    .font(.subheadline)
                    .foregroundStyle(ThemeColors.textSecondary)
                
                if !perk.synergyPartnerIds.isEmpty {
                    Divider().background(ThemeColors.gridStroke)
                    Text("Sinerji Ortakları:").font(.caption).bold()
                    HStack {
                        ForEach(perk.synergyPartnerIds, id: \.self) { partnerId in
                            if let partner = PerkEngine.perkPool.first(where: { $0.id == partnerId }) {
                                Text("\(partner.icon) \(partner.name)")
                                    .font(.caption2)
                                    .padding(6)
                                    .background(ThemeColors.neonPurple.opacity(0.2))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }
            .padding()
            .presentationCompactAdaptation(.popover)
            .background(ThemeColors.cosmicBlack)
        }
        .disabled(!isInteractable && perk.id != "sculptor" && !showDetails) 
        .simultaneousGesture(TapGesture().onEnded {
            if perk.id != "sculptor" {
                showDetails = true
            }
        })
    }
}
