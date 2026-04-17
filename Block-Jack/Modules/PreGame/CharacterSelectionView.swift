//
//  CharacterSelectionView.swift
//  Block-Jack
//

import SwiftUI

struct CharacterSelectionView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    
    let slotId: Int
    @State private var selectedCharId: String = "block_e"
    
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
                    Text(userEnv.localizedString("KARAKTER", "CHARACTER"))
                        .font(.setCustomFont(name: .InterBlack, size: 20))
                        .foregroundStyle(ThemeColors.neonCyan)
                        .tracking(2)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Character List
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(GameCharacter.roster) { char in
                            characterCard(char)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                
                // Character Details
                if let char = GameCharacter.roster.first(where: { $0.id == selectedCharId }) {
                    ScrollView(.vertical, showsIndicators: false) {
                        characterDetails(char)
                    }
                } else {
                    Spacer()
                }
            }
            
            // Continue Button (Only if uncovered/selected)
            if let char = GameCharacter.roster.first(where: { $0.id == selectedCharId }) {
                let isUnlocked = !char.isPremium || userEnv.unlockedCharacterIDs.contains(char.id)
                Button {
                    HapticManager.shared.play(.buttonTap)
                    if isUnlocked {
                        MainViewsRouter.shared.pushToPerkSelection(slotId: slotId, characterId: char.id)
                    } else {
                        // Attempt buy
                        if userEnv.spend(gold: char.cost) { // Note: GDD says diamond, adjust later if needed. Use diamond or gold.
                            userEnv.unlockedCharacterIDs.append(char.id)
                            HapticManager.shared.play(.success)
                        } else {
                            HapticManager.shared.play(.error)
                        }
                    }
                } label: {
                    Text(isUnlocked ? userEnv.localizedString("SEÇ VE DEVAM ET", "SELECT & CONTINUE") : "\(char.cost) 💎 UNLOCK")
                        .font(.setCustomFont(name: .InterExtraBold, size: 18))
                        .foregroundStyle(ThemeColors.cosmicBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(isUnlocked ? ThemeColors.neonCyan : ThemeColors.electricYellow)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: isUnlocked ? ThemeColors.neonCyan : ThemeColors.electricYellow, radius: 10)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func characterCard(_ char: GameCharacter) -> some View {
        let isSelected = selectedCharId == char.id
        let isUnlocked = !char.isPremium || userEnv.unlockedCharacterIDs.contains(char.id)
        
        Button {
            HapticManager.shared.play(.selection)
            selectedCharId = char.id
        } label: {
            VStack(spacing: 12) {
                Image(char.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .grayscale(isUnlocked ? 0 : 1)
                    .opacity(isUnlocked ? 1.0 : 0.4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? ThemeColors.neonCyan.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                Text(char.name)
                    .font(.setCustomFont(name: .InterBold, size: 14))
                    .foregroundStyle(isSelected ? ThemeColors.neonCyan : ThemeColors.textSecondary)
                
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeColors.textMuted)
                }
            }
            .frame(width: 140, height: 180)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? ThemeColors.neonCyan : ThemeColors.gridStroke.opacity(0.5), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? ThemeColors.neonCyan.opacity(0.3) : .clear, radius: 15)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func characterDetails(_ char: GameCharacter) -> some View {
        let isUnlocked = !char.isPremium || userEnv.unlockedCharacterIDs.contains(char.id)
        
        VStack(spacing: 16) {
            // Phase 7: Lore
            Text(userEnv.localizedString(char.loreTR, char.loreEN))
                .font(.setCustomFont(name: .InterMedium, size: 13))
                .foregroundStyle(ThemeColors.textSecondary)
                .multilineTextAlignment(.center)
                .italic()
                .padding(.horizontal, 16)
                
            // Phase 7: Stats
            HStack(spacing: 12) {
                statBadge(title: "ZORLUK", value: char.difficulty.rawValue, color: difficultyColor(char.difficulty))
                statBadge(title: "GÜÇLÜ YÖN", value: char.strongMode, color: ThemeColors.neonCyan)
                statBadge(title: "FAVORİ BLOK", value: char.favoriteBlockType.rawValue, color: ThemeColors.electricYellow)
            }
            .padding(.bottom, 8)
            
            // Passive
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "bolt.shield.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(ThemeColors.electricYellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("PASİF YETENEK")
                        .font(.setCustomFont(name: .InterBold, size: 12))
                        .foregroundStyle(ThemeColors.textMuted)
                    Text(char.passiveDesc)
                        .font(.setCustomFont(name: .InterMedium, size: 14))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(ThemeColors.electricYellow.opacity(0.2), lineWidth: 1))
            
            // Active
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(ThemeColors.neonPink)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AKTİF YETENEK (OVERDRIVE)")
                        .font(.setCustomFont(name: .InterBold, size: 12))
                        .foregroundStyle(ThemeColors.textMuted)
                    Text(char.activeDesc)
                        .font(.setCustomFont(name: .InterMedium, size: 14))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(ThemeColors.neonPink.opacity(0.2), lineWidth: 1))
            
            // Phase 7: Locked Condition
            if !isUnlocked {
                HStack(spacing: 8) {
                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 16))
                    Text(userEnv.localizedString(char.unlockCondition.descriptionTR, char.unlockCondition.descriptionEN))
                }
                .font(.setCustomFont(name: .InterBold, size: 14))
                .foregroundStyle(ThemeColors.neonOrange)
                .padding(.top, 12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .id(char.id) // Forces transition
    }
    
    @ViewBuilder
    private func statBadge(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(userEnv.localizedString(title, title))
                .font(.setCustomFont(name: .InterBold, size: 9))
                .foregroundStyle(ThemeColors.textMuted)
            Text(value)
                .font(.setCustomFont(name: .InterBlack, size: 11))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
    }
    
    private func difficultyColor(_ difficulty: CharacterDifficulty) -> Color {
        switch difficulty {
        case .beginner: return ThemeColors.success
        case .advanced: return ThemeColors.electricYellow
        case .expert: return ThemeColors.neonPink
        }
    }
}

#Preview {
    CharacterSelectionView(slotId: 1)
        .environmentObject(UserEnvironment.shared)
}
