//
//  RoundData.swift
//  Block-Jack
//

import Foundation

// MARK: - Boss Modifier
enum BossModifier: String, Codable, CaseIterable {
    case glitch   // Random cells locked
    case fog      // Timer bar hidden
    case weight   // Heavy blocks (2 hits)
    case phantom  // Blocks flicker in/out
    
    var title: String {
        switch self {
        case .glitch: return "GLITCH"
        case .fog: return "FOG"
        case .weight: return "WEIGHT"
        case .phantom: return "PHANTOM"
        }
    }
    
    var description: String {
        switch self {
        case .glitch: return "Some cells are locked."
        case .fog: return "The timer limit is hidden."
        case .weight: return "Blocks are heavy. 2 hits needed!"
        case .phantom: return "Placed blocks are flickering."
        }
    }
}

// MARK: - Round Data
struct RoundData {
    let roundNumber: Int
    let targetScore: Int
    let moveLimit: Int
    let timeLimit: Double       // saniye
    let modifier: BossModifier?
    
    var isBossRound: Bool { roundNumber % 5 == 0 && roundNumber > 0 }

    /// R1:500, R2:1200, R3:2100, R4:3200, R5(boss):4800...
    static func makeTarget(for round: Int) -> Int {
        // Taban: round başı 500, her round +700 artar, üstelişel
        let base = 500 + (round - 1) * 700 + (round - 1) * (round - 1) * 50
        
        if round % 5 == 0 && round > 0 {
            let bossIndex = round / 5
            let bump = 1.25 + Double(bossIndex) * 0.15 // 8x8 avantajı için %25 taban artışı
            return Int(Double(base) * bump)
        }
        return Int(Double(base) * 1.25) // Normal roundlar için de %25 artış
    }

    static func make(round: Int, modifier: BossModifier? = nil) -> RoundData {
        RoundData(
            roundNumber: round,
            targetScore: makeTarget(for: round),
            moveLimit: 300,
            timeLimit: max(25.0, 90.0 - Double(round - 1) * 5.0), // R1: 90s, R2: 85s... min 25s
            modifier: (round % 5 == 0 && round > 0) ? (modifier ?? BossModifier.allCases.randomElement()) : nil
        )
    }
}

// MARK: - Run State
struct RunState {
    var currentRound: Int = 1
    var currentScore: Int = 0
    var movesUsed: Int = 0
    var streak: Int = 0
    var halfBonusGiven: Bool = false
    var gold: Int = 0
    var activeModifier: BossModifier? = nil
    var currentRoundTargetScore: Int = 500 // Dynamic target for perks
    
    // NEW PHASE 1 VARIABLES
    var activePassivePerks: [PassivePerk] = []
    var inventory: [ConsumableItem] = []
    var currentOverdriveTier: OverdriveTier = .none
    var tensionCount: Int = 0
    var clockworkBonus: Double = 0.0
    var currentChapterMap: ChapterMap? = nil
    var completedNodeIds: Set<UUID> = []
    var overkillCarryover: Int = 0
    var sculptorUses: Int = 0
    
    // NEW PERK FLAGS
    var maxTraySlots: Int = 3
    var lastStandUsed: Bool = false
    var undyingRageActive: Bool = false
    
    // MARK: - Lives System (Balatro tarzı)
    var lives: Int = 3
    var maxLives: Int = 5
    
    mutating func loseLife() { lives = max(0, lives - 1) }
    mutating func gainLife() { lives = min(maxLives, lives + 1) }
    var isGameOver: Bool { lives <= 0 }

    var round: RoundData { RoundData.make(round: currentRound, modifier: activeModifier) }

    var scoreProgress: Double {
        let target = currentRoundTargetScore > 0 ? currentRoundTargetScore : round.targetScore
        guard target > 0 else { return 0 }
        return min(1.0, Double(currentScore) / Double(target))
    }

    var movesRemaining: Int { round.moveLimit - movesUsed }

    mutating func addScore(_ points: Int) {
        currentScore += points
    }

    mutating func nextRound() {
        currentRound += 1
        currentScore = 0
        movesUsed = 0
        streak = 0
        halfBonusGiven = false
        
        if currentRound % 5 == 0 {
            activeModifier = BossModifier.allCases.randomElement()
        } else {
            activeModifier = nil
        }
        
        // Reset dynamic target for the new round
        currentRoundTargetScore = round.targetScore
    }
    
    // MARK: - Perk Helpers
    func hasPerk(_ id: String) -> Bool {
        activePassivePerks.contains { $0.id == id }
    }
    
    func perkTier(_ id: String) -> Int {
        activePassivePerks.first(where: { $0.id == id })?.tier ?? 0
    }
}
