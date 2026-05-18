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
    let worldId: Int
    private let userEnv: UserEnvironment

    // Pixel map yerleşimi — harita logical boyutları. Gerçek render'da bu boyut
    // ekrana göre ölçeklenir; node pozisyonları normalized (0-1) tutulur.
    let mapAspectRatio: CGFloat = 0.55   // width / height — uzun dikey harita
    let nodePositions: [Int: CGPoint]    // level.id -> normalized (x, y) 0...1
    let connections: [WorldPathSegment]

    init(slotId: Int, worldId: Int = 1, userEnv: UserEnvironment) {
        self.slotId = slotId
        self.worldId = max(1, min(5, worldId))
        self.userEnv = userEnv

        // Pozisyonlar ve yol segmentleri bir kere hesaplanır (deterministik).
        let built = Self.buildLayout(worldId: self.worldId)
        self.nodePositions = built.positions
        self.connections = built.segments

        generateLevels()
    }

    // MARK: - Level Üretimi
    func generateLevels() {
        var newLevels: [WorldLevel] = []
        let unlockedMax = userEnv.unlockedWorldLevel

        let start = (worldId - 1) * 20 + 1
        let end = worldId * 20

        for i in start...end {
            let type: WorldLevelType = ChapterProgression.isBossLevel(i) ? .boss : .normal
            let status: WorldLevelStatus = i < unlockedMax ? .completed : (i == unlockedMax ? .available : .locked)

            newLevels.append(WorldLevel(
                id: i,
                title: type == .boss ? "BOSS SECTOR \(i)" : "SECTOR \(i)",
                type: type,
                status: status
            ))
        }
        // Sort by level ID to ensure consistent ordering
        self.levels = newLevels.sorted { $0.id < $1.id }
        print("📊 Generated \(self.levels.count) levels for world \(worldId), unlockedMax=\(unlockedMax)")
        for level in self.levels.prefix(5) {
            print("  Level \(level.id): \(level.status)")
        }
    }

    // MARK: - Etkileşim
    func selectLevel(_ level: WorldLevel) {
        guard level.status != .locked else {
            HapticManager.shared.play(.error)
            return
        }
        HapticManager.shared.play(.selection)
        selectedLevel = level
    }

    func dismissSelection() {
        selectedLevel = nil
    }

    func startLevel(_ level: WorldLevel) {
        let cid = SaveManager.shared.slots.first(where: { $0.id == slotId })?.characterId
            ?? userEnv.selectedCharacterID
        userEnv.consumeTrialRunIfNeeded(selectedCharacterId: cid)

        // Aynı chapter için tamamlanmamış kayıtlı map varsa yeniden kullan —
        // progress sıfırlanmaz.
        if let existing = SaveManager.shared.slots.first(where: { $0.id == slotId })?.currentChapterMap,
           existing.chapterIndex == level.id,
           !existing.isCleared {
            MainViewsRouter.shared.pushToMap(slotId: slotId)
            return
        }

        let map = ChapterMapGenerator.generate(chapterIndex: level.id)
        SaveManager.shared.updateMapState(slotId: slotId, map: map, completedNodes: [])
        MainViewsRouter.shared.pushToMap(slotId: slotId)
    }

    // Oyuncu sprite'ının haritada bulunduğu seviye — direkt unlockedWorldLevel'den hesapla
    var playerLevelId: Int {
        let start = (worldId - 1) * 20 + 1
        let end = worldId * 20
        let unlockedMax = userEnv.unlockedWorldLevel
        
        // Eğer oyuncu bu dünyada ise
        if unlockedMax >= start && unlockedMax <= end {
            return unlockedMax
        }
        
        // Eğer dünyayı geçtiyse, son level'i göster
        if unlockedMax > end {
            return end
        }
        
        // Dünyaya henüz erişemedi (shouldn't happen)
        return start
    }

    var totalChapters: Int { 20 }
    var completedCount: Int { levels.filter { $0.status == .completed }.count }
    var chapterProgress: Double {
        guard totalChapters > 0 else { return 0 }
        return Double(completedCount) / Double(totalChapters)
    }

    /// View katmanının tema kararı için kullanacağı aktif dünya teması.
    /// Şu an VM 1-20 üretiyor; unlockedWorldLevel 20'yi geçtiğinde Concrete
    /// Ruins'e kayacak. İleride VM çok-dünyalı hale gelirse bu da güncellenir.
    var currentTheme: WorldTheme {
        let start = (worldId - 1) * 20 + 1
        return ChapterProgression.theme(for: max(1, start))
    }

    // MARK: - Layout (zigzag yılan yolu, 20 sektör)
    private static func buildLayout(worldId: Int) -> (positions: [Int: CGPoint], segments: [WorldPathSegment]) {
        // 20 seviyeyi aşağıdan (y=0.95) yukarıya (y=0.05) yılan gibi sıralarız.
        // X kolonları 4 sütunlu snake: [0.22, 0.5, 0.78, 0.5] periyodu — doğal yol hissi.
        let xPattern: [CGFloat] = [0.22, 0.50, 0.78, 0.50]
        let count = 20
        let start = (max(1, min(5, worldId)) - 1) * 20 + 1
        let top: CGFloat = 0.05
        let bottom: CGFloat = 0.95
        let step = (bottom - top) / CGFloat(count - 1)

        var positions: [Int: CGPoint] = [:]
        for local in 1...count {
            let x = xPattern[(local - 1) % xPattern.count]
            // Seviye 1 haritanın altında, seviye 20 tepede
            let y = bottom - CGFloat(local - 1) * step
            let levelId = start + (local - 1)
            positions[levelId] = CGPoint(x: x, y: y)
        }

        var segments: [WorldPathSegment] = []
        for local in 1..<count {
            let from = start + (local - 1)
            let to = from + 1
            segments.append(WorldPathSegment(fromLevelId: from, toLevelId: to))
        }
        return (positions, segments)
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

struct WorldLevel: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let type: WorldLevelType
    let status: WorldLevelStatus
}

struct WorldPathSegment: Hashable {
    let fromLevelId: Int
    let toLevelId: Int
}
