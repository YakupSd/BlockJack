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
    // dragLocation: @Published DEĞİL — her frame güncellenir, @Published olursa tüm view yeniden render olur (lag!)
    // GameView'da @State dragPosition ile overlay render edilir.
    var dragLocation: CGPoint = .zero
    @Published var draggingBlock: GameBlock? = nil
    @Published var gridFrame: CGRect = .zero

    // VFX State
    @Published var shakeAmount: CGFloat = 0
    @Published var flashOpacity: Double = 0
    
    // MARK: - Partikül Event
    // GameView'a hangi tür patlamanın nerede çıkacağını iletir
    struct ParticleBurstEvent: Equatable {
        enum Kind: Equatable {
            case lineClear(positions: [GridPosition], color: Color)
            case zoneBlast(centerRow: Int, centerCol: Int, radius: CGFloat, color: Color)
            case overdriveBoom(centerRow: Int, centerCol: Int)
        }
        let id: UUID = UUID()
        let kind: Kind
        static func == (lhs: ParticleBurstEvent, rhs: ParticleBurstEvent) -> Bool {
            lhs.id == rhs.id
        }
    }
    @Published var particleBurst: ParticleBurstEvent? = nil

    // MARK: - Overdrive State
    @Published var overdriveCharge: Double = 0.0 // 0.0 to 3.0
    @Published var currentOverdriveTier: OverdriveTier = .none
    @Published var isOverdriveActive: Bool = false
    @Published var isTargetingOverdrive: Bool = false
    var activeOverdriveTierForTargeting: OverdriveTier = .none
    
    // Character Specific State
    @Published var isWraithActive: Bool = false    // Neon Wraith skill
    @Published var isPhantomVisible: Bool = true   // Boss Phantom pulse
    @Published var showTutorial: Bool = false      // 4: Tutorial Overlay
    @Published var activeSynergies: [PerkSynergy] = [] // Phase 4 Synergy Cache
    @Published var bossIntent: String? = nil           // AAA: Boss Warning Intent
    @Published var isSynergyClear: Bool = false        // AAA: Rainbow VFX Flag
    private var bossIntentCooldown: Int = 3            // Moves until intent clears
    
    private var lastPlacedBlockType: BlockType? = nil // Architect passive için
    var jokerMultBonus: Double = 0.0   // Joker bonusu — OverdriveEngine erişir
    private var maxRoundScore: Int = 0 // Echoes perk için
    
    // MARK: - Enemy Attack System
    @Published var enemy: EnemyState = EnemyState()
    @Published var showEnemyAttackWarning: Bool = false  // Uyarı overlay göster
    @Published var enemyCountdown: Double = 3.0          // Uyarı geri sayım
    private var enemyAttackTimer: AnyCancellable? = nil
    private var enemyWarningTimer: AnyCancellable? = nil
    private var enemyTrayUnlockTimer: AnyCancellable? = nil
    var lastPlacedPositions: [GridPosition] = []         // Son yerleştirilen blok pozisyonları (erase için)
    var activeCharacterId: String? {
        SaveManager.shared.slots.first(where: { $0.id == activeSlotId })?.characterId
    }
    
    var activePerkId: String? {
        SaveManager.shared.slots.first(where: { $0.id == activeSlotId })?.selectedPerkId
    }
    
    var currentBoss: BossEncounter {
        BossRegistry.shared.getBoss(for: run.worldLevel)
    }
    
    // MARK: - Logic Bridge
    // GameView tarafından sağlanır, ekran koordinatını grid koordinatına çevirir
    var gridSpaceConverter: ((CGPoint) -> GridPosition?)?

    // Drag throttle: ghost/hint güncellemesini saniyede max ~30 kez yap (33ms aralık)
    private var lastGhostUpdate: Date = .distantPast
    private let ghostThrottleInterval: TimeInterval = 0.033

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private let haptic = HapticManager.shared
    let userEnv: UserEnvironment
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
                // Dimension validation: Ensure saved grid matches current BoardViewModel.size (12x12)
                if savedGrid.count == BoardViewModel.size && (savedGrid.first?.count ?? 0) == BoardViewModel.size {
                    self.board.grid = savedGrid
                } else {
                    // Mismatch: Reset grid to prevent Index out of range crashes
                    self.board.resetGrid()
                    addPopup(text: "SYNC: GRID RESET", color: ThemeColors.neonOrange)
                }
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
        board.resetGrid() // FORCE RESET (Reset Bug Fix)
        
        // Phase 9: NodeType'a göre zorluğu ayarla
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
            initialTime = max(120.0, initialTime - 30.0) // Elite: -30sn, minimum 120sn
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
        
        if nodeType == .boss {
            phase = .bossDialogue
            timer.pause()
        } else {
            phase = .playing
            timer.start()
            
            // D\u00fc\u015fman atak sistemi ba\u015flat
            startEnemyAttackLoop()
        }
        
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
        
        // SYNERGY: GOLDEN FEVER (Penalty part)
        if activeSynergies.contains(where: { $0.synergyName == "GOLDEN FEVER" }) {
            run.currentRoundTargetScore = Int(Double(run.currentRoundTargetScore) * 1.2)
        }
    }

    func addPerk(_ perk: PassivePerk) {
        run.activePassivePerks.append(perk)
        activeSynergies = PerkEngine.evaluateSynergies(perks: run.activePassivePerks)
        
        // Phase C: Discovery
        UserEnvironment.shared.discoverPerk(perk.id)
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
        
        // Tray kilitliyse yerleştirme
        if enemy.isTrayLocked {
            haptic.play(.error)
            addPopup(text: "🔒 TEPSİ KİTLİ!", color: ThemeColors.electricYellow)
            return
        }
        
        let clearResult = board.placeBlock(block, at: position)
        let placementSuccess = clearResult != nil
        
        if placementSuccess, let result = clearResult {
            // Son yerleştirilen pozisyonları kaydet (düşman erase atağı için)
            lastPlacedPositions = block.cells.compactMap { (dr, dc) -> GridPosition? in
                let r = position.row + dr
                let c = position.col + dc
                guard r >= 0, r < BoardViewModel.size, c >= 0, c < BoardViewModel.size else { return nil }
                return GridPosition(row: r, col: c)
            }
            // AAA: Manage Boss Intent cooldown
            if run.round.isBossRound {
                bossIntentCooldown -= 1
                if bossIntentCooldown <= 0 {
                    bossIntent = nil
                }
                
                // Show new intent every 4 moves
                if bossIntentCooldown <= -1 {
                    bossIntent = currentBoss.getRandomIntent()
                    bossIntentCooldown = 3
                }
            } else {
                bossIntent = nil
            }

            // placeBlock'tan gelen clear result'ı kullanıyoruz (artık tekrar clearFullLinesAndZones çağırmaya gerek yok)
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
                                UserEnvironment.shared.addGoldEarned(amount)
                                AudioManager.shared.playSFX(.coin)
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
            
            // Minor charge per block (Faster charge)
            if overdriveCharge < 3.0 {
                let previousTier = currentOverdriveTier
                overdriveCharge = min(3.0, overdriveCharge + 0.15)
                updateOverdriveTier(previous: previousTier)
            }

            let cleared = result.clearedCells
            if cleared.isEmpty {
                // Temizleme olmadı → streak sıfırla, hiç puan yok
                run.streak = 0
                comboCount = 0
                
                // Phase 4: Momentum Tracker
                if run.hasPerk("momentum") {
                    run.tensionCount += 1
                }
                // Puan verilmiyor — sadece satır/sütun/zone dolunca puan kazanılır
            } else {
                // Track global stats
                UserEnvironment.shared.addLinesCleared(cleared.count)
                
                // Satır/sütun/alan temizlendi
                handleClear(result: result, blockCellCount: block.cells.count)
            }

            // Phase 5.2: Gravity Mode (Boss Round'lar için aktif olsun - Elite eklenecek)
            if run.round.isBossRound {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        self?.board.applyGravity()
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

    func handleClear(result: BoardViewModel.ClearResult, blockCellCount: Int = 4) {
        let clearedCells = result.clearedCells
        let clearedRows = result.rowsCleared
        let clearedCols = result.colsCleared
        
        comboCount += 1
        run.streak += 1
        
        // 1. Particle & Flash Effects
        let flashPositions = result.clearedPositions
        clearFlashPositions = flashPositions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.clearFlashPositions = []
        }
        
        // --- Partikül olayını yayınla ---
        if result.zonesCleared > 0 {
            // Zone blast — her temizlenen zone için merkez hesapla
            // Köşe zone merkezleri (4x4): (1,1) (1,10) (10,1) (10,10)
            // Merkez zone merkezi (5x5): (6,6)
            let zoneCenters: [(Int, Int, Color)] = [
                (1,  1,  ThemeColors.electricYellow),  // Sol üst köşe
                (1,  10, ThemeColors.electricYellow),  // Sağ üst köşe
                (10, 1,  ThemeColors.electricYellow),  // Sol alt köşe
                (10, 10, ThemeColors.electricYellow),  // Sağ alt köşe
                (6,  6,  ThemeColors.neonPurple),      // Merkez
            ]
            // Temizlenen zone pozisyonlarına en yakın merkezi bul
            if let firstPos = flashPositions.first {
                let zoneCenter = zoneCenters.min(by: {
                    let d0 = abs($0.0 - firstPos.row) + abs($0.1 - firstPos.col)
                    let d1 = abs($1.0 - firstPos.row) + abs($1.1 - firstPos.col)
                    return d0 < d1
                })
                if let zc = zoneCenter {
                    particleBurst = ParticleBurstEvent(kind: .zoneBlast(
                        centerRow: zc.0, centerCol: zc.1,
                        radius: result.zonesCleared > 0 ? 60 : 40,
                        color: zc.2
                    ))
                }
            }
        } else if clearedRows > 0 || clearedCols > 0 {
            // Satır/Sütun temizleme partikülü
            particleBurst = ParticleBurstEvent(kind: .lineClear(
                positions: flashPositions,
                color: ThemeColors.neonCyan
            ))
        }

        // 2. Haptics & Sound
        haptic.play(.lineClear)
        AudioManager.shared.playSFX(.lineClear)

        // 3. Multiplier Calculation
        var characterMult = jokerMultBonus + run.clockworkBonus
        
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
                var triggerChance = 0.07
                if userEnv.unlockedUpgradeIDs.contains(MetaUpgrade.luckyDice.rawValue) {
                    triggerChance = 0.10
                }
                if Double.random(in: 0...1) < triggerChance {
                    characterMult += 9.0 
                    addPopup(text: "JACKPOT! ×10", color: ThemeColors.electricYellow)
                    haptic.play(.success)
                }
            case "neonwraith":
                if timer.ratio < 0.15 {
                    characterMult += 2.0 
                    addPopup(text: "WRAITH FURY!", color: ThemeColors.neonPurple)
                }
            default: break
            }
        }

        // 4. Chip Calculations (Blue/Lead Pills)
        var chipBonus = 1.0
        let blueCount = clearedCells.filter { if case .filled(let c) = $0.state { return c == .blue } else { return false } }.count
        let greenCount = clearedCells.filter { if case .filled(let c) = $0.state { return c == .green } else { return false } }.count
        
        if run.hasPerk("blue_pill") && blueCount > 0 {
            let tier = run.perkTier("blue_pill")
            chipBonus *= Double(tier + 1)
        }
        if run.hasPerk("lead_pill") && greenCount > 0 {
            let tier = run.perkTier("lead_pill")
            chipBonus *= Double(tier + 1)
        }
        
        // SYNERGY: RAINBOW DOSAGE
        if activeSynergies.contains(where: { $0.synergyName == "RAINBOW DOSAGE" }) && blueCount > 0 && greenCount > 0 {
            characterMult += 3.0
            addPopup(text: "RAINBOW DOSAGE! ×3", color: ThemeColors.neonPurple)
            haptic.play(.success)
        }
        
        if chipBonus > 1.0 {
            addPopup(text: "CHIP BOOST!", color: ThemeColors.neonCyan)
        }
        
        // 5. Final Score Execution
        let scoreResult = ScoreEngine.calculate(
            clearedCells: clearedCells,
            blockCellCount: max(blockCellCount, clearedCells.count),
            streak: run.streak,
            clearedRows: clearedRows,
            clearedCols: clearedCols,
            clearedZones: result.zonesCleared,
            jokerMultBonus: characterMult
        )

        // AAA: Detect Synergy Context for VFX
        let isGoldenFever = activeSynergies.contains(where: { $0.synergyName == "GOLDEN FEVER" }) && scoreResult.isFlush
        let isEternalCycle = activeSynergies.contains(where: { $0.synergyName == "ETERNAL CYCLE" }) && (result.rowsCleared + result.colsCleared >= 2)
        let isRainbowDosage = activeSynergies.contains(where: { $0.synergyName == "RAINBOW DOSAGE" }) && blueCount > 0 && greenCount > 0
        
        if isGoldenFever || isEternalCycle || isRainbowDosage {
            isSynergyClear = true
            // Mark cells for rainbow effect
            for i in 0..<result.clearedPositions.count {
                let pos = result.clearedPositions[i]
                board.grid[pos.row][pos.col].isSynergySubject = true
            }
        } else {
            isSynergyClear = false
        }

        lastScoreResult = scoreResult
        run.addScore(scoreResult.totalScore)

        // 6. UI & Perk Effects
        if scoreResult.clearCombo != ClearCombo.single {
            showBigComboLabel = scoreResult.clearCombo.label
            
            // Midas Touch
            if scoreResult.isFlush {
                let hasMidas = run.hasPerk("midas_touch")
                let hasFever = activeSynergies.contains(where: { $0.synergyName == "GOLDEN FEVER" })
                if hasFever {
                    run.gold += 15
                    UserEnvironment.shared.addGoldEarned(15)
                    AudioManager.shared.playSFX(.coin)
                    addPopup(text: "GOLDEN FEVER +15G", color: ThemeColors.electricYellow)
                } else if hasMidas {
                    run.gold += 5
                    UserEnvironment.shared.addGoldEarned(5)
                    AudioManager.shared.playSFX(.coin)
                    addPopup(text: "MIDAS TOUCH +5G", color: ThemeColors.electricYellow)
                }
            }
            
            // Recycler
            if scoreResult.clearedRows + scoreResult.clearedCols >= 2 {
                let hasRecycler = run.hasPerk("recycler")
                let hasCycle = activeSynergies.contains(where: { $0.synergyName == "ETERNAL CYCLE" })
                let chance = hasCycle ? 0.4 : (hasRecycler ? 0.2 : 0.0)
                if Double.random(in: 0...1) < chance {
                    refillBlockTray()
                    addPopup(text: "TRAY RECYCLED!", color: ThemeColors.neonCyan)
                    haptic.play(.success)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                if self.showBigComboLabel == scoreResult.clearCombo.label {
                    self.showBigComboLabel = nil
                }
            }
        }

        // 7. Feedback & Juice
        if scoreResult.isBigCombo {
            haptic.play(.flush)
            AudioManager.shared.playSFX(.flush)
            triggerJuice(intensity: 10, flash: true)
        } else if scoreResult.isFlush {
            haptic.play(.lineClear)
            AudioManager.shared.playSFX(.lineClear)
            triggerJuice(intensity: 6, flash: true)
        } else {
            haptic.play(.lineClear)
            AudioManager.shared.playSFX(.lineClear)
            triggerJuice(intensity: 2, flash: false)
        }
        
        AudioManager.shared.setIntensity(streak: run.streak, lowTime: timer.timeRemaining < 15)

        // 8. Time Bonus & Scaling Perks
        let bonus = ScoreEngine.timeBonusSeconds(clearCombo: scoreResult.clearCombo, isFlush: scoreResult.isFlush, streakCount: run.streak)
        var finalTimeBonus = bonus
        if activeCharacterId == "timebender" {
            finalTimeBonus *= 1.5
        }
        timer.addTime(finalTimeBonus)
        
        // Clockwork Scaling
        if run.hasPerk("clockwork") {
            let tier = run.perkTier("clockwork")
            let baseInc = finalTimeBonus * 0.1
            let scaledInc = baseInc * Double(tier)
            run.clockworkBonus = min(2.5, run.clockworkBonus + scaledInc)
        }

        // %50 hedef bonusu
        if !run.halfBonusGiven && run.scoreProgress >= 0.5 {
            run.halfBonusGiven = true
            timer.addTime(10)
            addPopup(text: "+10s BONUS!", color: ThemeColors.electricYellow)
        }
        
        // Echoes kayıt
        if scoreResult.totalScore > maxRoundScore {
            maxRoundScore = scoreResult.totalScore
        }

        // Score popup
        addPopup(
            text: "+\(scoreResult.totalScore)",
            color: scoreResult.isBigCombo ? ThemeColors.neonPurple : ThemeColors.neonCyan
        )
        // Tüm combo labellarını göster
        for label in scoreResult.allLabels {
            addPopup(text: label, color: ThemeColors.electricYellow)
        }

        // Hedef kontrolü
        checkRoundTarget()
        
        // --- NEW PHASE B PERKS (Last Resort) ---
        
        // Double Down
        if run.movesRemaining == 0 && scoreResult.totalScore > 0 && run.hasPerk("double_down") {
            run.movesUsed -= 3 // Geriye alarak +3 hamle kazandırır
            addPopup(text: "DOUBLE DOWN! +3 MOVES", color: ThemeColors.neonPurple)
            haptic.play(.success)
        }
        
        // Vampiric Core
        if run.hasPerk("vampiric_core") && scoreResult.totalScore > 0 {
            let lastMilestone = (run.currentScore - scoreResult.totalScore) / 5000
            let currentMilestone = run.currentScore / 5000
            if currentMilestone > lastMilestone {
                if Double.random(in: 0...1) < 0.25 { // %25 şans
                    run.gainLife()
                    addPopup(text: "VAMPIRIC LUCK! +1 ❤️", color: ThemeColors.neonPink)
                    haptic.play(.success)
                }
            }
        }
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
        
        // Charge was already consumed in activateOverdrive()
        OverdriveEngine.executeTargeted(pos: pos, tier: activeOverdriveTierForTargeting, charId: charId, vm: self)
        haptic.play(.flush)
        
        // Sadece UI bayrağını sıfırla — charge zaten activateOverdrive'da sıfırlandı
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
        stopEnemyLoop() // Düşman atak timer'larını durdur
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
        UserEnvironment.shared.addGoldEarned(goldAdded)
        if goldAdded > 0 {
            AudioManager.shared.playSFX(.coin)
        }
        UserEnvironment.shared.updateHighScore(run.currentScore)

        
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
            UserEnvironment.shared.addGoldEarned(150)
            AudioManager.shared.playSFX(.coin)
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

    // MARK: - VFX Control
    
    private func triggerJuice(intensity: CGFloat, flash: Bool) {
        shakeAmount = intensity
        if flash { flashOpacity = 0.6 }
        
        // Shake decay
        withAnimation(.spring(response: 0.1, dampingFraction: 0.2, blendDuration: 0)) {
            shakeAmount = 0
        }
        
        // Flash decay
        if flash {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.4)) {
                    self.flashOpacity = 0
                }
            }
        }
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
        // Check if boss was defeated
        if run.round.isBossRound && run.currentScore >= run.currentRoundTargetScore {
            UserEnvironment.shared.discoverBoss("boss_\(run.round.roundNumber)") 
        }
        
        // Save global stats
        UserEnvironment.shared.addGoldEarned(run.gold) // In practice, you might want a delta tracking
        
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
    
    func rotateBlockInTray(id: UUID) {
        guard let index = blockTray.firstIndex(where: { $0.id == id }) else { return }
        var block = blockTray[index]
        
        if block.isRotatable {
            block.rotate()
            blockTray[index] = block
            haptic.play(.buttonTap)
        }
    }
    
    func updateDrag(location: CGPoint, gridPosition: GridPosition?) {
        guard isDragging, let block = draggingBlock else { return }
        dragLocation = location
        
        // Throttle: ghost + hint güncellemesini saniyede max ~30 kez yap
        let now = Date()
        guard now.timeIntervalSince(lastGhostUpdate) >= ghostThrottleInterval else { return }
        lastGhostUpdate = now
        
        if let pos = gridPosition {
            board.updateGhost(block, at: pos)
            board.detectPotentialClears(block: block, at: pos)
        } else {
            board.clearGhost()
            board.hintPositions = []
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
        dragLocation = .zero
        board.clearGhost()
        board.hintPositions = [] // AAA: Reset hints
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
    
    // MARK: - Enemy Attack System
    
    func startEnemyAttackLoop() {
        // Önceki timer'ları temizle
        stopEnemyLoop()
        
        // Bu round için rastgele bir düşman seç
        enemy = EnemyState()
        enemy.currentAttack = EnemyAttackType.random(forRound: run.currentRound)
        
        let interval = EnemyAttackType.attackInterval(forRound: run.currentRound)
        enemy.nextAttackIn = interval
        
        // Ana atak timer'ı: her `interval` saniyede bir çalışır
        enemyAttackTimer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.phase == .playing else { return }
                self.triggerEnemyWarning()
            }
    }
    
    private func triggerEnemyWarning() {
        guard let attackType = enemy.currentAttack else { return }
        
        // 3sn uyarı aşaması
        showEnemyAttackWarning = true
        enemyCountdown = 3.0
        haptic.play(.timerWarning)
        
        // Geri sayım timer'ı (her 0.1sn)
        enemyWarningTimer?.cancel()
        enemyWarningTimer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.enemyCountdown -= 0.1
                if self.enemyCountdown <= 0 {
                    self.enemyWarningTimer?.cancel()
                    self.showEnemyAttackWarning = false
                    self.executeEnemyAttack(attackType)
                }
            }
    }
    
    private func executeEnemyAttack(_ attack: EnemyAttackType) {
        haptic.play(.error)
        AudioManager.shared.playSFX(.lineClear) // Düşman sesini özelleştirebilirsin
        
        switch attack {
        
        // --- SABOTAJ: Rastgele 5 dolu hücreyi sil ---
        case .gridSabotage:
            let occupied = board.allOccupiedPositions().shuffled().prefix(5)
            let positions = Array(occupied)
            if !positions.isEmpty {
                let result = board.removeCells(at: positions)
                clearFlashPositions = positions
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.clearFlashPositions = [] }
                addPopup(text: "💥 SABOTAJ! 5 BLOK SİLİNDİ", color: ThemeColors.neonPink)
            } else {
                addPopup(text: "💥 SABOTAJ: Grid Boş!", color: ThemeColors.textMuted)
            }
            
        // --- SON BLOK SİL: Son yerleştirilen bloğu yok et ---
        case .lastBlockErase:
            if !lastPlacedPositions.isEmpty {
                board.removeCells(at: lastPlacedPositions)
                clearFlashPositions = lastPlacedPositions
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.clearFlashPositions = [] }
                addPopup(text: "🗑️ SON BLOK SİLİNDİ!", color: ThemeColors.neonOrange)
                lastPlacedPositions = []
            } else {
                addPopup(text: "🗑️ Erase: Hedef Yok", color: ThemeColors.textMuted)
            }
            
        // --- KİLİTLEME: Tepsiyi 12sn kilitle ---
        case .trayLockdown:
            enemy.isTrayLocked = true
            enemy.trayLockRemainingTime = 12.0
            addPopup(text: "🔒 TEPSİ 12SN KİLİTLENDİ!", color: ThemeColors.electricYellow)
            
            // 12sn sonra kilit aç — geri sayımla
            let lockDuration = 12.0
            enemyTrayUnlockTimer?.cancel()
            enemyTrayUnlockTimer = Timer.publish(every: 1.0, on: .main, in: .common)
                .autoconnect()
                .scan(0) { count, _ in count + 1 }
                .sink { [weak self] elapsed in
                    guard let self = self else { return }
                    self.enemy.trayLockRemainingTime = lockDuration - Double(elapsed)
                    if elapsed >= Int(lockDuration) {
                        self.enemy.isTrayLocked = false
                        self.enemy.trayLockRemainingTime = 0
                        self.enemyTrayUnlockTimer?.cancel()
                        self.addPopup(text: "🔓 KİLİT AÇILDI!", color: ThemeColors.neonCyan)
                    }
                }
            
        // --- KARIŞTIRMA: Tüm tray bloklarını rastgele döndür ---
        case .scramble:
            for i in blockTray.indices {
                let rotationCount = Int.random(in: 1...3)
                for _ in 0..<rotationCount {
                    blockTray[i].rotate()
                }
            }
            addPopup(text: "🌀 TEPSI KARISTIRILDI!", color: ThemeColors.neonPurple)
            
        // --- LANET YAYICISI: 5 boş hücreye lanet yayar ---
        case .curseSpreader:
            board.applyCursedCells(count: 5)
            addPopup(text: "☠️ 5 LANET YERLEŞTİRİLDİ!", color: Color(red: 0.6, green: 0.1, blue: 0.8))
            
        // --- ZAMAN HIRSIZI: 20sn çal ---
        case .timeHeist:
            timer.addTime(-20)
            addPopup(text: "⏳ -20SN ÇALINDI!", color: ThemeColors.neonCyan)
            
        // --- AĞIR ZIRH: 4 adet ağır hücre yerleştir ---
        case .heavyArmor:
            let positions = board.allEmptyPositions().shuffled().prefix(4)
            for pos in positions {
                board.grid[pos.row][pos.col].state = .heavy(hits: 2)
            }
            addPopup(text: "🛡️ 4 AĞIR ENGEL KOYULDU!", color: ThemeColors.neonOrange)
        }
        
        // Sonraki atak türünü değiştir (her ataktan sonra farklı biri)
        let nextAttack = EnemyAttackType.allCases
            .filter { $0 != attack }
            .randomElement() ?? attack
        enemy.currentAttack = nextAttack
    }
    
    func stopEnemyLoop() {
        enemyAttackTimer?.cancel()
        enemyAttackTimer = nil
        enemyWarningTimer?.cancel()
        enemyWarningTimer = nil
        enemyTrayUnlockTimer?.cancel()
        enemyTrayUnlockTimer = nil
        enemy.isTrayLocked = false
        showEnemyAttackWarning = false
    }
}

