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
        Group {
            if userEnv.isCharacterMastered(characterId) {
                // Master — altın yıldız rozet
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("MASTER")
                        .font(.setCustomFont(name: .InterBlack, size: 10))
                        .tracking(1)
                }
                .foregroundStyle(Color(red: 0.15, green: 0.08, blue: 0.0))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    LinearGradient(
                        colors: [ThemeColors.electricYellow, Color.orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: ThemeColors.electricYellow.opacity(0.9), radius: 6)
            } else if chapter > 0 {
                // Erken progress — cyan "CH X" rozet
                HStack(spacing: 3) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 9, weight: .bold))
                    Text("CH \(chapter)")
                        .font(.setCustomFont(name: .InterBold, size: 10))
                        .tracking(0.5)
                }
                .foregroundStyle(ThemeColors.neonCyan)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(ThemeColors.neonCyan.opacity(0.12))
                )
                .overlay(
                    Capsule().stroke(ThemeColors.neonCyan.opacity(0.6), lineWidth: 1)
                )
            } else {
                EmptyView()
            }
        }
    }
}

/// Karakter portresi / kartı için altın çerçeve (sadece master'lananlara).
struct CharacterMasteryFrame: ViewModifier {
    let characterId: String
    let cornerRadius: CGFloat
    @EnvironmentObject var userEnv: UserEnvironment

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        userEnv.isCharacterMastered(characterId)
                            ? LinearGradient(
                                colors: [ThemeColors.electricYellow, Color.orange, ThemeColors.electricYellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [Color.clear, Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ),
                        lineWidth: userEnv.isCharacterMastered(characterId) ? 2 : 0
                    )
            )
            .shadow(
                color: userEnv.isCharacterMastered(characterId)
                    ? ThemeColors.electricYellow.opacity(0.7)
                    : .clear,
                radius: userEnv.isCharacterMastered(characterId) ? 10 : 0
            )
    }
}

extension View {
    /// Kartın etrafına mastery (altın) glow efekti ekler; karakter master değilse no-op.
    func characterMasteryFrame(characterId: String, cornerRadius: CGFloat = 20) -> some View {
        modifier(CharacterMasteryFrame(characterId: characterId, cornerRadius: cornerRadius))
    }
}
