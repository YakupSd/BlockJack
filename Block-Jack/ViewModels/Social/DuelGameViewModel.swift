//
//  DuelGameViewModel.swift
//  Block-Jack
//

import Foundation
import Combine

// MARK: - Duel Game View Model
/// GameViewModel'den BAĞIMSIZ — sadece seed'li blok üretimi için DuelSeedEngine kullanır
class DuelGameViewModel: ObservableObject {

    @Published var score:        Int = 0
    @Published var lives:        Int = 1  // Düellolarda 1 can
    @Published var isGameOver:   Bool = false
    @Published var stats:        DuelStats?
    @Published var timeRemaining: Double = 180.0 // 3 dakika

    let duel:        DuelChallenge
    let playerID:    String
    
    private var blockQueue: [BlockType] = []
    private var blockIndex: Int = 0
    private var startTime: Date = Date()
    private var timerCancellable: AnyCancellable?

    init(duel: DuelChallenge, playerID: String) {
        self.duel = duel
        self.playerID = playerID
        
        // Seed'den blok kuyruğu oluştur — 500 blok önceden üretilir
        self.blockQueue = DuelSeedEngine.blockSequence(seed: duel.seed, count: 500)
        
        startTimer()
    }

    // ── Timer başlat ───────────────────────────────────────────────────────
    private func startTimer() {
        startTime = Date()
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
    }

    private func updateTimer() {
        // Düello ve etkinliklerde süre kısıtlaması kaldırıldı (Endless Mode)
    }

    // ── Sonraki blok (seed'den) ────────────────────────────────────────────
    func nextBlock() -> BlockType {
        defer { blockIndex += 1 }
        return blockQueue[blockIndex % blockQueue.count]
    }

    // ── Skor artır ─────────────────────────────────────────────────────────
    func addScore(_ points: Int) {
        score += points
    }

    // ── Can kaybı ──────────────────────────────────────────────────────────
    func loseLife() {
        lives -= 1
        if lives <= 0 {
            onGameOver(reason: .lostLife)
        }
        HapticManager.shared.play(.heavy)
    }

    // ── Oyun bitti ─────────────────────────────────────────────────────────
    enum GameOverReason {
        case lostLife
        case timeout
        case userQuit
    }

    func onGameOver(reason: GameOverReason) {
        guard !isGameOver else { return }
        
        isGameOver = true
        timerCancellable?.cancel()
        
        let durationSeconds = Int(Date().timeIntervalSince(startTime))
        
        stats = DuelStats(
            finalScore: score,
            linesCleared: Int.random(in: 3...12),
            zonesCleared: Int.random(in: 0...4),
            maxCombo: Int.random(in: 3...15),
            blocksPlaced: Int.random(in: 20...80),
            goldEarned: Int.random(in: 50...200),
            roundsPlayed: Int.random(in: 5...20),
            durationSeconds: durationSeconds,
            usedCharacter: "cyber_ninja",
            perksActivated: []
        )

        HapticManager.shared.play(.heavy)
        
        // Backend'e skor gönder (mock)
        Task {
            await DuelViewModel().submitResult(
                duelID: duel.id,
                stats: stats!,
                playerID: playerID
            )
        }
    }

    deinit {
        timerCancellable?.cancel()
    }
}
