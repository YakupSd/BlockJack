//
//  CareerStatsViewModel.swift
//  Block-Jack
//

import Foundation
import Combine

class CareerStatsViewModel: ObservableObject {
    @Published var careerStats: CareerStats = CareerStats()
    @Published var isLoading: Bool = false
    
    private let userEnv: UserEnvironment
    private var cancellables = Set<AnyCancellable>()
    
    init(userEnv: UserEnvironment = .shared) {
        self.userEnv = userEnv
        loadCareerStats()
    }
    
    // MARK: - Data Loading
    private func loadCareerStats() {
        if let data = UserDefaults.standard.data(forKey: "careerStats") {
            do {
                self.careerStats = try JSONDecoder().decode(CareerStats.self, from: data)
            } catch {
                print("[CareerVM] Career stats load failed: \(error)")
                self.careerStats = CareerStats()
                UserDefaults.standard.removeObject(forKey: "careerStats")
            }
        } else {
            self.careerStats = CareerStats()
        }
    }
    
    // MARK: - Save Career Stats
    private func saveCareerStats() {
        do {
            let data = try JSONEncoder().encode(careerStats)
            UserDefaults.standard.set(data, forKey: "careerStats")
        } catch {
            print("[CareerVM] Career stats save failed: \(error)")
        }
    }
    
    // MARK: - Recording a Run
    func recordRunCompletion(
        characterID: String,
        score: Int,
        damageDealt: Int,
        linesCleared: Int,
        bossesDefeated: Int,
        usedPerks: [String],
        duration: TimeInterval,
        chapter: Int
    ) {
        let entry = CareerStatEntry(
            runID: UUID().uuidString,
            characterID: characterID,
            score: score,
            damageDealt: damageDealt,
            linesCleared: linesCleared,
            bossesDefeated: bossesDefeated,
            usedPerks: usedPerks,
            duration: duration,
            date: Date(),
            chapter: chapter
        )
        
        // Update overall stats
        careerStats.totalDamageDealt += damageDealt
        careerStats.totalLinesCleared += linesCleared
        careerStats.totalBossesDefeated += bossesDefeated
        careerStats.totalRunsCompleted += 1
        careerStats.totalPlayTime += duration
        
        // Add to recent runs
        careerStats.recentRuns.insert(entry, at: 0)
        if careerStats.recentRuns.count > 50 {
            careerStats.recentRuns.removeLast()
        }
        
        // Update character-specific stats
        updateCharacterStats(characterID: characterID, entry: entry, newScore: score)
        
        // Update perk-specific stats
        for perkID in usedPerks {
            updatePerkStats(perkID: perkID, score: score, damageDealt: damageDealt)
        }
        
        // Update favorite character
        updateFavoriteCharacter()
        
        // Add mastery XP
        addMasteryXP(damageDealt: damageDealt, bossesDefeated: bossesDefeated)
        
        // Check for title unlocks
        checkTitleUnlocks()
        
        // Save
        saveCareerStats()
    }
    
    // MARK: - Character Stats Tracking
    private func updateCharacterStats(characterID: String, entry: CareerStatEntry, newScore: Int) {
        var charStats = careerStats.characterStats[characterID] ?? CharacterCareerStats(characterID: characterID)
        
        charStats.runsCompleted += 1
        charStats.totalDamageDealt += entry.damageDealt
        charStats.averageScore = (charStats.averageScore * (charStats.runsCompleted - 1) + newScore) / charStats.runsCompleted
        charStats.highestScore = max(charStats.highestScore, newScore)
        
        // Update preferred perk
        if let firstPerk = entry.usedPerks.first {
            charStats.preferredPerkID = firstPerk
        }
        
        careerStats.characterStats[characterID] = charStats
        
        if careerStats.totalCharactersUnlocked < careerStats.characterStats.count {
            careerStats.totalCharactersUnlocked = careerStats.characterStats.count
        }
    }
    
    // MARK: - Perk Stats Tracking
    private func updatePerkStats(perkID: String, score: Int, damageDealt: Int) {
        var perkStats = careerStats.perkStats[perkID] ?? PerkCareerStats(perkID: perkID)
        
        perkStats.timesUsed += 1
        perkStats.averageRunScore = (perkStats.averageRunScore * (perkStats.timesUsed - 1) + score) / perkStats.timesUsed
        perkStats.totalDamageDealt += damageDealt
        
        careerStats.perkStats[perkID] = perkStats
        
        // Update most used perk
        updateMostUsedPerk()
    }
    
    // MARK: - Favorite Character
    private func updateFavoriteCharacter() {
        var maxRuns = 0
        var favoriteID = ""
        
        for (charID, stats) in careerStats.characterStats {
            if stats.runsCompleted > maxRuns {
                maxRuns = stats.runsCompleted
                favoriteID = charID
            }
        }
        
        careerStats.favoriteCharacterID = favoriteID
    }
    
    // MARK: - Most Used Perk
    private func updateMostUsedPerk() {
        var maxUses = 0
        var mostUsedID = ""
        
        for (perkID, stats) in careerStats.perkStats {
            if stats.timesUsed > maxUses {
                maxUses = stats.timesUsed
                mostUsedID = perkID
            }
        }
        
        careerStats.mostUsedPerkID = mostUsedID
    }
    
    // MARK: - Mastery XP System
    private func addMasteryXP(damageDealt: Int, bossesDefeated: Int) {
        // 1 damage = 0.01 XP, each boss = 100 XP
        let damageXP = damageDealt / 100
        let bossXP = bossesDefeated * 100
        
        careerStats.masteryXP += (damageXP + bossXP)
    }
    
    // MARK: - Title/Achievement Checking
    private func checkTitleUnlocks() {
        // Grid Slayer: 500+ lines cleared
        if careerStats.totalLinesCleared >= 500 && !careerStats.unlockedTitles.contains(SpecialTitle.gridSlayer.rawValue) {
            careerStats.unlockedTitles.insert(SpecialTitle.gridSlayer.rawValue)
        }
        
        // Damage Dealer: 10M+ damage
        if careerStats.totalDamageDealt >= 10_000_000 && !careerStats.unlockedTitles.contains(SpecialTitle.damageDealer.rawValue) {
            careerStats.unlockedTitles.insert(SpecialTitle.damageDealer.rawValue)
        }
        
        // Perk Collector: 50+ different perks
        if careerStats.perkStats.count >= 50 && !careerStats.unlockedTitles.contains(SpecialTitle.perkCollector.rawValue) {
            careerStats.unlockedTitles.insert(SpecialTitle.perkCollector.rawValue)
        }
        
        // Boss Hunter: 100+ bosses
        if careerStats.totalBossesDefeated >= 100 && !careerStats.unlockedTitles.contains(SpecialTitle.bossHunter.rawValue) {
            careerStats.unlockedTitles.insert(SpecialTitle.bossHunter.rawValue)
        }
        
        // Speed Runner: 50 runs under 5 minutes
        let speedRuns = careerStats.recentRuns.filter { $0.duration < 300 }.count
        if speedRuns >= 50 && !careerStats.unlockedTitles.contains(SpecialTitle.speedRunner.rawValue) {
            careerStats.unlockedTitles.insert(SpecialTitle.speedRunner.rawValue)
        }
        
        // Eternal: Mastery Level 5
        if careerStats.masteryLevel.level >= 5 && !careerStats.unlockedTitles.contains(SpecialTitle.eternal.rawValue) {
            careerStats.unlockedTitles.insert(SpecialTitle.eternal.rawValue)
        }
        
        // Time Keeper: 1000+ hours
        if careerStats.totalPlayTime >= 3600000 && !careerStats.unlockedTitles.contains(SpecialTitle.timeKeeper.rawValue) { // 1000 hours in seconds
            careerStats.unlockedTitles.insert(SpecialTitle.timeKeeper.rawValue)
        }
    }
    
    // MARK: - Stats Getters
    func getCharacterStats(for characterID: String) -> CharacterCareerStats? {
        return careerStats.characterStats[characterID]
    }
    
    func getPerkStats(for perkID: String) -> PerkCareerStats? {
        return careerStats.perkStats[perkID]
    }
    
    func getFormattedDamage(_ damage: Int) -> String {
        if damage >= 1_000_000 {
            return String(format: "%.1fM", Double(damage) / 1_000_000)
        } else if damage >= 1_000 {
            return String(format: "%.1fK", Double(damage) / 1_000)
        }
        return "\(damage)"
    }
    
    func getFormattedPlayTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    func getTitleStatus(for title: SpecialTitle) -> (unlocked: Bool, progress: String) {
        let unlocked = careerStats.unlockedTitles.contains(title.rawValue)
        
        var progress = ""
        switch title {
        case .gridSlayer:
            progress = "\(careerStats.totalLinesCleared) / 500"
        case .damageDealer:
            progress = "\(getFormattedDamage(careerStats.totalDamageDealt)) / 10M"
        case .perkCollector:
            progress = "\(careerStats.perkStats.count) / 50"
        case .bossHunter:
            progress = "\(careerStats.totalBossesDefeated) / 100"
        case .speedRunner:
            let speedRuns = careerStats.recentRuns.filter { $0.duration < 300 }.count
            progress = "\(speedRuns) / 50"
        case .eternal:
            progress = "Level \(careerStats.masteryLevel.level) / 5"
        case .timeKeeper:
            progress = "\(Int(careerStats.totalPlayTime / 3600)) / 1000h"
        case .perfectRun:
            progress = "Special"
        }
        
        return (unlocked, progress)
    }
}
