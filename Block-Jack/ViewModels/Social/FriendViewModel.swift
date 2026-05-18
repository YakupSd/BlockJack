//
//  FriendViewModel.swift
//  Block-Jack
//

import Foundation
import Combine

// MARK: - Friend View Model
class FriendViewModel: ObservableObject {

    @Published var friends:        [FriendRelation] = []
    @Published var pendingInvites: [FriendRelation] = [] // gelen arkadaşlık istekleri
    @Published var searchResults:  [SearchedPlayer] = []
    @Published var myInviteCode:   FriendInvite?
    @Published var isSearching:    Bool = false
    @Published var isLoading:      Bool = false

    // ── Arkadaş ara ────────────────────────────────────────────────────────
    func searchPlayer(username: String) async {
        guard username.count >= 3 else {
            searchResults = []
            return
        }
        isSearching = true
        defer { isSearching = false }
        
        // Mock: backend çağrısı yerine mock data
        await Task.sleep(500_000_000) // 0.5 saniye gecikme
        
        searchResults = [
            SearchedPlayer(id: "p1", username: username, avatarSlot: 1, globalRank: 45),
            SearchedPlayer(id: "p2", username: username + "_pro", avatarSlot: 2, globalRank: 128),
            SearchedPlayer(id: "p3", username: "rival_" + username, avatarSlot: 3, globalRank: 203),
        ]
    }

    // ── Arkadaşlık isteği gönder ──────────────────────────────────────────
    func sendRequest(to playerID: String) async {
        isLoading = true
        defer { isLoading = false }
        
        // Mock: arkadaş pending duruma ekle
        await Task.sleep(300_000_000)
        
        let newFriend = FriendRelation(
            friendID: playerID,
            username: "NewFriend",
            avatarSlot: Int.random(in: 1...9),
            status: .pending
        )
        friends.append(newFriend)
        HapticManager.shared.play(.success)
    }

    // ── Kod veya link ile davet et ────────────────────────────────────────
    func generateInviteCode() async {
        isLoading = true
        defer { isLoading = false }
        
        await Task.sleep(200_000_000)
        
        myInviteCode = FriendInvite(
            code: FriendInvite.generateCode(),
            ownerID: "current_player_id"
        )
    }

    func shareInviteLink() {
        guard let invite = myInviteCode else { return }
        let message = "Block-Jack'e katıl ve benimle düello yap! \(invite.deepLink)"
        
        // UIActivityViewController ile paylaş — burada placeholder
        print("Paylaşılacak link: \(message)")
        HapticManager.shared.play(.buttonTap)
    }

    // ── Deep link ile arkadaş ekle ────────────────────────────────────────
    func handleInviteCode(_ code: String) async {
        isLoading = true
        defer { isLoading = false }
        
        await Task.sleep(300_000_000)
        
        // Mock: başarı
        HapticManager.shared.play(.success)
        print("Davet kodu kabul edildi: \(code)")
    }

    // ── Arkadaşlık isteği kabul/ret ───────────────────────────────────────
    func acceptRequest(from playerID: String) async {
        isLoading = true
        defer { isLoading = false }
        
        await Task.sleep(200_000_000)
        
        if let idx = pendingInvites.firstIndex(where: { $0.friendID == playerID }) {
            var friend = pendingInvites[idx]
            friend.status = .accepted
            friends.append(friend)
            pendingInvites.remove(at: idx)
        }
        HapticManager.shared.play(.success)
    }

    func declineRequest(from playerID: String) async {
        isLoading = true
        defer { isLoading = false }
        
        await Task.sleep(200_000_000)
        
        pendingInvites.removeAll { $0.friendID == playerID }
        HapticManager.shared.play(.error)
    }

    // ── Engelle ───────────────────────────────────────────────────────────
    func blockPlayer(_ playerID: String) async {
        isLoading = true
        defer { isLoading = false }
        
        await Task.sleep(200_000_000)
        
        friends.removeAll { $0.friendID == playerID }
        HapticManager.shared.play(.heavy)
    }

    func fetchFriends() async {
        isLoading = true
        defer { isLoading = false }
        
        await Task.sleep(300_000_000)
        
        // Mock data
        friends = [
            FriendRelation(friendID: "f1", username: "PIXEL_GOD", avatarSlot: 1, globalRank: 5, isOnline: true),
            FriendRelation(friendID: "f2", username: "NEON_KID", avatarSlot: 2, globalRank: 8, isOnline: true),
            FriendRelation(friendID: "f3", username: "BLOCKZILLA", avatarSlot: 3, globalRank: 12, isOnline: false),
            FriendRelation(friendID: "f4", username: "GRID_RIDER", avatarSlot: 4, globalRank: 25, isOnline: false),
        ]
        
        pendingInvites = [
            FriendRelation(friendID: "p1", username: "NewPlayer", avatarSlot: 5, status: .pending, isOnline: false),
        ]
    }
}
