//
//  PerkEngine.swift
//  Block-Jack
//

import Foundation

class PerkEngine {
    
    // MARK: - Perk Registry
    static let perkPool: [PassivePerk] = [
        PassivePerk(id: "momentum", name: "Momentum", icon: "⚡", desc: "4. seride çift puan verip komboyu sıfırlar", tier: 1, synergyPartnerIds: ["clockwork"]),
        PassivePerk(id: "glass_cannon", name: "Glass Cannon", icon: "🔮", desc: "Can 1 iken tüm puanlar ×1.5 artar", tier: 1, synergyPartnerIds: ["last_stand"]),
        PassivePerk(id: "overkill", name: "Overkill", icon: "💥", desc: "Kalan puanları bir sonraki tura aktarır", tier: 1, synergyPartnerIds: ["echoes"]),
        PassivePerk(id: "last_stand", name: "Last Stand", icon: "🛡️", desc: "Öldüğünde 1 kereliğine ücretsiz canlanma sunar", tier: 1, synergyPartnerIds: ["glass_cannon"]),
        PassivePerk(id: "safe_house", name: "Safe House", icon: "🏕️", desc: "Dinlenme alanlarında otomatik +2 Altın", tier: 1, synergyPartnerIds: []),
        PassivePerk(id: "echoes", name: "Echoes", icon: "🔊", desc: "Tur sonu, en iyi hamlenin puanını tekrar ekler", tier: 1, synergyPartnerIds: ["overkill"]),
        PassivePerk(id: "wide_load", name: "Wide Load", icon: "📦", desc: "Blok haznesine ekstra 4. bir slot açar", tier: 1, synergyPartnerIds: ["sculptor"]),
        PassivePerk(id: "clockwork", name: "Clockwork", icon: "🕰️", desc: "Kazanılan süre ilerledikçe bonus çarpan ekler", tier: 1, synergyPartnerIds: ["momentum"]),
        PassivePerk(id: "sculptor", name: "Sculptor", icon: "🔨", desc: "Turda 2 kez bloğu çevirme hakkı verir", tier: 1, synergyPartnerIds: ["wide_load"]),
        PassivePerk(id: "golden_stamp", name: "Golden Stamp", icon: "🧧", desc: "Hedef skor -%15", tier: 1, synergyPartnerIds: []),
        PassivePerk(id: "blue_pill", name: "Blue Pill", icon: "💊", desc: "Mavi bloklar ×2 Chips verir", tier: 1, synergyPartnerIds: []),
        PassivePerk(id: "lucky_clover", name: "Lucky Clover", icon: "🍀", desc: "Oyun boyu çarpan bonusu verir", tier: 1, synergyPartnerIds: [])
    ]
    
    static let possibleSynergies = [
        PerkSynergy(
            requiredPerkIds: ["momentum", "clockwork"],
            synergyName: "TIME LAPSE",
            synergyDesc: "Momentum tetiklendiğinde Timer'a anında +5sn ekler.",
            effect: .unknown
        ),
        PerkSynergy(
            requiredPerkIds: ["glass_cannon", "last_stand"],
            synergyName: "UNDYING RAGE",
            synergyDesc: "Canın 1'e düştüğünde ölümsüzlük saniyesi kazanırsın.",
            effect: .unknown
        ),
        PerkSynergy(
            requiredPerkIds: ["wide_load", "sculptor"],
            synergyName: "MASTER BUILDER",
            synergyDesc: "4. slota gelen bloklar ücretsiz döndürülebilir.",
            effect: .wideLoadFreeRotate
        ),
        PerkSynergy(
            requiredPerkIds: ["overkill", "echoes"],
            synergyName: "ENDLESS RESERVES",
            synergyDesc: "Overkill artıkları rastgele zaman bonusuna dönüşür.",
            effect: .overkillConvertsToTime
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
    
    static func handleSafeHouse(gold: inout Int) {
        gold += 2
    }
}
