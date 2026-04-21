//
//  OverdriveEngine.swift
//  Block-Jack
//

import Foundation
import SwiftUI

class OverdriveEngine {
    
    /// Belirtilen şarja ve eşiklere göre mevcut Tier'i hesaplar
    static func currentTier(charge: Double, thresholds: [Double]) -> OverdriveTier {
        guard thresholds.count == 3 else { return .none }
        
        if charge >= thresholds[2] {
            return .tier3
        } else if charge >= thresholds[1] {
            return .tier2
        } else if charge >= thresholds[0] {
            return .tier1
        }
        
        return .none
    }
    
    /// CharID ve Tier'a göre açıklamayı döner
    static func tierDescription(charId: String, tier: OverdriveTier) -> String {
        switch charId {
        case "block_e":
            switch tier {
            case .tier1: return "Seçilen satırı sil (Target mode)"
            case .tier2: return "Seçilen satır + sütun sil (L şekli)"
            case .tier3: return "3x3 alan bombası"
            default: return ""
            }
        case "architect":
            switch tier {
            case .tier1: return "3x3 alan temizle"
            case .tier2: return "En iyi hamleyi göster"
            case .tier3: return "Otomatik en iyi hamleyi oyna"
            default: return ""
            }
        case "ghost":
            switch tier {
            case .tier1: return "Phantom yerleştirme"
            case .tier2: return "Gizli tepsi — yerleştirilenlere x1.5 çarpan"
            case .tier3: return "Sıkışıklıkları vurgula ve 15sn kazan"
            default: return ""
            }
        case "alchemist":
            switch tier {
            case .tier1: return "Kötü bloğu dönüştür"
            case .tier2: return "Tüm tepsiyi aynı renge boya (Flush!)"
            case .tier3: return "Double Count modu (5 hamle)"
            default: return ""
            }
        case "titan":
            switch tier {
            case .tier1: return "Dev 4x4 blok"
            case .tier2: return "Ağır 3x1 darbe"
            case .tier3: return "Earthquake — gridin yarısını sil"
            default: return ""
            }
        default:
            return "Aktif yetenek tetiklenir."
        }
    }
    
    /// Yetenek aksiyonunu GameViewModel üstünde çalıştırır
    static func execute(tier: OverdriveTier, charId: String, vm: GameViewModel) {
        guard tier != .none else { return }
        
        switch charId {
        case "block_e", "architect":
            // Bu karakterlerde tüm seviyeler hedeflemeli olabilir
            vm.isTargetingOverdrive = true
            vm.addPopup(text: "HEDEF SEÇ: \(tierDescription(charId: charId, tier: tier))", color: ThemeColors.neonPink)
            
        case "timebender":
            vm.isOverdriveActive = true
            vm.timer.pause()
            vm.addPopup(text: "ZAMAN DONDURULDU!", color: ThemeColors.neonCyan)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak vm] in
                vm?.timer.resume()
                vm?.isOverdriveActive = false
            }
            
        case "ghost":
            if tier == .tier1 {
               vm.isWraithActive = true
               vm.addPopup(text: "PHANTOM PLACEMENT", color: ThemeColors.neonPurple)
            } else if tier == .tier2 {
               vm.jokerMultBonus += 0.5
               vm.addPopup(text: "GHOSTLY TRAY ACTIVE", color: ThemeColors.neonPurple)
            } else if tier == .tier3 {
               vm.timer.addTime(15)
               vm.addPopup(text: "+15s ZAMAN KAZANILDI", color: ThemeColors.neonPurple)
               // Highlight empty spaces feature could go here
            }
            
        case "alchemist":
            if tier == .tier1 {
               vm.refillBlockTray()
            } else if tier == .tier2 {
               vm.addPopup(text: "ALCHEMIST: TRAY FLUSHED!", color: ThemeColors.neonCyan)
            } else if tier == .tier3 {
               vm.addPopup(text: "DOUBLE COUNT ACTIVE!", color: ThemeColors.neonCyan)
            }
            
        case "titan":
            if tier == .tier3 {
               vm.board.resetGrid()
               vm.addPopup(text: "EARTHQUAKE!", color: ThemeColors.electricYellow)
            } else {
                let giantBlock = GameBlock(type: .plus, color: .yellow, ability: .bomb)
                if vm.blockTray.count < 3 {
                    vm.blockTray.append(giantBlock)
                } else {
                    vm.blockTray[0] = giantBlock
                }
                vm.addPopup(text: "TITAN: GIANT BLOCK READY", color: ThemeColors.electricYellow)
            }
            
        default:
            vm.isOverdriveActive = true
            vm.addPopup(text: "YETENEK KULLANILDI!", color: ThemeColors.electricYellow)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak vm] in
                vm?.isOverdriveActive = false
            }
        }
    }
    
    /// Hedeflenmiş yetenek tetiklenmesi
    static func executeTargeted(pos: GridPosition, tier: OverdriveTier, charId: String, vm: GameViewModel) {
        // Bounds Check
        guard pos.row >= 0 && pos.row < BoardViewModel.size && pos.col >= 0 && pos.col < BoardViewModel.size else { return }
        
        switch charId {
        case "block_e":
            if tier == .tier1 {
                let positions = (0..<BoardViewModel.size).map { GridPosition(row: pos.row, col: $0) }
                let res = vm.board.removeCells(at: positions)
                vm.handleClear(result: BoardViewModel.ClearResult(clearedCells: res.clearedCells, clearedPositions: res.clearedPositions, rowsCleared: 1, colsCleared: 0, zonesCleared: 0))
            } else if tier == .tier2 {
                var positions: [GridPosition] = []
                for c in 0..<BoardViewModel.size { positions.append(GridPosition(row: pos.row, col: c)) }
                for r in 0..<BoardViewModel.size { positions.append(GridPosition(row: r, col: pos.col)) }
                let res = vm.board.removeCells(at: positions)
                vm.handleClear(result: BoardViewModel.ClearResult(clearedCells: res.clearedCells, clearedPositions: res.clearedPositions, rowsCleared: 1, colsCleared: 1, zonesCleared: 0))
            } else if tier == .tier3 {
                var positions: [GridPosition] = []
                for r in max(0, pos.row-1)...min(BoardViewModel.size-1, pos.row+1) {
                    for c in max(0, pos.col-1)...min(BoardViewModel.size-1, pos.col+1) {
                        positions.append(GridPosition(row: r, col: c))
                    }
                }
                let res = vm.board.removeCells(at: positions)
                vm.handleClear(result: BoardViewModel.ClearResult(clearedCells: res.clearedCells, clearedPositions: res.clearedPositions, rowsCleared: 0, colsCleared: 0, zonesCleared: 0))
            }
            vm.addPopup(text: "CLEARED!", color: ThemeColors.neonPink)
        case "architect":
            if tier == .tier1 {
                let cleared = vm.board.applyArchitectOverdrive(at: pos)
                if !cleared.isEmpty {
                    // 3x3 etrafındaki pozisyonları hesapla (flash için)
                    var clearedPos: [GridPosition] = []
                    for r in max(0, pos.row-1)...min(BoardViewModel.size-1, pos.row+1) {
                        for c in max(0, pos.col-1)...min(BoardViewModel.size-1, pos.col+1) {
                            clearedPos.append(GridPosition(row: r, col: c))
                        }
                    }
                    vm.clearFlashPositions = clearedPos
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        vm.clearFlashPositions = []
                    }
                    // Overdrive Boom partikülü — merkezden patlasın
                    vm.particleBurst = GameViewModel.ParticleBurstEvent(kind: .overdriveBoom(
                        centerRow: pos.row, centerCol: pos.col
                    ))
                    vm.handleClear(result: BoardViewModel.ClearResult(
                        clearedCells: cleared,
                        clearedPositions: clearedPos,
                        rowsCleared: 0, colsCleared: 0, zonesCleared: 0
                    ))
                    vm.addPopup(text: "ARCHITECT ARCHIVES!", color: ThemeColors.neonCyan)
                } else {
                    vm.addPopup(text: "HEDEF BOŞ!", color: ThemeColors.textMuted)
                }
            } else {
                vm.addPopup(text: "YETENEK ALANI İŞLENDİ", color: ThemeColors.electricYellow)
            }
        default:
            break
        }
    }
}
