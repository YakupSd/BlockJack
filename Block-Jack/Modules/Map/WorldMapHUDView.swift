//
//  WorldMapHUDView.swift
//  Block-Jack
//

import SwiftUI
import Combine

// MARK: - Üst HUD (sol: karakter, sağ: bölüm + altın)
struct WorldMapHUDView: View {
    @ObservedObject var vm: WorldMapViewModel
    @EnvironmentObject var userEnv: UserEnvironment
    let onBack: () -> Void

    private var character: GameCharacter {
        GameCharacter.roster.first(where: { $0.id == userEnv.selectedCharacterID })
            ?? GameCharacter.roster[0]
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                // Back Button
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                // Character Badge
                HStack(spacing: 10) {
                    ZStack {
                        // FIXED: Using actual character image instead of pixel avatar
                        Image(character.icon)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(ThemeColors.neonCyan.opacity(0.5), lineWidth: 1.5)
                            .frame(width: 36, height: 36)
                    }
                    .shadow(color: ThemeColors.neonCyan.opacity(0.3), radius: 5)

                    VStack(alignment: .leading, spacing: -2) {
                        // FIXED: Text scaling and wrapping
                        Text(character.name.uppercased())
                            .font(.setCustomFont(name: .InterBlack, size: 13))
                            .foregroundColor(.white)
                            .tracking(0.5)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text(difficultyLabel)
                            .font(.setCustomFont(name: .InterBold, size: 8))
                            .foregroundColor(ThemeColors.neonPurple)
                            .tracking(1)
                    }
                }
                
                // Manual Focus Button
                Button(action: { 
                    HapticManager.shared.play(.selection)
                    vm.objectWillChange.send() 
                }) {
                    Image(systemName: "scope")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(ThemeColors.neonCyan)
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Resources
                HStack(spacing: 8) {
                    // Gold
                    HStack(spacing: 4) {
                        Image("icon_gold")
                            .resizable()
                            .frame(width: 10, height: 10)
                        Text("\(userEnv.gold)")
                            .font(.setCustomFont(name: .InterBold, size: 12))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(ThemeColors.electricYellow.opacity(0.3), lineWidth: 1))
                    
                    // Progress Info
                    VStack(alignment: .trailing, spacing: -1) {
                        Text(userEnv.labelChapterCaps)
                            .font(.setCustomFont(name: .InterBold, size: 7))
                            .foregroundColor(.white.opacity(0.4))
                        Text("\(min(userEnv.unlockedWorldLevel, vm.totalChapters))/\(vm.totalChapters)")
                            .font(.setCustomFont(name: .InterBlack, size: 14))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 48) // Further reduced
            .padding(.bottom, 10) // Further reduced
            .background(
                ThemeColors.mapBg.opacity(0.85)
                    .overlay(VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark))
                    .ignoresSafeArea(edges: .top)
            )
            
            // Bottom edge glow line
            LinearGradient(colors: [ThemeColors.neonCyan.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 1)
        }
    }

    private var difficultyLabel: String {
        switch character.difficulty {
        case .beginner: return userEnv.labelRookiePilotCaps
        case .advanced: return userEnv.labelAdeptPilotCaps
        case .expert:   return userEnv.labelElitePilotCaps
        }
    }
}

// MARK: - Alt Bar (ilerleme + son kilidi açılan)
struct WorldMapBottomBarView: View {
    @ObservedObject var vm: WorldMapViewModel
    @EnvironmentObject var userEnv: UserEnvironment

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(userEnv.labelCampaignProgressCaps)
                        .font(.setCustomFont(name: .InterBold, size: 10))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)
                    
                    WorldMapProgressBar(value: vm.chapterProgress, color: ThemeColors.neonCyan)
                        .frame(height: 6)
                }
                
                Spacer(minLength: 40)
                
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(vm.completedCount)")
                        .font(.setCustomFont(name: .InterBlack, size: 20))
                        .foregroundColor(.white)
                    Text(userEnv.labelDoneCaps)
                        .font(.setCustomFont(name: .InterBold, size: 9))
                        .foregroundColor(ThemeColors.neonCyan)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                ThemeColors.mapBg.opacity(0.8)
                    .overlay(VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark))
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Progress bar
struct WorldMapProgressBar: View {
    let value: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.1))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(min(max(value, 0), 1)))
                    .shadow(color: color.opacity(0.5), radius: 4)
            }
        }
    }
}
