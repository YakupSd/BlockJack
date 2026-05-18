//
//  CareerStatsModel.swift
//  Block-Jack
//

import Foundation

// MARK: - Mastery Level System
struct MasteryLevel: Codable, Equatable {
    let level: Int // 1, 2, 3, 4, 5
    let titleTR: String
    let titleEN: String
    let requiredXP: Int

    func title(lang: AppLanguage) -> String {
        switch lang {
        case .turkish: return titleTR
        case .english: return titleEN
        }
    }
    
    static let levels: [MasteryLevel] = [
        MasteryLevel(level: 1, titleTR: "Çırak", titleEN: "Apprentice", requiredXP: 0),
        MasteryLevel(level: 2, titleTR: "Uzman", titleEN: "Expert", requiredXP: 5000),
        MasteryLevel(level: 3, titleTR: "İleri Seviye", titleEN: "Advanced", requiredXP: 15000),
        MasteryLevel(level: 4, titleTR: "Ustanın Ustası", titleEN: "Master", requiredXP: 35000),
        MasteryLevel(level: 5, titleTR: "Efsanevi", titleEN: "Legendary", requiredXP: 100000)
    ]
    
    static func getMasteryLevel(xp: Int) -> MasteryLevel {
        let sorted = levels.sorted { $0.requiredXP > $1.requiredXP }
        for level in sorted {
            if xp >= level.requiredXP {
                return level
            }
        }
        return levels.first ?? MasteryLevel(level: 1, titleTR: "Çırak", titleEN: "Apprentice", requiredXP: 0)
    }
}

// MARK: - Career Stat Entry (for individual stat tracking)
struct CareerStatEntry: Codable {
    let runID: String
    let characterID: String
    let score: Int
    let damageDealt: Int // Total damage dealt in this run
    let linesCleared: Int
    let bossesDefeated: Int
    let usedPerks: [String] // Perk IDs used in this run
    let duration: TimeInterval
    let date: Date
    let chapter: Int
}

// MARK: - Career Stats Container
struct CareerStats: Codable {
    // MARK: - Overall Stats
    var totalDamageDealt: Int = 0 // Sum of all damage across all runs
    var totalLinesCleared: Int = 0
    var totalBossesDefeated: Int = 0
    var totalRunsCompleted: Int = 0
    var totalPlayTime: TimeInterval = 0 // Total hours played
    
    // MARK: - Character Stats
    var totalCharactersUnlocked: Int = 0
    var favoriteCharacterID: String = ""
    var characterStats: [String: CharacterCareerStats] = [:] // [characterID: stats]
    
    // MARK: - Perk Stats
    var mostUsedPerkID: String = ""
    var perkStats: [String: PerkCareerStats] = [:] // [perkID: stats]
    
    // MARK: - Mastery
    var masteryXP: Int = 0 // Overall mastery XP
    var masteryLevel: MasteryLevel { MasteryLevel.getMasteryLevel(xp: masteryXP) }
    
    // MARK: - Session History
    var recentRuns: [CareerStatEntry] = [] // Last 50 runs
    
    // MARK: - Achievements
    var unlockedTitles: Set<String> = [] // Special achievement titles
}

// MARK: - Character-Specific Career Stats
struct CharacterCareerStats: Codable, Identifiable {
    let characterID: String
    var id: String { characterID }
    
    var runsCompleted: Int = 0
    var averageScore: Int = 0
    var highestScore: Int = 0
    var totalDamageDealt: Int = 0
    var favoriteMapID: String = ""
    var preferredPerkID: String = ""
    var masteryXP: Int = 0 // Character-specific mastery
    var masteryLevel: MasteryLevel { MasteryLevel.getMasteryLevel(xp: masteryXP) }
}

// MARK: - Perk-Specific Career Stats
struct PerkCareerStats: Codable, Identifiable {
    let perkID: String
    var id: String { perkID }
    
    var timesUsed: Int = 0
    var averageRunScore: Int = 0
    var winRateWithPerk: Double = 0 // % of runs where perk was equipped
    var totalDamageDealt: Int = 0
}

// MARK: - Special Titles (Achievements)
enum SpecialTitle: String, CaseIterable, Codable {
    case gridSlayer = "GRID_SLAYER" // 500+ lines cleared
    case damageDealer = "DAMAGE_DEALER" // 10M+ damage
    case perkCollector = "PERK_COLLECTOR" // Used 50+ different perks
    case bossHunter = "BOSS_HUNTER" // 100+ bosses defeated
    case speedRunner = "SPEED_RUNNER" // Completed 50 runs under 5 minutes
    case eternal = "ETERNAL" // Reach level 5 Mastery
    case perfectRun = "PERFECT_RUN" // 0 mistakes in a run (internal tracking)
    case timeKeeper = "TIME_KEEPER" // 1000+ hours played
    
    var titleTR: String {
        switch self {
        case .gridSlayer: return "Grid Katili"
        case .damageDealer: return "Hasar Ustası"
        case .perkCollector: return "Perk Koleksiyoncusu"
        case .bossHunter: return "Boss Avcısı"
        case .speedRunner: return "Hız Koşucusu"
        case .eternal: return "Ebedi"
        case .perfectRun: return "Mükemmel Koşu"
        case .timeKeeper: return "Zaman Koruyucusu"
        }
    }
    
    var titleEN: String {
        switch self {
        case .gridSlayer: return "Grid Slayer"
        case .damageDealer: return "Damage Dealer"
        case .perkCollector: return "Perk Collector"
        case .bossHunter: return "Boss Hunter"
        case .speedRunner: return "Speed Runner"
        case .eternal: return "Eternal"
        case .perfectRun: return "Perfect Run"
        case .timeKeeper: return "Time Keeper"
        }
    }
    
    var descriptionTR: String {
        switch self {
        case .gridSlayer: return "500+ satır temizle"
        case .damageDealer: return "10M+ hasar ver"
        case .perkCollector: return "50+ farklı perk kullan"
        case .bossHunter: return "100+ boss yenilgiyi"
        case .speedRunner: return "50 run'u 5dk altında tamamla"
        case .eternal: return "Mastery Level 5'e ulaş"
        case .perfectRun: return "Hiçbir hata yapmadan bir run tamamla"
        case .timeKeeper: return "1000+ saat oyna"
        }
    }
    
    var descriptionEN: String {
        switch self {
        case .gridSlayer: return "Clear 500+ lines"
        case .damageDealer: return "Deal 10M+ damage"
        case .perkCollector: return "Use 50+ different perks"
        case .bossHunter: return "Defeat 100+ bosses"
        case .speedRunner: return "Complete 50 runs under 5 minutes"
        case .eternal: return "Reach Mastery Level 5"
        case .perfectRun: return "Complete a run with no mistakes"
        case .timeKeeper: return "Play 1000+ hours"
        }
    }
    
    var icon: String {
        switch self {
        case .gridSlayer: return "⚔️"
        case .damageDealer: return "💥"
        case .perkCollector: return "✨"
        case .bossHunter: return "🎯"
        case .speedRunner: return "⚡"
        case .eternal: return "👑"
        case .perfectRun: return "💎"
        case .timeKeeper: return "🕐"
        }
    }

    func title(lang: AppLanguage) -> String {
        switch lang {
        case .turkish: return titleTR
        case .english: return titleEN
        }
    }

    func description(lang: AppLanguage) -> String {
        switch lang {
        case .turkish: return descriptionTR
        case .english: return descriptionEN
        }
    }
}
