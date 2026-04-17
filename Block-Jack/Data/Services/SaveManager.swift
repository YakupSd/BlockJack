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
        
        // Phase 9: Initialize map and base properties
        newSlot.currentChapterMap = ChapterMapGenerator.generate(chapterIndex: 1)
        newSlot.completedNodeIds = []
        newSlot.activePassivePerks = []
        newSlot.gold = 0
        newSlot.lives = 3 // Starting lives
        
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
    
    // Phase 10: Run State direct modifiers
    func updateGold(slotId: Int, amount: Int) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        slots[index].gold += amount
        slots[index].lastSaved = Date()
        saveToDisk()
    }
    
    func updateLives(slotId: Int, amount: Int) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        slots[index].lives = max(0, min(5, slots[index].lives + amount))
        slots[index].lastSaved = Date()
        saveToDisk()
    }
    
    func addPassivePerk(slotId: Int, perk: PassivePerk) {
        guard let index = slots.firstIndex(where: { $0.id == slotId }) else { return }
        
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
}
