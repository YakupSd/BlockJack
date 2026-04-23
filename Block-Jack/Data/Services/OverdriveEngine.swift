//
//  OverdriveEngine.swift
//  Block-Jack
//

import Foundation
import SwiftUI

class OverdriveEngine {

    // MARK: - Tier Hesaplama

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

    // MARK: - Tier Açıklaması (HUD'da gösterilir)

    static func tierDescription(charId: String, tier: OverdriveTier) -> String {
        switch charId {
        case "block_e":
            switch tier {
            case .tier1: return "Satır Temizle (hedefli)"
            case .tier2: return "Satır + Sütun (çapraz)"
            case .tier3: return "3×3 Bomba"
            default: return ""
            }
        case "architect":
            switch tier {
            case .tier1: return "3×3 Alan Yıkımı"
            case .tier2: return "5×5 Alan Yıkımı"
            case .tier3: return "7×7 Mega Yıkım +1500"
            default: return ""
            }
        case "timebender":
            switch tier {
            case .tier1: return "Zamanı 5sn dondur"
            case .tier2: return "8sn dondur + tepsiyi yenile"
            case .tier3: return "3 hamle boyunca timer freeze"
            default: return ""
            }
        case "gambler":
            switch tier {
            case .tier1: return "1 bloğu yenile"
            case .tier2: return "Tüm tepsiyi yenile"
            case .tier3: return "Tepsi yenile + 2000 şans puanı"
            default: return ""
            }
        case "neonwraith":
            switch tier {
            case .tier1: return "+15 sn zaman"
            case .tier2: return "+25 sn + 1 satır temizle"
            case .tier3: return "Sonraki 3 clear +2 çarpan"
            default: return ""
            }
        case "ghost":
            switch tier {
            case .tier1: return "Phantom yerleştirme"
            case .tier2: return "Phantom + sonraki clear +%50"
            case .tier3: return "Phantom + 3×3 overwrite +10sn"
            default: return ""
            }
        case "alchemist":
            switch tier {
            case .tier1: return "Tepsiyi yenile"
            case .tier2: return "Tek-renk tepsi (flush ready)"
            case .tier3: return "3 hamle ×2 puan (Double Count)"
            default: return ""
            }
        case "titan":
            switch tier {
            case .tier1: return "Dev 3×3 plus blok"
            case .tier2: return "2× dev blok +500 overkill"
            case .tier3: return "Earthquake — grid sıfır +2500"
            default: return ""
            }
        default:
            return "Aktif yetenek tetiklenir."
        }
    }

    // MARK: - Execute (direkt tetikleme)

    static func execute(tier: OverdriveTier, charId: String, vm: GameViewModel) {
        guard tier != .none else { return }

        // Questline: her overdrive kullanımını raporla
        UserEnvironment.shared.reportQuestEvent(characterId: charId, event: .overdriveUsed, amount: 1)

        switch charId {
        case "block_e", "architect":
            // Bu karakterler hedef seçim moduna girer, asıl etki executeTargeted'da
            vm.isTargetingOverdrive = true
            vm.addPopup(
                text: "HEDEF SEÇ: \(tierDescription(charId: charId, tier: tier))",
                color: ThemeColors.neonPink
            )

        case "timebender":
            executeTimebender(tier: tier, vm: vm)

        case "gambler":
            executeGambler(tier: tier, vm: vm)

        case "neonwraith":
            executeNeonWraith(tier: tier, vm: vm)

        case "ghost":
            executeGhost(tier: tier, vm: vm)

        case "alchemist":
            executeAlchemist(tier: tier, vm: vm)

        case "titan":
            executeTitan(tier: tier, vm: vm)

        default:
            vm.isOverdriveActive = true
            vm.addPopup(text: "YETENEK KULLANILDI!", color: ThemeColors.electricYellow)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak vm] in
                vm?.isOverdriveActive = false
            }
        }
    }

    // MARK: - Execute Targeted (hedef tıklanınca)

    static func executeTargeted(pos: GridPosition, tier: OverdriveTier, charId: String, vm: GameViewModel) {
        guard pos.row >= 0 && pos.row < BoardViewModel.size,
              pos.col >= 0 && pos.col < BoardViewModel.size else { return }

        switch charId {
        case "block_e":
            executeBlockE(pos: pos, tier: tier, vm: vm)
        case "architect":
            executeArchitect(pos: pos, tier: tier, vm: vm)
        default:
            break
        }
    }

    // MARK: - BLOCK-E (hedefli geometrik temizlik)

    private static func executeBlockE(pos: GridPosition, tier: OverdriveTier, vm: GameViewModel) {
        var positions: [GridPosition] = []
        var rowsCleared = 0
        var colsCleared = 0

        switch tier {
        case .tier1:
            // Satır
            positions = (0..<BoardViewModel.size).map { GridPosition(row: pos.row, col: $0) }
            rowsCleared = 1
        case .tier2:
            // Çapraz (satır + sütun)
            for c in 0..<BoardViewModel.size { positions.append(GridPosition(row: pos.row, col: c)) }
            for r in 0..<BoardViewModel.size { positions.append(GridPosition(row: r, col: pos.col)) }
            rowsCleared = 1
            colsCleared = 1
        case .tier3:
            // 3×3 bomba
            for r in max(0, pos.row-1)...min(BoardViewModel.size-1, pos.row+1) {
                for c in max(0, pos.col-1)...min(BoardViewModel.size-1, pos.col+1) {
                    positions.append(GridPosition(row: r, col: c))
                }
            }
        default: return
        }

        let res = vm.board.removeCells(at: positions)
        vm.handleClear(result: BoardViewModel.ClearResult(
            clearedCells: res.clearedCells,
            clearedPositions: res.clearedPositions,
            rowsCleared: rowsCleared,
            colsCleared: colsCleared,
            zonesCleared: 0
        ))
        vm.clearFlashPositions = res.clearedPositions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            vm.clearFlashPositions = []
        }
        vm.addPopup(text: "BLOCK-E: CLEARED!", color: ThemeColors.neonPink)
    }

    // MARK: - Architect (hedefli alan yıkımı, tier → alan)

    private static func executeArchitect(pos: GridPosition, tier: OverdriveTier, vm: GameViewModel) {
        let radius: Int
        let bonusScore: Int
        switch tier {
        case .tier1: radius = 1; bonusScore = 0    // 3×3
        case .tier2: radius = 2; bonusScore = 0    // 5×5
        case .tier3: radius = 3; bonusScore = 1500 // 7×7 + bonus
        default: return
        }

        var clearedPos: [GridPosition] = []
        for r in max(0, pos.row-radius)...min(BoardViewModel.size-1, pos.row+radius) {
            for c in max(0, pos.col-radius)...min(BoardViewModel.size-1, pos.col+radius) {
                clearedPos.append(GridPosition(row: r, col: c))
            }
        }

        let res = vm.board.removeCells(at: clearedPos)
        vm.clearFlashPositions = clearedPos
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            vm.clearFlashPositions = []
        }
        vm.particleBurst = GameViewModel.ParticleBurstEvent(kind: .overdriveBoom(
            centerRow: pos.row, centerCol: pos.col
        ))

        if !res.clearedCells.isEmpty {
            vm.handleClear(result: BoardViewModel.ClearResult(
                clearedCells: res.clearedCells,
                clearedPositions: res.clearedPositions,
                rowsCleared: 0, colsCleared: 0, zonesCleared: 0
            ))
        }
        if bonusScore > 0 {
            vm.run.addScore(bonusScore)
            vm.addPopup(text: "MEGA YIKIM +\(bonusScore)!", color: ThemeColors.electricYellow)
        } else if res.clearedCells.isEmpty {
            vm.addPopup(text: "HEDEF BOŞ!", color: ThemeColors.textMuted)
        } else {
            vm.addPopup(text: "ARCHITECT ARCHIVES!", color: ThemeColors.neonCyan)
        }
    }

    // MARK: - TimeBender (zaman manipülasyonu)

    private static func executeTimebender(tier: OverdriveTier, vm: GameViewModel) {
        switch tier {
        case .tier1:
            vm.isOverdriveActive = true
            vm.timer.pause()
            vm.addPopup(text: "ZAMAN DONDU 5sn!", color: ThemeColors.neonCyan)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak vm] in
                vm?.timer.resume()
                vm?.isOverdriveActive = false
                vm?.addPopup(text: "TIME FLOWS", color: ThemeColors.neonCyan)
            }
        case .tier2:
            vm.isOverdriveActive = true
            vm.timer.pause()
            vm.refillBlockTray()
            vm.addPopup(text: "ZAMAN DONDU 8sn + TEPSİ YENİLENDİ", color: ThemeColors.neonCyan)
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { [weak vm] in
                vm?.timer.resume()
                vm?.isOverdriveActive = false
                vm?.addPopup(text: "TIME FLOWS", color: ThemeColors.neonCyan)
            }
        case .tier3:
            // 3 hamle boyunca timer donuk — her başarılı yerleştirme sayacı azaltır
            vm.timer.pause()
            vm.timebenderFreezeMoves = 3
            vm.addPopup(text: "TIME FREEZE — 3 HAMLE!", color: ThemeColors.neonCyan)
        default: break
        }
        UserEnvironment.shared.bumpAchievement("timebender_chrono", by: 1)
    }

    // MARK: - Gambler (tepsi yenileme + şans puanı)

    private static func executeGambler(tier: OverdriveTier, vm: GameViewModel) {
        switch tier {
        case .tier1:
            // 1 rastgele tray bloğu yeniden roll
            guard !vm.blockTray.isEmpty else { return }
            let randomIdx = Int.random(in: 0..<vm.blockTray.count)
            vm.blockTray[randomIdx] = GameBlock.random(forRound: vm.run.currentRound)
            vm.addPopup(text: "REROLL! 1 BLOK YENİLENDİ", color: ThemeColors.electricYellow)
        case .tier2:
            vm.refillBlockTray()
            vm.addPopup(text: "TEPSİ YENİLENDİ!", color: ThemeColors.electricYellow)
        case .tier3:
            vm.refillBlockTray()
            vm.run.addScore(2000)
            vm.addPopup(text: "JACKPOT! +2000 puan + TEPSİ YENİ!", color: ThemeColors.electricYellow)
        default: break
        }
    }

    // MARK: - Neon Wraith (zaman + agresif boost)

    private static func executeNeonWraith(tier: OverdriveTier, vm: GameViewModel) {
        switch tier {
        case .tier1:
            vm.timer.addTime(15.0)
            vm.addPopup(text: "WRAITH SPRINT +15s!", color: ThemeColors.neonPurple)
        case .tier2:
            vm.timer.addTime(25.0)
            // En çok dolu satırı bul ve temizle
            let rowCounts: [(row: Int, count: Int)] = (0..<BoardViewModel.size).map { r in
                let occupied = (0..<BoardViewModel.size).filter { vm.board.grid[r][$0].isOccupied }.count
                return (row: r, count: occupied)
            }
            if let best = rowCounts.max(by: { $0.count < $1.count }), best.count > 0 {
                let positions = (0..<BoardViewModel.size).map { GridPosition(row: best.row, col: $0) }
                let res = vm.board.removeCells(at: positions)
                vm.handleClear(result: BoardViewModel.ClearResult(
                    clearedCells: res.clearedCells,
                    clearedPositions: res.clearedPositions,
                    rowsCleared: 1, colsCleared: 0, zonesCleared: 0
                ))
            }
            vm.addPopup(text: "WRAITH RAMPAGE +25s!", color: ThemeColors.neonPurple)
        case .tier3:
            // Sonraki 3 clear'de +2 mult pasif olarak binecek
            vm.neonWraithActiveBoost = 3
            vm.addPopup(text: "WRAITH FURY — SONRAKİ 3 CLEAR +2×", color: ThemeColors.neonPurple)
        default: break
        }
    }

    // MARK: - Ghost (phantom yerleştirme + varyasyonlar)

    private static func executeGhost(tier: OverdriveTier, vm: GameViewModel) {
        switch tier {
        case .tier1:
            vm.isWraithActive = true
            vm.addPopup(text: "PHANTOM PLACEMENT!", color: ThemeColors.neonPurple)
        case .tier2:
            vm.isWraithActive = true
            vm.ghostPhantomMultBonus = 0.5 // sonraki handleClear'de +%50 bonus (tek atımlık)
            vm.addPopup(text: "PHANTOM + PHANTOM BONUS (+50%)!", color: ThemeColors.neonPurple)
        case .tier3:
            vm.isWraithActive = true
            vm.timer.addTime(10.0)
            vm.ghostPhantomMultBonus = 1.0 // sonraki handleClear'de +%100 bonus
            vm.addPopup(text: "GHOST OVERDRIVE +10s +100%!", color: ThemeColors.neonPurple)
        default: break
        }
    }

    // MARK: - Alchemist (tepsi dönüşümü + double count)

    private static func executeAlchemist(tier: OverdriveTier, vm: GameViewModel) {
        switch tier {
        case .tier1:
            vm.refillBlockTray()
            vm.addPopup(text: "ALCHEMY: TEPSİ YENİLENDİ!", color: ThemeColors.neonCyan)
        case .tier2:
            // Tüm tepsiyi aynı renge boya (flush-ready)
            vm.refillBlockTray()
            let targetColor: BlockDisplayColor = BlockDisplayColor.allCases.randomElement() ?? .blue
            for i in 0..<vm.blockTray.count {
                let old = vm.blockTray[i]
                vm.blockTray[i] = GameBlock(
                    id: old.id,
                    type: old.type,
                    color: targetColor,
                    ability: old.ability,
                    pairedBlockId: old.pairedBlockId,
                    rotationSteps: old.rotationSteps
                )
            }
            vm.addPopup(text: "ALCHEMY: FLUSH TRAY!", color: ThemeColors.neonCyan)
        case .tier3:
            // 3 hamle boyunca skor ×2
            vm.alchemistDoubleCountMoves = 3
            vm.addPopup(text: "DOUBLE COUNT — 3 HAMLE ×2!", color: ThemeColors.neonCyan)
        default: break
        }
    }

    // MARK: - Titan (yıkıcı dev bloklar)

    private static func executeTitan(tier: OverdriveTier, vm: GameViewModel) {
        switch tier {
        case .tier1:
            // 1 adet dev plus bomb
            let giantBlock = GameBlock(type: .plus, color: .yellow, ability: .bomb)
            if vm.blockTray.count < 3 {
                vm.blockTray.append(giantBlock)
            } else {
                vm.blockTray[0] = giantBlock
            }
            vm.addPopup(text: "TITAN: DEV BLOK HAZIR", color: ThemeColors.electricYellow)
        case .tier2:
            // 2 adet dev plus bomb + overkill carryover
            let giantA = GameBlock(type: .plus, color: .yellow, ability: .bomb)
            let giantB = GameBlock(type: .plus, color: .yellow, ability: .bomb)
            if vm.blockTray.count < 2 {
                vm.blockTray.append(giantA)
                vm.blockTray.append(giantB)
            } else {
                vm.blockTray[0] = giantA
                if vm.blockTray.count > 1 { vm.blockTray[1] = giantB }
            }
            vm.run.overkillCarryover += 500
            vm.addPopup(text: "TITAN: ÇİFT DEV BLOK +500 OVERKILL!", color: ThemeColors.electricYellow)
        case .tier3:
            // Earthquake — grid'i tamamen silip +2500 puan
            vm.board.resetGrid()
            vm.run.addScore(2500)
            vm.addPopup(text: "EARTHQUAKE! +2500 puan", color: ThemeColors.electricYellow)
            UserEnvironment.shared.bumpAchievement("titan_earthquake", by: 1)
            UserEnvironment.shared.reportQuestEvent(characterId: "titan", event: .titanEarthquake, amount: 1)
        default: break
        }
    }
}
