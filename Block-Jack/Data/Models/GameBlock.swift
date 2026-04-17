//
//  GameBlock.swift
//  Block-Jack
//

import Foundation
import SwiftUI

// MARK: - Block Special Ability
enum BlockAbility: String, Codable, Equatable {
    case normal       // Standart blok
    case lightning    // Yerleşince tüm satırı siler ⚡
    case bomb         // 3x3 alanı siler 💣
    case wild         // Yanındaki boş hücreleri doldurur 🌀
    
    var icon: String {
        switch self {
        case .normal:    return ""
        case .lightning: return "⚡"
        case .bomb:      return "💣"
        case .wild:      return "🌀"
        }
    }
    
    var displayName: String {
        switch self {
        case .normal:    return ""
        case .lightning: return "LIGHTNING"
        case .bomb:      return "BOMB"
        case .wild:      return "WILD"
        }
    }
    
    var glowColor: Color {
        switch self {
        case .normal:    return .clear
        case .lightning: return Color(hue: 0.15, saturation: 1.0, brightness: 1.0)  // Parlak sarı
        case .bomb:      return Color(hue: 0.02, saturation: 1.0, brightness: 1.0)  // Kırmızı
        case .wild:      return Color(hue: 0.55, saturation: 1.0, brightness: 1.0)  // Cyan
        }
    }
}

// MARK: - Block Type
enum BlockType: String, CaseIterable, Codable {
    case I, L, J, O, T, S, Z       // Standart
    case lMirror = "L_MIRROR"
    case single = "1x1"            // Nadir kurtarıcı
    case hollow = "HOLLOW"         // 3x3 ortası boş
    case chain = "CHAIN"           // Diğer chain ile yapışır
    case plus = "PLUS"             // 3x3 +
    case uShape = "U_SHAPE"        // 3x2 U
    case stair = "STAIR"           // 3x2 basamak
    case star5 = "STAR5"           // 3x3 X shape

    var rarity: BlockRarity {
        switch self {
        case .single:              return .rare
        case .I, .O:               return .common
        case .L, .J, .lMirror, .T: return .uncommon
        case .S, .Z, .chain, .plus, .uShape, .stair: return .uncommon
        case .hollow, .star5:              return .rare
        }
    }
    
    /// Round'a göre spawn edilebilir mi?
    func isAvailable(forRound round: Int) -> Bool {
        // Tüm blokları 1. rounddan itibaren açıyoruz (Zorluk artışı için)
        return true
    }
}

// MARK: - Block Rarity
enum BlockRarity {
    case common, uncommon, rare
    var spawnWeight: Int {
        switch self {
        case .common:   return 8    // O, I
        case .uncommon: return 10   // T, L, J, S, Z (Daha sık gelsin ki zorlaşsın)
        case .rare:     return 5    // Single, Hollow, Chain
        }
    }
}

// MARK: - GameBlock
struct GameBlock: Identifiable, Equatable, Codable {
    let id: UUID
    let type: BlockType
    let color: BlockDisplayColor
    let ability: BlockAbility
    var pairedBlockId: UUID? = nil
    var rotationSteps: Int = 0 // 0: 0°, 1: 90°, 2: 180°, 3: 270°
    
    var isSpecial: Bool { ability != .normal || type == .chain || type == .hollow }

    init(id: UUID = UUID(), type: BlockType, color: BlockDisplayColor, ability: BlockAbility = .normal, pairedBlockId: UUID? = nil, rotationSteps: Int = 0) {
        self.id = id
        self.type = type
        self.color = color
        self.ability = ability
        self.pairedBlockId = pairedBlockId
        self.rotationSteps = rotationSteps
    }

    // shape: true olan hücreler dolu
    var shape: [[Bool]] {
        let baseShape = GameBlock.shapes[type] ?? [[true]]
        return applyRotation(baseShape, steps: rotationSteps)
    }

    private func applyRotation(_ matrix: [[Bool]], steps: Int) -> [[Bool]] {
        var current = matrix
        for _ in 0..<(steps % 4) {
            current = rotate90Clockwise(current)
        }
        return current
    }

    private func rotate90Clockwise(_ matrix: [[Bool]]) -> [[Bool]] {
        guard !matrix.isEmpty else { return matrix }
        let rows = matrix.count
        let cols = matrix[0].count
        var rotated = Array(repeating: Array(repeating: false, count: rows), count: cols)
        
        for r in 0..<rows {
            for c in 0..<cols {
                rotated[c][rows - 1 - r] = matrix[r][c]
            }
        }
        return rotated
    }

    mutating func rotate() {
        rotationSteps = (rotationSteps + 1) % 4
    }

    var rows: Int { shape.count }
    var cols: Int { shape.first?.count ?? 1 }

    /// (satır, sütun) offsetlerini döndürür
    var cells: [(row: Int, col: Int)] {
        var result: [(Int, Int)] = []
        for r in 0..<rows {
            for c in 0..<cols {
                if shape[r][c] { result.append((r, c)) }
            }
        }
        return result
    }

    // MARK: - Tüm şekil tanımları
    static let shapes: [BlockType: [[Bool]]] = [
        .I: [
            [true, true, true, true]
        ],
        .L: [
            [true, false],
            [true, false],
            [true, true]
        ],
        .J: [
            [false, true],
            [false, true],
            [true,  true]
        ],
        .O: [
            [true, true],
            [true, true]
        ],
        .T: [
            [true, true, true],
            [false, true, false]
        ],
        .S: [
            [false, true, true],
            [true,  true, false]
        ],
        .Z: [
            [true,  true, false],
            [false, true, true]
        ],
        .lMirror: [
            [false, true],
            [false, true],
            [true,  true]
        ],
        .single: [
            [true]
        ],
        .hollow: [
            [true, true, true],
            [true, false, true],
            [true, true, true]
        ],
        .chain: [
            [true, true]
        ],
        .plus: [
            [false, true, false],
            [true,  true, true],
            [false, true, false]
        ],
        .uShape: [
            [true,  false, true],
            [true,  true,  true]
        ],
        .stair: [
            [true,  false],
            [true,  true],
            [false, true]
        ],
        .star5: [
            [true,  false, true],
            [false, true,  false],
            [true,  false, true]
        ]
    ]

    // MARK: - Factory

    /// Normal round havuzundan rastgele blok
    static func random(forRound round: Int = 99) -> GameBlock {
        let available = BlockType.allCases.filter { $0.isAvailable(forRound: round) }
        let weighted = available.flatMap { type in
            Array(repeating: type, count: type.rarity.spawnWeight)
        }
        let type = weighted.randomElement() ?? .O
        let color = BlockDisplayColor.allCases.randomElement() ?? .blue
        
        // Özel blok şansı (Round 3'ten itibaren, %8 ihtimal)
        let abilityRoll = Int.random(in: 1...100)
        let ability: BlockAbility
        if round >= 3 && abilityRoll <= 8 {
            ability = [BlockAbility.lightning, .bomb, .wild].randomElement() ?? .normal
        } else {
            ability = .normal
        }
        
        return GameBlock(type: type, color: color, ability: ability)
    }
    
    /// Belirli bir özel yeteneğe sahip blok oluştur (mağaza için)
    static func special(ability: BlockAbility, forRound round: Int = 1) -> GameBlock {
        let available = BlockType.allCases.filter { $0.isAvailable(forRound: round) && $0 != .single }
        let type = available.randomElement() ?? .L
        let color = BlockDisplayColor.allCases.randomElement() ?? .blue
        return GameBlock(type: type, color: color, ability: ability)
    }
}
