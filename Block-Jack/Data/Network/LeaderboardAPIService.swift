//
//  LeaderboardAPIService.swift
//  Block-Jack
//
//  URLSession async/await tabanlı HTTP client.
//  Backend: LeaderboardController.cs → 9 endpoint
//  Auth: "Authorization: Token <token>"
//  DeviceID: "X-Device-ID: <uuid>" (me, delete endpoint'leri)
//

import Foundation
import UIKit

// MARK: - API Configuration

enum LeaderboardAPIConfig {
    /// Backend base URL (APISecrets'ten okunur)
    static let baseURL = APISecrets.leaderboardBaseURL
    
    /// Token auth (APISecrets'ten okunur)
    static let token = APISecrets.leaderboardToken
    
    /// Timeout
    static let timeoutInterval: TimeInterval = 15
}

// MARK: - API Service

class LeaderboardAPIService {
    
    static let shared = LeaderboardAPIService()
    
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    /// In-memory cache (60sn TTL)
    private var globalCache: (entries: [LeaderboardEntry], fetchedAt: Date)?
    private var localCache: (country: String, entries: [LeaderboardEntry], fetchedAt: Date)?
    private let cacheTTL: TimeInterval = 60
    
    /// Offline skor kuyruğu
    private let offlineQueueKey = "pendingScoreSubmissions"
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = LeaderboardAPIConfig.timeoutInterval
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - 1. Submit Score (POST /submit)
    
    /// Skor gönder. Başarısız olursa offline kuyruğa ekler.
    @discardableResult
    func submitScore(_ request: ScoreSubmitRequest) async -> Result<ScoreSubmitResponse, LeaderboardAPIError> {
        let result: Result<ScoreSubmitResponse, LeaderboardAPIError> = await post(
            path: "/submit",
            body: request
        )
        
        // Başarısızlık → offline queue
        if case .failure = result {
            saveToOfflineQueue(request)
        }
        
        return result
    }
    
    // MARK: - 2. Global Leaderboard (GET /global?limit=N)
    
    func fetchGlobalLeaderboard(limit: Int = 100) async -> Result<[LeaderboardEntry], LeaderboardAPIError> {
        // Cache kontrolü
        if let cached = globalCache,
           Date().timeIntervalSince(cached.fetchedAt) < cacheTTL {
            return .success(cached.entries)
        }
        
        let result: Result<[LeaderboardEntry], LeaderboardAPIError> = await get(
            path: "/global",
            queryItems: [URLQueryItem(name: "limit", value: "\(limit)")]
        )
        
        // Cache güncelle
        if case .success(let entries) = result {
            globalCache = (entries, Date())
        }
        
        return result
    }
    
    // MARK: - 3. Local Leaderboard (GET /local?country=XX&limit=N)
    
    func fetchLocalLeaderboard(country: String? = nil, limit: Int = 50) async -> Result<[LeaderboardEntry], LeaderboardAPIError> {
        let cc = country ?? currentCountryCode()
        
        // Cache kontrolü
        if let cached = localCache,
           cached.country == cc,
           Date().timeIntervalSince(cached.fetchedAt) < cacheTTL {
            return .success(cached.entries)
        }
        
        let result: Result<[LeaderboardEntry], LeaderboardAPIError> = await get(
            path: "/local",
            queryItems: [
                URLQueryItem(name: "country", value: cc),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        )
        
        if case .success(let entries) = result {
            localCache = (cc, entries, Date())
        }
        
        return result
    }
    
    // MARK: - 4. My Rank (GET /me)
    
    func fetchMyRank() async -> Result<MyRankResponse, LeaderboardAPIError> {
        return await get(
            path: "/me",
            queryItems: [],
            includeDeviceHeader: true
        )
    }
    
    // MARK: - 5. Register (POST /register)
    
    func registerPlayer(_ request: RegisterPlayerRequest) async -> Result<GenericAPIResponse, LeaderboardAPIError> {
        return await post(path: "/register", body: request)
    }
    
    // MARK: - 6. Update Player (PUT /update-player)
    
    func updatePlayer(_ request: UpdatePlayerRequest) async -> Result<GenericAPIResponse, LeaderboardAPIError> {
        return await put(path: "/update-player", body: request)
    }
    
    // MARK: - 7. Update Registration (PUT /update-registration)
    
    func updateRegistration(_ request: UpdateRegistrationRequest) async -> Result<GenericAPIResponse, LeaderboardAPIError> {
        return await put(path: "/update-registration", body: request)
    }
    
    // MARK: - 8. Delete Player (DELETE /delete-player)
    
    func deletePlayer() async -> Result<GenericAPIResponse, LeaderboardAPIError> {
        return await delete(path: "/delete-player")
    }
    
    // MARK: - 9. Delete Scores (DELETE /delete-scores)
    
    func deleteScores() async -> Result<GenericAPIResponse, LeaderboardAPIError> {
        return await delete(path: "/delete-scores")
    }
    
    // MARK: - Offline Queue
    
    /// Bekleyen skorları tekrar gönder (app launch'ta çağrılır)
    @discardableResult
    func retryPendingSubmissions() async -> Bool {
        guard let data = UserDefaults.standard.data(forKey: offlineQueueKey),
              let pending = try? JSONDecoder().decode([ScoreSubmitRequest].self, from: data),
              !pending.isEmpty else { return false }
        
        var remaining: [ScoreSubmitRequest] = []
        
        for req in pending {
            let result = await submitScoreDirectly(req)
            if case .failure = result {
                remaining.append(req)
            }
        }
        
        if remaining.isEmpty {
            UserDefaults.standard.removeObject(forKey: offlineQueueKey)
        } else if let data = try? JSONEncoder().encode(remaining) {
            UserDefaults.standard.set(data, forKey: offlineQueueKey)
        }
        
        return remaining.count < pending.count
    }
    
    /// Cache'i temizle (manual refresh)
    func invalidateCache() {
        globalCache = nil
        localCache = nil
    }
    
    // MARK: - Private: Generic HTTP Methods
    
    private func get<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        includeDeviceHeader: Bool = false
    ) async -> Result<T, LeaderboardAPIError> {
        guard var components = URLComponents(string: LeaderboardAPIConfig.baseURL + path) else {
            return .failure(.badRequest("Geçersiz URL"))
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            return .failure(.badRequest("URL oluşturulamadı"))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addAuthHeaders(&request, includeDevice: includeDeviceHeader)
        
        return await execute(request)
    }
    
    private func post<T: Decodable, B: Encodable>(
        path: String,
        body: B
    ) async -> Result<T, LeaderboardAPIError> {
        guard let url = URL(string: LeaderboardAPIConfig.baseURL + path) else {
            return .failure(.badRequest("Geçersiz URL"))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeaders(&request)
        
        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            return .failure(.badRequest("JSON encode hatası"))
        }
        
        return await execute(request)
    }
    
    private func put<T: Decodable, B: Encodable>(
        path: String,
        body: B
    ) async -> Result<T, LeaderboardAPIError> {
        guard let url = URL(string: LeaderboardAPIConfig.baseURL + path) else {
            return .failure(.badRequest("Geçersiz URL"))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeaders(&request)
        
        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            return .failure(.badRequest("JSON encode hatası"))
        }
        
        return await execute(request)
    }
    
    private func delete<T: Decodable>(
        path: String
    ) async -> Result<T, LeaderboardAPIError> {
        guard let url = URL(string: LeaderboardAPIConfig.baseURL + path) else {
            return .failure(.badRequest("Geçersiz URL"))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        addAuthHeaders(&request, includeDevice: true)
        
        return await execute(request)
    }
    
    // MARK: - Private: Execute & Parse
    
    private func execute<T: Decodable>(_ request: URLRequest) async -> Result<T, LeaderboardAPIError> {
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                return .failure(.noConnection)
            case .timedOut:
                return .failure(.noConnection)
            default:
                return .failure(.serverError(error.localizedDescription))
            }
        } catch {
            return .failure(.serverError(error.localizedDescription))
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(.unknown(0))
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoded = try decoder.decode(T.self, from: data)
                return .success(decoded)
            } catch {
                return .failure(.decodingError)
            }
            
        case 401:
            return .failure(.unauthorized)
            
        case 404:
            let msg = parseErrorMessage(data) ?? "Bulunamadı"
            return .failure(.notFound(msg))
            
        case 405:
            let msg = parseErrorMessage(data) ?? "Yöntem İzin Verilmiyor (HTTP 405)"
            return .failure(.serverError(msg))
            
        case 409:
            let msg = parseErrorMessage(data) ?? "Çakışma"
            return .failure(.conflict(msg))
            
        case 400:
            let msg = parseErrorMessage(data) ?? "Geçersiz istek"
            return .failure(.badRequest(msg))
            
        case 500...599:
            let msg = parseErrorMessage(data) ?? "Sunucu hatası"
            return .failure(.serverError(msg))
            
        default:
            let msg = parseErrorMessage(data) ?? "HTTP \(httpResponse.statusCode)"
            return .failure(.unknown(httpResponse.statusCode))
        }
    }
    
    // MARK: - Private: Helpers
    
    private func addAuthHeaders(_ request: inout URLRequest, includeDevice: Bool = false) {
        request.setValue("token \(LeaderboardAPIConfig.token)", forHTTPHeaderField: "Authorization")
        if includeDevice {
            request.setValue(DeviceIdentifier.deviceID, forHTTPHeaderField: "X-Device-ID")
        }
    }
    
    private func parseErrorMessage(_ data: Data) -> String? {
        // Backend bazen string, bazen JSON döner
        if let str = String(data: data, encoding: .utf8) {
            // JSON string olabilir: "\"Mesaj\""
            let trimmed = str.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }
    
    private func currentCountryCode() -> String {
        Locale.current.region?.identifier ?? "XX"
    }
    
    /// Doğrudan gönder (offline queue retry için — queue'ya tekrar eklemez)
    private func submitScoreDirectly(_ request: ScoreSubmitRequest) async -> Result<ScoreSubmitResponse, LeaderboardAPIError> {
        return await post(path: "/submit", body: request)
    }
    
    private func saveToOfflineQueue(_ request: ScoreSubmitRequest) {
        var pending: [ScoreSubmitRequest] = []
        if let data = UserDefaults.standard.data(forKey: offlineQueueKey),
           let existing = try? JSONDecoder().decode([ScoreSubmitRequest].self, from: data) {
            pending = existing
        }
        pending.append(request)
        // Max 10 offline skor tut
        if pending.count > 10 { pending = Array(pending.suffix(10)) }
        if let data = try? JSONEncoder().encode(pending) {
            UserDefaults.standard.set(data, forKey: offlineQueueKey)
        }
    }
}
