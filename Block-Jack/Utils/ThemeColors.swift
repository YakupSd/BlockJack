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

    // MARK: - World Selection (UI Spec)
    static func worldCardPalette(worldId: Int) -> (cardBg: Color, accent: Color) {
        switch max(1, min(5, worldId)) {
        case 1:
            return (Color(hex: "#0E1A2B"), Color(hex: "#00F5FF"))
        case 2:
            return (Color(hex: "#1A1512"), Color(hex: "#A0522D"))
        case 3:
            return (Color(hex: "#1A0D14"), Color(hex: "#FF6FA3"))
        case 4:
            return (Color(hex: "#071419"), Color(hex: "#00FFCC"))
        default:
            return (Color(hex: "#0D0A12"), Color(hex: "#9B59FF"))
        }
    }

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

    // MARK: - Game Board Zone Colors (UI Revize)
    // Sol üst (yeşilimsi), sağ üst (mor-mavi), sol alt (kırmızımsı), sağ alt (turkuaz)
    // Ortak: koyu mat arka planlar, hafif renk ton farkıyla zone algısı yaratır.
    static let zoneTL          = Color(hex: "#1a2a1a")   // sol üst
    static let zoneTR          = Color(hex: "#1a1a2a")   // sağ üst
    static let zoneBL          = Color(hex: "#2a1a1a")   // sol alt
    static let zoneBR          = Color(hex: "#1a2a2a")   // sağ alt
    static let zoneCenter      = Color(hex: "#1a1a2e")   // merkez
    static let zoneTLBorder    = Color(hex: "#2a4a2a")
    static let zoneTRBorder    = Color(hex: "#2a2a4a")
    static let zoneBLBorder    = Color(hex: "#4a2a2a")
    static let zoneBRBorder    = Color(hex: "#2a4a4a")
    static let zoneCenterBorder = Color(hex: "#2a2a4e")
    static let cellEmpty       = Color(hex: "#111122")   // zone dışı boş hücre

    // MARK: - Game HUD / Tray / Enemy (UI Revize)
    static let hudBg           = Color(hex: "#0d0d18")   // HUD şeridi
    static let hudBorder       = Color(hex: "#1e1e33")
    static let trayBg          = Color(hex: "#0f0f1e")
    static let trayBorder      = Color(hex: "#1e1e33")
    static let enemyBg         = Color(hex: "#1f1020")
    static let perkBg          = Color(hex: "#15152a")
    static let cardBg          = Color(hex: "#12121f")
    static let cardBorder      = Color(hex: "#23233a")

    // MARK: - World Map (Pixel-Retro Revize)
    // Harita arkaplanı — çok koyu laciverti + çini desen varyasyonları
    static let mapBg           = Color(hex: "#0a0e1a")
    static let mapTile1        = Color(hex: "#0d1120")
    static let mapTile2        = Color(hex: "#0c1018")
    static let mapTile3        = Color(hex: "#0e1222")
    static let mapTile4        = Color(hex: "#0b0f18")
    static let mapRoadDark     = Color(hex: "#1a2040")
    static let mapRoadDash     = Color(hex: "#2a3060")

    // Node state renkleri (state driven border / label)
    static let nodeCompleted   = Color(hex: "#4a8a4a")
    static let nodeCurrent     = Color(hex: "#c8a200")
    static let nodeLocked      = Color(hex: "#2a3050")
    static let nodeBoss        = Color(hex: "#cc3333")

    // Node arkaplan tonları (state)
    static let nodeBgCompleted = Color(hex: "#0d1a0d")
    static let nodeBgCurrent   = Color(hex: "#1a1600")
    static let nodeBgLocked    = Color(hex: "#0d0f1a")
    static let nodeBgBoss      = Color(hex: "#1a0808")

    // Piksel art avatar tonları
    static let pixelSkin       = Color(hex: "#c8a87a")
    static let pixelHair       = Color(hex: "#5ab8d4")
    static let pixelEye        = Color(hex: "#00e5ff")
    static let pixelBody       = Color(hex: "#1a3a5c")

    // HUD paneller
    static let mapHudBg        = Color(hex: "#080c16")
    static let mapHudPanel     = Color(hex: "#111830")
    static let mapHudPanelAlt  = Color(hex: "#1a1400")
    static let mapHudBorder    = Color(hex: "#1e2a50")
    static let mapHudMuted     = Color(hex: "#445566")

    // MARK: - World 2: Concrete Ruins (Endüstriyel Harabeler)
    // Gri betonlar, pas turuncuları, yosunlu yeşiller — post-apokaliptik
    // endüstriyel palet. Pixel-retro background dosyası ile birlikte kullanılır.
    static let ruinBg          = Color(hex: "#1a1815")
    static let ruinTile1       = Color(hex: "#2a2622")   // koyu beton
    static let ruinTile2       = Color(hex: "#1e1c19")   // gölgeli beton
    static let ruinTile3       = Color(hex: "#332a1e")   // pas tonu
    static let ruinTile4       = Color(hex: "#1f2a1e")   // yosun tonu
    static let ruinRustAccent  = Color(hex: "#c66a2e")   // pas turuncusu
    static let ruinMossAccent  = Color(hex: "#6aa86a")   // yosun yeşili

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
