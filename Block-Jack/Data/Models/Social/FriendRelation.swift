//
//  FriendRelation.swift
//  Block-Jack
//

import Foundation

// MARK: - Friend Status
enum FriendStatus: String, Codable {
    case pending    // davet gönderildi, kabul bekleniyor
    case accepted   // arkadaş
    case blocked    // engellendi
}

// MARK: - Friend Relation Model
struct FriendRelation: Codable, Identifiable {
    let id:             String          // ilişki ID'si (UUID)
    let friendID:       String          // karşı tarafın PlayerID'si
    let username:       String
    let avatarSlot:     Int
    var status:         FriendStatus
    let globalRank:     Int?
    let lastSeenAt:     Date?
    let isOnline:       Bool
    let pendingDuelID:  String?         // bekleyen duello varsa ID'si
    
    // Mock initializer
    init(
        id: String = UUID().uuidString,
        friendID: String,
        username: String,
        avatarSlot: Int,
        status: FriendStatus = .accepted,
        globalRank: Int? = nil,
        lastSeenAt: Date? = nil,
        isOnline: Bool = false,
        pendingDuelID: String? = nil
    ) {
        self.id = id
        self.friendID = friendID
        self.username = username
        self.avatarSlot = avatarSlot
        self.status = status
        self.globalRank = globalRank
        self.lastSeenAt = lastSeenAt
        self.isOnline = isOnline
        self.pendingDuelID = pendingDuelID
    }
}

// MARK: - Searched Player (Arama Sonucu)
struct SearchedPlayer: Codable, Identifiable {
    let id:         String
    let username:   String
    let avatarSlot: Int
    let globalRank: Int?
    var isFriend:   Bool
    
    init(
        id: String = UUID().uuidString,
        username: String,
        avatarSlot: Int,
        globalRank: Int? = nil,
        isFriend: Bool = false
    ) {
        self.id = id
        self.username = username
        self.avatarSlot = avatarSlot
        self.globalRank = globalRank
        self.isFriend = isFriend
    }
}
