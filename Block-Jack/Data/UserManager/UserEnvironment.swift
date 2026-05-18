//
//  UserEnvironment.swift
//  Block-Jack
//

import Combine
import CryptoKit
import OSLog
import SwiftUI

// MARK: - Avatar System
enum AvatarCategory: String, CaseIterable, Codable {
    case male = "Erkek"
    case female = "Kadın"
    case animal = "Hayvan"

    func displayName(lang: AppLanguage) -> String {
        switch lang {
        case .turkish:
            switch self {
            case .male: return "ERKEK"
            case .female: return "KADIN"
            case .animal: return "HAYVAN"
            }
        case .english:
            switch self {
            case .male: return "MALE"
            case .female: return "FEMALE"
            case .animal: return "ANIMAL"
            }
        }
    }
}

struct AvatarItem: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let imageName: String
    let category: AvatarCategory
    let cost: Int
    
    var isFree: Bool { cost == 0 }
}

extension AvatarItem {
    static let allAvatars: [AvatarItem] = [
        // Male
        AvatarItem(id: 0, name: "Neon Prince", imageName: "profile_male_1_free", category: .male, cost: 0),
        AvatarItem(id: 1, name: "Cyber Ninja", imageName: "profile_male_2_paid", category: .male, cost: 500),
        AvatarItem(id: 2, name: "Synth Lord", imageName: "profile_male_3_paid", category: .male, cost: 1500),
        
        // Female
        AvatarItem(id: 3, name: "Holo Queen", imageName: "profile_female_1_free", category: .female, cost: 0),
        AvatarItem(id: 4, name: "Data Diva", imageName: "profile_female_2_paid", category: .female, cost: 500),
        AvatarItem(id: 5, name: "Glitch Ghost", imageName: "profile_female_3_paid", category: .female, cost: 1500),
        
        // Animal
        AvatarItem(id: 6, name: "Cosmic Cat", imageName: "profile_animal_1_free", category: .animal, cost: 0),
        AvatarItem(id: 7, name: "Byte Bear", imageName: "profile_animal_2_paid", category: .animal, cost: 500),
        AvatarItem(id: 8, name: "Binary Bunny", imageName: "profile_animal_3_paid", category: .animal, cost: 1500)
    ]
}

// MARK: - Language Enum
enum AppLanguage: String, CaseIterable, Codable {
    case turkish = "tr"
    case english = "en"

    var displayName: String {
        switch self {
        case .turkish: return "Türkçe"
        case .english: return "English"
        }
    }
}

// MARK: - Meta Upgrades Enum (Diamond Purchases - One Time)
enum MetaUpgrade: String, CaseIterable {
    case goldEye = "gold_eye"
    case ironWill = "iron_will"
    case luckyDice = "lucky_dice"
    case extraSlot = "extra_slot"
    
    var cost: Int {
        switch self {
        case .goldEye: return 300
        case .ironWill: return 500
        case .luckyDice: return 800
        case .extraSlot: return 1500
        }
    }

    var titleTR: String {
        switch self {
        case .goldEye: return "Altın Göz"
        case .ironWill: return "Iron Will"
        case .luckyDice: return "Şanslı Zar"
        case .extraSlot: return "Ekstra Slot"
        }
    }

    var titleEN: String {
        switch self {
        case .goldEye: return "Gold Eye"
        case .ironWill: return "Iron Will"
        case .luckyDice: return "Lucky Dice"
        case .extraSlot: return "Extra Slot"
        }
    }

    var descTR: String {
        switch self {
        case .goldEye: return "Pasif: Her tur sonu +%10 bonus altın."
        case .ironWill: return "Başlangıç süresini +10 saniye artırır."
        case .luckyDice: return "The Gambler'ın şansı +%3 artar."
        case .extraSlot: return "Maksimum envanter 3'ten 4'e çıkar."
        }
    }

    var descEN: String {
        switch self {
        case .goldEye: return "Passive: +10% bonus gold at round end."
        case .ironWill: return "Starting time +10 seconds permanently."
        case .luckyDice: return "Gambler's trigger chance +3%."
        case .extraSlot: return "Max inventory slots from 3 to 4."
        }
    }

    func title(lang: AppLanguage) -> String {
        switch lang {
        case .turkish: return titleTR
        case .english: return titleEN
        }
    }

    func desc(lang: AppLanguage) -> String {
        switch lang {
        case .turkish: return descTR
        case .english: return descEN
        }
    }
}

// MARK: - Gold Upgrades Enum (Gold Purchases - Leveled)
enum GoldUpgrade: String, CaseIterable {
    case comboTime = "combo_time"     // Kombo süresi uzar
    case startBonus = "start_bonus"   // Başlangıç skoru bonusı
    case overdriveFill = "overdrive_fill" // Overdrive dolum hızı
    case blockLuck = "block_luck"     // Daha iyi bloklar gelme ihtimali
    case goldMagnet = "gold_magnet"   // Round başı ekstra altın
    
    var maxLevel: Int { 5 }
    
    var titleTR: String {
        switch self {
        case .comboTime: return "Kombo Uzatıcı"
        case .startBonus: return "Başlangıç Bonusu"
        case .overdriveFill: return "Hızlı şarş"
        case .blockLuck: return "Blok Şansı"
        case .goldMagnet: return "Altın Mıknatıs"
        }
    }
    
    var titleEN: String {
        switch self {
        case .comboTime: return "Combo Extender"
        case .startBonus: return "Head Start"
        case .overdriveFill: return "Fast Charge"
        case .blockLuck: return "Block Luck"
        case .goldMagnet: return "Gold Magnet"
        }
    }
    
    var icon: String {
        switch self {
        case .comboTime: return "timer"
        case .startBonus: return "bolt.fill"
        case .overdriveFill: return "battery.100.bolt"
        case .blockLuck: return "sparkles"
        case .goldMagnet: return "magnet.fill"
        }
    }
    
    var descTemplateTR: String {
        switch self {
        case .comboTime: return "Kombo süresi +{{value}}% daha yavaş düşer"
        case .startBonus: return "Round başında +{{value}} puan bonusu"
        case .overdriveFill: return "Overdrive +{{value}}% daha hızlı dolar"
        case .blockLuck: return "%{{value}} ihtimalle nadide blok gelir"
        case .goldMagnet: return "Her round +{{value}} altın kazancı"
        }
    }
    
    var descTemplateEN: String {
        switch self {
        case .comboTime: return "Combo timer is {{value}}% slower"
        case .startBonus: return "+{{value}} score bonus at round start"
        case .overdriveFill: return "Overdrive fills {{value}}% faster"
        case .blockLuck: return "{{value}}% chance for rare block"
        case .goldMagnet: return "+{{value}} gold bonus per round"
        }
    }
    
    var effectTemplateTR: String {
        switch self {
        case .startBonus: return "Şu an: +{{value}} puan / round"
        case .goldMagnet: return "Şu an: +{{value}} altın / round"
        case .overdriveFill: return "Şu an: +%{{value}} dolum hızı"
        case .comboTime: return "Şu an: streak düşüşü %{{value}} daha yavaş"
        case .blockLuck: return "Şu an: daha iyi blok şansı +{{value}}"
        }
    }
    
    var effectTemplateEN: String {
        switch self {
        case .startBonus: return "Now: +{{value}} score / round"
        case .goldMagnet: return "Now: +{{value}} gold / round"
        case .overdriveFill: return "Now: +{{value}}% fill rate"
        case .comboTime: return "Now: streak decays {{value}}% slower"
        case .blockLuck: return "Now: improved block odds +{{value}}"
        }
    }

    func title(lang: AppLanguage) -> String {
        switch lang {
        case .turkish: return titleTR
        case .english: return titleEN
        }
    }

    func desc(lang: AppLanguage) -> String {
        switch lang {
        case .turkish: return descTemplateTR
        case .english: return descTemplateEN
        }
    }

    func currentEffectTemplate(lang: AppLanguage) -> String {
        switch lang {
        case .turkish: return effectTemplateTR
        case .english: return effectTemplateEN
        }
    }

    /// Seviyeye göre dinamik olarak hesaplanması gereken sayısal değerler
    func calculatedValue(level: Int, isEffect: Bool = false) -> Int {
        switch self {
        case .comboTime:
            return min(50, level * 10)
        case .startBonus:
            return level * 50
        case .overdriveFill:
            return level * 10
        case .blockLuck:
            return isEffect ? level : level * 5
        case .goldMagnet:
            return level * 10
        }
    }
    
    /// Her seviyenin altın maliyeti (artan)
    func cost(for level: Int) -> Int {
        let baseGold: [GoldUpgrade: Int] = [
            .comboTime: 100,
            .startBonus: 80,
            .overdriveFill: 120,
            .blockLuck: 150,
            .goldMagnet: 90
        ]
        let base = baseGold[self] ?? 100
        return base * level * level // Karesel artış: 100, 400, 900, 1600, 2500...
    }
}

// MARK: - UserEnvironment
class UserEnvironment: ObservableObject {

    static let shared = UserEnvironment()

    // MARK: - Language
    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "appLanguage") }
    }

    // MARK: - Currency
    @Published var gold: Int {
        didSet { UserDefaults.standard.set(gold, forKey: "playerGold") }
    }
    @Published var diamonds: Int {
        didSet { UserDefaults.standard.set(diamonds, forKey: "playerDiamonds") }
    }

    // MARK: - Active Slot Tracking (Phase 11)
    @Published var activeSlotId: Int? = nil
    @Published var unlockedWorldLevel: Int = 1 {
        didSet { syncWithSlot() }
    }

    // MARK: - Pre-run Config (tek kaynak)
    @Published var runConfig: RunConfig? = nil

    // MARK: - Trial Character (günlük 1 premium deneme)
    @Published var trialCharacterLastDay: String {
        didSet { UserDefaults.standard.set(trialCharacterLastDay, forKey: "trialCharacterLastDay") }
    }
    @Published var trialCharacterIdToday: String {
        didSet { UserDefaults.standard.set(trialCharacterIdToday, forKey: "trialCharacterIdToday") }
    }
    @Published var trialRunUsedToday: Bool {
        didSet { UserDefaults.standard.set(trialRunUsedToday, forKey: "trialRunUsedToday") }
    }

    // MARK: - Settings
    @Published var isSoundEnabled: Bool {
        didSet { 
            UserDefaults.standard.set(isSoundEnabled, forKey: "soundEnabled")
            if isSoundEnabled {
                // If music was stopped, maybe resume? For now just ensure it's not nil.
            } else {
                AudioManager.shared.stopMusic()
            }
        }
    }
    @Published var isHapticEnabled: Bool {
        didSet { 
            UserDefaults.standard.set(isHapticEnabled, forKey: "hapticEnabled")
            if isHapticEnabled {
                HapticManager.shared.play(.selection)
            }
        }
    }

    // MARK: - Game Stats
    @Published var highScore: Int {
        didSet { UserDefaults.standard.set(highScore, forKey: "highScore") }
    }
    
    // Phase C: Lifetime Stats
    @Published var totalGoldEarned: Int {
        didSet { UserDefaults.standard.set(totalGoldEarned, forKey: "totalGoldEarned") }
    }
    @Published var totalLinesCleared: Int {
        didSet { UserDefaults.standard.set(totalLinesCleared, forKey: "totalLinesCleared") }
    }
    @Published var totalBossesDefeated: Int {
        didSet { UserDefaults.standard.set(totalBossesDefeated, forKey: "totalBossesDefeated") }
    }
    
    // Phase C: Discovery Tracking
    @Published var discoveredPerkIDs: Set<String> {
        didSet {
            if let data = try? JSONEncoder().encode(discoveredPerkIDs) {
                UserDefaults.standard.set(data, forKey: "discoveredPerks")
            }
        }
    }
    @Published var discoveredBossIDs: Set<String> {
        didSet {
            if let data = try? JSONEncoder().encode(discoveredBossIDs) {
                UserDefaults.standard.set(data, forKey: "discoveredBosses")
            }
        }
    }

    @Published var tutorialCompleted: Bool {
        didSet { UserDefaults.standard.set(tutorialCompleted, forKey: "tutorialCompleted") }
    }
    @Published var hubIntroShown: Bool {
        didSet { UserDefaults.standard.set(hubIntroShown, forKey: "hubIntroShown") }
    }
    @Published var selectedCharacterID: String {
        didSet { UserDefaults.standard.set(selectedCharacterID, forKey: "selectedCharacterID") }
    }
    @Published var unlockedCharacterIDs: [String] {
        didSet {
            if let data = try? JSONEncoder().encode(unlockedCharacterIDs) {
                UserDefaults.standard.set(data, forKey: "unlockedCharacters")
            }
        }
    }
    @Published var unlockedUpgradeIDs: [String] {
        didSet {
            if let data = try? JSONEncoder().encode(unlockedUpgradeIDs) {
                UserDefaults.standard.set(data, forKey: "unlockedUpgrades")
            }
            syncWithSlot()
        }
    }
    
    // MARK: - Gold Upgrade Levels
    @Published var goldUpgradeLevels: [String: Int] {
        didSet {
            if let data = try? JSONEncoder().encode(goldUpgradeLevels) {
                UserDefaults.standard.set(data, forKey: "goldUpgradeLevels")
            }
            syncWithSlot()
        }
    }
    
    // MARK: - Leaderboard (Online)
    @Published var username: String {
        didSet { UserDefaults.standard.set(username, forKey: "leaderboardUsername") }
    }
    @Published var isRegistered: Bool {
        didSet { UserDefaults.standard.set(isRegistered, forKey: "leaderboardRegistered") }
    }
    @Published var playerCountryCode: String {
        didSet { UserDefaults.standard.set(playerCountryCode, forKey: "playerCountryCode") }
    }
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }
    @Published var fullName: String {
        didSet { UserDefaults.standard.set(fullName, forKey: "leaderboardFullName") }
    }
    @Published var email: String {
        didSet { UserDefaults.standard.set(email, forKey: "leaderboardEmail") }
    }
    private(set) var passwordHash: String {
        didSet { UserDefaults.standard.set(passwordHash, forKey: "leaderboardPasswordHash") }
    }

    // MARK: - Avatar State
    @Published var selectedAvatarID: Int {
        didSet { UserDefaults.standard.set(selectedAvatarID, forKey: "selectedAvatarID") }
    }
    @Published var unlockedAvatarIDs: Set<Int> {
        didSet {
            if let data = try? JSONEncoder().encode(unlockedAvatarIDs) {
                UserDefaults.standard.set(data, forKey: "unlockedAvatars")
            }
        }
    }


    // MARK: - Phase 8: Retention (Daily Reward / Achievements / Leaderboard)

    /// Son daily reward talep anı (epoch sn). 0 = hiç talep edilmedi.
    @Published var lastDailyClaimTimestamp: TimeInterval {
        didSet { UserDefaults.standard.set(lastDailyClaimTimestamp, forKey: "lastDailyClaimTimestamp") }
    }
    /// Üst üste giriş günü. 24h içinde claim kaçırılırsa 1'e resetlenir.
    @Published var dailyStreak: Int {
        didSet { UserDefaults.standard.set(dailyStreak, forKey: "dailyStreak") }
    }
    /// Açılmış (ödülü alınmış) başarı id'leri.
    @Published var unlockedAchievementIDs: Set<String> {
        didSet {
            if let data = try? JSONEncoder().encode(unlockedAchievementIDs) {
                UserDefaults.standard.set(data, forKey: "unlockedAchievements")
            }
        }
    }
    /// Her başarı için kümülatif ilerleme sayacı.
    @Published var achievementProgress: [String: Int] {
        didSet {
            if let data = try? JSONEncoder().encode(achievementProgress) {
                UserDefaults.standard.set(data, forKey: "achievementProgress")
            }
        }
    }
    /// Unlock olduğunda UI'ın göstereceği toast için pending id.
    @Published var pendingAchievementToastId: String? = nil
    /// En iyi 5 skor — her run sonunda eklenir, sıralanıp kırpılır.
    @Published var topScores: [LocalScoreEntry] {
        didSet {
            if let data = try? JSONEncoder().encode(topScores) {
                UserDefaults.standard.set(data, forKey: "topScores")
            }
        }
    }
    /// Her karakter için oynanmış **en yüksek** chapter (bölüm) numarası.
    /// Mastery badge ve golden glow için referans. Chapter clear edildiğinde
    /// `recordCharacterChapterClear` ile güncellenir.
    @Published var characterMaxChapter: [String: Int] {
        didSet {
            if let data = try? JSONEncoder().encode(characterMaxChapter) {
                UserDefaults.standard.set(data, forKey: "characterMaxChapter")
            }
        }
    }

    // MARK: - Character Questline (7-day chain)

    /// Her karakter için quest zincirinde hangi günde (1..7) olduğunu tutar.
    @Published var characterQuestDay: [String: Int] {
        didSet {
            if let data = try? JSONEncoder().encode(characterQuestDay) {
                UserDefaults.standard.set(data, forKey: "characterQuestDay")
            }
        }
    }

    /// Aktif quest için karakter bazlı progress (0..goal).
    @Published var characterQuestProgress: [String: Int] {
        didSet {
            if let data = try? JSONEncoder().encode(characterQuestProgress) {
                UserDefaults.standard.set(data, forKey: "characterQuestProgress")
            }
        }
    }

    /// Aynı karakterin quest gününü günde 1 kez ilerletebilmek için.
    /// Format: yyyy-MM-dd
    @Published var characterQuestLastAdvanceDay: [String: String] {
        didSet {
            if let data = try? JSONEncoder().encode(characterQuestLastAdvanceDay) {
                UserDefaults.standard.set(data, forKey: "characterQuestLastAdvanceDay")
            }
        }
    }

    // MARK: - Cosmetics (UI-only ownership)

    @Published var ownedCosmeticIDs: Set<String> {
        didSet {
            if let data = try? JSONEncoder().encode(ownedCosmeticIDs) {
                UserDefaults.standard.set(data, forKey: "ownedCosmetics")
            }
        }
    }

    // MARK: - Career Stats (Phase 11: Player Career & Advanced Stats)
    @Published var careerStats: CareerStats {
        didSet {
            if let data = try? JSONEncoder().encode(careerStats) {
                UserDefaults.standard.set(data, forKey: "careerStats")
            }
        }
    }

    // MARK: - Init
    init() {
        // 1. Initialize all properties from storage
        let savedLang = UserDefaults.standard.string(forKey: "appLanguage") ?? "tr"
        self.language = AppLanguage(rawValue: savedLang) ?? .turkish
        self.gold = UserDefaults.standard.integer(forKey: "playerGold")
        self.diamonds = UserDefaults.standard.integer(forKey: "playerDiamonds")
        self.isSoundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        self.isHapticEnabled = UserDefaults.standard.object(forKey: "hapticEnabled") as? Bool ?? true
        self.highScore = UserDefaults.standard.integer(forKey: "highScore")
        
        self.totalGoldEarned = UserDefaults.standard.integer(forKey: "totalGoldEarned")
        self.totalLinesCleared = UserDefaults.standard.integer(forKey: "totalLinesCleared")
        self.totalBossesDefeated = UserDefaults.standard.integer(forKey: "totalBossesDefeated")
        
        if let data = UserDefaults.standard.data(forKey: "discoveredPerks"),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.discoveredPerkIDs = decoded
        } else {
            self.discoveredPerkIDs = []
        }
        
        if let data = UserDefaults.standard.data(forKey: "discoveredBosses"),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.discoveredBossIDs = decoded
        } else {
            self.discoveredBossIDs = []
        }

        self.tutorialCompleted = UserDefaults.standard.bool(forKey: "tutorialCompleted")
        self.hubIntroShown = UserDefaults.standard.bool(forKey: "hubIntroShown")
        self.selectedCharacterID = UserDefaults.standard.string(forKey: "selectedCharacterID") ?? "block_e"

        if let data = UserDefaults.standard.data(forKey: "unlockedCharacters"),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            self.unlockedCharacterIDs = decoded
        } else {
            self.unlockedCharacterIDs = ["block_e"] // Block-E default açık
        }
        
        if let data = UserDefaults.standard.data(forKey: "unlockedUpgrades"),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            self.unlockedUpgradeIDs = decoded
        } else {
            self.unlockedUpgradeIDs = []
        }
        
        if let data = UserDefaults.standard.data(forKey: "goldUpgradeLevels"),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            self.goldUpgradeLevels = decoded
        } else {
            self.goldUpgradeLevels = [:]
        }
        


        // Phase 8 retention state
        self.lastDailyClaimTimestamp = UserDefaults.standard.double(forKey: "lastDailyClaimTimestamp")
        self.dailyStreak = UserDefaults.standard.integer(forKey: "dailyStreak")
        if let data = UserDefaults.standard.data(forKey: "unlockedAchievements"),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.unlockedAchievementIDs = decoded
        } else {
            self.unlockedAchievementIDs = []
        }
        if let data = UserDefaults.standard.data(forKey: "achievementProgress"),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            self.achievementProgress = decoded
        } else {
            self.achievementProgress = [:]
        }
        if let data = UserDefaults.standard.data(forKey: "topScores"),
           let decoded = try? JSONDecoder().decode([LocalScoreEntry].self, from: data) {
            self.topScores = decoded
        } else {
            self.topScores = []
        }
        if let data = UserDefaults.standard.data(forKey: "characterMaxChapter"),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            self.characterMaxChapter = decoded
        } else {
            self.characterMaxChapter = [:]
        }
        if let data = UserDefaults.standard.data(forKey: "characterQuestDay"),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            self.characterQuestDay = decoded
        } else {
            self.characterQuestDay = [:]
        }
        if let data = UserDefaults.standard.data(forKey: "characterQuestProgress"),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            self.characterQuestProgress = decoded
        } else {
            self.characterQuestProgress = [:]
        }
        if let data = UserDefaults.standard.data(forKey: "characterQuestLastAdvanceDay"),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            self.characterQuestLastAdvanceDay = decoded
        } else {
            self.characterQuestLastAdvanceDay = [:]
        }
        if let data = UserDefaults.standard.data(forKey: "ownedCosmetics"),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.ownedCosmeticIDs = decoded
        } else {
            self.ownedCosmeticIDs = []
        }

        // Career Stats init - with error handling
        if let data = UserDefaults.standard.data(forKey: "careerStats") {
            do {
                self.careerStats = try JSONDecoder().decode(CareerStats.self, from: data)
            } catch {
                // Corrupted data, reset to default
                print("[UserEnv] Career stats decode failed: \(error)")
                self.careerStats = CareerStats()
                UserDefaults.standard.removeObject(forKey: "careerStats")
            }
        } else {
            self.careerStats = CareerStats()
        }

        self.trialCharacterLastDay = UserDefaults.standard.string(forKey: "trialCharacterLastDay") ?? ""
        self.trialCharacterIdToday = UserDefaults.standard.string(forKey: "trialCharacterIdToday") ?? ""
        self.trialRunUsedToday = UserDefaults.standard.object(forKey: "trialRunUsedToday") as? Bool ?? false

        // Leaderboard state
        self.username = UserDefaults.standard.string(forKey: "leaderboardUsername") ?? "Player_\(String(DeviceIdentifier.deviceID.prefix(6)))"
        self.isRegistered = UserDefaults.standard.bool(forKey: "leaderboardRegistered")
        self.playerCountryCode = UserDefaults.standard.string(forKey: "playerCountryCode") ?? (Locale.current.region?.identifier ?? "XX")
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.fullName = UserDefaults.standard.string(forKey: "leaderboardFullName") ?? ""
        self.email = UserDefaults.standard.string(forKey: "leaderboardEmail") ?? ""
        self.passwordHash = UserDefaults.standard.string(forKey: "leaderboardPasswordHash") ?? ""

        // Avatar init
        self.selectedAvatarID = UserDefaults.standard.integer(forKey: "selectedAvatarID")
        if let data = UserDefaults.standard.data(forKey: "unlockedAvatars"),
           let decoded = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            self.unlockedAvatarIDs = decoded
        } else {
            // Default unlocked avatars (id 0, 3, 6 are free)
            self.unlockedAvatarIDs = [0, 3, 6]
        }

        // 2. Perform post-init logic (Testing Boost etc.)
        if self.gold < 10000 {
            self.gold = 10000
            UserDefaults.standard.set(10000, forKey: "playerGold")
        }
        if self.diamonds < 50000 {
            self.diamonds = 50000
            UserDefaults.standard.set(50000, forKey: "playerDiamonds")
        }
    }

    // MARK: - Helpers
    func updateHighScore(_ newScore: Int) {
        if newScore > highScore { highScore = newScore }
    }

    /// Gold tek kaynak hakikati aktif slot (SaveSlot.gold). Aktif slot varken
    /// doğrudan `gold -= amount` yazarsak, slot bir sonraki yüklemede altını
    /// geri veriyordu (shop regression). Slot varsa SaveManager üzerinden
    /// gidiyoruz; SaveManager de `UserEnvironment.gold`'u sync'liyor.
    func spend(gold amount: Int) -> Bool {
        guard gold >= amount else { return false }
        if let slotId = activeSlotId {
            SaveManager.shared.updateGold(slotId: slotId, amount: -amount)
        } else {
            gold -= amount
        }
        return true
    }

    func spend(diamonds amount: Int) -> Bool {
        guard diamonds >= amount else { return false }
        if let slotId = activeSlotId {
            SaveManager.shared.updateDiamonds(slotId: slotId, amount: -amount)
        } else {
            diamonds -= amount
        }
        return true
    }

    func earn(gold amount: Int) {
        if let slotId = activeSlotId {
            SaveManager.shared.updateGold(slotId: slotId, amount: amount)
        } else {
            gold += amount
        }
    }
    func earn(diamonds amount: Int) {
        if let slotId = activeSlotId {
            SaveManager.shared.updateDiamonds(slotId: slotId, amount: amount)
        } else {
            diamonds += amount
        }
    }
    
    /// Karakter satın alma mantığı
    func unlockCharacter(_ character: GameCharacter, useDiamonds: Bool) -> Bool {
        if unlockedCharacterIDs.contains(character.id) { return true }
        
        let cost = character.cost
        let success = useDiamonds ? spend(diamonds: cost / 10) : spend(gold: cost) // Elmasla 10 kat daha ucuz (örnek oran)
        
        if success {
            unlockedCharacterIDs.append(character.id)
            HapticManager.shared.play(.success)
            AudioManager.shared.playSFX(.perkUnlock)
            return true
        }
        
        HapticManager.shared.play(.error)
        return false
    }

    func unlockAvatar(_ avatar: AvatarItem) -> Bool {
        if unlockedAvatarIDs.contains(avatar.id) { return true }
        
        if spend(gold: avatar.cost) {
            unlockedAvatarIDs.insert(avatar.id)
            HapticManager.shared.play(.success)
            AudioManager.shared.playSFX(.perkUnlock)
            return true
        }
        
        HapticManager.shared.play(.error)
        return false
    }

    func goldLevel(for upgrade: GoldUpgrade) -> Int {
        goldUpgradeLevels[upgrade.rawValue] ?? 0
    }
    
    func upgradeGold(_ upgrade: GoldUpgrade) -> Bool {
        let currentLevel = goldLevel(for: upgrade)
        guard currentLevel < upgrade.maxLevel else { return false }
        let nextLevel = currentLevel + 1
        let cost = upgrade.cost(for: nextLevel)
        guard spend(gold: cost) else { return false }
        goldUpgradeLevels[upgrade.rawValue] = nextLevel
        syncWithSlot()
        return true
    }
    


    // MARK: - Phase C Discovery Helpers
    
    func discoverPerk(_ id: String) {
        if !discoveredPerkIDs.contains(id) {
            discoveredPerkIDs.insert(id)
            earn(diamonds: 50) // Discovery reward
            AudioManager.shared.playSFX(.perkUnlock)
            reportAchievement("perk_collector_5", progress: discoveredPerkIDs.count)
        }
    }
    
    func discoverBoss(_ id: String) {
        if !discoveredBossIDs.contains(id) {
            discoveredBossIDs.insert(id)
            earn(diamonds: 500) // Boss Discovery reward
            AudioManager.shared.playSFX(.perkUnlock)
        }
        totalBossesDefeated += 1
    }
    
    func addLinesCleared(_ count: Int) {
        totalLinesCleared += count
    }
    
    func addGoldEarned(_ count: Int) {
        totalGoldEarned += count
    }

    // MARK: - Slot Syncing (Phase 11)
    func syncWithSlot() {
        guard let slotId = activeSlotId else { return }
        SaveManager.shared.updateSlotProgression(
            slotId: slotId,
            worldLevel: unlockedWorldLevel,
            goldUpgrades: goldUpgradeLevels,
            metaUpgrades: unlockedUpgradeIDs
        )
    }
    
    func loadFromSlot(_ slot: SaveSlot) {
        self.activeSlotId = slot.id
        self.unlockedWorldLevel = slot.unlockedWorldLevel
        
        // Slot bazlı geliştirmeler:
        self.goldUpgradeLevels = slot.goldUpgradeLevels
        self.unlockedUpgradeIDs = slot.unlockedMetaUpgradeIDs
        
        self.gold = slot.gold
        self.diamonds = slot.diamonds ?? 0
        // Slot bazlı karakter senkronizasyonu
        if let cid = slot.characterId, !cid.isEmpty {
            self.selectedCharacterID = cid
        }
    }

    func setRunConfig(_ config: RunConfig?) {
        runConfig = config
    }

    // MARK: - Trial helpers
    func canStartTrialToday() -> Bool {
        // Yeni gün → reset hissi (id boş olmasa bile)
        if trialCharacterLastDay != todayKey() { return true }
        return !trialRunUsedToday
    }

    func startTrial(characterId: String) {
        guard !characterId.isEmpty else { return }
        trialCharacterLastDay = todayKey()
        trialCharacterIdToday = characterId
        trialRunUsedToday = false
        HapticManager.shared.play(.success)
        AudioManager.shared.playSFX(.perkUnlock)
    }

    func isTrialCharacterAvailableNow(_ characterId: String) -> Bool {
        guard trialCharacterLastDay == todayKey(),
              trialCharacterIdToday == characterId,
              !trialRunUsedToday else { return false }
        return true
    }

    func consumeTrialRunIfNeeded(selectedCharacterId: String) {
        guard isTrialCharacterAvailableNow(selectedCharacterId) else { return }
        trialRunUsedToday = true
    }

    func wasTrialRunUsedToday(for characterId: String) -> Bool {
        guard !characterId.isEmpty else { return false }
        return trialCharacterLastDay == todayKey()
            && trialCharacterIdToday == characterId
            && trialRunUsedToday
    }

    /// Aktif slot bağlamını kapatır. Dashboard'a dönerken çağrılır.
    func clearActiveSlot() {
        self.activeSlotId = nil
    }

    /// Oyun kazanılınca MapView'e dönüşte tamamlanacak node.
    /// In-memory only — force-close sonrasında nil olur, node accessible kalır (retry).
    var pendingMapNodeId: UUID? = nil

    // MARK: - Event / Duel Score Persistence
    // Her event için "oynandı" ve "son puan" bilgisi UserDefaults'ta saklanır.
    // Key formatı: "event_played_<eventId>" ve "event_score_<eventId>"
    // Oyun başlar başlamaz markalanır → çıkıp girince tekrar oynanamaz.

    /// Event'i "oynanmış" olarak işaretle (oyun başladığında çağır).
    func markEventStarted(_ eventId: String) {
        UserDefaults.standard.set(true, forKey: "event_played_\(eventId)")
        DispatchQueue.main.async { self.objectWillChange.send() }
    }

    /// Event için son puanı kaydet (oyun bittiğinde çağır).
    func saveEventScore(_ eventId: String, score: Int) {
        // Mevcut kayıtlı puana bakma — en son oynanan geçerli, ragequit da dahil.
        UserDefaults.standard.set(score, forKey: "event_score_\(eventId)")
        DispatchQueue.main.async { self.objectWillChange.send() }
    }

    /// Event daha önce oynandı mı?
    func hasPlayedEvent(_ eventId: String) -> Bool {
        UserDefaults.standard.bool(forKey: "event_played_\(eventId)")
    }

    /// Event için kaydedilmiş son puan (oynanmadıysa nil).
    func savedEventScore(_ eventId: String) -> Int? {
        guard hasPlayedEvent(eventId) else { return nil }
        let score = UserDefaults.standard.integer(forKey: "event_score_\(eventId)")
        return score
    }
    
    func localizedString(_ trText: String, _ enText: String) -> String {
        language == .turkish ? trText : enText
    }

    // MARK: - Dynamic Localization Properties (Migration Guide)
    var labelIncomingAttack: String {
        switch language {
        case .turkish: return "Saldırı geliyor"
        case .english: return "Incoming attack"
        }
    }

    var labelRound: String {
        switch language {
        case .turkish: return "TUR"
        case .english: return "ROUND"
        }
    }

    var labelComplete: String {
        switch language {
        case .turkish: return "TAMAMLANDI"
        case .english: return "COMPLETE"
        }
    }

    var labelBestScore: String {
        switch language {
        case .turkish: return "En İyi"
        case .english: return "Best"
        }
    }

    var labelNextRound: String {
        switch language {
        case .turkish: return "Sonraki tur"
        case .english: return "Next round in"
        }
    }

    var labelSecondsSuffix: String {
        switch language {
        case .turkish: return "s sonra…"
        case .english: return "s..."
        }
    }

    var labelTapToSkip: String {
        switch language {
        case .turkish: return "Atlamak için dokun"
        case .english: return "Tap to skip"
        }
    }

    var labelCyberKnight: String {
        switch language {
        case .turkish: return "SİBER ŞÖVALYE"
        case .english: return "CYBER KNIGHT"
        }
    }

    var labelBossPowerWarning: String {
        switch language {
        case .turkish: return "ÖZEL GÜÇ UYARISI"
        case .english: return "SPECIAL POWER WARNING"
        }
    }

    var btnContinue: String {
        switch language {
        case .turkish: return "DEVAM ET"
        case .english: return "CONTINUE"
        }
    }

    var btnInitiateCombat: String {
        switch language {
        case .turkish: return "SAVAŞI BAŞLAT"
        case .english: return "INITIATE COMBAT"
        }
    }

    var labelModifierFogTitle: String {
        switch language {
        case .turkish: return "SİSTEM KARARMASI (FOG)"
        case .english: return "SYSTEM BLACKOUT (FOG)"
        }
    }

    var labelModifierGlitchTitle: String {
        switch language {
        case .turkish: return "HÜCRE KİLİDİ (GLITCH)"
        case .english: return "CELL LOCK (GLITCH)"
        }
    }

    var labelModifierWeightTitle: String {
        switch language {
        case .turkish: return "AĞIR ÇEKİM (WEIGHT)"
        case .english: return "HEAVY GRAVITY (WEIGHT)"
        }
    }

    var labelModifierPhantomTitle: String {
        switch language {
        case .turkish: return "HAYALET BLOKLAR (PHANTOM)"
        case .english: return "GHOST BLOCKS (PHANTOM)"
        }
    }

    var labelModifierFogDesc: String {
        switch language {
        case .turkish: return "Süre barı gizlenir ve oyun tablası hacklenip kararır."
        case .english: return "Timer bar is hidden and grid gets hacked & dimmed."
        }
    }

    var labelModifierGlitchDesc: String {
        switch language {
        case .turkish: return "Bazı hücreler kilitlenir, oralara blok koyılamaz."
        case .english: return "Some cells are locked, blocking block placement."
        }
    }

    var labelModifierWeightDesc: String {
        switch language {
        case .turkish: return "Bloklar ağırdır, yok etmek için 2 kere patlatmak gerekir."
        case .english: return "Blocks are heavy. Requires 2 clears to break."
        }
    }

    var labelModifierPhantomDesc: String {
        switch language {
        case .turkish: return "Yerleştirilen bloklar ara sıra görünmez olur."
        case .english: return "Placed blocks will flicker and become invisible."
        }
    }

    var labelScore: String {
        switch language {
        case .turkish: return "PUAN"
        case .english: return "SCORE"
        }
    }

    var labelMult: String {
        switch language {
        case .turkish: return "Çarpan"
        case .english: return "Mult"
        }
    }

    // MARK: - Social Module Localization Properties
    var labelYourTurn: String {
        switch language {
        case .turkish: return "Sıra sende"
        case .english: return "Your turn"
        }
    }

    var labelOpponentPlaying: String {
        switch language {
        case .turkish: return "Rakip oynuyor"
        case .english: return "Opponent playing"
        }
    }

    var labelDuelResult: String {
        switch language {
        case .turkish: return "DÜELLO SONUCU"
        case .english: return "DUEL RESULT"
        }
    }

    var labelCongratulations: String {
        switch language {
        case .turkish: return "Tebrikler!"
        case .english: return "Congratulations!"
        }
    }

    var labelNextTime: String {
        switch language {
        case .turkish: return "Bir dahaki sefere!"
        case .english: return "Next time!"
        }
    }

    var labelYouWon: String {
        switch language {
        case .turkish: return "KAZANDIN!"
        case .english: return "YOU WON!"
        }
    }

    var labelYouLost: String {
        switch language {
        case .turkish: return "KAYBETTİN"
        case .english: return "YOU LOST"
        }
    }

    var labelYourScore: String {
        switch language {
        case .turkish: return "SENİN SKORUN"
        case .english: return "YOUR SCORE"
        }
    }

    var labelOpponentScore: String {
        switch language {
        case .turkish: return "RAKİP SKORU"
        case .english: return "OPPONENT SCORE"
        }
    }

    var labelYourStats: String {
        switch language {
        case .turkish: return "SENİN İSTATİSTİKLERİN"
        case .english: return "YOUR STATS"
        }
    }

    var labelOpponentStats: String {
        switch language {
        case .turkish: return "RAKİP İSTATİSTİKLERİ"
        case .english: return "OPPONENT STATS"
        }
    }

    var btnGoBack: String {
        switch language {
        case .turkish: return "GERİ DÖN"
        case .english: return "GO BACK"
        }
    }

    var labelLinesCleared: String {
        switch language {
        case .turkish: return "Açık Satır"
        case .english: return "Lines Cleared"
        }
    }

    var labelZones: String {
        switch language {
        case .turkish: return "Bölge"
        case .english: return "Zones"
        }
    }

    var labelMaxCombo: String {
        switch language {
        case .turkish: return "Max Kombo"
        case .english: return "Max Combo"
        }
    }

    var labelBlocksPlaced: String {
        switch language {
        case .turkish: return "Blok Yerleştirme"
        case .english: return "Blocks Placed"
        }
    }

    var labelGold: String {
        switch language {
        case .turkish: return "Altın"
        case .english: return "Gold"
        }
    }

    var labelDuration: String {
        switch language {
        case .turkish: return "Süre"
        case .english: return "Duration"
        }
    }

    var labelSocial: String {
        switch language {
        case .turkish: return "SOSYAL"
        case .english: return "SOCIAL"
        }
    }

    var labelFriendsAndDuels: String {
        switch language {
        case .turkish: return "Arkadaşlar & Düellolar"
        case .english: return "Friends & Duels"
        }
    }

    var labelFriends: String {
        switch language {
        case .turkish: return "ARKADAŞLAR"
        case .english: return "FRIENDS"
        }
    }

    var labelDuels: String {
        switch language {
        case .turkish: return "DÜELLOLAR"
        case .english: return "DUELS"
        }
    }

    var labelNoFriendsYet: String {
        switch language {
        case .turkish: return "Henüz arkadaşın yok"
        case .english: return "No friends yet"
        }
    }

    var labelShareInviteCode: String {
        switch language {
        case .turkish: return "Davet kodunu paylaşarak arkadaş ekle!"
        case .english: return "Share your invite code to add friends!"
        }
    }

    var btnShareYourInvite: String {
        switch language {
        case .turkish: return "DAVETİNİ PAYLAŞ"
        case .english: return "SHARE YOUR INVITE"
        }
    }

    var labelCopied: String {
        switch language {
        case .turkish: return "KOPYALANDI"
        case .english: return "COPIED"
        }
    }

    var labelCopy: String {
        switch language {
        case .turkish: return "KOPYALA"
        case .english: return "COPY"
        }
    }

    var labelIncomingChallenges: String {
        switch language {
        case .turkish: return "GELEN DAVETLER"
        case .english: return "INCOMING CHALLENGES"
        }
    }

    var labelActiveDuels: String {
        switch language {
        case .turkish: return "AKTİF DÜELLOLAR"
        case .english: return "ACTIVE DUELS"
        }
    }

    var labelHistory: String {
        switch language {
        case .turkish: return "GEÇMİŞ"
        case .english: return "HISTORY"
        }
    }

    var labelNoDuelsYet: String {
        switch language {
        case .turkish: return "Henüz düellon yok"
        case .english: return "No duels yet"
        }
    }

    var labelChallengeYourFriends: String {
        switch language {
        case .turkish: return "Arkadaşlarına düello at!"
        case .english: return "Challenge your friends!"
        }
    }

    var labelChallengesYou: String {
        switch language {
        case .turkish: return "sana meydan okuyor!"
        case .english: return "challenges you!"
        }
    }

    var labelStake: String {
        switch language {
        case .turkish: return "Bahis:"
        case .english: return "Stake:"
        }
    }

    var btnDecline: String {
        switch language {
        case .turkish: return "RET"
        case .english: return "DECLINE"
        }
    }

    var btnAccept: String {
        switch language {
        case .turkish: return "KABUL ET"
        case .english: return "ACCEPT"
        }
    }

    var labelWonWon: String {
        switch language {
        case .turkish: return "KAZANDIN"
        case .english: return "WON"
        }
    }

    var labelLostLost: String {
        switch language {
        case .turkish: return "KAYBETTİN"
        case .english: return "LOST"
        }
    }

    var labelDuelDetails: String {
        switch language {
        case .turkish: return "DÜELLO DETAYI"
        case .english: return "DUEL DETAILS"
        }
    }

    var labelStakeAmount: String {
        switch language {
        case .turkish: return "BAHİS MİKTARI"
        case .english: return "STAKE AMOUNT"
        }
    }

    var labelGoldUnit: String {
        switch language {
        case .turkish: return "Altın"
        case .english: return "Gold"
        }
    }

    var labelPotential: String {
        switch language {
        case .turkish: return "POTANSİYEL"
        case .english: return "POTENTIAL"
        }
    }

    var labelStatus: String {
        switch language {
        case .turkish: return "DURUM"
        case .english: return "STATUS"
        }
    }

    var labelPlayed: String {
        switch language {
        case .turkish: return "Oynadı ✓"
        case .english: return "Played ✓"
        }
    }

    var labelWaiting: String {
        switch language {
        case .turkish: return "Bekliyor"
        case .english: return "Waiting"
        }
    }

    var btnStartGame: String {
        switch language {
        case .turkish: return "OYUNU BAŞLAT"
        case .english: return "START GAME"
        }
    }

    var btnViewResults: String {
        switch language {
        case .turkish: return "SONUÇLARI GÖR"
        case .english: return "VIEW RESULTS"
        }
    }

    var labelWaitingOpponent: String {
        switch language {
        case .turkish: return "Rakibin oynaması bekleniyor..."
        case .english: return "Waiting for opponent to play..."
        }
    }

    var labelStartDuel: String {
        switch language {
        case .turkish: return "DÜELLO BAŞLAT"
        case .english: return "START DUEL"
        }
    }

    var labelChallengeSingle: String {
        switch language {
        case .turkish: return "Meydan oku"
        case .english: return "Challenge"
        }
    }

    var labelRank: String {
        switch language {
        case .turkish: return "Sıra"
        case .english: return "Rank"
        }
    }

    var labelSelectStake: String {
        switch language {
        case .turkish: return "BAHİS SEÇ"
        case .english: return "SELECT STAKE"
        }
    }

    var btnChallenge: String {
        switch language {
        case .turkish: return "MEYDAN OKU"
        case .english: return "CHALLENGE"
        }
    }

    var labelOnline: String {
        switch language {
        case .turkish: return "Çevrimiçi"
        case .english: return "Online"
        }
    }

    var labelOffline: String {
        switch language {
        case .turkish: return "Çevrimdışı"
        case .english: return "Offline"
        }
    }

    var labelPending: String {
        switch language {
        case .turkish: return "BEKLİYOR"
        case .english: return "PENDING"
        }
    }

    var btnDuel: String {
        switch language {
        case .turkish: return "DÜELLO"
        case .english: return "DUEL"
        }
    }

    // MARK: - Store Module Localization Properties
    var titleConfirmPurchase: String {
        switch language {
        case .turkish: return "Satın Alma Onayı"
        case .english: return "Confirm Purchase"
        }
    }

    var btnCancel: String {
        switch language {
        case .turkish: return "İptal"
        case .english: return "Cancel"
        }
    }

    var labelStoreTitle: String {
        switch language {
        case .turkish: return "MAĞAZA"
        case .english: return "STORE"
        }
    }

    var labelRealMoney: String {
        switch language {
        case .turkish: return "GERÇEK PARA İLE"
        case .english: return "REAL MONEY"
        }
    }

    var labelGoldCaps: String {
        switch language {
        case .turkish: return "ALTIN"
        case .english: return "GOLD"
        }
    }

    var labelDiamondsCaps: String {
        switch language {
        case .turkish: return "ELMAS"
        case .english: return "GEMS"
        }
    }

    var labelCosmeticUnlock: String {
        switch language {
        case .turkish: return "Kozmetik kilidi açılır"
        case .english: return "Cosmetic unlock"
        }
    }

    var labelOwned: String {
        switch language {
        case .turkish: return "SAHİP"
        case .english: return "OWNED"
        }
    }

    var labelPurchasesTiedToAccount: String {
        switch language {
        case .turkish: return "Satın alımlar hesabınıza bağlıdır."
        case .english: return "Purchases are tied to your account."
        }
    }

    var labelRestoreTermsPrivacy: String {
        switch language {
        case .turkish: return "Geri Yükle · Kullanım Şartları · Gizlilik"
        case .english: return "Restore · Terms · Privacy"
        }
    }

    // MARK: - Career Module Localization Properties
    var labelCareerTitle: String {
        switch language {
        case .turkish: return "KARİYER"
        case .english: return "CAREER"
        }
    }

    var tabCareerOverall: String {
        switch language {
        case .turkish: return "📊 Genel"
        case .english: return "📊 Overall"
        }
    }

    var tabCareerCharacters: String {
        switch language {
        case .turkish: return "🎮 Karakterler"
        case .english: return "🎮 Characters"
        }
    }

    var tabCareerPerks: String {
        switch language {
        case .turkish: return "✨ Perkler"
        case .english: return "✨ Perks"
        }
    }

    var tabCareerTitles: String {
        switch language {
        case .turkish: return "🏆 Unvanlar"
        case .english: return "🏆 Titles"
        }
    }

    // MARK: - Career Stats Module Localization Properties
    var labelTotalDamage: String {
        switch language {
        case .turkish: return "TOPLAM HASAR"
        case .english: return "TOTAL DAMAGE"
        }
    }

    var labelTotalLinesCleared: String {
        switch language {
        case .turkish: return "SATIR TEMİZLEDİ"
        case .english: return "LINES CLEARED"
        }
    }

    var labelTotalBossesDefeated: String {
        switch language {
        case .turkish: return "BOSS YENDİ"
        case .english: return "BOSSES DEFEATED"
        }
    }

    var labelTotalRuns: String {
        switch language {
        case .turkish: return "TOPLAM KOŞU"
        case .english: return "TOTAL RUNS"
        }
    }

    var labelTotalPlaytime: String {
        switch language {
        case .turkish: return "TOPLAM OYUN SÜRESİ"
        case .english: return "TOTAL PLAYTIME"
        }
    }

    var labelFavoriteCharacter: String {
        switch language {
        case .turkish: return "EN SEVDİĞİ KARAKTERİ"
        case .english: return "FAVORITE CHARACTER"
        }
    }

    var labelMostUsedPerk: String {
        switch language {
        case .turkish: return "EN ÇOK KULLANILAN PERK"
        case .english: return "MOST USED PERK"
        }
    }

    // MARK: - Character Stats Module Localization Properties
    var labelNoCharactersPlayed: String {
        switch language {
        case .turkish: return "Henüz hiçbir karakter oynanmadı"
        case .english: return "No characters played yet"
        }
    }

    var labelRunsCountCaps: String {
        switch language {
        case .turkish: return "KOŞU SAYISI"
        case .english: return "RUNS"
        }
    }

    var labelAvgScoreCaps: String {
        switch language {
        case .turkish: return "ORJ. SKOR"
        case .english: return "AVG SCORE"
        }
    }

    var labelHighestScoreCaps: String {
        switch language {
        case .turkish: return "EN YÜKSEK"
        case .english: return "HIGHEST"
        }
    }

    var labelDamageCaps: String {
        switch language {
        case .turkish: return "HASAR"
        case .english: return "DAMAGE"
        }
    }

    var labelNoPerksUsed: String {
        switch language {
        case .turkish: return "Henüz hiçbir perk kullanılmadı"
        case .english: return "No perks used yet"
        }
    }

    var labelUnlockedCaps: String {
        switch language {
        case .turkish: return "KAZANILANLAR"
        case .english: return "UNLOCKED"
        }
    }

    // MARK: - Character Shop & Selection Localization Properties
    var labelHeroes: String {
        switch language {
        case .turkish: return "KAHRAMANLAR"
        case .english: return "HEROES"
        }
    }

    var labelRecruitYourTeam: String {
        switch language {
        case .turkish: return "EKİBİNİ KUR"
        case .english: return "RECRUIT YOUR TEAM"
        }
    }

    var labelPassiveCaps: String {
        switch language {
        case .turkish: return "PASİF"
        case .english: return "PASSIVE"
        }
    }

    var labelActiveCaps: String {
        switch language {
        case .turkish: return "AKTİF"
        case .english: return "ACTIVE"
        }
    }

    var labelHeroRecruited: String {
        switch language {
        case .turkish: return "BU KAHRAMAN EKİBİNDE!"
        case .english: return "HERO RECRUITED!"
        }
    }

    var labelCharacter: String {
        switch language {
        case .turkish: return "KARAKTER"
        case .english: return "CHARACTER"
        }
    }

    var labelSelectThisCharacter: String {
        switch language {
        case .turkish: return "BU KARAKTERİ SEÇ"
        case .english: return "SELECT THIS CHARACTER"
        }
    }

    var labelSelectAndContinue: String {
        switch language {
        case .turkish: return "SEÇ VE DEVAM ET"
        case .english: return "SELECT & CONTINUE"
        }
    }

    var labelTrialFreeOneRun: String {
        switch language {
        case .turkish: return "TRIAL (ÜCRETSİZ) — 1 RUN"
        case .english: return "TRIAL (FREE) — 1 RUN"
        }
    }

    var labelDifficultyCaps: String {
        switch language {
        case .turkish: return "ZORLUK"
        case .english: return "DIFFICULTY"
        }
    }

    var labelStrongPointCaps: String {
        switch language {
        case .turkish: return "GÜÇLÜ YÖN"
        case .english: return "STRONG POINT"
        }
    }

    var labelFavoriteBlockCaps: String {
        switch language {
        case .turkish: return "FAVORİ BLOK"
        case .english: return "FAVORITE BLOCK"
        }
    }

    var labelPassiveAbilityCaps: String {
        switch language {
        case .turkish: return "PASİF YETENEK"
        case .english: return "PASSIVE ABILITY"
        }
    }

    var labelActiveAbilityOverdriveCaps: String {
        switch language {
        case .turkish: return "AKTİF YETENEK (OVERDRIVE)"
        case .english: return "ACTIVE ABILITY (OVERDRIVE)"
        }
    }

    var labelGoToShop: String {
        switch language {
        case .turkish: return "MAĞAZAYA GİT"
        case .english: return "GO TO SHOP"
        }
    }

    // MARK: - Upgrades & Market Localization Properties
    var labelUpgradesCaps: String {
        switch language {
        case .turkish: return "MARKET"
        case .english: return "UPGRADES"
        }
    }

    var labelPermanentUpgrades: String {
        switch language {
        case .turkish: return "KALICI GELİŞTİRMELER"
        case .english: return "PERMANENT UPGRADES"
        }
    }

    var labelPermanentUpgradesDesc: String {
        switch language {
        case .turkish: return "Tek seferlik satın al, sonsuza kadar aktif."
        case .english: return "Buy once, active forever."
        }
    }

    var labelPassiveBoosts: String {
        switch language {
        case .turkish: return "PASİF GÜÇLENDİRMELER"
        case .english: return "PASSIVE BOOSTS"
        }
    }

    var labelPassiveBoostsDesc: String {
        switch language {
        case .turkish: return "Seviye atla, etkisi artsın. Max. Seviye: 5"
        case .english: return "Level up for stronger effect. Max Level: 5"
        }
    }

    var labelNextTemplate: String {
        switch language {
        case .turkish: return "Sonraki: {{desc}}"
        case .english: return "Next: {{desc}}"
        }
    }

    var btnUnlockWithGold: String {
        switch language {
        case .turkish: return "ALTIN İLE AÇ"
        case .english: return "UNLOCK WITH GOLD"
        }
    }

    var btnUnlockWithDiamond: String {
        switch language {
        case .turkish: return "ELMAS İLE AÇ"
        case .english: return "UNLOCK WITH DIAMOND"
        }
    }

    var labelReachLevelTemplate: String {
        switch language {
        case .turkish: return "SEVİYE {{level}} GEREKLİ"
        case .english: return "REACH LEVEL {{level}}"
        }
    }

    // MARK: - Events Localization Properties
    var labelNoDailyChallenges: String {
        switch language {
        case .turkish: return "Hiçbir günlük challenge aktif değil"
        case .english: return "No daily challenges active"
        }
    }

    var labelNoWeeklyChallenges: String {
        switch language {
        case .turkish: return "Hiçbir haftalık challenge aktif değil"
        case .english: return "No weekly challenges active"
        }
    }

    var labelChallengesLoading: String {
        switch language {
        case .turkish: return "Challenge'lar yükleniyor..."
        case .english: return "Loading challenges..."
        }
    }

    var titleChallengeCaps: String {
        switch language {
        case .turkish: return "CHALLENGE"
        case .english: return "CHALLENGE"
        }
    }

    var labelSpecialModes: String {
        switch language {
        case .turkish: return "Özel Modlar"
        case .english: return "Special Modes"
        }
    }

    var labelEndingInCaps: String {
        switch language {
        case .turkish: return "BİTMESİNE"
        case .english: return "ENDING IN"
        }
    }

    var labelCompletedCaps: String {
        switch language {
        case .turkish: return "TAMAMLANDI"
        case .english: return "COMPLETED"
        }
    }

    var labelDetailsCaps: String {
        switch language {
        case .turkish: return "DETAYLAR"
        case .english: return "DETAILS"
        }
    }

    var btnExamineCaps: String {
        switch language {
        case .turkish: return "İNCELEYİN"
        case .english: return "EXAMINE"
        }
    }

    var labelGameModifiers: String {
        switch language {
        case .turkish: return "OYUN MODİFİYELERİ"
        case .english: return "GAME MODIFIERS"
        }
    }

    var labelSpecialCharacter: String {
        switch language {
        case .turkish: return "ÖZEL KARAKTER"
        case .english: return "SPECIAL CHARACTER"
        }
    }

    var labelRankingRewards: String {
        switch language {
        case .turkish: return "SIRALAMA ÖDÜLLERİ"
        case .english: return "RANKING REWARDS"
        }
    }

    var labelYourBestScore: String {
        switch language {
        case .turkish: return "ÜST PUANINIZ"
        case .english: return "YOUR BEST SCORE"
        }
    }

    var labelChallengeCompleted: String {
        switch language {
        case .turkish: return "MEYDAN OKUMA TAMAMLANDI"
        case .english: return "CHALLENGE COMPLETED"
        }
    }

    var btnStartChallenge: String {
        switch language {
        case .turkish: return "MEYDAN OKUMAYA BAŞLA"
        case .english: return "START CHALLENGE"
        }
    }

    var labelSabotageAbilitiesTemplate: String {
        switch language {
        case .turkish: return "SABOTAJ YETENEKLERİ (Her {{value}} Roundda)"
        case .english: return "SABOTAGE ABILITIES (Every {{value}} Rounds)"
        }
    }

    var labelExclusive: String {
        switch language {
        case .turkish: return "ÖZEL"
        case .english: return "EXCLUSIVE"
        }
    }

    var labelCharacterBonuses: String {
        switch language {
        case .turkish: return "KARAKTER BONUSLARI"
        case .english: return "CHARACTER BONUSES"
        }
    }

    var labelChampionReward: String {
        switch language {
        case .turkish: return "Şampiyon Ödülü"
        case .english: return "Champion Reward"
        }
    }

    var labelRankingReward: String {
        switch language {
        case .turkish: return "Sıralama Ödülü"
        case .english: return "Ranking Reward"
        }
    }

    var labelRoundCaps: String {
        switch language {
        case .turkish: return "ROUND"
        case .english: return "ROUND"
        }
    }

    var labelNextPerkCaps: String {
        switch language {
        case .turkish: return "SIRADAKİ"
        case .english: return "NEXT PERK"
        }
    }

    var labelBossLockCells: String {
        switch language {
        case .turkish: return "BOSS: HÜCRELER KİLİTLENDİ!"
        case .english: return "BOSS: CELLS LOCKED!"
        }
    }

    var labelBossStealTime: String {
        switch language {
        case .turkish: return "BOSS: PUAN ÇALINDI!"
        case .english: return "BOSS: SCORE STOLEN!"
        }
    }

    var labelBossBlockTray: String {
        switch language {
        case .turkish: return "BOSS: TRAY KİLİTLENDİ!"
        case .english: return "BOSS: TRAY LOCKED!"
        }
    }

    var labelBossAddJunkRow: String {
        switch language {
        case .turkish: return "BOSS: ÇÖP SATIRI!"
        case .english: return "BOSS: JUNK ROW ADDED!"
        }
    }

    var labelBossShuffleBoard: String {
        switch language {
        case .turkish: return "BOSS: TAHTA KARIŞTI!"
        case .english: return "BOSS: BOARD SHUFFLED!"
        }
    }

    var labelBossInvertControls: String {
        switch language {
        case .turkish: return "BOSS: KONTROLLER TERS!"
        case .english: return "BOSS: CONTROLS INVERTED!"
        }
    }

    var labelRoundCompleteCaps: String {
        switch language {
        case .turkish: return "TUR TAMAMLANDI!"
        case .english: return "ROUND COMPLETE!"
        }
    }

    var labelChooseAPerk: String {
        switch language {
        case .turkish: return "Bir güçlendirme seç"
        case .english: return "Choose a perk"
        }
    }

    var btnSelectAndContinue: String {
        switch language {
        case .turkish: return "SEÇ VE DEVAM ET →"
        case .english: return "SELECT AND CONTINUE →"
        }
    }

    var labelGameOverCaps: String {
        switch language {
        case .turkish: return "OYUN BİTTİ"
        case .english: return "GAME OVER"
        }
    }

    var labelChallengeEnded: String {
        switch language {
        case .turkish: return "Meydan okuma sona erdi"
        case .english: return "The challenge has ended"
        }
    }

    var labelRankingCaps: String {
        switch language {
        case .turkish: return "SIRALAMA"
        case .english: return "RANKING"
        }
    }

    var labelGoldEarnedCaps: String {
        switch language {
        case .turkish: return "KAZANILAN ALTIN"
        case .english: return "GOLD EARNED"
        }
    }

    var btnBackToMenuCaps: String {
        switch language {
        case .turkish: return "ANA MENÜYE DÖN"
        case .english: return "BACK TO MENU"
        }
    }

    var titleEventRankingCaps: String {
        switch language {
        case .turkish: return "ETKİNLİK SIRALAMASI"
        case .english: return "EVENT RANKING"
        }
    }

    // MARK: - Leaderboard Row & State Localization Properties
    var labelChapterTemplate: String {
        switch language {
        case .turkish: return "Bölüm {{value}}"
        case .english: return "Chapter {{value}}"
        }
    }

    var labelChShortTemplate: String {
        switch language {
        case .turkish: return "Böl.{{value}}"
        case .english: return "Ch.{{value}}"
        }
    }

    var labelNewRecordCaps: String {
        switch language {
        case .turkish: return "YENİ REKOR!"
        case .english: return "NEW BEST!"
        }
    }

    var labelGlobal: String {
        switch language {
        case .turkish: return "Global"
        case .english: return "Global"
        }
    }

    var labelCountry: String {
        switch language {
        case .turkish: return "Ülke"
        case .english: return "Country"
        }
    }

    var btnSaveScore: String {
        switch language {
        case .turkish: return "Skorlarını Kaydet"
        case .english: return "Save Score"
        }
    }

    var labelLoadingEllipsis: String {
        switch language {
        case .turkish: return "Yükleniyor…"
        case .english: return "Loading…"
        }
    }

    var labelNoScoresYet: String {
        switch language {
        case .turkish: return "Henüz skor yok."
        case .english: return "No scores yet."
        }
    }

    var labelNoInternetConnection: String {
        switch language {
        case .turkish: return "İnternet bağlantısı bulunamadı"
        case .english: return "No internet connection"
        }
    }

    var btnRetry: String {
        switch language {
        case .turkish: return "Tekrar Dene"
        case .english: return "Retry"
        }
    }

    // MARK: - Existing Account Login Localization Properties
    var titleLoginAccount: String {
        switch language {
        case .turkish: return "Hesabıma Giriş Yap"
        case .english: return "Log In to My Account"
        }
    }

    var labelLoginAccountDesc: String {
        switch language {
        case .turkish: return "Var olan e-posta adresinizle giriş yapın ve skorlarınızı transfer edin."
        case .english: return "Log in with your existing email and transfer your scores."
        }
    }

    var labelEmailPlaceholder: String {
        switch language {
        case .turkish: return "E-Posta Adresi"
        case .english: return "Email Address"
        }
    }

    var labelInvalidEmail: String {
        switch language {
        case .turkish: return "Geçerli bir e-posta giriniz."
        case .english: return "Enter a valid email address."
        }
    }

    var labelPasswordPlaceholder: String {
        switch language {
        case .turkish: return "Şifre"
        case .english: return "Password"
        }
    }

    var labelLoginScoreLinkInfo: String {
        switch language {
        case .turkish: return "Bu kullanıcı adı ile oynanan tüm skorlar hesabınıza bağlanacak."
        case .english: return "All scores played with this username will be linked to your account."
        }
    }

    var labelLoggingInCaps: String {
        switch language {
        case .turkish: return "GİRİŞ YAPILIYOR..."
        case .english: return "LOGGING IN..."
        }
    }

    var labelLogInCaps: String {
        switch language {
        case .turkish: return "GİRİŞ YAP"
        case .english: return "LOG IN"
        }
    }

    var btnCancelCaps: String {
        switch language {
        case .turkish: return "İPTAL"
        case .english: return "CANCEL"
        }
    }

    var labelEmailNotPersisted: String {
        switch language {
        case .turkish: return "Bu e-posta bu cihazda kayıtlı değil."
        case .english: return "This email is not registered on this device."
        }
    }

    var labelEmailOrPasswordIncorrect: String {
        switch language {
        case .turkish: return "E-posta veya şifre yanlış."
        case .english: return "Email or password is incorrect."
        }
    }

    var labelLoginSuccessful: String {
        switch language {
        case .turkish: return "Giriş başarılı!"
        case .english: return "Login successful!"
        }
    }

    // MARK: - Leaderboard Tab Content Localization Properties
    var labelLeaderboardCaps: String {
        switch language {
        case .turkish: return "SIRALAMA"
        case .english: return "LEADERBOARD"
        }
    }

    var labelLeaderboardDesc: String {
        switch language {
        case .turkish: return "En iyi oyuncular burada yarışıyor"
        case .english: return "The best players compete here"
        }
    }

    var labelPersonalBestsCaps: String {
        switch language {
        case .turkish: return "KİŞİSEL EN İYİLER"
        case .english: return "PERSONAL BESTS"
        }
    }

    var labelUnrankedInfo: String {
        switch language {
        case .turkish: return "Henüz global bir sıralaman yok.\nOyun oyna ve skorun otomatik yüklensin!"
        case .english: return "You don't have a global rank yet.\nPlay a game and your score will be uploaded!"
        }
    }

    var labelPublishScoresTitle: String {
        switch language {
        case .turkish: return "Skorlarını Dünyaya Aç!"
        case .english: return "Publish Your Scores!"
        }
    }

    var labelPublishScoresDesc: String {
        switch language {
        case .turkish: return "Kaydol ve ödüller kazan."
        case .english: return "Sign up and earn rewards."
        }
    }

    var labelNoRankingsYet: String {
        switch language {
        case .turkish: return "Henüz sıralama yok."
        case .english: return "No rankings yet."
        }
    }

    var btnRefresh: String {
        switch language {
        case .turkish: return "Yenile"
        case .english: return "Refresh"
        }
    }

    var labelConnectionError: String {
        switch language {
        case .turkish: return "Bağlantı Hatası"
        case .english: return "Connection Error"
        }
    }

    var labelCheckConnectionDesc: String {
        switch language {
        case .turkish: return "Lütfen internet bağlantınızı kontrol edin."
        case .english: return "Please check your internet connection."
        }
    }

    var btnTryAgain: String {
        switch language {
        case .turkish: return "Tekrar Dene"
        case .english: return "Try Again"
        }
    }

    var labelGlobalRankings: String {
        switch language {
        case .turkish: return "Global Sıralama"
        case .english: return "Global Rankings"
        }
    }

    var labelCountryRankingsTemplate: String {
        switch language {
        case .turkish: return "{{code}} Sıralaması"
        case .english: return "{{code}} Rankings"
        }
    }

    var labelWorldLevelTemplate: String {
        switch language {
        case .turkish: return "Dünya {{value}}"
        case .english: return "World {{value}}"
        }
    }

    // MARK: - Collection Tab Localization Properties
    var labelCollectionCaps: String {
        switch language {
        case .turkish: return "KOLEKSİYON"
        case .english: return "COLLECTION"
        }
    }


    var labelHighScore: String {
        switch language {
        case .turkish: return "En Yüksek Skor"
        case .english: return "High Score"
        }
    }

    var labelTotalGoldEarned: String {
        switch language {
        case .turkish: return "Toplam Altın Kazancı"
        case .english: return "Total Gold Earned"
        }
    }


    var labelBossesDefeated: String {
        switch language {
        case .turkish: return "Yenilen Bosslar"
        case .english: return "Bosses Defeated"
        }
    }

    var labelPerksDiscovered: String {
        switch language {
        case .turkish: return "Keşfedilen Perkler"
        case .english: return "Perks Discovered"
        }
    }

    var labelLoginStreak: String {
        switch language {
        case .turkish: return "Giriş Serisi"
        case .english: return "Login Streak"
        }
    }

    var labelDaysSuffix: String {
        switch language {
        case .turkish: return "gün"
        case .english: return "days"
        }
    }

    var labelCharacterQuestsCaps: String {
        switch language {
        case .turkish: return "KARAKTER GÖREVLERİ"
        case .english: return "CHARACTER QUESTS"
        }
    }

    var labelCharacterQuestsDesc: String {
        switch language {
        case .turkish: return "Her karakter için 7 günlük zincir. Her karakter günde 1 adım ilerler."
        case .english: return "A 7-day chain per character. Each character advances 1 step per day."
        }
    }

    var labelQuestDayTemplate: String {
        switch language {
        case .turkish: return "GÜN {{day}}/7"
        case .english: return "DAY {{day}}/7"
        }
    }

    var labelTomorrowCaps: String {
        switch language {
        case .turkish: return "YARIN"
        case .english: return "TOMORROW"
        }
    }

    var labelRewardCaps: String {
        switch language {
        case .turkish: return "ÖDÜL"
        case .english: return "REWARD"
        }
    }

    var labelQuestNotFound: String {
        switch language {
        case .turkish: return "Görev bulunamadı."
        case .english: return "Quest not found."
        }
    }

    var labelClassifiedData: String {
        switch language {
        case .turkish: return "GİZLİ VERİ"
        case .english: return "REDACTED DATA"
        }
    }

    var labelWorldLockedHint: String {
        switch language {
        case .turkish: return "Bu dünya henüz kilitli."
        case .english: return "This world is still locked."
        }
    }

    var labelRedactedFile: String {
        switch language {
        case .turkish: return "GİZLİ DOSYA"
        case .english: return "REDACTED FILE"
        }
    }

    var labelUnlockFileHint: String {
        switch language {
        case .turkish: return "Bu boss ile karşılaşınca dosya açılacak."
        case .english: return "Defeat this boss to unlock the file."
        }
    }

    var labelWorldLogsCaps: String {
        switch language {
        case .turkish: return "DÜNYA KAYITLARI"
        case .english: return "WORLD LOGS"
        }
    }

    var labelWorldLogsDesc: String {
        switch language {
        case .turkish: return "Dünyaların kısa giriş metinleri."
        case .english: return "Short introductions for each world."
        }
    }

    var labelBossFilesCaps: String {
        switch language {
        case .turkish: return "BOSS DOSYALARI"
        case .english: return "BOSS FILES"
        }
    }

    var labelBossFilesDesc: String {
        switch language {
        case .turkish: return "Keşfettikçe biyografiler açılır (spoiler yok)."
        case .english: return "Bios unlock as you discover them (spoiler-free)."
        }
    }

    // MARK: - Daily Reward Localization Properties
    var labelDailyRewardCaps: String {
        switch language {
        case .turkish: return "GÜNLÜK ÖDÜL"
        case .english: return "DAILY REWARD"
        }
    }

    var labelDailyRewardDesc: String {
        switch language {
        case .turkish: return "Üst üste giriş yaparak büyük ödülleri topla!"
        case .english: return "Log in daily to unlock bigger rewards!"
        }
    }

    var btnCloseCaps: String {
        switch language {
        case .turkish: return "KAPAT"
        case .english: return "CLOSE"
        }
    }

    var labelDailyRewardDayTemplate: String {
        switch language {
        case .turkish: return "GÜN {{day}}"
        case .english: return "DAY {{day}}"
        }
    }

    var btnClaimCaps: String {
        switch language {
        case .turkish: return "ÖDÜLÜ AL"
        case .english: return "CLAIM"
        }
    }

    var labelClaimedCaps: String {
        switch language {
        case .turkish: return "ALINDI"
        case .english: return "CLAIMED"
        }
    }

    var labelGoldWord: String {
        switch language {
        case .turkish: return "Altın"
        case .english: return "Gold"
        }
    }

    var labelNextRewardCaps: String {
        switch language {
        case .turkish: return "SONRAKİ ÖDÜL"
        case .english: return "NEXT REWARD"
        }
    }

    // MARK: - Dashboard Localization Properties
    var labelHighScoreCaps: String {
        switch language {
        case .turkish: return "EN YÜKSEK SKOR"
        case .english: return "HIGH SCORE"
        }
    }

    var labelOtherProfiles: String {
        switch language {
        case .turkish: return "Diğer Profiller ›"
        case .english: return "Other Profiles ›"
        }
    }

    var labelChallengeCaps: String {
        switch language {
        case .turkish: return "CHALLENGE"
        case .english: return "CHALLENGE"
        }
    }

    var labelGalleryCaps: String {
        switch language {
        case .turkish: return "GALERİ"
        case .english: return "GALLERY"
        }
    }


    var labelDuelsCaps: String {
        switch language {
        case .turkish: return "DÜELLOLAR"
        case .english: return "DUELS"
        }
    }

    var labelStoreCaps: String {
        switch language {
        case .turkish: return "MAĞAZA"
        case .english: return "STORE"
        }
    }

    var labelCareerCaps: String {
        switch language {
        case .turkish: return "KARİYER"
        case .english: return "CAREER"
        }
    }

    var btnNewRunCaps: String {
        switch language {
        case .turkish: return "YENİ RUN"
        case .english: return "NEW RUN"
        }
    }

    var btnPlayCaps: String {
        switch language {
        case .turkish: return "OYNA"
        case .english: return "PLAY"
        }
    }

    var labelSaveScores: String {
        switch language {
        case .turkish: return "Skorlarını Kaydet"
        case .english: return "Save Your Scores"
        }
    }

    var labelSaveScoresDesc: String {
        switch language {
        case .turkish: return "Dünya sıralamasında yer al ve skorlarını her zaman koruma altında tutun."
        case .english: return "Join the global leaderboard and keep your scores safe."
        }
    }

    var btnRegisterNowCaps: String {
        switch language {
        case .turkish: return "ŞİMDİ KAYIT OL"
        case .english: return "REGISTER NOW"
        }
    }

    var btnAlreadyHaveAccount: String {
        switch language {
        case .turkish: return "Zaten hesabım var"
        case .english: return "Already have an account"
        }
    }

    // MARK: - Battle Reward Localization Properties
    var labelBonusRewardActiveCaps: String {
        switch language {
        case .turkish: return "BONUS ÖDÜL AKTİF (Challenge/Contract)."
        case .english: return "BONUS REWARD ACTIVE (Challenge/Contract)."
        }
    }

    var labelClaimLootDesc: String {
        switch language {
        case .turkish: return "Ganimeti topla ve güçlen."
        case .english: return "Claim your loot and power up."
        }
    }

    var labelRewardDataCache: String {
        switch language {
        case .turkish: return "Veri Önbelleği"
        case .english: return "Data Cache"
        }
    }

    var labelRewardGoldEarnTemplate: String {
        switch language {
        case .turkish: return "+{{amount}} Altın kazan."
        case .english: return "Get +{{amount}} Gold."
        }
    }

    var labelRewardDiamondCache: String {
        switch language {
        case .turkish: return "Elmas Önbelleği"
        case .english: return "Diamond Cache"
        }
    }

    var labelRewardDiamondEarnTemplate: String {
        switch language {
        case .turkish: return "+{{amount}} Elmas kazan."
        case .english: return "Get +{{amount}} Diamonds."
        }
    }

    var labelRewardBackupBattery: String {
        switch language {
        case .turkish: return "Yedek Batarya"
        case .english: return "Backup Battery"
        }
    }

    var labelRewardLifeEarnTemplate: String {
        switch language {
        case .turkish: return "+{{amount}} Yaşam Puanı kazan."
        case .english: return "Get +{{amount}} Life Point."
        }
    }

    var labelRewardLevelUpTemplate: String {
        switch language {
        case .turkish: return "SEVİYE YÜKSELDİ: {{name}}"
        case .english: return "LEVEL UP: {{name}}"
        }
    }

    var labelRewardUpgradePerkTemplate: String {
        switch language {
        case .turkish: return "Mevcut perki L{{level}} seviyesine yükselt."
        case .english: return "Upgrade active perk to level L{{level}}."
        }
    }

    var labelRewardNewPerkTemplate: String {
        switch language {
        case .turkish: return "YENİ PERK: {{desc}}"
        case .english: return "NEW PERK: {{desc}}"
        }
    }

    // MARK: - Scoring Info Localization Properties
    var labelScoringSystem: String {
        switch language {
        case .turkish: return "PUAN SİSTEMİ"
        case .english: return "SCORING SYSTEM"
        }
    }

    var labelScoringSystemDesc: String {
        switch language {
        case .turkish: return "Matematikte ustalaş, tahtaya hükmet."
        case .english: return "Master the math, dominate the board."
        }
    }

    var labelBaseChipsTitle: String {
        switch language {
        case .turkish: return "1. TABAN CHIP (YERLEŞTİRME)"
        case .english: return "1. BASE CHIPS (THE SNAP)"
        }
    }

    var labelBaseChipsDesc: String {
        switch language {
        case .turkish: return "Her yerleştirilen blok; Kütle, Komşular ve Renk Gruplarına göre chip üretir. Karmaşıklık arttıkça daha fazla chip kazanırsın."
        case .english: return "Every placed block generates chips based on its **Mass**, **Neighbors**, and **Color Clusters**. Higher complexity = more chips."
        }
    }

    var labelMass: String {
        switch language {
        case .turkish: return "KÜTLE"
        case .english: return "MASS"
        }
    }

    var labelNeighbor: String {
        switch language {
        case .turkish: return "KOMŞU"
        case .english: return "NEIGHBOR"
        }
    }

    var labelCluster: String {
        switch language {
        case .turkish: return "GRUP"
        case .english: return "CLUSTER"
        }
    }

    var labelColorMultipliersTitle: String {
        switch language {
        case .turkish: return "2. RENK ÇARPANLARI"
        case .english: return "2. COLOR MULTIPLIERS"
        }
    }

    var labelColorMultipliersDesc: String {
        switch language {
        case .turkish: return "Yüksek değerli renklerle satır temizleyerek çarpanını yükselt. Ortalama renk değeri toplam çarpanına eklenir."
        case .english: return "Clear lines with high-value colors to boost your multiplier. The average color value is added to your total mult."
        }
    }

    var labelColorPurple: String {
        switch language {
        case .turkish: return "MOR (PURPLE)"
        case .english: return "PURPLE"
        }
    }

    var labelColorYellow: String {
        switch language {
        case .turkish: return "SARI (YELLOW)"
        case .english: return "YELLOW"
        }
    }

    var labelColorRed: String {
        switch language {
        case .turkish: return "KIRMIZI (RED)"
        case .english: return "RED"
        }
    }

    var labelColorGreen: String {
        switch language {
        case .turkish: return "YEŞİL (GREEN)"
        case .english: return "GREEN"
        }
    }

    var labelColorBlue: String {
        switch language {
        case .turkish: return "MAVİ (BLUE)"
        case .english: return "BLUE"
        }
    }

    var labelPatternsTitle: String {
        switch language {
        case .turkish: return "3. PATERNLER & KOMBOLAR"
        case .english: return "3. PATTERNS & COMBOS"
        }
    }

    var labelPatternMixed: String {
        switch language {
        case .turkish: return "Mixed (Karışık)"
        case .english: return "Mixed"
        }
    }

    var labelPatternDuoTone: String {
        switch language {
        case .turkish: return "Duo-Tone (2 Renk)"
        case .english: return "Duo-Tone"
        }
    }

    var labelPatternFlush: String {
        switch language {
        case .turkish: return "Flush (Tek Renk)"
        case .english: return "Flush"
        }
    }

    var labelPatternSuperFlush: String {
        switch language {
        case .turkish: return "Super Flush (2+ Flush)"
        case .english: return "Super Flush"
        }
    }

    var labelPattern2LineCombo: String {
        switch language {
        case .turkish: return "2'li Kombo"
        case .english: return "2-Line Combo"
        }
    }

    var labelPattern4LineCombo: String {
        switch language {
        case .turkish: return "4'lü (QUAD) Kombo"
        case .english: return "4-Line (QUAD)"
        }
    }

    var labelStreakTitle: String {
        switch language {
        case .turkish: return "4. SERİ (STREAK)"
        case .english: return "4. THE STREAK"
        }
    }

    var labelStreakDesc: String {
        switch language {
        case .turkish: return "Serini koruyarak her şeyi katla! Bonus başlangıçta doğrusal artar, denge için **3.8x**'te limitlenir."
        case .english: return "Maintain your streak to multiply everything! The bonus grows linearly at first, then caps at **3.8x** to keep things balanced."
        }
    }

    var labelGoalsTitle: String {
        switch language {
        case .turkish: return "HEDEFLER & TAHMİNLER"
        case .english: return "GOALS & MILESTONES"
        }
    }

    var labelGoalSingleMixedLine: String {
        switch language {
        case .turkish: return "Tek Karışık Satır"
        case .english: return "Single Mixed Line"
        }
    }

    var labelGoal2LineDuoTone: String {
        switch language {
        case .turkish: return "2'li Duo-Tone Kombo"
        case .english: return "2-Line Duo-Tone"
        }
    }

    var labelGoalSinglePurpleFlush: String {
        switch language {
        case .turkish: return "Tek Mor Flush"
        case .english: return "Single Flush (Purple)"
        }
    }

    var labelGoalZoneFlush: String {
        switch language {
        case .turkish: return "4x4 Alan Temizliği"
        case .english: return "4x4 Zone Flush"
        }
    }

    var labelPts: String {
        switch language {
        case .turkish: return "puan"
        case .english: return "pts"
        }
    }

    // MARK: - Rotation Info Localization Properties
    var labelRotateLimit: String {
        switch language {
        case .turkish: return "ROTASYON SINIRI!"
        case .english: return "ROTATE LIMIT!"
        }
    }

    var labelRotated: String {
        switch language {
        case .turkish: return "DÖNDÜRÜLDÜ!"
        case .english: return "ROTATED!"
        }
    }

    // MARK: - Enemy & HUD Info Localization Properties
    var labelEnemyPrefix: String {
        switch language {
        case .turkish: return "Düşman: "
        case .english: return "Enemy: "
        }
    }

    var labelEnemyTrayLockRemainingTemplate: String {
        switch language {
        case .turkish: return "Kilit: {{time}}sn"
        case .english: return "Lock: {{time}}s"
        }
    }

    var labelEnemyCaps: String {
        switch language {
        case .turkish: return "DÜŞMAN"
        case .english: return "ENEMY"
        }
    }

    var labelAttackIncoming: String {
        switch language {
        case .turkish: return "Saldırı geliyor"
        case .english: return "Attack incoming"
        }
    }

    var labelDifficultyPilot: String {
        switch language {
        case .turkish: return "Pilot"
        case .english: return "Pilot"
        }
    }

    var labelDifficultyBeginner: String {
        switch language {
        case .turkish: return "Acemi"
        case .english: return "Beginner"
        }
    }

    var labelDifficultyAdvanced: String {
        switch language {
        case .turkish: return "İleri"
        case .english: return "Advanced"
        }
    }

    var labelDifficultyExpert: String {
        switch language {
        case .turkish: return "Uzman"
        case .english: return "Expert"
        }
    }

    var labelRoundTemplate: String {
        switch language {
        case .turkish: return "Tur {{num}}"
        case .english: return "Round {{num}}"
        }
    }

    // MARK: - Game Overlays Localization Properties
    var labelChallengeOver: String {
        switch language {
        case .turkish: return "MEYDAN OKUMA BITTI"
        case .english: return "CHALLENGE OVER"
        }
    }

    var labelChallengeOverDesc: String {
        switch language {
        case .turkish: return "Grid sıkıştı — puanın sıralamaya kaydedildi."
        case .english: return "Grid locked — your score has been recorded."
        }
    }

    var labelBackToMenu: String {
        switch language {
        case .turkish: return "ANA MENÜYE DÖN"
        case .english: return "BACK TO MENU"
        }
    }

    var labelRoundLost: String {
        switch language {
        case .turkish: return "ROUND KAYBEDİLDİ"
        case .english: return "ROUND LOST"
        }
    }

    var labelRoundLostDesc: String {
        switch language {
        case .turkish: return "Grid sıkıştı veya süren bitti."
        case .english: return "Grid locked or time ran out."
        }
    }

    var labelRetry: String {
        switch language {
        case .turkish: return "TEKRAR DENE"
        case .english: return "RETRY"
        }
    }

    var labelGiveUpViewSummary: String {
        switch language {
        case .turkish: return "PES ET / ÖZETİ GÖR"
        case .english: return "GIVE UP / VIEW SUMMARY"
        }
    }

    var labelRoundClear: String {
        switch language {
        case .turkish: return "ROUND TAMAMLANDI"
        case .english: return "ROUND CLEAR"
        }
    }

    var labelBackToMap: String {
        switch language {
        case .turkish: return "HARİTAYA DÖN"
        case .english: return "BACK TO MAP"
        }
    }

    var labelPaused: String {
        switch language {
        case .turkish: return "DURAKLATILDI"
        case .english: return "PAUSED"
        }
    }

    var labelPausedDesc: String {
        switch language {
        case .turkish: return "Sistem ayarlarını yönet ve devam et."
        case .english: return "Manage system settings and continue."
        }
    }

    var labelSound: String {
        switch language {
        case .turkish: return "Ses"
        case .english: return "Sound"
        }
    }

    var labelHaptics: String {
        switch language {
        case .turkish: return "Titreşim (Haptic)"
        case .english: return "Haptics"
        }
    }

    var labelResume: String {
        switch language {
        case .turkish: return "DEVAM ET"
        case .english: return "RESUME"
        }
    }

    var labelRestartSector: String {
        switch language {
        case .turkish: return "SEKTÖRÜ YENİDEN BAŞLAT"
        case .english: return "RESTART SECTOR"
        }
    }

    var labelSettingsCaps: String {
        switch language {
        case .turkish: return "AYARLAR"
        case .english: return "SETTINGS"
        }
    }

    var labelGiveUpSaveScore: String {
        switch language {
        case .turkish: return "PES ET VE PUANI KAYDET"
        case .english: return "GIVE UP & SAVE SCORE"
        }
    }

    var labelSaveBackToHub: String {
        switch language {
        case .turkish: return "KAYDET VE HUB'A DÖN"
        case .english: return "SAVE & BACK TO HUB"
        }
    }

    var labelWarningCaps: String {
        switch language {
        case .turkish: return "DİKKAT"
        case .english: return "WARNING"
        }
    }

    var labelBossRoundCaps: String {
        switch language {
        case .turkish: return "BOSS ROUND"
        case .english: return "BOSS ROUND"
        }
    }

    var labelFightCaps: String {
        switch language {
        case .turkish: return "SAVAŞ"
        case .english: return "FIGHT"
        }
    }

    var labelHowToPlayCaps: String {
        switch language {
        case .turkish: return "NASIL OYNANIR?"
        case .english: return "HOW TO PLAY"
        }
    }

    var labelNextCaps: String {
        switch language {
        case .turkish: return "SONRAKİ"
        case .english: return "NEXT"
        }
    }

    var labelStartCaps: String {
        switch language {
        case .turkish: return "BAŞLA!"
        case .english: return "START!"
        }
    }

    var labelChapterBossCaps: String {
        switch language {
        case .turkish: return "BÖLÜM PATRONU"
        case .english: return "CHAPTER BOSS"
        }
    }

    // MARK: - Passive Perk HUD Localization Properties
    var labelPerksCaps: String {
        switch language {
        case .turkish: return "PERKLER"
        case .english: return "PERKS"
        }
    }

    var labelNoActivePerk: String {
        switch language {
        case .turkish: return "Aktif perk yok"
        case .english: return "No active perk"
        }
    }

    var labelSynergyPartnersCaps: String {
        switch language {
        case .turkish: return "SİNERJİ ORTAKLARI"
        case .english: return "SYNERGY PARTNERS"
        }
    }

    // MARK: - Run Summary Localization Properties
    var labelRunOverCaps: String {
        switch language {
        case .turkish: return "RUN BİTTİ"
        case .english: return "RUN OVER"
        }
    }

    var labelSummaryCaps: String {
        switch language {
        case .turkish: return "İSTATİSTİKLER"
        case .english: return "SUMMARY"
        }
    }

    var labelTrialRunCaps: String {
        switch language {
        case .turkish: return "TRIAL RUN"
        case .english: return "TRIAL RUN"
        }
    }

    var labelTotalScoreCaps: String {
        switch language {
        case .turkish: return "TOPLAM SKOR"
        case .english: return "TOTAL SCORE"
        }
    }

    var labelWorldCaps: String {
        switch language {
        case .turkish: return "WORLD"
        case .english: return "WORLD"
        }
    }

    var labelPerkCaps: String {
        switch language {
        case .turkish: return "PERK"
        case .english: return "PERKS"
        }
    }

    var labelSubmittingScore: String {
        switch language {
        case .turkish: return "Skor gönderiliyor…"
        case .english: return "Submitting score…"
        }
    }

    var labelSaveYourScores: String {
        switch language {
        case .turkish: return "Skorlarını Kaydet"
        case .english: return "Save Your Scores"
        }
    }

    var labelNewRunCaps: String {
        switch language {
        case .turkish: return "YENİ RUN"
        case .english: return "NEW RUN"
        }
    }

    var labelMainMenuCaps: String {
        switch language {
        case .turkish: return "ANA MENÜ"
        case .english: return "MAIN MENU"
        }
    }

    // MARK: - Merchant & Forge Localization Properties
    var labelMerchantKairoCaps: String {
        switch language {
        case .turkish: return "TÜCCAR KAIRO"
        case .english: return "MERCHANT KAIRO"
        }
    }

    var labelMerchantKairoDialogue: String {
        switch language {
        case .turkish: return "\"Veri akışında nadir parçalar keşfettim. Elindeki altınlar burada değerli.\""
        case .english: return "\"I've scavenged rare data fragments. Your gold buys well here.\""
        }
    }

    var labelMerchantCaps: String {
        switch language {
        case .turkish: return "TÜCCAR"
        case .english: return "MERCHANT"
        }
    }

    var labelSlotCaps: String {
        switch language {
        case .turkish: return "SLOT"
        case .english: return "SLOT"
        }
    }

    var labelMerchantSubDialogue: String {
        switch language {
        case .turkish: return "\"Karanlıkta parlayan her şey altın değildir... ama bunlar öyle.\""
        case .english: return "\"Not all that glitters in the dark is gold... but these are.\""
        }
    }

    var labelOffersCaps: String {
        switch language {
        case .turkish: return "TEKLİFLER"
        case .english: return "OFFERS"
        }
    }

    var labelPerkForgeCaps: String {
        switch language {
        case .turkish: return "PERK DEMİRCİSİ"
        case .english: return "PERK FORGE"
        }
    }

    var labelForgeSelectionHint: String {
        switch language {
        case .turkish: return "2 Seç: 1 Yeni"
        case .english: return "Pick 2: Get 1"
        }
    }

    var labelForgeDescription: String {
        switch language {
        case .turkish: return "İki perk'i feda ederek çok daha güçlü veya rastgele bir perk elde et."
        case .english: return "Sacrifice two perks to forge a stronger or random new one."
        }
    }

    var btnForgeCaps: String {
        switch language {
        case .turkish: return "BİRLEŞTİR (FORGE)"
        case .english: return "FORGE"
        }
    }

    var btnBackToMapCaps: String {
        switch language {
        case .turkish: return "HARİTAYA DÖN"
        case .english: return "BACK TO MAP"
        }
    }

    var labelSoldCaps: String {
        switch language {
        case .turkish: return "SATILDI"
        case .english: return "SOLD"
        }
    }

    var labelLifePotion: String {
        switch language {
        case .turkish: return "Yaşam İksiri"
        case .english: return "Life Potion"
        }
    }

    var labelUnknown: String {
        switch language {
        case .turkish: return "Bilinmeyen"
        case .english: return "Unknown"
        }
    }

    // MARK: - Mystery Event & Treasure Room Localization Properties
    var labelMysteryEventCaps: String {
        switch language {
        case .turkish: return "GİZEMLİ OLAY"
        case .english: return "MYSTERY EVENT"
        }
    }

    var labelMysteryEnergySwirl: String {
        switch language {
        case .turkish: return "Önünde karanlık bir enerji süzülüyor...\nDokunmaya cesaretin var mı?"
        case .english: return "A dark energy swirls before you...\nDare to touch it?"
        }
    }

    var btnTouchAndSeeCaps: String {
        switch language {
        case .turkish: return "DOKUN VE GÖR"
        case .english: return "TOUCH AND SEE"
        }
    }

    var btnAcceptAndContinueCaps: String {
        switch language {
        case .turkish: return "KABUL ET VE DEVAM ET"
        case .english: return "ACCEPT AND CONTINUE"
        }
    }

    var btnLeaveCaps: String {
        switch language {
        case .turkish: return "UZAKLAŞ"
        case .english: return "LEAVE"
        }
    }

    func formatSafeHouseBonus(tier: Int, bonus: Int) -> String {
        switch language {
        case .turkish: return "SAFE HOUSE (L\(tier)) bonusu: +\(bonus) Altın"
        case .english: return "SAFE HOUSE (L\(tier)) bonus: +\(bonus) Gold"
        }
    }

    var labelTreasureVaultCaps: String {
        switch language {
        case .turkish: return "HAZİNE ODASI"
        case .english: return "TREASURE VAULT"
        }
    }

    var labelChooseReward: String {
        switch language {
        case .turkish: return "Bir hediye seç!"
        case .english: return "Choose a reward!"
        }
    }

    var labelOldChestSitting: String {
        switch language {
        case .turkish: return "Karanlık bir köşede eski bir sandık duruyor..."
        case .english: return "An old chest sits in a dark corner..."
        }
    }

    var btnOpenChestCaps: String {
        switch language {
        case .turkish: return "SANDIĞI AÇ"
        case .english: return "OPEN CHEST"
        }
    }

    var labelCollectedAllPowers: String {
        switch language {
        case .turkish: return "Tüm açık özel güçleri topladın!"
        case .english: return "You've collected all unlocked powers!"
        }
    }

    func formatPerkUpgrade(from currentTier: Int, to nextTier: Int) -> String {
        switch language {
        case .turkish: return "L\(currentTier) -> L\(nextTier) seviyesine yükselt."
        case .english: return "Upgrade from L\(currentTier) to L\(nextTier)."
        }
    }

    func formatPerkLevelUp(name: String) -> String {
        switch language {
        case .turkish: return "SEVİYE ATLA: \(name)"
        case .english: return "LEVEL UP: \(name)"
        }
    }

    func formatPerkClaimed(name: String) -> String {
        switch language {
        case .turkish: return "\(name) Elde Edildi!"
        case .english: return "\(name) Claimed!"
        }
    }

    var btnSkipCaps: String {
        switch language {
        case .turkish: return "ATLA"
        case .english: return "SKIP"
        }
    }

    // MARK: - Map View Localization Properties
    var labelWorldSelectionCaps: String {
        switch language {
        case .turkish: return "DÜNYA SEÇİMİ"
        case .english: return "WORLD SELECT"
        }
    }

    var labelSystemAnalysisCaps: String {
        switch language {
        case .turkish: return "SİSTEM ANALİZİ"
        case .english: return "SYSTEM ANALYSIS"
        }
    }

    func formatChapterIndex(index: Int) -> String {
        switch language {
        case .turkish: return "BÖLÜM \(index)"
        case .english: return "CHAPTER \(index)"
        }
    }

    var btnRefreshDataCaps: String {
        switch language {
        case .turkish: return "VERİYİ YENİLE"
        case .english: return "REFRESH DATA"
        }
    }

    var btnInitializeLinkCaps: String {
        switch language {
        case .turkish: return "BAĞLANTIYI BAŞLAT"
        case .english: return "INITIALIZE LINK"
        }
    }

    // Node Type Titles
    var labelNodeTitleNormal: String {
        switch language {
        case .turkish: return "Veri Temizliği"
        case .english: return "Data Purge"
        }
    }
    var labelNodeTitleElite: String {
        switch language {
        case .turkish: return "Sistem Gardiyanı"
        case .english: return "System Guardian"
        }
    }
    var labelNodeTitleChallenge: String {
        switch language {
        case .turkish: return "Protokol X"
        case .english: return "Protocol X"
        }
    }
    var labelNodeTitleMerchant: String {
        switch language {
        case .turkish: return "Veri Borsası"
        case .english: return "Data Exchange"
        }
    }
    var labelNodeTitleTreasure: String {
        switch language {
        case .turkish: return "Sistem Sızıntısı"
        case .english: return "System Leak"
        }
    }
    var labelNodeTitleRest: String {
        switch language {
        case .turkish: return "Enerji İstasyonu"
        case .english: return "Power Station"
        }
    }
    var labelNodeTitleMystery: String {
        switch language {
        case .turkish: return "Anomali"
        case .english: return "Anomaly"
        }
    }
    var labelNodeTitleBoss: String {
        switch language {
        case .turkish: return "ANA ÇEKİRDEK"
        case .english: return "CORE KERNEL"
        }
    }

    // Node Type Descriptions
    var labelNodeDescNormal: String {
        switch language {
        case .turkish: return "Standart veri temizleme işlemi."
        case .english: return "Standard data purge operation."
        }
    }
    var labelNodeDescElite: String {
        switch language {
        case .turkish: return "Yüksek güvenlikli birim koruması."
        case .english: return "High-security unit protection."
        }
    }
    var labelNodeDescChallenge: String {
        switch language {
        case .turkish: return "Riskli veri kurtarma protokolü."
        case .english: return "Risky data recovery protocol."
        }
    }
    var labelNodeDescMerchant: String {
        switch language {
        case .turkish: return "Donanım modülleri takas merkezi."
        case .english: return "Hardware module exchange hub."
        }
    }
    var labelNodeDescTreasure: String {
        switch language {
        case .turkish: return "Sahipsiz sistem yetenekleri."
        case .english: return "Unclaimed system capabilities."
        }
    }
    var labelNodeDescRest: String {
        switch language {
        case .turkish: return "Sistem optimizasyonu ve onarım."
        case .english: return "System optimization and repair."
        }
    }
    var labelNodeDescMystery: String {
        switch language {
        case .turkish: return "Tanımlanamayan veri sinyali."
        case .english: return "Unidentified data signal."
        }
    }
    var labelNodeDescBoss: String {
        switch language {
        case .turkish: return "Sistemi kontrol eden ana protokol."
        case .english: return "The master protocol controlling the system."
        }
    }

    // MARK: - World Map Detail Sheet Localization Properties
    func formatSectorIndex(index: Int) -> String {
        switch language {
        case .turkish: return "SEKTÖR \(index)"
        case .english: return "SECTOR \(index)"
        }
    }

    var labelCriticalTargetCaps: String {
        switch language {
        case .turkish: return "KRİTİK HEDEF"
        case .english: return "CRITICAL TARGET"
        }
    }

    var labelDataPurgedCaps: String {
        switch language {
        case .turkish: return "VERİ TEMİZLENDİ"
        case .english: return "DATA PURGED"
        }
    }

    var labelAccessDeniedCaps: String {
        switch language {
        case .turkish: return "ERİŞİM ENGELLENDİ"
        case .english: return "ACCESS DENIED"
        }
    }

    var labelActiveSignalCaps: String {
        switch language {
        case .turkish: return "AKTİF SİNYAL"
        case .english: return "ACTIVE SIGNAL"
        }
    }

    func formatModifierHint(bucket: Int) -> String {
        switch bucket {
        case 0:
            switch language {
            case .turkish: return "TAVSİYE: Titan blokları ağırlık direnci gerektirir."
            case .english: return "ADVICE: Titan blocks require weight resistance."
            }
        case 1:
            switch language {
            case .turkish: return "TAVSİYE: Zaman Bükücü'ye karşı hızlı hamleler yap."
            case .english: return "ADVICE: Use fast moves against Time Benders."
            }
        case 2:
            switch language {
            case .turkish: return "TAVSİYE: Neon Hayaletler görüş alanını daraltabilir."
            case .english: return "ADVICE: Neon Wraiths may narrow your field of view."
            }
        default:
            switch language {
            case .turkish: return "TAVSİYE: Boşluk bloklarını temizlemek için kombolara odaklan."
            case .english: return "ADVICE: Focus on combos to clear Void blocks."
            }
        }
    }

    var labelEnemyAnalysisCaps: String {
        switch language {
        case .turkish: return "DÜŞMAN ANALİZİ"
        case .english: return "ENEMY ANALYSIS"
        }
    }

    var labelPotentialRewardsCaps: String {
        switch language {
        case .turkish: return "POTANSİYEL ÖDÜL"
        case .english: return "POTENTIAL REWARDS"
        }
    }

    var labelCriticalThreatDetectedCaps: String {
        switch language {
        case .turkish: return "KRİTİK TEHDİT TESPİT EDİLDİ"
        case .english: return "CRITICAL THREAT DETECTED"
        }
    }

    var labelRiskAnalysisRewardsCaps: String {
        switch language {
        case .turkish: return "RİSK ANALİZİ & ÖDÜLLER"
        case .english: return "RISK ANALYSIS & REWARDS"
        }
    }

    var labelSafeCaps: String {
        switch language {
        case .turkish: return "GÜVENLİ"
        case .english: return "SAFE"
        }
    }

    var labelStandardDifficulty: String {
        switch language {
        case .turkish: return "Standart Zorluk"
        case .english: return "Standard Difficulty"
        }
    }

    var labelRiskyCaps: String {
        switch language {
        case .turkish: return "RİSKLİ"
        case .english: return "RISKY"
        }
    }

    var labelRiskyHPModifier: String {
        switch language {
        case .turkish: return "+50% Boss Canı"
        case .english: return "+50% Boss HP"
        }
    }

    var btnAccessRestrictedCaps: String {
        switch language {
        case .turkish: return "ERİŞİM KISITLI"
        case .english: return "ACCESS RESTRICTED"
        }
    }

    var btnInitializeLinkCapsV2: String {
        switch language {
        case .turkish: return "BAĞLANTIYI KUR"
        case .english: return "INITIALIZE LINK"
        }
    }

    var btnReConnectCaps: String {
        switch language {
        case .turkish: return "YENİDEN BAĞLAN"
        case .english: return "RE-CONNECT"
        }
    }

    var btnInitializeEntryCaps: String {
        switch language {
        case .turkish: return "SİSTEME GİRİŞ"
        case .english: return "INITIALIZE ENTRY"
        }
    }

    // MARK: - World Selection View Localization Properties
    var labelTotalProgressCaps: String {
        switch language {
        case .turkish: return "TOPLAM İLERLEME"
        case .english: return "TOTAL PROGRESS"
        }
    }

    var labelSectorSelectionCaps: String {
        switch language {
        case .turkish: return "SEKTÖR SEÇİMİ"
        case .english: return "SECTOR SELECTION"
        }
    }

    var labelSelectRegionDesc: String {
        switch language {
        case .turkish: return "Giriş yapılacak bölgeyi seçin"
        case .english: return "Select the region to initialize entry"
        }
    }

    func formatWorldTitle(worldId: Int) -> String {
        switch worldId {
        case 1:
            switch language {
            case .turkish: return "NEON ÇEKİRDEK"
            case .english: return "NEON CORE"
            }
        case 2:
            switch language {
            case .turkish: return "BETON HARABELER"
            case .english: return "CONCRETE RUINS"
            }
        case 3:
            switch language {
            case .turkish: return "ŞEKER LABORATUVARI"
            case .english: return "CANDY LAB"
            }
        case 4:
            switch language {
            case .turkish: return "DERİN OKYANUS"
            case .english: return "DEEP OCEAN"
            }
        default:
            switch language {
            case .turkish: return "BOŞLUK ÇEKİRDEĞİ"
            case .english: return "VOID KERNEL"
            }
        }
    }

    func formatWorldTwist(worldId: Int) -> String {
        switch worldId {
        case 1:
            switch language {
            case .turkish: return "Eğitim dünyası · Twist yok"
            case .english: return "Tutorial world · No twist"
            }
        case 2:
            switch language {
            case .turkish: return "Ağırlık: Bloklar daha hızlı düşer"
            case .english: return "Weight: Blocks fall faster"
            }
        case 3:
            switch language {
            case .turkish: return "Yapışkan: Bloklar birbirine bağlanır"
            case .english: return "Sticky: Blocks chain together"
            }
        case 4:
            switch language {
            case .turkish: return "Basınç: Karar verme süresi azalır"
            case .english: return "Pressure: Reduced decision time"
            }
        default:
            switch language {
            case .turkish: return "Boşluk: Gerçeklik katmanları bükülür"
            case .english: return "Void: Reality layers distort"
            }
        }
    }

    var btnReConnectCapsV2: String {
        switch language {
        case .turkish: return "TEKRAR BAĞLAN"
        case .english: return "RE-CONNECT"
        }
    }

    var btnNotNowCaps: String {
        switch language {
        case .turkish: return "ŞİMDİLİK DEĞİL"
        case .english: return "NOT NOW"
        }
    }

    var labelChapterCaps: String {
        switch language {
        case .turkish: return "BÖLÜM"
        case .english: return "CHAPTER"
        }
    }

    var labelRookiePilotCaps: String {
        switch language {
        case .turkish: return "ACEMİ PİLOT"
        case .english: return "ROOKIE PILOT"
        }
    }

    var labelAdeptPilotCaps: String {
        switch language {
        case .turkish: return "USTA PİLOT"
        case .english: return "ADEPT PILOT"
        }
    }

    var labelElitePilotCaps: String {
        switch language {
        case .turkish: return "UZMAN PİLOT"
        case .english: return "ELITE PILOT"
        }
    }

    var labelCampaignProgressCaps: String {
        switch language {
        case .turkish: return "KAMPANYA İLERLEMESİ"
        case .english: return "CAMPAIGN PROGRESS"
        }
    }

    var labelDoneCaps: String {
        switch language {
        case .turkish: return "TAMAM"
        case .english: return "DONE"
        }
    }

    var labelAchievementUnlockedCaps: String {
        switch language {
        case .turkish: return "BAŞARI AÇILDI!"
        case .english: return "ACHIEVEMENT UNLOCKED!"
        }
    }

    // MARK: - Perk Selection & Perk Shop Localization Properties
    var labelStartingPerkCaps: String {
        switch language {
        case .turkish: return "ÖZEL GÜÇ"
        case .english: return "STARTING PERK"
        }
    }

    func formatPerksLockedDesc(count: Int) -> String {
        switch language {
        case .turkish: return "\(count) perk kilitli — Perk Dükkanı’ndan aç"
        case .english: return "\(count) perks locked — unlock in Perk Shop"
        }
    }

    var btnStartRunCaps: String {
        switch language {
        case .turkish: return "OYUNA BAŞLA"
        case .english: return "START RUN"
        }
    }

    func formatSynergyHint(partnerName: String) -> String {
        switch language {
        case .turkish: return "Sinerji: \(partnerName)"
        case .english: return "Synergy: \(partnerName)"
        }
    }

    var labelPerkShopCaps: String {
        switch language {
        case .turkish: return "PERK DÜKKANI"
        case .english: return "PERK SHOP"
        }
    }

    var labelInsufficientGoldBanner: String {
        switch language {
        case .turkish: return "⚠️ Yetersiz altın!"
        case .english: return "⚠️ Not enough gold!"
        }
    }

    var labelStarterCaps: String {
        switch language {
        case .turkish: return "BAŞLANGIÇ"
        case .english: return "STARTER"
        }
    }

    var labelUnlockedStatus: String {
        switch language {
        case .turkish: return "Açık"
        case .english: return "Unlocked"
        }
    }

    var labelStarterPerkAlwaysFree: String {
        switch language {
        case .turkish: return "Başlangıç perki — otomatik açık"
        case .english: return "Starter perk — always free"
        }
    }

    var labelGoldToUnlock: String {
        switch language {
        case .turkish: return "Altın ile Aç"
        case .english: return "Gold to Unlock"
        }
    }

    var labelTier1FreeCaps: String {
        switch language {
        case .turkish: return "TIER 1 — ÜCRETSİZ"
        case .english: return "TIER 1 — FREE"
        }
    }

    // MARK: - Perk Upgrade System & Run Setup View Localization Properties
    var labelPerkShopStoreCaps: String {
        switch language {
        case .turkish: return "PERK MAĞAZASI"
        case .english: return "PERK SHOP"
        }
    }

    var labelMetaProgressionCaps: String {
        switch language {
        case .turkish: return "META İLERLEME SİSTEMİ"
        case .english: return "META PROGRESSION"
        }
    }

    var labelRunSetupCaps: String {
        switch language {
        case .turkish: return "SEFER KURULUMU"
        case .english: return "RUN SETUP"
        }
    }

    var labelRunSetupDesc: String {
        switch language {
        case .turkish: return "Slot, karakter, perk ve dünya seç"
        case .english: return "Choose slot, character, perk and world"
        }
    }

    func formatWorldTitleTemplate(worldId: Int) -> String {
        switch language {
        case .turkish: return "Dünya \(worldId)"
        case .english: return "World \(worldId)"
        }
    }

    var labelWorldHeaderCaps: String {
        switch language {
        case .turkish: return "DÜNYA"
        case .english: return "WORLD"
        }
    }

    var labelStartingPerkHeaderCaps: String {
        switch language {
        case .turkish: return "STARTING PERK"
        case .english: return "STARTING PERK"
        }
    }

    var labelStartingItemHeaderCaps: String {
        switch language {
        case .turkish: return "STARTING ITEM"
        case .english: return "STARTING ITEM"
        }
    }

    var labelSelectWorldCaps: String {
        switch language {
        case .turkish: return "DÜNYA SEÇ"
        case .english: return "SELECT WORLD"
        }
    }

    // MARK: - Save Slot Selection View Localization Properties
    var labelSelectSlotCaps: String {
        switch language {
        case .turkish: return "SLOT SEÇ"
        case .english: return "SELECT SLOT"
        }
    }

    var labelDeleteSave: String {
        switch language {
        case .turkish: return "Kaydı Sil"
        case .english: return "Delete Save"
        }
    }

    var btnDelete: String {
        switch language {
        case .turkish: return "Sil"
        case .english: return "Delete"
        }
    }

    var labelConfirmDeleteSavePrompt: String {
        switch language {
        case .turkish: return "Bu kaydı silmek istediğinize emin misiniz? Bu işlem geri alınamaz."
        case .english: return "Are you sure you want to delete this save? This action cannot be undone."
        }
    }

    var labelEmptySlotStatus: String {
        switch language {
        case .turkish: return "Boş Kayıt"
        case .english: return "Empty Slot"
        }
    }

    func formatChapterLabelTemplate(chapterIndex: Int) -> String {
        switch language {
        case .turkish: return "Bölüm \(chapterIndex)"
        case .english: return "Chapter \(chapterIndex)"
        }
    }

    func formatRoundLabelTemplate(roundIndex: Int) -> String {
        switch language {
        case .turkish: return "Tur \(roundIndex)"
        case .english: return "Round \(roundIndex)"
        }
    }

    // MARK: - Slot Hub View Localization Properties
    var btnBackCaps: String {
        switch language {
        case .turkish: return "GERİ"
        case .english: return "BACK"
        }
    }

    var labelNeuralLinkStableCaps: String {
        switch language {
        case .turkish: return "NÖRAL BAĞLANTI: STABİL"
        case .english: return "NEURAL LINK: STABLE"
        }
    }

    var labelSystemTelemetryCaps: String {
        switch language {
        case .turkish: return "SİSTEM VERİLERİ"
        case .english: return "SYSTEM TELEMETRY"
        }
    }

    var labelMaxSectorCaps: String {
        switch language {
        case .turkish: return "EN YÜKSEK SKOR"
        case .english: return "MAX SECTOR"
        }
    }

    var labelCreditsCaps: String {
        switch language {
        case .turkish: return "ALTIN"
        case .english: return "CREDITS"
        }
    }

    var labelStabilityCaps: String {
        switch language {
        case .turkish: return "STABİLİTE"
        case .english: return "STABILITY"
        }
    }

    var labelModulesCaps: String {
        switch language {
        case .turkish: return "MODÜLLER"
        case .english: return "MODULES"
        }
    }

    var labelRecentDataLogsCaps: String {
        switch language {
        case .turkish: return "SON VERİ KAYITLARI"
        case .english: return "RECENT DATA LOGS"
        }
    }

    func formatSectorDataLog(sectorIndex: Int) -> String {
        switch language {
        case .turkish: return "SEKTÖR \(sectorIndex) VERİSİ"
        case .english: return "SECTOR \(sectorIndex) DATA"
        }
    }

    var btnContinueRunCaps: String {
        switch language {
        case .turkish: return "SEFERE DEVAM ET"
        case .english: return "CONTINUE RUN"
        }
    }

    var btnStartNewRunCaps: String {
        switch language {
        case .turkish: return "YENİ SEFER BAŞLAT"
        case .english: return "START NEW RUN"
        }
    }

    var btnChangeSectorCaps: String {
        switch language {
        case .turkish: return "SEKTÖRÜ DEĞİŞTİR"
        case .english: return "CHANGE SECTOR"
        }
    }

    var btnPerkUpgradesCaps: String {
        switch language {
        case .turkish: return "PERK GELİŞTİRME"
        case .english: return "PERK UPGRADES"
        }
    }

    var labelHeroCaps: String {
        switch language {
        case .turkish: return "KAHRAMAN"
        case .english: return "HERO"
        }
    }

    var labelMarketCaps: String {
        switch language {
        case .turkish: return "PAZAR"
        case .english: return "MARKET"
        }
    }

    var labelLoreCaps: String {
        switch language {
        case .turkish: return "KOLEKSİYON"
        case .english: return "LORE"
        }
    }

    // MARK: - How to Play View Localization Properties
    var labelHowToPlayQuestionCaps: String {
        switch language {
        case .turkish: return "NASIL OYNANIR?"
        case .english: return "HOW TO PLAY?"
        }
    }

    var btnGotItCaps: String {
        switch language {
        case .turkish: return "ANLADIM!"
        case .english: return "GOT IT!"
        }
    }

    var btnNextCaps: String {
        switch language {
        case .turkish: return "İLERİ"
        case .english: return "NEXT"
        }
    }

    // MARK: - App Start View Localization Properties
    var labelLoadingCaps: String {
        switch language {
        case .turkish: return "YÜKLENİYOR..."
        case .english: return "LOADING..."
        }
    }

    // MARK: - Settings View Localization Properties
    var labelExperienceCaps: String {
        switch language {
        case .turkish: return "DENEYİM"
        case .english: return "EXPERIENCE"
        }
    }

    var labelSoundEffects: String {
        switch language {
        case .turkish: return "Ses Efektleri"
        case .english: return "Sound Effects"
        }
    }


    var labelLanguageCaps: String {
        switch language {
        case .turkish: return "DİL"
        case .english: return "LANGUAGE"
        }
    }

    var labelInfoCaps: String {
        switch language {
        case .turkish: return "BİLGİ"
        case .english: return "INFO"
        }
    }

    var labelHowToPlayQuestion: String {
        switch language {
        case .turkish: return "Nasıl Oynanır?"
        case .english: return "How to Play"
        }
    }

    var labelOurWebsite: String {
        switch language {
        case .turkish: return "Web Sitemiz"
        case .english: return "Our Website"
        }
    }

    var labelLogout: String {
        switch language {
        case .turkish: return "Çıkış Yap"
        case .english: return "Logout"
        }
    }

    var labelLogoutCaps: String {
        switch language {
        case .turkish: return "ÇIKIŞ YAP"
        case .english: return "LOGOUT"
        }
    }

    var msgLogoutMessage: String {
        switch language {
        case .turkish: return "Hesabınızdan çıkış yapılacak. Yerel verileriniz korunur."
        case .english: return "You will be logged out. Your local data will be preserved."
        }
    }

    var titleSettingsCaps: String {
        switch language {
        case .turkish: return "AYARLAR"
        case .english: return "SETTINGS"
        }
    }

    var labelGuestPlayerCaps: String {
        switch language {
        case .turkish: return "MİSAFİR OYUNCU"
        case .english: return "GUEST PLAYER"
        }
    }

    var labelGuestSubtitle: String {
        switch language {
        case .turkish: return "Skorlarını kaydetmek için kaydol"
        case .english: return "Sign up to save your scores"
        }
    }

    var labelProfileIconCaps: String {
        switch language {
        case .turkish: return "PROFİL İKONU"
        case .english: return "PROFILE ICON"
        }
    }

    var btnDeleteAccount: String {
        switch language {
        case .turkish: return "Hesabımı Kalıcı Olarak Sil"
        case .english: return "Permanently Delete My Account"
        }
    }


    var btnDeleteCaps: String {
        switch language {
        case .turkish: return "SİL"
        case .english: return "DELETE"
        }
    }

    var msgDeleteAccountMessage: String {
        switch language {
        case .turkish: return "Bu işlem geri alınamaz. Tüm oyun verileriniz silinecektir."
        case .english: return "This action cannot be undone. All your game data will be deleted."
        }
    }

    var btnClose: String {
        switch language {
        case .turkish: return "Kapat"
        case .english: return "Close"
        }
    }

    var btnDone: String {
        switch language {
        case .turkish: return "Bitti"
        case .english: return "Done"
        }
    }

    var msgOfflineScoresSynced: String {
        switch language {
        case .turkish: return "Çevrimdışı skorlarınız başarıyla eşitlendi!"
        case .english: return "Offline scores successfully synced!"
        }
    }

    var labelLockedCaps: String {
        switch language {
        case .turkish: return "KİLİTLİ"
        case .english: return "LOCKED"
        }
    }

    var labelMaxCaps: String {
        switch language {
        case .turkish: return "MAX"
        case .english: return "MAX"
        }
    }

    var labelMaxLevelReachedCaps: String {
        switch language {
        case .turkish: return "MAKSİMUM SEVİYEYE ULAŞILDI"
        case .english: return "MAX LEVEL REACHED"
        }
    }

    var labelCurrentTierCaps: String {
        switch language {
        case .turkish: return "MEVCUT SEVİYE"
        case .english: return "CURRENT TIER"
        }
    }

    var labelNextTierCaps: String {
        switch language {
        case .turkish: return "SONRAKİ SEVİYE"
        case .english: return "NEXT TIER"
        }
    }

    var btnUnlockPerkCaps: String {
        switch language {
        case .turkish: return "AVANTAJI AÇ"
        case .english: return "UNLOCK PERK"
        }
    }

    func formatUpgradeToTierCaps(tier: Int) -> String {
        switch language {
        case .turkish: return "SEVİYE \(tier)'E YÜKSELT"
        case .english: return "UPGRADE TO TIER \(tier)"
        }
    }

    var btnUnlockCaps: String {
        switch language {
        case .turkish: return "AÇ"
        case .english: return "UNLOCK"
        }
    }

    var btnUpgradeCaps: String {
        switch language {
        case .turkish: return "YÜKSELT"
        case .english: return "UPGRADE"
        }
    }

    var labelSuccessCaps: String {
        switch language {
        case .turkish: return "BAŞARILI!"
        case .english: return "SUCCESS!"
        }
    }

    var labelPerkLevelUpgradedCaps: String {
        switch language {
        case .turkish: return "PERK SEVİYESİ YÜKSELDİ"
        case .english: return "PERK LEVEL UPGRADED"
        }
    }

    var labelForgeSuccessfulCaps: String {
        switch language {
        case .turkish: return "BİRLEŞTİRME BAŞARILI!"
        case .english: return "FORGE SUCCESSFUL!"
        }
    }

    // MARK: - Onboarding & Login Localization Properties
    var labelWelcome: String {
        switch language {
        case .turkish: return "BLOCK JACK'E HOŞ GELDİN"
        case .english: return "WELCOME TO BLOCK JACK"
        }
    }

    var labelWelcomeDesc: String {
        switch language {
        case .turkish: return "Skorlarını tüm dünya ile paylaşmak için giriş yap veya yeni bir hesap oluştur, kullanıcı adı + şifre belirle. Misafir olarak da devam edebilirsin."
        case .english: return "Sign in to share your scores with the world, or create a new account with username + password. You can still continue as guest."
        }
    }

    var labelConnectingApple: String {
        switch language {
        case .turkish: return "Apple ile bağlanılıyor..."
        case .english: return "Connecting with Apple..."
        }
    }

    var labelRegisterWithEmail: String {
        switch language {
        case .turkish: return "E-Posta İle Kayıt Ol"
        case .english: return "Register with Email"
        }
    }

    var labelContinueAsGuest: String {
        switch language {
        case .turkish: return "Misafir Olarak Devam Et"
        case .english: return "Continue as Guest"
        }
    }

    // MARK: - Leaderboard & Player Registration Localization Properties
    var labelLeaderboardProfile: String {
        switch language {
        case .turkish: return "Liderlik Tablosu Profili"
        case .english: return "Leaderboard Profile"
        }
    }

    var labelLeaderboardProfileDesc: String {
        switch language {
        case .turkish: return "Skorlarını tüm dünyaya göster ve en iyiler arasına gir."
        case .english: return "Show your scores to the world and rank among the best."
        }
    }

    var labelUsernameInGame: String {
        switch language {
        case .turkish: return "Kullanıcı Adı (Oyunda Görünecek)"
        case .english: return "Username (In-Game)"
        }
    }

    var labelUsernameValidation: String {
        switch language {
        case .turkish: return "3-20 karakter, harf/sayı/_/- kullanın"
        case .english: return "3-20 chars, use letters/numbers/-/_"
        }
    }

    var labelFullName: String {
        switch language {
        case .turkish: return "Ad Soyad"
        case .english: return "Full Name"
        }
    }

    var labelFullNameValidation: String {
        switch language {
        case .turkish: return "En az 3 karakter, sadece harf/boşluk"
        case .english: return "Min 3 chars, letters/spaces only"
        }
    }

    var labelEmailAddress: String {
        switch language {
        case .turkish: return "E-Posta Adresi"
        case .english: return "Email Address"
        }
    }

    var labelEmailValidation: String {
        switch language {
        case .turkish: return "Geçerli e-posta giriniz"
        case .english: return "Enter a valid email"
        }
    }

    var labelPassword: String {
        switch language {
        case .turkish: return "Şifre"
        case .english: return "Password"
        }
    }

    var labelPasswordValidation: String {
        switch language {
        case .turkish: return "Şifre en az 8 karakter, küçük/büyük harf ve rakam içermelidir."
        case .english: return "Password must be at least 8 characters and include uppercase, lowercase, and a number."
        }
    }

    var labelConfirmPassword: String {
        switch language {
        case .turkish: return "Şifreyi Onayla"
        case .english: return "Confirm Password"
        }
    }

    var labelPasswordMismatch: String {
        switch language {
        case .turkish: return "Şifreler eşleşmiyor"
        case .english: return "Passwords do not match"
        }
    }

    var labelAgreeTo: String {
        switch language {
        case .turkish: return "Kabul ediyorum"
        case .english: return "I agree to"
        }
    }

    var labelTermsOfService: String {
        switch language {
        case .turkish: return "Kullanım Koşulları"
        case .english: return "Terms of Service"
        }
    }

    var labelAnd: String {
        switch language {
        case .turkish: return "ve"
        case .english: return "and"
        }
    }

    var labelPrivacyPolicy: String {
        switch language {
        case .turkish: return "Gizlilik Politikası"
        case .english: return "Privacy Policy"
        }
    }

    var labelRegisteringCaps: String {
        switch language {
        case .turkish: return "KAYDEDİLİYOR..."
        case .english: return "REGISTERING..."
        }
    }

    var labelRegisterCaps: String {
        switch language {
        case .turkish: return "KAYIT OL"
        case .english: return "REGISTER"
        }
    }

    var labelRegisteredProfile: String {
        switch language {
        case .turkish: return "Kayıtlı Profil"
        case .english: return "Registered Profile"
        }
    }

    var labelUsername: String {
        switch language {
        case .turkish: return "Kullanıcı Adı"
        case .english: return "Username"
        }
    }

    var labelContinue: String {
        switch language {
        case .turkish: return "Devam Et"
        case .english: return "Continue"
        }
    }

    var labelDeleteAccount: String {
        switch language {
        case .turkish: return "Hesabımı Sil"
        case .english: return "Delete Account"
        }
    }

    var labelCancel: String {
        switch language {
        case .turkish: return "İptal"
        case .english: return "Cancel"
        }
    }

    var labelDeleteCaps: String {
        switch language {
        case .turkish: return "SİL"
        case .english: return "DELETE"
        }
    }

    var labelDeleteAccountDesc: String {
        switch language {
        case .turkish: return "Bu işlem geri alınamaz. Tüm verileriniz silinecek ve Leaderboard sıralamasından çıkarılacaksınız."
        case .english: return "This action cannot be undone. All your data will be deleted and you will be removed from the leaderboard."
        }
    }

    var labelUsernameTaken: String {
        switch language {
        case .turkish: return "Bu kullanıcı adı daha önce kullanılmış. Başka bir ad seçiniz."
        case .english: return "This username is already taken. Please choose another."
        }
    }

    var labelRegistrationSuccessful: String {
        switch language {
        case .turkish: return "Kayıt başarılı!"
        case .english: return "Registration successful!"
        }
    }

    var labelEmailTaken: String {
        switch language {
        case .turkish: return "Bu e-posta zaten kayıtlı. Farklı bir e-posta deneyin."
        case .english: return "This email is already registered. Please use another email."
        }
    }

    var labelDeleteFailedTemplate: String {
        switch language {
        case .turkish: return "Silme işlemi başarısız oldu: {{error}}"
        case .english: return "Failed to delete account: {{error}}"
        }
    }

    // MARK: - Phase 8: Daily Reward API

    /// 24 saat geçtiyse claim hakkı var. İlk kez girenler için de true.
    var canClaimDaily: Bool {
        let now = Date().timeIntervalSince1970
        return (now - lastDailyClaimTimestamp) >= 24 * 60 * 60
    }

    /// Bir sonraki claim'e kalan saniye. 0 = hazır.
    var secondsUntilNextDaily: TimeInterval {
        let now = Date().timeIntervalSince1970
        let delta = 24 * 60 * 60 - (now - lastDailyClaimTimestamp)
        return max(0, delta)
    }

    /// Ödülü talep eder ve verilen tier'ı döner. Çağıran UI feedback üretir.
    /// Streak mantığı: önceki claim 24-48h penceresinde ise streak++; 48h
    /// geçtiyse streak 1'e resetlenir. İlk kez claim'de streak = 1.
    @discardableResult
    func claimDailyReward() -> DailyRewardTier? {
        guard canClaimDaily else { return nil }
        let now = Date().timeIntervalSince1970
        let elapsed = now - lastDailyClaimTimestamp
        if lastDailyClaimTimestamp == 0 {
            dailyStreak = 1
        } else if elapsed <= 48 * 60 * 60 {
            dailyStreak += 1
        } else {
            dailyStreak = 1
        }
        let tier = DailyRewardSchedule.reward(forStreakDay: dailyStreak)
        earn(gold: tier.gold)
        if tier.diamonds > 0 { earn(diamonds: tier.diamonds) }
        lastDailyClaimTimestamp = now
        reportAchievement("streak_7", progress: dailyStreak)
        return tier
    }

    // MARK: - Phase 8: Achievement API

    /// Kümülatif delta raporla (ör. +1 boss yenildi). Progress güncellenir ve
    /// gerekiyorsa unlock edilir. Aynı id tekrar gelirse progress artar ama
    /// unlock tekrarı yapılmaz.
    func reportAchievement(_ id: String, progress newValue: Int) {
        guard let achievement = AchievementEngine.achievement(for: id) else { return }
        // Progress düşmesin: kümülatif stat olarak tut.
        let current = achievementProgress[id] ?? 0
        let updated = max(current, newValue)
        if updated != current { achievementProgress[id] = updated }
        if updated >= achievement.goal && !unlockedAchievementIDs.contains(id) {
            unlockedAchievementIDs.insert(id)
            if achievement.rewardGold > 0 { earn(gold: achievement.rewardGold) }
            if achievement.rewardDiamonds > 0 { earn(diamonds: achievement.rewardDiamonds) }
            AudioManager.shared.playSFX(.perkUnlock)
            pendingAchievementToastId = id
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak self] in
                if self?.pendingAchievementToastId == id {
                    self?.pendingAchievementToastId = nil
                }
            }
        }
    }

    /// Kısayol: +delta ile rapor.
    func bumpAchievement(_ id: String, by delta: Int = 1) {
        let current = achievementProgress[id] ?? 0
        reportAchievement(id, progress: current + delta)
    }

    // MARK: - Character Mastery API

    /// Bir karakterin bölüm clear'ını kaydet. Kümülatif max tutulur.
    func recordCharacterChapterClear(characterId: String, chapter: Int) {
        guard !characterId.isEmpty, chapter > 0 else { return }
        let current = characterMaxChapter[characterId] ?? 0
        guard chapter > current else { return }

        characterMaxChapter[characterId] = chapter

        // First-time character clear bonus (1 kez / chapter / character)
        // Satın alma motivasyonu: premium karakterle yeni chapter bitirmek “ödül” verir.
        // (Farm engeli: sadece max chapter artınca tetiklenir.)
        let baseGold = 150 + min(20, chapter) * 25
        let baseDiamonds = 3 + min(20, chapter) / 2

        earn(gold: baseGold)
        earn(diamonds: baseDiamonds)
        AudioManager.shared.playSFX(.perkUnlock)
    }

    /// Bir karakterin şu ana kadar ulaştığı en yüksek chapter.
    func maxChapter(for characterId: String) -> Int {
        characterMaxChapter[characterId] ?? 0
    }

    /// Karakter %100 master'lanmış mı? (Ch20 = son bölüm)
    func isCharacterMastered(_ characterId: String) -> Bool {
        maxChapter(for: characterId) >= 20
    }

    // MARK: - Questline helpers

    private func todayKey() -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.calendar = Calendar(identifier: .gregorian)
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }

    func questDay(for characterId: String) -> Int {
        min(7, max(1, characterQuestDay[characterId] ?? 1))
    }

    func questProgress(for characterId: String) -> Int {
        max(0, characterQuestProgress[characterId] ?? 0)
    }

    func canAdvanceQuestToday(for characterId: String) -> Bool {
        let today = todayKey()
        return characterQuestLastAdvanceDay[characterId] != today
    }

    func resetQuestProgress(for characterId: String) {
        characterQuestProgress[characterId] = 0
    }

    /// Quest event raporla. Aktif quest bu event'i dinliyorsa progress artar.
    func reportQuestEvent(characterId: String, event: CharacterQuestEvent, amount: Int = 1) {
        guard !characterId.isEmpty, amount > 0 else { return }
        // Aynı karakter quest zincirinde günde 1 adım kuralı:
        // Bir quest tamamlanıp gün ilerlediğinde (lastAdvanceDay=today), yeni
        // quest'e aynı gün progress yazmayı durduruyoruz.
        guard canAdvanceQuestToday(for: characterId) else { return }
        guard let quest = CharacterQuestEngine.currentQuest(for: characterId, day: questDay(for: characterId)) else { return }
        guard quest.event == event else { return }

        let updated = min(quest.goal, questProgress(for: characterId) + amount)
        characterQuestProgress[characterId] = updated

        if updated >= quest.goal && canAdvanceQuestToday(for: characterId) {
            if quest.rewardGold > 0 { earn(gold: quest.rewardGold) }
            if quest.rewardDiamonds > 0 { earn(diamonds: quest.rewardDiamonds) }
            AudioManager.shared.playSFX(.perkUnlock)

            // Advance day
            characterQuestLastAdvanceDay[characterId] = todayKey()
            characterQuestDay[characterId] = min(7, questDay(for: characterId) + 1)
            characterQuestProgress[characterId] = 0
        }
    }

    func isQuestLockedToday(for characterId: String) -> Bool {
        !canAdvanceQuestToday(for: characterId)
    }

    // MARK: - Registration Helpers

    func clearRegistration() {
        self.isRegistered = false
        self.fullName = ""
        self.email = ""
        self.passwordHash = ""
    }

    func setLeaderboardPassword(_ password: String) {
        guard !password.isEmpty else { return }
        self.passwordHash = Self.sha256(password)
    }

    func verifyLeaderboardPassword(_ password: String) -> Bool {
        guard !password.isEmpty, !passwordHash.isEmpty else { return false }
        return passwordHash == Self.sha256(password)
    }

    func verifyLeaderboardLogin(email: String, password: String) -> Bool {
        return email.caseInsensitiveCompare(self.email) == .orderedSame && verifyLeaderboardPassword(password)
    }

    private static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Cosmetics API

    func ownsCosmetic(_ id: String) -> Bool {
        ownedCosmeticIDs.contains(id)
    }

    func unlockCosmetic(_ id: String) {
        guard !id.isEmpty else { return }
        ownedCosmeticIDs.insert(id)
    }

    // MARK: - Phase 8: Leaderboard API

    /// Run sonunda çağrılır. Top-5'e düşerse ekler, değilse atar.
    func recordRun(score: Int, worldLevelReached: Int) {
        guard score > 0 else { return }
        let entry = LocalScoreEntry(
            score: score,
            characterID: selectedCharacterID,
            worldLevelReached: worldLevelReached,
            timestamp: Date().timeIntervalSince1970
        )
        var list = topScores
        list.append(entry)
        list.sort { $0.score > $1.score }
        topScores = Array(list.prefix(5))
        reportAchievement("score_10k", progress: max(score, achievementProgress["score_10k"] ?? 0))
    }
}
