//
//  GameCell.swift
//  Block-Jack
//

import Foundation

// MARK: - Cell State
enum CellState: Equatable, Codable {
    case empty
    case filled(color: BlockDisplayColor)
    case locked          // Boss: Glitch modifier
    case heavy(hits: Int) // Boss: Weight modifier (2 hit gerekir)
    
    // Custom Codable implementation since Swift enum with associated values needs it.
    private enum CodingKeys: String, CodingKey {
        case base, color, hits
    }
    
    private enum BaseState: String, Codable {
        case empty, filled, locked, heavy
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let base = try container.decode(BaseState.self, forKey: .base)
        
        switch base {
        case .empty:
            self = .empty
        case .filled:
            let color = try container.decode(BlockDisplayColor.self, forKey: .color)
            self = .filled(color: color)
        case .locked:
            self = .locked
        case .heavy:
            let hits = try container.decode(Int.self, forKey: .hits)
            self = .heavy(hits: hits)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .empty:
            try container.encode(BaseState.empty, forKey: .base)
        case .filled(let color):
            try container.encode(BaseState.filled, forKey: .base)
            try container.encode(color, forKey: .color)
        case .locked:
            try container.encode(BaseState.locked, forKey: .base)
        case .heavy(let hits):
            try container.encode(BaseState.heavy, forKey: .base)
            try container.encode(hits, forKey: .hits)
        }
    }
}

// MARK: - GameCell
struct GameCell: Identifiable, Equatable, Codable {
    let id: UUID
    var state: CellState = .empty
    var modifier: CellModifierType? = nil
    
    init(id: UUID = UUID(), state: CellState = .empty, modifier: CellModifierType? = nil) {
        self.id = id
        self.state = state
        self.modifier = modifier
    }

    var isEmpty: Bool {
        if case .empty = state { return true }
        return false
    }

    var isOccupied: Bool { !isEmpty }

    var isLocked: Bool {
        if case .locked = state { return true }
        if modifier == .locked { return true }
        return false
    }

    var color: BlockDisplayColor? {
        if case .filled(let c) = state { return c }
        if case .heavy = state { return .yellow }
        return nil
    }
}

