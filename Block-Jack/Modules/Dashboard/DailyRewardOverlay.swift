//
//  DailyRewardOverlay.swift
//  Block-Jack
//
//  Phase 8 — 7 günlük rotasyon üzerinden günlük ödül overlay'i.
//  Dashboard'dan tetiklenir. Claim edilebilir durumdaysa Al butonu
//  aktiftir; değilse 24h geri sayımı gösterilir. Streak gün bantları
//  1..7 olarak stilize edilmiş kartlar halinde sıralanır.
//

import SwiftUI
import Combine

struct DailyRewardOverlay: View {

    @EnvironmentObject var userEnv: UserEnvironment
    @Binding var isPresented: Bool
    @State private var claimedTier: DailyRewardTier?
    @State private var now: Date = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture { close() }

            VStack(spacing: 20) {
                Text(userEnv.localizedString("GÜNLÜK ÖDÜL", "DAILY REWARD"))
                    .font(.setCustomFont(name: .InterBlack, size: 22))
                    .foregroundStyle(ThemeColors.electricYellow)
                    .tracking(3)

                Text(userEnv.localizedString(
                    "Üst üste giriş yaparak büyük ödülleri topla!",
                    "Log in daily to unlock bigger rewards!"
                ))
                .font(.setCustomFont(name: .InterMedium, size: 12))
                .foregroundStyle(ThemeColors.textSecondary)
                .multilineTextAlignment(.center)

                streakGrid

                if let tier = claimedTier {
                    claimedBanner(tier: tier)
                } else if userEnv.canClaimDaily {
                    claimButton
                } else {
                    countdownLabel
                }

                Button {
                    close()
                } label: {
                    Text(userEnv.localizedString("KAPAT", "CLOSE"))
                        .font(.setCustomFont(name: .InterBold, size: 13))
                        .foregroundStyle(ThemeColors.textMuted)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 24)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(ThemeColors.surfaceDark)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(ThemeColors.electricYellow.opacity(0.35), lineWidth: 1)
                    )
                    .shadow(color: ThemeColors.electricYellow.opacity(0.2), radius: 30)
            )
            .padding(.horizontal, 24)
        }
        .onReceive(timer) { _ in now = Date() }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    private var streakGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
            ForEach(DailyRewardSchedule.schedule, id: \.day) { tier in
                streakCell(tier: tier)
            }
        }
    }

    private func streakCell(tier: DailyRewardTier) -> some View {
        let todayIndex = ((max(1, userEnv.dailyStreak) - 1) % DailyRewardSchedule.schedule.count) + 1
        let alreadyClaimedToday = !userEnv.canClaimDaily && tier.day == todayIndex
        let isNext = userEnv.canClaimDaily && tier.day == todayIndex
        let isPast = tier.day < todayIndex

        return VStack(spacing: 4) {
            Text(userEnv.localizedString("GÜN \(tier.day)", "DAY \(tier.day)"))
                .font(.setCustomFont(name: .InterBold, size: 9))
                .foregroundStyle(isNext ? ThemeColors.electricYellow : ThemeColors.textMuted)

            Image(systemName: tier.diamonds > 0 ? "diamond.fill" : "dollarsign.circle.fill")
                .foregroundStyle(tier.diamonds > 0 ? ThemeColors.neonCyan : ThemeColors.electricYellow)
                .font(.system(size: 18))

            Text("\(tier.gold)")
                .font(.setCustomFont(name: .InterBold, size: 11))
                .foregroundStyle(.white)
            if tier.diamonds > 0 {
                Text("+\(tier.diamonds)💎")
                    .font(.setCustomFont(name: .InterMedium, size: 9))
                    .foregroundStyle(ThemeColors.neonCyan)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isNext ? ThemeColors.electricYellow.opacity(0.12) : Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isNext ? ThemeColors.electricYellow :
                            (isPast || alreadyClaimedToday ? ThemeColors.neonCyan.opacity(0.4) : ThemeColors.gridStroke.opacity(0.3)),
                            lineWidth: isNext ? 2 : 1
                        )
                )
        )
        .opacity((isPast || alreadyClaimedToday) ? 0.55 : 1.0)
    }

    private var claimButton: some View {
        Button {
            HapticManager.shared.play(.heavy)
            if let tier = userEnv.claimDailyReward() {
                claimedTier = tier
                AudioManager.shared.playSFX(.coin)
            }
        } label: {
            Text(userEnv.localizedString("ÖDÜLÜ AL", "CLAIM"))
                .font(.setCustomFont(name: .InterBlack, size: 16))
                .tracking(4)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(ThemeColors.electricYellow)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: ThemeColors.electricYellow.opacity(0.5), radius: 18)
        }
        .buttonStyle(.plain)
    }

    private func claimedBanner(tier: DailyRewardTier) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(ThemeColors.neonCyan)
            VStack(alignment: .leading, spacing: 2) {
                Text(userEnv.localizedString("ALINDI", "CLAIMED"))
                    .font(.setCustomFont(name: .InterBold, size: 11))
                    .foregroundStyle(ThemeColors.neonCyan)
                Text("+\(tier.gold) \(userEnv.localizedString("Altın", "Gold"))" + (tier.diamonds > 0 ? " · +\(tier.diamonds) 💎" : ""))
                    .font(.setCustomFont(name: .InterMedium, size: 13))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var countdownLabel: some View {
        let seconds = Int(userEnv.secondsUntilNextDaily)
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        let pretty = String(format: "%02d:%02d:%02d", h, m, s)
        return VStack(spacing: 4) {
            Text(userEnv.localizedString("SONRAKİ ÖDÜL", "NEXT REWARD"))
                .font(.setCustomFont(name: .InterMedium, size: 10))
                .foregroundStyle(ThemeColors.textMuted)
                .tracking(2)
            Text(pretty)
                .font(.setCustomFont(name: .InterBlack, size: 22))
                .foregroundStyle(ThemeColors.neonCyan)
                .monospacedDigit()
        }
        .padding(.vertical, 6)
        .onAppear { _ = now } // trigger recompute via timer
    }

    private func close() {
        withAnimation(.easeOut(duration: 0.2)) {
            isPresented = false
        }
    }
}
