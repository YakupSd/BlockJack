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
    
    var body: some View {
        Button(action: {
            if perk.id == "sculptor" {
                vm.rotateSelectedBlock()
                withAnimation(.spring()) { isAnimating = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { isAnimating = false }
            }
        }) {
            ZStack {
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
                
                if perk.id == "sculptor" {
                    // Kullanım hakkı göstergesi (Tier'a bağlı)
                    let maxUses = perk.tier * 2
                    Text("\(maxUses - vm.run.sculptorUses)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(3)
                        .background(ThemeColors.neonPink)
                        .clipShape(Circle())
                        .offset(x: 14, y: 14) // Alt köşeye alalım level ile çakışmasın
                }
            }
        )
    }
}
