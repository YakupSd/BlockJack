//
//  RunConfig.swift
//  Block-Jack
//

import Foundation

/// Pre-run seçimleri için tek kaynak (tek truth).
struct RunConfig: Codable, Equatable {
    var slotId: Int
    var characterId: String
    var startingPerkId: String
    var worldId: Int
    var startingItemId: String? = nil
}

