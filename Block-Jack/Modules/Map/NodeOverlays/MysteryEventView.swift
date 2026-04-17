//
//  MysteryEventView.swift
//  Block-Jack
//

import SwiftUI

struct MysteryEventView: View {
    @Environment(\.dismiss) var dismiss
    @State private var eventRevealed = false
    @State private var currentEvent: MysteryEvent?
    
    let slotId: Int
    
    struct MysteryEvent: Identifiable {
        let id = UUID()
        let title: String
        let desc: String
        let outcomeDesc: String
        let action: (Int) -> Void
    }
    
    var body: some View {
        ZStack {
            // Background with premium AI image
            Image("cyber_mystery_rift")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            Color.black.opacity(0.6).ignoresSafeArea() // Görünürlük için karartma
            
            // Purple Glow
            RadialGradient(
                colors: [ThemeColors.neonPurple.opacity(0.3), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 600
            ).ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("GİZEMLİ OLAY")
                    .font(.custom("Outfit-Bold", size: 32, relativeTo: .largeTitle))
                    .foregroundColor(ThemeColors.neonPurple)
                
                Spacer()
                
                if !eventRevealed {
                    unknownEventSection
                } else {
                    revealedEventSection
                }
                
                Spacer()
                
                footerSection
            }
            .padding(.top, 40)
        }
        .onAppear {
            pickRandomEvent()
        }
    }
    
    private func pickRandomEvent() {
        let events = [
            MysteryEvent(
                title: "AÇGÖZLÜLÜK",
                desc: "Karanlık bir sunak üzerinde parlayan altınlar var. Ama bedeli ağır olabilir.",
                outcomeDesc: "1 Can kaybettin ama 150 Altın kazandın!",
                action: { id in
                    SaveManager.shared.updateLives(slotId: id, amount: -1)
                    SaveManager.shared.updateGold(slotId: id, amount: 150)
                }
            ),
            MysteryEvent(
                title: "ŞANSLI BULUŞ",
                desc: "Yerde tozlu bir kutu buldun. İçinden bir şeyler fısıldıyor.",
                outcomeDesc: "Rastgele bir Pasif Perk kazandın!",
                action: { id in
                    if let perk = PerkEngine.perkPool.randomElement() {
                        SaveManager.shared.addPassivePerk(slotId: id, perk: perk)
                    }
                }
            ),
            MysteryEvent(
                title: "KAN ANLAŞMASI",
                desc: "Gizemli bir silüet sana güç teklif ediyor, ama ruhundan bir parça istiyor.",
                outcomeDesc: "1 Can kaybettin ama mevcut bir perkin rastgele gelişti!",
                action: { id in
                    SaveManager.shared.updateLives(slotId: id, amount: -1)
                    if let slot = SaveManager.shared.slots.first(where: { $0.id == id }),
                       let randomPerk = slot.activePassivePerks.randomElement() {
                        SaveManager.shared.upgradePassivePerk(slotId: id, perkId: randomPerk.id)
                    }
                }
            )
        ]
        currentEvent = events.randomElement()
    }
    
    private var unknownEventSection: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .stroke(ThemeColors.neonPurple, lineWidth: 2)
                    .frame(width: 150, height: 150)
                    .blur(radius: 5)
                
                Image(systemName: "questionmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(ThemeColors.neonPurple)
                    .shadow(color: ThemeColors.neonPurple, radius: 20)
            }
            .phaseAnimator([0, 10, 0]) { content, offset in
                content.offset(y: offset)
            } animation: { _ in
                .easeInOut(duration: 2).repeatForever(autoreverses: true)
            }
            
            Text("Önünde karanlık bir enerji süzülüyor...\nDokunmaya cesaretin var mı?")
                .font(.headline)
                .foregroundColor(ThemeColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                if let event = currentEvent {
                    event.action(slotId)
                    withAnimation(.spring()) {
                        eventRevealed = true
                    }
                    HapticManager.shared.play(.success)
                }
            }) {
                Text("DOKUN VE GÖR")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(ThemeColors.neonPurple.opacity(0.3))
                    .cornerRadius(25)
                    .overlay(Capsule().stroke(ThemeColors.neonPurple, lineWidth: 2))
            }
        }
    }
    
    private var revealedEventSection: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(ThemeColors.neonPurple)
            
            Text(currentEvent?.title ?? "OLAY")
                .font(.title)
                .bold()
                .foregroundColor(.white)
            
            Text(currentEvent?.outcomeDesc ?? "")
                .font(.headline)
                .foregroundColor(ThemeColors.neonPurple)
                .multilineTextAlignment(.center)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ThemeColors.neonPurple.opacity(0.3), lineWidth: 1))
        }
        .padding()
        .transition(.scale.combined(with: .opacity))
    }
    
    private var footerSection: some View {
        Button(action: {
            dismiss()
        }) {
            Text(eventRevealed ? "KABUL ET VE DEVAM ET" : "UZAKLAŞ")
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
