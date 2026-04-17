//
//  MerchantViewModel.swift
//  Block-Jack
//

import SwiftUI
import Combine

class MerchantViewModel: ObservableObject {
    @Published var shopItems: [ShopItem] = []
    @Published var forgeSelection: [PassivePerk] = []
    
    let slotId: Int
    
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
    
    init(slotId: Int) {
        self.slotId = slotId
        generateStock()
    }
    
    func generateStock() {
        var items: [ShopItem] = []
        
        // 3 adet rastgele perk üret
        let availablePerks = PerkEngine.perkPool.shuffled()
        for i in 0..<3 {
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
    
    func forge() {
        guard canForge() else { return }
        
        // 2 perk'i sil
        for perk in forgeSelection {
            SaveManager.shared.removePassivePerk(slotId: slotId, perkId: perk.id)
        }
        
        // Yeni bir rastgele (belki daha güçlü) perk ver
        // Şimdilik havuzdan rastgele birini veriyoruz (seçilenler hariç)
        let selectionIds = forgeSelection.map { $0.id }
        if let newPerk = PerkEngine.perkPool.filter({ !selectionIds.contains($0.id) }).randomElement() {
            SaveManager.shared.addPassivePerk(slotId: slotId, perk: newPerk)
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
