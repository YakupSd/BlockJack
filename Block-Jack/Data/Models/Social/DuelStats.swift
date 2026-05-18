//
//  DuelStats.swift
//  Block-Jack
//

import Foundation

// MARK: - Duel Statistics
struct DuelStats: Codable, Identifiable {
    let id: String = UUID().uuidString
    
    let finalScore:      Int
    let linesCleared:    Int
    let zonesCleared:    Int
    let maxCombo:        Int
    let blocksPlaced:    Int
    let goldEarned:      Int
    let roundsPlayed:    Int
    let durationSeconds: Int
    let usedCharacter:   String   // karakter ID'si
    let perksActivated:  [String] // aktifleşen perk ID'leri
    
    // Mock initializer
    init(
        finalScore: Int,
        linesCleared: Int = 0,
        zonesCleared: Int = 0,
        maxCombo: Int = 0,
        blocksPlaced: Int = 0,
        goldEarned: Int = 0,
        roundsPlayed: Int = 0,
        durationSeconds: Int = 0,
        usedCharacter: String = "cyber_ninja",
        perksActivated: [String] = []
    ) {
        self.finalScore = finalScore
        self.linesCleared = linesCleared
        self.zonesCleared = zonesCleared
        self.maxCombo = maxCombo
        self.blocksPlaced = blocksPlaced
        self.goldEarned = goldEarned
        self.roundsPlayed = roundsPlayed
        self.durationSeconds = durationSeconds
        self.usedCharacter = usedCharacter
        self.perksActivated = perksActivated
    }
}
