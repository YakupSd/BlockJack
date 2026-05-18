//
//  DuelViewModel.swift
//  Block-Jack
//

import Foundation
import Combine

// MARK: - Duel View Model
class DuelViewModel: ObservableObject {

    @Published var pendingDuels:   [DuelChallenge] = []  // gelen davetler
    @Published var activeDuels:    [DuelChallenge] = []  // oynanmayı bekleyen
    @Published var historyDuels:   [DuelChallenge] = []  // tamamlananlar
    @Published var isLoading:      Bool = false

    // ── Düello oluştur ─────────────────────────────────────────────────────
    func createDuel(
        opponentID: String,
        opponentName: String,
        stakeAmount: Int,
        seed: Int64 = DuelSeedEngine.generateSeed()
    ) async -> DuelChallenge? {
        isLoading = true
        defer { isLoading = false }
        
        // 1. Yeterli altın kontrolü (mock)
        // PlayerWallet.shared.gold >= stakeAmount
        
        await Task.sleep(500_000_000)
        
        let duel = DuelChallenge(
            challengerID: "current_player",
            challengerName: "SenAdi",
            challengedID: opponentID,
            challengedName: opponentName,
            seed: seed,
            stakeAmount: stakeAmount,
            status: .pending
        )
        
        activeDuels.append(duel)
        HapticManager.shared.play(.success)
        return duel
    }

    // ── Düello kabul et ────────────────────────────────────────────────────
    func acceptDuel(_ duelID: String) async {
        isLoading = true
        defer { isLoading = false }
        
        await Task.sleep(300_000_000)
        
        if let idx = pendingDuels.firstIndex(where: { $0.id == duelID }) {
            var duel = pendingDuels[idx]
            duel.status = .accepted
            activeDuels.append(duel)
            pendingDuels.remove(at: idx)
        }
        
        HapticManager.shared.play(.success)
    }

    // ── Düello reddet ──────────────────────────────────────────────────────
    func declineDuel(_ duelID: String) async {
        isLoading = true
        defer { isLoading = false }
        
        await Task.sleep(200_000_000)
        
        if let idx = pendingDuels.firstIndex(where: { $0.id == duelID }) {
            pendingDuels.remove(at: idx)
        }
        
        HapticManager.shared.play(.error)
    }

    // ── Oyun bitti, skor gönder ────────────────────────────────────────────
    func submitResult(duelID: String, stats: DuelStats, playerID: String) async {
        isLoading = true
        defer { isLoading = false }
        
        await Task.sleep(400_000_000)
        
        if let idx = activeDuels.firstIndex(where: { $0.id == duelID }) {
            var duel = activeDuels[idx]
            
            if playerID == duel.challengerID {
                duel.challengerScore = stats.finalScore
                duel.challengerStats = stats
                duel.status = .challengerDone
            } else {
                duel.challengedScore = stats.finalScore
                duel.challengedStats = stats
                duel.status = .challengedDone
            }
            
            // İkisi de oynadıysa sonuç belli
            if duel.challengerScore != nil && duel.challengedScore != nil {
                duel.status = .completed
                historyDuels.append(duel)
                activeDuels.remove(at: idx)
            } else {
                activeDuels[idx] = duel
            }
        }
        
        HapticManager.shared.play(.success)
    }

    func fetchAllDuels() async {
        isLoading = true
        defer { isLoading = false }
        
        await Task.sleep(400_000_000)
        
        // Mock data
        pendingDuels = [
            DuelChallenge(
                challengerID: "opp1",
                challengerName: "BLOCKZILLA",
                challengedID: "current_player",
                challengedName: "Siz",
                stakeAmount: 500,
                status: .pending
            )
        ]
        
        activeDuels = [
            DuelChallenge(
                challengerID: "current_player",
                challengerName: "Siz",
                challengedID: "opp2",
                challengedName: "NEON_KID",
                stakeAmount: 500,
                status: .accepted,
                challengerScore: 48_320
            )
        ]
        
        historyDuels = [
            DuelChallenge(
                challengerID: "current_player",
                challengerName: "Siz",
                challengedID: "opp3",
                challengedName: "PIXEL_GOD",
                stakeAmount: 500,
                status: .completed,
                challengerScore: 58_100,
                challengedScore: 41_500,
                challengerStats: DuelStats(finalScore: 58_100, linesCleared: 6, maxCombo: 12),
                challengedStats: DuelStats(finalScore: 41_500, linesCleared: 4, maxCombo: 8)
            )
        ]
    }
}
