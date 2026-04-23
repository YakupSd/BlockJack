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
}


// MARK: - Character Model
struct GameCharacter: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let passiveDesc: String
    let activeDesc: String
    let isPremium: Bool
    let cost: Int
    var overdriveThresholds: [Double] = [0.33, 0.66, 1.0] // Default
    
    // Phase 7: Lore & İstatistikler
    let loreTR: String
    let loreEN: String
    let favoriteBlockType: BlockType
    let strongMode: String
    let difficulty: CharacterDifficulty
    let unlockCondition: UnlockCondition
    
    static let roster: [GameCharacter] = [
        GameCharacter(id: "block_e", name: "BLOCK-E", icon: "port_block_e",
                      passiveDesc: "Her 10sn sahadaki bir hücreyi temizler (max 3/tur)",
                      activeDesc: "Hedefli temizlik: T1 satır, T2 çapraz, T3 3×3 bomba",
                      isPremium: false, cost: 0,
                      loreTR: "İlk üretilen temizlik asistanı. Yıllarca fabrikada çalıştıktan sonra yapay zekası limitleri aştı.",
                      loreEN: "The first generation cleaning assistant. Its AI broke bounds after years in the factory.",
                      favoriteBlockType: .I, strongMode: "Satır Temizliği", difficulty: .beginner, unlockCondition: .free),

        GameCharacter(id: "architect", name: "THE ARCHITECT", icon: "port_architect",
                      passiveDesc: "Kare (O) bloklarla temizlikte +%30 çarpan",
                      activeDesc: "Alan yıkımı: T1 3×3, T2 5×5, T3 7×7 +1500 puan",
                      isPremium: true, cost: 500,
                      loreTR: "Gridin yaratıcısı. Sistemin her bir köşesini kendi elleriyle kodladı.",
                      loreEN: "Creator of the Grid. Coded every edge of the system manually.",
                      favoriteBlockType: .O, strongMode: "Büyük Kombinasyonlar", difficulty: .advanced, unlockCondition: .gold(500)),

        GameCharacter(id: "timebender", name: "TIME BENDER", icon: "port_timebender",
                      passiveDesc: "Temizlikte +%50 süre, streak yavaş düşer",
                      activeDesc: "Zaman kontrolü: T1 5sn dur, T2 8sn+tepsi, T3 3 hamle freeze",
                      isPremium: true, cost: 800,
                      loreTR: "Zaman algısını bükmeyi başardı. O oynarken saniyeler uzar, dakikalar kaybolur.",
                      loreEN: "Mastered twisting the perception of time. Seconds stretch as he plays.",
                      favoriteBlockType: .T, strongMode: "Zaman Yönetimi", difficulty: .advanced, unlockCondition: .gold(800)),

        GameCharacter(id: "gambler", name: "THE GAMBLER", icon: "port_gambler",
                      passiveDesc: "%7 şansla o hamlede +9 çarpan (≈×10 combo)",
                      activeDesc: "Şans tepsi: T1 1 blok, T2 tüm tepsi, T3 tepsi +2000 puan",
                      isPremium: true, cost: 1200,
                      loreTR: "Sisteme her girişinde hayatını ortaya koyuyor. Şansı yaver giderse yıkılamaz.",
                      loreEN: "Puts his life on the line on every login. Invincible if lucky.",
                      favoriteBlockType: .J, strongMode: "Yüksek Risk, Yüksek Ödül", difficulty: .expert, unlockCondition: .gold(1200)),

        GameCharacter(id: "neonwraith", name: "NEON WRAITH", icon: "port_neonwraith",
                      passiveDesc: "Süre <%20 iken +2.5 çarpan (Wraith Fury)",
                      activeDesc: "T1 +15sn, T2 +25sn & satır temizle, T3 sonraki 3 clear +2×",
                      isPremium: true, cost: 3000,
                      loreTR: "Sokakların hayaleti. Kimse yüzünü görmedi. Sadece hızıyla ve ardında bıraktığı yıkımla bilinir.",
                      loreEN: "Ghost of the streets. Known only for its speed and destruction left behind.",
                      favoriteBlockType: .Z, strongMode: "Panik Kontrolü", difficulty: .expert, unlockCondition: .goldAndLevel(amount: 3000, level: 5)),

        GameCharacter(id: "ghost", name: "GHOST", icon: "port_ghost",
                      passiveDesc: "Her 10sn +3sn whisper zaman bonusu",
                      activeDesc: "Phantom overwrite: T1 yer, T2 +%50 clear, T3 +%100 +10sn",
                      isPremium: true, cost: 2000,
                      overdriveThresholds: [0.33, 0.66, 1.0],
                      loreTR: "Sistemin arka kapısı. O varken bloklar sessizce kaybolur.",
                      loreEN: "Backdoor of the system. Blocks vanish quietly when it's around.",
                      favoriteBlockType: .single, strongMode: "Gizlilik ve Sabır", difficulty: .expert, unlockCondition: .goldAndLevel(amount: 2000, level: 10)),

        GameCharacter(id: "alchemist", name: "ALCHEMIST", icon: "port_alchemist",
                      passiveDesc: "Tek-renk temizlikte +1.0 çarpan (Resonance)",
                      activeDesc: "T1 tepsi yenile, T2 tek-renk tepsi, T3 3 hamle ×2 puan",
                      isPremium: true, cost: 2500,
                      overdriveThresholds: [0.4, 0.7, 1.0],
                      loreTR: "Veri tiplerini altına çevirir. Kuralları esnetir ve yeniden yazar.",
                      loreEN: "Turns data types into gold. Bends and rewrites the rules.",
                      favoriteBlockType: .L, strongMode: "Dönüşüm Zincirleri", difficulty: .advanced, unlockCondition: .goldAndLevel(amount: 2500, level: 15)),

        GameCharacter(id: "titan", name: "TITAN", icon: "port_titan",
                      passiveDesc: "Heavy hücre temizlikte +0.5× (her heavy başına)",
                      activeDesc: "T1 dev blok, T2 2× dev +500 overkill, T3 Earthquake +2500",
                      isPremium: true, cost: 4000,
                      overdriveThresholds: [0.5, 0.8, 1.2],
                      loreTR: "Son teknoloji savaş makinesi modifikasyonu. O düştüğünde grid titrer.",
                      loreEN: "High-tech war machine mod. The grid shakes when it drops.",
                      favoriteBlockType: .I, strongMode: "Dev Şekiller", difficulty: .beginner, unlockCondition: .goldAndLevel(amount: 4000, level: 20))
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
    
    static let available: [StartingPerk] = [
        StartingPerk(id: "none", nameTR: "Hiçbiri", nameEN: "None", icon: "🚫",
                    descTR: "Temel başlangıç, güçlendirme yok.", descEN: "Basic start. No bonus."),
        StartingPerk(id: "blue_pill", nameTR: "Blue Pill", nameEN: "Blue Pill", icon: "item_blue_pill",
                    descTR: "Mavi bloklar ×2 Chips verir", descEN: "Blue blocks grant ×2 Chips."),
        StartingPerk(id: "golden_stamp", nameTR: "Golden Stamp", nameEN: "Golden Stamp", icon: "item_golden_stamp",
                    descTR: "Hedef skor -%15", descEN: "Target score -15%."),
        StartingPerk(id: "lucky_clover", nameTR: "Lucky Clover", nameEN: "Lucky Clover", icon: "🍀",
                    descTR: "Streak maxı +10 artırır", descEN: "Streak cap +10."),
        
        // Yeni Perkler
        StartingPerk(id: "momentum", nameTR: "Momentum", nameEN: "Momentum", icon: "⚡",
                    descTR: "4. seride çift puan verip komboyu sıfırlar", descEN: "On 4th streak: double score and reset combo."),
        StartingPerk(id: "glass_cannon", nameTR: "Glass Cannon", nameEN: "Glass Cannon", icon: "🔮",
                    descTR: "Can 1 iken tüm puanlar ×1.5 artar", descEN: "When at 1 life: all scores ×1.5."),
        StartingPerk(id: "overkill", nameTR: "Overkill", nameEN: "Overkill", icon: "💥",
                    descTR: "Kalan puanları bir sonraki tura aktarır", descEN: "Carry leftover score into the next round."),
        StartingPerk(id: "last_stand", nameTR: "Last Stand", nameEN: "Last Stand", icon: "🛡️",
                    descTR: "Öldüğünde 1 kereliğine ücretsiz canlanma sunar", descEN: "Revive once for free when you die."),
        StartingPerk(id: "safe_house", nameTR: "Safe House", nameEN: "Safe House", icon: "🏕️",
                    descTR: "Dinlenme alanlarında otomatik +2 Altın", descEN: "Rest sites grant +2 Gold automatically."),
        StartingPerk(id: "echoes", nameTR: "Echoes", nameEN: "Echoes", icon: "🔊",
                    descTR: "Tur sonu, en iyi hamlenin puanını tekrar ekler", descEN: "End of round: repeat your best move score."),
        StartingPerk(id: "wide_load", nameTR: "Wide Load", nameEN: "Wide Load", icon: "📦",
                    descTR: "Blok haznesine ekstra 4. bir slot açar", descEN: "Unlock an extra 4th tray slot."),
        StartingPerk(id: "clockwork", nameTR: "Clockwork", nameEN: "Clockwork", icon: "🕰️",
                    descTR: "Kazanılan süre ilerledikçe bonus çarpan ekler", descEN: "Time gained gradually adds a bonus multiplier."),
        StartingPerk(id: "sculptor", nameTR: "Sculptor", nameEN: "Sculptor", icon: "🔨",
                    descTR: "Turda 2 kez bloğu çevirme hakkı verir", descEN: "Rotate blocks up to 2 times per round."),
        
        // --- NEW PHASE B PERKS ---
        StartingPerk(id: "lead_pill", nameTR: "Lead Pill", nameEN: "Lead Pill", icon: "item_green_pill",
                    descTR: "Yeşil bloklar ×2 Chips verir", descEN: "Green blocks grant ×2 Chips."),
        StartingPerk(id: "midas_touch", nameTR: "Midas Touch", nameEN: "Midas Touch", icon: "💰✨",
                    descTR: "Her Flush (Renkli Temizlik) +5 Altın verir", descEN: "Each Flush grants +5 Gold."),
        StartingPerk(id: "vampiric_core", nameTR: "Vampiric Core", nameEN: "Vampiric Core", icon: "🧛",
                    descTR: "Her 5000 puanda bir +1 Can şansı verir", descEN: "Every 5000 score: chance to gain +1 Life."),
        StartingPerk(id: "recycler", nameTR: "Recycler", nameEN: "Recycler", icon: "♻️",
                    descTR: "2+ satır silindiğinde %20 hazne yenileme şansı", descEN: "On 2+ line clear: 20% chance to refresh tray."),
        StartingPerk(id: "chain_pulse", nameTR: "Chain Pulse", nameEN: "Chain Pulse", icon: "📡",
                    descTR: "Temizlik sonrası komşu kareleri kontrol eder", descEN: "After a clear: checks adjacent squares."),
        StartingPerk(id: "heavy_duty", nameTR: "Heavy Duty", nameEN: "Heavy Duty", icon: "🏗️",
                    descTR: "Ağır (Heavy) bloklar ×3 çarpan katkısı sağlar", descEN: "Heavy cells contribute ×3 to multiplier."),
        StartingPerk(id: "phantom_siphon", nameTR: "Phantom Siphon", nameEN: "Phantom Siphon", icon: "👻🧪",
                    descTR: "Phantom kare yanına yerleşim +2s kazandırır", descEN: "Placing next to Phantom cell grants +2s."),
        StartingPerk(id: "double_down", nameTR: "Double Down", nameEN: "Double Down", icon: "✖️2",
                    descTR: "Son hamlede temizlik yapılırsa +3 hamle verir", descEN: "If you clear on your last move: +3 moves."),
        StartingPerk(id: "static_charge", nameTR: "Static Charge", nameEN: "Static Charge", icon: "🔌",
                    descTR: "Static kareler overdrive barını hızla doldurur", descEN: "Static cells rapidly charge overdrive."),
        StartingPerk(id: "tactical_lens", nameTR: "Tactical Lens", nameEN: "Tactical Lens", icon: "🔍",
                    descTR: "En iyi yerleşimi 10sn aralıkla vurgular", descEN: "Highlights best placement every 10s.")
    ]
    
    func displayName(lang: AppLanguage) -> String {
        lang == .turkish ? nameTR : nameEN
    }

    func displayDesc(lang: AppLanguage) -> String {
        lang == .turkish ? descTR : descEN
    }

    func toPassivePerk(lang: AppLanguage) -> PassivePerk {
        return PassivePerk(
            id: self.id,
            name: displayName(lang: lang),
            icon: self.icon,
            desc: displayDesc(lang: lang),
            tier: 1,
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
    var activePassivePerks: [PassivePerk] = []
    var inventory: [ConsumableItem] = []
    var gold: Int = 0
    var lives: Int = 3
    
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
