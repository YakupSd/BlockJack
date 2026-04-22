//
//  UserEnvironment.swift
//  Block-Jack
//

import Combine
import OSLog
import SwiftUI

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
    
    func descTR(level: Int) -> String {
        switch self {
        case .comboTime: return "Kombo süresi +\(level * 10)% daha yavaş düşer"
        case .startBonus: return "Round başında +\(level * 50) puan bonusı"
        case .overdriveFill: return "Overdrive +\(level * 10)% daha hızlı dolar"
        case .blockLuck: return "\(level * 5)% ihtimalle nadide blok gelir"
        case .goldMagnet: return "Her round +\(level * 10) altın kazancı"
        }
    }
    
    func descEN(level: Int) -> String {
        switch self {
        case .comboTime: return "Combo timer is \(level * 10)% slower"
        case .startBonus: return "+\(level * 50) score bonus at round start"
        case .overdriveFill: return "Overdrive fills \(level * 10)% faster"
        case .blockLuck: return "\(level * 5)% chance for rare block"
        case .goldMagnet: return "+\(level * 10) gold bonus per round"
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

        // 2. Perform post-init logic (Testing Boost etc.)
        if self.diamonds < 50000 {
            self.diamonds = 50000
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
        diamonds -= amount
        return true
    }

    func earn(gold amount: Int) {
        if let slotId = activeSlotId {
            SaveManager.shared.updateGold(slotId: slotId, amount: amount)
        } else {
            gold += amount
        }
    }
    func earn(diamonds amount: Int) { diamonds += amount }
    
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
        self.goldUpgradeLevels = slot.goldUpgradeLevels
        self.unlockedUpgradeIDs = slot.unlockedMetaUpgradeIDs
        self.gold = slot.gold
        // Slot bazlı karakter: Hub ve ekranlar aktif slot'un karakterini
        // okuyabilsin diye global `selectedCharacterID`'yi slot değerine
        // senkron ediyoruz. Slot'ta karakter yoksa (eski kayıt) mevcut
        // global değer korunur.
        if let cid = slot.characterId, !cid.isEmpty {
            self.selectedCharacterID = cid
        }
    }

    /// Aktif slot bağlamını kapatır. Dashboard'a dönerken çağrılır; böylece
    /// global cüzdana yapılacak `spend/earn` çağrıları yanlışlıkla yakın
    /// zamanda kapatılmış slot'a yönlendirilmez.
    func clearActiveSlot() {
        self.activeSlotId = nil
    }
    
    func localizedString(_ trText: String, _ enText: String) -> String {
        language == .turkish ? trText : enText
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
        if chapter > current {
            characterMaxChapter[characterId] = chapter
        }
    }

    /// Bir karakterin şu ana kadar ulaştığı en yüksek chapter.
    func maxChapter(for characterId: String) -> Int {
        characterMaxChapter[characterId] ?? 0
    }

    /// Karakter %100 master'lanmış mı? (Ch20 = son bölüm)
    func isCharacterMastered(_ characterId: String) -> Bool {
        maxChapter(for: characterId) >= 20
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
