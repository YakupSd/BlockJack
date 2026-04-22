//
//  GridModifier.swift
//  Block-Jack
//

import Foundation

// MARK: - Bonus Type
enum BonusType: Codable, Equatable {
    case gold(Int)
    case star
    case timeBoost(Double)
}

// MARK: - Cell Modifier Type
enum CellModifierType: Codable, Equatable {
    case locked
    case bonus(BonusType)
    case cursed
    case gravity
    /// Static Charge perki aktifken round başında gride yerleştirilir. Bu hücre
    /// bir temizliğin parçası olduğunda overdrive barına burst şarj ekler.
    case staticCharge
}
