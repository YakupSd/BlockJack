//
//  LeaderboardViewModel.swift
//  Block-Jack
//
//  Leaderboard ekranının state yönetimi.
//  3 scope: Global / Ülke / Benim Sıram
//  API çağrıları, cache, loading/error state.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Leaderboard Scope

enum LeaderboardScope: String, CaseIterable {
    case global = "GLOBAL"
    case local  = "ÜLKE"
    case me     = "BEN"
    
    var icon: String {
        switch self {
        case .global: return "globe"
        case .local:  return "flag.fill"
        case .me:     return "person.fill"
        }
    }
    
    func displayName(for lang: AppLanguage) -> String {
        switch self {
        case .global: return lang == .turkish ? "GLOBAL"  : "GLOBAL"
        case .local:  return lang == .turkish ? "ÜLKE"    : "COUNTRY"
        case .me:     return lang == .turkish ? "BEN"     : "ME"
        }
    }
}

// MARK: - View State

enum LeaderboardState {
    case idle
    case loading
    case loaded
    case empty
    case error(String)
    case offline
}

// MARK: - ViewModel

class LeaderboardViewModel: ObservableObject {
    
    @Published var scope: LeaderboardScope = .global
    @Published var state: LeaderboardState = .idle
    
    @Published var globalEntries: [LeaderboardEntry] = []
    @Published var localEntries: [LeaderboardEntry] = []
    @Published var myRank: MyRankResponse? = nil
    
    /// Skor gönderimi sonucu (run bittiğinde gösterilir)
    @Published var lastSubmitResult: ScoreSubmitResponse? = nil
    @Published var isSubmitting: Bool = false
    
    private let api = LeaderboardAPIService.shared
    
    // MARK: - Fetch
    
    @MainActor
    func fetchCurrentScope(forceRefresh: Bool = false) async {
        state = .loading
        if forceRefresh { api.invalidateCache() }
        
        switch scope {
        case .global:
            await fetchGlobal(forceRefresh: forceRefresh)
        case .local:
            await fetchLocal(forceRefresh: forceRefresh)
        case .me:
            await fetchMe()
        }
    }
    
    @MainActor
    func fetchGlobal(forceRefresh: Bool = false) async {
        state = .loading
        if forceRefresh { api.invalidateCache() }
        let result = await api.fetchGlobalLeaderboard(limit: 100) // Max 100 global
        
        switch result {
        case .success(let entries):
            globalEntries = entries
            state = entries.isEmpty ? .empty : .loaded
        case .failure(let error):
            handleError(error)
        }
    }
    
    @MainActor
    func fetchLocal(forceRefresh: Bool = false) async {
        state = .loading
        if forceRefresh { api.invalidateCache() }
        let result = await api.fetchLocalLeaderboard(limit: 50) // Max 50 yerel
        
        switch result {
        case .success(let entries):
            localEntries = entries
            state = entries.isEmpty ? .empty : .loaded
        case .failure(let error):
            handleError(error)
        }
    }
    
    @MainActor
    func fetchMe() async {
        state = .loading
        let result = await api.fetchMyRank()
        
        switch result {
        case .success(let rank):
            myRank = rank
            state = .loaded
        case .failure(let error):
            handleError(error)
        }
    }
    
    // MARK: - Submit Score
    
    @MainActor
    func submitScore(
        username: String,
        score: Int,
        worldLevel: Int,
        currentRound: Int,
        characterId: String,
        durationSeconds: Int
    ) async {
        isSubmitting = true
        
        // CharacterID → roster index
        let charIndex = GameCharacter.roster.firstIndex(where: { $0.id == characterId }) ?? 0
        
        let request = ScoreSubmitRequest(
            deviceID: DeviceIdentifier.deviceID,
            username: username,
            countryCode: currentCountryCode(),
            score: score,
            chapterReached: UInt8(min(255, worldLevel)),
            roundReached: UInt8(min(255, currentRound)),
            characterID: UInt8(min(255, charIndex)),
            durationSeconds: Int16(min(32767, durationSeconds))
        )
        
        let result = await api.submitScore(request)
        
        switch result {
        case .success(let response):
            lastSubmitResult = response
            // Cache'i invalide et — yeni skor var
            api.invalidateCache()
        case .failure:
            // Offline queue'ya eklendi (API service içinde)
            lastSubmitResult = nil
        }
        
        isSubmitting = false
    }
    
    @MainActor
    func ensurePlayerExistsOnServer(username: String) async {
        let allSlots = SaveManager.shared.slots
        let bestSlot = allSlots.max(by: { $0.bestScore < $1.bestScore })
        
        let score = bestSlot?.bestScore ?? 0
        let worldLevel = bestSlot?.bestWorldLevel ?? 1
        let cid = bestSlot?.characterId ?? "rookie"
        let charIndex = GameCharacter.roster.firstIndex(where: { $0.id == cid }) ?? 0
        
        let request = ScoreSubmitRequest(
            deviceID: DeviceIdentifier.deviceID,
            username: username,
            countryCode: currentCountryCode(),
            score: score,
            chapterReached: UInt8(min(255, max(1, worldLevel))),
            roundReached: 1, // Geçmişteki tam round bilinmediği için varsayılan 1
            characterID: UInt8(min(255, charIndex)),
            durationSeconds: 120 // Geçmişteki süre bilinmediği için varsayılan 2 dakika
        )
        
        _ = await api.submitScore(request)
        api.invalidateCache()
    }
    
    // MARK: - Register
    
    func registerPlayer(fullName: String, email: String, phone: String = "") async -> Result<Void, LeaderboardAPIError> {
        let request = RegisterPlayerRequest(
            deviceID: DeviceIdentifier.deviceID,
            fullName: fullName,
            email: email,
            phone: phone
        )
        
        let result = await api.registerPlayer(request)
        switch result {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Transfer Guest Scores
    
    /// Misafir oyuncu tarafından kaydedilen tüm skorları sunucuya gönder.
    /// Register olurken çağrılarak, guest skorlarının yeni kayıtlı hesaba associate edilmesi sağlanır.
    @MainActor
    func transferGuestScoresToServer(username: String, userEnv: UserEnvironment) async {
        let topScores = userEnv.topScores
        guard !topScores.isEmpty else { return }
        
        isSubmitting = true
        defer { isSubmitting = false }
        
        for entry in topScores {
            let charIndex = GameCharacter.roster.firstIndex(where: { $0.id == entry.characterID }) ?? 0
            
            let request = ScoreSubmitRequest(
                deviceID: DeviceIdentifier.deviceID,
                username: username,
                countryCode: currentCountryCode(),
                score: entry.score,
                chapterReached: UInt8(min(255, max(1, entry.worldLevelReached))),
                roundReached: 1,
                characterID: UInt8(min(255, charIndex)),
                durationSeconds: 120
            )
            
            _ = await api.submitScore(request)
        }
        
        api.invalidateCache()
    }
    
    // MARK: - Check Username Availability
    
    /// Kullanıcı adının uygun olup olmadığını kontrol et (sunucuya sorarak)
    func checkUsernameAvailable(_ username: String) async -> Result<Bool, LeaderboardAPIError> {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure(.badRequest("Kullanıcı adı boş olamaz"))
        }
        
        // Leaderboard global'de sorgu yap - eğer bulunursa unavailable
        let result = await api.fetchGlobalLeaderboard(limit: 100)
        switch result {
        case .success(let entries):
            let exists = entries.contains { $0.username.lowercased() == username.lowercased() }
            if exists {
                return .failure(.conflict("Bu kullanıcı adı zaten kullanılıyor"))
            }
            return .success(true)
        case .failure:
            // Offline ise local check yap — strict olmayız
            return .success(true)
        }
    }
    
    // MARK: - Update Player
    
    func updatePlayer(username: String? = nil, countryCode: String? = nil, avatarSlot: UInt8? = nil) async -> Result<Void, LeaderboardAPIError> {
        let request = UpdatePlayerRequest(
            deviceID: DeviceIdentifier.deviceID,
            username: username,
            countryCode: countryCode,
            avatarSlot: avatarSlot
        )
        
        let result = await api.updatePlayer(request)
        switch result {
        case .success:
            api.invalidateCache()
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Delete
    
    @MainActor
    func deleteAllData() async -> Result<Void, LeaderboardAPIError> {
        let result = await api.deletePlayer()
        switch result {
        case .success:
            globalEntries = []
            localEntries = []
            myRank = nil
            api.invalidateCache()
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
    
    @MainActor
    func deleteScoresOnly() async -> Result<Void, LeaderboardAPIError> {
        let result = await api.deleteScores()
        switch result {
        case .success:
            api.invalidateCache()
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Refresh
    
    func refresh() async {
        api.invalidateCache()
        await fetchCurrentScope()
    }
    
    // MARK: - Private
    
    @MainActor
    private func handleError(_ error: LeaderboardAPIError) {
        switch error {
        case .noConnection:
            state = .offline
        default:
            state = .error(error.localizedDescription ?? "Bilinmeyen hata")
        }
    }
    
    private func currentCountryCode() -> String {
        Locale.current.region?.identifier ?? "XX"
    }
}
