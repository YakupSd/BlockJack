//
//  MapViewModel.swift
//  Block-Jack
//

import Foundation
import Combine
import CoreGraphics

class MapViewModel: ObservableObject {
    @Published var currentMap: ChapterMap
    @Published var selectedNode: MapNode?
    @Published var lastCompletedNodeId: UUID?
    
    let slotId: Int
    
    init(slotId: Int) {
        self.slotId = slotId
        // Load map from save slot
        if let slot = SaveManager.shared.slots.first(where: { $0.id == slotId }),
           let map = slot.currentChapterMap {
            self.currentMap = map
            self.lastCompletedNodeId = slot.completedNodeIds.last
        } else {
            self.currentMap = ChapterMapGenerator.generate(chapterIndex: 1)
            saveMap()
        }
    }
    
    private func saveMap() {
        // SaveManager.updateMapState üzerinden diskte tutan versiyonu kullan
        SaveManager.shared.updateMapState(slotId: slotId, map: currentMap, completedNodes: [])
    }
    
    func selectNode(_ node: MapNode) {
        // Sadece erişilebilir veya tekrar oynanabilir düğümlere izin ver
        if node.isAccessible || node.isReplayable {
            selectedNode = node
        }
    }
    
    func markNodeCompleted(_ nodeId: UUID) {
        guard let index = currentMap.nodes.firstIndex(where: { $0.id == nodeId }) else { return }
        
        let completedLayer = currentMap.nodes[index].layerIndex
        
        // Önce TÜM düğümleri kitle (sıfırla)
        for i in 0..<currentMap.nodes.count {
            currentMap.nodes[i].isAccessible = false
        }
        
        // Mevcut düğümü işaretle
        currentMap.nodes[index].isCompleted = true
        currentMap.nodes[index].isReplayable = false // Tekrar oynama mantığını kapatalım (strict flow)
        
        // Sadece bağlı olan "ileri" düğümleri aç
        let connections = currentMap.nodes[index].connections
        for connectedId in connections {
            if let connectedIndex = currentMap.nodes.firstIndex(where: { $0.id == connectedId }) {
                currentMap.nodes[connectedIndex].isAccessible = true
            }
        }
        
        selectedNode = nil
        lastCompletedNodeId = nodeId
        saveMap()
        
        // --- BOSS COMPLETION CHECK ---
        if currentMap.nodes[index].type == .boss {
            // Wait slightly for visual feedback before jumping
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.generateNextChapterMap()
            }
        }
        
        // SaveManager üzerinden kalıcı olarak kaydedelim
        SaveManager.shared.updateMapState(slotId: slotId, map: currentMap, completedNodes: [nodeId])
    }
    
    /// Oyunu kaydedip ana sayfaya dönmek için tetikleyici
    func saveAndReturnToDashboard() {
        // En güncel durumu bir kez daha kaydedelim (Map objesini senkronize eder)
        SaveManager.shared.updateMapState(slotId: slotId, map: currentMap, completedNodes: [])
        HapticManager.shared.play(.buttonTap)
    }
    
    func canReplay(_ node: MapNode) -> Bool {
        return node.isReplayable && node.type == .normal
    }
    
    func generateNextChapterMap() {
        currentMap = ChapterMapGenerator.generate(chapterIndex: currentMap.chapterIndex + 1)
        selectedNode = nil
        saveMap()
        SaveManager.shared.updateMapState(slotId: slotId, map: currentMap, completedNodes: [])
    }
}
