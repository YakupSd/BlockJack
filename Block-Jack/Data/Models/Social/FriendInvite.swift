//
//  FriendInvite.swift
//  Block-Jack
//

import Foundation

// MARK: - Friend Invite Code
struct FriendInvite: Codable, Identifiable {
    let id: String = UUID().uuidString
    
    let code:       String    // "BLK-7X9K" formatında 8 karakter
    let ownerID:    String
    let deepLink:   String    // "blockjack://friend?code=BLK-7X9K"
    let expiresAt:  Date?     // nil = süresiz
    var usageCount: Int = 0
    
    // Mock initializer
    init(
        code: String = Self.generateCode(),
        ownerID: String,
        deepLink: String? = nil,
        expiresAt: Date? = nil,
        usageCount: Int = 0
    ) {
        self.code = code
        self.ownerID = ownerID
        self.deepLink = deepLink ?? "blockjack://friend?code=\(code)"
        self.expiresAt = expiresAt
        self.usageCount = usageCount
    }
    
    // Kod üretim yardımcısı
    static func generateCode() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let code = (0..<8).map { _ in String(chars.randomElement()!) }.joined()
        return "BLK-\(code.prefix(4))"
    }
}
