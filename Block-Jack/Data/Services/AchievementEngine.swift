//
//  AchievementEngine.swift
//  Block-Jack
//
//  Phase 8 — Retention katmanı: kalıcı başarı/achievement kataloğu.
//  UserEnvironment içinde tutulan progress map'i ve unlocked set ile
//  çalışır; bu dosya sadece katalog + reward metadata + ilerleme
//  değerlendirmesi yapar. Gerçek eventler (round kazan, boss yen, skor vs.)
//  GameViewModel / UserEnvironment üzerinden `report(id:delta:)` ile gelir.
//

import Foundation

struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let titleTR: String
    let titleEN: String
    let descTR: String
    let descEN: String
    let goal: Int
    let rewardGold: Int
    let rewardDiamonds: Int
    let icon: String
}

enum AchievementEngine {

    /// Katalog — eklenen her id, UserEnvironment.achievementProgress
    /// sözlüğünde 0'dan başlar. Kaldırmak istersen save migration yok,
    /// sadece id'yi sözlükten okuyoruz — yeni id eklemek güvenli.
    static let catalog: [Achievement] = [
        Achievement(
            id: "first_victory",
            titleTR: "İlk Zaferin",
            titleEN: "First Victory",
            descTR: "1 tur kazan",
            descEN: "Win 1 round",
            goal: 1,
            rewardGold: 100,
            rewardDiamonds: 0,
            icon: "rosette"
        ),
        Achievement(
            id: "perk_collector_5",
            titleTR: "Koleksiyoncu",
            titleEN: "Collector",
            descTR: "5 farklı perk keşfet",
            descEN: "Discover 5 different perks",
            goal: 5,
            rewardGold: 300,
            rewardDiamonds: 20,
            icon: "sparkles"
        ),
        Achievement(
            id: "boss_slayer_3",
            titleTR: "Boss Avcısı",
            titleEN: "Boss Slayer",
            descTR: "3 boss yen",
            descEN: "Defeat 3 bosses",
            goal: 3,
            rewardGold: 500,
            rewardDiamonds: 50,
            icon: "shield.lefthalf.filled"
        ),
        Achievement(
            id: "gold_hoarder_5k",
            titleTR: "Altın Tutkusu",
            titleEN: "Gold Hoarder",
            descTR: "Toplam 5.000 altın kazan",
            descEN: "Earn 5,000 gold lifetime",
            goal: 5000,
            rewardGold: 0,
            rewardDiamonds: 30,
            icon: "dollarsign.circle.fill"
        ),
        Achievement(
            id: "world_explorer_2",
            titleTR: "Sınır Ötesi",
            titleEN: "Beyond Borders",
            descTR: "Dünya 2'ye ulaş",
            descEN: "Reach World 2",
            goal: 2,
            rewardGold: 1000,
            rewardDiamonds: 100,
            icon: "map.fill"
        ),
        Achievement(
            id: "lines_100",
            titleTR: "Temizlik Şampiyonu",
            titleEN: "Clean Sweep",
            descTR: "Toplam 100 satır temizle",
            descEN: "Clear 100 lines lifetime",
            goal: 100,
            rewardGold: 400,
            rewardDiamonds: 10,
            icon: "trapezoid.and.line.horizontal"
        ),
        Achievement(
            id: "score_10k",
            titleTR: "Kombo Ustası",
            titleEN: "Combo Master",
            descTR: "Tek seferde 10.000 skor yap",
            descEN: "Score 10,000 in a single run",
            goal: 10000,
            rewardGold: 750,
            rewardDiamonds: 25,
            icon: "crown.fill"
        ),
        Achievement(
            id: "streak_7",
            titleTR: "Sadakat Programı",
            titleEN: "Daily Devotee",
            descTR: "7 gün üst üste giriş yap",
            descEN: "Log in 7 days in a row",
            goal: 7,
            rewardGold: 500,
            rewardDiamonds: 50,
            icon: "calendar.badge.checkmark"
        ),

        // MARK: - Karakter-özel başarılar
        // Her karakter için bir hedef — oyuncu bütün rosterı test etmeye
        // motive olur, premium karakterler "pasif show-off" değil aktif
        // oynanış hedefine dönüşür.

        Achievement(
            id: "block_e_custodian",
            titleTR: "BLOCK-E • Temizlik Botu",
            titleEN: "BLOCK-E • Custodian",
            descTR: "BLOCK-E pasifi ile 100 hücre eritsin",
            descEN: "Melt 100 cells with BLOCK-E's passive",
            goal: 100,
            rewardGold: 400,
            rewardDiamonds: 15,
            icon: "cpu.fill"
        ),
        Achievement(
            id: "architect_geometer",
            titleTR: "Architect • Geometri Ustası",
            titleEN: "Architect • Geometer",
            descTR: "Architect ile 50 O-blok yerleştir",
            descEN: "Place 50 O-blocks as the Architect",
            goal: 50,
            rewardGold: 500,
            rewardDiamonds: 40,
            icon: "square.grid.3x3.fill"
        ),
        Achievement(
            id: "timebender_chrono",
            titleTR: "Time Bender • Zaman Kadim",
            titleEN: "Time Bender • Chrono",
            descTR: "Time Bender aktif gücünü 10 kez kullan",
            descEN: "Activate Time Bender's overdrive 10 times",
            goal: 10,
            rewardGold: 500,
            rewardDiamonds: 50,
            icon: "hourglass"
        ),
        Achievement(
            id: "gambler_jackpot",
            titleTR: "Gambler • Jackpot",
            titleEN: "Gambler • Jackpot",
            descTR: "Gambler ile ×10 jackpot'u 5 kez tetikle",
            descEN: "Trigger Gambler's ×10 jackpot 5 times",
            goal: 5,
            rewardGold: 500,
            rewardDiamonds: 60,
            icon: "dice.fill"
        ),
        Achievement(
            id: "wraith_clutch",
            titleTR: "Neon Wraith • Son Saniye",
            titleEN: "Neon Wraith • Clutch",
            descTR: "%20 sürenin altındayken 20 temizlik yap",
            descEN: "Clear 20 lines under 20% time as Wraith",
            goal: 20,
            rewardGold: 500,
            rewardDiamonds: 50,
            icon: "bolt.fill"
        ),
        Achievement(
            id: "ghost_phantom",
            titleTR: "Ghost • Hayalet Yazgı",
            titleEN: "Ghost • Phantom Write",
            descTR: "Ghost pasifi ile 30 phantom bloğu yerleştir",
            descEN: "Overwrite 30 cells with Ghost's phantom",
            goal: 30,
            rewardGold: 500,
            rewardDiamonds: 50,
            icon: "eye.slash.fill"
        ),
        Achievement(
            id: "alchemist_resonance",
            titleTR: "Alchemist • Rezonans",
            titleEN: "Alchemist • Resonance",
            descTR: "Alchemist ile 25 mono-renk flush yap",
            descEN: "Score 25 mono-color flushes as Alchemist",
            goal: 25,
            rewardGold: 500,
            rewardDiamonds: 55,
            icon: "flask.fill"
        ),
        Achievement(
            id: "titan_earthquake",
            titleTR: "Titan • Deprem",
            titleEN: "Titan • Earthquake",
            descTR: "Titan T3 ile grid'i 5 kez sıfırla",
            descEN: "Reset the grid 5 times with Titan T3",
            goal: 5,
            rewardGold: 500,
            rewardDiamonds: 60,
            icon: "hammer.fill"
        )
    ]

    static func achievement(for id: String) -> Achievement? {
        catalog.first { $0.id == id }
    }

    /// Progress [0, goal] aralığına clamp edilmiş oran.
    static func progressRatio(_ achievement: Achievement, current: Int) -> Double {
        guard achievement.goal > 0 else { return 0 }
        return min(1.0, max(0.0, Double(current) / Double(achievement.goal)))
    }
}

// MARK: - Daily Reward katalog

struct DailyRewardTier: Equatable {
    let day: Int           // 1..7
    let gold: Int
    let diamonds: Int
}

enum DailyRewardSchedule {
    /// 7 günlük rotasyon; streak ≥ 7 olduğunda mod 7 ile döner.
    static let schedule: [DailyRewardTier] = [
        .init(day: 1, gold: 50,  diamonds: 0),
        .init(day: 2, gold: 75,  diamonds: 0),
        .init(day: 3, gold: 100, diamonds: 5),
        .init(day: 4, gold: 150, diamonds: 5),
        .init(day: 5, gold: 200, diamonds: 10),
        .init(day: 6, gold: 250, diamonds: 15),
        .init(day: 7, gold: 500, diamonds: 50)
    ]

    static func reward(forStreakDay day: Int) -> DailyRewardTier {
        let idx = (max(1, day) - 1) % schedule.count
        return schedule[idx]
    }
}

// MARK: - Local Leaderboard

struct LocalScoreEntry: Codable, Identifiable, Equatable {
    var id: String { "\(timestamp)_\(score)" }
    let score: Int
    let characterID: String
    let worldLevelReached: Int
    let timestamp: TimeInterval   // Date().timeIntervalSince1970
}
