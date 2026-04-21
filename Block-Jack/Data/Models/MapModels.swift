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
    let bossNodeId: UUID
    
    mutating func updateNode(_ node: MapNode) {
        if let index = nodes.firstIndex(where: { $0.id == node.id }) {
            nodes[index] = node
        }
    }
}

// MARK: - Chapter Map Generator
class ChapterMapGenerator {
    static func generate(chapterIndex: Int) -> ChapterMap {
        let isBossChapter = (chapterIndex == 3 || chapterIndex % 5 == 0) && chapterIndex > 0
        let nodeCount = isBossChapter ? Int.random(in: 5...7) : Int.random(in: 8...12)
        var nodes: [MapNode] = []
        
        let startNode = MapNode(type: .normal, position: CGPoint(x: 0.5, y: 0.9), isAccessible: true, layerIndex: 0)
        let levels = nodeCount / 2 // Approximately
        let bossNode = MapNode(type: .boss, position: CGPoint(x: 0.5, y: 0.1), layerIndex: levels)
        
        nodes.append(startNode)
        
        var previousLevelNodes: [MapNode] = [startNode]
        
        for level in 1..<levels {
            let numNodesInLevel = isBossChapter ? 1 : Int.random(in: 1...2) 
            var currentLevelNodes: [MapNode] = []
            
            for _ in 0..<numNodesInLevel {
                var type: NodeType = .normal
                let rand = Double.random(in: 0...1)
                
                if level == levels / 2 {
                    type = isBossChapter ? .elite : .treasure
                } else if level == levels - 1 {
                    type = .rest
                } else {
                    if isBossChapter {
                        if rand < 0.3 { type = .elite }
                        else if rand < 0.6 { type = .mystery }
                    } else {
                        if rand < 0.2 { type = .elite }
                        else if rand < 0.35 { type = .merchant }
                        else if rand < 0.5 { type = .mystery }
                    }
                }
                
                let yPos = 0.9 - (0.8 * (Double(level) / Double(levels)))
                let xPos = numNodesInLevel == 1 ? 0.5 : Double.random(in: 0.2...0.8)
                
                let node = MapNode(type: type, position: CGPoint(x: xPos, y: yPos), layerIndex: level)
                currentLevelNodes.append(node)
                nodes.append(node)
            }
            
            for i in 0..<previousLevelNodes.count {
                if let index = nodes.firstIndex(where: { $0.id == previousLevelNodes[i].id }) {
                    for targetNode in currentLevelNodes {
                        if !nodes[index].connections.contains(targetNode.id) {
                            nodes[index].connections.append(targetNode.id)
                        }
                    }
                }
            }
            previousLevelNodes = currentLevelNodes
        }
        
        for prev in previousLevelNodes {
            if let index = nodes.firstIndex(where: { $0.id == prev.id }) {
                nodes[index].connections.append(bossNode.id)
            }
        }
        nodes.append(bossNode)
        return ChapterMap(id: UUID(), chapterIndex: chapterIndex, nodes: nodes, startNodeId: startNode.id, bossNodeId: bossNode.id)
    }
}
