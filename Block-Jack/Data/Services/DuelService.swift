//
//  DuelService.swift
//  Block-Jack
//

import Foundation

// MARK: - Duel Service
class DuelService: NSObject {
    static let shared = DuelService()
    
    private let apiBase = "https://api.blockjack.io/api"
    
    /// Yeni düello oluştur
    func createDuel(
        opponentID: String,
        stakeAmount: Int,
        seed: Int64 = DuelSeedEngine.generateSeed()
    ) async throws -> DuelChallenge {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        return DuelChallenge(
            challengerID: "current_player",
            challengerName: "SenAdi",
            challengedID: opponentID,
            challengedName: "OpponentName",
            seed: seed,
            stakeAmount: stakeAmount,
            status: .pending
        )
    }
    
    /// Düello isteğini kabul et
    func acceptDuel(_ duelID: String) async throws -> DuelChallenge? {
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Mock: accepted status'e güncelle
        return DuelChallenge(
            id: duelID,
            challengerID: "opp1",
            challengerName: "Rakip",
            challengedID: "player",
            challengedName: "Siz",
            stakeAmount: 500,
            status: .accepted
        )
    }
    
    /// Düello isteğini reddet
    func declineDuel(_ duelID: String) async throws -> Bool {
        try await Task.sleep(nanoseconds: 200_000_000)
        return true
    }
    
    /// Tüm düelloları getir (pending + active + history)
    func fetchAllDuels() async throws -> (pending: [DuelChallenge], active: [DuelChallenge], history: [DuelChallenge]) {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let pending = [
            DuelChallenge(
                challengerID: "opp1",
                challengerName: "BLOCKZILLA",
                challengedID: "player",
                challengedName: "Siz",
                stakeAmount: 500,
                status: .pending
            )
        ]
        
        let active = [
            DuelChallenge(
                challengerID: "player",
                challengerName: "Siz",
                challengedID: "opp2",
                challengedName: "NEON_KID",
                stakeAmount: 500,
                status: .accepted,
                challengerScore: 48_320
            )
        ]
        
        let history = [
            DuelChallenge(
                challengerID: "player",
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
        
        return (pending, active, history)
    }
    
    /// Oyun sonucu gönder
    func submitDuelScore(
        duelID: String,
        playerID: String,
        stats: DuelStats
    ) async throws -> DuelChallenge? {
        try await Task.sleep(nanoseconds: 400_000_000)
        
        // Mock: skor kaydedildi
        print("Duello \(duelID) - Oyuncu \(playerID) - Skor: \(stats.finalScore)")
        return nil
    }
    
    /// Düello detayını getir
    func fetchDuelDetail(_ duelID: String) async throws -> DuelChallenge? {
        try await Task.sleep(nanoseconds: 200_000_000)
        
        return DuelChallenge(
            id: duelID,
            challengerID: "player",
            challengerName: "Siz",
            challengedID: "opp",
            challengedName: "Rakip",
            stakeAmount: 500,
            status: .accepted
        )
    }
}
