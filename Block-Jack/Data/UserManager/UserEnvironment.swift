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
        }
    }
    
    // MARK: - Gold Upgrade Levels
    @Published var goldUpgradeLevels: [String: Int] {
        didSet {
            if let data = try? JSONEncoder().encode(goldUpgradeLevels) {
                UserDefaults.standard.set(data, forKey: "goldUpgradeLevels")
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
        
        // 2. Perform post-init logic (Testing Boost etc.)
        if self.diamonds < 50000 {
            self.diamonds = 50000
        }
    }

    // MARK: - Helpers
    func updateHighScore(_ newScore: Int) {
        if newScore > highScore { highScore = newScore }
    }

    func spend(gold amount: Int) -> Bool {
        guard gold >= amount else { return false }
        gold -= amount
        return true
    }
    
    func spend(diamonds amount: Int) -> Bool {
        guard diamonds >= amount else { return false }
        diamonds -= amount
        return true
    }

    func earn(gold amount: Int) { gold += amount }
    func earn(diamonds amount: Int) { diamonds += amount }
    
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

    func localizedString(_ trText: String, _ enText: String) -> String {
        language == .turkish ? trText : enText
    }
}
