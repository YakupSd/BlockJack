//
//  DuelChallenge.swift
//  Block-Jack
//

import Foundation

// MARK: - Duel Status
enum DuelStatus: String, Codable {
    case pending        // davet gönderildi, kabul bekleniyor
    case accepted       // kabul edildi, iki taraf da oynayabilir
    case challengerDone // meydan okuyan oynadı, rakip sırada
    case challengedDone // rakip oynadı, meydan okuyan sırada
    case completed      // ikisi de oynadı, sonuç belli
    case declined       // reddedildi
    case expired        // 48 saat geçti
    case cancelled      // iptal edildi
}

// MARK: - Duel Challenge Model
struct DuelChallenge: Codable, Identifiable {
    let id:             String          // UUID
    let challengerID:   String          // meydan okuyan PlayerID
    let challengerName: String
    let challengedID:   String          // meydan okunan PlayerID
    let challengedName: String

    let seed:           Int64           // her iki oyuncu için aynı blok dizisi
    let stakeAmount:    Int             // bahis altın miktarı (her iki taraftan kesilir)
    var status:         DuelStatus
    let createdAt:      Date
    let expiresAt:      Date            // 48 saat sonra otomatik iptal

    // Skorlar — oynadıktan sonra dolar
    var challengerScore:  Int?
    var challengedScore:  Int?
    var challengerStats:  DuelStats?
    var challengedStats:  DuelStats?

    var winnerID: String? {
        guard let cs = challengerScore, let cd = challengedScore else { return nil }
        return cs >= cd ? challengerID : challengedID
    }

    var loserID: String? {
        guard let cs = challengerScore, let cd = challengedScore else { return nil }
        return cs < cd ? challengerID : challengedID
    }

    func myScore(playerID: String) -> Int? {
        playerID == challengerID ? challengerScore : challengedScore
    }

    func myStats(playerID: String) -> DuelStats? {
        playerID == challengerID ? challengerStats : challengedStats
    }

    // Mock initializer
    init(
        id: String = UUID().uuidString,
        challengerID: String,
        challengerName: String,
        challengedID: String,
        challengedName: String,
        seed: Int64 = Int64.random(in: 100_000...999_999_999),
        stakeAmount: Int,
        status: DuelStatus = .pending,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        challengerScore: Int? = nil,
        challengedScore: Int? = nil,
        challengerStats: DuelStats? = nil,
        challengedStats: DuelStats? = nil
    ) {
        self.id = id
        self.challengerID = challengerID
        self.challengerName = challengerName
        self.challengedID = challengedID
        self.challengedName = challengedName
        self.seed = seed
        self.stakeAmount = stakeAmount
        self.status = status
        self.createdAt = createdAt
        self.expiresAt = expiresAt ?? Calendar.current.date(byAdding: .hour, value: 48, to: createdAt) ?? Date()
        self.challengerScore = challengerScore
        self.challengedScore = challengedScore
        self.challengerStats = challengerStats
        self.challengedStats = challengedStats
    }
}
