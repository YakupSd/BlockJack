//
//  LeaderboardModels.swift
//  Block-Jack
//
//  C# backend modelleriyle 1:1 eşleşen request/response yapıları.
//  Backend: LeaderboardController.cs (BlockJackAPI)
//

import Foundation

// MARK: - REQUEST MODELLERİ

struct ScoreSubmitRequest: Codable {
    let deviceID: String
    let username: String
    let countryCode: String
    let score: Int
    let chapterReached: UInt8
    let roundReached: UInt8
    let characterID: UInt8
    let durationSeconds: Int16
    
    enum CodingKeys: String, CodingKey {
        case deviceID = "DeviceID"
        case username = "Username"
        case countryCode = "CountryCode"
        case score = "Score"
        case chapterReached = "ChapterReached"
        case roundReached = "RoundReached"
        case characterID = "CharacterID"
        case durationSeconds = "DurationSeconds"
    }
}

struct RegisterPlayerRequest: Codable {
    let deviceID: String
    let fullName: String
    let email: String
    let phone: String
    
    enum CodingKeys: String, CodingKey {
        case deviceID = "DeviceID"
        case fullName = "FullName"
        case email = "Email"
        case phone = "Phone"
    }
}

struct UpdatePlayerRequest: Codable {
    let deviceID: String
    let username: String?
    let countryCode: String?
    let avatarSlot: UInt8?
    
    enum CodingKeys: String, CodingKey {
        case deviceID = "DeviceID"
        case username = "Username"
        case countryCode = "CountryCode"
        case avatarSlot = "AvatarSlot"
    }
}

struct UpdateRegistrationRequest: Codable {
    let deviceID: String
    let fullName: String?
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case deviceID = "DeviceID"
        case fullName = "FullName"
        case email = "Email"
    }
}

// MARK: - RESPONSE MODELLERİ

struct ScoreSubmitResponse: Codable {
    let isPersonalBest: Bool
    let globalRank: Int
    let localRank: Int
    
    enum CodingKeys: String, CodingKey {
        case isPersonalBest = "IsPersonalBest"
        case globalRank = "GlobalRank"
        case localRank = "LocalRank"
    }
}

struct LeaderboardEntry: Codable, Identifiable, Equatable {
    var id: String { "\(rank)_\(username)" }
    let rank: Int
    let username: String
    let countryCode: String
    let score: Int
    let chapter: UInt8
    let characterID: UInt8
    let badge: String
    
    enum CodingKeys: String, CodingKey {
        case rank = "Rank"
        case username = "Username"
        case countryCode = "CountryCode"
        case score = "Score"
        case chapter = "Chapter"
        case characterID = "CharacterID"
        case badge = "Badge"
    }
    
    /// Badge rengi
    var badgeColor: String {
        switch badge {
        case "RARE":   return "electricYellow"  // Altın — Top 3
        case "EXPERT": return "neonCyan"        // Gümüş — Top 50
        default:       return "textMuted"       // Bronz — BETA
        }
    }
    
    /// Karakter roster index'inden karakter bilgisi
    var character: GameCharacter? {
        let idx = Int(characterID)
        guard idx >= 0 && idx < GameCharacter.roster.count else { return nil }
        return GameCharacter.roster[idx]
    }
    
    /// Ülke bayrağı emoji
    var flagEmoji: String {
        countryCodeToFlag(countryCode)
    }
}

struct MyRankResponse: Codable {
    let username: String
    let countryCode: String
    let score: Int
    let chapter: UInt8
    let globalRank: Int
    let localRank: Int
    let badge: String
    
    enum CodingKeys: String, CodingKey {
        case username = "Username"
        case countryCode = "CountryCode"
        case score = "Score"
        case chapter = "Chapter"
        case globalRank = "GlobalRank"
        case localRank = "LocalRank"
        case badge = "Badge"
    }
    
    var flagEmoji: String {
        countryCodeToFlag(countryCode)
    }
}

struct GenericAPIResponse: Codable {
    let detail: String?
}

// MARK: - API Error

enum LeaderboardAPIError: Error, LocalizedError {
    case noConnection
    case unauthorized
    case notFound(String)
    case conflict(String)
    case badRequest(String)
    case serverError(String)
    case decodingError
    case unknown(Int)
    
    var errorDescription: String? {
        switch self {
        case .noConnection:       return "İnternet bağlantısı bulunamadı"
        case .unauthorized:       return "Yetkisiz istek"
        case .notFound(let msg):  return msg
        case .conflict(let msg):  return msg
        case .badRequest(let msg): return msg
        case .serverError(let msg): return "Sunucu hatası: \(msg)"
        case .decodingError:      return "Veri çözümleme hatası"
        case .unknown(let code):  return "Bilinmeyen hata (\(code))"
        }
    }
}

// MARK: - Helpers

/// "TR" → 🇹🇷 (Unicode regional indicator)
func countryCodeToFlag(_ code: String) -> String {
    let base: UInt32 = 127397
    let uppercased = code.uppercased()
    guard uppercased.count == 2 else { return "🏳️" }
    let scalars = uppercased.unicodeScalars.compactMap { Unicode.Scalar(base + $0.value) }
    return scalars.map { String($0) }.joined()
}
