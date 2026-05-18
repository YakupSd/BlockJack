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
        let synergyPartnerIds: [String]

        func name(lang: AppLanguage) -> String { lang == .turkish ? nameTR : nameEN }
        
        func desc(lang: AppLanguage, tier: Int = 1) -> String {
            if let upgradeId = PerkUpgradeID(rawValue: id) {
                let desc = PerkUpgradeRegistry.effectDescription(for: upgradeId, tier: tier)
                // Localization check: Registry might be EN only, but for core perks we can append TR if needed
                // For now, registry descriptions are clear enough.
                return desc
            }
            return "???"
        }

        func toPassivePerk(lang: AppLanguage, tier: Int = 1) -> PassivePerk {
            PassivePerk(
                id: id,
                name: name(lang: lang),
                icon: icon,
                desc: desc(lang: lang, tier: tier),
                tier: tier,
                synergyPartnerIds: synergyPartnerIds
            )
        }
    }

    static let perkCatalog: [PerkDefinition] = [
        PerkDefinition(id: "overkill", nameTR: "Overkill", nameEN: "Overkill", icon: "perk_overkill", synergyPartnerIds: ["echoes"]),
        PerkDefinition(id: "last_stand", nameTR: "Last Stand", nameEN: "Last Stand", icon: "perk_last_stand", synergyPartnerIds: ["glass_cannon"]),
        PerkDefinition(id: "safe_house", nameTR: "Safe House", nameEN: "Safe House", icon: "perk_safe_house", synergyPartnerIds: []),
        PerkDefinition(id: "echoes", nameTR: "Echoes", nameEN: "Echoes", icon: "perk_echoes", synergyPartnerIds: ["overkill"]),
        PerkDefinition(id: "wide_load", nameTR: "Wide Load", nameEN: "Wide Load", icon: "perk_wide_load", synergyPartnerIds: ["sculptor"]),
        PerkDefinition(id: "clockwork", nameTR: "Clockwork", nameEN: "Clockwork", icon: "perk_clockwork", synergyPartnerIds: ["momentum"]),
        PerkDefinition(id: "sculptor", nameTR: "Sculptor", nameEN: "Sculptor", icon: "perk_sculptor", synergyPartnerIds: ["wide_load"]),
        PerkDefinition(id: "golden_stamp", nameTR: "Golden Stamp", nameEN: "Golden Stamp", icon: "perk_golden_stamp", synergyPartnerIds: []),
        PerkDefinition(id: "blue_pill", nameTR: "Blue Pill", nameEN: "Blue Pill", icon: "perk_blue_pill", synergyPartnerIds: ["lead_pill"]),
        PerkDefinition(id: "lucky_clover", nameTR: "Lucky Clover", nameEN: "Lucky Clover", icon: "perk_lucky_clover", synergyPartnerIds: []),
        PerkDefinition(id: "lead_pill", nameTR: "Lead Pill", nameEN: "Lead Pill", icon: "perk_lead_pill", synergyPartnerIds: ["blue_pill"]),
        PerkDefinition(id: "midas_touch", nameTR: "Midas Touch", nameEN: "Midas Touch", icon: "perk_midas_touch", synergyPartnerIds: ["golden_stamp"]),
        PerkDefinition(id: "vampiric_core", nameTR: "Vampiric Core", nameEN: "Vampiric Core", icon: "perk_vampiric_core", synergyPartnerIds: []),
        PerkDefinition(id: "recycler", nameTR: "Recycler", nameEN: "Recycler", icon: "perk_recycler", synergyPartnerIds: ["wide_load"]),
        PerkDefinition(id: "chain_pulse", nameTR: "Chain Pulse", nameEN: "Chain Pulse", icon: "perk_chain_pulse", synergyPartnerIds: ["static_charge"]),
        PerkDefinition(id: "heavy_duty", nameTR: "Heavy Duty", nameEN: "Heavy Duty", icon: "perk_heavy_duty", synergyPartnerIds: []),
        PerkDefinition(id: "phantom_siphon", nameTR: "Phantom Siphon", nameEN: "Phantom Siphon", icon: "perk_phantom_siphon", synergyPartnerIds: []),
        PerkDefinition(id: "double_down", nameTR: "Double Down", nameEN: "Double Down", icon: "perk_double_down", synergyPartnerIds: []),
        PerkDefinition(id: "static_charge", nameTR: "Static Charge", nameEN: "Static Charge", icon: "perk_static_charge", synergyPartnerIds: ["chain_pulse"]),
        PerkDefinition(id: "tactical_lens", nameTR: "Tactical Lens", nameEN: "Tactical Lens", icon: "perk_tactical_lens", synergyPartnerIds: []),
        PerkDefinition(id: "momentum", nameTR: "Momentum", nameEN: "Momentum", icon: "perk_momentum", synergyPartnerIds: ["clockwork"]),
        PerkDefinition(id: "glass_cannon", nameTR: "Glass Cannon", nameEN: "Glass Cannon", icon: "perk_glass_cannon", synergyPartnerIds: ["last_stand"])
    ]

    /// Geriye dönük uyumluluk ve dinamik havuz: Dile ve meta seviyelere göre perk listesi sunar.
    static func getPerkPool(lang: AppLanguage, perkLevels: [String: Int] = [:]) -> [PassivePerk] {
        perkCatalog.map { def in
            let tier = perkLevels[def.id] ?? 1
            return def.toPassivePerk(lang: lang, tier: tier)
        }
    }

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
    
    // (Eski trigger'lar ScoreManager'da dinamik tier hesabı ile yapıldığı için kaldırıldı)
    
}
