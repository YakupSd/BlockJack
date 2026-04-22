//
//  WorldMapDetailSheet.swift
//  Block-Jack
//
//  Ana haritada bir sektöre tıklandığında açılan alt sheet.
//  Normal seviyeler için "savaş" içeriği, boss seviyeleri için boss uyarı
//  banner'ı ve BossRegistry'den çekilen ön izleme gösterir.
//

import SwiftUI

// MARK: - Detail Sheet
struct WorldMapDetailSheet: View {
    let level: WorldLevel
    let onEnter: () -> Void
    let onDismiss: () -> Void

    @EnvironmentObject var userEnv: UserEnvironment

    var body: some View {
        VStack(spacing: 0) {
            // Sistem presentationDragIndicator zaten görünür — kendi Capsule'ümüzü
            // çiftlemiyoruz. Üstte sadece hafif boşluk bırak.
            Color.clear.frame(height: 14)

            header
                .padding(.horizontal, 20)

            Rectangle()
                .fill(ThemeColors.mapRoadDark)
                .frame(height: 1)
                .padding(.vertical, 12)

            // İçerik — type'a göre
            Group {
                if level.type == .boss {
                    WorldSheetBossContent(level: level)
                } else {
                    WorldSheetBattleContent(level: level)
                }
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 12)

            WorldSheetActionButton(level: level, onEnter: onEnter)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .background(ThemeColors.mapBg)
        .foregroundColor(.white)
    }

    // MARK: Header
    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(nodeHeaderBg)
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(nodeHeaderBorder, lineWidth: 1.5)
                    )
                WorldCityPixelIcon(level: level)
                    .frame(width: 40, height: 40)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(typeBadgeText)
                    .font(.pixel(5))
                    .foregroundColor(nodeHeaderBorder)
                    .tracking(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(nodeHeaderBorder.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 3))

                Text(title)
                    .font(.pixel(11))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                difficultyBar
            }

            Spacer(minLength: 4)
        }
    }

    private var title: String {
        if level.type == .boss {
            return BossRegistry.shared.getBoss(for: level.id).name
        }
        return userEnv.localizedString("SEKTÖR \(level.id)", "SECTOR \(level.id)")
    }

    private var typeBadgeText: String {
        switch (level.type, level.status) {
        case (.boss, _):
            return userEnv.localizedString("BOSS", "BOSS")
        case (_, .completed):
            return userEnv.localizedString("TAMAMLANDI", "CLEARED")
        case (_, .locked):
            return userEnv.localizedString("KİLİTLİ", "LOCKED")
        case (_, .available):
            return userEnv.localizedString("SAVAŞ", "BATTLE")
        }
    }

    private var difficultyStars: Int {
        // 20 seviyeye yayılmış yıldız — boss'larda 1 ekstra
        let base = max(1, min(5, (level.id + 3) / 4))
        return level.type == .boss ? min(5, base + 1) : base
    }

    private var difficultyBar: some View {
        HStack(spacing: 3) {
            ForEach(0..<5) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(i < difficultyStars ? ThemeColors.nodeCurrent : ThemeColors.nodeLocked)
                    .frame(width: 12, height: 6)
            }
            Text(userEnv.localizedString("ZORLUK", "DIFFICULTY"))
                .font(.pixel(5))
                .foregroundColor(ThemeColors.mapHudMuted)
                .tracking(1)
                .padding(.leading, 2)
        }
    }

    private var nodeHeaderBg: Color {
        if level.type == .boss { return ThemeColors.nodeBgBoss }
        switch level.status {
        case .completed: return ThemeColors.nodeBgCompleted
        case .available: return ThemeColors.nodeBgCurrent
        case .locked:    return ThemeColors.nodeBgLocked
        }
    }

    private var nodeHeaderBorder: Color {
        if level.type == .boss { return ThemeColors.nodeBoss }
        switch level.status {
        case .completed: return ThemeColors.nodeCompleted
        case .available: return ThemeColors.nodeCurrent
        case .locked:    return ThemeColors.nodeLocked
        }
    }
}

// MARK: - Normal savaş içeriği
struct WorldSheetBattleContent: View {
    let level: WorldLevel
    @EnvironmentObject var userEnv: UserEnvironment

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(ThemeColors.enemyBg)
                        .frame(width: 44, height: 44)
                    Text(enemyEmoji)
                        .font(.system(size: 22))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(enemyName)
                        .font(.pixel(7))
                        .foregroundColor(ThemeColors.nodeCurrent)
                        .lineLimit(1)
                    Text(enemyIntent)
                        .font(.pixel(5))
                        .foregroundColor(ThemeColors.mapHudMuted)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .padding(10)
            .background(ThemeColors.mapHudPanel)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(ThemeColors.mapHudBorder, lineWidth: 1)
            )

            HStack(spacing: 8) {
                WorldRewardPill(icon: "★",
                                label: userEnv.localizedString("PUAN", "SCORE"),
                                value: "\(estimatedScore)")
                WorldRewardPill(icon: "◆",
                                label: userEnv.localizedString("ALTIN", "GOLD"),
                                value: "\(estimatedGold)",
                                color: ThemeColors.electricYellow)
                WorldRewardPill(icon: "⚡",
                                label: userEnv.localizedString("PERK", "PERK"),
                                value: userEnv.localizedString("ŞANS", "CHANCE"),
                                color: ThemeColors.neonCyan)
            }
        }
    }

    private var enemyEmoji: String {
        // Seviye bandına göre değişen minik görsel aksesuar
        switch level.id {
        case 0...3:   return "🤖"
        case 4...7:   return "👾"
        case 8...11:  return "🛸"
        case 12...15: return "💀"
        default:      return "⚡"
        }
    }

    private var enemyName: String {
        let tr = [
            "VERİ BEKÇİSİ", "GLITCH PROBU", "SİBER AVCI", "NEON GLADIATÖR",
            "KOD KEMİRCİSİ", "SENTRY BIRIMI", "PHANTOM EKO", "AĞIRLIK MODÜLÜ"
        ]
        let en = [
            "DATA WARDEN", "GLITCH PROBE", "CYBER HUNTER", "NEON GLADIATOR",
            "CODE GNAWER", "SENTRY UNIT", "PHANTOM ECHO", "WEIGHT MODULE"
        ]
        let idx = abs(level.id - 1) % tr.count
        return userEnv.language == .turkish ? tr[idx] : en[idx]
    }

    private var enemyIntent: String {
        let tr = [
            "Gridini kilitleyecek.",
            "Hamle başına 2 saniye çalar.",
            "Blokları rastgele döndürür.",
            "Can hasarı ikiye katlanır.",
            "Tepsini karıştırır.",
            "Puan çarpanını düşürür."
        ]
        let en = [
            "Will lock your grid.",
            "Steals 2s per move.",
            "Spins blocks randomly.",
            "Life damage doubled.",
            "Shuffles your tray.",
            "Drops score multiplier."
        ]
        let idx = (level.id * 7) % tr.count
        return userEnv.language == .turkish ? tr[idx] : en[idx]
    }

    private var estimatedScore: Int { 400 + level.id * 75 }
    private var estimatedGold: Int { 25 + level.id * 8 }
}

// MARK: - Boss içeriği
struct WorldSheetBossContent: View {
    let level: WorldLevel
    @EnvironmentObject var userEnv: UserEnvironment
    @State private var warningPulse = false
    // Intent'i bir kere yakala — her re-render'da değişip titremesin
    @State private var bossIntent: String = ""

    private var boss: BossEncounter {
        BossRegistry.shared.getBoss(for: level.id)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                // Boss portresi (gerçek asset) + kırmızı aksan çubuğu
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(ThemeColors.nodeBgBoss)
                        .frame(width: 56, height: 56)
                    Image(boss.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(ThemeColors.nodeBoss, lineWidth: 1.5)
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(userEnv.localizedString("!! BOSS SAVAŞI !!", "!! BOSS FIGHT !!"))
                        .font(.pixel(7))
                        .foregroundColor(ThemeColors.nodeBoss)
                        .tracking(1)
                        .opacity(warningPulse ? 0.45 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                   value: warningPulse)
                    Text(bossIntent.isEmpty ? boss.getRandomIntent() : bossIntent)
                        .font(.pixel(6))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                    Text(userEnv.localizedString(
                        "Tüm canlarını ve overdrive'ını hazırla.",
                        "Bring every life and overdrive you've got."
                    ))
                    .font(.pixel(5))
                    .foregroundColor(ThemeColors.mapHudMuted)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Color(hex: "#130808"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(ThemeColors.nodeBoss.opacity(0.4), lineWidth: 1)
            )

            HStack(spacing: 8) {
                WorldRewardPill(icon: "★",
                                label: userEnv.localizedString("PUAN", "SCORE"),
                                value: "\(1000 + level.id * 120)",
                                color: ThemeColors.nodeCurrent)
                WorldRewardPill(icon: "◆",
                                label: userEnv.localizedString("ALTIN", "GOLD"),
                                value: "\(150 + level.id * 15)",
                                color: ThemeColors.electricYellow)
                WorldRewardPill(icon: "♦",
                                label: userEnv.localizedString("EŞYA", "ITEM"),
                                value: userEnv.localizedString("NADİR", "RARE"),
                                color: ThemeColors.neonPurple)
            }
        }
        .onAppear {
            warningPulse = true
            if bossIntent.isEmpty { bossIntent = boss.getRandomIntent() }
        }
    }
}

// MARK: - Ödül pill
struct WorldRewardPill: View {
    let icon: String
    let label: String
    let value: String
    var color: Color = .white

    var body: some View {
        HStack(spacing: 5) {
            Text(icon).font(.system(size: 10))
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.pixel(4))
                    .foregroundColor(ThemeColors.mapHudMuted)
                    .tracking(1)
                Text(value)
                    .font(.pixel(7))
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(ThemeColors.mapHudPanel)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(ThemeColors.mapHudBorder, lineWidth: 1)
        )
    }
}

// MARK: - Aksiyon butonu
struct WorldSheetActionButton: View {
    let level: WorldLevel
    let onEnter: () -> Void
    @EnvironmentObject var userEnv: UserEnvironment

    var body: some View {
        Button(action: onEnter) {
            Text(label)
                .font(.pixel(9))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(bg)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(border, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .disabled(level.status == .locked)
        .opacity(level.status == .locked ? 0.55 : 1.0)
    }

    private var label: String {
        switch (level.type, level.status) {
        case (_, .locked):     return userEnv.localizedString("KİLİTLİ", "LOCKED")
        case (.boss, _):       return userEnv.localizedString("!! BOSS'A MEYDAN OKU !!", "!! CHALLENGE BOSS !!")
        case (_, .completed):  return userEnv.localizedString("TEKRAR GİR", "RE-ENTER")
        case (_, .available):  return userEnv.localizedString("SAVAŞA GİR >", "ENTER BATTLE >")
        }
    }

    private var bg: Color {
        if level.status == .locked { return Color.black.opacity(0.6) }
        return level.type == .boss ? Color(hex: "#3a0808") : Color(hex: "#0d1a2e")
    }

    private var border: Color {
        if level.status == .locked { return ThemeColors.nodeLocked }
        return level.type == .boss ? ThemeColors.nodeBoss : ThemeColors.pixelEye
    }

    private var textColor: Color {
        if level.status == .locked { return ThemeColors.mapHudMuted }
        return level.type == .boss ? ThemeColors.nodeBoss : ThemeColors.pixelEye
    }
}
