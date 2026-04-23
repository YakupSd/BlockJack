//
//  RunSummaryView.swift
//  Block-Jack
//
//  TODO 9: Run bittikten sonra gösterilen özet ekranı.
//  Skor, world level, karakter, altın, perk sayısı gibi bilgileri modern
//  bir tasarımla sunar. Arkasında Dashboard vardır.
//

import SwiftUI

struct RunSummaryView: View {
    let summary: LastRunSummary
    let slotId: Int

    @EnvironmentObject var userEnv: UserEnvironment
    @State private var appeared = false
    @State private var scoreCounter: Int = 0

    private var character: GameCharacter? {
        GameCharacter.roster.first(where: { $0.id == summary.characterId })
    }

    var body: some View {
        ZStack {
            // Arka Plan
            ThemeColors.backgroundGradient.ignoresSafeArea()
            backgroundGrid

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                // --- Başlık ---
                VStack(spacing: 8) {
                    Text(userEnv.localizedString("RUN BİTTİ", "RUN OVER"))
                        .font(.setCustomFont(name: .InterBlack, size: 14))
                        .tracking(4)
                        .foregroundStyle(ThemeColors.neonPink)

                    Text(userEnv.localizedString("İSTATİSTİKLER", "SUMMARY"))
                        .font(.setCustomFont(name: .InterExtraBold, size: 32))
                        .foregroundStyle(.white)
                        .tracking(3)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -16)
                .animation(.easeOut(duration: 0.4), value: appeared)

                Spacer(minLength: 28)

                // --- Karakter Portresi ---
                if let char = character {
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(ThemeColors.surfaceDark)
                                .frame(width: 110, height: 110)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(ThemeColors.neonPink.opacity(0.55), lineWidth: 1.5)
                                )
                                .shadow(color: ThemeColors.neonPink.opacity(0.3), radius: 16)

                            Image(char.icon)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 102, height: 102)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }

                        Text(char.name)
                            .font(.setCustomFont(name: .InterBlack, size: 16))
                            .foregroundStyle(ThemeColors.neonCyan)
                            .tracking(2)

                        if summary.wasTrial {
                            Text(userEnv.localizedString("TRIAL RUN", "TRIAL RUN"))
                                .font(.setCustomFont(name: .InterBold, size: 10))
                                .tracking(2)
                                .foregroundStyle(ThemeColors.neonOrange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(ThemeColors.neonOrange.opacity(0.15))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(ThemeColors.neonOrange.opacity(0.4), lineWidth: 1))
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.85)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appeared)
                }

                Spacer(minLength: 24)

                // --- İstatistik Kartları ---
                VStack(spacing: 10) {
                    // Büyük Skor
                    VStack(spacing: 4) {
                        Text(userEnv.localizedString("TOPLAM SKOR", "TOTAL SCORE"))
                            .font(.setCustomFont(name: .InterBold, size: 11))
                            .tracking(2)
                            .foregroundStyle(ThemeColors.textMuted)

                        Text("\(scoreCounter)")
                            .font(.setCustomFont(name: .InterExtraBold, size: 52))
                            .foregroundStyle(ThemeColors.electricYellow)
                            .shadow(color: ThemeColors.electricYellow.opacity(0.5), radius: 10)
                            .contentTransition(.numericText())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(ThemeColors.surfaceDark.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18)
                        .stroke(ThemeColors.electricYellow.opacity(0.3), lineWidth: 1))

                    // Alt stat satırları
                    HStack(spacing: 10) {
                        statCard(
                            icon: "globe.europe.africa.fill",
                            label: userEnv.localizedString("WORLD", "WORLD"),
                            value: "W\(summary.worldLevelReached)",
                            color: ThemeColors.neonPurple
                        )
                        statCard(
                            icon: "bitcoinsign.circle.fill",
                            label: userEnv.localizedString("ALTIN", "GOLD"),
                            value: "\(summary.goldTotal)",
                            color: ThemeColors.electricYellow
                        )
                        statCard(
                            icon: "bolt.fill",
                            label: userEnv.localizedString("PERK", "PERKS"),
                            value: "\(summary.perksCount)",
                            color: ThemeColors.neonCyan
                        )
                    }
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 24)
                .animation(.easeOut(duration: 0.45).delay(0.2), value: appeared)

                Spacer()

                // --- Aksiyon Butonları ---
                VStack(spacing: 12) {
                    // Yeni Run
                    Button {
                        HapticManager.shared.play(.heavy)
                        // Karakter seçimine gönder (yeni run)
                        let emptySlot = SaveManager.shared.slots.first(where: { $0.isEmpty })
                        let targetSlot = emptySlot?.id ?? slotId
                        MainViewsRouter.shared.pushToCharacterSelection(slotId: targetSlot, mode: .firstSetup)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                            Text(userEnv.localizedString("YENİ RUN", "NEW RUN"))
                                .font(.setCustomFont(name: .InterExtraBold, size: 20))
                                .tracking(3)
                        }
                        .foregroundStyle(ThemeColors.cosmicBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(ThemeColors.electricYellow)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: ThemeColors.electricYellow.opacity(0.5), radius: 16)
                    }
                    .buttonStyle(.plain)

                    // Ana Menü
                    Button {
                        HapticManager.shared.play(.buttonTap)
                        MainViewsRouter.shared.popToDashboard()
                    } label: {
                        Text(userEnv.localizedString("ANA MENÜ", "MAIN MENU"))
                            .font(.setCustomFont(name: .InterBold, size: 16))
                            .foregroundStyle(ThemeColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(ThemeColors.gridStroke.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation { appeared = true }
            // Skor sayacını animate et
            let target = summary.score
            let duration: Double = 1.2
            let steps = 30
            let stepValue = max(1, target / steps)
            for i in 0...steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration * Double(i) / Double(steps)) {
                    withAnimation(.easeOut) {
                        scoreCounter = min(target, i * stepValue)
                        if i == steps { scoreCounter = target }
                    }
                }
            }
        }
    }

    // MARK: - İstatistik Kartı
    @ViewBuilder
    private func statCard(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(color)
            Text(value)
                .font(.setCustomFont(name: .InterExtraBold, size: 22))
                .foregroundStyle(.white)
            Text(label)
                .font(.setCustomFont(name: .InterBold, size: 9))
                .tracking(1.5)
                .foregroundStyle(ThemeColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(ThemeColors.surfaceDark.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(color.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Arka Plan Izgarası
    private var backgroundGrid: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 40
            let color = GraphicsContext.Shading.color(ThemeColors.gridStroke.opacity(0.10))
            for x in stride(from: 0, through: size.width, by: spacing) {
                var p = Path(); p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height))
                ctx.stroke(p, with: color, lineWidth: 0.5)
            }
            for y in stride(from: 0, through: size.height, by: spacing) {
                var p = Path(); p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y))
                ctx.stroke(p, with: color, lineWidth: 0.5)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    RunSummaryView(
        summary: LastRunSummary(
            score: 12450,
            worldLevelReached: 7,
            characterId: "block_e",
            goldTotal: 320,
            perksCount: 4,
            wasTrial: false,
            timestamp: Date().timeIntervalSince1970
        ),
        slotId: 1
    )
    .environmentObject(UserEnvironment.shared)
}
