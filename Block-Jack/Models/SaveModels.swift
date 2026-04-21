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
        GameCharacter(id: "block_e", name: "BLOCK-E", icon: "port_block_e", passiveDesc: "Her 10 saniyede bir sahadaki bir bloğu siler (max 3/maç)", activeDesc: "Kombo çarpan artışı 5 saniye boyunca ×5 olur", isPremium: false, cost: 0,
                      loreTR: "İlk üretilen temizlik asistanı. Yıllarca fabrikada çalıştıktan sonra yapay zekası limitleri aştı.",
                      loreEN: "The first generation cleaning assistant. Its AI broke bounds after years in the factory.",
                      favoriteBlockType: .I, strongMode: "Satır Temizliği", difficulty: .beginner, unlockCondition: .free),
        
        GameCharacter(id: "architect", name: "THE ARCHITECT", icon: "port_architect", passiveDesc: "Kare (O) bloklara +%20 puan verir", activeDesc: "3×3 alanı anında temizler", isPremium: true, cost: 500,
                      loreTR: "Gridin yaratıcısı. Sistemin her bir köşesini kendi elleriyle kodladı.",
                      loreEN: "Creator of the Grid. Coded every edge of the system manually.",
                      favoriteBlockType: .O, strongMode: "Büyük Kombinasyonlar", difficulty: .advanced, unlockCondition: .gold(500)),
        
        GameCharacter(id: "timebender", name: "TIME BENDER", icon: "port_timebender", passiveDesc: "Kombo süresi %50 yavaş düşer", activeDesc: "Zamanı ve çarpanı 3 hamle boyunca dondurur", isPremium: true, cost: 800,
                      loreTR: "Zaman algısını bükmeyi başardı. O oynarken saniyeler uzar, dakikalar kaybolur.",
                      loreEN: "Mastered twisting the perception of time. Seconds stretch as he plays.",
                      favoriteBlockType: .T, strongMode: "Zaman Yönetimi", difficulty: .advanced, unlockCondition: .gold(800)),
        
        GameCharacter(id: "gambler", name: "THE GAMBLER", icon: "port_gambler", passiveDesc: "%7 ihtimalle o hamlenin puanı ×10 olur", activeDesc: "Mevcut ve sahadaki 3 bloğu rastgele yeniler", isPremium: true, cost: 1200,
                      loreTR: "Sisteme her girişinde hayatını ortaya koyuyor. Şansı yaver giderse yıkılamaz.",
                      loreEN: "Puts his life on the line on every login. Invincible if lucky.",
                      favoriteBlockType: .lMirror, strongMode: "Yüksek Risk, Yüksek Ödül", difficulty: .expert, unlockCondition: .gold(1200)),
        
        GameCharacter(id: "neonwraith", name: "NEON WRAITH", icon: "port_neonwraith", passiveDesc: "Süre <%10 ise tüm puanlar ×3 olur", activeDesc: "Dolu karenin üzerine blok koyup alttakileri siler", isPremium: true, cost: 3000,
                      loreTR: "Sokakların hayaleti. Kimse yüzünü görmedi. Sadece hızıyla ve ardında bıraktığı yıkımla bilinir.",
                      loreEN: "Ghost of the streets. Known only for its speed and destruction left behind.",
                      favoriteBlockType: .Z, strongMode: "Panik Kontrolü", difficulty: .expert, unlockCondition: .goldAndLevel(amount: 3000, level: 5)),
        
        // Bu karakterler hem Altın hem de belirli bir Seviye gerektirecek şekilde güncellendi
        GameCharacter(id: "ghost", name: "GHOST", icon: "port_ghost", passiveDesc: "Stealth oyuncusu, gizli hamleler sağlar", activeDesc: "Phantom yerleştirme, görünmez blok", isPremium: true, cost: 2000,
                      overdriveThresholds: [0.33, 0.66, 1.0],
                      loreTR: "Sistemin arka kapısı. O varken bloklar sessizce kaybolur.",
                      loreEN: "Backdoor of the system. Blocks vanish quietly when it's around.",
                      favoriteBlockType: .single, strongMode: "Gizlilik ve Sabır", difficulty: .expert, unlockCondition: .goldAndLevel(amount: 2000, level: 10)),
        
        GameCharacter(id: "alchemist", name: "ALCHEMIST", icon: "port_alchemist", passiveDesc: "Dönüşüm temalı yetenekler", activeDesc: "Blok rengini değiştirir", isPremium: true, cost: 2500,
                      overdriveThresholds: [0.4, 0.7, 1.0],
                      loreTR: "Veri tiplerini altına çevirir. Kuralları esnetir ve yeniden yazar.",
                      loreEN: "Turns data types into gold. Bends and rewrites the rules.",
                      favoriteBlockType: .L, strongMode: "Dönüşüm Zincirleri", difficulty: .advanced, unlockCondition: .goldAndLevel(amount: 2500, level: 15)),
        
        GameCharacter(id: "titan", name: "TITAN", icon: "port_titan", passiveDesc: "Dev bloklar ile ağır ve yıkıcı hamleler", activeDesc: "Büyük 4x4 blok yerleştirme", isPremium: true, cost: 4000,
                      overdriveThresholds: [0.5, 0.8, 1.2],
                      loreTR: "Son teknoloji savaş makinesi modifikasyonu. O düştüğünde grid titrer.",
                      loreEN: "High-tech war machine mod. The grid shakes when it drops.",
                      favoriteBlockType: .I, strongMode: "Dev Şekiller", difficulty: .beginner, unlockCondition: .goldAndLevel(amount: 4000, level: 20))
    ]
}

// MARK: - Selected Perk / Starting Item
struct StartingPerk: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let desc: String
    
    static let available: [StartingPerk] = [
        StartingPerk(id: "none", name: "Hiçbiri", icon: "🚫", desc: "Temel başlangıç, güçlendirme yok."),
        StartingPerk(id: "blue_pill", name: "Blue Pill", icon: "item_blue_pill", desc: "Mavi bloklar ×2 Chips verir"),
        StartingPerk(id: "golden_stamp", name: "Golden Stamp", icon: "item_golden_stamp", desc: "Hedef skor -%15"),
        StartingPerk(id: "lucky_clover", name: "Lucky Clover", icon: "🍀", desc: "Streak maxı +10 artırır"),
        
        // Yeni Perkler
        StartingPerk(id: "momentum", name: "Momentum", icon: "⚡", desc: "4. seride çift puan verip komboyu sıfırlar"),
        StartingPerk(id: "glass_cannon", name: "Glass Cannon", icon: "🔮", desc: "Can 1 iken tüm puanlar ×1.5 artar"),
        StartingPerk(id: "overkill", name: "Overkill", icon: "💥", desc: "Kalan puanları bir sonraki tura aktarır"),
        StartingPerk(id: "last_stand", name: "Last Stand", icon: "🛡️", desc: "Öldüğünde 1 kereliğine ücretsiz canlanma sunar"),
        StartingPerk(id: "safe_house", name: "Safe House", icon: "🏕️", desc: "Dinlenme alanlarında otomatik +2 Altın"),
        StartingPerk(id: "echoes", name: "Echoes", icon: "🔊", desc: "Tur sonu, en iyi hamlenin puanını tekrar ekler"),
        StartingPerk(id: "wide_load", name: "Wide Load", icon: "📦", desc: "Blok haznesine ekstra 4. bir slot açar"),
        StartingPerk(id: "clockwork", name: "Clockwork", icon: "🕰️", desc: "Kazanılan süre ilerledikçe bonus çarpan ekler"),
        StartingPerk(id: "sculptor", name: "Sculptor", icon: "🔨", desc: "Turda 2 kez bloğu çevirme hakkı verir"),
        
        // --- NEW PHASE B PERKS ---
        StartingPerk(id: "lead_pill", name: "Lead Pill", icon: "item_green_pill", desc: "Yeşil bloklar ×2 Chips verir"),
        StartingPerk(id: "midas_touch", name: "Midas Touch", icon: "💰✨", desc: "Her Flush (Renkli Temizlik) +5 Altın verir"),
        StartingPerk(id: "vampiric_core", name: "Vampiric Core", icon: "🧛", desc: "Her 5000 puanda bir +1 Can şansı verir"),
        StartingPerk(id: "recycler", name: "Recycler", icon: "♻️", desc: "2+ satır silindiğinde %20 hazne yenileme şansı"),
        StartingPerk(id: "chain_pulse", name: "Chain Pulse", icon: "📡", desc: "Temizlik sonrası komşu kareleri kontrol eder"),
        StartingPerk(id: "heavy_duty", name: "Heavy Duty", icon: "🏗️", desc: "Ağır (Heavy) bloklar ×3 çarpan katkısı sağlar"),
        StartingPerk(id: "phantom_siphon", name: "Phantom Siphon", icon: "👻🧪", desc: "Phantom kare yanına yerleşim +2s kazandırır"),
        StartingPerk(id: "double_down", name: "Double Down", icon: "✖️2", desc: "Son hamlede temizlik yapılırsa +3 hamle verir"),
        StartingPerk(id: "static_charge", name: "Static Charge", icon: "🔌", desc: "Static kareler overdrive barını hızla doldurur"),
        StartingPerk(id: "tactical_lens", name: "Tactical Lens", icon: "🔍", desc: "En iyi yerleşimi 10sn aralıkla vurgular")
    ]
    
    func toPassivePerk() -> PassivePerk {
        return PassivePerk(
            id: self.id,
            name: self.name,
            icon: self.icon,
            desc: self.desc,
            tier: 1,
            synergyPartnerIds: []
        )
    }
}

// MARK: - Synergy System
enum SynergyEffect: Codable {
    case tensionThresholdReduce(Int)
    case overkillConvertsToTime
    case wideLoadFreeRotate
    case colorComboMult(Double)
    case goldOnFlush(Int)
    case trayRefillChance(Double)
    case unknown
}

struct PerkSynergy: Codable, Identifiable {
    var id: String { requiredPerkIds.joined(separator: "_") }
    let requiredPerkIds: [String]
    let synergyName: String
    let synergyDesc: String
    let effect: SynergyEffect
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
