//
//  MapModels.swift
//  Block-Jack
//

import Foundation
import CoreGraphics

// MARK: - Node Type
enum NodeType: String, Codable, CaseIterable {
    case normal
    case elite
    case merchant
    case treasure
    case rest
    case mystery
    case boss
}

// MARK: - World Theme (Expansion Phase 1)
/// 100 seviyelik genişlemede her 20 level'lık bloğun görsel kimliği.
/// Dünya 1 şu an aktif (neon cyberpunk), diğerleri roadmap'te.
enum WorldTheme: String, Codable, CaseIterable {
    case neonGrid        // Dünya 1 (1-20): Neon Cyberpunk — AKTİF
    case concreteRuins   // Dünya 2 (21-40): Beton Harabeler — rezerv piksel assetleri
    case candyLab        // Dünya 3 (41-60): Şeker Laboratuvarı
    case deepAbyss       // Dünya 4 (61-80): Derin Uçurum
    case coreSingularity // Dünya 5 (81-100): Çekirdek Tekilliği
    
    var displayName: String {
        switch self {
        case .neonGrid:        return "Neon Grid"
        case .concreteRuins:   return "Concrete Ruins"
        case .candyLab:        return "Candy Lab"
        case .deepAbyss:       return "Deep Abyss"
        case .coreSingularity: return "Core Singularity"
        }
    }
    
    /// Kod tabanında henüz üretime alınmış mı? Sadece neonGrid.
    var isImplemented: Bool { self == .neonGrid }
}

// MARK: - Chapter Progression
/// Kampanya ilerlemesinin merkezi kurallarını tutar.
/// - Hangi dünya seviyelerinin boss olduğu
/// - Finale encounter türünün nasıl seçildiği
/// - 100 level'a doğru genişleme için WorldTheme eşleşmesi
enum ChapterProgression {
    /// Boss encounter'ları bu dünya seviyelerinde olur.
    /// Boss olmayan seviyelerde de chapter sonunda bir dövüş (elite) olur.
    /// 1-20 arası aktif; sonraki dünyalar roadmap'te (bossLevelsByWorld'de).
    static let bossWorldLevels: Set<Int> = [1, 3, 5, 7, 9, 11, 15, 17, 20]
    
    /// Her dünya için boss seviyeleri. Genişleme için veri katmanı — UI henüz
    /// Dünya 1'i render ediyor ama shipping'den önce balance tuning burada yapılır.
    static let bossLevelsByWorld: [Int: Set<Int>] = [
        1: [1, 3, 5, 7, 9, 11, 15, 17, 20],
        2: [23, 25, 27, 29, 31, 35, 37, 40],
        3: [43, 45, 47, 49, 51, 55, 57, 60],
        4: [63, 65, 67, 69, 71, 75, 77, 80],
        5: [83, 85, 87, 89, 91, 95, 97, 100]
    ]
    
    /// Verilen world level'in hangi dünyaya ait olduğunu döner. 1-20 → Dünya 1, 21-40 → Dünya 2, …
    static func world(for level: Int) -> Int {
        max(1, min(5, ((level - 1) / 20) + 1))
    }
    
    /// Bu level'in görsel teması.
    static func theme(for level: Int) -> WorldTheme {
        switch world(for: level) {
        case 1: return .neonGrid
        case 2: return .concreteRuins
        case 3: return .candyLab
        case 4: return .deepAbyss
        default: return .coreSingularity
        }
    }
    
    static func isBossLevel(_ level: Int) -> Bool {
        if let set = bossLevelsByWorld[world(for: level)] {
            return set.contains(level)
        }
        return bossWorldLevels.contains(level)
    }
    
    /// Mini map'in son encounter'ının tipini döndürür.
    /// - Boss seviyesi: `.boss` (dialogue + boss müziği + modifier)
    /// - Diğer seviyeler: `.elite` (daha zor normal dövüş, dialogue yok)
    static func finaleNodeType(for level: Int) -> NodeType {
        return isBossLevel(level) ? .boss : .elite
    }
}

// MARK: - Map Node
struct MapNode: Identifiable, Codable {
    let id: UUID
    let type: NodeType
    let position: CGPoint // Normalized position between 0 and 1
    var connections: [UUID]
    var isCompleted: Bool
    var isAccessible: Bool
    var isReplayable: Bool
    var layerIndex: Int // Katman indexi (strict pathing için)
    
    init(id: UUID = UUID(), type: NodeType, position: CGPoint, connections: [UUID] = [], isCompleted: Bool = false, isAccessible: Bool = false, isReplayable: Bool = false, layerIndex: Int = 0) {
        self.id = id
        self.type = type
        self.position = position
        self.connections = connections
        self.isCompleted = isCompleted
        self.isAccessible = isAccessible
        self.isReplayable = isReplayable
        self.layerIndex = layerIndex
    }
}

// MARK: - Chapter Map
struct ChapterMap: Codable, Identifiable {
    let id: UUID
    let chapterIndex: Int
    var nodes: [MapNode]
    let startNodeId: UUID
    /// Son encounter node ID'si. Eski kodla uyumluluk için adı `bossNodeId` olarak
    /// kaldı ama artık boss olmayan chapter'larda elite finale'yi de işaret eder.
    let bossNodeId: UUID
    
    /// Son encounter node ID'si için semantik alias. Yeni kod bunu kullanmalı.
    var finaleNodeId: UUID { bossNodeId }
    
    /// Verilen node, bu chapter'ın finale encounter'ı mı?
    func isFinaleNode(_ node: MapNode) -> Bool {
        return node.id == bossNodeId
    }
    
    /// Bu chapter'ın finale encounter'ı bir boss mu?
    var hasBossFinale: Bool {
        return ChapterProgression.isBossLevel(chapterIndex)
    }

    /// Chapter bitti mi? (Finale node'u tamamlanmış mı?)
    /// Bitmişse Slot Hub "SEFERE DEVAM" yerine "SEFERE BAŞLA" göstermeli ve
    /// kullanıcıyı World Map'e yönlendirmeli — aksi halde kullanıcı aynı
    /// bitik bölümün haritasına geri düşüp loop'a giriyordu.
    var isCleared: Bool {
        return nodes.first(where: { $0.id == bossNodeId })?.isCompleted == true
    }
    
    mutating func updateNode(_ node: MapNode) {
        if let index = nodes.firstIndex(where: { $0.id == node.id }) {
            nodes[index] = node
        }
    }
}

// MARK: - Chapter Map Generator
class ChapterMapGenerator {
    /// Chapter map üretimi — Slay-the-Spire tarzı lane-based branching.
    ///
    /// Önceki generator "full mesh" bağlantı ve çoğu layer'da tek node üretiyordu,
    /// bu da ekranda düz vertical bir çizgi yaratıyordu (özellikle boss
    /// chapter'larında). Yeni versiyon:
    ///   • Her layer 1-3 paralel "lane" üretir (boss'larda max 2, normal
    ///     chapter'larda max 3).
    ///   • Bağlantılar "en yakın lane" mantığıyla kurulur, full mesh yok;
    ///     böylece gerçek bir "savaş mı/kaçış mı?" seçimi ortaya çıkar.
    ///   • Layer 1 ve son mid-layer funnel yapar (finale'e yaklaşırken daralır).
    ///   • %30 ihtimalle ekstra çapraz (cross) bağlantı eklenir — bu sayede
    ///     haritada zigzag gibi alternatif rotalar belirir.
    static func generate(chapterIndex: Int) -> ChapterMap {
        let isBossChapter = ChapterProgression.isBossLevel(chapterIndex)
        let finaleType = ChapterProgression.finaleNodeType(for: chapterIndex)

        // Katman sayısı: boss chapter'ları daha kısa; normaller daha uzun.
        let numLayers = isBossChapter ? Int.random(in: 4...5) : Int.random(in: 5...7)
        // Paralel lane üst sınırı
        let maxLanes = isBossChapter ? 2 : 3

        var nodes: [MapNode] = []

        // --- Başlangıç node (ortada, erişilebilir) ---
        let startNode = MapNode(
            type: .normal,
            position: CGPoint(x: 0.5, y: 0.92),
            isAccessible: true,
            layerIndex: 0
        )
        nodes.append(startNode)
        var previousLayer: [MapNode] = [startNode]

        // Layout parametreleri
        let topY: CGFloat = 0.18
        let bottomY: CGFloat = 0.92
        let usableY = bottomY - topY

        // --- Mid layer'ları üret ---
        for layer in 1...numLayers {
            let layerProgress = CGFloat(layer) / CGFloat(numLayers + 1)
            let baseY = bottomY - usableY * layerProgress

            // Lane sayısı: ilk ve son mid-layer funnel gibi davranır,
            // orta kısım daha dallanır.
            let lanes: Int
            if layer == numLayers {
                // Finale'den önceki layer: 1-2 node (boss'a doğru daral)
                lanes = min(2, maxLanes)
            } else if layer == 1 {
                // İlk dallanma: 2 lane (fight/flee ilk seçimi)
                lanes = min(2, maxLanes)
            } else {
                // Orta layer'lar: tam aralık
                lanes = Int.random(in: 2...maxLanes)
            }

            var currentLayer: [MapNode] = []
            for laneIdx in 0..<lanes {
                let xPos: CGFloat
                if lanes == 1 {
                    xPos = 0.5
                } else {
                    let margin: CGFloat = 0.22
                    let width: CGFloat = 1.0 - 2 * margin
                    xPos = margin + width * CGFloat(laneIdx) / CGFloat(lanes - 1)
                }
                // Doğal his için hafif jitter
                let jitterX = CGFloat.random(in: -0.025...0.025)
                let jitterY = CGFloat.random(in: -0.02...0.02)

                let type = pickNodeType(
                    layer: layer,
                    numLayers: numLayers,
                    laneIdx: laneIdx,
                    lanes: lanes,
                    isBossChapter: isBossChapter
                )

                let node = MapNode(
                    type: type,
                    position: CGPoint(x: xPos + jitterX, y: baseY + jitterY),
                    layerIndex: layer
                )
                currentLayer.append(node)
                nodes.append(node)
            }

            // --- Kenar (edge) kurulumu: "en yakın lane" + funneling ---
            // 1) Her curr node, prev'deki EN YAKIN prev'den en az bir edge alır.
            for curr in currentLayer {
                if let closestPrev = previousLayer.min(by: { lhs, rhs in
                    abs(lhs.position.x - curr.position.x) < abs(rhs.position.x - curr.position.x)
                }),
                   let idx = nodes.firstIndex(where: { $0.id == closestPrev.id }),
                   !nodes[idx].connections.contains(curr.id) {
                    nodes[idx].connections.append(curr.id)
                }
            }
            // 2) Outgoing edge'i olmayan her prev node, en yakın curr'a bağlanır.
            for prev in previousLayer {
                if let idx = nodes.firstIndex(where: { $0.id == prev.id }),
                   nodes[idx].connections.filter({ cid in currentLayer.contains(where: { $0.id == cid }) }).isEmpty {
                    if let closestCurr = currentLayer.min(by: { lhs, rhs in
                        abs(lhs.position.x - prev.position.x) < abs(rhs.position.x - prev.position.x)
                    }) {
                        nodes[idx].connections.append(closestCurr.id)
                    }
                }
            }
            // 3) %30 ihtimalle ekstra cross-edge — kullanıcıya ekstra seçenek sun.
            for prev in previousLayer {
                guard Double.random(in: 0...1) < 0.3 else { continue }
                guard let idx = nodes.firstIndex(where: { $0.id == prev.id }) else { continue }
                let already = Set(nodes[idx].connections)
                let candidates = currentLayer.filter { !already.contains($0.id) }
                if let extra = candidates.randomElement() {
                    nodes[idx].connections.append(extra.id)
                }
            }

            previousLayer = currentLayer
        }

        // --- Finale node ---
        let finaleNode = MapNode(
            type: finaleType,
            position: CGPoint(x: 0.5, y: 0.08),
            layerIndex: numLayers + 1
        )
        nodes.append(finaleNode)

        // Son mid-layer → finale (tüm paths tek bosta toplansın)
        for prev in previousLayer {
            if let idx = nodes.firstIndex(where: { $0.id == prev.id }),
               !nodes[idx].connections.contains(finaleNode.id) {
                nodes[idx].connections.append(finaleNode.id)
            }
        }

        // NOTE: `bossNodeId` semantik olarak artık "finale node id". Boss olmayan
        // chapter'larda bu bir elite encounter'ı işaret eder. İsim geriye dönük
        // uyumluluk için korundu (save dosyaları).
        return ChapterMap(
            id: UUID(),
            chapterIndex: chapterIndex,
            nodes: nodes,
            startNodeId: startNode.id,
            bossNodeId: finaleNode.id
        )
    }

    /// Layer içindeki pozisyona ve chapter tipine göre node türü seç.
    /// - Dengeli dağılım: her chapter'da en az bir rest (son mid-layer) ve
    ///   ortada treasure/elite odası bulunur.
    /// - Dallanmalı layer'larda sol lane "tehlikeli" (elite/mystery), sağ lane
    ///   "güvenli" (merchant/rest) eğilimindedir — kullanıcıya net seçim sunar.
    private static func pickNodeType(
        layer: Int,
        numLayers: Int,
        laneIdx: Int,
        lanes: Int,
        isBossChapter: Bool
    ) -> NodeType {
        // Finale'den önceki layer: rest (soluklanma) — her zaman
        if layer == numLayers {
            return .rest
        }
        // Orta layer'da treasure/elite anchor
        if layer == max(1, numLayers / 2) {
            // Birden fazla lane varsa ortadaki treasure olsun
            if lanes > 1 && laneIdx == lanes / 2 {
                return .treasure
            }
            if !isBossChapter { return .treasure }
            return .elite
        }

        // Risky/safe lane yönlendirmesi (sol lane = risky)
        let isLeftLane = lanes > 1 && laneIdx == 0
        let isRightLane = lanes > 1 && laneIdx == lanes - 1

        let rand = Double.random(in: 0...1)
        if isBossChapter {
            if isLeftLane {
                if rand < 0.45 { return .elite }
                if rand < 0.7  { return .mystery }
                return .normal
            } else if isRightLane {
                if rand < 0.35 { return .merchant }
                if rand < 0.6  { return .mystery }
                return .normal
            }
            if rand < 0.25 { return .elite }
            if rand < 0.5  { return .mystery }
            return .normal
        } else {
            if isLeftLane {
                if rand < 0.35 { return .elite }
                if rand < 0.6  { return .mystery }
                return .normal
            } else if isRightLane {
                if rand < 0.4  { return .merchant }
                if rand < 0.6  { return .mystery }
                if rand < 0.75 { return .rest }
                return .normal
            }
            if rand < 0.2 { return .elite }
            if rand < 0.4 { return .merchant }
            if rand < 0.55 { return .mystery }
            return .normal
        }
    }
}
