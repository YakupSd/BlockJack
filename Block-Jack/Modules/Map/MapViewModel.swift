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
        
        // --- FINALE COMPLETION CHECK ---
        // Artık sadece .boss değil, chapter'ın finale node'u ne olursa olsun (boss veya elite)
        // tamamlandığında world level atlanır. Bu sayede boss olmayan seviyelerde de
        // chapter sonunda sabit bir dövüş olur ve biter.
        //
        // NOT: World level, node'a BAŞLAR başlamaz unlock ediliyor (klasik roguelite davranışı).
        // Kullanıcı savaşı kaybederse de aynı chapter'ı tekrar açabilmek için save yapılır.
        // Eskiden burada 1.5 sn sonra `popViewControllers(count: 1)` vardı — bu dövüş
        // sırasında GameView'ı pop ederek savaşı kesiyordu. O yüzden kaldırıldı.
        // Kullanıcı savaşı bitirince BattleRewardView dismiss ile MapView'a döner, oradan
        // manuel olarak WorldMap'e çıkabilir.
        if currentMap.isFinaleNode(currentMap.nodes[index]) {
            UserEnvironment.shared.unlockedWorldLevel += 1

            // Per-character mastery: aktif karakter bu bölümü bitirdi
            UserEnvironment.shared.recordCharacterChapterClear(
                characterId: UserEnvironment.shared.selectedCharacterID,
                chapter: currentMap.chapterIndex
            )

            SaveManager.shared.updateSlotProgression(
                slotId: slotId,
                worldLevel: UserEnvironment.shared.unlockedWorldLevel,
                goldUpgrades: UserEnvironment.shared.goldUpgradeLevels,
                metaUpgrades: UserEnvironment.shared.unlockedUpgradeIDs
            )
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

    /// Chapter bitti mi? (finale node tamamlanmış)
    var isChapterCleared: Bool {
        currentMap.isCleared
    }

    /// ANA MENÜ / DÜNYA HARİTASI butonunun tek giriş noktası.
    /// - Bölüm bitmişse: map'i temizle ve doğrudan WorldMapView'a geç.
    ///   Kullanıcı aynı bitik haritaya dönmesin diye `hasActiveRun`=false
    ///   olacak şekilde slot güncellenir.
    /// - Bölüm bitmediyse: eski davranış — Slot Hub'a dön (run'a devam edilebilir).
    func handleExitPressed() {
        HapticManager.shared.play(.buttonTap)
        if isChapterCleared {
            // Haritayı diskten temizle → SlotHub artık "SEFERE BAŞLA" gösterir.
            SaveManager.shared.clearChapterMap(slotId: slotId)
            MainViewsRouter.shared.popToWorldMap(slotId: slotId)
        } else {
            SaveManager.shared.updateMapState(slotId: slotId, map: currentMap, completedNodes: [])
            MainViewsRouter.shared.popToSlotHub(slotId: slotId)
        }
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
