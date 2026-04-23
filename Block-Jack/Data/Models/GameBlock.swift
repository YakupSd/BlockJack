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
    case I, L, J, O, T, S, Z       // Standart tetromino'lar
    case single = "1x1"            // Nadir kurtarıcı
    case chain = "CHAIN"           // 1x2 domino — eşlenebilir
    case plus = "PLUS"             // 3x3 +
    case uShape = "U_SHAPE"        // 3x2 U
    case stair = "STAIR"           // 3x2 basamak
    // Yeni eklenen şekiller (Nisan 2026 revizesi):
    case duo = "DUO"               // 1x3 düz üçlü — basit yardımcı
    case smallL = "SMALL_L"        // 2x2 L — mini köşe
    case bigI = "BIG_I"            // 1x5 uzun sıra — nadir kurtarıcı
    case triangle = "TRIANGLE"     // 3x3 üçgen (hipotenüs)
    case diagonal = "DIAGONAL"     // 2x2 çapraz — zorlayıcı, nadir

    var rarity: BlockRarity {
        switch self {
        case .I, .O, .duo, .smallL:                         return .common
        case .L, .J, .T, .S, .Z,
             .chain, .plus, .uShape, .stair, .triangle:     return .uncommon
        case .single, .bigI, .diagonal:                     return .rare
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
    
    var isSpecial: Bool { ability != .normal || type == .chain }
    
    var isRotatable: Bool {
        switch type {
        case .O, .single, .plus, .diagonal: return false
        default: return true
        }
    }

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
        .single: [
            [true]
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
        // --- Yeni şekiller (Nisan 2026) ---
        .duo: [
            [true, true, true]
        ],
        .smallL: [
            [true, false],
            [true, true]
        ],
        .bigI: [
            [true, true, true, true, true]
        ],
        .triangle: [
            [true,  false, false],
            [true,  true,  false],
            [true,  true,  true]
        ],
        .diagonal: [
            [true,  false],
            [false, true]
        ]
    ]

    // MARK: - Factory

    /// Normal round havuzundan rastgele blok
    static func random(forRound round: Int = 99) -> GameBlock {
        random(forRound: round, luckLevel: 0)
    }

    /// Normal round havuzundan rastgele blok (Gold Upgrade: Block Luck ile boost)
    /// - luckLevel: 0...5 (UserEnvironment.GoldUpgrade.blockLuck)
    static func random(forRound round: Int = 99, luckLevel: Int) -> GameBlock {
        let available = BlockType.allCases.filter { $0.isAvailable(forRound: round) }
        let clampedLuck = max(0, min(5, luckLevel))
        let weighted = available.flatMap { type in
            var w = type.rarity.spawnWeight
            // Block Luck: nadir blokların ağırlığını artır, common'ı hafifçe azalt.
            switch type.rarity {
            case .rare:
                w += (2 * clampedLuck) // +0...+10
            case .uncommon:
                w += clampedLuck       // +0...+5
            case .common:
                w = max(1, w - clampedLuck) // 8 -> 3 (luck 5)
            }
            return Array(repeating: type, count: max(1, w))
        }
        let type = weighted.randomElement() ?? .O
        let color = BlockDisplayColor.allCases.randomElement() ?? .blue
        
        // Özel blok şansı (Round 3'ten itibaren, %8 ihtimal)
        // Block Luck ile +%2/level (max +%10) → toplam max %18
        let abilityRoll = Int.random(in: 1...100)
        let ability: BlockAbility
        let specialChance = 8 + (2 * clampedLuck)
        if round >= 3 && abilityRoll <= specialChance {
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
