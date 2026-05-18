//
//  DuelSeedEngine.swift
//  Block-Jack
//

import Foundation

// MARK: - Duel Seed Engine
final class DuelSeedEngine {

    /// Verilen seed'den deterministik blok dizisi üretir
    static func blockSequence(seed: Int64, count: Int) -> [BlockType] {
        var rng = SeededRNG(seed: seed)
        return (0..<count).map { _ in
            let index = Int(rng.next() % UInt64(BlockType.allCases.count))
            return BlockType.allCases[index]
        }
    }

    /// Yeni rastgele seed üretir
    static func generateSeed() -> Int64 {
        Int64.random(in: 100_000...999_999_999)
    }
}

// MARK: - Seeded RNG (LCG)
/// Basit, seed'li pseudo-random number generator (Linear Congruential Generator)
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int64) {
        self.state = UInt64(bitPattern: seed)
    }

    mutating func next() -> UInt64 {
        // LCG parametreleri (GCC tarafından kullanılan)
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}
