//
//  WorldMapHUDView.swift
//  Block-Jack
//
//  Dünya 1 (Neon Cyberpunk) için üst/alt HUD çubukları.
//  Karakter avatarı piksel stilinde kalıyor (karakterler zaten piksel art
//  tasarımında), onun dışında tipografi ve border'lar neon cyber dilinde:
//  cyan/magenta glow, ince monospace, koyu cam panel.
//
//  Veriler UserEnvironment/GameCharacter üzerinden — ViewModel mantığı değişmez.
//

import SwiftUI

/// Neon cyber HUD tipografi helper'ı. Press Start 2P kullanmak yerine
/// modern monospaced ince font + ekstra tracking → sci-fi terminali hissi.
private enum HUDFont {
    static func mono(_ size: CGFloat, weight: Font.Weight = .black) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

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
        HStack(alignment: .top, spacing: 10) {
            backButton
            characterBadge
            Spacer(minLength: 6)
            rightStack
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(
            LinearGradient(
                colors: [Color(hex: "#050718").opacity(0.92),
                         Color(hex: "#050718").opacity(0.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: Back button
    private var backButton: some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(ThemeColors.neonCyan)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "#080C1E").opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(ThemeColors.neonCyan.opacity(0.55), lineWidth: 1)
                        )
                )
                .shadow(color: ThemeColors.neonCyan.opacity(0.4), radius: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: Karakter rozeti
    private var characterBadge: some View {
        HStack(spacing: 8) {
            WorldMapPixelAvatar(character: character)
                .frame(width: 32, height: 32)
                .background(Color(hex: "#0A0D20"))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(ThemeColors.neonCyan, lineWidth: 1.5)
                )
                .shadow(color: ThemeColors.neonCyan.opacity(0.6), radius: 5)

            VStack(alignment: .leading, spacing: 3) {
                Text(character.name)
                    .font(HUDFont.mono(10, weight: .black))
                    .foregroundColor(ThemeColors.neonCyan)
                    .tracking(0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(difficultyLabel)
                    .font(HUDFont.mono(7, weight: .semibold))
                    .foregroundColor(ThemeColors.neonPurple)
                    .tracking(1.2)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(Color(hex: "#080C1E").opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(ThemeColors.neonCyan.opacity(0.3), lineWidth: 1)
        )
    }

    private var difficultyLabel: String {
        // Sadece karakter zorluğu — bölüm bilgisi sağdaki BÖLÜM pill'inde var.
        // Eski "LV X · ACEMİ" formatı karakter leveli ile karışıyordu.
        switch character.difficulty {
        case .beginner: return userEnv.localizedString("ACEMİ PİLOT", "ROOKIE PILOT")
        case .advanced: return userEnv.localizedString("USTA PİLOT", "ADEPT PILOT")
        case .expert:   return userEnv.localizedString("UZMAN PİLOT", "ELITE PILOT")
        }
    }

    // MARK: Sağ blok (bölüm + altın)
    private var rightStack: some View {
        VStack(spacing: 4) {
            chapterPill
            goldPill
        }
    }

    private var chapterPill: some View {
        HStack(spacing: 5) {
            Text(userEnv.localizedString("BÖLÜM", "CHAPTER"))
                .font(HUDFont.mono(7, weight: .semibold))
                .foregroundColor(ThemeColors.neonPurple)
                .tracking(1.2)
            Text("\(min(userEnv.unlockedWorldLevel, vm.totalChapters))/\(vm.totalChapters)")
                .font(HUDFont.mono(10, weight: .black))
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color(hex: "#0B0C22").opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(ThemeColors.neonPurple.opacity(0.5), lineWidth: 1)
        )
    }

    private var goldPill: some View {
        HStack(spacing: 5) {
            Image("icon_gold")
                .resizable()
                .frame(width: 11, height: 11)
            Text("\(userEnv.gold)")
                .font(HUDFont.mono(10, weight: .black))
                .foregroundColor(ThemeColors.electricYellow)
                .monospacedDigit()
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color(hex: "#170F00").opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(ThemeColors.electricYellow.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Alt Bar (ilerleme + son kilidi açılan)
struct WorldMapBottomBarView: View {
    @ObservedObject var vm: WorldMapViewModel
    @EnvironmentObject var userEnv: UserEnvironment

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(userEnv.localizedString("SEFER İLERLEME", "CAMPAIGN PROGRESS"))
                    .font(HUDFont.mono(7, weight: .semibold))
                    .foregroundColor(ThemeColors.neonPurple)
                    .tracking(1.3)
                WorldMapProgressBar(value: vm.chapterProgress,
                                    color: ThemeColors.neonCyan)
                    .frame(height: 8)
            }

            VStack(spacing: 1) {
                Text("\(vm.completedCount)")
                    .font(HUDFont.mono(14, weight: .black))
                    .foregroundColor(.white)
                    .monospacedDigit()
                Text(userEnv.localizedString("TAMAM", "DONE"))
                    .font(HUDFont.mono(7, weight: .semibold))
                    .foregroundColor(ThemeColors.neonCyan)
                    .tracking(1.5)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(hex: "#0B0C22").opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(ThemeColors.neonCyan.opacity(0.45), lineWidth: 1)
            )
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(
            Color(hex: "#05060F").opacity(0.95)
                .overlay(
                    // Üst ince neon çizgi — görünümü bottom bar'dan ayırıyor
                    LinearGradient(
                        colors: [.clear,
                                 ThemeColors.neonCyan.opacity(0.5),
                                 ThemeColors.neonPurple.opacity(0.5),
                                 .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(height: 1),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Progress bar
struct WorldMapProgressBar: View {
    let value: Double   // 0...1
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "#070918"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(color.opacity(0.35), lineWidth: 1)
                    )
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.75), ThemeColors.neonPurple.opacity(0.8)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(min(max(value, 0), 1)))
                    .shadow(color: color.opacity(0.6), radius: 3)
            }
        }
    }
}

// MARK: - Piksel Karakter Avatar
/// Basit 8x8 retro karakter portresi. Karakter ID'sine göre ufak varyasyonlar.
struct WorldMapPixelAvatar: View {
    let character: GameCharacter

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let cell = min(size.width, size.height) / 8.0
                let p = pattern
                for (r, row) in p.enumerated() {
                    for (c, v) in row.enumerated() where v != 0 {
                        let rect = CGRect(x: CGFloat(c) * cell,
                                          y: CGFloat(r) * cell,
                                          width: cell, height: cell)
                        ctx.fill(Path(rect), with: .color(color(for: v)))
                    }
                }
            }
        }
    }

    // Değer: 1 = saç, 2 = ten, 3 = göz, 4 = vücut, 0 = boş
    private var pattern: [[Int]] {
        [
            [0,0,1,1,1,1,0,0],
            [0,1,1,1,1,1,1,0],
            [0,1,2,2,2,2,1,0],
            [0,1,2,3,3,2,1,0],
            [0,1,2,2,2,2,1,0],
            [0,0,2,2,2,2,0,0],
            [0,4,4,4,4,4,4,0],
            [0,4,4,0,0,4,4,0],
        ]
    }

    private var accent: Color {
        switch character.difficulty {
        case .beginner: return ThemeColors.pixelHair
        case .advanced: return ThemeColors.neonPurple
        case .expert:   return ThemeColors.neonPink
        }
    }

    private func color(for v: Int) -> Color {
        switch v {
        case 1: return accent
        case 2: return ThemeColors.pixelSkin
        case 3: return ThemeColors.pixelEye
        case 4: return ThemeColors.pixelBody
        default: return .clear
        }
    }
}
