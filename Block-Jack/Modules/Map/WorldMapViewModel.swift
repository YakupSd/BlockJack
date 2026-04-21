//
//  WorldMapViewModel.swift
//  Block-Jack
//

import SwiftUI
import Combine

class WorldMapViewModel: ObservableObject {
    @Published var levels: [WorldLevel] = []
    @Published var selectedLevel: WorldLevel?
    
    let slotId: Int
    private let userEnv: UserEnvironment
    
    init(slotId: Int, userEnv: UserEnvironment) {
        self.slotId = slotId
        self.userEnv = userEnv
        generateLevels()
    }
    
    func generateLevels() {
        var newLevels: [WorldLevel] = []
        let unlockedMax = userEnv.unlockedWorldLevel
        
        for i in 1...20 {
            let type: WorldLevelType = (i == 3 || i % 5 == 0) ? .boss : .normal
            let status: WorldLevelStatus = i < unlockedMax ? .completed : (i == unlockedMax ? .available : .locked)
            
            newLevels.append(WorldLevel(
                id: i,
                title: type == .boss ? "BOSS SECTOR \(i)" : "SECTOR \(i)",
                type: type,
                status: status
            ))
        }
        self.levels = newLevels
    }
    
    func selectLevel(_ level: WorldLevel) {
        guard level.status != .locked else { return }
        selectedLevel = level
        HapticManager.shared.play(.selection)
    }
    
    func startLevel(_ level: WorldLevel) {
        // Tıklanan seviyeye göre yeni bir ChapterMap oluşturup oyunu başlatır
        let map = ChapterMapGenerator.generate(chapterIndex: level.id)
        
        // SaveManager üzerinden bu slotun haritasını güncelle
        SaveManager.shared.updateMapState(slotId: slotId, map: map, completedNodes: [])
        
        // Router üzerinden MapView'a geçiş yap
        MainViewsRouter.shared.pushToMap(slotId: slotId)
    }
}

// MARK: - Models
enum WorldLevelType: String, Codable {
    case normal
    case boss
}

enum WorldLevelStatus: String, Codable {
    case locked
    case available
    case completed
}

struct WorldLevel: Identifiable, Codable {
    let id: Int
    let title: String
    let type: WorldLevelType
    let status: WorldLevelStatus
}
