import SwiftUI
import Combine

class EventGameViewModel: ObservableObject {
    @Published var session:         EventSessionState = EventSessionState()
    @Published var showPerkChoice:  Bool = false
    @Published var currentBossAnim: BossIntentType? = nil
    @Published var leaderboard:     [EventLeaderboardEntry] = []
    @Published var isGameOver:      Bool = false
    @Published var gameOverScore:   Int = 0
    @Published var gameOverRank:    Int? = nil
    
    let config: EventConfig
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init(config: EventConfig) {
        self.config = config
        setupInitialState()
    }
    
    private func setupInitialState() {
        session.lives = 1
        session.maxLives = 1
        
        // Modifiers'a göre başlangıç konfigürasyonu
        applyModifiers(config.modifiers)
        
        // İlk perk havuzunu oluştur
        generateNextPerkChoice()
        
        // Leaderboard'u yükle (mock)
        loadMockLeaderboard()
    }
    
    // MARK: - Modifier Uygulama
    private func applyModifiers(_ modifiers: [EventModifier]) {
        for mod in modifiers {
            switch mod.type {
            case .blockSpeedMultiplier:
                // BlockDropEngine.shared.speedMultiplier = mod.value
                break
            case .goldPerLineClear:
                // ScoreEngine.shared.eventGoldBonus = Int(mod.value)
                break
            case .infiniteTime:
                // TimeManager.shared.isInfinite = true
                break
            case .extraLife:
                session.lives = Int(mod.value)
                session.maxLives = Int(mod.value)
            default:
                break
            }
        }
    }
    
    // MARK: - Round Management
    func onRoundComplete(score: Int, zonesCleaned: Int = 0, comboMax: Int = 0, goldEarned: Int = 0) {
        session.totalScore += score
        session.goldEarned += goldEarned
        session.metricValue += zonesCleaned // ranking metric'e bağlı olarak artar
        
        session.advanceRound()
        
        // Boss intent tetikle mi?
        triggerBossIntentIfNeeded()
        
        // Perk sunulacak mı? (her 5 roundda)
        if session.currentRound % 5 == 0 {
            generateNextPerkChoice()
            showPerkChoice = true
        }
        
        // Leaderboard güncelle
        submitScoreToLeaderboard()
    }
    
    func selectPerk(_ perk: EventPerk) {
        session.activePerks.append(perk)
        session.pendingPerkChoice = nil
        showPerkChoice = false
        applyPerkEffect(perk)
        HapticManager.shared.play(.success)
    }
    
    // MARK: - Boss Intent
    private func triggerBossIntentIfNeeded() {
        guard session.currentRound % config.boss.intentCycle == 0 else { return }
        guard session.currentRound > 0 else { return }
        
        let intentIndex = (session.currentRound / config.boss.intentCycle - 1) % config.boss.intents.count
        let intent = config.boss.intents[intentIndex]
        
        currentBossAnim = intent.type
        executeBossIntent(intent)
        HapticManager.shared.play(.heavy)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.currentBossAnim = nil
        }
    }
    
    private func executeBossIntent(_ intent: BossIntent) {
        // Game engine ile entegre edilecek
        // Şimdilik placeholder
        switch intent.type {
        case .lockCells:
            // BoardViewModel.shared.lockRandomCells(count: intent.value)
            print("Boss: \(intent.value) hücre kilitlendi")
        case .stealTime:
            // Infinite mode'da puan penaltısı
            session.totalScore = max(0, session.totalScore - (intent.value * 10))
        case .blockTray:
            // TrayViewModel.shared.lockFor(rounds: intent.value)
            print("Boss: Tray \(intent.value) round kilitlendi")
        case .addJunkRow:
            // BoardViewModel.shared.addJunkRow()
            print("Boss: Çöp satırı eklendi")
        case .shuffleBoard:
            // BoardViewModel.shared.shuffleRandomCells(count: intent.value)
            print("Boss: \(intent.value) blok karıştırıldı")
        case .invertControls:
            // TimeManager.shared.invertControlsFor(seconds: intent.value)
            print("Boss: Kontroller tersine çevrildi")
        }
    }
    
    // MARK: - Perk Management
    private func generateNextPerkChoice() {
        let available = eventPerkPool.filter { !session.activePerks.contains($0) }
        let shuffled = available.shuffled()
        
        // En az 3 perk seç
        let chosen = Array(shuffled.prefix(3))
        if chosen.count >= 3 {
            session.pendingPerkChoice = chosen
        } else {
            // Havuz bitti, tüm perkler aktif → tüm perkleri sıfırla ve tekrar seç
            session.activePerks.removeAll()
            session.pendingPerkChoice = Array(shuffled.prefix(3))
        }
    }
    
    private func applyPerkEffect(_ perk: EventPerk) {
        // PerkEngine.shared.activate(perk.id)
        print("Perk activated: \(perk.name)")
    }
    
    // MARK: - Game Over
    func loseLife() {
        session.lives -= 1
        if session.lives <= 0 {
            endGame()
        }
        HapticManager.shared.play(.timerWarning)
    }
    
    func endGame() {
        isGameOver = true
        gameOverScore = session.totalScore
        // gameOverRank hesapla (mock olarak)
        gameOverRank = leaderboard.firstIndex(where: { $0.score < session.totalScore }).map { $0 + 1 }
        submitFinalScoreToLeaderboard()
    }
    
    // MARK: - Leaderboard
    private func loadMockLeaderboard() {
        leaderboard = [
            EventLeaderboardEntry(id: "1", rank: 1, username: "ZenithMaster", score: 125000, metric: 45),
            EventLeaderboardEntry(id: "2", rank: 2, username: "CyberPhantom", score: 118500, metric: 42),
            EventLeaderboardEntry(id: "3", rank: 3, username: "NeonViper", score: 115200, metric: 40),
            EventLeaderboardEntry(id: "4", rank: 4, username: "GridTitan", score: 112800, metric: 38),
            EventLeaderboardEntry(id: "5", rank: 5, username: "ShadowNinja", score: 110000, metric: 35),
            EventLeaderboardEntry(id: "me", rank: 128, username: "Player", score: 45000, metric: 15),
        ]
    }
    
    private func submitScoreToLeaderboard() {
        // Backend: POST /api/events/:eventId/score
        // {
        //    deviceId: uuid,
        //    score: session.totalScore,
        //    metric: session.metricValue,
        //    round: session.currentRound
        // }
        print("Skor gönderildi: \(session.totalScore)")
    }
    
    private func submitFinalScoreToLeaderboard() {
        // Backend: POST /api/events/:eventId/finalize
        print("Final skor gönderildi: \(session.totalScore)")
    }
    
    func fetchLeaderboard() async {
        // Backend: GET /api/events/:eventId/leaderboard
        // Mock delay simülasyonu
        try? await Task.sleep(nanoseconds: 500_000_000)
        await MainActor.run {
            loadMockLeaderboard()
        }
    }
}
