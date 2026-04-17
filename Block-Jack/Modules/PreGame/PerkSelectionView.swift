//
//  PerkSelectionView.swift
//  Block-Jack
//

import SwiftUI

struct PerkSelectionView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    
    let slotId: Int
    let characterId: String
    
    @State private var selectedPerkId: String = "none"
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ThemeColors.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        HapticManager.shared.play(.buttonTap)
                        MainViewsRouter.shared.nav?.popViewController(animated: true)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(ThemeColors.textSecondary)
                            .frame(width: 44, height: 44)
                            .background(ThemeColors.surfaceDark)
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text(userEnv.localizedString("ÖZEL GÜÇ", "STARTING PERK"))
                        .font(.setCustomFont(name: .InterBlack, size: 20))
                        .foregroundStyle(ThemeColors.electricYellow)
                        .tracking(2)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Perk List
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(StartingPerk.available) { perk in
                            perkRow(perk)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120) // spacing for start button
                }
            }
            
            // START RUN BUTTON
            VStack {
                Spacer()
                Button {
                    HapticManager.shared.play(.heavy) // heavy for start
                    
                    // Veriyi kaydet ve başla
                    SaveManager.shared.createNewSave(
                        in: slotId,
                        characterId: characterId,
                        perkId: selectedPerkId
                    )
                    
                    // Direkt MapView'a geç
                    MainViewsRouter.shared.pushToMap(slotId: slotId)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 20, weight: .black))
                        Text(userEnv.localizedString("OYUNA BAŞLA", "START RUN"))
                            .font(.setCustomFont(name: .InterExtraBold, size: 22))
                            .tracking(2)
                    }
                    .foregroundStyle(ThemeColors.cosmicBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(ThemeColors.electricYellow)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: ThemeColors.electricYellow, radius: 12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func perkRow(_ perk: StartingPerk) -> some View {
        let isSelected = selectedPerkId == perk.id
        
        Button {
            HapticManager.shared.play(.selection)
            selectedPerkId = perk.id
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    if perk.icon.contains("item_") {
                        Image(perk.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Text(perk.icon)
                            .font(.system(size: 32))
                    }
                }
                .frame(width: 60, height: 60)
                .background(ThemeColors.gridDark)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(perk.name)
                        .font(.setCustomFont(name: .InterBold, size: 16))
                        .foregroundStyle(isSelected ? ThemeColors.electricYellow : .white)
                    
                    Text(perk.desc)
                        .font(.setCustomFont(name: .InterMedium, size: 12))
                        .foregroundStyle(ThemeColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(ThemeColors.electricYellow)
                } else {
                    Circle()
                        .stroke(ThemeColors.gridStroke, lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? ThemeColors.electricYellow : ThemeColors.gridStroke.opacity(0.5), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? ThemeColors.electricYellow.opacity(0.15) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PerkSelectionView(slotId: 1, characterId: "block_e")
        .environmentObject(UserEnvironment.shared)
}
