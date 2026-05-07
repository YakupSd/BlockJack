//
//  ScoreManager.swift
//  Block-Jack
//
//  Orchestrator Pattern: Scoring pipeline extracted from GameViewModel.
//  Handles: handleClear, timed multiplier, frenzy mode, round completion,
//  gold earnings, perk score side-effects, and clockwork scaling.
//

import Foundation
import SwiftUI
import Combine

final class ScoreManager {

    // MARK: - Back-Reference
    unowned let vm: GameViewModel

    // MARK: - Init
    init(vm: GameViewModel) {
        self.vm = vm
    }

    // MARK: - Handle Clear (Main Scoring Pipeline)

    func handleClear(result: BoardViewModel.ClearResult, blockCellCount: Int = 4, neighbors: Int = 0, cluster: Int = 0) {
        let clearedCells = result.clearedCells
        let clearedRows = result.rowsCleared
        let clearedCols = result.colsCleared

        // Debug counters for pacing
        if result.zonesCleared > 0 { vm.debugZoneBlastsThisRound += result.zonesCleared }
        if (clearedRows + clearedCols) > 0 { vm.debugLineClearsThisRound += (clearedRows + clearedCols) }
        
        vm.comboCount += 1
        vm.run.streak += 1

        // Questline: line progress
        let totalLines = clearedRows + clearedCols
        // 3.8: Trigger Timed Multiplier
        triggerTimedMultiplier(for: result)
        
        // 1. Visual & Haptic Feedback
        let flashPositions = result.clearedPositions
        vm.clearFlashPositions = flashPositions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.vm.clearFlashPositions = []
        }
        
        // Particle burst
        if result.zonesCleared > 0 {
            let zoneCenters: [(Int, Int, Color)] = [
                (1, 1, ThemeColors.electricYellow), (1, 10, ThemeColors.electricYellow),
                (10, 1, ThemeColors.electricYellow), (10, 10, ThemeColors.electricYellow),
                (6, 6, ThemeColors.neonPurple)
            ]
            if let firstPos = flashPositions.first {
                let zc = zoneCenters.min(by: {
                    (abs($0.0 - firstPos.row) + abs($0.1 - firstPos.col)) < (abs($1.0 - firstPos.row) + abs($1.1 - firstPos.col))
                }) ?? zoneCenters[4]
                vm.particleBurst = GameViewModel.ParticleBurstEvent(kind: .zoneBlast(centerRow: zc.0, centerCol: zc.1, radius: 60, color: zc.2))
            }
        } else {
            vm.particleBurst = GameViewModel.ParticleBurstEvent(kind: .lineClear(positions: flashPositions, color: ThemeColors.neonCyan))
        }

        vm.haptic.play(.lineClear)
        AudioManager.shared.playSFX(.lineClear)

        // 2. Additive Multiplier Calculation (Character & Perk Specifics)
        var extraAdditiveMult: Double = vm.jokerMultBonus + vm.run.clockworkBonus
        
        if let charId = vm.activeCharacterId {
            switch charId {
            case "architect":
                if vm.lastPlacedBlockType == .O { extraAdditiveMult += 0.3 }
            case "gambler":
                let triggerChance = vm.userEnv.unlockedUpgradeIDs.contains(MetaUpgrade.luckyDice.rawValue) ? 0.10 : 0.07
                if Double.random(in: 0...1) < triggerChance {
                    extraAdditiveMult += 9.0
                    vm.addPopup(text: "JACKPOT! ×10", color: ThemeColors.electricYellow)
                    vm.haptic.play(.success)
                }
            case "neonwraith":
                if vm.timer.ratio < 0.20 { extraAdditiveMult += 2.5 }
                if vm.neonWraithActiveBoost > 0 {
                    extraAdditiveMult += 2.0
                    vm.neonWraithActiveBoost -= 1
                }
            case "alchemist":
                let colors = clearedCells.compactMap { cell -> BlockDisplayColor? in
                    if case .filled(let c) = cell.state { return c }
                    return nil
                }
                if colors.count >= 3 && Set(colors).count == 1 {
                    extraAdditiveMult += 1.0
                    vm.addPopup(text: "ALCHEMY RESONANCE!", color: ThemeColors.neonPurple)
                    vm.userEnv.reportQuestEvent(characterId: "alchemist", event: .alchemistMonoResonance, amount: 1)
                }
            case "titan":
                let heavyCount = clearedCells.filter { if case .heavy = $0.state { return true } else { return false } }.count
                if heavyCount > 0 { 
                    extraAdditiveMult += Double(heavyCount) * 0.5 
                    vm.userEnv.reportQuestEvent(characterId: "titan", event: .heavyCellsCleared, amount: heavyCount)
                }
            default: break
            }
        }

        // Perk Specifics
        if vm.run.hasPerk("heavy_duty") {
            let heavyCount = clearedCells.filter { if case .heavy = $0.state { return true } else { return false } }.count
            if heavyCount > 0 {
                extraAdditiveMult += Double(heavyCount) * Double(max(1, vm.run.perkTier("heavy_duty")))
            }
        }

        // 3. Final Scoring Pipeline V3
        let combinedLines = result.rowCells + result.colCells
        let combo = result.rowsCleared + result.colsCleared + result.zonesCleared
        
        let scoreResult = ScoreEngine.calculate(
            placementMass: blockCellCount,
            neighbors: neighbors,
            cluster: cluster,
            clearedLines: combinedLines,
            combo: combo,
            streak: vm.run.streak,
            perks: vm.run.activePassivePerks,
            timeRemaining: vm.timer.timeRemaining,
            overkillCarryover: vm.run.overkillCarryover,
            rowsCleared: result.rowsCleared,
            colsCleared: result.colsCleared,
            frenzyMult: vm.isFrenzyActive ? 1.25 : 1.0
        )
        
        // Add extra character/perk bonuses to the context
        var finalScore = Int(Double(scoreResult.baseChips) * (1.0 + scoreResult.additiveMult + extraAdditiveMult) * scoreResult.multiplicativeMult)

        // Alchemist Double Count
        if vm.alchemistDoubleCountMoves > 0 {
            finalScore *= 2
            vm.addPopup(text: "DOUBLE COUNT!", color: ThemeColors.neonCyan)
        }

        // Ghost Phantom Bonus
        if vm.ghostPhantomMultBonus > 0 {
            finalScore = Int(Double(finalScore) * (1.0 + vm.ghostPhantomMultBonus))
            vm.ghostPhantomMultBonus = 0.0
        }

        vm.run.addScore(finalScore)
        vm.updateBossPhaseIfNeeded()
        vm.lastScoreResult = scoreResult

        // Questline: flush
        if scoreResult.isFlush {
            vm.userEnv.reportQuestEvent(characterId: vm.activeCharacterId ?? "block_e", event: .flushScored, amount: 1)
        }
        
        // UI Feedback
        if let label = scoreResult.displayLabel(lang: vm.userEnv.language) {
            vm.addPopup(text: label, color: ThemeColors.electricYellow)
        } else {
            vm.addPopup(text: vm.isFrenzyActive ? "+\(finalScore) 🔥" : "+\(finalScore)", color: vm.isFrenzyActive ? ThemeColors.neonOrange : ThemeColors.neonCyan)
        }
        
        // --- Frenzy Logic ---
        if (result.rowsCleared + result.colsCleared + result.zonesCleared) > 0 {
            activateFrenzy()
        }
        
        // 4. Time Rewards
        var timeBonus: Double = (combo >= 4) ? 15.0 : (combo >= 2 ? 8.0 : 4.0)
        if scoreResult.patterns.contains(.flush) { timeBonus += 5.0 }
        if vm.run.streak >= 5 { timeBonus += 3.0 }
        vm.timer.addTime(timeBonus)
        
        // 5. Gold Earnings & Perk Side Effects
        let gold = ScoreEngine.calculateOverflowGold(score: finalScore, target: vm.run.currentRoundTargetScore / 10)
        if gold > 0 { vm.addRunGold(gold) }

        // Midas Touch
        if scoreResult.isFlush {
            let hasFever = vm.activeSynergies.contains(where: { $0.synergyName == SynergyID.goldenFever })
            if hasFever {
                vm.addRunGold(15)
                vm.addPopup(text: "GOLDEN FEVER +15G", color: ThemeColors.electricYellow)
            } else {
                let midasTier = vm.run.perkTier("midas_touch")
                if midasTier > 0 {
                    let amount = Int(PerkUpgradeRegistry.tierData(for: .midasTouch, tier: midasTier).effectValue)
                    vm.addRunGold(amount)
                    vm.addPopup(text: "MIDAS TOUCH +\(amount)G", color: ThemeColors.electricYellow)
                }
            }
        }

        // Recycler
        if scoreResult.clearedRows + scoreResult.clearedCols >= 2 {
            let hasCycle = vm.activeSynergies.contains(where: { $0.synergyName == SynergyID.eternalCycle })
            let recyclerTier = vm.run.perkTier("recycler")
            let chance = hasCycle ? 0.45 : (recyclerTier > 0 ? PerkUpgradeRegistry.tierData(for: .recycler, tier: recyclerTier).effectValue : 0.0)
            if chance > 0 && Double.random(in: 0...1) < chance {
                vm.refillBlockTray()
                vm.addPopup(text: "RECYCLED!", color: ThemeColors.neonCyan)
            }
        }

        // 6. Audio & Music Pacing
        AudioManager.shared.setIntensity(streak: vm.run.streak, lowTime: vm.timer.timeRemaining < 15)

        // 7. Clockwork Perk Scaling
        if vm.run.hasPerk("clockwork") {
            let tier = vm.run.perkTier("clockwork")
            let baseInc = timeBonus * 0.1
            let scaledInc = baseInc * Double(tier)
            vm.run.clockworkBonus = min(2.5, vm.run.clockworkBonus + scaledInc)
        }

        // 8. Target Milestones
        if !vm.run.halfBonusGiven && vm.run.scoreProgress >= 0.5 {
            vm.run.halfBonusGiven = true
            vm.timer.addTime(10)
            vm.addPopup(text: "+10s BONUS!", color: ThemeColors.electricYellow)
        }

        // 9. Records
        if finalScore > vm.maxRoundScore {
            vm.maxRoundScore = finalScore
        }

        // 10. Round Progression
        checkRoundTarget()
        
        // 11. End-of-Clear Perks (Last Resort & Sustain)
        
        // Double Down: Gaining moves on empty tray
        if vm.run.movesRemaining == 0 && finalScore > 0 && vm.run.hasPerk("double_down") {
            let tier = vm.run.perkTier("double_down")
            let movesGained = 1 + (tier * 2)
            vm.run.movesUsed -= movesGained
            vm.addPopup(text: "DOUBLE DOWN LV.\(tier)! +\(movesGained) MOVES", color: ThemeColors.neonPurple)
            vm.haptic.play(.success)
        }
        
        // Vampiric Core: Healing on high score milestones
        if vm.run.hasPerk("vampiric_core") && finalScore > 0 {
            let tier = vm.run.perkTier("vampiric_core")
            let targetScore = max(1000, 5000 - ((tier - 1) * 500))
            let lastMilestone = (vm.run.currentScore - finalScore) / targetScore
            let currentMilestone = vm.run.currentScore / targetScore
            if currentMilestone > lastMilestone {
                if Double.random(in: 0...1) < 0.25 {
                    vm.timer.addTime(5.0)
                    vm.addPopup(text: "VAMPIRIC LV.\(tier)! +5s ⌛", color: ThemeColors.neonPink)
                    vm.haptic.play(.success)
                }
            }
        }
        
        // Chain Pulse: Cascade effect
        if vm.run.hasPerk("chain_pulse") && !result.clearedPositions.isEmpty {
            let tier = vm.run.perkTier("chain_pulse")
            let chance = 0.15 * Double(max(1, tier))
            if Double.random(in: 0...1) < chance {
                let maxTargets = max(1, tier)
                triggerChainPulse(around: result.clearedPositions, maxTargets: maxTargets)
            }
        }
    }

    // MARK: - Timed Multiplier

    func startMultiplierTimer() {
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.vm.phase == .playing else { return }
                if self.vm.multiplierRemainingTime > 0 {
                    self.vm.multiplierRemainingTime -= 1.0
                    if self.vm.multiplierRemainingTime <= 0 {
                        self.vm.timedMultiplier = 1.0
                    }
                }
            }
            .store(in: &vm.cancellables)
    }
    
    func triggerTimedMultiplier(for result: BoardViewModel.ClearResult) {
        let totalCleared = result.rowsCleared + result.colsCleared + result.zonesCleared
        guard totalCleared > 0 else { return }
        
        if vm.multiplierRemainingTime <= 0 {
            vm.timedMultiplier = 1.25
        } else {
            // Stacking bonus
            vm.timedMultiplier = min(3.0, vm.timedMultiplier + 0.05)
        }
        vm.multiplierRemainingTime = 15.0
        
        // Visual feedback
        vm.addPopup(text: String(format: "MULT ×%.2f", vm.timedMultiplier), color: ThemeColors.electricYellow)
    }

    // MARK: - Frenzy Mode

    func activateFrenzy() {
        if !vm.isFrenzyActive {
            vm.addPopup(text: "FRENZY MODE! 🔥", color: ThemeColors.neonOrange)
            AudioManager.shared.playSFX(.powerUp)
        }
        vm.frenzyTimeRemaining = 15.0
        
        vm.frenzyCancellable?.cancel()
        vm.frenzyCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.vm.frenzyTimeRemaining -= 0.1
                if self.vm.frenzyTimeRemaining <= 0 {
                    self.vm.frenzyTimeRemaining = 0
                    self.vm.frenzyCancellable?.cancel()
                }
            }
    }

    // MARK: - Round Progression

    func checkRoundTarget() {
        if vm.run.currentScore >= vm.run.currentRoundTargetScore {
            completeRound()
        }
    }

    func checkMoveLimit() {
        // Hamle limiti artık çok yüksek (300)
        if vm.run.movesUsed >= vm.run.round.moveLimit {
            if vm.run.currentScore >= vm.run.currentRoundTargetScore {
                completeRound()
            } else {
                vm.triggerGameOver()
            }
        }
    }

    func completeRound() {
        vm.timer.pause()
        vm.stopEnemyLoop() // Düşman atak timer'larını durdur
        let result = vm.lastScoreResult ?? ScoreResult(
            baseChips: 0, additiveMult: 0.0, multiplicativeMult: 1.0, totalScore: 0,
            patterns: [], comboCount: 0, streak: 0, clearedRows: 0, clearedCols: 0
        )
        // Echoes Scaling: Repeated score scales with tier
        if vm.run.hasPerk("echoes") && vm.maxRoundScore > 0 {
            let tier = vm.run.perkTier("echoes")
            let scale = 1.0 + (Double(tier - 1) * 0.5)
            let bonus = Int(Double(vm.maxRoundScore) * scale)
            vm.run.addScore(bonus)
            vm.addPopup(text: "ECHOES LV.\(tier) +\(bonus)", color: ThemeColors.neonPurple)
        }
        
        // Overkill Scaling: Percent carryover increases with tier
        if vm.run.hasPerk("overkill") {
            let tier = vm.run.perkTier("overkill")
            let percentage = PerkUpgradeRegistry.tierData(for: .overkill, tier: tier).effectValue
            let rawOverflow = max(0, vm.run.currentScore - vm.run.currentRoundTargetScore)
            let overflow = Int(Double(rawOverflow) * percentage)
            
            vm.run.overkillCarryover = overflow
            vm.addPopup(text: "OVERKILL LV.\(tier) +\(overflow) NEXT", color: ThemeColors.neonPink)
            
            // SYNERGY: ENDLESS RESERVES (Overkill + Echoes)
            if vm.activeSynergies.contains(where: { $0.synergyName == SynergyID.endlessReserves }) {
                let timeBonus = Double(overflow) / 50.0 // Her 50 puan için 1sn
                vm.timer.addTime(timeBonus)
                if timeBonus > 1 {
                    vm.addPopup(text: "RESERVES: +\(Int(timeBonus))s", color: ThemeColors.neonPurple)
                }
            }
        }
        
        // 3. Altın Hesabı & Commit Pending
        let hasGoldEye = vm.userEnv.unlockedUpgradeIDs.contains(MetaUpgrade.goldEye.rawValue)
        let goldFromClear = ScoreEngine.goldEarned(for: result, hasGoldEye: hasGoldEye)
        
        // Finalize all gold earned this round
        let totalRoundGold = vm.pendingGold + goldFromClear
        vm.run.gold += totalRoundGold
        vm.pendingGold = 0
        
        if totalRoundGold > 0 {
            AudioManager.shared.playSFX(.coin)
            vm.addPopup(text: "+\(totalRoundGold) GOLD", color: ThemeColors.electricYellow)
        }
        UserEnvironment.shared.updateHighScore(vm.run.currentScore)
        // Phase 8: başarı ilerlemesi — round kazanç, skor, lines, gold.
        UserEnvironment.shared.bumpAchievement("first_victory", by: 1)
        UserEnvironment.shared.reportAchievement("score_10k", progress: vm.run.currentScore)
        UserEnvironment.shared.reportAchievement("lines_100", progress: UserEnvironment.shared.totalLinesCleared)
        UserEnvironment.shared.reportAchievement("gold_hoarder_5k", progress: UserEnvironment.shared.totalGoldEarned)
        UserEnvironment.shared.reportAchievement("perk_collector_5", progress: UserEnvironment.shared.discoveredPerkIDs.count)

        // Boss discovery (anında): boss node kazanıldığı anda kolleksiyonda açılsın.
        if vm.currentNodeType == .boss {
            UserEnvironment.shared.discoverBoss(vm.currentBoss.id)
            UserEnvironment.shared.reportAchievement(
                "boss_slayer_3",
                progress: UserEnvironment.shared.totalBossesDefeated
            )
            UserEnvironment.shared.reportAchievement(
                "world_explorer_2",
                progress: UserEnvironment.shared.unlockedWorldLevel
            )
        }

        
        // Boss round kazanma
        if vm.currentNodeType == .boss {
            vm.showBigComboLabel = "BOSS DEFEATED!" // Üstte büyük yazı çıksın
            vm.haptic.play(.heavy)
            vm.addPopup(text: "CHAPTER COMPLETE!", color: ThemeColors.neonPink)
            
            // Wait to clear the big label
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.vm.showBigComboLabel = nil
            }
        }
        
        // Round zaferi: müzik yumuşasın, kazanım SFX'i çalsın.
        AudioManager.shared.playSFX(.roundWin)
        
        // ÖNEMLİ: Sonraki round'a geçişi burada yap, skor/round sıfırlansın.
        vm.run.nextRound()
        
        vm.phase = .roundComplete

        // Skor/round'u diske persist et — Slot seçim ekranı ve Hub'ın "Round X
        // · N pts" göstergeleri anında güncellensin. Eskiden sadece oyun çıkışı
        // / pause save / game-over'da yazılıyordu, bu yüzden slot listesi
        // çoğu zaman "Round 1 · 0 pts" ile bayat kalıyordu.
        SaveManager.shared.updateSave(
            slotId: vm.activeSlotId,
            score: vm.run.currentScore,
            round: vm.run.currentRound
        )

#if DEBUG
        print("[PACING] ROUND COMPLETE R\(vm.run.currentRound) WL\(vm.run.worldLevel) " +
              "moves=\(vm.run.movesUsed) score=\(vm.run.currentScore)/\(vm.run.currentRoundTargetScore) " +
              "zoneBlasts=\(vm.debugZoneBlastsThisRound) lineClears=\(vm.debugLineClearsThisRound)")
#endif
    }

    // MARK: - Chain Pulse

    /// Chain Pulse perk etkisi: clearedPositions'ın komşularından dolu olanları
    /// topla, rastgele `maxTargets` kadarını "elektriklenip" temizle. Statik
    /// charge synerjisi için görünür bir feedback sağlanır.
    func triggerChainPulse(around cleared: [GridPosition], maxTargets: Int) {
        let deltas: [(Int, Int)] = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        let clearedSet = Set(cleared)
        var candidates: Set<GridPosition> = []
        for pos in cleared {
            for (dr, dc) in deltas {
                let nr = pos.row + dr
                let nc = pos.col + dc
                guard nr >= 0, nr < BoardViewModel.size, nc >= 0, nc < BoardViewModel.size else { continue }
                let np = GridPosition(row: nr, col: nc)
                if clearedSet.contains(np) { continue }
                if vm.board.grid[nr][nc].isOccupied {
                    candidates.insert(np)
                }
            }
        }
        guard !candidates.isEmpty else { return }
        let targets = Array(candidates.shuffled().prefix(maxTargets))
        vm.board.removeCells(at: targets)
        vm.clearFlashPositions = targets
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.vm.clearFlashPositions = []
        }
        vm.addPopup(text: "CHAIN PULSE! \(targets.count)×", color: ThemeColors.neonCyan)
        vm.haptic.play(.success)
    }

    /// STATIC SHOCK sinerjisi: static_charge hücresi tetiklendiği satırdaki
    /// tüm dolu hücreleri elektrikle temizler. Her temizlenen hücre için küçük
    /// bir skor bonusu verilir; komşu satırlar zincirleme tetiklenmez.
    func triggerStaticShock(row: Int) {
        guard row >= 0, row < BoardViewModel.size else { return }
        var targets: [GridPosition] = []
        for c in 0..<BoardViewModel.size where vm.board.grid[row][c].isOccupied {
            targets.append(GridPosition(row: row, col: c))
        }
        guard !targets.isEmpty else { return }
        vm.board.removeCells(at: targets)
        vm.clearFlashPositions = targets
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.vm.clearFlashPositions = []
        }
        let bonus = targets.count * 75
        vm.run.addScore(bonus)
        vm.addPopup(text: "STATIC SHOCK! +\(bonus)", color: ThemeColors.electricYellow)
        vm.haptic.play(.flush)
        AudioManager.shared.playSFX(.flush)
    }
}
