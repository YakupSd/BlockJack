//
//  RestView.swift
//  Block-Jack
//

import SwiftUI

struct RestSiteView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userEnv: UserEnvironment
    
    let slotId: Int
    @State private var hasActed = false
    @State private var showMessage = false
    @State private var message = ""
    
    // Check if player has Safe House perk
    var hasSafeHouse: Bool {
        guard let slot = SaveManager.shared.slots.first(where: { $0.id == slotId }) else { return false }
        return slot.activePassivePerks.contains { $0.id == "safe_house" }
    }
    
    var body: some View {
        ZStack {
            // Background Image
            Image("cyber_rest_station")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            Color.black.opacity(0.7).ignoresSafeArea()
            
            // Neon Glow
            RadialGradient(
                colors: [ThemeColors.neonCyan.opacity(0.2), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 600
            ).ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Text("GÜVENLİ BÖLGE")
                        .font(.custom("Outfit-Bold", size: 36, relativeTo: .largeTitle))
                        .foregroundColor(ThemeColors.neonCyan)
                        .shadow(color: ThemeColors.neonCyan, radius: 10)
                    
                    Text("Sistemlerini optimize et ve dinlen.")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 40)
                
                Spacer()
                
                if showMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(ThemeColors.success)
                        
                        Text(message)
                            .font(.title3)
                            .bold()
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(ThemeColors.success.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    actionButtons
                }
                
                Spacer()
                
                // Footer
                Button(action: {
                    dismiss()
                }) {
                    Text(hasActed ? "AYRIL" : "ŞİMDİLİK DEĞİL")
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
        .onAppear {
            checkSafeHouseBonus()
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 20) {
            // 1. Repair Systems (Heal)
            restButton(
                title: "SİSTEM ONARIMI",
                icon: "heart.fill",
                desc: "+1 Yaşam Puanı kazan.",
                color: ThemeColors.neonPink
            ) {
                SaveManager.shared.updateLives(slotId: slotId, amount: 1)
                completeAction("Sistemler onarıldı. +1 Can eklendi.")
            }
            
            // 2. Scavenge (Gold)
            restButton(
                title: "VERİ MADENCİLİĞİ",
                icon: "cpu.fill",
                desc: "Hızlıca veri topla ve 50 Altın kazan.",
                color: ThemeColors.electricYellow
            ) {
                SaveManager.shared.updateGold(slotId: slotId, amount: 50)
                completeAction("Veriler toplandı. +50 Altın kazanıldı.")
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func restButton(title: String, icon: String, desc: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                    .frame(width: 60, height: 60)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("Outfit-Bold", size: 18))
                        .foregroundColor(.white)
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
        }
    }
    
    private func checkSafeHouseBonus() {
        if hasSafeHouse {
            let bonusGold = 100 // Safe House Perk gives 100 gold in rest areas
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                HapticManager.shared.play(.success)
                SaveManager.shared.updateGold(slotId: slotId, amount: bonusGold)
                // We could show a specific toast or just add it.
            }
        }
    }
    
    private func completeAction(_ msg: String) {
        HapticManager.shared.play(.success)
        withAnimation(.spring()) {
            message = msg
            hasActed = true
            showMessage = true
        }
    }
}
