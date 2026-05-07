//
//  BoardController.swift
//  Block-Jack
//
//  Orchestrator Pattern: Board interaction logic extracted from GameViewModel.
//  Handles: Block placement (tryPlace), drag lifecycle, tray management,
//  deadlock detection, enemy attack system, and grid modifier processing.
//

import Foundation
import SwiftUI
import Combine

final class BoardController {

    // MARK: - Back-Reference
    unowned let vm: GameViewModel

    // MARK: - Init
    init(vm: GameViewModel) {
        self.vm = vm
    }

    // MARK: - Block Placement

    func tryPlace(block: GameBlock, at position: GridPosition) {
        guard vm.phase == .playing else { return }

        // Neon Wraith check: if active, canPlace is always true for overlaps, but handle logic
        var clearedByWraith: [GameCell] = []
        if vm.isWraithActive {
            // Skill usage: Place anyway and clear what was there
            var overwrittenCount = 0
            for (dr, dc) in block.cells {
                let r = position.row + dr
                let c = position.col + dc
                if r >= 0 && r < BoardViewModel.size && c >= 0 && c < BoardViewModel.size {
                    if vm.board.grid[r][c].isOccupied { overwrittenCount += 1 }
                    clearedByWraith.append(vm.board.grid[r][c])
                    vm.board.grid[r][c].state = .empty
                }
            }
            vm.isWraithActive = false
            vm.addPopup(text: "GHOST OVERWRITE!", color: ThemeColors.neonPurple)
            if vm.activeCharacterId == "ghost", overwrittenCount > 0 {
                vm.userEnv.bumpAchievement("ghost_phantom", by: overwrittenCount)
                vm.userEnv.reportQuestEvent(characterId: "ghost", event: .phantomOverwriteCells, amount: overwrittenCount)
            }
        }

        vm.lastPlacedBlockType = block.type
        
        // Tray kilitliyse yerleştirme
        if vm.enemy.isTrayLocked {
            vm.haptic.play(.error)
            vm.addPopup(text: "🔒 TEPSİ KİTLİ!", color: ThemeColors.electricYellow)
            return
        }
        
        let clearResult = vm.board.placeBlock(block, at: position)
        let placementSuccess = clearResult != nil
        
        if placementSuccess, let result = clearResult {
            // Son yerleştirilen pozisyonları kaydet (düşman erase atağı için)
            vm.lastPlacedPositions = block.cells.compactMap { (dr, dc) -> GridPosition? in
                let r = position.row + dr
                let c = position.col + dc
                guard r >= 0, r < BoardViewModel.size, c >= 0, c < BoardViewModel.size else { return nil }
                return GridPosition(row: r, col: c)
            }
            // AAA: Manage Boss Intent cooldown
            if vm.run.round.isBossRound {
                vm.bossIntentCooldown -= 1
                if vm.bossIntentCooldown <= 0 {
                    vm.bossIntent = nil
                }
                
                // Show new intent every 4 moves
                if vm.bossIntentCooldown <= -1 {
                    vm.bossIntent = vm.currentBoss.getRandomIntent()
                    vm.bossIntentCooldown = 3
                }
            } else {
                vm.bossIntent = nil
            }

            // placeBlock'tan gelen clear result'ı kullanıyoruz (artık tekrar clearFullLinesAndZones çağırmaya gerek yok)
            // Yerleştirme başarılı
            vm.haptic.play(.blockPlace)
            vm.run.movesUsed += 1

            // Time Bender active (T3): timer freeze'i kalan hamle sayısı kadar sürer
            if vm.timebenderFreezeMoves > 0 {
                vm.timebenderFreezeMoves -= 1
                if vm.timebenderFreezeMoves == 0 {
                    vm.timer.resume()
                    vm.addPopup(text: "TIME UNFROZEN", color: ThemeColors.neonCyan)
                }
            }

            // Alchemist active (T3): double count hamle sayısını azalt
            if vm.alchemistDoubleCountMoves > 0 {
                vm.alchemistDoubleCountMoves -= 1
            }
            
            // Phase 5.1: Process Modifiers BEFORE checking clears
            for (dr, dc) in block.cells {
                let r = position.row + dr
                let c = position.col + dc
                if r >= 0 && r < BoardViewModel.size && c >= 0 && c < BoardViewModel.size {
                    if let mod = vm.board.grid[r][c].modifier {
                        switch mod {
                        case .bonus(let type):
                            switch type {
                            case .gold(let amount):
                                vm.addRunGold(amount)
                                AudioManager.shared.playSFX(.coin)
                                vm.addPopup(text: "+\(amount) ALTIN", color: ThemeColors.electricYellow)
                            case .star:
                                vm.run.addScore(500)
                                vm.addPopup(text: "YILDIZ! +500", color: ThemeColors.electricYellow)
                            case .timeBoost(let secs):
                                vm.timer.addTime(secs)
                                vm.addPopup(text: "+\(Int(secs))s", color: ThemeColors.neonCyan)
                            }
                        case .cursed:
                            vm.timer.addTime(-5) // -5 seconds
                            vm.comboCount += 1 // Combo charge
                            vm.addPopup(text: "LANET! -5s", color: ThemeColors.neonPink)
                            vm.haptic.play(.error)
                        case .staticCharge:
                            // Static Charge perki aktifken round başında yerleştirilen
                            // hücreler bunlar. Üzerine blok koyunca overdrive'a yoğun
                            // şarj transferi olur (tier başına +0.5, max 1.5).
                            let tier = vm.run.perkTier("static_charge")
                            let boost = min(1.5, 0.5 * Double(max(1, tier)))
                            let previousTier = vm.currentOverdriveTier
                            vm.overdriveCharge = min(3.0, vm.overdriveCharge + boost)
                            vm.abilityManager.updateOverdriveTier(previous: previousTier)
                            vm.addPopup(text: "STATIC CHARGE! +\(Int(boost * 100))%", color: ThemeColors.electricYellow)
                            vm.haptic.play(.success)

                            // STATIC SHOCK sinerjisi (static_charge + chain_pulse):
                            // Static hücre tetiklendiğinde satır elektrikle patlar.
                            // Grid mutasyonu güvenli olsun diye bir sonraki runloop'a atıyoruz.
                            if vm.activeSynergies.contains(where: { $0.synergyName == SynergyID.staticShock }) {
                                let targetRow = r
                                DispatchQueue.main.async { [weak self] in
                                    self?.vm.scoreManager.triggerStaticShock(row: targetRow)
                                }
                            }
                        default:
                            break // Locked is handled in canPlace
                        }
                        // Modifier'ı consume et (sil)
                        vm.board.grid[r][c].modifier = nil
                    }
                }
            }
            
            // Minor charge per block (Faster charge)
            if vm.overdriveCharge < 3.0 {
                let previousTier = vm.currentOverdriveTier
                // Gold Upgrade: Overdrive Fill (+%10/level)
                let overdriveFillLevel = vm.userEnv.goldLevel(for: .overdriveFill)
                let mult = 1.0 + (0.10 * Double(max(0, overdriveFillLevel)))
                vm.overdriveCharge = min(3.0, vm.overdriveCharge + (0.15 * mult))
                vm.abilityManager.updateOverdriveTier(previous: previousTier)
            }
            
            // Phantom Siphon (hayalet perk bağlantısı): Phantom modifier'lı round'da
            // her başarılı yerleştirmede süreye tier × 2 saniye ekler. Phantom
            // bosslarındaki görünmezliği avantaja çevirir.
            if vm.run.hasPerk("phantom_siphon") && vm.run.activeModifier == .phantom {
                let tier = vm.run.perkTier("phantom_siphon")
                let bonusSeconds = Double(2 * max(1, tier))
                vm.timer.addTime(bonusSeconds)
                vm.addPopup(text: "PHANTOM SIPHON +\(Int(bonusSeconds))s", color: ThemeColors.neonPurple)
            }

            let neighbors = vm.board.calculateNeighbors(for: block, at: position)
            let cluster = vm.board.calculateColorCluster(for: block, at: position)

            let cleared = result.clearedCells
            if cleared.isEmpty {
                // Temizleme olmadı → Yine de yerleştirme puanı ver (V3)
                let scoreResult = ScoreEngine.calculate(
                    placementMass: block.cells.count,
                    neighbors: neighbors,
                    cluster: cluster,
                    clearedLines: [],
                    combo: 0,
                    streak: vm.run.streak,
                    perks: vm.run.activePassivePerks,
                    timeRemaining: vm.timer.timeRemaining,
                    overkillCarryover: vm.run.overkillCarryover,
                    rowsCleared: 0,
                    colsCleared: 0
                )
                
                vm.run.addScore(scoreResult.totalScore)
                if scoreResult.totalScore > 0 {
                    vm.addPopup(text: "+\(scoreResult.totalScore)", color: .white)
                }

                // Temizleme olmadı → streak sıfırla (TimeBender pasifi yumuşatır)
                if vm.run.streak > 0 {
                    let baseDecay: Int = (vm.activeCharacterId == "timebender") ? 2 : vm.run.streak
                    let comboTimeLevel = vm.userEnv.goldLevel(for: .comboTime)
                    let slowPct = min(0.50, 0.10 * Double(max(0, comboTimeLevel)))
                    let adjustedDecay = max(1, Int(round(Double(baseDecay) * (1.0 - slowPct))))
                    vm.run.streak = max(0, vm.run.streak - adjustedDecay)

                    if vm.activeCharacterId == "timebender", vm.run.streak > 0 {
                        vm.addPopup(text: "TIME BEND: STREAK \(vm.run.streak)", color: ThemeColors.neonCyan)
                    } else if comboTimeLevel > 0, vm.run.streak > 0 {
                        vm.addPopup(text: "COMBO TIME: STREAK \(vm.run.streak)", color: ThemeColors.neonPurple)
                    }
                }
                vm.comboCount = 0
                
                if vm.run.hasPerk("momentum") {
                    vm.run.tensionCount += 1
                }
            } else {
                // Track global stats
                UserEnvironment.shared.addLinesCleared(cleared.count)
                
                // Satır/sütun/alan temizlendi
                vm.scoreManager.handleClear(result: result, blockCellCount: block.cells.count, neighbors: neighbors, cluster: cluster)
            }

            // Phase 5.2: Gravity Mode (Boss Round'lar için aktif olsun - Elite eklenecek)
            if vm.run.round.isBossRound {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        self?.vm.board.applyGravity()
                    }
                }
            }

            // Tray'den bloğu kaldır
            vm.blockTray.removeAll { $0.id == block.id }
            
            // Phase 6.2: Chain Block removal
            if block.type == .chain, let pairedId = block.pairedBlockId {
                vm.blockTray.removeAll { $0.id == pairedId }
            }
            
            if vm.blockTray.isEmpty { refillBlockTray() }

            // Hamle sınırı kontrolü
            vm.scoreManager.checkMoveLimit()

            // Deadlock kontrolü
            if vm.board.isDeadlock(blocks: vm.blockTray) { vm.triggerGameOver() }

        } else {
            // Yerleştirme başarısız
            vm.haptic.play(.blockFail)
        }
    }

    // MARK: - Drag Handling
    
    func updateDrag(location: CGPoint, gridPosition: GridPosition?) {
        guard vm.isDragging, let block = vm.draggingBlock else { return }
        vm.dragLocation = location
        
        // Throttle: ghost + hint güncellemesini saniyede max ~30 kez yap
        let now = Date()
        guard now.timeIntervalSince(vm.lastGhostUpdate) >= vm.ghostThrottleInterval else { return }
        vm.lastGhostUpdate = now
        
        if let pos = gridPosition {
            vm.board.updateGhost(block, at: pos)
            vm.board.detectPotentialClears(block: block, at: pos)
        } else {
            vm.board.clearGhost()
            vm.board.hintPositions = []
            vm.board.hintZonePositions = []
        }
        // Check for deadlock after placing a block and potentially refilling
        checkDeadlock()
    }
    
    func handleDragEnd() {
        guard vm.isDragging, let block = vm.draggingBlock else {
            resetDrag()
            return
        }
        
        // BlockTrayView'dan tetiklenir, lokasyonu GameView'dan gelen converter ile çözer
        if let pos = vm.gridSpaceConverter?(vm.dragLocation) {
            tryPlace(block: block, at: pos)
        }
        
        resetDrag()
    }
    
    func handleOverdriveDrop() {
        guard vm.isTargetingOverdrive else { return }
        if let pos = vm.gridSpaceConverter?(vm.dragLocation) {
            vm.abilityManager.applyTargetedOverdrive(at: pos)
        } else {
            vm.abilityManager.cancelTargetedOverdrive()
        }
    }

    func resetDrag() {
        vm.isDragging = false
        vm.draggingBlock = nil
        vm.dragLocation = .zero
        vm.board.clearGhost()
        vm.board.hintPositions = []
        vm.board.hintZonePositions = []
    }

    // MARK: - Block Tray

    func refillBlockTray() {
        var newBlocks: [GameBlock] = []
        let blockLuckLevel = vm.userEnv.goldLevel(for: .blockLuck)
        for _ in 0..<vm.run.maxTraySlots {
            newBlocks.append(GameBlock.random(forRound: vm.run.currentRound, luckLevel: blockLuckLevel))
        }
        if vm.pendingStartingBombBlock, let first = newBlocks.first {
            let bomb = GameBlock(type: first.type, color: first.color, ability: .bomb, pairedBlockId: first.pairedBlockId, rotationSteps: first.rotationSteps)
            newBlocks[0] = bomb
            vm.pendingStartingBombBlock = false
        }
        vm.blockTray = newBlocks
        
        // Phase 6.2: Chain block pairing
        let chainBlocks = vm.blockTray.filter { $0.type == .chain }
        if chainBlocks.count >= 2 {
            for i in 0..<chainBlocks.count {
                for j in (i+1)..<chainBlocks.count {
                    if chainBlocks[i].color == chainBlocks[j].color && chainBlocks[i].pairedBlockId == nil && chainBlocks[j].pairedBlockId == nil {
                        if let index1 = vm.blockTray.firstIndex(where: { $0.id == chainBlocks[i].id }),
                           let index2 = vm.blockTray.firstIndex(where: { $0.id == chainBlocks[j].id }) {
                            vm.blockTray[index1].pairedBlockId = vm.blockTray[index2].id
                            vm.blockTray[index2].pairedBlockId = vm.blockTray[index1].id
                        }
                    }
                }
            }
        }
    }

    // MARK: - Deadlock & Refresh
    
    func checkDeadlock() {
        // Eğer zaten oyun bittiyse kontrol etme
        guard vm.phase == .playing else { return }
        
        var hasValidMove = false
        for block in vm.blockTray {
            if vm.board.canPlaceAnywhere(block: block) {
                hasValidMove = true
                break
            }
        }
        
        let wasDeadlocked = vm.isDeadlocked
        vm.isDeadlocked = !hasValidMove
        vm.canRefreshTray = vm.run.gold >= 100
        
        if vm.isDeadlocked && !wasDeadlocked {
            AudioManager.shared.playSFX(.deadlock)
        }
    }
    
    func refreshTrayWithCost() {
        guard vm.run.gold >= 100 else { return }
        
        vm.addRunGold(-100)
        refillBlockTray()
        vm.addPopup(text: "TRAY REFRESHED (-100 GOLD)", color: ThemeColors.neonOrange)
        vm.haptic.play(.success)
        
        checkDeadlock()
    }

    // MARK: - Enemy Attack System
    
    func startEnemyAttackLoop() {
        // Önceki timer'ları temizle
        stopEnemyLoop()
        
        // Bu round için rastgele bir düşman seç
        vm.enemy = EnemyState()
        if vm.currentNodeType == .boss {
            vm.enemy.currentAttack = EnemyAttackType.random(forRound: vm.run.currentRound, archetype: vm.bossArchetype, phase: vm.bossPhase)
        } else {
            vm.enemy.currentAttack = EnemyAttackType.random(forRound: vm.run.currentRound)
        }
        
        let interval: Double = {
            if vm.currentNodeType == .boss {
                return EnemyAttackType.attackInterval(forRound: vm.run.currentRound, archetype: vm.bossArchetype, phase: vm.bossPhase)
            }
            return EnemyAttackType.attackInterval(forRound: vm.run.currentRound)
        }()
        vm.enemy.nextAttackIn = interval
        
        // Ana atak timer'ı: her `interval` saniyede bir çalışır
        vm.enemyAttackTimer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.vm.phase == .playing else { return }
                self.triggerEnemyWarning()
            }
    }
    
    private func triggerEnemyWarning() {
        guard let attackType = vm.enemy.currentAttack else { return }
        
        // 3sn uyarı aşaması
        vm.showEnemyAttackWarning = true
        vm.enemyCountdown = 3.0
        vm.haptic.play(.timerWarning)
        
        // Geri sayım timer'ı (her 0.1sn)
        vm.enemyWarningTimer?.cancel()
        vm.enemyWarningTimer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.vm.enemyCountdown -= 0.1
                if self.vm.enemyCountdown <= 0 {
                    self.vm.enemyWarningTimer?.cancel()
                    self.vm.showEnemyAttackWarning = false
                    self.executeEnemyAttack(attackType)
                }
            }
    }
    
    private func executeEnemyAttack(_ attack: EnemyAttackType) {
        vm.haptic.play(.error)
        AudioManager.shared.playSFX(.lineClear) // Düşman sesini özelleştirebilirsin
        
        switch attack {
        
        // --- SABOTAJ: Rastgele 5 dolu hücreyi sil ---
        case .gridSabotage:
            let occupied = vm.board.allOccupiedPositions().shuffled().prefix(5)
            let positions = Array(occupied)
            if !positions.isEmpty {
                let result = vm.board.removeCells(at: positions)
                vm.clearFlashPositions = positions
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.vm.clearFlashPositions = [] }
                vm.addPopup(text: "💥 SABOTAJ! 5 BLOK SİLİNDİ", color: ThemeColors.neonPink)
            } else {
                vm.addPopup(text: "💥 SABOTAJ: Grid Boş!", color: ThemeColors.textMuted)
            }
            
        // --- SON BLOK SİL: Son yerleştirilen bloğu yok et ---
        case .lastBlockErase:
            if !vm.lastPlacedPositions.isEmpty {
                vm.board.removeCells(at: vm.lastPlacedPositions)
                vm.clearFlashPositions = vm.lastPlacedPositions
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.vm.clearFlashPositions = [] }
                vm.addPopup(text: "🗑️ SON BLOK SİLİNDİ!", color: ThemeColors.neonOrange)
                vm.lastPlacedPositions = []
            } else {
                vm.addPopup(text: "🗑️ Erase: Hedef Yok", color: ThemeColors.textMuted)
            }
            
        // --- KİLİTLEME: Tepsiyi 12sn kilitle ---
        case .trayLockdown:
            vm.enemy.isTrayLocked = true
            vm.enemy.trayLockRemainingTime = 12.0
            vm.addPopup(text: "🔒 TEPSİ 12SN KİLİTLENDİ!", color: ThemeColors.electricYellow)
            
            // 12sn sonra kilit aç — geri sayımla
            let lockDuration = 12.0
            vm.enemyTrayUnlockTimer?.cancel()
            vm.enemyTrayUnlockTimer = Timer.publish(every: 1.0, on: .main, in: .common)
                .autoconnect()
                .scan(0) { count, _ in count + 1 }
                .sink { [weak self] elapsed in
                    guard let self = self else { return }
                    self.vm.enemy.trayLockRemainingTime = lockDuration - Double(elapsed)
                    if elapsed >= Int(lockDuration) {
                        self.vm.enemy.isTrayLocked = false
                        self.vm.enemy.trayLockRemainingTime = 0
                        self.vm.enemyTrayUnlockTimer?.cancel()
                        self.vm.addPopup(text: "🔓 KİLİT AÇILDI!", color: ThemeColors.neonCyan)
                    }
                }
            
        // --- KARIŞTIRMA: Tüm tray bloklarını rastgele döndür ---
        case .scramble:
            for i in vm.blockTray.indices {
                let rotationCount = Int.random(in: 1...3)
                for _ in 0..<rotationCount {
                    vm.blockTray[i].rotate()
                }
            }
            vm.addPopup(text: "🌀 TEPSI KARISTIRILDI!", color: ThemeColors.neonPurple)
            
        // --- LANET YAYICISI: 5 boş hücreye lanet yayar ---
        case .curseSpreader:
            vm.board.applyCursedCells(count: 5)
            vm.addPopup(text: "☠️ 5 LANET YERLEŞTİRİLDİ!", color: Color(red: 0.6, green: 0.1, blue: 0.8))
            
        // --- ZAMAN HIRSIZI: 20sn çal ---
        case .timeHeist:
            vm.timer.addTime(-20)
            vm.addPopup(text: "⏳ -20SN ÇALINDI!", color: ThemeColors.neonCyan)
            
        // --- AĞIR ZIRH: 4 adet ağır hücre yerleştir ---
        case .heavyArmor:
            let positions = vm.board.allEmptyPositions().shuffled().prefix(4)
            for pos in positions {
                vm.board.grid[pos.row][pos.col].state = .heavy(hits: 2)
            }
            vm.addPopup(text: "🛡️ 4 AĞIR ENGEL KOYULDU!", color: ThemeColors.neonOrange)
        }
        
        // Sonraki atak türünü değiştir (her ataktan sonra farklı biri)
        if vm.currentNodeType == .boss {
            vm.enemy.currentAttack = EnemyAttackType.random(forRound: vm.run.currentRound, archetype: vm.bossArchetype, phase: vm.bossPhase)
        } else {
            let nextAttack = EnemyAttackType.allCases
                .filter { $0 != attack }
                .randomElement() ?? attack
            vm.enemy.currentAttack = nextAttack
        }
    }
    
    func stopEnemyLoop() {
        vm.enemyAttackTimer?.cancel()
        vm.enemyAttackTimer = nil
        vm.enemyWarningTimer?.cancel()
        vm.enemyWarningTimer = nil
        vm.enemyTrayUnlockTimer?.cancel()
        vm.enemyTrayUnlockTimer = nil
        vm.enemy.isTrayLocked = false
        vm.showEnemyAttackWarning = false
    }

    // MARK: - Clear Analysis Helpers
    
    // Kaç farklı satır temizlendiğini hesaplar
    func countClearedRows(in cells: [GameCell]) -> Int {
        var rows: Set<Int> = []
        for r in 0..<BoardViewModel.size {
            for c in 0..<BoardViewModel.size {
                if cells.contains(where: { $0 == vm.board.grid[r][c] }) {
                    // Bu hücre temizlenenlerden biri.
                    rows.insert(r)
                }
            }
        }
        // Eğer bir satırdaki TÜM hücreler (size=8) temizlendiyse o bir satır temizliğidir
        var count = 0
        for r in rows {
            let clearedInRow = cells.filter { cell in
                vm.board.grid[r].contains(where: { $0 == cell })
            }.count
            if clearedInRow >= BoardViewModel.size { count += 1 }
        }
        return count
    }
    
    func countClearedCols(in cells: [GameCell]) -> Int {
        var cols: Set<Int> = []
        for r in 0..<BoardViewModel.size {
            for c in 0..<BoardViewModel.size {
                if cells.contains(where: { $0 == vm.board.grid[r][c] }) {
                    cols.insert(c)
                }
            }
        }
        var count = 0
        for c in cols {
            let clearedInCol = cells.filter { cell in
                (0..<BoardViewModel.size).map({ vm.board.grid[$0][c] }).contains(where: { $0 == cell })
            }.count
            if clearedInCol >= BoardViewModel.size { count += 1 }
        }
        return count
    }
}
