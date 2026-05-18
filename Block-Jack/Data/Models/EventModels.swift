import SwiftUI

// ============================================================
// EVENT MODELS
// ============================================================

// MARK: - EventType & RankingMetric
enum EventType: String, Codable, CaseIterable {
    case daily, weekly
    
    var label: String {
        self == .daily ? "GÜNLÜK" : "HAFTALIK"
    }
}

enum RankingMetric: String, Codable {
    case score
    case zoneCount
    case comboCount
    case goldEarned
}

// MARK: - EventConfig
struct EventConfig: Codable, Identifiable {
    let id:           String
    let type:         EventType
    let title:        String
    let description:  String
    let startsAt:     Date
    let endsAt:       Date
    
    let modifiers:    [EventModifier]
    let boss:         EventBoss
    let character:    EventCharacter?
    let rewards:      [EventReward]
    let rankingMetric: RankingMetric
    
    var isActive: Bool { Date() >= startsAt && Date() <= endsAt }
    var timeRemaining: TimeInterval { endsAt.timeIntervalSince(Date()) }
    var timeRemainingSince: String {
        let remaining = timeRemaining
        if remaining < 0 { return "BITTI" }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        return "\(hours)s \(minutes)d"
    }
}

// MARK: - EventModifier
struct EventModifier: Codable, Identifiable {
    let id:          String
    let type:        ModifierType
    let value:       Double
    let description: String
    let iconName:    String
}

enum ModifierType: String, Codable {
    case blockSpeedMultiplier
    case goldPerLineClear
    case scoreMultiplier
    case infiniteTime
    case noShuffle
    case mirrorBoard
    case ghostBlocks
    case extraLife
}

// MARK: - EventBoss
struct EventBoss: Codable {
    let id:          String
    let name:        String
    let description: String
    let spriteKey:   String
    let intents:     [BossIntent]
    let intentCycle: Int
}

struct BossIntent: Codable, Identifiable {
    let id:          String
    let type:        BossIntentType
    let value:       Int
    let description: String
}

enum BossIntentType: String, Codable {
    case lockCells
    case stealTime
    case blockTray
    case addJunkRow
    case shuffleBoard
    case invertControls
    
    var emoji: String {
        switch self {
        case .lockCells:      return "🔒"
        case .stealTime:      return "⏱️"
        case .blockTray:      return "📦"
        case .addJunkRow:     return "🚫"
        case .shuffleBoard:   return "🔀"
        case .invertControls: return "🔄"
        }
    }
}

// MARK: - EventCharacter
struct EventCharacter: Codable, Identifiable {
    let id:           String
    let name:         String
    let description:  String
    let spriteKey:    String
    let isExclusive:  Bool
    let bonusModifiers: [EventModifier]
}

// MARK: - EventReward
struct EventReward: Codable, Identifiable {
    let id:         String
    let rankFrom:   Int
    let rankTo:     Int
    let diamonds:   Int
    let gold:       Int
    let perkUnlock: String?
    let label:      String
}

// MARK: - EventPerk (Tier 1 only)
struct EventPerk: Identifiable, Hashable {
    let id:          String
    let name:        String
    let description: String
    let iconName:    String
    let tier:        Int
    let effect:      String  // "scoreMultiplier", "goldBonus", etc.
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: EventPerk, rhs: EventPerk) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - EventSessionState
struct EventSessionState {
    var currentRound:    Int = 1
    var totalScore:      Int = 0
    var goldEarned:      Int = 0
    var lives:           Int = 3
    var maxLives:        Int = 3
    var activePerks:     [EventPerk] = []
    var pendingPerkChoice: [EventPerk]? = nil
    var bossIntentIndex: Int = 0
    var metricValue:     Int = 0
    var isGameOver:      Bool = false
    
    mutating func advanceRound() {
        currentRound += 1
    }
    
    var nextPerkRound: Int {
        let nextMultiple = ((currentRound / 5) + 1) * 5
        return nextMultiple
    }
    
    var roundsUntilPerk: Int {
        nextPerkRound - currentRound
    }
}

// MARK: - EventLeaderboardEntry
struct EventLeaderboardEntry: Identifiable {
    let id:       String
    let rank:     Int
    let username: String
    let score:    Int
    let metric:   Int
    let isMe:     Bool = false
}

// MARK: - Sample Event Perk Pool (PerkEngine Catalog'dan senkronize)
let eventPerkPool: [EventPerk] = [
    EventPerk(id: "momentum", name: "MOMENTUM", description: "İleri momentum + Hız bonusu", iconName: "perk_momentum", tier: 1, effect: "scoreMultiplier"),
    EventPerk(id: "glass_cannon", name: "GLASS CANNON", description: "Kırılgan ama güçlü", iconName: "perk_glass_cannon", tier: 1, effect: "critChance"),
    EventPerk(id: "overkill", name: "OVERKILL", description: "+%30 taşan hasar bonusu", iconName: "perk_overkill", tier: 1, effect: "overflowBonus"),
    EventPerk(id: "last_stand", name: "LAST STAND", description: "Son can - diriliş şansı", iconName: "perk_last_stand", tier: 1, effect: "revive"),
    EventPerk(id: "safe_house", name: "SAFE HOUSE", description: "Dinlenme +100 altın", iconName: "perk_safe_house", tier: 1, effect: "restBonus"),
    EventPerk(id: "echoes", name: "ECHOES", description: "Yankı efekti - tekrar etki", iconName: "perk_echoes", tier: 1, effect: "echoHit"),
    EventPerk(id: "wide_load", name: "WIDE LOAD", description: "+1 slot kapasitesi", iconName: "perk_wide_load", tier: 1, effect: "extraSlot"),
    EventPerk(id: "clockwork", name: "CLOCKWORK", description: "Saat mekanizması - tempo", iconName: "perk_clockwork", tier: 1, effect: "timing"),
    EventPerk(id: "sculptor", name: "SCULPTOR", description: "Blok şekli kontrolü", iconName: "perk_sculptor", tier: 1, effect: "blockShape"),
    EventPerk(id: "golden_stamp", name: "GOLDEN STAMP", description: "Puan damgası +50", iconName: "perk_golden_stamp", tier: 1, effect: "scoreStamp"),
    EventPerk(id: "blue_pill", name: "BLUE PILL", description: "Siber güçlendir +%15 puan", iconName: "perk_blue_pill", tier: 1, effect: "scoreBoost"),
    EventPerk(id: "lucky_clover", name: "LUCKY CLOVER", description: "Şans ×2 kritik", iconName: "perk_lucky_clover", tier: 1, effect: "luckyHit"),
    EventPerk(id: "lead_pill", name: "LEAD PILL", description: "Toksik ama güçlü +%25 crit", iconName: "perk_lead_pill", tier: 1, effect: "toxicCrit"),
    EventPerk(id: "midas_touch", name: "MIDAS TOUCH", description: "Altına dönüştür +30 altın", iconName: "perk_midas_touch", tier: 1, effect: "goldConverter"),
    EventPerk(id: "vampiric_core", name: "VAMPIRIC CORE", description: "Yaşam çalma +1 can", iconName: "perk_vampiric_core", tier: 1, effect: "lifeSteal"),
    EventPerk(id: "recycler", name: "RECYCLER", description: "Geri dönüşüm slot yenileme", iconName: "perk_recycler", tier: 1, effect: "slotReset"),
    EventPerk(id: "chain_pulse", name: "CHAIN PULSE", description: "Zincirleme etki +combo", iconName: "perk_chain_pulse", tier: 1, effect: "chainCombo"),
    EventPerk(id: "heavy_duty", name: "HEAVY DUTY", description: "Ağır blok x2 güç", iconName: "perk_heavy_duty", tier: 1, effect: "heavyBlock"),
    EventPerk(id: "phantom_siphon", name: "PHANTOM SIPHON", description: "Hayalet emiş +15 puan", iconName: "perk_phantom_siphon", tier: 1, effect: "spectralDrain"),
    EventPerk(id: "double_down", name: "DOUBLE DOWN", description: "Risk bahis ×2 ödül", iconName: "perk_double_down", tier: 1, effect: "doubleReward"),
    EventPerk(id: "static_charge", name: "STATIC CHARGE", description: "Statik elektrik atağı", iconName: "perk_static_charge", tier: 1, effect: "staticStrike"),
    EventPerk(id: "tactical_lens", name: "TACTICAL LENS", description: "Hedefleme bonus +accuracy", iconName: "perk_tactical_lens", tier: 1, effect: "precision"),
]
