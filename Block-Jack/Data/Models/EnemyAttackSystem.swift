//
//  EnemyAttackSystem.swift
//  Block-Jack
//

import SwiftUI

// MARK: - Düşman Atak Türleri

enum EnemyAttackType: String, CaseIterable {
    
    // Her round rastgele bir tane seçilir
    case gridSabotage     // Rastgele 4-6 dolu hücreyi siler
    case lastBlockErase   // Son yerleştirilen bloğun hücrelerini siler
    case trayLockdown     // Tepsideki blokları 12sn kilitle (yerleştirilemez)
    case scramble         // Tepsideki blokları rastgele döndür
    case curseSpreader    // 5 boş hücreye lanet yayar
    case timeHeist        // 20sn çalar
    case heavyArmor       // Gride 4 ağır hücre yerleştirir (2 vuruş gerekir)
    
    // MARK: - Metadata
    
    var name: String {
        switch self {
        case .gridSabotage:   return "SABOTAJ"
        case .lastBlockErase: return "SİL & KAÇIR"
        case .trayLockdown:   return "KİLİTLEME"
        case .scramble:       return "KARISTIRMA"
        case .curseSpreader:  return "LANET YAYICISI"
        case .timeHeist:      return "ZAMAN HIRSIZI"
        case .heavyArmor:     return "AĞIR ZIRH"
        }
    }
    
    var description: String {
        switch self {
        case .gridSabotage:   return "Grid'den rastgele 5 blok siler!"
        case .lastBlockErase: return "Son yerleştirilen bloğu yokeder!"
        case .trayLockdown:   return "Tepsiyi 12sn kilitler!"
        case .scramble:       return "Tüm blokları karıştırır!"
        case .curseSpreader:  return "5 hücreye lanet yayar (-5sn/temas)"
        case .timeHeist:      return "Süreden 20sn çalar!"
        case .heavyArmor:     return "4 adet ağır engel yerleştirir!"
        }
    }
    
    var icon: String {
        switch self {
        case .gridSabotage:   return "💥"
        case .lastBlockErase: return "🗑️"
        case .trayLockdown:   return "🔒"
        case .scramble:       return "🌀"
        case .curseSpreader:  return "☠️"
        case .timeHeist:      return "⏳"
        case .heavyArmor:     return "🛡️"
        }
    }
    
    var warningColor: Color {
        switch self {
        case .gridSabotage:   return ThemeColors.neonPink
        case .lastBlockErase: return ThemeColors.neonOrange
        case .trayLockdown:   return ThemeColors.electricYellow
        case .scramble:       return ThemeColors.neonPurple
        case .curseSpreader:  return Color(red: 0.6, green: 0.1, blue: 0.8)
        case .timeHeist:      return ThemeColors.neonCyan
        case .heavyArmor:     return ThemeColors.neonOrange
        }
    }
    
    // Her kaç saniyede bir atak yapar (round bazlı)
    static func attackInterval(forRound round: Int) -> Double {
        // Round 1 = 40sn, Round 10 = 25sn, minimum 20sn
        return max(20.0, 40.0 - Double(round - 1) * 1.5)
    }

    // Boss archetype / phase ile interval ayarı
    static func attackInterval(forRound round: Int, archetype: BossArchetype?, phase: Int) -> Double {
        let base = attackInterval(forRound: round)
        let p = max(1, min(3, phase))
        var adjusted = base
        // Phase ilerledikçe daha sık
        if p == 2 { adjusted = max(16.0, base - 4.0) }
        if p == 3 { adjusted = max(14.0, base - 7.0) }
        // Archetype bazıları daha agresif
        switch archetype {
        case .breaker:
            adjusted = max(14.0, adjusted - 2.0)
        case .timerHunter:
            adjusted = max(14.0, adjusted - 1.0)
        case .heavyKing:
            adjusted = max(15.0, adjusted - 0.5)
        case .phantom:
            adjusted = max(14.0, adjusted - 1.5)
        case .none:
            break
        }
        return adjusted
    }
    
    // Round'a göre ağırlıklı rastgele seçim (zor roundlarda daha kötü ataklar)
    static func random(forRound round: Int) -> EnemyAttackType {
        if round <= 3 {
            // İlk roundlar — hafif ataklar
            return [.timeHeist, .scramble, .curseSpreader].randomElement()!
        } else if round <= 7 {
            // Orta roundlar — orta ataklar
            return [.gridSabotage, .trayLockdown, .timeHeist, .scramble, .curseSpreader].randomElement()!
        } else {
            // Zor roundlar — her şey olabilir
            return EnemyAttackType.allCases.randomElement()!
        }
    }

    static func random(forRound round: Int, archetype: BossArchetype?, phase: Int) -> EnemyAttackType {
        let p = max(1, min(3, phase))
        let pool: [EnemyAttackType] = {
            switch archetype {
            case .breaker:
                return [.gridSabotage, .lastBlockErase, .scramble, .trayLockdown]
            case .timerHunter:
                return [.timeHeist, .trayLockdown, .curseSpreader, .scramble]
            case .heavyKing:
                return [.heavyArmor, .trayLockdown, .gridSabotage, .curseSpreader]
            case .phantom:
                return [.curseSpreader, .scramble, .lastBlockErase, .timeHeist]
            case .none:
                return EnemyAttackType.allCases
            }
        }()

        // Phase 1: daha hafif subset
        if p == 1 {
            let mild = pool.filter { $0 != .gridSabotage && $0 != .heavyArmor } // biraz daha yumuşak
            return (mild.isEmpty ? pool : mild).randomElement() ?? .scramble
        }
        // Phase 3: ağır ataklar daha olası
        if p == 3 {
            let weighted = pool + pool + pool + [.gridSabotage, .heavyArmor, .trayLockdown]
            return weighted.randomElement() ?? pool.randomElement() ?? .gridSabotage
        }
        return pool.randomElement() ?? EnemyAttackType.random(forRound: round)
    }
}

// MARK: - Aktif Düşman Durumu

struct EnemyState {
    var currentAttack: EnemyAttackType?   // Bu roundaki düşman tipi
    var nextAttackIn: Double = 0           // Kaç saniye sonra atak
    var isWarning: Bool = false            // Uyarı aşamasında mı (son 3sn)
    var isTrayLocked: Bool = false         // Tepsi kilitli mi?
    var trayLockRemainingTime: Double = 0  // Kilit ne kadar kaldı
    var lastErasedPositions: [GridPosition] = [] // Son silinen pozisyonlar (son blok erase için)
}
