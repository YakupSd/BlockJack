//
//  SaveModels.swift
//  Block-Jack
//

import Foundation

// MARK: - Overdrive Tier
enum OverdriveTier: Int, Codable {
    case none = 0
    case tier1 = 1
    case tier2 = 2
    case tier3 = 3
}

// MARK: - Character Progression Models
enum CharacterDifficulty: String, Codable, Hashable {
    case beginner = "BEGINNER"
    case advanced = "ADVANCED"
    case expert = "EXPERT"

    func title(lang: AppLanguage) -> String {
        switch lang {
        case .turkish:
            switch self {
            case .beginner: return "KOLAY"
            case .advanced: return "ORTA"
            case .expert: return "ZOR"
            }
        case .english:
            switch self {
            case .beginner: return "EASY"
            case .advanced: return "MEDIUM"
            case .expert: return "HARD"
            }
        }
    }
}

enum UnlockCondition: Codable, Hashable {
    case free
    case gold(Int)
    case chapterClear(Int)
    case goldAndLevel(amount: Int, level: Int) // Phase 11: Mastery
    
    var descriptionTR: String {
        switch self {
        case .free: return "Açık"
        case .gold(let amount): return "\(amount) Altın ile Açılır"
        case .chapterClear(let chapter): return "Bölüm \(chapter)'i Tamamla"
        case .goldAndLevel(let amount, let level): return "\(amount) Altın + Seviye \(level) Gerekli"
        }
    }
    
    var descriptionEN: String {
        switch self {
        case .free: return "Unlocked"
        case .gold(let amount): return "Unlocks with \(amount) Gold"
        case .chapterClear(let chapter): return "Clear Chapter \(chapter)"
        case .goldAndLevel(let amount, let level): return "\(amount) Gold + Reach Level \(level)"
        }
    }

    func description(lang: AppLanguage) -> String {
        switch lang {
        case .turkish: return descriptionTR
        case .english: return descriptionEN
        }
    }
}


// MARK: - Character Model
struct GameCharacter: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let passiveDescTR: String
    let passiveDescEN: String
    let activeDescTR: String
    let activeDescEN: String
    let isPremium: Bool
    let cost: Int
    var overdriveThresholds: [Double] = [0.33, 0.66, 1.0] // Default
    
    // Phase 7: Lore & İstatistikler
    let loreTR: String
    let loreEN: String
    let favoriteBlockType: BlockType
    let strongModeTR: String
    let strongModeEN: String
    let difficulty: CharacterDifficulty
    let unlockCondition: UnlockCondition

    func passiveDesc(lang: AppLanguage) -> String {
        switch lang {
        case .turkish: return passiveDescTR
        case .english: return passiveDescEN
        }
    }

    func activeDesc(lang: AppLanguage) -> String {
        switch lang {
        case .turkish: return activeDescTR
        case .english: return activeDescEN
        }
    }

    func strongMode(lang: AppLanguage) -> String {
        switch lang {
        case .turkish: return strongModeTR
        case .english: return strongModeEN
        }
    }

    func lore(lang: AppLanguage) -> String {
        switch lang {
        case .turkish: return loreTR
        case .english: return loreEN
        }
    }
    
    static let roster: [GameCharacter] = [
        GameCharacter(id: "block_e", name: "BLOCK-E", icon: "port_block_e",
                      passiveDescTR: "Her 10sn sahadaki bir hücreyi temizler (max 3/tur)",
                      passiveDescEN: "Clears a cell on the board every 10s (max 3/turn)",
                      activeDescTR: "Hedefli temizlik: T1 satır, T2 çapraz, T3 3×3 bomba",
                      activeDescEN: "Targeted clean: T1 row, T2 diagonal, T3 3x3 bomb",
                      isPremium: false, cost: 0,
                      loreTR: "İlk üretilen temizlik asistanı. Yıllarca fabrikada çalıştıktan sonra yapay zekası limitleri aştı.",
                      loreEN: "The first generation cleaning assistant. Its AI broke bounds after years in the factory.",
                      favoriteBlockType: .I,
                      strongModeTR: "Satır Temizliği",
                      strongModeEN: "Row Clearing",
                      difficulty: .beginner, unlockCondition: .free),

        GameCharacter(id: "architect", name: "THE ARCHITECT", icon: "port_architect",
                      passiveDescTR: "Kare (O) bloklarla temizlikte +%30 çarpan",
                      passiveDescEN: "+30% multiplier for clears with Square (O) blocks",
                      activeDescTR: "Alan yıkımı: T1 3×3, T2 5×5, T3 7×7 +1500 puan",
                      activeDescEN: "Area destruction: T1 3x3, T2 5x5, T3 7x7 +1500 pts",
                      isPremium: true, cost: 500,
                      loreTR: "Gridin yaratıcısı. Sistemin her bir köşesini kendi elleriyle kodladı.",
                      loreEN: "Creator of the Grid. Coded every edge of the system manually.",
                      favoriteBlockType: .O,
                      strongModeTR: "Büyük Kombinasyonlar",
                      strongModeEN: "Big Combinations",
                      difficulty: .advanced, unlockCondition: .gold(500)),

        GameCharacter(id: "timebender", name: "TIME BENDER", icon: "port_timebender",
                      passiveDescTR: "Temizlikte +%50 süre, streak yavaş düşer",
                      passiveDescEN: "+50% duration on clears, streak decays slower",
                      activeDescTR: "Zaman kontrolü: T1 5sn dur, T2 8sn+tepsi, T3 3 hamle freeze",
                      activeDescEN: "Time control: T1 freeze 5s, T2 8s+tray, T3 freeze 3 moves",
                      isPremium: true, cost: 800,
                      loreTR: "Zaman algısını bükmeyi başardı. O oynarken saniyeler uzar, dakikalar kaybolur.",
                      loreEN: "Mastered twisting the perception of time. Seconds stretch as he plays.",
                      favoriteBlockType: .T,
                      strongModeTR: "Zaman Yönetimi",
                      strongModeEN: "Time Management",
                      difficulty: .advanced, unlockCondition: .gold(800)),

        GameCharacter(id: "gambler", name: "THE GAMBLER", icon: "port_gambler",
                      passiveDescTR: "%7 şansla o hamlede +9 çarpan (≈×10 combo)",
                      passiveDescEN: "7% chance for a +9 multiplier on that move (≈x10 combo)",
                      activeDescTR: "Şans tepsi: T1 1 blok, T2 tüm tepsi, T3 tepsi +2000 puan",
                      activeDescEN: "Lucky tray: T1 1 block, T2 whole tray, T3 tray +2000 pts",
                      isPremium: true, cost: 1200,
                      loreTR: "Sisteme her girişinde hayatını ortaya koyuyor. Şansı yaver giderse yıkılamaz.",
                      loreEN: "Puts his life on the line on every login. Invincible if lucky.",
                      favoriteBlockType: .J,
                      strongModeTR: "Yüksek Risk, Yüksek Ödül",
                      strongModeEN: "High Risk, High Reward",
                      difficulty: .expert, unlockCondition: .gold(1200)),

        GameCharacter(id: "neonwraith", name: "NEON WRAITH", icon: "port_neonwraith",
                      passiveDescTR: "Süre <%20 iken +2.5 çarpan (Wraith Fury)",
                      passiveDescEN: "+2.5 multiplier when time is <20% (Wraith Fury)",
                      activeDescTR: "T1 +15sn, T2 +25sn & satır temizle, T3 sonraki 3 clear +2×",
                      activeDescEN: "T1 +15s, T2 +25s & clear row, T3 next 3 clears +2x",
                      isPremium: true, cost: 3000,
                      loreTR: "Sokakların hayaleti. Kimse yüzünü görmedi. Sadece hızıyla ve ardında bıraktığı yıkımla bilinir.",
                      loreEN: "Ghost of the streets. Known only for its speed and destruction left behind.",
                      favoriteBlockType: .Z,
                      strongModeTR: "Panik Kontrolü",
                      strongModeEN: "Panic Control",
                      difficulty: .expert, unlockCondition: .goldAndLevel(amount: 3000, level: 5)),

        GameCharacter(id: "ghost", name: "GHOST", icon: "port_ghost",
                      passiveDescTR: "Her 10sn +3sn whisper zaman bonusu",
                      passiveDescEN: "+3s whisper time bonus every 10s",
                      activeDescTR: "Phantom overwrite: T1 yer, T2 +%50 clear, T3 +%100 +10sn",
                      activeDescEN: "Phantom overwrite: T1 place, T2 +50% clear, T3 +100% +10s",
                      isPremium: true, cost: 2000,
                      overdriveThresholds: [0.33, 0.66, 1.0],
                      loreTR: "Sistemin arka kapısı. O varken bloklar sessizce kaybolur.",
                      loreEN: "Backdoor of the system. Blocks vanish quietly when it's around.",
                      favoriteBlockType: .single,
                      strongModeTR: "Gizlilik ve Sabır",
                      strongModeEN: "Stealth and Patience",
                      difficulty: .expert, unlockCondition: .goldAndLevel(amount: 2000, level: 10)),

        GameCharacter(id: "alchemist", name: "ALCHEMIST", icon: "port_alchemist",
                      passiveDescTR: "Tek-renk temizlikte +1.0 çarpan (Resonance)",
                      passiveDescEN: "+1.0 multiplier on single-color clears (Resonance)",
                      activeDescTR: "T1 tepsi yenile, T2 tek-renk tepsi, T3 3 hamle ×2 puan",
                      activeDescEN: "T1 refresh tray, T2 single-color tray, T3 3 moves x2 score",
                      isPremium: true, cost: 2500,
                      overdriveThresholds: [0.4, 0.7, 1.0],
                      loreTR: "Veri tiplerini altına çevirir. Kuralları esnetir ve yeniden yazar.",
                      loreEN: "Turns data types into gold. Bends and rewrites the rules.",
                      favoriteBlockType: .L,
                      strongModeTR: "Dönüşüm Zincirleri",
                      strongModeEN: "Transmutation Chains",
                      difficulty: .advanced, unlockCondition: .goldAndLevel(amount: 2500, level: 15)),

        GameCharacter(id: "titan", name: "TITAN", icon: "port_titan",
                      passiveDescTR: "Heavy hücre temizlikte +0.5× (her heavy başına)",
                      passiveDescEN: "+0.5x on heavy cell clears (per heavy)",
                      activeDescTR: "T1 dev blok, T2 2× dev +500 overkill, T3 Earthquake +2500",
                      activeDescEN: "T1 giant block, T2 2x giant +500 overkill, T3 Earthquake +2500",
                      isPremium: true, cost: 4000,
                      overdriveThresholds: [0.5, 0.8, 1.2],
                      loreTR: "Son teknoloji savaş makinesi modifikasyonu. O düştüğünde grid titrer.",
                      loreEN: "High-tech war machine mod. The grid shakes when it drops.",
                      favoriteBlockType: .I,
                      strongModeTR: "Dev Şekiller",
                      strongModeEN: "Giant Shapes",
                      difficulty: .beginner, unlockCondition: .goldAndLevel(amount: 4000, level: 20))
    ]
}

// MARK: - Selected Perk / Starting Item
struct StartingPerk: Codable, Identifiable, Hashable {
    let id: String
    let nameTR: String
    let nameEN: String
    let icon: String
    let descTR: String
    let descEN: String
    /// 1 = ücretsiz (slot açılınca gelir), 2/3/4 = gold ile satın alınır
    var tier: Int = 1
    /// Tier 1 perkler için 0. Diğerlerinde gold maliyeti.
    var goldCost: Int = 0

    /// Slot yeni oluşturulduğunda varsayılan açık perk ID'leri (tier 1).
    static let defaultUnlockedIDs: [String] = ["golden_stamp", "overkill", "safe_house"]

    static let available: [StartingPerk] = [
        // ---- TIER 1: Ücretsiz (3 adet) ----
        StartingPerk(id: "golden_stamp", nameTR: "Golden Stamp", nameEN: "Golden Stamp", icon: "perk_golden_stamp",
                    descTR: "Hedef skor %15 azalır.", descEN: "Reduces target score by 15%.",
                    tier: 1, goldCost: 0),
        StartingPerk(id: "overkill", nameTR: "Overkill", nameEN: "Overkill", icon: "perk_overkill",
                    descTR: "Artan puanların %30'u aktarılır.", descEN: "Carries over 30% of excess score.",
                    tier: 1, goldCost: 0),
        StartingPerk(id: "safe_house", nameTR: "Safe House", nameEN: "Safe House", icon: "perk_safe_house",
                    descTR: "Dinlenme alanlarında +50 Altın verir.", descEN: "Grants +50 Gold at rest sites.",
                    tier: 1, goldCost: 0),

        // ---- TIER 2: 200 Gold ----
        StartingPerk(id: "blue_pill", nameTR: "Blue Pill", nameEN: "Blue Pill", icon: "perk_blue_pill",
                    descTR: "Mavi bloklar ×2 Chips verir", descEN: "Blue blocks grant ×2 Chips.",
                    tier: 2, goldCost: 200),
        StartingPerk(id: "lead_pill", nameTR: "Lead Pill", nameEN: "Lead Pill", icon: "perk_lead_pill",
                    descTR: "Yeşil bloklar ×2 Chips verir", descEN: "Green blocks grant ×2 Chips.",
                    tier: 2, goldCost: 200),
        StartingPerk(id: "lucky_clover", nameTR: "Lucky Clover", nameEN: "Lucky Clover", icon: "perk_lucky_clover",
                    descTR: "Her temizlikte ek çarpan sağlar", descEN: "Additional multiplier per clear.",
                    tier: 2, goldCost: 200),
        StartingPerk(id: "momentum", nameTR: "Momentum", nameEN: "Momentum", icon: "perk_momentum",
                    descTR: "4. seride çift puan verip komboyu sıfırlar", descEN: "On 4th streak: double score and reset combo.",
                    tier: 2, goldCost: 200),
        StartingPerk(id: "midas_touch", nameTR: "Midas Touch", nameEN: "Midas Touch", icon: "perk_midas_touch",
                    descTR: "Her Flush (Renkli Temizlik) +5 Altın verir", descEN: "Each Flush grants +5 Gold.",
                    tier: 2, goldCost: 200),

        // ---- TIER 3: 400 Gold ----
        StartingPerk(id: "glass_cannon", nameTR: "Glass Cannon", nameEN: "Glass Cannon", icon: "perk_glass_cannon",
                    descTR: "Can 1 iken tüm puanlar ×1.5 artar", descEN: "When at 1 life: all scores ×1.5.",
                    tier: 3, goldCost: 400),
        StartingPerk(id: "last_stand", nameTR: "Last Stand", nameEN: "Last Stand", icon: "perk_last_stand",
                    descTR: "Öldüğünde 1 kerelik ücretsiz canlanma", descEN: "Revive once for free when you die.",
                    tier: 3, goldCost: 400),
        StartingPerk(id: "wide_load", nameTR: "Wide Load", nameEN: "Wide Load", icon: "perk_wide_load",
                    descTR: "Blok haznesine ekstra 4. bir slot açar", descEN: "Unlock an extra 4th tray slot.",
                    tier: 3, goldCost: 400),
        StartingPerk(id: "sculptor", nameTR: "Sculptor", nameEN: "Sculptor", icon: "perk_sculptor",
                    descTR: "Turda blok döndürme hakkı verir", descEN: "Rotate blocks during round.",
                    tier: 3, goldCost: 400),
        StartingPerk(id: "recycler", nameTR: "Recycler", nameEN: "Recycler", icon: "perk_recycler",
                    descTR: "2+ satır silinince %20 hazne yenileme şansı", descEN: "On 2+ line clear: 20% chance to refresh tray.",
                    tier: 3, goldCost: 400),

        // ---- TIER 4: 600 Gold ----
        StartingPerk(id: "echoes", nameTR: "Echoes", nameEN: "Echoes", icon: "perk_echoes",
                    descTR: "Tur sonu, en iyi hamlenin puanını tekrar ekler", descEN: "End of round: repeat your best move score.",
                    tier: 4, goldCost: 600),
        StartingPerk(id: "clockwork", nameTR: "Clockwork", nameEN: "Clockwork", icon: "perk_clockwork",
                    descTR: "Kazanılan süre ilerledikçe bonus çarpan ekler", descEN: "Time gained gradually adds a bonus multiplier.",
                    tier: 4, goldCost: 600),
        StartingPerk(id: "vampiric_core", nameTR: "Vampiric Core", nameEN: "Vampiric Core", icon: "perk_vampiric_core",
                    descTR: "Her 5000 puanda bir +1 Can şansı", descEN: "Every 5000 score: chance to gain +1 Life.",
                    tier: 4, goldCost: 600),
        StartingPerk(id: "chain_pulse", nameTR: "Chain Pulse", nameEN: "Chain Pulse", icon: "perk_chain_pulse",
                    descTR: "Temizlik sonrası zincirleme reaksiyon tetikler", descEN: "Triggers chain reaction after clear.",
                    tier: 4, goldCost: 600),
        StartingPerk(id: "static_charge", nameTR: "Static Charge", nameEN: "Static Charge", icon: "perk_static_charge",
                    descTR: "Static kareler overdrive barını hızla doldurur", descEN: "Static cells rapidly charge overdrive.",
                    tier: 4, goldCost: 600),

        // ---- TIER 5: 800 Gold (En Güçlü) ----
        StartingPerk(id: "heavy_duty", nameTR: "Heavy Duty", nameEN: "Heavy Duty", icon: "perk_heavy_duty",
                    descTR: "Ağır (Heavy) bloklar ek çarpan katkısı sağlar", descEN: "Heavy cells contribute extra multiplier.",
                    tier: 5, goldCost: 800),
        StartingPerk(id: "phantom_siphon", nameTR: "Phantom Siphon", nameEN: "Phantom Siphon", icon: "perk_phantom_siphon",
                    descTR: "Phantom kareler zaman bonusu kazandırır", descEN: "Phantom cells grant time bonus.",
                    tier: 5, goldCost: 800),
        StartingPerk(id: "double_down", nameTR: "Double Down", nameEN: "Double Down", icon: "perk_double_down",
                    descTR: "Son hamlede temizlik yapılırsa ek hamle verir", descEN: "If you clear on your last move: extra moves.",
                    tier: 5, goldCost: 800),
        StartingPerk(id: "tactical_lens", nameTR: "Tactical Lens", nameEN: "Tactical Lens", icon: "perk_tactical_lens",
                    descTR: "Saha üzerindeki en iyi yerleşimi vurgular", descEN: "Highlights the best placement on grid.",
                    tier: 5, goldCost: 800),
    ]
    
    func displayName(lang: AppLanguage) -> String {
        lang == .turkish ? nameTR : nameEN
    }

    func displayDesc(lang: AppLanguage) -> String {
        // Mismatch Fix: Always check PerkUpgradeRegistry first if the perk is upgradeable
        if let upgradeId = PerkUpgradeID(rawValue: id) {
            // Get the description from registry for the user's current meta level
            // In PerkSelectionView, we want to show the current level's effect.
            // If the user hasn't unlocked it yet, show Level 1 values as a preview.
            let slotId = UserEnvironment.shared.activeSlotId ?? 1
            let currentMetaLevel = SaveManager.shared.slots.first(where: { $0.id == slotId })?.perkLevels[id] ?? 1
            let safeLevel = max(1, currentMetaLevel)
            
            return PerkUpgradeRegistry.effectDescription(for: upgradeId, tier: safeLevel)
        }
        return lang == .turkish ? descTR : descEN
    }

    func toPassivePerk(lang: AppLanguage, tier overrideTier: Int? = nil) -> PassivePerk {
        return PassivePerk(
            id: self.id,
            name: displayName(lang: lang),
            icon: self.icon,
            desc: displayDesc(lang: lang),
            tier: overrideTier ?? self.tier,
            synergyPartnerIds: []
        )
    }
}

// MARK: - Synergy System
/// Sinerji mekaniği `synergyName` karşılaştırması üzerinden çalışıyor; dışarıdan
/// büyüsel string kullanımını önlemek için tüm isimler `SynergyID` altında
/// toplandı. Yeni bir sinerji eklendiğinde önce buraya id sabitini ekleyin,
/// ardından `GameViewModel`'deki tüketim noktalarında `SynergyID.x` kullanın.
enum SynergyID {
    static let timeLapse       = "TIME LAPSE"
    static let undyingRage     = "UNDYING RAGE"
    static let masterBuilder   = "MASTER BUILDER"
    static let endlessReserves = "ENDLESS RESERVES"
    static let rainbowDosage   = "RAINBOW DOSAGE"
    static let goldenFever     = "GOLDEN FEVER"
    static let eternalCycle    = "ETERNAL CYCLE"
    static let staticShock     = "STATIC SHOCK"
}

struct PerkSynergy: Codable, Identifiable, Equatable {
    var id: String { requiredPerkIds.joined(separator: "_") }
    let requiredPerkIds: [String]
    let synergyName: String
    let synergyDesc: String
}

// MARK: - Passive Perks (In-Run)
struct PassivePerk: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let desc: String
    var tier: Int
    let synergyPartnerIds: [String]
    
    // Equatable/Hashable support for custom properties if needed
}

// MARK: - Consumable Items
enum ConsumableType: String, Codable, CaseIterable {
    case heal      // Can kazandırır (+1)
    case energy    // Overdrive barını doldurur
    case goldBag   // Anında altın verir
    case cleanup   // Rastgele bir bloğu veya alanı temizler
}

struct ConsumableItem: Codable, Identifiable, Hashable {
    let id: UUID
    let type: ConsumableType
    let name: String
    let icon: String
    let desc: String
    let cost: Int
    
    init(id: UUID = UUID(), type: ConsumableType, name: String, icon: String, desc: String, cost: Int = 50) {
        self.id = id
        self.type = type
        self.name = name
        self.icon = icon
        self.desc = desc
        self.cost = cost
    }
    
    static let shopPool: [ConsumableItem] = [
        ConsumableItem(type: .heal, name: "Yaşam İksiri", icon: "🧪❤️", desc: "Sana +1 Can kazandırır.", cost: 100),
        ConsumableItem(type: .energy, name: "Neon Enerji", icon: "🧪⚡", desc: "Overdrive barını anında doldurur.", cost: 75),
        ConsumableItem(type: .goldBag, name: "Veri Kesesi", icon: "💰", desc: "Anında 150 Altın kazandırır.", cost: 50),
        ConsumableItem(type: .cleanup, name: "Sistem Temizleyici", icon: "🧹", desc: "Sahadaki tüm blokları anında temizler.", cost: 150)
    ]
}

// MARK: - Slot Run History
struct SlotRunEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let score: Int
    let worldLevelReached: Int
    let characterId: String
    let timestamp: TimeInterval

    init(id: UUID = UUID(), score: Int, worldLevelReached: Int, characterId: String, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        self.id = id
        self.score = score
        self.worldLevelReached = worldLevelReached
        self.characterId = characterId
        self.timestamp = timestamp
    }
}

struct LastRunSummary: Codable, Hashable {
    let score: Int
    let worldLevelReached: Int
    let characterId: String
    let goldTotal: Int
    let perksCount: Int
    let wasTrial: Bool
    let timestamp: TimeInterval
}


// MARK: - Save Slot
struct SaveSlot: Codable, Identifiable {
    let id: Int // 1, 2, or 3
    var isEmpty: Bool
    var characterId: String?
    var selectedPerkId: String?
    var lastSaved: Date?
    var currentScore: Int = 0
    var currentRound: Int = 1
    
    // Serialized Game State
    var grid: [[GameCell]]?
    var trayBlocks: [GameBlock]?
    var timeLeft: Double?
    
    // Phase 9: Persistent Map and Run State Data
    var currentChapterMap: ChapterMap?
    var completedNodeIds: [UUID] = []
    var activeBattleNodeId: UUID? = nil
    var activePassivePerks: [PassivePerk] = []
    var inventory: [ConsumableItem] = []
    var gold: Int = 0
    var diamonds: Int?
    var lives: Int = 3
    
    // Scoring V3 Persistence
    var streak: Int = 0
    var overkillCarryover: Int = 0
    var clockworkBonus: Double = 0.0
    
    // Phase 11: Persistent World Map and Slot-Based Upgrades
    var unlockedWorldLevel: Int = 1
    var goldUpgradeLevels: [String: Int] = [:]
    var unlockedMetaUpgradeIDs: [String] = []

    // Boss Contract (tek seferlik risk seçimi — WorldMap boss sheet'ten)
    var activeBossContractId: String? = nil

    // Phase 12: Slot bazlı run history / best
    var bestScore: Int = 0
    var bestWorldLevel: Int = 1
    var recentRuns: [SlotRunEntry] = []
    var lastRunSummary: LastRunSummary? = nil
    
    // Perk Shop: slot bazında perk seviyeleri. (Tier 0 = Kilitli)
    // Yeni kayıtta default seviyelerle başlar.
    var perkLevels: [String: Int] = [
        "golden_stamp": 1,
        "overkill": 1,
        "safe_house": 1
    ]

    var character: GameCharacter? {
        GameCharacter.roster.first(where: { $0.id == characterId })
    }
    
    var perk: StartingPerk? {
        StartingPerk.available.first(where: { $0.id == selectedPerkId })
    }
    
    static func empty(id: Int) -> SaveSlot {
        SaveSlot(id: id, isEmpty: true)
    }
}
