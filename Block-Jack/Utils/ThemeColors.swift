//
//  ThemeColors.swift
//  Block-Jack
//

import SwiftUI

struct ThemeColors {

    // MARK: - Luminescent Architecture (Pearl & Light)
    static let surface         = Color(hex: "#f7f9fb")   // Architectural off-white
    static let luminescentPrimary = Color(hex: "#0058bc") // Ethereal Blue
    static let surfaceContainerLowest = Color(hex: "#ffffff") // Pearl
    static let surfaceContainerLow    = Color(hex: "#f1f3f5") // Silver shift
    static let surfaceContainerHigh   = Color(hex: "#e0e3e5") // Deep silver
    static let outlineVariant  = Color(hex: "#c1c6d7")   // Ghost border (10-15% opacity)

    // MARK: - Legacy Aliases (Prevents build errors)
    static let cosmicBlack     = Color(hex: "#0A0A0F")
    static let gridDark        = Color(hex: "#1A1A2E")
    static let gridStroke      = Color(hex: "#2A2A4A")
    static let surfaceDark     = Color(hex: "#12121C")
    static let surfaceMid      = Color(hex: "#1E1E30")
    static let surfaceLight    = Color(hex: "#2E2E4A")

    // MARK: - Neon Accents (Retro-Legacy)
    static let neonCyan        = Color(hex: "#00F5FF")
    static let neonPurple      = Color(hex: "#BF5FFF")
    static let neonPink        = Color(hex: "#FF2D78")
    static let electricYellow  = Color(hex: "#FFE600")
    static let neonGreen       = Color(hex: "#39FF14")
    static let neonOrange      = Color(hex: "#FF6B35")

    // MARK: - Block Colors (5 Ana Renk)
    static let blockRed        = Color(hex: "#FF3366")   // Kırmızı blok
    static let blockBlue       = Color(hex: "#00CFFF")   // Mavi blok
    static let blockGreen      = Color(hex: "#39FF14")   // Yeşil blok
    static let blockYellow     = Color(hex: "#FFE600")   // Sarı blok
    static let blockPurple     = Color(hex: "#BF5FFF")   // Mor blok

    // MARK: - Timer Bar Colors
    static let timerGreen      = Color(hex: "#39FF14")
    static let timerYellow     = Color(hex: "#FFE600")
    static let timerOrange     = Color(hex: "#FF6B35")
    static let timerRed        = Color(hex: "#FF2D78")

    // MARK: - Text Colors
    static let textPrimary     = Color.white
    static let textSecondary   = Color(hex: "#A0A0C0")
    static let textMuted       = Color(hex: "#606080")

    // MARK: - UI States
    static let success         = Color(hex: "#39FF14")
    static let warning         = Color(hex: "#FFE600")
    static let danger          = Color(hex: "#FF2D78")
    static let locked          = Color(hex: "#3A3A5C")

    // MARK: - Gradients
    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "#0A0A0F"), Color(hex: "#0D0D1A"), Color(hex: "#0A0A0F")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let neonCyanGradient = LinearGradient(
        colors: [Color(hex: "#00F5FF"), Color(hex: "#0080FF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let neonPurpleGradient = LinearGradient(
        colors: [Color(hex: "#BF5FFF"), Color(hex: "#7B2FFF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let liquidChromeGradient = LinearGradient(
        colors: [Color(hex: "#0058bc"), Color(hex: "#0070eb")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassGradient = LinearGradient(
        colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Block neon glow rengi
    static func neonGlow(for blockColor: BlockDisplayColor) -> Color {
        switch blockColor {
        case .red:    return blockRed
        case .blue:   return blockBlue
        case .green:  return blockGreen
        case .yellow: return blockYellow
        case .purple: return blockPurple
        }
    }

    // MARK: - Timer bar rengi (yüzdeye göre)
    static func timerColor(ratio: Double) -> Color {
        switch ratio {
        case 0.5...1.0: return timerGreen
        case 0.25..<0.5: return timerYellow
        case 0.10..<0.25: return timerOrange
        default: return timerRed
        }
    }
}

// MARK: - Block Display Color Enum (renk sistemi)
enum BlockDisplayColor: String, CaseIterable, Codable {
    case red, blue, green, yellow, purple

    var color: Color {
        switch self {
        case .red:    return ThemeColors.blockRed
        case .blue:   return ThemeColors.blockBlue
        case .green:  return ThemeColors.blockGreen
        case .yellow: return ThemeColors.blockYellow
        case .purple: return ThemeColors.blockPurple
        }
    }

    var displayName: String { rawValue.capitalized }
}

// MARK: - Color Hex Init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
