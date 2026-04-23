//
//  SaveManager.swift
//  Block-Jack
//

import Foundation
import Combine

class SaveManager: ObservableObject {
    static let shared = SaveManager()
    
    @Published var slots: [SaveSlot] = []
    
    private let defaultsKey = "BlockJack_SaveSlots"
    
    private init() {
        loadSlots()
    }
    
    // MARK: - Save / Load
    
    func loadSlots() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode([SaveSlot].self, from: data) {
            self.slots = decoded
        } else {
            // Initialize 3 empty slots if none exist
            self.slots = [
                SaveSlot.empty(id: 1),
                SaveSlot.empty(id: 2),
                SaveSlot.empty(id: 3)
            ]
            saveToDisk()
        }
    }
    
    private func saveToDisk() {
        if let encoded = try? JSONEncoder().encode(slots) {
            UserDefaults.standard.set(encoded, forKey: defaultsKey)
        }
    }
    
    // MARK: - Actions
    
    func createNewSave(in slotId: Int, characterId: String, perkId: String) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        
        var newSlot = SaveSlot(id: slotId, isEmpty: false)
        newSlot.characterId = characterId
        newSlot.selectedPerkId = perkId
        newSlot.lastSaved = Date()
        newSlot.currentRound = 1
        newSlot.currentScore = 0
        
        // Phase 9: Initialize run base properties
        // NOT: ChapterMap'i burada yaratmayalım. Aksi halde Hub "aktif run var"
        // sanıp direkt mini map'e düşüyor. World Select/World Map akışı için
        // map sadece oyuncu bir level seçince (WorldMapViewModel.startLevel)
        // üretilmeli.
        newSlot.currentChapterMap = nil
        newSlot.completedNodeIds = []
        newSlot.activePassivePerks = []
        newSlot.gold = 0
        newSlot.lives = 3 // Starting lives
        
        // Phase 11: World Map & Upgrades
        newSlot.unlockedWorldLevel = 1
        newSlot.goldUpgradeLevels = [:]
        newSlot.unlockedMetaUpgradeIDs = []
        newSlot.bestScore = 0
        newSlot.bestWorldLevel = 1
        newSlot.recentRuns = []
        
        slots[index] = newSlot
        saveToDisk()
    }
    
    func deleteSave(slotId: Int) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        slots[index] = SaveSlot.empty(id: slotId)
        saveToDisk()
    }
    
    func updateSave(slotId: Int, score: Int, round: Int) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        slots[index].currentScore = score
        slots[index].currentRound = round
        slots[index].lastSaved = Date()
        saveToDisk()
    }
    
    // Phase 9: Map State saving
    func updateMapState(slotId: Int, map: ChapterMap, completedNodes: [UUID]) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        slots[index].currentChapterMap = map
        for nodeId in completedNodes {
            if !slots[index].completedNodeIds.contains(nodeId) {
                slots[index].completedNodeIds.append(nodeId)
            }
        }
        slots[index].lastSaved = Date()
        saveToDisk()
    }
    
    func addConsumable(slotId: Int, item: ConsumableItem) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        slots[index].inventory.append(item)
        saveToDisk()
    }
    
    func removeConsumable(slotId: Int, itemId: UUID) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        slots[index].inventory.removeAll(where: { $0.id == itemId })
        saveToDisk()
    }
    
    // Phase 9: Advance chapter 
    func advanceToNextChapter(slotId: Int) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }),
              let currentMap = slots[index].currentChapterMap else { return }
        
        let nextChapter = currentMap.chapterIndex + 1
        let newMap = ChapterMapGenerator.generate(chapterIndex: nextChapter)
        
        slots[index].currentChapterMap = newMap
        slots[index].completedNodeIds = [] // Reset completed nodes
        slots[index].lastSaved = Date()
        saveToDisk()
    }

    /// Chapter bitti → haritayı sıfırla. Slot Hub'daki "hasActiveRun" false
    /// olur, kullanıcı "SEFERE BAŞLA" ile WorldMap'e düşer ve sonraki
    /// bölümünü seçebilir. Eskiden map `isCleared=true` ile diskte kalıyor,
    /// "SEFERE DEVAM" da aynı bitik haritaya dönüş loop'u yaratıyordu.
    func clearChapterMap(slotId: Int) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        slots[index].currentChapterMap = nil
        slots[index].completedNodeIds = []
        slots[index].lastSaved = Date()
        saveToDisk()
    }
    
    // Phase 10: Run State direct modifiers
    func updateGold(slotId: Int, amount: Int) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        slots[index].gold = max(0, slots[index].gold + amount)
        slots[index].lastSaved = Date()
        saveToDisk()
        // Tek altın havuzu: aktif slot değiştiyse kullanıcının cüzdanını da eşitle.
        // Dashboard / Shop / Upgrades UserEnvironment.gold okur, Rest/Treasure/Mystery
        // slot.gold yazar. Bu sync olmazsa iki havuz birbirinden koparydı (meşhur
        // "altın görünmüyor" bug'ı).
        if UserEnvironment.shared.activeSlotId == slotId {
            UserEnvironment.shared.gold = slots[index].gold
        }
    }
    
    /// Slot'un mevcut altın değerini mutlak olarak yazar. Run sonunda oyun içi
    /// biriken altını diske kalıcı hale getirmek için kullanılır.
    func setGold(slotId: Int, total: Int) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        slots[index].gold = max(0, total)
        slots[index].lastSaved = Date()
        saveToDisk()
        if UserEnvironment.shared.activeSlotId == slotId {
            UserEnvironment.shared.gold = slots[index].gold
        }
    }
    
    func updateLives(slotId: Int, amount: Int) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        slots[index].lives = max(0, min(5, slots[index].lives + amount))
        slots[index].lastSaved = Date()
        saveToDisk()
    }
    
    func addPassivePerk(slotId: Int, perk: PassivePerk) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        
        // Koleksiyon keşfi: Perk ilk kez görüldüğünde katalogda açılır.
        // `discoverPerk` içi set kontrolü yaptığından güvenle her eklemede çağrılabilir.
        UserEnvironment.shared.discoverPerk(perk.id)

        if let existingIndex = slots[index].activePassivePerks.firstIndex(where: { $0.id == perk.id }) {
            // Level up existing perk
            slots[index].activePassivePerks[existingIndex].tier += 1
            slots[index].lastSaved = Date()
            saveToDisk()
        } else {
            // Add new perk
            slots[index].activePassivePerks.append(perk)
            slots[index].lastSaved = Date()
            saveToDisk()
        }
    }
    
    func upgradePassivePerk(slotId: Int, perkId: String) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        UserEnvironment.shared.discoverPerk(perkId)
        if let perkIndex = slots[index].activePassivePerks.firstIndex(where: { $0.id == perkId }) {
            slots[index].activePassivePerks[perkIndex].tier += 1
            slots[index].lastSaved = Date()
            saveToDisk()
        }
    }
    
    func removePassivePerk(slotId: Int, perkId: String) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        slots[index].activePassivePerks.removeAll { $0.id == perkId }
        slots[index].lastSaved = Date()
        saveToDisk()
    }
    
    /// Slot Hub'dan karakter değiştirme. Yeni karakter id'sini yazar ve
    /// aktif slot ise UserEnvironment.selectedCharacterID'yi de günceller
    /// (avatar/stat okuyan ekranlar anında yenilenir).
    func setCharacter(slotId: Int, characterID: String) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        slots[index].characterId = characterID
        slots[index].lastSaved = Date()
        saveToDisk()
        if UserEnvironment.shared.activeSlotId == slotId {
            UserEnvironment.shared.selectedCharacterID = characterID
        }
    }

    /// Slot bağlamında seçili starting perk id'sini günceller.
    func setStartingPerk(slotId: Int, perkId: String) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        slots[index].selectedPerkId = perkId
        slots[index].lastSaved = Date()
        saveToDisk()
    }

    // MARK: - Slot Progression (Phase 11)
    func updateSlotProgression(slotId: Int, worldLevel: Int, goldUpgrades: [String: Int], metaUpgrades: [String]) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        slots[index].unlockedWorldLevel = worldLevel
        slots[index].goldUpgradeLevels = goldUpgrades
        slots[index].unlockedMetaUpgradeIDs = metaUpgrades
        slots[index].lastSaved = Date()
        saveToDisk()
    }

    // MARK: - Slot Run History
    func recordSlotRun(slotId: Int, score: Int, worldLevelReached: Int, characterId: String, perksCount: Int, wasTrial: Bool) {
        guard score > 0, let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        let entry = SlotRunEntry(score: score, worldLevelReached: max(1, worldLevelReached), characterId: characterId)
        slots[index].recentRuns.insert(entry, at: 0)
        if slots[index].recentRuns.count > 3 {
            slots[index].recentRuns = Array(slots[index].recentRuns.prefix(3))
        }
        slots[index].bestScore = max(slots[index].bestScore, score)
        slots[index].bestWorldLevel = max(slots[index].bestWorldLevel, max(1, worldLevelReached))
        slots[index].lastRunSummary = LastRunSummary(
            score: score,
            worldLevelReached: max(1, worldLevelReached),
            characterId: characterId,
            goldTotal: slots[index].gold,
            perksCount: max(0, perksCount),
            wasTrial: wasTrial,
            timestamp: Date().timeIntervalSince1970
        )
        slots[index].lastSaved = Date()
        saveToDisk()
    }

    func setBossContract(slotId: Int, contractId: String?) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        slots[index].activeBossContractId = contractId
        slots[index].lastSaved = Date()
        saveToDisk()
    }
}
