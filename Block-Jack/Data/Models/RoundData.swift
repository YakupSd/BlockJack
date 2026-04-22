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

    /// Scoring v2 ile eşleşen hedefler:
    /// R1:~1500, R2:~3375, R3:~5550, R4:~8025, R5(boss):~12000, R10(boss):~30000
    /// PLUS: World Level scaling (+25% per level)
    ///
    /// NOT: Skor tabanı (ScoreEngine.calculate) ~2.5x büyütüldü, target'ı da
    /// benzer oranda büyütüyoruz ki round pacing eskisiyle aynı hissetsin —
    /// ama sayılar artık "juice'lu" (hızlı artıyor, büyük combo'da ekran
    /// patlıyor). Oyuncu önceki R1 ~625 yerine ~1500 hedef görüyor, ama bir
    /// tek double-clear ile ~5000 puan kazanabildiği için round çok daha
    /// tatmin edici kapanıyor.
    static func makeTarget(for round: Int, worldLevel: Int = 1) -> Int {
        // SCORING v2 sonrası (combo/zone/flush çok daha büyük) pacing fix:
        // Hedefi yukarı çekiyoruz ki tek bir mega-clear çoğu zaman round'u
        // tek atışta geçirmesin; yine de 2-4 hamlede “juice” hissi sürsün.
        let r = max(1, round)
        let wl = max(1, worldLevel)

        // Taban eğri: lineer + kuadratik + hafif üstel (round büyüdükçe hızlanır)
        let rr = Double(r - 1)
        let base = 2200.0 + rr * 2600.0 + rr * rr * 220.0

        // World Level çarpanı: daha agresif (W10+ modifier’larla skor da artıyor)
        let worldMultiplier = 1.0 + Double(wl - 1) * 0.35

        // Global pacing: her durumda hedefi yukarı çeker
        var finalTarget = base * worldMultiplier

        // Boss round’lar doğal olarak daha sert
        if r % 5 == 0 && r > 0 {
            let bossIndex = r / 5
            let bump = 1.6 + Double(bossIndex) * 0.22
            finalTarget *= bump
        } else {
            finalTarget *= 2.1
        }

        // Alt sınır: round 1 bile “tek patlatma ile bitmesin”
        return max(3500, Int(finalTarget.rounded()))
    }

    static func make(round: Int, worldLevel: Int = 1, modifier: BossModifier? = nil) -> RoundData {
        // Süre: Round 1 = 240sn, her round -3sn azalır, minimum 180sn
        let timeLimit = max(180.0, 240.0 - Double(round - 1) * 3.0)
        return RoundData(
            roundNumber: round,
            targetScore: makeTarget(for: round, worldLevel: worldLevel),
            moveLimit: 300,
            timeLimit: timeLimit,
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
    var worldLevel: Int = 1 // New: Current world level for scaling
    
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

    var round: RoundData { RoundData.make(round: currentRound, worldLevel: worldLevel, modifier: activeModifier) }

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
