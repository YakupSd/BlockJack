//
//  ScoreEngine.swift
//  Block-Jack
//

import Foundation

// MARK: - Flush Type
enum FlushType {
    case none        // Karışık renk
    case half        // >%50 aynı renk → ×2
    case full        // %100 aynı renk → ×5

    var multiplier: Double {
        switch self {
        case .none: return 1.0
        case .half: return 2.0
        case .full: return 5.0
        }
    }

    var label: String? {
        switch self {
        case .none: return nil
        case .half: return "COLOR BONUS ×2"
        case .full: return "FLUSH! ×5"
        }
    }
}

// MARK: - Clear Type
enum ClearCombo {
    case single              // 1 satır/sütun
    case double              // 2 satır/sütun
    case triple              // 3+
    case cross               // Satır + sütun aynı anda
    
    var multiplierBonus: Double {
        switch self {
        case .single: return 1.0
        case .double: return 2.5
        case .triple: return 5.0
        case .cross:  return 3.5
        }
    }
    
    var label: String? {
        switch self {
        case .single: return nil
        case .double: return "DOUBLE CLEAR! ×2.5"
        case .triple: return "MEGA CLEAR! ×5"
        case .cross:  return "CROSS CLEAR! ×3.5"
        }
    }
}

// MARK: - Score Result
struct ScoreResult {
    let baseChips: Int
    let multiplier: Double
    let totalScore: Int
    let flushType: FlushType
    let clearCombo: ClearCombo
    let clearedRows: Int
    let clearedCols: Int
    let streakBonus: Double

    var isFlush: Bool { flushType == .full }
    var isBigCombo: Bool { clearCombo != .single }
    
    var displayLabel: String? {
        // Önce en büyük combo labelını göster
        if let comboLabel = clearCombo.label { return comboLabel }
        return flushType.label
    }
    
    var allLabels: [String] {
        var labels: [String] = []
        if let cl = clearCombo.label { labels.append(cl) }
        if let fl = flushType.label { labels.append(fl) }
        return labels
    }
}

// MARK: - ScoreEngine
struct ScoreEngine {

    // MARK: - Ana hesaplama (Güncel: boyuta göre chip, multiplier sistemi)
    static func calculate(
        clearedCells: [GameCell],
        blockCellCount: Int = 4,   // Yerleştirilen bloğun hücre sayısı (chip değeri için)
        streak: Int,
        clearedRows: Int,
        clearedCols: Int,
        jokerMultBonus: Double = 0.0
    ) -> ScoreResult {

        // Chip değeri: Temizlenen hücre sayısına göre tier × hücre
        let chipsPerCell: Int
        switch clearedCells.count {
        case 0..<6:   chipsPerCell = 5
        case 6..<10:  chipsPerCell = 8
        case 10..<16: chipsPerCell = 12
        default:      chipsPerCell = 15
        }
        
        let baseChips = clearedCells.count * chipsPerCell
        
        // Clear combo detects: cross > triple > double > single
        let totalLines = clearedRows + clearedCols
        let clearCombo: ClearCombo
        if clearedRows > 0 && clearedCols > 0 {
            clearCombo = .cross
        } else if totalLines >= 3 {
            clearCombo = .triple
        } else if totalLines == 2 {
            clearCombo = .double
        } else {
            clearCombo = .single
        }
        
        // Flush detection
        let flush = detectFlush(cells: clearedCells)
        
        // Streak bonus: her 3 combo +0.5 mult, max +3.0
        let streakBonus = min(Double(streak / 3) * 0.5, 3.0)
        
        // Final multiplier = base (1.0) + clear combo + flush + streak + joker
        let mult = clearCombo.multiplierBonus + flush.multiplier - 1.0 + streakBonus + jokerMultBonus
        
        let total = max(10, Int(Double(baseChips) * max(1.0, mult)))

        return ScoreResult(
            baseChips: baseChips,
            multiplier: mult,
            totalScore: total,
            flushType: flush,
            clearCombo: clearCombo,
            clearedRows: clearedRows,
            clearedCols: clearedCols,
            streakBonus: streakBonus
        )
    }

    // MARK: - Flush tespiti
    static func detectFlush(cells: [GameCell]) -> FlushType {
        guard !cells.isEmpty else { return .none }

        let coloredCells = cells.compactMap { $0.color }
        guard !coloredCells.isEmpty else { return .none }

        var counts: [BlockDisplayColor: Int] = [:]
        for color in coloredCells { counts[color, default: 0] += 1 }
        let maxCount = counts.values.max() ?? 0
        let ratio = Double(maxCount) / Double(coloredCells.count)

        if ratio >= 1.0 { return .full }
        if ratio >= 0.5 { return .half }
        return .none
    }

    // MARK: - Süre bonusu hesabı
    static func timeBonusSeconds(clearCombo: ClearCombo, isFlush: Bool, streakCount: Int) -> Double {
        var bonus: Double
        switch clearCombo {
        case .single: bonus = 2.0
        case .double: bonus = 5.0
        case .triple: bonus = 10.0
        case .cross:  bonus = 8.0
        }
        if isFlush { bonus += 4.0 }
        if streakCount >= 5 { bonus += 3.0 }
        return bonus
    }

    // MARK: - Altın kazancı
    static func goldEarned(for result: ScoreResult, hasGoldEye: Bool = false) -> Int {
        var gold = result.totalScore / 300  // Her 300 puan = 1 altın
        if result.isFlush { gold += 3 }
        if result.isBigCombo { gold += 2 }
        
        // Meta-Upgrade: Gold Eye (+10%)
        if hasGoldEye {
            gold = Int(Double(gold) * 1.1)
        }
        
        return max(1, gold)
    }
    
    // MARK: - Overdrive / Power Clear Score
    /// Özel güçler için puan hesaplar. Normal temizliğin yaklaşık 2.5 katı etkilidir.
    static func calculatePowerClear(basePoints: Int, multiplier: Double) -> Int {
        let powerMultiplier = 2.5
        return Int(Double(basePoints) * multiplier * powerMultiplier)
    }
}
