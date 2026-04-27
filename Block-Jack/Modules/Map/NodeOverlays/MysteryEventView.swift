//
//  MysteryEventView.swift
//  Block-Jack
//

import SwiftUI

struct MysteryEventView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userEnv: UserEnvironment
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
            Image("cyber_mystery_rift")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            Color.black.opacity(0.62).ignoresSafeArea()

            RadialGradient(
                colors: [ThemeColors.neonPurple.opacity(0.32), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 600
            )
            .ignoresSafeArea()

            AdaptiveOverlay(
                header: {
                    OverlayTitleBlock(
                        "GİZEMLİ OLAY",
                        subtitle: nil,
                        color: ThemeColors.neonPurple
                    )
                },
                content: {
                    if !eventRevealed {
                        unknownEventSection
                    } else {
                        revealedEventSection
                    }
                },
                footer: { footerSection }
            )
        }
        .onAppear { pickRandomEvent() }
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
                    if let slot = SaveManager.shared.slots.first(where: { $0.id == id }) {
                        let unlockedIds = Set(slot.unlockedPerkIDs.isEmpty ? StartingPerk.defaultUnlockedIDs : slot.unlockedPerkIDs)
                        let activeIds = Set(slot.activePassivePerks.map { $0.id })
                        
                        let availablePerks = PerkEngine.perkPool.filter { perk in
                            unlockedIds.contains(perk.id) && 
                            (slot.activePassivePerks.first(where: { $0.id == perk.id })?.tier ?? 0) < 3
                        }
                        if let perk = availablePerks.randomElement() {
                            SaveManager.shared.addPassivePerk(slotId: id, perk: perk)
                        }
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
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .stroke(ThemeColors.neonPurple, lineWidth: 2)
                    .frame(width: 130, height: 130)
                    .blur(radius: 5)

                Image(systemName: "questionmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 86, height: 86)
                    .foregroundColor(ThemeColors.neonPurple)
                    .shadow(color: ThemeColors.neonPurple, radius: 20)
            }
            .phaseAnimator([0, 10, 0]) { content, offset in
                content.offset(y: offset)
            } animation: { _ in
                .easeInOut(duration: 2).repeatForever(autoreverses: true)
            }

            Text(userEnv.localizedString(
                "Önünde karanlık bir enerji süzülüyor...\nDokunmaya cesaretin var mı?",
                "A dark energy swirls before you...\nDare to touch it?"
            ))
                .font(.subheadline.weight(.medium))
                .foregroundColor(ThemeColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)

            Button(action: {
                if let event = currentEvent {
                    event.action(slotId)
                    withAnimation(.spring()) { eventRevealed = true }
                    HapticManager.shared.play(.success)
                }
            }) {
                Text(userEnv.localizedString("DOKUN VE GÖR", "TOUCH AND SEE"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(ThemeColors.neonPurple.opacity(0.3))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(ThemeColors.neonPurple, lineWidth: 2))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    private var revealedEventSection: some View {
        VStack(spacing: 18) {
            Image(systemName: "sparkles")
                .font(.system(size: 52))
                .foregroundColor(ThemeColors.neonPurple)
                .shadow(color: ThemeColors.neonPurple.opacity(0.7), radius: 10)

            Text(currentEvent?.title ?? "OLAY")
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(currentEvent?.outcomeDesc ?? "")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(ThemeColors.neonPurple)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ThemeColors.neonPurple.opacity(0.35), lineWidth: 1)
                )
        }
        .padding(.horizontal, 20)
        .transition(.scale.combined(with: .opacity))
    }

    private var footerSection: some View {
        Button(action: {
            NotificationCenter.default.post(name: NSNotification.Name("mapOverlayDidDismiss"), object: nil)
            dismiss()
        }) {
            Text(eventRevealed ? "KABUL ET VE DEVAM ET" : "UZAKLAŞ")
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
