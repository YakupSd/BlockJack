//
//  MerchantViewModel.swift
//  Block-Jack
//

import SwiftUI
import Combine

class MerchantViewModel: ObservableObject {
    @Published var shopItems: [ShopItem] = []
    @Published var forgeSelection: [PassivePerk] = []
    @Published var forgedPerkResult: PassivePerk? = nil
    
    let slotId: Int
    let lang: AppLanguage
    
    struct ShopItem: Identifiable {
        let id = UUID()
        let perk: PassivePerk?
        let consumableType: ConsumableType?
        let cost: Int
        var isSold: Bool = false
        
        enum ConsumableType {
            case lifeRestoration
            case maxScoreBoost // Temporary next-round boost
        }
    }
    
    init(slotId: Int, lang: AppLanguage = .turkish) {
        self.slotId = slotId
        self.lang = lang
        generateStock()
    }
    
    func generateStock() {
        var items: [ShopItem] = []
        
        let perkLevels = currentSlot?.perkLevels ?? [:]
        let unlockedIds = Set(perkLevels.filter { $0.value >= 1 }.map { $0.key })
        let activeIds = currentSlot?.activePassivePerks.map { $0.id } ?? []
        
        // Sadece açık olan ve henüz alınmamış perkleri filtrele
        let availablePerks = PerkEngine.getPerkPool(lang: lang, perkLevels: currentSlot?.perkLevels ?? [:]).filter { perk in
            unlockedIds.contains(perk.id) && !activeIds.contains(perk.id)
        }.shuffled()
        
        // En fazla 3 perk üret
        let maxPerks = min(3, availablePerks.count)
        for i in 0..<maxPerks {
            let perk = availablePerks[i]
            let cost = Int.random(in: 120...200)
            items.append(ShopItem(perk: perk, consumableType: nil, cost: cost))
        }
        
        // 1 adet can yenileme
        items.append(ShopItem(perk: nil, consumableType: .lifeRestoration, cost: 100))
        
        self.shopItems = items
    }
    
    var currentSlot: SaveSlot? {
        SaveManager.shared.slots.first(where: { $0.id == slotId })
    }
    
    func buyItem(_ item: ShopItem) -> Bool {
        guard let slot = currentSlot, slot.gold >= item.cost, !item.isSold else { return false }
        
        if let perk = item.perk {
            SaveManager.shared.addPassivePerk(slotId: slotId, perk: perk)
        } else if let consumable = item.consumableType {
            if consumable == .lifeRestoration {
                SaveManager.shared.updateLives(slotId: slotId, amount: 1)
            }
        }
        
        SaveManager.shared.updateGold(slotId: slotId, amount: -item.cost)
        
        if let index = shopItems.firstIndex(where: { $0.id == item.id }) {
            shopItems[index].isSold = true
        }
        
        return true
    }
    
    // MARK: - Perk Forge Logic
    
    func toggleForgeSelection(_ perk: PassivePerk) {
        if let index = forgeSelection.firstIndex(where: { $0.id == perk.id }) {
            forgeSelection.remove(at: index)
        } else if forgeSelection.count < 2 {
            forgeSelection.append(perk)
        }
    }
    
    func canForge() -> Bool {
        return forgeSelection.count == 2
    }
    
    func willTriggerFallback() -> Bool {
        guard canForge() else { return false }
        
        let perkLevels = currentSlot?.perkLevels ?? [:]
        let unlockedIds = Set(perkLevels.filter { $0.value >= 1 }.map { $0.key })
        let activeIds = currentSlot?.activePassivePerks.map { $0.id } ?? []
        let selectionIds = forgeSelection.map { $0.id }
        
        let forgePool = PerkEngine.getPerkPool(lang: lang, perkLevels: perkLevels).filter { perk in
            unlockedIds.contains(perk.id) && !activeIds.contains(perk.id) && !selectionIds.contains(perk.id)
        }
        
        return forgePool.isEmpty
    }
    
    func forge() {
        guard canForge() else { return }
        
        // 2 perk'i sil
        let deletedPerks = forgeSelection
        for perk in deletedPerks {
            SaveManager.shared.removePassivePerk(slotId: slotId, perkId: perk.id)
        }
        
        // Yeni bir rastgele perk ver
        // Sadece açık olan ve seçilenler HARİCİ aktif olmayan perkler
        let perkLevels = currentSlot?.perkLevels ?? [:]
        let unlockedIds = Set(perkLevels.filter { $0.value >= 1 }.map { $0.key })
        let activeIds = currentSlot?.activePassivePerks.map { $0.id } ?? []
        let selectionIds = deletedPerks.map { $0.id }
        
        var forgePool = PerkEngine.getPerkPool(lang: lang, perkLevels: perkLevels).filter { perk in
            unlockedIds.contains(perk.id) && !activeIds.contains(perk.id) && !selectionIds.contains(perk.id)
        }
        
        // Fallback: Eğer seçilmemiş diğer açık pasif perk kalmadıysa, feda edilen 2 perkten birini rastgele geri ver
        if forgePool.isEmpty {
            forgePool = PerkEngine.getPerkPool(lang: lang, perkLevels: perkLevels).filter { perk in
                unlockedIds.contains(perk.id) && !activeIds.contains(perk.id)
            }
        }
        
        if let newPerk = forgePool.randomElement() {
            SaveManager.shared.addPassivePerk(slotId: slotId, perk: newPerk)
            forgedPerkResult = newPerk
        }
        
        forgeSelection = []
    }
    
    // MARK: - Synergies
    
    func hasPotentialSynergy(_ perk: PassivePerk) -> Bool {
        guard let slot = currentSlot else { return false }
        let currentPerkIds = slot.activePassivePerks.map { $0.id }
        
        for partnerId in perk.synergyPartnerIds {
            if currentPerkIds.contains(partnerId) {
                return true
            }
        }
        return false
    }
}
