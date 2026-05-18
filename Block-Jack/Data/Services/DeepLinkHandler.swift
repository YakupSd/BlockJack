//
//  DeepLinkHandler.swift
//  Block-Jack
//

import Foundation
import SwiftUI

// MARK: - Deep Link Handler
struct DeepLinkHandler {
    
    /// DeepLink URL'sini parse et
    /// Format: blockjack://friend?code=BLK-XXXX
    static func handle(_ url: URL) -> DeepLinkAction? {
        guard url.scheme == "blockjack" else { return nil }
        
        switch url.host {
        case "friend":
            if let code = parseQueryParameter(url, "code") {
                return .friendInvite(code)
            }
        case "duel":
            if let duelID = parseQueryParameter(url, "duelId") {
                return .viewDuel(duelID)
            }
        default:
            break
        }
        
        return nil
    }
    
    private static func parseQueryParameter(_ url: URL, _ key: String) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let items = components.queryItems else {
            return nil
        }
        return items.first(where: { $0.name == key })?.value
    }
}

// MARK: - Deep Link Action
enum DeepLinkAction: Equatable {
    case friendInvite(String)  // code: BLK-XXXX
    case viewDuel(String)      // duelID
}
