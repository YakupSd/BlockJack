//
//  ScoreEngine.swift
//  Block-Jack
//
//  Scoring Engine V4 - Generous Scoring Strategy
//  Focus: Higher base chips, color-based multipliers, and balanced streak scaling.
//

import Foundation
import SwiftUI

// MARK: - Line Pattern
enum LinePattern {
    case mixed        // 3+ different colors
    case duoTone      // Exactly 2 colors
    case triTone      // Exactly 3 colors
    case gradient     // All 5 colors (rainbow)
    case flush        // All 13 cells same color
    case superFlush   // 2+ lines cleared, both Flush
    case none

    var baseMultValue: Double {
        switch self {
        case .mixed: return 5.0
        case .duoTone: return 10.0
        case .triTone: return 15.0
        case .gradient: return 25.0
        case .flush: return 50.0
        case .superFlush: return 150.0
        case .none: return 0
        }
    }

    func label(lang: AppLanguage) -> String? {
        switch self {
        case .mixed: return nil
        case .duoTone: return lang == .turkish ? "2-RENK! +5.0" : "DUO-TONE! +5.0"
        case .triTone: return lang == .turkish ? "3-RENK! +7.0" : "TRI-TONE! +7.0"
        case .gradient: return lang == .turkish ? "GÖKKUŞAĞI! +9.0" : "GRADIENT! +9.0"
        case .flush: return lang == .turkish ? "FLUSH! +16.0" : "FLUSH! +16.0"
        case .superFlush: return lang == .turkish ? "SÜPER FLUSH! +40.0" : "SUPER FLUSH! +40.0"
        case .none: return nil
        }
    }
    
    var glowColor: Color {
        switch self {
        case .mixed: return .white
        case .duoTone: return .yellow
        case .gradient: return .orange
        case .flush: return ThemeColors.neonCyan
        case .superFlush: return ThemeColors.neonPurple
        default: return .white
        }
    }
}

// MARK: - Score Context
struct ScoreContext {
    var baseChips: Double = 0
    var additiveMult: Double = 0        // ΣAdditiveMult
    var multiplicativeMult: Double = 1.0  // ΠMultiplicativeMult
    
    var finalScore: Int {
        // TotalScore = (BaseChips) × (1.0 + ΣAdditiveMult) × ΠMultiplicativeMult
        Int(round(baseChips * (1.0 + additiveMult) * multiplicativeMult))
    }
    
    mutating func addMult(_ value: Double) {
        additiveMult += value
    }
    
    mutating func multiplyMult(_ value: Double) {
        multiplicativeMult *= value
    }
}

// MARK: - Score Result
struct ScoreResult {
    let baseChips: Int
    let additiveMult: Double
    let multiplicativeMult: Double
    let totalScore: Int
    
    let patterns: [LinePattern]
    let comboCount: Int
    let streak: Int
    let clearedRows: Int
    let clearedCols: Int
    
    func displayLabel(lang: AppLanguage) -> String? {
        if patterns.contains(.superFlush) { return lang == .turkish ? "SÜPER FLUSH!" : "SUPER FLUSH!" }
        if patterns.contains(.flush) { return lang == .turkish ? "FLUSH!" : "FLUSH!" }
        if comboCount >= 4 { return lang == .turkish ? "DÖRTLÜ TEMİZLEME!" : "QUAD CLEAR!" }
        if comboCount >= 2 { return lang == .turkish ? "KOMBO! ×\(comboCount)" : "COMBO! ×\(comboCount)" }
        return patterns.first?.label(lang: lang)
    }

    var isFlush: Bool { patterns.contains(.flush) || patterns.contains(.superFlush) }
    var isBigCombo: Bool { comboCount >= 2 }

    var clearCombo: ClearCombo {
        if patterns.contains(.superFlush) { return .megaZone }
        switch comboCount {
        case 2: return .double
        case 3...: return .triple
        default: return .single
        }
    }
}

// Retro-compatibility enum for existing VM logic
enum ClearCombo {
    case single, double, triple, cross, zoneBlast, megaZone
    func label(lang: AppLanguage) -> String? {
        switch self {
        case .single: return nil
        case .double: return lang == .turkish ? "ÇİFT TEMİZLEME!" : "DOUBLE CLEAR!"
        case .triple: return lang == .turkish ? "ÜÇLÜ TEMİZLEME!" : "TRIPLE CLEAR!"
        case .cross: return lang == .turkish ? "ÇAPRAZ TEMİZLEME!" : "CROSS CLEAR!"
        case .zoneBlast: return lang == .turkish ? "ALAN PATLAMASI!" : "ZONE BLAST!"
        case .megaZone: return lang == .turkish ? "MEGA PATLAMA!" : "MEGA BLAST!"
        }
    }
}

// MARK: - ScoreEngine
struct ScoreEngine {
    
    // Phase 1: Placement Scoring (V4 - MAJOR BOOST)
    static func calculatePlacementChips(mass: Int, neighbors: Int, cluster: Int) -> Double {
        // BaseChips = (BlockMass × 20) + (NeighborBonus × 10) + (ClusterBonus × 5)
        let massPoints = Double(mass * 20)
        let neighborPoints = Double(neighbors * 10)
        let clusterPoints = Double(cluster * 5)
        return massPoints + neighborPoints + clusterPoints
    }
    
    // Phase 2: Color Bonus (NEW)
    static func calculateColorBonus(cells: [GameCell]) -> Double {
        // Equal color distribution: all colors worth 1.0
        // This prevents bias toward purple/yellow and encourages color diversity
        // Color bonus = average value of all cleared cells in this line
        let colorValues: [BlockDisplayColor: Double] = [
            .blue: 1.0,
            .green: 1.0,
            .red: 1.0,
            .yellow: 1.0,
            .purple: 1.0
        ]
        
        let validCells = cells.filter { $0.color != nil }
        guard !validCells.isEmpty else { return 0.0 }
        
        let totalValue = validCells.reduce(0.0) { sum, cell in
            sum + (colorValues[cell.color!] ?? 1.0)
        }
        
        return totalValue / Double(validCells.count)
    }

    // Phase 3: Pattern & Combo Detection
    static func comboBonus(_ lines: Int) -> Double {
        // Combo multipliers based on simultaneous line clears
        // Aligned with SCORING_ENGINE_V2.md Phase 3: Combo Stack
        switch lines {
        case 0: return 0.0      // No lines cleared
        case 1: return 0.0      // Single line (no combo bonus)
        case 2: return 10.0     // Double (+10.0)
        case 3: return 25.0     // Triple (+25.0)
        case 4: return 75.0     // QUAD (+75.0) - Massive boost for rare moves
        case 5...: return 150.0 // MEGA 5+ (+150.0)
        default: return 0
        }
    }
    
    static func sizeBonus(_ totalCells: Int) -> Double {
        // SizeBonus = (TotalCellsCleared / 8) × 2.0
        return (Double(totalCells) / 8.0) * 2.0
    }
    
    // Phase 5: Streak X-Mult (V4 - Exponential)
    static func calculateStreakXMult(streak: Int) -> Double {
        if streak <= 0 { return 1.0 }
        // Formula: 1.15^streak (Faster scaling for Elite players)
        return pow(1.15, Double(streak))
    }
    
    // MARK: - Detection Logic
    static func detectPattern(cells: [GameCell]) -> LinePattern {
        let occupiedCells = cells.filter { $0.isOccupied }
        guard !occupiedCells.isEmpty else { return .none }
        
        let colors = occupiedCells.compactMap { $0.color }
        let uniqueColors = Set(colors)
        
        switch uniqueColors.count {
        case 1: return .flush
        case 2: return .duoTone
        case 3: return .triTone
        case 5: return .gradient
        default: return .mixed
        }
    }
    
    // MARK: - Main Pipeline
    static func calculate(
        placementMass: Int,
        neighbors: Int,
        cluster: Int,
        clearedLines: [[GameCell]],
        combo: Int,
        streak: Int,
        perks: [PassivePerk],
        timeRemaining: TimeInterval,
        overkillCarryover: Int = 0,
        rowsCleared: Int = 0,
        colsCleared: Int = 0,
        frenzyMult: Double = 1.0,
        currentHP: Int = 0
    ) -> ScoreResult {
        var context = ScoreContext()
        
        // 1. Phase: Base Chips Boost
        context.baseChips = calculatePlacementChips(mass: placementMass, neighbors: neighbors, cluster: cluster)
        
        // 2 & 3. Phase: DETECTION, COMBO & COLOR BONUS
        var patterns: [LinePattern] = []
        var totalColorBonus: Double = 0.0
        var totalCellsCleared: Int = 0
        
        for line in clearedLines {
            let pattern = detectPattern(cells: line)
            patterns.append(pattern)
            context.addMult(pattern.baseMultValue)
            totalColorBonus += calculateColorBonus(cells: line)
            totalCellsCleared += line.count
        }
        
        // Color Bonus Average
        if !clearedLines.isEmpty {
            context.addMult(totalColorBonus / Double(clearedLines.count))
        }
        
        // Combo & Size Bonus
        context.addMult(comboBonus(combo))
        if totalCellsCleared > 0 {
            context.addMult(sizeBonus(totalCellsCleared))
        }
        
        // Super Flush check (Override pattern mult if needed)
        let flushCount = patterns.filter { $0 == .flush }.count
        if flushCount >= 2 {
            context.addMult(40.0) // Super Flush bonus
            patterns.append(.superFlush)
        }
        
        // 4. Phase: PERKS (Additive)
        applyPerkBonuses(to: &context, perks: perks, streak: streak, clearedLines: clearedLines)
        
        // 5. Phase: X-FACTOR (Multiplicative)
        // Streak Mult (Hybrid)
        let streakMult = calculateStreakXMult(streak: streak)
        context.multiplyMult(streakMult)
        
        // Frenzy Mult
        if frenzyMult > 1.0 {
            context.multiplyMult(frenzyMult)
        }
        
        // Perk X-Mults
        applyPerkXMults(to: &context, perks: perks, timeRemaining: timeRemaining, overkillCarryover: overkillCarryover, currentHP: currentHP)
        
        return ScoreResult(
            baseChips: Int(context.baseChips),
            additiveMult: context.additiveMult,
            multiplicativeMult: context.multiplicativeMult,
            totalScore: context.finalScore,
            patterns: patterns,
            comboCount: combo,
            streak: streak,
            clearedRows: rowsCleared,
            clearedCols: colsCleared
        )
    }
    
    // MARK: - Perk Implementation (Pipeline V4)
    
    private static func applyPerkBonuses(
        to context: inout ScoreContext,
        perks: [PassivePerk],
        streak: Int,
        clearedLines: [[GameCell]]
    ) {
        for perk in perks {
            switch perk.id {
            case "blue_pill":
                let hasBlue = clearedLines.flatMap { $0 }.contains { if case .filled(let color) = $0.state, color == .blue { return true } else { return false } }
                if hasBlue {
                    let value = PerkUpgradeRegistry.tierData(for: .bluePill, tier: perk.tier).effectValue
                    context.addMult(value)
                }
            case "lead_pill":
                let hasGreen = clearedLines.flatMap { $0 }.contains { if case .filled(let color) = $0.state, color == .green { return true } else { return false } }
                if hasGreen {
                    let value = PerkUpgradeRegistry.tierData(for: .leadPill, tier: perk.tier).effectValue
                    context.addMult(value)
                }
            case "momentum":
                if streak % 4 == 0 && streak > 0 {
                    let value = PerkUpgradeRegistry.tierData(for: .momentum, tier: perk.tier).effectValue
                    context.addMult(value)
                }
            case "lucky_clover":
                // Lucky Clover: Increases max streak limit (game logic) + boosts score per streak level
                // Registry: effectValue = max streak limit (5-40 by tier)
                // Scoring: +0.2 additive mult per streak level
                // Example: Tier 5 (limit 40) + Streak 30 → +6.0 additive mult
                context.addMult(Double(streak) * 0.2)
            default:
                break
            }
        }
    }
    
    private static func applyPerkXMults(
        to context: inout ScoreContext,
        perks: [PassivePerk],
        timeRemaining: TimeInterval,
        overkillCarryover: Int,
        currentHP: Int
    ) {
        for perk in perks {
            switch perk.id {
            case "glass_cannon":
                let value = PerkUpgradeRegistry.tierData(for: .glassCannon, tier: perk.tier).effectValue
                let hpThreshold: Int = (perk.tier <= 2) ? 1 : (perk.tier <= 4 ? 2 : 3)
                if currentHP <= hpThreshold && currentHP > 0 {
                    context.multiplyMult(value)
                }
            case "overkill":
                if overkillCarryover > 0 {
                    let carryoverRate = PerkUpgradeRegistry.tierData(for: .overkill, tier: perk.tier).effectValue
                    let carriedBonus = Double(overkillCarryover) * carryoverRate
                    context.baseChips += carriedBonus
                }
            default:
                break
            }
        }
    }
    
    // MARK: - Economic Overflow
    static func calculateOverflowGold(score: Int, target: Int) -> Int {
        guard score > target else { return 0 }
        let excess = Double(score - target)
        let ratio = excess / Double(target)
        
        if ratio >= 5.0 { return 25 }
        if ratio >= 2.0 { return 20 }
        if ratio >= 1.0 { return 10 }
        if ratio >= 0.5 { return 5 }
        if ratio >= 0.25 { return 2 }
        return 0
    }
    
    static func goldEarned(for result: ScoreResult, hasGoldEye: Bool = false) -> Int {
        let base = result.totalScore / 500
        let flushBonus = result.isFlush ? 5 : 0
        let comboBonus = result.isBigCombo ? 3 : 0
        let raw = base + flushBonus + comboBonus
        let multiplier = hasGoldEye ? 1.25 : 1.0
        return Int(Double(raw) * multiplier)
    }
}
