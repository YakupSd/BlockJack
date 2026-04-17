//
//  GameViewModel.swift
//  Block-Jack
//

import Foundation
import SwiftUI
import Combine

// MARK: - Game Phase
enum GamePhase {
    case menu
    case playing
    case paused
    case bossIntro      // Boss round öncesi özel banner
    case bossDialogue   // BOSS DIALOGUE (NEW)
    case roundComplete  // Round bitti, mağaza
    case chapterComplete // Bölüm bitti (5. round kazanıldı)
    case shopping
    case gameOver
}

// MARK: - Score Popup (uçuşan yazı için)
struct ScorePopup: Identifiable {
    let id = UUID()
    let text: String
    let color: Color
    var position: CGPoint
}

// MARK: - GameViewModel
final class GameViewModel: ObservableObject {

    // MARK: - Sub-ViewModels & Services
    let board = BoardViewModel()
    let timer = TimerManager()

    var currentMultiplier: Double {
        // Ambient multiplier based on current streak and joker bonuses
        let streakBonus = min(Double(run.streak / 3) * 0.5, 3.0)
        return 1.0 + streakBonus + jokerMultBonus
    }

    // MARK: - Published State
    @Published var phase: GamePhase = .menu
    @Published var run = RunState()
    @Published var blockTray: [GameBlock] = []
    @Published var selectedBlock: GameBlock? = nil
    @Published var scorePopups: [ScorePopup] = []
    @Published var lastScoreResult: ScoreResult? = nil
    @Published var comboCount: Int = 0
    
    // MARK: - Visual Effects State
    @Published var clearFlashPositions: [GridPosition] = []  // 3.3: Neon flaş efekti için
    @Published var showBigComboLabel: String? = nil          // 3.4: DOUBLE CLEAR! vs ekranı
    
    // MARK: - Dragging State
    @Published var isDragging: Bool = false
    @Published var dragLocation: CGPoint = .zero
    @Published var draggingBlock: GameBlock? = nil
    @Published var gridFrame: CGRect = .zero

    // MARK: - Overdrive State
    @Published var overdriveCharge: Double = 0.0 // 0.0 to 3.0
    @Published var currentOverdriveTier: OverdriveTier = .none
    @Published var isOverdriveActive: Bool = false
    @Published var isTargetingOverdrive: Bool = false
    private var activeOverdriveTierForTargeting: OverdriveTier = .none
    
    // Character Specific State
    @Published var isWraithActive: Bool = false    // Neon Wraith skill
    @Published var isPhantomVisible: Bool = true   // Boss Phantom pulse
    @Published var showTutorial: Bool = false      // 4: Tutorial Overlay
    @Published var activeSynergies: [PerkSynergy] = [] // Phase 4 Synergy Cache
    
    private var lastPlacedBlockType: BlockType? = nil // Architect passive için
    var jokerMultBonus: Double = 0.0   // Joker bonusu — OverdriveEngine erişir
    private var maxRoundScore: Int = 0 // Echoes perk için
    var activeCharacterId: String? {
        SaveManager.shared.slots.first(where: { $0.id == activeSlotId })?.characterId
    }
    
    var activePerkId: String? {
        SaveManager.shared.slots.first(where: { $0.id == activeSlotId })?.selectedPerkId
    }
    
    var currentBoss: BossEncounter {
        BossRegistry.shared.getBoss(for: ((run.currentRound - 1) / 5) + 1)
    }
    
    // MARK: - Logic Bridge
    // GameView tarafından sağlanır, ekran koordinatını grid koordinatına çevirir
    var gridSpaceConverter: ((CGPoint) -> GridPosition?)?

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private let haptic = HapticManager.shared
    private let userEnv: UserEnvironment
    // jokerMultBonus aşağıda (sat 68) tanımlandı - OverdriveEngine erişimi için internal

    let activeSlotId: Int
    private let nodeType: NodeType?

    init(slotId: Int, nodeType: NodeType? = nil, userEnv: UserEnvironment = UserEnvironment.shared) {
        self.activeSlotId = slotId
        self.nodeType = nodeType
        self.userEnv = userEnv
        
        // Timer değişikliklerini ViewModel'e yansıt (UI update için)
        timer.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
            
        bindTimer()
        startPhantomPulse()
        startPassiveLoop() // 3.6: Character passive loops
        
        // Load initial state from save slot
        if let slot = SaveManager.shared.slots.first(where: { $0.id == slotId }), !slot.isEmpty {
            self.run.currentRound = slot.currentRound
            self.run.currentScore = slot.currentScore
            
            if let savedGrid = slot.grid {
                self.board.grid = savedGrid
            }
            if let savedTray = slot.trayBlocks {
                self.blockTray = savedTray
            }
            
            self.run.activePassivePerks = slot.activePassivePerks
            self.run.inventory = slot.inventory
            self.run.gold = slot.gold
            self.run.lives = slot.lives
            
            // Wide Load check
            if run.activePassivePerks.contains(where: { $0.id == "wide_load" }) {
                run.maxTraySlots = 4
            }
        }
    }

    // MARK: - Game Control

    func startNewRun() {
        run = RunState()
        board.resetGrid()
        startRound()
    }

    func startRound() {
        // Phase 9: NodeType'a göre zorluğu ayarla (run.round bir computed property - direkt set edilemez)
        if nodeType == .boss {
            run.activeModifier = BossModifier.allCases.randomElement()
            run.currentRoundTargetScore = RoundData.makeTarget(for: run.currentRound)
        } else if nodeType == .elite {
            run.activeModifier = nil
            let baseTarget = RoundData.makeTarget(for: run.currentRound)
            run.currentRoundTargetScore = Int(Double(baseTarget) * 1.5) // Elite: %50 daha zor
        } else {
            run.activeModifier = nil
            run.currentRoundTargetScore = RoundData.makeTarget(for: run.currentRound)
        }
        
        // Her round başlangıcında hamle ve streak sayaçlarını sıfırla
        run.movesUsed = 0
        run.streak = 0
        run.currentScore = 0
        run.halfBonusGiven = false
        
        // Timer: nodeType'a göre süre ayarla
        var initialTime = run.round.timeLimit
        if nodeType == .elite {
            initialTime = max(15.0, initialTime - 10.0)
        }
        
        // Kalıcı Geliştirme: Iron Will kontrolü
        if userEnv.unlockedUpgradeIDs.contains(MetaUpgrade.ironWill.rawValue) {
            initialTime += 10.0
        }
        
        timer.setup(seconds: initialTime)
        
        // Phase 4: Synergy Calculation
        activeSynergies = PerkEngine.evaluateSynergies(perks: run.activePassivePerks)
        
        // Phase 4: Overkill Carryover Check
        if run.overkillCarryover > 0 {
            run.currentScore += run.overkillCarryover
            addPopup(text: "OVERKILL +\(run.overkillCarryover)", color: ThemeColors.electricYellow)
            run.overkillCarryover = 0
        }
        
        run.sculptorUses = 0 // Reset Sculptor charges
        
        maxRoundScore = 0 // Sıfırla (Echoes Perk)
        
        if blockTray.isEmpty {
            refillBlockTray()
        }
        
        phase = .playing
        timer.start()
        
        // 4.2: Tutorial Check (Sadece 1. round ve eğer tamamlanmadıysa)
        if run.currentRound == 1 && !userEnv.tutorialCompleted {
            showTutorial = true
            timer.pause()
        }
        
        // Architect passive: Square O-blocks are easier to score with (implemented in handleClear)
        // Time Bender passive: Handle via time rewards
        
        // --- STARTING & PASSIVE PERKS (Task 4 & Leveling) ---
        
        // Ensure starting perk is converted to passive list (for HUD and consistent checks)
        if let pid = activePerkId, pid != "none" {
            if !run.hasPerk(pid), let starting = StartingPerk.available.first(where: { $0.id == pid }) {
                run.activePassivePerks.append(starting.toPassivePerk())
            }
        }
        
        // Golden Stamp: Target score reduction
        if run.hasPerk("golden_stamp") {
            let tier = run.perkTier("golden_stamp")
            // Level 1: -15%, Level 2: -25%, Level 3: -35%...
            let reduction = 0.15 + (Double(tier - 1) * 0.10)
            run.currentRoundTargetScore = Int(Double(run.currentRoundTargetScore) * (1.0 - reduction))
            addPopup(text: "STAMPED LV.\(tier)! -\(Int(reduction*100))% TARGET", color: ThemeColors.electricYellow)
        }
        
        // Wide Load: Extra tray slot
        if run.hasPerk("wide_load") {
            run.maxTraySlots = 4
        }
    }

    func pauseGame() {
        guard phase == .playing else { return }
        timer.pause()
        phase = .paused
    }

    func resumeGame() {
        guard phase == .paused else { return }
        timer.resume()
        phase = .playing
    }
    
    func dismissTutorial() {
        showTutorial = false
        userEnv.tutorialCompleted = true
        timer.resume()
    }

    // MARK: - Block Placement

    func tryPlace(block: GameBlock, at position: GridPosition) {
        guard phase == .playing else { return }

        // Neon Wraith check: if active, canPlace is always true for overlaps, but handle logic
        var clearedByWraith: [GameCell] = []
        if isWraithActive {
            // Skill usage: Place anyway and clear what was there
            for (dr, dc) in block.cells {
                let r = position.row + dr
                let c = position.col + dc
                if r >= 0 && r < BoardViewModel.size && c >= 0 && c < BoardViewModel.size {
                    clearedByWraith.append(board.grid[r][c])
                    board.grid[r][c].state = .empty
                }
            }
            isWraithActive = false
            addPopup(text: "GHOST OVERWRITE!", color: ThemeColors.neonPurple)
        }

        lastPlacedBlockType = block.type
        let clearedCells = board.placeBlock(block, at: position)

        if let cleared = clearedCells {
            // Yerleştirme başarılı
            haptic.play(.blockPlace)
            run.movesUsed += 1
            
            // Phase 5.1: Process Modifiers BEFORE checking clears
            for (dr, dc) in block.cells {
                let r = position.row + dr
                let c = position.col + dc
                if r >= 0 && r < BoardViewModel.size && c >= 0 && c < BoardViewModel.size {
                    if let mod = board.grid[r][c].modifier {
                        switch mod {
                        case .bonus(let type):
                            switch type {
                            case .gold(let amount):
                                run.gold += amount
                                addPopup(text: "+\(amount) ALTIN", color: ThemeColors.electricYellow)
                            case .star:
                                run.addScore(500)
                                addPopup(text: "YILDIZ! +500", color: ThemeColors.electricYellow)
                            case .timeBoost(let secs):
                                timer.addTime(secs)
                                addPopup(text: "+\(Int(secs))s", color: ThemeColors.neonCyan)
                            }
                        case .cursed:
                            timer.addTime(-5) // -5 seconds
                            comboCount += 1 // Combo charge
                            addPopup(text: "LANET! -5s", color: ThemeColors.neonPink)
                            haptic.play(.error)
                        default:
                            break // Locked is handled in canPlace
                        }
                        // Modifier'ı consume et (sil)
                        board.grid[r][c].modifier = nil
                    }
                }
            }
            
            // Minor charge per block
            if overdriveCharge < 3.0 {
                let previousTier = currentOverdriveTier
                overdriveCharge = min(3.0, overdriveCharge + 0.05)
                updateOverdriveTier(previous: previousTier)
            }

            if cleared.isEmpty {
                // Temizleme olmadı → streak sıfırla
                run.streak = 0
                comboCount = 0
                
                // Phase 4: Momentum Tracker
                if run.hasPerk("momentum") {
                    run.tensionCount += 1
                }
            } else {
                // Satır/sütun temizlendi
                handleClear(clearedCells: cleared)
            }

            // Phase 5.2: Gravity Mode (Boss Round'lar için aktif olsun - Elite eklenecek)
            if run.round.isBossRound {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        self?.board.applyGravity()
                        // Yerçekimi sonrası oluşan yeni kombinasyonları tetikleyebiliriz
                        // Fakat sonsuz döngüden kaçınmak için şimdilik sadece visual shifting yapalım
                    }
                }
            }

            // Tray'den bloğu kaldır
            blockTray.removeAll { $0.id == block.id }
            
            // Phase 6.2: Chain Block removal
            if block.type == .chain, let pairedId = block.pairedBlockId {
                blockTray.removeAll { $0.id == pairedId }
            }
            
            if blockTray.isEmpty { refillBlockTray() }

            // Hamle sınırı kontrolü
            checkMoveLimit()

            // Deadlock kontrolü
            if board.isDeadlock(blocks: blockTray) { triggerGameOver() }

        } else {
            // Yerleştirme başarısız
            haptic.play(.blockFail)
        }
    }

    func handleClear(clearedCells: [GameCell]) {
        comboCount += 1
        run.streak += 1
        
        // 3.3: Neon Flash Effect
        // (Assuming GridView can see these, we set them and clear them after delay)
        // To find positions, we need to know WHICH cells were cleared. 
        // We'll approximate or use board grid logic if needed, but here we have clearedCells.
        // Wait, BoardViewModel doesn't store positions in GameCell. 
        // I should have improved GameCell to hold its position. 
        // For now, I'll use a trick: search the grid for cells that are NOW empty but were in clearedCells.
        // Better: I'll update BoardViewModel to return positions too or just use the clearedRows/Cols.
        
        // For simplicity, let's trigger a general flash if positions aren't available, 
        // but I'll try to get them from the grid.
        var flashPositions: [GridPosition] = []
        for r in 0..<BoardViewModel.size {
            for c in 0..<BoardViewModel.size {
                if clearedCells.contains(where: { $0 == board.grid[r][c] }) {
                    flashPositions.append(GridPosition(row: r, col: c))
                }
            }
        }
        clearFlashPositions = flashPositions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.clearFlashPositions = []
        }

        // Overdrive charge
        if overdriveCharge < 3.0 {
            let previousTier = currentOverdriveTier
            overdriveCharge = min(3.0, overdriveCharge + 0.20)
            updateOverdriveTier(previous: previousTier)
        }

        // 3.6: Character Passive Multipliers
        var characterMult = jokerMultBonus
        
        // --- STARTING & PASSIVE PERKS (Task 4: Scaling Logic) ---
        
        // Lucky Clover Scaling: +0.5 per tier
        if run.hasPerk("lucky_clover") {
            let tier = run.perkTier("lucky_clover")
            characterMult += (0.5 * Double(tier))
        }
        
        // Momentum Scaling: x(Tier+1) on 4th streak
        if run.hasPerk("momentum") && run.tensionCount >= 3 {
            let tier = run.perkTier("momentum")
            let bonus = Double(tier + 1)
            characterMult += bonus
            run.tensionCount = 0 // Reset
            addPopup(text: "MOMENTUM LV.\(tier)! +\(Int(bonus))x", color: ThemeColors.electricYellow)
            
            // SYNERGY: TIME LAPSE (Momentum + Clockwork)
            if activeSynergies.contains(where: { $0.synergyName == "TIME LAPSE" }) {
                timer.addTime(5.0)
                addPopup(text: "TIME LAPSE! +5s", color: ThemeColors.neonPurple)
            }
        }
        
        // Glass Cannon Scaling: +0.5 multiplier step per tier
        if run.hasPerk("glass_cannon") && run.lives == 1 {
            let tier = run.perkTier("glass_cannon")
            let bonus = 0.5 + (Double(tier - 1) * 0.5)
            characterMult += bonus
            addPopup(text: "GLASS CANNON LV.\(tier) ACTIVE", color: ThemeColors.neonPink)
        }
        
        if let charId = activeCharacterId {
            switch charId {
            case "architect":
                if lastPlacedBlockType == .O {
                    characterMult += 0.2 // Square (O) blocks +20%
                    addPopup(text: "ARCHITECT BONUS!", color: ThemeColors.neonCyan)
                }
            case "gambler":
                // Gelişmiş Şans (Meta-Upgrade: Lucky Dice +3% chance)
                var triggerChance = 0.07
                if userEnv.unlockedUpgradeIDs.contains(MetaUpgrade.luckyDice.rawValue) {
                    triggerChance = 0.10
                }
                
                if Double.random(in: 0...1) < triggerChance {
                    characterMult += 9.0 // effectively total x10 if base was 1
                    addPopup(text: "JACKPOT! ×10", color: ThemeColors.electricYellow)
                    haptic.play(.success)
                }
            case "neonwraith":
                if timer.ratio < 0.15 {
                    characterMult += 2.0 // x3 multiplier in last 15% time
                    addPopup(text: "WRAITH FURY!", color: ThemeColors.neonPurple)
                }
            default: break
            }
        }

        // Satır ve sütun sayısını hesapla (clear combo için)
        let clearedRows = countClearedRows(in: clearedCells)
        let clearedCols = countClearedCols(in: clearedCells)
        
        // Blue Pill Scaling: x(Tier+1) chips for blue blocks
        var chipBonus = 1.0
        if run.hasPerk("blue_pill") {
            let blueCount = clearedCells.filter { if case .filled(let c) = $0.state { return c == .blue } else { return false } }.count
            if blueCount > 0 {
                let tier = run.perkTier("blue_pill")
                chipBonus = Double(tier + 1)
                addPopup(text: "BLUE PILL LV.\(tier)! ×\(Int(chipBonus))", color: ThemeColors.neonCyan)
            }
        }
        
        var result = ScoreEngine.calculate(
            clearedCells: clearedCells,
            blockCellCount: Int(Double(clearedCells.count) * chipBonus), // Effectively doubling chips if blue exists
            streak: run.streak,
            clearedRows: clearedRows,
            clearedCols: clearedCols,
            jokerMultBonus: characterMult
        )

        lastScoreResult = result
        run.addScore(result.totalScore)

        // 3.4: Big Combo Label
        if result.clearCombo != .single {
            showBigComboLabel = result.clearCombo.label
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                if self.showBigComboLabel == result.clearCombo.label {
                    self.showBigComboLabel = nil
                }
            }
        }

        // Haptic
        if result.isBigCombo {
            haptic.play(.flush)
        } else if result.isFlush {
            haptic.play(.lineClear)
        } else {
            haptic.play(.lineClear)
        }

        // Süre bonusu
        var bonus = ScoreEngine.timeBonusSeconds(clearCombo: result.clearCombo, isFlush: result.isFlush, streakCount: run.streak)
        
        // 3.6: Time Bender Passive
        if activeCharacterId == "timebender" {
            bonus *= 1.5
        }
        
        timer.addTime(bonus)

        // %50 hedef bonusu
        if !run.halfBonusGiven && run.scoreProgress >= 0.5 {
            run.halfBonusGiven = true
            timer.addTime(10)
            addPopup(text: "+10s BONUS!", color: ThemeColors.electricYellow)
        }
        
        // Echoes kayıt
        if result.totalScore > maxRoundScore {
            maxRoundScore = result.totalScore
        }
        
        // Clockwork Scaling
        if run.hasPerk("clockwork") {
            let tier = run.perkTier("clockwork")
            // Base logic moved here for direct scaling
            let baseInc = bonus * 0.1
            let scaledInc = baseInc * Double(tier)
            run.clockworkBonus = min(2.5, run.clockworkBonus + scaledInc)
            
            if run.clockworkBonus > 0 { characterMult += run.clockworkBonus }
        }

        // Score popup
        addPopup(
            text: "+\(result.totalScore)",
            color: result.isBigCombo ? ThemeColors.neonPurple : ThemeColors.neonCyan
        )
        // Tüm combo labellarını göster
        for label in result.allLabels {
            addPopup(text: label, color: ThemeColors.electricYellow)
        }

        // Hedef kontrolü
        checkRoundTarget()
    }
    
    private func updateOverdriveTier(previous: OverdriveTier) {
        guard let char = SaveManager.shared.slots.first(where: { $0.id == activeSlotId })?.character else { return }
        currentOverdriveTier = OverdriveEngine.currentTier(charge: overdriveCharge, thresholds: char.overdriveThresholds)
        
        if currentOverdriveTier != previous && currentOverdriveTier != .none {
            haptic.play(.success)
            addPopup(text: "TIER \(currentOverdriveTier.rawValue) READY!", color: ThemeColors.electricYellow)
        }
    }
    
    // MARK: - Overdrive Mechanics
    func activateOverdrive() {
        guard let charId = activeCharacterId else { return }
        let tier = currentOverdriveTier
        guard tier != .none else { return }
        
        // Store tier for targeting characters before resetting
        if charId == "block_e" || charId == "architect" {
            activeOverdriveTierForTargeting = tier
        }
        
        OverdriveEngine.execute(tier: tier, charId: charId, vm: self)
        
        // Şarjı tüket
        guard let char = SaveManager.shared.slots.first(where: { $0.id == activeSlotId })?.character else { return }
        // Seviyenin threshold'u kadar harcatır veya tamamen sıfırlarız, simdilik sifirliyoruz
        overdriveCharge = 0.0
        currentOverdriveTier = .none
    }
    
    func applyTargetedOverdrive(at pos: GridPosition) {
        guard isTargetingOverdrive else { return }
        guard let charId = activeCharacterId else { return }
        
        // Execute targeting via engine (the charge was already consumed)
        // Since we consumed the charge in activateOverdrive, we just use the selected mechanic
        
        OverdriveEngine.executeTargeted(pos: pos, tier: activeOverdriveTierForTargeting, charId: charId, vm: self)
        haptic.play(.flush)
        isTargetingOverdrive = false
    }

    // MARK: - Round Logic

    private func checkRoundTarget() {
        if run.currentScore >= run.currentRoundTargetScore {
            completeRound()
        }
    }

    private func checkMoveLimit() {
        // Hamle limiti artık çok yüksek (300)
        if run.movesUsed >= run.round.moveLimit {
            if run.currentScore >= run.currentRoundTargetScore {
                completeRound()
            } else {
                triggerGameOver()
            }
        }
    }

    private func completeRound() {
        timer.pause()
        let result = lastScoreResult ?? ScoreResult(
            baseChips: 0, multiplier: 1, totalScore: 0,
            flushType: .none, clearCombo: .single, clearedRows: 0, clearedCols: 0, streakBonus: 0
        )
        // Echoes Scaling: Repeated score scales with tier
        if run.hasPerk("echoes") && maxRoundScore > 0 {
            let tier = run.perkTier("echoes")
            let scale = 1.0 + (Double(tier - 1) * 0.5)
            let bonus = Int(Double(maxRoundScore) * scale)
            run.addScore(bonus)
            addPopup(text: "ECHOES LV.\(tier) +\(bonus)", color: ThemeColors.neonPurple)
        }
        
        // Overkill Scaling: Percent carryover increases with tier
        if run.hasPerk("overkill") {
            let tier = run.perkTier("overkill")
            // Level 1: 30%, Level 2: 45%, Level 3: 60%...
            let percentage = 0.30 + (Double(tier - 1) * 0.15)
            let rawOverflow = max(0, run.currentScore - run.currentRoundTargetScore)
            let overflow = Int(Double(rawOverflow) * percentage)
            
            run.overkillCarryover = overflow
            addPopup(text: "OVERKILL LV.\(tier) +\(overflow) NEXT", color: ThemeColors.neonPink)
            
            // SYNERGY: ENDLESS RESERVES (Overkill + Echoes)
            if activeSynergies.contains(where: { $0.synergyName == "ENDLESS RESERVES" }) {
                let timeBonus = Double(overflow) / 50.0 // Her 50 puan için 1sn
                timer.addTime(timeBonus)
                if timeBonus > 1 {
                    addPopup(text: "RESERVES: +\(Int(timeBonus))s", color: ThemeColors.neonPurple)
                }
            }
        }
        
        // 3. Altın Hesabı (Meta-Upgrade: Gold Eye Bonus)
        let hasGoldEye = userEnv.unlockedUpgradeIDs.contains(MetaUpgrade.goldEye.rawValue)
        let goldAdded = ScoreEngine.goldEarned(for: result, hasGoldEye: hasGoldEye)
        run.gold += goldAdded
        userEnv.earn(gold: goldAdded)
        userEnv.updateHighScore(run.currentScore)

        
        // Boss round kazanma = +1 can!
        if run.round.isBossRound {
            run.gainLife()
            showBigComboLabel = "BOSS DEFEATED!" // Üstte büyük yazı çıksın
            haptic.play(.heavy)
            addPopup(text: "CHAPTER COMPLETE! +1 ❤️", color: ThemeColors.neonPink)
            
            // Wait to clear the big label
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.showBigComboLabel = nil
            }
        }
        
        phase = .roundComplete
    }

    func proceedToNextRound() {
        let wasBossRound = run.round.isBossRound
        run.nextRound()
        board.resetGrid()
        
        // Flow routing based on new round state
        if wasBossRound {
            // We just finished a boss round (e.g. going from 5 to 6) -> Chapter complete
            phase = .chapterComplete
        } else if run.round.isBossRound {
            // The next round is a boss round (e.g. going from 4 to 5) -> Boss intro
            phase = .bossIntro
        } else {
            // Normal round
            startRound()
        }
    }
    
    func startChapter() {
        // Called from ChapterCompleteOverlay "Devam Et" button
        startRound()
    }
    
    func startBossRound() {
        // Called from BossIntroOverlay "Savaş" button -> Moves to Dialogue
        phase = .bossDialogue
        timer.pause()
    }
    
    func startBossFightAfterDialogue() {
        // Called from BossDialogueOverlay when dialogue ends
        if let modifier = run.round.modifier {
            addPopup(text: "BOSS FIGHT: \(modifier.title)", color: ThemeColors.neonPink)
            
            // Apply initial boss mechanics
            switch modifier {
            case .glitch:
                board.applyGlitch(count: 3 + (run.currentRound / 5))
            case .weight:
                break
            default: break
            }
        }
        startRound()
    }

    // MARK: - Perk Interactions
    
    func rotateSelectedBlock() {
        guard let block = selectedBlock else { return }
        
        // Sculptor Kontrolü
        let hasSculptor = run.activePassivePerks.contains(where: { $0.id == "sculptor" })
        guard hasSculptor else { return }
        
        // SYNERGY: MASTER BUILDER (Wide Load + Sculptor)
        let isMasterBuilder = activeSynergies.contains(where: { $0.synergyName == "MASTER BUILDER" })
        let isFourthSlot = blockTray.firstIndex(where: { $0.id == block.id }) == 3
        
        // Kullanım Sınırı Kontrolü (Master Builder ise 4. slot ücretsiz)
        let tier = run.perkTier("sculptor")
        let maxUses = tier * 2
        if !isMasterBuilder || !isFourthSlot {
            guard run.sculptorUses < maxUses else {
                addPopup(text: "HAKKIN BİTTİ (\(maxUses)/\(maxUses))!", color: ThemeColors.neonPink)
                return
            }
            run.sculptorUses += 1
        } else if isMasterBuilder && isFourthSlot {
            addPopup(text: "FREE ROTATE!", color: ThemeColors.neonPurple)
        }
        
        if let index = blockTray.firstIndex(where: { $0.id == block.id }) {
            blockTray[index].rotate()
            selectedBlock = blockTray[index]
            haptic.play(.selection)
            addPopup(text: "DÖNDÜRÜLDÜ!", color: ThemeColors.neonCyan)
        }
    }

    // MARK: - Consumable Interactions
    
    func useItem(_ item: ConsumableItem) {
        guard phase == .playing || phase == .paused else { return }
        
        switch item.type {
        case .heal:
            run.gainLife()
            addPopup(text: "+1 ❤️ (HEALED)", color: ThemeColors.neonPink)
            haptic.play(.success)
        case .energy:
            overdriveCharge = 3.0
            updateOverdriveTier(previous: .none)
            addPopup(text: "ENERGY MAXED!", color: ThemeColors.electricYellow)
            haptic.play(.success)
        case .goldBag:
            run.gold += 150
            userEnv.earn(gold: 150)
            addPopup(text: "+150 GOLD", color: ThemeColors.electricYellow)
            haptic.play(.success)
        case .cleanup:
            board.resetGrid()
            addPopup(text: "SYSTEM CLEANUP", color: ThemeColors.neonCyan)
            haptic.play(.flush)
        }
        
        // Remove from local and disk
        run.inventory.removeAll(where: { $0.id == item.id })
        SaveManager.shared.removeConsumable(slotId: activeSlotId, itemId: item.id)
    }

    // MARK: - Game Over & Saving

    func saveGameState() {
        var slot = SaveManager.shared.slots.first(where: { $0.id == activeSlotId }) ?? SaveSlot.empty(id: activeSlotId)
        slot.currentScore = run.currentScore
        slot.currentRound = run.currentRound
        slot.grid = board.grid
        slot.trayBlocks = blockTray
        slot.timeLeft = timer.timeRemaining > 0 ? timer.timeRemaining : nil
        slot.lastSaved = Date()
        
        if let index = SaveManager.shared.slots.firstIndex(where: { $0.id == activeSlotId }) {
            SaveManager.shared.slots[index] = slot
        }
        // Ideally trigger the internal saveToDisk inside SaveManager, handled by assigning if @Published,
        // but we'll do an explicit update just in case.
        SaveManager.shared.updateSave(slotId: activeSlotId, score: run.currentScore, round: run.currentRound)
        
        // We bypass the strictly private update but since it's published, it might trigger automatically.
    }

    func triggerGameOver() {
        // --- PREVENTION LAYER (Synergies & Perks) ---
        if run.undyingRageActive { return } // Do not die while immortal

        // 1. SYNERGY: UNDYING RAGE (One-time save with 5s immortality)
        let hasUndyingRage = activeSynergies.contains(where: { $0.synergyName == "UNDYING RAGE" })
        if hasUndyingRage && run.lives == 1 && !run.lastStandUsed {
            run.lastStandUsed = true 
            run.gainLife()
            run.undyingRageActive = true
            timer.pause()
            addPopup(text: "UNDYING RAGE! +1 ❤️ & IMMORTAL", color: ThemeColors.neonPurple)
            haptic.play(.heavy)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                self?.run.undyingRageActive = false
                self?.timer.resume()
                self?.addPopup(text: "IMMORTALITY ENDED", color: ThemeColors.neonPink)
            }
            return
        }

        // 2. PERK: Last Stand (Basic save)
        if run.hasPerk("last_stand") && !run.lastStandUsed {
            run.lastStandUsed = true
            run.lives = max(1, run.lives)
            addPopup(text: "LAST STAND! ❤️", color: ThemeColors.neonCyan)
            haptic.play(.heavy)
            return
        }

        // --- ACTUAL GAME OVER / LIFE LOSS ---
        timer.stop()
        haptic.play(.gameOver)
        
        run.loseLife()
        saveGameState()
        
        phase = .gameOver // Triggets GameOverOverlay which reads run.isGameOver
    }

    // MARK: - Block Tray

    func refillBlockTray() {
        var newBlocks: [GameBlock] = []
        for _ in 0..<run.maxTraySlots {
            newBlocks.append(GameBlock.random(forRound: run.currentRound))
        }
        blockTray = newBlocks
        
        // Phase 6.2: Chain block pairing
        let chainBlocks = blockTray.filter { $0.type == .chain }
        if chainBlocks.count >= 2 {
            for i in 0..<chainBlocks.count {
                for j in (i+1)..<chainBlocks.count {
                    if chainBlocks[i].color == chainBlocks[j].color && chainBlocks[i].pairedBlockId == nil && chainBlocks[j].pairedBlockId == nil {
                        if let index1 = blockTray.firstIndex(where: { $0.id == chainBlocks[i].id }),
                           let index2 = blockTray.firstIndex(where: { $0.id == chainBlocks[j].id }) {
                            blockTray[index1].pairedBlockId = blockTray[index2].id
                            blockTray[index2].pairedBlockId = blockTray[index1].id
                        }
                    }
                }
            }
        }
    }

    // MARK: - Drag Handling
    
    func updateDrag(location: CGPoint, gridPosition: GridPosition?) {
        guard isDragging, let block = draggingBlock else { return }
        dragLocation = location
        
        if let pos = gridPosition {
            board.updateGhost(block, at: pos)
        } else {
            board.clearGhost()
        }
    }
    
    func handleDragEnd() {
        guard isDragging, let block = draggingBlock else {
            resetDrag()
            return
        }
        
        // BlockTrayView'dan tetiklenir, lokasyonu GameView'dan gelen converter ile çözer
        if let pos = gridSpaceConverter?(dragLocation) {
            tryPlace(block: block, at: pos)
        }
        
        resetDrag()
    }
    
    func handleOverdriveDrop() {
        guard isTargetingOverdrive else { return }
        if let pos = gridSpaceConverter?(dragLocation) {
            applyTargetedOverdrive(at: pos)
        } else {
            isTargetingOverdrive = false
        }
    }
    
    private func resetDrag() {
        isDragging = false
        draggingBlock = nil
        board.clearGhost()
    }
    
    // MARK: - Timer Binding

    private func bindTimer() {
        timer.$didExpire
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.triggerGameOver()
            }
            .store(in: &cancellables)

        timer.$ratio
            .filter { $0 < 0.1 }
            .removeDuplicates()
            .sink { [weak self] (ratio: Double) in // Explicit type to aid inference
                self?.haptic.play(.timerWarning)
            }
            .store(in: &cancellables)
    }

    // MARK: - Boss Specific Logic
    
    private func startPhantomPulse() {
        Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.run.round.modifier == .phantom else { return }
                
                // Pulse visibility: 0.8s visible, then hide again
                self.isPhantomVisible = true
                self.addPopup(text: "PHANTOM DETECTED!", color: ThemeColors.neonPurple)
                self.haptic.play(.heavy)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.isPhantomVisible = false
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Character Passives Loop
    
    private func startPassiveLoop() {
        Timer.publish(every: 10.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.phase == .playing else { return }
                
                if let charId = self.activeCharacterId {
                    switch charId {
                    case "block_e":
                        // BLOCK-E: Every 10s, clear 1 random occupied cell
                        self.clearRandomCell(count: 1)
                        self.addPopup(text: "BLOCK-E: SYSTEM CLEANUP", color: ThemeColors.neonCyan)
                        self.haptic.play(.lineClear)
                    default: break
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func clearRandomCell(count: Int) {
        let occupied = (0..<BoardViewModel.size).flatMap { r in
            (0..<BoardViewModel.size).compactMap { c in
                board.grid[r][c].isOccupied ? GridPosition(row: r, col: c) : nil
            }
        }.shuffled()
        
        for pos in occupied.prefix(count) {
            board.removeCell(at: pos)
            // Trigger a small flash
            clearFlashPositions = [pos]
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.clearFlashPositions = []
            }
        }
    }

    // MARK: - Score Popup Helper

    func addPopup(text: String, color: Color, position: CGPoint = CGPoint(x: 187, y: 300)) {
        let popup = ScorePopup(text: text, color: color, position: position)
        scorePopups.append(popup)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.scorePopups.removeAll { $0.id == popup.id }
        }
    }
    
    // MARK: - Clear Analysis Helpers
    
    // Kaç farklı satır temizlendiğini hesaplar
    private func countClearedRows(in cells: [GameCell]) -> Int {
        var rows: Set<Int> = []
        for r in 0..<BoardViewModel.size {
            for c in 0..<BoardViewModel.size {
                if cells.contains(where: { $0 == board.grid[r][c] }) {
                    // Bu hücre temizlenenlerden biri.
                    rows.insert(r)
                }
            }
        }
        // Eğer bir satırdaki TÜM hücreler (size=8) temizlendiyse o bir satır temizliğidir
        var count = 0
        for r in rows {
            let clearedInRow = cells.filter { cell in
                board.grid[r].contains(where: { $0 == cell })
            }.count
            if clearedInRow >= BoardViewModel.size { count += 1 }
        }
        return count
    }
    
    private func countClearedCols(in cells: [GameCell]) -> Int {
        var cols: Set<Int> = []
        for r in 0..<BoardViewModel.size {
            for c in 0..<BoardViewModel.size {
                if cells.contains(where: { $0 == board.grid[r][c] }) {
                    cols.insert(c)
                }
            }
        }
        var count = 0
        for c in cols {
            let clearedInCol = cells.filter { cell in
                (0..<BoardViewModel.size).map({ board.grid[$0][c] }).contains(where: { $0 == cell })
            }.count
            if clearedInCol >= BoardViewModel.size { count += 1 }
        }
        return count
    }
}
