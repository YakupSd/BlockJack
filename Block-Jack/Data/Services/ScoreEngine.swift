//
//  ScoreEngine.swift
//  Block-Jack
//

import Foundation

// MARK: - Flush Type
enum FlushType {
    case none        // Karışık renk
    case half        // >%50 aynı renk → ×2.5
    case full        // %100 aynı renk → ×7

    var multiplier: Double {
        switch self {
        case .none: return 1.0
        case .half: return 2.5
        case .full: return 7.0
        }
    }

    var label: String? {
        switch self {
        case .none: return nil
        case .half: return "COLOR BONUS ×2.5"
        case .full: return "FLUSH! ×7"
        }
    }
}

// MARK: - Clear Type
enum ClearCombo {
    case single              // 1 satır/sütun
    case double              // 2 satır/sütun
    case triple              // 3+
    case cross               // Satır + sütun aynı anda
    case zoneBlast           // 3x3 Alan patlaması
    case megaZone            // Birden fazla alan veya Line + Area
    
    var multiplierBonus: Double {
        switch self {
        case .single:    return 1.0
        case .double:    return 3.5
        case .triple:    return 8.0
        case .cross:     return 5.0
        // Zone blast'ler çok "tek atış" yapıyordu. Zone'ları hâlâ tatmin edici tutup
        // pacing'i korumak için çarpanları ciddi düşürüyoruz.
        case .zoneBlast: return 1.3
        case .megaZone:  return 3.0
        }
    }
    
    var label: String? {
        switch self {
        case .single: return nil
        case .double: return "DOUBLE CLEAR! ×3.5"
        case .triple: return "MEGA CLEAR! ×8"
        case .cross:  return "CROSS CLEAR! ×5"
        case .zoneBlast: return "ZONE BLAST! ×1.3"
        case .megaZone: return "OMEGA BLAST! ×3"
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

    // MARK: - Ana hesaplama
    // Sadece satır, sütun veya zone temizlendiğinde puan kazanılır.
    //
    // SCORING v2 — "Juice Pass":
    //  • Her temizlenen hücre: 40 puan (eski 15)
    //  • Satır/sütun başına: +350 puan (eski 150)
    //  • Zone (4x4/5x5) başına: +500 puan (pacing fix: zone tek başına round bitirmesin)
    //  • Combo/flush/streak çarpanları da belirgin büyütüldü — böylece
    //    küçük temizlikler bile "anlamlı sayı" hissi veriyor, büyük
    //    combo'lar ekranda patlama gibi duruyor (Balatro tarzı ödül).
    //  • RoundData.makeTarget buna göre ~2x yükseltildi; dengeye değil,
    //    algıya odaklı — skor hızlı ve tatmin edici artsın.
    static func calculate(
        clearedCells: [GameCell],
        blockCellCount: Int = 4,   // Chip değeri için artık ikincil önemde
        streak: Int,
        clearedRows: Int,
        clearedCols: Int,
        clearedZones: Int = 0,
        jokerMultBonus: Double = 0.0
    ) -> ScoreResult {

        // --- BASE SCORE ---
        let cellPoints = clearedCells.count * 40      // Her temizlenen hücre 40 puan
        let lineClearBonus = (clearedRows + clearedCols) * 350
        let zoneClearBonus = clearedZones * 500       // Zone artık "bonus", tek başına run taşımasın
        
        let baseScore = cellPoints + lineClearBonus + zoneClearBonus
        
        let totalLines = clearedRows + clearedCols
        let clearCombo: ClearCombo
        
        if clearedZones > 0 {
            if clearedZones > 1 || totalLines > 0 {
                clearCombo = .megaZone
            } else {
                clearCombo = .zoneBlast
            }
        } else if clearedRows > 0 && clearedCols > 0 {
            clearCombo = .cross
        } else {
            switch totalLines {
            case 2:  clearCombo = .double
            case 3...: clearCombo = .triple
            default: clearCombo = .single
            }
        }
        
        // Flush detection (Renk uyumu)
        let flush = detectFlush(cells: clearedCells)
        
        // Streak bonus: her 2 combo +0.75 mult, max +8.0 (daha gurur verici streak)
        let streakBonus = min(Double(streak / 2) * 0.75, 8.0)
        
        // Final multiplier
        let hasAnyClear = totalLines > 0 || clearedZones > 0
        let mult: Double
        if hasAnyClear {
            // Combo + Flush + Streak birleşimi
            mult = clearCombo.multiplierBonus + (flush.multiplier - 1.0) + streakBonus + jokerMultBonus
        } else {
            // Clear yoksa çarpan 1.0 (Zaten VM seviyesinde engellendi ama güvenlik için)
            mult = 1.0
        }
        
        let total = Int(Double(baseScore) * max(1.0, mult))

        return ScoreResult(
            baseChips: baseScore,
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
        // Zone'lar zaten hücre bazında çok değerli; ekstra süre bonusunu da düşür.
        case .zoneBlast: bonus = 6.0
        case .megaZone: bonus = 8.0
        }
        if isFlush { bonus += 4.0 }
        if streakCount >= 5 { bonus += 3.0 }
        return bonus
    }

    // MARK: - Altın kazancı
    /// Skor 2-3x büyüdüğü için divisor 300 → 650'ye çıkarıldı.
    /// Net etki: altın kazancı yaklaşık %25 buff'lı kalır; big combo/flush
    /// bonusları ise ekstra 2 → 4 / 3 → 5 olarak güçlendirildi.
    static func goldEarned(for result: ScoreResult, hasGoldEye: Bool = false) -> Int {
        var gold = result.totalScore / 650  // Her 650 puan = 1 altın
        if result.isFlush { gold += 5 }
        if result.isBigCombo { gold += 4 }
        
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
