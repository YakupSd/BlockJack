//
//  CharacterMasteryBadge.swift
//  Block-Jack
//
//  Karakter-özel ilerleme göstergesi: bir oyuncunun hangi karakterle
//  hangi bölüme ulaştığını küçük bir rozet ve altın glow ile gösterir.
//  Amaç: "bu karakter bu chapter'ı gördü mü?" sorusunu UI'da hemen
//  iletmek — oyuncuyu rosterdaki diğer karakterleri denemeye motive
//  eder (Ch20 = master, altın çerçeve; Ch 1-19 = küçük chapter rozet).
//

import SwiftUI

/// Karakter kartlarına takılan küçük mastery rozeti.
struct CharacterMasteryBadge: View {
    let characterId: String
    @EnvironmentObject var userEnv: UserEnvironment

    var body: some View {
        let chapter = userEnv.maxChapter(for: characterId)
        let tier = CharacterMasteryTier.from(chapter: chapter)
        Group {
            if tier == .none {
                EmptyView()
            } else if tier == .master {
                masteryBadge(
                    icon: "star.fill",
                    text: "MASTER",
                    foreground: Color(red: 0.15, green: 0.08, blue: 0.0),
                    background: LinearGradient(
                        colors: [ThemeColors.electricYellow, Color.orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    shadow: ThemeColors.electricYellow.opacity(0.9)
                )
            } else {
                // Ch5/10/15 katmanlı rozet + yanında current chapter
                masteryBadge(
                    icon: tier.icon,
                    text: "\(tier.label) • CH \(chapter)",
                    foreground: tier.color,
                    background: LinearGradient(
                        colors: [tier.color.opacity(0.18), tier.color.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    shadow: tier.color.opacity(0.55)
                )
                .overlay(
                    Capsule().stroke(tier.color.opacity(0.55), lineWidth: 1)
                )
            }
        }
    }

    private func masteryBadge(icon: String, text: String, foreground: Color, background: LinearGradient, shadow: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.setCustomFont(name: .InterBlack, size: 10))
                .tracking(0.6)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(background)
        .clipShape(Capsule())
        .shadow(color: shadow, radius: 6)
    }
}

enum CharacterMasteryTier: Int, CaseIterable {
    case none = 0
    case bronze = 5
    case silver = 10
    case gold = 15
    case master = 20

    static func from(chapter: Int) -> CharacterMasteryTier {
        if chapter >= 20 { return .master }
        if chapter >= 15 { return .gold }
        if chapter >= 10 { return .silver }
        if chapter >= 5 { return .bronze }
        return chapter > 0 ? .bronze : .none
    }

    var label: String {
        switch self {
        case .bronze: return "BRONZE"
        case .silver: return "SILVER"
        case .gold: return "GOLD"
        case .master: return "MASTER"
        case .none: return ""
        }
    }

    var icon: String {
        switch self {
        case .bronze: return "circle.lefthalf.filled"
        case .silver: return "seal.fill"
        case .gold: return "crown.fill"
        case .master: return "star.fill"
        case .none: return "circle"
        }
    }

    var color: Color {
        switch self {
        case .bronze: return ThemeColors.neonPink
        case .silver: return ThemeColors.neonCyan
        case .gold: return ThemeColors.electricYellow
        case .master: return ThemeColors.electricYellow
        case .none: return ThemeColors.textMuted
        }
    }

    var frameGradient: LinearGradient? {
        switch self {
        case .none: return nil
        case .bronze:
            return LinearGradient(colors: [ThemeColors.neonPink, ThemeColors.neonPurple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .silver:
            return LinearGradient(colors: [ThemeColors.neonCyan, ThemeColors.neonPurple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gold, .master:
            return LinearGradient(colors: [ThemeColors.electricYellow, .orange, ThemeColors.electricYellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

/// Karakter portresi / kartı için çerçeve (tier'a göre).
struct CharacterMasteryFrame: ViewModifier {
    let characterId: String
    let cornerRadius: CGFloat
    @EnvironmentObject var userEnv: UserEnvironment

    func body(content: Content) -> some View {
        let chapter = userEnv.maxChapter(for: characterId)
        let tier = CharacterMasteryTier.from(chapter: chapter)
        let gradient = tier.frameGradient
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        gradient ?? LinearGradient(colors: [.clear, .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: gradient == nil ? 0 : (tier == .master ? 2.5 : 1.8)
                    )
            )
            .shadow(
                color: gradient == nil ? .clear : tier.color.opacity(tier == .master ? 0.75 : 0.45),
                radius: gradient == nil ? 0 : (tier == .master ? 10 : 7)
            )
    }
}

extension View {
    /// Kartın etrafına mastery (altın) glow efekti ekler; karakter master değilse no-op.
    func characterMasteryFrame(characterId: String, cornerRadius: CGFloat = 20) -> some View {
        modifier(CharacterMasteryFrame(characterId: characterId, cornerRadius: cornerRadius))
    }
}
