//
//  CharacterShopView.swift
//  Block-Jack
//

import SwiftUI

struct CharacterShopView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedChar: GameCharacter = GameCharacter.roster.first!
    
    var body: some View {
        ZStack {
            ThemeColors.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header
                headerView
                
                // MARK: - Currency Display
                currencyDisplay
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // MARK: - Character Carousel
                        characterCarousel
                        
                        // MARK: - Character Details
                        characterDetailsCard
                        
                        // MARK: - Purchase Action
                        purchaseSection
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Button {
                HapticManager.shared.play(.buttonTap)
                dismiss()
            } label: {
                Image("ui_close")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .background(ThemeColors.surfaceDark)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(ThemeColors.gridStroke, lineWidth: 1))
            }
            
            Spacer()
            
            Text(userEnv.localizedString("KAHRAMANLAR", "HEROES"))
                .font(.setCustomFont(name: .InterBlack, size: 24))
                .foregroundStyle(ThemeColors.neonCyan)
                .tracking(2)
            
            Spacer()
            
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    private var currencyDisplay: some View {
        HStack(spacing: 20) {
            currencyBadge(icon: "icon_gold", value: userEnv.gold, color: ThemeColors.electricYellow)
            currencyBadge(icon: "icon_diamond", value: userEnv.diamonds, color: ThemeColors.neonCyan)
        }
        .padding(.bottom, 20)
    }
    
    private func currencyBadge(icon: String, value: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(icon)
                .resizable()
                .frame(width: 22, height: 22)
            Text("\(value)")
                .font(.setCustomFont(name: .InterExtraBold, size: 18))
                .foregroundStyle(color)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
    }
    
    private var characterCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(userEnv.localizedString("EKİBİNİ KUR", "RECRUIT YOUR TEAM"))
                .font(.setCustomFont(name: .InterBold, size: 14))
                .foregroundStyle(ThemeColors.textSecondary)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(GameCharacter.roster, id: \.id) { char in
                        let isUnlocked = userEnv.unlockedCharacterIDs.contains(char.id)
                        let isSelected = selectedChar.id == char.id
                        
                        Button {
                            HapticManager.shared.play(.selection)
                            withAnimation(.spring(response: 0.3)) {
                                selectedChar = char
                            }
                        } label: {
                            VStack(spacing: 6) {
                                ZStack(alignment: .bottomTrailing) {
                                    Image(char.icon)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .grayscale(isUnlocked ? 0 : 1)
                                        .opacity(isUnlocked ? 1.0 : 0.6)
                                    
                                    if !isUnlocked {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white)
                                            .padding(4)
                                            .background(Color.black.opacity(0.6))
                                            .clipShape(Circle())
                                            .offset(x: 4, y: 4)
                                    } else if userEnv.isCharacterMastered(char.id) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color(red: 0.15, green: 0.08, blue: 0.0))
                                            .padding(4)
                                            .background(
                                                LinearGradient(colors: [ThemeColors.electricYellow, .orange],
                                                               startPoint: .topLeading,
                                                               endPoint: .bottomTrailing)
                                            )
                                            .clipShape(Circle())
                                            .shadow(color: ThemeColors.electricYellow.opacity(0.8), radius: 4)
                                            .offset(x: 4, y: 4)
                                    }
                                }
                                
                                Text(char.name)
                                    .font(.setCustomFont(name: .InterBold, size: 10))
                                    .foregroundStyle(isSelected ? ThemeColors.neonCyan : .white)

                                CharacterMasteryBadge(characterId: char.id)
                            }
                            .padding(10)
                            .background(isSelected ? AnyShapeStyle(ThemeColors.neonCyan.opacity(0.1)) : AnyShapeStyle(.ultraThinMaterial))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isSelected ? ThemeColors.neonCyan : Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .characterMasteryFrame(characterId: char.id, cornerRadius: 16)
                            .scaleEffect(isSelected ? 1.05 : 1.0)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private var characterDetailsCard: some View {
        VStack(spacing: 20) {
            // Character Image & Info
            HStack(spacing: 20) {
                Image(selectedChar.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: ThemeColors.neonCyan.opacity(0.3), radius: 15)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(selectedChar.name)
                        .font(.setCustomFont(name: .InterBlack, size: 22))
                        .foregroundStyle(.white)
                    
                    Text(selectedChar.strongMode)
                        .font(.setCustomFont(name: .InterBold, size: 12))
                        .foregroundStyle(ThemeColors.neonCyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ThemeColors.neonCyan.opacity(0.15))
                        .clipShape(Capsule())
                    
                    Text(userEnv.localizedString(selectedChar.loreTR, selectedChar.loreEN))
                        .font(.setCustomFont(name: .InterMedium, size: 11))
                        .foregroundStyle(ThemeColors.textSecondary)
                        .lineLimit(3)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Stats Row
            HStack(spacing: 12) {
                detailBadge(title: "PASİF", desc: selectedChar.passiveDesc, icon: "bolt.shield.fill", color: ThemeColors.electricYellow)
                detailBadge(title: "AKTİF", desc: selectedChar.activeDesc, icon: "flame.fill", color: ThemeColors.neonPink)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func detailBadge(title: String, desc: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.setCustomFont(name: .InterBold, size: 10))
            }
            .foregroundStyle(color)
            
            Text(desc)
                .font(.setCustomFont(name: .InterMedium, size: 11))
                .foregroundStyle(.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding(14)
        .background(AnyShapeStyle(.ultraThinMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.2), lineWidth: 1))
    }
    
    private var purchaseSection: some View {
        let isUnlocked = userEnv.unlockedCharacterIDs.contains(selectedChar.id)
        
        // Seviye şartı kontrolü
        var isLevelMet = true
        var requiredLevel = 1
        if case .goldAndLevel(_, let level) = selectedChar.unlockCondition {
            requiredLevel = level
            isLevelMet = userEnv.unlockedWorldLevel >= level
        }
        
        return VStack(spacing: 16) {
            if isUnlocked {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(ThemeColors.success)
                    Text(userEnv.localizedString("BU KAHRAMAN EKİBİNDE!", "HERO RECRUITED!"))
                        .font(.setCustomFont(name: .InterExtraBold, size: 18))
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(ThemeColors.success.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(ThemeColors.success.opacity(0.3), lineWidth: 1))
            } else {
                if !isLevelMet {
                    // Level Yetmiyor Uyarısı
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(ThemeColors.neonPink)
                        Text(userEnv.localizedString("SEVİYE \(requiredLevel) GEREKLİ", "REACH LEVEL \(requiredLevel)"))
                            .font(.setCustomFont(name: .InterExtraBold, size: 16))
                            .foregroundStyle(.white)
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(ThemeColors.neonPink.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(ThemeColors.neonPink.opacity(0.3), lineWidth: 1))
                }
                
                HStack(spacing: 16) {
                    // Gold Purchase
                    buyButton(currencyName: "ALTIN", amount: selectedChar.cost, icon: "icon_gold", color: isLevelMet ? ThemeColors.electricYellow : ThemeColors.textMuted) {
                        if isLevelMet {
                            _ = userEnv.unlockCharacter(selectedChar, useDiamonds: false)
                        } else {
                            HapticManager.shared.play(.error)
                        }
                    }
                    .disabled(!isLevelMet)
                    .opacity(isLevelMet ? 1.0 : 0.5)
                    
                    // Diamond Purchase
                    buyButton(currencyName: "ELMAS", amount: selectedChar.cost / 10, icon: "icon_diamond", color: isLevelMet ? ThemeColors.neonCyan : ThemeColors.textMuted) {
                        if isLevelMet {
                            _ = userEnv.unlockCharacter(selectedChar, useDiamonds: true)
                        } else {
                            HapticManager.shared.play(.error)
                        }
                    }
                    .disabled(!isLevelMet)
                    .opacity(isLevelMet ? 1.0 : 0.5)
                }
                
                Text(userEnv.localizedString(selectedChar.unlockCondition.descriptionTR, selectedChar.unlockCondition.descriptionEN))
                    .font(.setCustomFont(name: .InterBold, size: 12))
                    .foregroundStyle(ThemeColors.textMuted)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
    }
    
    private func buyButton(currencyName: String, amount: Int, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(userEnv.localizedString("\(currencyName) İLE AÇ", "UNLOCK WITH \(currencyName)"))
                    .font(.setCustomFont(name: .InterBold, size: 10))
                    .foregroundStyle(ThemeColors.textSecondary)
                
                HStack(spacing: 6) {
                    Image(icon)
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("\(amount)")
                        .font(.setCustomFont(name: .InterBlack, size: 18))
                        .foregroundStyle(color)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AnyShapeStyle(.ultraThinMaterial))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.4), lineWidth: 1))
        }
    }
}

#Preview {
    CharacterShopView()
        .environmentObject(UserEnvironment.shared)
}
