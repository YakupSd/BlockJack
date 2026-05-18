//
//  FriendService.swift
//  Block-Jack
//

import Foundation
import Combine

// MARK: - Friend Service
class FriendService: NSObject {
    static let shared = FriendService()
    
    // API base URL (backend integration için)
    private let apiBase = "https://api.blockjack.io/api"
    
    /// Oyuncuyu ara
    func searchPlayer(username: String) async throws -> [SearchedPlayer] {
        // Mock: gerçek backend'e POST yapılacak
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Mock yanıt
        return [
            SearchedPlayer(id: "p1", username: username, avatarSlot: 1, globalRank: 45),
            SearchedPlayer(id: "p2", username: username + "_pro", avatarSlot: 2, globalRank: 128),
        ]
    }
    
    /// Arkadaşlık isteği gönder
    func sendFriendRequest(to playerID: String) async throws -> Bool {
        try await Task.sleep(nanoseconds: 300_000_000)
        return true
    }
    
    /// Arkadaşlık isteğini kabul et
    func acceptFriendRequest(from playerID: String) async throws -> Bool {
        try await Task.sleep(nanoseconds: 300_000_000)
        return true
    }
    
    /// Arkadaşlık isteğini reddet
    func declineFriendRequest(from playerID: String) async throws -> Bool {
        try await Task.sleep(nanoseconds: 300_000_000)
        return true
    }
    
    /// Oyuncuyu engelle
    func blockPlayer(_ playerID: String) async throws -> Bool {
        try await Task.sleep(nanoseconds: 200_000_000)
        return true
    }
    
    /// Arkadaş listesi getir
    func fetchFriends() async throws -> [FriendRelation] {
        try await Task.sleep(nanoseconds: 400_000_000)
        
        return [
            FriendRelation(friendID: "f1", username: "PIXEL_GOD", avatarSlot: 1, globalRank: 5, isOnline: true),
            FriendRelation(friendID: "f2", username: "NEON_KID", avatarSlot: 2, globalRank: 8, isOnline: true),
            FriendRelation(friendID: "f3", username: "BLOCKZILLA", avatarSlot: 3, globalRank: 12, isOnline: false),
        ]
    }
    
    /// Davet kodu doğrula ve arkadaş ekle
    func redeemInviteCode(_ code: String) async throws -> FriendRelation? {
        try await Task.sleep(nanoseconds: 400_000_000)
        
        // Mock: kodun geçerli olup olmadığını kontrol et
        if code.hasPrefix("BLK-") && code.count == 8 {
            return FriendRelation(
                friendID: UUID().uuidString,
                username: "InvitedFriend",
                avatarSlot: Int.random(in: 1...9)
            )
        }
        return nil
    }
}
