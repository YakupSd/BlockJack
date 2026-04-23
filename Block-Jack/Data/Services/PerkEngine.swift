//
//  PerkEngine.swift
//  Block-Jack
//

import Foundation

class PerkEngine {
    
    // MARK: - Perk Registry
    struct PerkDefinition: Identifiable {
        let id: String
        let nameTR: String
        let nameEN: String
        let icon: String
        let descTR: String
        let descEN: String
        let synergyPartnerIds: [String]

        func name(lang: AppLanguage) -> String { lang == .turkish ? nameTR : nameEN }
        func desc(lang: AppLanguage) -> String { lang == .turkish ? descTR : descEN }

        func toPassivePerk(lang: AppLanguage, tier: Int = 1) -> PassivePerk {
            PassivePerk(
                id: id,
                name: name(lang: lang),
                icon: icon,
                desc: desc(lang: lang),
                tier: tier,
                synergyPartnerIds: synergyPartnerIds
            )
        }
    }

    /// Tek kaynak: Perk metinleri TR/EN burada tutulur.
    static let perkCatalog: [PerkDefinition] = [
        PerkDefinition(id: "momentum", nameTR: "Momentum", nameEN: "Momentum", icon: "⚡",
                       descTR: "4. seride çift puan verip komboyu sıfırlar", descEN: "On the 4th streak: double score and reset combo.",
                       synergyPartnerIds: ["clockwork"]),
        PerkDefinition(id: "glass_cannon", nameTR: "Glass Cannon", nameEN: "Glass Cannon", icon: "🔮",
                       descTR: "Can 1 iken tüm puanlar ×1.5 artar", descEN: "When at 1 life: all scores ×1.5.",
                       synergyPartnerIds: ["last_stand"]),
        PerkDefinition(id: "overkill", nameTR: "Overkill", nameEN: "Overkill", icon: "💥",
                       descTR: "Kalan puanları bir sonraki tura aktarır", descEN: "Carry leftover score into the next round.",
                       synergyPartnerIds: ["echoes"]),
        PerkDefinition(id: "last_stand", nameTR: "Last Stand", nameEN: "Last Stand", icon: "🛡️",
                       descTR: "Öldüğünde 1 kereliğine ücretsiz canlanma sunar", descEN: "Revive once for free when you die.",
                       synergyPartnerIds: ["glass_cannon"]),
        PerkDefinition(id: "safe_house", nameTR: "Safe House", nameEN: "Safe House", icon: "🏕️",
                       descTR: "Dinlenme alanına her girdiğinde otomatik +100 Altın", descEN: "Each rest site grants +100 Gold automatically.",
                       synergyPartnerIds: []),
        PerkDefinition(id: "echoes", nameTR: "Echoes", nameEN: "Echoes", icon: "🔊",
                       descTR: "Tur sonu, en iyi hamlenin puanını tekrar ekler", descEN: "End of round: repeat your best move score.",
                       synergyPartnerIds: ["overkill"]),
        PerkDefinition(id: "wide_load", nameTR: "Wide Load", nameEN: "Wide Load", icon: "📦",
                       descTR: "Blok haznesine ekstra 4. bir slot açar", descEN: "Unlock an extra 4th tray slot.",
                       synergyPartnerIds: ["sculptor"]),
        PerkDefinition(id: "clockwork", nameTR: "Clockwork", nameEN: "Clockwork", icon: "🕰️",
                       descTR: "Kazanılan süre ilerledikçe bonus çarpan ekler", descEN: "Time gained gradually adds a bonus multiplier.",
                       synergyPartnerIds: ["momentum"]),
        PerkDefinition(id: "sculptor", nameTR: "Sculptor", nameEN: "Sculptor", icon: "🔨",
                       descTR: "Turda 2 kez bloğu çevirme hakkı verir", descEN: "Rotate blocks up to 2 times per round.",
                       synergyPartnerIds: ["wide_load"]),
        PerkDefinition(id: "golden_stamp", nameTR: "Golden Stamp", nameEN: "Golden Stamp", icon: "🧧",
                       descTR: "Hedef skor -%15", descEN: "Target score -15%.",
                       synergyPartnerIds: []),
        PerkDefinition(id: "blue_pill", nameTR: "Blue Pill", nameEN: "Blue Pill", icon: "💊",
                       descTR: "Mavi bloklar ×2 Chips verir", descEN: "Blue blocks grant ×2 Chips.",
                       synergyPartnerIds: ["lead_pill"]),
        PerkDefinition(id: "lucky_clover", nameTR: "Lucky Clover", nameEN: "Lucky Clover", icon: "🍀",
                       descTR: "Her temizlikte +0.5x çarpan (her tier +0.5x)", descEN: "+0.5x multiplier per clear (per tier).",
                       synergyPartnerIds: []),

        PerkDefinition(id: "lead_pill", nameTR: "Lead Pill", nameEN: "Lead Pill", icon: "🟢",
                       descTR: "Yeşil bloklar ×2 Chips verir", descEN: "Green blocks grant ×2 Chips.",
                       synergyPartnerIds: ["blue_pill"]),
        PerkDefinition(id: "midas_touch", nameTR: "Midas Touch", nameEN: "Midas Touch", icon: "💰",
                       descTR: "Her Flush +5 Altın verir", descEN: "Each Flush grants +5 Gold.",
                       synergyPartnerIds: ["golden_stamp"]),
        PerkDefinition(id: "vampiric_core", nameTR: "Vampiric Core", nameEN: "Vampiric Core", icon: "🧛",
                       descTR: "5000 puanda bir can şansı", descEN: "Every 5000 score: chance to gain +1 Life.",
                       synergyPartnerIds: []),
        PerkDefinition(id: "recycler", nameTR: "Recycler", nameEN: "Recycler", icon: "♻️",
                       descTR: "2+ satırda %20 tray yenileme", descEN: "On 2+ line clear: 20% chance to refresh tray.",
                       synergyPartnerIds: ["wide_load"]),
        PerkDefinition(id: "chain_pulse", nameTR: "Chain Pulse", nameEN: "Chain Pulse", icon: "📡",
                       descTR: "Temizlik sonrası %15 şansla komşu dolu hücreyi zincir temizler", descEN: "After a clear: 15% chance to chain-clear an adjacent filled cell.",
                       synergyPartnerIds: ["static_charge"]),
        PerkDefinition(id: "heavy_duty", nameTR: "Heavy Duty", nameEN: "Heavy Duty", icon: "🏗️",
                       descTR: "Temizlenen her Heavy hücre +1.0x çarpan getirir (tier başına)", descEN: "Each Heavy cell cleared grants +1.0x multiplier (per tier).",
                       synergyPartnerIds: []),
        PerkDefinition(id: "phantom_siphon", nameTR: "Phantom Siphon", nameEN: "Phantom Siphon", icon: "👻",
                       descTR: "Phantom modifier'lı round'da her yerleştirme +2s (tier başına)", descEN: "In Phantom rounds: each placement grants +2s (per tier).",
                       synergyPartnerIds: []),
        PerkDefinition(id: "double_down", nameTR: "Double Down", nameEN: "Double Down", icon: "✖️",
                       descTR: "Son hamlede temizlik +3 hamle", descEN: "If you clear on your last move: +3 moves.",
                       synergyPartnerIds: []),
        PerkDefinition(id: "static_charge", nameTR: "Static Charge", nameEN: "Static Charge", icon: "🔌",
                       descTR: "Round başında static hücreler yerleşir; üzerine blok koyunca overdrive +50%", descEN: "Static cells appear at round start; placing over them grants +50% overdrive.",
                       synergyPartnerIds: ["chain_pulse"]),
        PerkDefinition(id: "tactical_lens", nameTR: "Tactical Lens", nameEN: "Tactical Lens", icon: "🔍",
                       descTR: "Blok çekilirken en iyi yerleşim yeşil ışıkla işaretlenir", descEN: "While dragging: highlights the best placement in green.",
                       synergyPartnerIds: [])
    ]

    /// Geriye dönük uyumluluk: Perk havuzunu (TR) PassivePerk listesi olarak sun.
    static let perkPool: [PassivePerk] = perkCatalog.map { $0.toPassivePerk(lang: .turkish, tier: 1) }

    static func definition(for id: String) -> PerkDefinition? {
        perkCatalog.first(where: { $0.id == id })
    }

    static func perk(for id: String, lang: AppLanguage, tier: Int = 1) -> PassivePerk? {
        definition(for: id)?.toPassivePerk(lang: lang, tier: tier)
    }
    
    static let possibleSynergies = [
        PerkSynergy(
            requiredPerkIds: ["momentum", "clockwork"],
            synergyName: SynergyID.timeLapse,
            synergyDesc: "Momentum tetiklendiğinde Timer'a anında +5sn ekler."
        ),
        PerkSynergy(
            requiredPerkIds: ["glass_cannon", "last_stand"],
            synergyName: SynergyID.undyingRage,
            synergyDesc: "Canın 1'e düştüğünde ölümsüzlük saniyesi kazanırsın."
        ),
        PerkSynergy(
            requiredPerkIds: ["wide_load", "sculptor"],
            synergyName: SynergyID.masterBuilder,
            synergyDesc: "4. slota gelen bloklar ücretsiz döndürülebilir."
        ),
        PerkSynergy(
            requiredPerkIds: ["overkill", "echoes"],
            synergyName: SynergyID.endlessReserves,
            synergyDesc: "Overkill artıkları rastgele zaman bonusuna dönüşür."
        ),
        PerkSynergy(
            requiredPerkIds: ["blue_pill", "lead_pill"],
            synergyName: SynergyID.rainbowDosage,
            synergyDesc: "Mavi ve Yeşil içeren temizliklerde ×3 toplam skor."
        ),
        PerkSynergy(
            requiredPerkIds: ["midas_touch", "golden_stamp"],
            synergyName: SynergyID.goldenFever,
            synergyDesc: "Her Flush +15 Altın, ancak hedef skor ×1.2 artar."
        ),
        PerkSynergy(
            requiredPerkIds: ["recycler", "wide_load"],
            synergyName: SynergyID.eternalCycle,
            synergyDesc: "Recycler tetiklendiğinde tüm 4 slot da yenilenir."
        ),
        PerkSynergy(
            requiredPerkIds: ["static_charge", "chain_pulse"],
            synergyName: SynergyID.staticShock,
            synergyDesc: "Static bir kare temizlendiğinde o satırdaki tüm hücreleri patlatır."
        )
    ]
    
    // MARK: - Synergy Evaluation
    static func evaluateSynergies(perks: [PassivePerk]) -> [PerkSynergy] {
        var activeSynergies: [PerkSynergy] = []
        let activeIds = Set(perks.map { $0.id })
        
        for synergy in possibleSynergies {
            let reqs = Set(synergy.requiredPerkIds)
            if reqs.isSubset(of: activeIds) {
                activeSynergies.append(synergy)
            }
        }
        
        return activeSynergies
    }
    
    // MARK: - Perk Triggers
    
    // Most perks are handled dynamically in GameViewModel when clear/score/next round happens.
    // PerkEngine acts as the central logic container.
    
    static func triggerOverkill(currentScore: Int, targetScore: Int) -> Int {
        if currentScore > targetScore {
            // Overkill: %30 carryover
            return Int(Double(currentScore - targetScore) * 0.3)
        }
        return 0
    }
    
    static func triggerClockwork(secondsGained: Double, currentBonus: Double) -> Double {
        // Her kazanılan sn x 0.1, max 2.0
        let newBonus = currentBonus + (secondsGained * 0.1)
        return min(2.0, newBonus)
    }
    
    /// Safe House perki için dinlenme alanında uygulanacak bonus altın miktarı.
    /// RestSiteView doğrudan SaveManager.updateGold(+100) çağırıyor; bu fonksiyon
    /// geriye dönük uyumluluk için kaldı (eskiden 2 altındı, açıklamayla çelişiyordu).
    static let safeHouseGoldBonus: Int = 100
}
