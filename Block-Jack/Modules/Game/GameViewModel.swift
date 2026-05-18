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
    case shopping
    case gameOver
}

// MARK: - GameViewModel
final class GameViewModel: ObservableObject {

    // MARK: - Sub-ViewModels & Services
    let board = BoardViewModel()
    let timer = TimerManager()

    // MARK: - Orchestrator Managers
    lazy var scoreManager = ScoreManager(vm: self)
    lazy var abilityManager = AbilityManager(vm: self)
    lazy var boardController = BoardController(vm: self)
    let notificationManager = NotificationManager()

    var currentMultiplier: Double {
        // Streak bonus logic: Lucky Clover affects the limit
        let luckyCloverTier = run.perkTier("lucky_clover")
        let cloverBonus = PerkUpgradeRegistry.tierData(for: .luckyClover, tier: luckyCloverTier).effectValue
        let baseStreakLimit = 8.0
        let finalStreakLimit = baseStreakLimit + (luckyCloverTier > 0 ? cloverBonus * 0.2 : 0) // Scaling limit slightly
        
        let streakBonus = min(Double(run.streak / 2) * 0.75, finalStreakLimit)
        
        // Timed multiplier bonus
        let timedBonus = multiplierRemainingTime > 0 ? (timedMultiplier - 1.0) : 0.0
        
        return 1.0 + streakBonus + jokerMultBonus + timedBonus + run.clockworkBonus
    }

    // MARK: - Published State
    @Published var phase: GamePhase = .menu
    @Published var comboCount: Int = 0
    @Published var run: RunState = RunState()
    
    // --- Frenzy Mode ---
    @Published var frenzyTimeRemaining: Double = 0
    var isFrenzyActive: Bool { frenzyTimeRemaining > 0 }
    var frenzyCancellable: AnyCancellable?
    
    // --- Pending Gold (Save-Scumming Protection) ---
    @Published var pendingGold: Int = 0
    @Published var blockTray: [GameBlock] = []
    @Published var selectedBlock: GameBlock? = nil
    @Published var lastScoreResult: ScoreResult? = nil
    @Published var isDeadlocked: Bool = false
    @Published var canRefreshTray: Bool = false
    
    // --- Timed Multiplier ---
    @Published var timedMultiplier: Double = 1.0
    @Published var multiplierRemainingTime: Double = 0
    
    // MARK: - Visual Effects State
    @Published var clearFlashPositions: [GridPosition] = []  // 3.3: Neon flaş efekti için
    @Published var showBigComboLabel: String? = nil          // 3.4: DOUBLE CLEAR! vs ekranı
    
    // MARK: - Dragging State
    @Published var isDragging: Bool = false
    // dragLocation: @Published DEĞİL — her frame güncellenir, @Published olursa tüm view yeniden render olur (lag!)
    // GameView'da @State dragPosition ile overlay render edilir.
    var dragLocation: CGPoint = .zero
    @Published var draggingBlock: GameBlock? = nil {
        didSet {
            // Tactical Lens: blok çekilirken en iyi yerleşim hücrelerini vurgula.
            // Perk yoksa hep boş bırak (gereksiz hesaplama yapma).
            guard run.hasPerk("tactical_lens") else {
                if !board.bestPlacementCells.isEmpty { board.bestPlacementCells = [] }
                return
            }
            // No-op skip: aynı blok tekrar atanırsa O(13×13×cells) aramayı
            // yeniden yapma — @Published didSet değer aynı olsa bile tetiklenir.
            // Böylece drag sürecinde tray seçim değişmediyse hesap sıfır.
            if oldValue?.id == draggingBlock?.id { return }
            board.updateBestPlacementHint(for: draggingBlock)
        }
    }
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
    var pendingTargetedOverdriveConsumption: Bool = false
    
    // Character Specific State
    @Published var isWraithActive: Bool = false    // Neon Wraith skill
    @Published var isPhantomVisible: Bool = true   // Boss Phantom pulse
    @Published var showTutorial: Bool = false      // 4: Tutorial Overlay
    @Published var activeSynergies: [PerkSynergy] = [] // Phase 4 Synergy Cache
    @Published var bossIntent: String? = nil           // AAA: Boss Warning Intent
    @Published var isSynergyClear: Bool = false        // AAA: Rainbow VFX Flag
    var bossIntentCooldown: Int = 3            // Moves until intent clears
    
    var lastPlacedBlockType: BlockType? = nil // Architect passive için
    var jokerMultBonus: Double = 0.0   // Joker bonusu — OverdriveEngine erişir
    var maxRoundScore: Int = 0 // Echoes perk için

    // MARK: - Debug (Pacing / Balance)
    var debugZoneBlastsThisRound: Int = 0
    var debugLineClearsThisRound: Int = 0

    // MARK: - Pre-run loadout state
    var pendingStartingBombBlock: Bool = false

    // MARK: - Boss variety
    var bossArchetype: BossArchetype? = nil
    var bossPhase: Int = 1
    var isContractChallenge: Bool = false

    // MARK: - Karakter Ephemeral State (startRound'da sıfırlanır)
    var blockEClearsThisRound: Int = 0   // BLOCK-E pasif: max 3/round cap
    var timebenderFreezeMoves: Int = 0           // TimeBender active: timer donuk kalan hamle
    var alchemistDoubleCountMoves: Int = 0       // Alchemist active: skoru 2× ile çıkaran hamleler
    var ghostPhantomMultBonus: Double = 0.0      // Ghost active T2: tek atımlık handleClear bonusu
    var neonWraithActiveBoost: Int = 0           // NeonWraith active: sonraki N clear'de ekstra +2 mult
    
    // MARK: - Enemy Attack System
    @Published var enemy: EnemyState = EnemyState()
    @Published var showEnemyAttackWarning: Bool = false  // Uyarı overlay göster
    @Published var enemyCountdown: Double = 3.0          // Uyarı geri sayım
    var enemyAttackTimer: AnyCancellable? = nil
    var enemyWarningTimer: AnyCancellable? = nil
    var enemyTrayUnlockTimer: AnyCancellable? = nil
    var endlessEscalationTimer: AnyCancellable? = nil
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
    var lastGhostUpdate: Date = .distantPast
    let ghostThrottleInterval: TimeInterval = 0.033
    
    // Leaderboard
    var runStartSessionTime: Date = Date()
    @Published var leaderboardSubmitResult: ScoreSubmitResponse? = nil

    // MARK: - Private
    var cancellables = Set<AnyCancellable>()
    let haptic = HapticManager.shared
    let userEnv: UserEnvironment
    // jokerMultBonus aşağıda (sat 68) tanımlandı - OverdriveEngine erişimi için internal

    let activeSlotId: Int
    let nodeType: NodeType?
    var eventConfig: EventConfig?  // Event mode configuration (modifiers, boss, etc.)

    var currentNodeType: NodeType {
        nodeType ?? .normal
    }

    init(slotId: Int, nodeType: NodeType? = nil, eventConfig: EventConfig? = nil, userEnv: UserEnvironment = UserEnvironment.shared) {
        self.activeSlotId = slotId
        self.nodeType = nodeType
        self.eventConfig = eventConfig
        self.userEnv = userEnv
        
        // Timer değişikliklerini ViewModel'e yansıt (UI update için)
        timer.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
            
        bindTimer()
        abilityManager.startPhantomPulse()
        abilityManager.startPassiveLoop() // 3.6: Character passive loops
        scoreManager.startMultiplierTimer() // 1s tick for timed multiplier
        
        // Load initial state from save slot
        if let slot = SaveManager.shared.slots.first(where: { $0.id == slotId }), !slot.isEmpty {
            self.run.currentRound = slot.currentRound
            self.run.currentScore = slot.currentScore
            
            let isSameNode = (slot.activeBattleNodeId == userEnv.pendingMapNodeId) && (userEnv.pendingMapNodeId != nil)

            if isSameNode {
                var loadedValidGrid = false
                if let savedGrid = slot.grid {
                    // Dimension validation: Ensure saved grid matches current BoardViewModel.size (12x12)
                    if savedGrid.count == BoardViewModel.size && (savedGrid.first?.count ?? 0) == BoardViewModel.size {
                        self.board.grid = savedGrid
                        loadedValidGrid = true
                    } else {
                        // Mismatch: Reset grid to prevent Index out of range crashes
                        self.board.resetGrid()
                        addPopup(text: "SYNC: GRID RESET", color: ThemeColors.neonOrange)
                    }
                }
                
                if loadedValidGrid {
                    if let savedTray = slot.trayBlocks {
                        self.blockTray = savedTray
                    }
                    self.setupRoundTargetAndModifiers()
                    let totalTime = self.calculateInitialTime()
                    self.timer.setup(seconds: totalTime)
                    if let savedTime = slot.timeLeft {
                        self.timer.timeRemaining = savedTime
                    }
                    self.phase = .playing
                }
            } else {
                self.board.resetGrid()
            }
            
            self.run.activePassivePerks = slot.activePassivePerks
            self.run.inventory = slot.inventory
            self.run.gold = slot.gold
            self.run.lives = slot.lives
            
            // Scoring V3 Persistence
            self.run.streak = slot.streak
            self.run.overkillCarryover = slot.overkillCarryover
            self.run.clockworkBonus = slot.clockworkBonus
            
            // PHASE 11 FIX: World level scaling should follow the current map's chapter, 
            // not the global maximum unlocked level. Otherwise replaying Stage 1 
            // becomes as hard as the latest unlocked stage.
            if let map = slot.currentChapterMap {
                self.run.worldLevel = map.chapterIndex
            } else {
                self.run.worldLevel = max(1, slot.unlockedWorldLevel)
            }
            
            // Cüzdan senkronizasyonu: meta UI (Dashboard/Shop) UserEnvironment.gold'u
            // okuyor; slot aktif olduğunda iki havuzu eşitle.
            if UserEnvironment.shared.activeSlotId == slotId {
                UserEnvironment.shared.gold = slot.gold
            }
            
            // Wide Load check
            if run.activePassivePerks.contains(where: { $0.id == "wide_load" }) {
                run.maxTraySlots = 4
            }
        }
        
        // MARK: - Event Mode Setup
        if let eventConfig = eventConfig {
            applyEventModifiers(eventConfig.modifiers)
            setupEventBossConfiguration(eventConfig.boss)
            if eventConfig.modifiers.contains(where: { $0.type == .infiniteTime }) {
                timer.isInfiniteMode = true
            }
        }
    }
    
    // MARK: - Event Mode Integration
    private func applyEventModifiers(_ modifiers: [EventModifier]) {
        for modifier in modifiers {
            switch modifier.type {
            case .blockSpeedMultiplier:
                // BoardViewModel'e block drop hızını pass et
                // BoardController'a multiplier apply edecek
                run.blockSpeedMultiplier = modifier.value
                
            case .goldPerLineClear:
                // Scoring bonus — her line clear'da bonus altın
                run.eventGoldBonus = Int(modifier.value)
                
            case .infiniteTime:
                // Timer sonsuz mode
                timer.isInfiniteMode = true
                
            case .extraLife:
                // İlave can
                run.lives = Int(modifier.value)
                
            default:
                break
            }
        }
    }
    
    private func setupEventBossConfiguration(_ boss: EventBoss) {
        // Event boss'u normal boss'un yerine geç
        // Intent cycle'ı set et
        bossIntentCooldown = boss.intentCycle
    }
    
    /// Run içinde altın kazanımlarını tek yerden geçirmek için yardımcı.
    /// Hem run state'i hem slot.gold'u (UserEnvironment.gold ile birlikte) senkron tutar.
    /// Gold Magnet benzeri sonradan eklenecek multiplier'ları da burada uygulayabiliriz.
    func addRunGold(_ amount: Int) {
        guard amount != 0 else { return }
        // Save-scumming protection: Add to pending instead of run.gold immediately
        pendingGold += amount
        // Yalnızca lifetime istatistiğini artır
        UserEnvironment.shared.addGoldEarned(max(0, amount))
    }

    // MARK: - Game Control

    func startNewRun() {
        runStartSessionTime = Date()
        run = RunState()
        board.resetGrid()
        startRound()
    }

    func setupRoundTargetAndModifiers() {
        let worldLevel = run.worldLevel

        if nodeType == .boss {
            // Boss her zaman kendi modifier'ını taşır
            run.activeModifier = currentBoss.modifier
            bossArchetype = BossRegistry.shared.archetype(for: run.worldLevel)
            bossPhase = 1
            run.currentRoundTargetScore = RoundData.makeTarget(for: run.currentRound, worldLevel: worldLevel)

            // Boss Contract (risk/ödül): sadece bu boss fight için
            let contractId = SaveManager.shared.slots.first(where: { $0.id == activeSlotId })?.activeBossContractId ?? "safe"
            if contractId == BossContract.risky.rawValue {
                run.currentRoundTargetScore = Int(Double(run.currentRoundTargetScore) * 1.35)
                isContractChallenge = true
                addPopup(text: "CONTRACT: RISKY", color: ThemeColors.neonPink)
            } else {
                isContractChallenge = false
            }
            // Tek seferlik: tüket
            SaveManager.shared.setBossContract(slotId: activeSlotId, contractId: nil)
        } else if nodeType == .challenge {
            // Challenge: opsiyonel yüksek risk — her zaman modifier + daha sert target + daha az süre.
            run.activeModifier = BossModifier.allCases.randomElement()
            let baseTarget = RoundData.makeTarget(for: run.currentRound, worldLevel: worldLevel)
            run.currentRoundTargetScore = Int(Double(baseTarget) * 2.0)
        } else if nodeType == .elite {
            // Elite: W5+'da rastgele modifier, aksi halde nil
            if worldLevel >= 5 {
                run.activeModifier = BossModifier.allCases.randomElement()
            } else {
                run.activeModifier = nil
            }
            let baseTarget = RoundData.makeTarget(for: run.currentRound, worldLevel: worldLevel)
            run.currentRoundTargetScore = Int(Double(baseTarget) * 1.5) // Elite: %50 daha zor
        } else {
            // Normal round
            if worldLevel >= 15 {
                // W15+: her normal round bir modifier al (rotasyon)
                let all = BossModifier.allCases
                let idx = abs(run.currentRound) % all.count
                run.activeModifier = all[idx]
            } else if worldLevel >= 10 {
                // W10–14: normal round'larda %50 modifier şansı
                if Double.random(in: 0...1) < 0.5 {
                    run.activeModifier = BossModifier.allCases.randomElement()
                } else {
                    run.activeModifier = nil
                }
            } else {
                run.activeModifier = nil
            }
            run.currentRoundTargetScore = RoundData.makeTarget(for: run.currentRound, worldLevel: worldLevel)
        }
    }

    func startRound() {
        abilityManager.applyMetaPerks()
        board.resetGrid() // FORCE RESET (Reset Bug Fix)

        self.setupRoundTargetAndModifiers()
        
        // Her round başlangıcında hamle ve streak sayaçlarını sıfırla
        run.movesUsed = 0
        run.streak = 0
        run.currentScore = 0
        run.halfBonusGiven = false
        pendingGold = 0 // Reset pending gold for new round/retry
        frenzyTimeRemaining = 0 // Reset frenzy
        
        // --- SECTOR CHECKPOINT SYNC ---
        // Eğer round 1'den büyükse ve bir checkpoint dönüşü yapılıyorsa
        // target score'u o round'un zorluğuna göre tekrar hesapla.
        run.currentRoundTargetScore = RoundData.makeTarget(for: run.currentRound, worldLevel: run.worldLevel)

        // Debug counters
        debugZoneBlastsThisRound = 0
        debugLineClearsThisRound = 0

        // Karakter per-round ephemeral state sıfırlama
        blockEClearsThisRound = 0
        timebenderFreezeMoves = 0
        alchemistDoubleCountMoves = 0
        ghostPhantomMultBonus = 0.0
        neonWraithActiveBoost = 0

        // Düello ve Etkinlikler için zorunlu kısıtlamalar (Tek round, 1 can, Sınırsız süre)
        if let config = eventConfig {
            run.lives = 1
            run.maxLives = 1
            timer.isInfiniteMode = true
            
            // Özel güçleri / perkleri iptal et
            run.activePassivePerks.removeAll()
            run.inventory.removeAll()
            
            // Oyun başlar başlamaz event'i markala — uygulamayı kapatıp açsa da tekrar oynayamaz.
            UserEnvironment.shared.markEventStarted(config.id)
        }

        // Gold Upgrade: Start Bonus (Head Start)
        // Round başında skor bonusu ekle.
        let startBonusLevel = userEnv.goldLevel(for: .startBonus)
        if startBonusLevel > 0 {
            let bonus = startBonusLevel * 50
            addScore(bonus)
            addPopup(text: "+\(bonus) START BONUS", color: ThemeColors.electricYellow)
        }

        // Gold Upgrade: Gold Magnet
        // Her round başı ekstra altın.
        let goldMagnetLevel = userEnv.goldLevel(for: .goldMagnet)
        if goldMagnetLevel > 0 {
            let goldBonus = goldMagnetLevel * 10
            addRunGold(goldBonus)
            addPopup(text: "+\(goldBonus) GOLD MAGNET", color: ThemeColors.electricYellow)
        }
        
        let initialTime = calculateInitialTime()
        
        timer.setup(seconds: initialTime)
        
        // Phase 4: Synergy Calculation
        let oldSynergies = Set(activeSynergies.map { $0.synergyName })
        activeSynergies = PerkEngine.evaluateSynergies(perks: run.activePassivePerks)
        let newSynergies = activeSynergies.filter { !oldSynergies.contains($0.synergyName) }
        
        for (index, synergy) in newSynergies.enumerated() {
            let delay = Double(index) * 0.4
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.addPopup(text: "SYNERGY: \(synergy.synergyName.uppercased())", color: ThemeColors.neonPurple)
                HapticManager.shared.play(.success)
                AudioManager.shared.playSFX(.synergy)
            }
        }
        
        // Phase 4: Overkill Carryover Check
        if run.overkillCarryover > 0 {
            run.currentScore += run.overkillCarryover
            addPopup(text: "OVERKILL +\(run.overkillCarryover)", color: ThemeColors.electricYellow)
            run.overkillCarryover = 0
        }
        
        run.currentRotationUses = run.maxRotationUses // Reset Sculptor charges
        
        maxRoundScore = 0 // Sıfırla (Echoes Perk)
        
        if blockTray.isEmpty {
            boardController.refillBlockTray()
        }
        
        boardController.checkDeadlock()
        
        if nodeType == .boss {
            phase = .bossDialogue
            timer.pause()
            // Boss dramatik girişi: dialogue açılmadan önce SFX ve güçlü haptic.
            AudioManager.shared.playSFX(.bossEntry)
            haptic.play(.heavy)
        } else {
            phase = .playing
            timer.start()
            
            // Düşman atak sistemi başlat
            boardController.startEnemyAttackLoop()

            // Non-boss round için modifier initial mechanic (W10+ çeşitlenme).
            // Boss node'unda bu iş startBossFightAfterDialogue'da yapılıyor.
            if let modifier = run.activeModifier {
                addPopup(text: "\(modifier.title): \(modifier.description)", color: ThemeColors.neonPurple)
                switch modifier {
                case .glitch:
                    let worldScale = max(0, run.worldLevel - 1) / 2
                    board.applyGlitch(count: 2 + worldScale)
                case .weight:
                    // Non-boss için biraz daha hafif: W10:2, W15:3, W20:4
                    let heavyCount = min(4, 2 + max(0, run.worldLevel - 10) / 4)
                    board.applyHeavy(count: heavyCount)
                default: break
                }
            }
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
                let slot = SaveManager.shared.slots.first(where: { $0.id == activeSlotId })
                let metaTier = slot?.perkLevels[pid] ?? 1
                run.activePassivePerks.append(starting.toPassivePerk(lang: userEnv.language, tier: metaTier))
                // Koleksiyon keşfi: starting perk seçildiğinde de aç.
                userEnv.discoverPerk(pid)
            }
        }
        
        // Golden Stamp: Target score reduction
        if run.hasPerk("golden_stamp") {
            let tier = run.perkTier("golden_stamp")
            let reduction = PerkUpgradeRegistry.tierData(for: .goldenStamp, tier: tier).effectValue
            run.currentRoundTargetScore = Int(Double(run.currentRoundTargetScore) * (1.0 - reduction))
            addPopup(text: "STAMPED LV.\(tier)! -\(Int(reduction*100))% TARGET", color: ThemeColors.electricYellow)
        }
        
        // Wide Load: Extra tray slot
        if run.hasPerk("wide_load") {
            run.maxTraySlots = 4
        }
        
        // SYNERGY: GOLDEN FEVER (Penalty part)
        if activeSynergies.contains(where: { $0.synergyName == SynergyID.goldenFever }) {
            run.currentRoundTargetScore = Int(Double(run.currentRoundTargetScore) * 1.2)
        }
        
        // Static Charge (hayalet perk bağlantısı): round başında 3 + (tier-1) boş
        // hücreye static modifier yerleştir. Bunları temizleyince overdrive patlar.
        if run.hasPerk("static_charge") {
            let tier = run.perkTier("static_charge")
            board.applyStaticCells(count: 3 + max(0, tier - 1))
        }
        
        // Phantom Siphon: round başında 2 + (tier-1) boş hücreye phantom modifier
        // yerleştir. Üzerine blok koyunca tier × 2sn süre bonusu verir.
        if run.hasPerk("phantom_siphon") {
            let tier = run.perkTier("phantom_siphon")
            board.applyPhantomCells(count: 2 + max(0, tier - 1))
        }
        
        // Best placement hint sıfırla — yeni round, yeni tavsiye.
        board.bestPlacementCells = []
    }

    func addPerk(_ perk: PassivePerk) {
        abilityManager.addPerk(perk)
    }

    func pauseGame() {
        guard phase == .playing else { return }
        timer.pause()
        phase = .paused
    }

    /// Oyuncu öldüğünde veya pes ettiğinde sektörü en başından başlatır (Checkpoint).
    /// Formül: ((Round - 1) / 5) * 5 + 1
    func resetToSectorStart() {
        let current = run.currentRound
        let sectorStart = ((current - 1) / 5) * 5 + 1
        
        run.currentRound = sectorStart
        run.currentScore = 0
        run.movesUsed = 0
        run.streak = 0
        
        runStartSessionTime = Date()
        leaderboardSubmitResult = nil
        
        // NEW: Clear map progress so the player starts from the beginning of the map
        run.completedNodeIds.removeAll()
        UserEnvironment.shared.pendingMapNodeId = nil
        SaveManager.shared.resetMapProgress(slotId: activeSlotId)
        
        // Grid ve state temizliği
        board.resetGrid()
        blockTray = []
        boardController.refillBlockTray()
        
        // Round'u başlat
        startRound()
        
        // Kaydı güncelle ki çıkıp girince de checkpointten başlasın
        saveGameState()
    }

    // MARK: - Helpers

    func calculateInitialTime() -> Double {
        var initialTime = run.round.timeLimit
        if nodeType == .elite {
            initialTime = max(120.0, initialTime - 30.0) // Elite: -30sn, minimum 120sn
        } else if nodeType == .challenge {
            initialTime = max(105.0, initialTime - 45.0) // Challenge: daha kısa süre, minimum 105sn
        }
        
        // Kalıcı Geliştirme: Iron Will kontrolü
        if userEnv.unlockedUpgradeIDs.contains(MetaUpgrade.ironWill.rawValue) {
            initialTime += 10.0
        }

        // Starting Item (Loadout) — 1 kez / run
        if !run.startingItemApplied {
            let id = UserEnvironment.shared.runConfig?.startingItemId ?? ""
            switch id {
            case "time_plus30":
                initialTime += 30.0
            default:
                break
            }
        }
        return initialTime
    }

    func shouldShowTutorial() -> Bool {      
        return run.currentRound == 1 && !userEnv.tutorialCompleted
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
        boardController.tryPlace(block: block, at: position)
    }

    // MARK: - Scoring Helpers
    
    func addScore(_ points: Int) {
        guard points > 0 else { return }
        run.addScore(points)
        
        // 1. Check Win Condition (Round Target)
        scoreManager.checkRoundTarget()
        
        // 2. Update Boss Phase
        updateBossPhaseIfNeeded()
        
        // 3. Track Max Round Score (for Echoes)
        if run.currentScore > maxRoundScore {
            maxRoundScore = run.currentScore
        }
    }

    func updateBossPhaseIfNeeded() {
        guard currentNodeType == .boss else { return }
        let p: Int = {
            let prog = run.scoreProgress
            if prog >= 0.66 { return 3 }
            if prog >= 0.33 { return 2 }
            return 1
        }()
        bossPhase = p
        if phase == .playing {
            startEnemyAttackLoop()
            addPopup(text: "BOSS PHASE \(bossPhase)", color: ThemeColors.nodeBoss)
        }
    }

    func handleClear(result: BoardViewModel.ClearResult, blockCellCount: Int = 4, neighbors: Int = 0, cluster: Int = 0) {
        scoreManager.handleClear(result: result, blockCellCount: blockCellCount, neighbors: neighbors, cluster: cluster)
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
        abilityManager.activateOverdrive()
    }
    
    func applyTargetedOverdrive(at pos: GridPosition) {
        abilityManager.applyTargetedOverdrive(at: pos)
    }

    // MARK: - Round Logic

    func checkRoundTarget() {
        scoreManager.checkRoundTarget()
    }

    func checkMoveLimit() {
        scoreManager.checkMoveLimit()
    }

    func completeRound() {
        scoreManager.completeRound()
    }

    
    
    
    func startBossRound() {
        // Called from BossIntroOverlay "Savaş" button -> Moves to Dialogue
        phase = .bossDialogue
        timer.pause()
    }
    
    func startBossFightAfterDialogue() {
        // Called from BossDialogueOverlay when dialogue ends.
        // IMPORTANT: startRound() is NOT called here — it was already called when we
        // entered the boss node (which set phase = .bossDialogue). Calling it again
        // would re-enter the dialogue phase (infinite loop) AND reset run-state that
        // was just configured (tray, target, overkill carryover, timer, etc.).
        // Instead we just apply the initial boss mechanics and flip to .playing.

        // activeModifier is set in startRound() when nodeType == .boss, so prefer that
        // over run.round.modifier (which is nil for non-%5 rounds like world level 1).
        if let modifier = run.activeModifier {
            addPopup(text: "BOSS FIGHT: \(modifier.title)", color: ThemeColors.neonPink)
            
            // Apply initial boss mechanics
            switch modifier {
            case .glitch:
                // Scale glitch cells with world level (min 3)
                let worldScale = max(0, run.worldLevel - 1) / 2
                board.applyGlitch(count: 3 + worldScale)
            case .weight:
                // Weight: N heavy hücresi seed. W5:3 → W20:8.
                let heavyCount = min(8, 3 + max(0, run.worldLevel - 5) / 3)
                board.applyHeavy(count: heavyCount)
            default: break
            }
        }

        phase = .playing
        timer.start()
        startEnemyAttackLoop()
        
        AudioManager.shared.playMusic(.boss)
        haptic.play(.heavy)
    }

    // MARK: - Perk Interactions
    
    func rotateSelectedBlock() {
        abilityManager.rotateSelectedBlock()
    }

    // MARK: - Consumable Interactions
    
    func useItem(_ item: ConsumableItem) {
        abilityManager.useItem(item)
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
        slot.gold = run.gold
        slot.lastSaved = Date()
        slot.activeBattleNodeId = userEnv.pendingMapNodeId
        
        // Scoring V3 Persistence
        slot.streak = run.streak
        slot.overkillCarryover = run.overkillCarryover
        slot.clockworkBonus = run.clockworkBonus
        
        if let index = SaveManager.shared.slots.firstIndex(where: { $0.id == activeSlotId }) {
            SaveManager.shared.slots[index] = slot
        }
        
        // Boss discovery artık roundComplete anında yapılıyor (anında koleksiyon açılması için).
        
        // Cüzdan ve slot gold tek havuza bağlı (setGold içinde UserEnvironment.gold
        // da yazılır). Burada sadece diske yaz.
        SaveManager.shared.setGold(slotId: activeSlotId, total: run.gold)
        SaveManager.shared.updateSave(slotId: activeSlotId, score: run.currentScore, round: run.currentRound)
    }

    func syncPerksWithSlot() {
        guard let slot = SaveManager.shared.slots.first(where: { $0.id == activeSlotId }) else { return }
        
        // Slot'taki güncel aktif perkleri RunState'e aktar
        self.run.activePassivePerks = slot.activePassivePerks
        
        // Sinerjileri tekrar hesapla
        self.activeSynergies = PerkEngine.evaluateSynergies(perks: self.run.activePassivePerks)
        self.run.activeSynergies = self.activeSynergies
        
        // ÖNEMLİ: Eğer Golden Stamp gibi target etkileyen bir perk güncellendiyse
        // hedef skoru anında revize et (oyun devam ederken etki etmesi için).
        setupRoundTargetAndModifiers()
        
        // Wide Load gibi slot kapasitesini değiştiren perkler için:
        if run.hasPerk("wide_load") {
            let tier = run.perkTier("wide_load")
            run.maxTraySlots = Int(PerkUpgradeRegistry.tierData(for: .wideLoad, tier: tier).effectValue)
        }
        
        objectWillChange.send()
    }

    // MARK: - Timed Multiplier Logic
    
    private func startMultiplierTimer() {
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.phase == .playing else { return }
                if self.multiplierRemainingTime > 0 {
                    self.multiplierRemainingTime -= 1.0
                    if self.multiplierRemainingTime <= 0 {
                        self.timedMultiplier = 1.0
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func triggerTimedMultiplier(for result: BoardViewModel.ClearResult) {
        let totalCleared = result.rowsCleared + result.colsCleared + result.zonesCleared
        guard totalCleared > 0 else { return }
        
        if multiplierRemainingTime <= 0 {
            timedMultiplier = 1.25
        } else {
            // Stacking bonus
            timedMultiplier = min(3.0, timedMultiplier + 0.05)
        }
        multiplierRemainingTime = 15.0
        
        // Visual feedback
        addPopup(text: String(format: "MULT ×%.2f", timedMultiplier), color: ThemeColors.electricYellow)
    }

    // MARK: - Deadlock & Refresh
    
    func checkDeadlock() {
        boardController.checkDeadlock()
    }
    
    func refreshTrayWithCost() {
        boardController.refreshTrayWithCost()
    }

    func triggerGameOver() {
        // --- RACE CONDITION PREVENTION ---
        // Eğer zaten gameOver phase'indeysek veya başka bir özel phase'deysek
        // (örn. Retry basıldıktan hemen sonra eski bir timer sinyali geldiyse) işlemi iptal et.
        guard phase == .playing || phase == .bossDialogue || phase == .bossIntro else { return }
        
        // --- PREVENTION LAYER (Synergies & Perks) ---
        if run.undyingRageActive { return } // Do not die while immortal

        // 1. SYNERGY: UNDYING RAGE (One-time save with 5s immortality)
        let hasUndyingRage = activeSynergies.contains(where: { $0.synergyName == SynergyID.undyingRage })
        if hasUndyingRage && run.lastStandUses == 0 {
            run.lastStandUses += 1 
            run.undyingRageActive = true
            timer.pause()
            addPopup(text: "IMMORTAL", color: ThemeColors.neonPurple)
            haptic.play(.heavy)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                self?.run.undyingRageActive = false
                self?.timer.resume()
                self?.addPopup(text: "IMMORTALITY ENDED", color: ThemeColors.neonPink)
            }
            return
        }

        // 2. PERK: Last Stand (Basic save)
        if run.hasPerk("last_stand") {
            let tier = run.perkTier("last_stand")
            if run.lastStandUses < tier {
                run.lastStandUses += 1
                addPopup(text: "LAST STAND LV.\(tier)! (\(run.lastStandUses)/\(tier))", color: ThemeColors.neonCyan)
                haptic.play(.heavy)
                
                // Perform the actual save mechanics
                board.resetGrid()
                refillBlockTray()
                if timer.timeRemaining <= 0 {
                    timer.addTime(30.0)
                }
                if phase != .playing {
                    timer.resume()
                }
                
                return
            }
        }

        // --- ACTUAL GAME OVER ---
        timer.stop()
        stopEnemyLoop()
        haptic.play(.gameOver)
        AudioManager.shared.playSFX(.gameOver)
        
        saveGameState()
        
        // EVENT / DUEL: Final puanı kaydet (rage-quit dahil, en son puan geçerli)
        if let config = eventConfig {
            UserEnvironment.shared.saveEventScore(config.id, score: run.currentScore)
        }
        
        phase = .gameOver // Triggets GameOverOverlay
        
        UserEnvironment.shared.recordRun(
            score: run.currentScore,
            worldLevelReached: max(1, run.worldLevel)
        )

        // Slot bazlı run history / best
        let cid = SaveManager.shared.slots.first(where: { $0.id == activeSlotId })?.characterId
            ?? UserEnvironment.shared.selectedCharacterID
        SaveManager.shared.recordSlotRun(
            slotId: activeSlotId,
            score: run.currentScore,
            worldLevelReached: max(1, run.worldLevel),
            characterId: cid,
            perksCount: run.activePassivePerks.count,
            wasTrial: UserEnvironment.shared.wasTrialRunUsedToday(for: cid)
        )
        
        // Phase 8: Skor Submit (Leaderboard)
        let durationSeconds = Int(Date().timeIntervalSince(runStartSessionTime))
        let finalScore = run.currentScore
        let finalWorld = run.worldLevel
        let finalRound = run.currentRound
        
        Task { @MainActor in
            let request = ScoreSubmitRequest(
                deviceID: DeviceIdentifier.deviceID,
                username: UserEnvironment.shared.username,
                countryCode: UserEnvironment.shared.playerCountryCode,
                score: finalScore,
                chapterReached: UInt8(min(255, max(1, finalWorld))),
                roundReached: UInt8(min(255, max(1, finalRound))),
                characterID: UInt8(min(255, GameCharacter.roster.firstIndex(where: { $0.id == cid }) ?? 0)),
                durationSeconds: Int16(min(32767, durationSeconds))
            )
            let result = await LeaderboardAPIService.shared.submitScore(request)
            if case .success(let response) = result {
                self.leaderboardSubmitResult = response
                LeaderboardAPIService.shared.invalidateCache()
            }
        }
    }

    // MARK: - Block Tray

    func refillBlockTray() {
        boardController.refillBlockTray()
    }

    // MARK: - Drag Handling
    
    func rotateBlockInTray(id: UUID) {
        abilityManager.rotateBlockInTray(id: id)
    }
    
    // MARK: - Block Discard / Reroll (Phase 11.5)
    
    func discardBlockFromTray(blockId: UUID) {
        boardController.discardBlockFromTray(blockId: blockId.uuidString)
    }
    
    func rerollBlockInTray(blockId: UUID) {
        boardController.rerollBlockInTray(blockId: blockId.uuidString)
    }
    
    func updateDrag(location: CGPoint, gridPosition: GridPosition?) {
        boardController.updateDrag(location: location, gridPosition: gridPosition)
    }
    
    func handleDragEnd() {
        boardController.handleDragEnd()
    }
    
    func handleOverdriveDrop() {
        boardController.handleOverdriveDrop()
    }

    func cancelTargetedOverdrive() {
        abilityManager.cancelTargetedOverdrive()
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
    


    // MARK: - Score Popup Helper (Notification System)

    func addPopup(text: String, color: Color, position: CGPoint = CGPoint(x: 187, y: 300)) {
        // Determine notification type based on text content
        var type: NotificationType
        var title = text
        var subtitle = ""
        var value: String? = nil
        
        // Extract value from text (e.g., "+9.0", "+500")
        if let plusRange = text.range(of: " +") {
            let potentialValue = String(text[plusRange.lowerBound...])
            value = potentialValue.trimmingCharacters(in: .whitespaces)
            title = String(text[..<plusRange.lowerBound])
        }
        
        if text.contains("FRENZY") {
            type = .frenzy(text)
            subtitle = "Çarpan aktif"
        } else if text.contains("STREAK") || text.contains("Streak") {
            type = .streak(text)
        } else if text.contains("GRADIENT") || text.contains("FLUSH") || text.contains("MULANK") {
            type = .pattern(text)
        } else if text.contains("OVERDRIVE") || text.contains("TIER") && text.contains("READY") {
            type = .overdrive(text)
        } else if text.contains("BOSS") || text.contains("PHASE") {
            type = .system(text)
        } else if text.contains("PERK") || text.contains("OVERKILL") || text.contains("SYNERGY") || text.contains("MOMENTUM") {
            type = .perk(text)
        } else if text.contains("ACHIEVEMENT") || text.contains("QUEST") || text.contains("DOUBLE COUNT") {
            type = .achievement(text)
        } else if text.contains("!") && value != nil {
            type = .pattern(text)
        } else {
            type = .system(text)
        }
        
        // TEK enqueue çağrısı — çift bildirim bug'ı düzeltildi
        let notification = GameNotification(
            type: type,
            title: title,
            subtitle: subtitle,
            value: value,
            color: color
        )
        notificationManager.enqueue(notification)
    }
    
    /// Direct enqueue for new notification API
    func enqueueNotification(_ notification: GameNotification) {
        notificationManager.enqueue(notification)
    }
    
    // MARK: - Enemy Ability Notification
    
    func showEnemyAbility(title: String, description: String, color: Color) {
        let alert = EnemyAbilityAlert(title: title, description: description, color: color)
        notificationManager.addEnemyAbility(alert)
    }
    
    // MARK: - Clear Analysis Helpers
    

    
    // MARK: - Enemy Attack System
    
    func startEnemyAttackLoop() {
        boardController.startEnemyAttackLoop()
    }
    
    func stopEnemyLoop() {
        boardController.stopEnemyLoop()
    }



    deinit {
        cancellables.forEach { $0.cancel() }
        frenzyCancellable?.cancel()
        stopEnemyLoop()
    }
}

