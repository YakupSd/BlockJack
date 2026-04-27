//
//  SlotHubView.swift
//  Block-Jack
//
//  Slot-bağlamlı ana menü. Slot seçildikten sonra kullanıcı buraya düşer
//  ve tüm shop/karakter/galeri/sefer aksiyonları slot kimliği taşıyarak
//  buradan açılır. Böylece "hangi oyuncu için alışveriş yapıyorum"
//  sorusu her ekranda net kalır; Market/Karakter'e slot seçmeden
//  girme bug'ı ortadan kalkar.
//

import SwiftUI

struct SlotHubView: View {

    @EnvironmentObject var userEnv: UserEnvironment
    @StateObject private var saveManager = SaveManager.shared
    @State private var showDailyReward = false
    @State private var showHubIntro = false

    let slotId: Int

    private var slot: SaveSlot? {
        saveManager.slots.first { $0.id == slotId }
    }

    private var character: GameCharacter {
        let id = slot?.characterId ?? userEnv.selectedCharacterID
        return GameCharacter.roster.first(where: { $0.id == id })
            ?? GameCharacter.roster[0]
    }

    /// Devam edilebilir bir run var mı?
    /// - Slot dolu OLMALI.
    /// - `currentChapterMap` null DEĞİL.
    /// - Map bitmemiş (finale node tamamlanmamış). Eskiden bu kontrol yoktu
    ///   ve bölüm bittikten sonra da "SEFERE DEVAM" çıkıp bitik haritaya
    ///   geri atıyor, loop yapıyordu.
    private var hasActiveRun: Bool {
        guard let s = slot, !s.isEmpty, let map = s.currentChapterMap else { return false }
        return !map.isCleared
    }

    var body: some View {
        ZStack {
            ThemeColors.backgroundGradient.ignoresSafeArea()
            backgroundGrid

            VStack(spacing: 0) {
                topBar

                Spacer(minLength: 12)

                characterCard

                Spacer(minLength: 16)

                if let s = slot, !s.isEmpty {
                    runHistoryCard(slot: s)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 14)
                }

                primaryActionButton

                if hasActiveRun {
                    seferSecButton
                        .padding(.top, 10)
                }

                perkShopButton
                    .padding(.top, 10)

                Spacer(minLength: 12)

                hubPills

                Spacer(minLength: 12)

                currencyFooter
            }
            .padding(.bottom, 32)

            if showDailyReward {
                DailyRewardOverlay(isPresented: $showDailyReward)
                    .environmentObject(userEnv)
                    .zIndex(10)
            }

            if showHubIntro {
                hubIntroOverlay
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .zIndex(20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            AudioManager.shared.playMusic(.menu)
            if let s = slot, !s.isEmpty {
                userEnv.loadFromSlot(s)
            }

            // İlk kez Hub'a gelen oyuncuya kısa yönlendirme (tek sefer)
            if !userEnv.hubIntroShown {
                userEnv.hubIntroShown = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        showHubIntro = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showHubIntro = false
                        }
                    }
                }
            }
        }
    }

    private var hubIntroOverlay: some View {
        VStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(userEnv.localizedString("HUB İPUCU", "HUB TIP"))
                    .font(.setCustomFont(name: .InterBlack, size: 12))
                    .tracking(2)
                    .foregroundStyle(ThemeColors.electricYellow)
                Text(userEnv.localizedString(
                    "Sefer için 'SEFERE BAŞLA'ya bas. Market, Galeri ve Karakter buradan açılır.",
                    "Tap 'START CAMPAIGN' to begin. Market, Gallery and Character open from here."
                ))
                .font(.setCustomFont(name: .InterMedium, size: 12))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(ThemeColors.hudBg.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(ThemeColors.electricYellow.opacity(0.35), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.top, 70)
            Spacer()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                HapticManager.shared.play(.buttonTap)
                userEnv.clearActiveSlot()
                MainViewsRouter.shared.popToDashboard()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text(userEnv.localizedString("SLOT", "SLOTS"))
                        .tracking(2)
                }
                .font(.setCustomFont(name: .InterBold, size: 12))
                .foregroundStyle(ThemeColors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(ThemeColors.surfaceDark)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(ThemeColors.gridStroke.opacity(0.4), lineWidth: 1))
            }

            Spacer()

            Button {
                HapticManager.shared.play(.buttonTap)
                showDailyReward = true
            } label: {
                ZStack {
                    Circle()
                        .fill(ThemeColors.surfaceDark)
                        .frame(width: 40, height: 40)
                        .overlay(Circle().stroke(ThemeColors.gridStroke, lineWidth: 1))
                    Image(systemName: "gift.fill")
                        .foregroundStyle(userEnv.canClaimDaily ? ThemeColors.electricYellow : ThemeColors.textMuted)
                        .font(.system(size: 16, weight: .bold))
                    if userEnv.canClaimDaily {
                        Circle()
                            .fill(ThemeColors.neonPink)
                            .frame(width: 9, height: 9)
                            .offset(x: 12, y: -12)
                    }
                }
            }

            Button {
                HapticManager.shared.play(.buttonTap)
                MainViewsRouter.shared.present(view: MainNavigationView.builder.makeView(
                    SettingsView().environmentObject(userEnv),
                    withNavigationTitle: "", navigationBarHidden: true
                ))
            } label: {
                Image("ui_settings")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .background(ThemeColors.surfaceDark)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(ThemeColors.gridStroke, lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    // MARK: - Character Card

    private var characterCard: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(ThemeColors.surfaceDark)
                    .frame(width: 180, height: 180)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(ThemeColors.neonCyan.opacity(0.55), lineWidth: 1.5)
                    )
                    .shadow(color: ThemeColors.neonCyan.opacity(0.25), radius: 22)

                Image(character.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 172, height: 172)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            }
            .characterMasteryFrame(characterId: character.id, cornerRadius: 28)

            Text(character.name)
                .font(.setCustomFont(name: .InterBlack, size: 22))
                .foregroundStyle(ThemeColors.neonCyan)
                .tracking(3)

            CharacterMasteryBadge(characterId: character.id)

            HStack(spacing: 6) {
                pillTag(text: userEnv.localizedString("SLOT \(slotId)", "SLOT \(slotId)"), color: ThemeColors.electricYellow)
                if let s = slot, !s.isEmpty {
                    pillTag(
                        text: userEnv.localizedString("DÜNYA \(s.unlockedWorldLevel)", "WORLD \(s.unlockedWorldLevel)"),
                        color: ThemeColors.neonPurple
                    )
                    pillTag(
                        text: userEnv.localizedString("TUR \(s.currentRound)", "ROUND \(s.currentRound)"),
                        color: ThemeColors.neonPink
                    )
                } else {
                    pillTag(text: userEnv.localizedString("YENİ BAŞLANGIÇ", "FRESH START"), color: ThemeColors.neonPink)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func pillTag(text: String, color: Color) -> some View {
        Text(text)
            .font(.setCustomFont(name: .InterBold, size: 10))
            .tracking(1.5)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }

    private func runHistoryCard(slot: SaveSlot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(userEnv.localizedString("RUN GEÇMİŞİ", "RUN HISTORY"))
                    .font(.setCustomFont(name: .InterBlack, size: 12))
                    .tracking(2)
                    .foregroundStyle(ThemeColors.textSecondary)
                Spacer()
                Text(userEnv.localizedString("BEST \(slot.bestScore)", "BEST \(slot.bestScore)"))
                    .font(.setCustomFont(name: .InterBold, size: 11))
                    .foregroundStyle(ThemeColors.electricYellow)
            }

            if let last = slot.lastRunSummary {
                VStack(alignment: .leading, spacing: 6) {
                    let charName = GameCharacter.roster.first(where: { $0.id == last.characterId })?.name ?? last.characterId
                    Text(userEnv.localizedString("SON RUN ÖZETİ", "LAST RUN SUMMARY"))
                        .font(.setCustomFont(name: .InterBold, size: 11))
                        .foregroundStyle(ThemeColors.textMuted)
                        .tracking(1.5)
                    HStack(spacing: 10) {
                        pillTag(text: charName, color: ThemeColors.neonCyan)
                        pillTag(text: "W\(last.worldLevelReached)", color: ThemeColors.neonPurple)
                        pillTag(text: "\(last.score) PTS", color: ThemeColors.electricYellow)
                    }
                    HStack(spacing: 10) {
                        pillTag(text: userEnv.localizedString("ALTIN \(last.goldTotal)", "GOLD \(last.goldTotal)"), color: ThemeColors.electricYellow)
                        pillTag(text: userEnv.localizedString("PERK \(last.perksCount)", "PERK \(last.perksCount)"), color: ThemeColors.neonPurple)
                        if last.wasTrial {
                            pillTag(text: userEnv.localizedString("TRIAL RUN", "TRIAL RUN"), color: ThemeColors.neonPink)
                        }
                    }
                }
                .padding(.bottom, 6)
            }

            HStack(spacing: 10) {
                pillTag(
                    text: userEnv.localizedString("EN YÜKSEK WORLD \(slot.bestWorldLevel)", "MAX WORLD \(slot.bestWorldLevel)"),
                    color: ThemeColors.neonPurple
                )
                pillTag(
                    text: userEnv.localizedString("SON RUN \(slot.currentRound) / \(slot.currentScore)", "LAST \(slot.currentRound) / \(slot.currentScore)"),
                    color: ThemeColors.neonCyan
                )
            }

            if slot.recentRuns.isEmpty {
                Text(userEnv.localizedString("Henüz run geçmişi yok.", "No run history yet."))
                    .font(.setCustomFont(name: .InterMedium, size: 12))
                    .foregroundStyle(ThemeColors.textMuted)
            } else {
                VStack(spacing: 8) {
                    ForEach(slot.recentRuns.prefix(3)) { r in
                        HStack(spacing: 10) {
                            let name = GameCharacter.roster.first(where: { $0.id == r.characterId })?.name ?? r.characterId
                            Text(name)
                                .font(.setCustomFont(name: .InterBold, size: 11))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .frame(width: 110, alignment: .leading)

                            Spacer(minLength: 0)

                            Text("W\(r.worldLevelReached)")
                                .font(.setCustomFont(name: .InterBold, size: 11))
                                .foregroundStyle(ThemeColors.neonPurple)

                            Text("\(r.score)")
                                .font(.setCustomFont(name: .InterBlack, size: 12))
                                .foregroundStyle(ThemeColors.electricYellow)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(ThemeColors.surfaceDark.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ThemeColors.gridStroke.opacity(0.25), lineWidth: 1))
                    }
                }
            }
        }
        .padding(14)
        .background(ThemeColors.surfaceDark.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(ThemeColors.gridStroke.opacity(0.35), lineWidth: 1))
    }

    // MARK: - Primary Action

    private var primaryActionButton: some View {
        Button {
            HapticManager.shared.play(.buttonTap)
            if hasActiveRun {
                // Aktif chapter map varsa — oyuncu boss'a giden yolun ortasındaydı
                MainViewsRouter.shared.pushToMap(slotId: slotId)
            } else {
                // Slot dolu ama aktif map yok → yeni seçim için WorldSelection'a git
                // (karakter & perk zaten slot'ta kayıtlı, tekrar seçtirme)
                if let s = SaveManager.shared.slots.first(where: { $0.id == slotId }) {
                    userEnv.loadFromSlot(s)
                }
                MainViewsRouter.shared.push(
                    WorldSelectionView(slotId: slotId).environmentObject(UserEnvironment.shared)
                )
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: hasActiveRun ? "play.circle.fill" : "map.fill")
                    .font(.system(size: 22, weight: .bold))
                Text(hasActiveRun
                     ? userEnv.localizedString("SEFERE DEVAM", "CONTINUE RUN")
                     : userEnv.localizedString("SEFERE BAŞLA", "START CAMPAIGN"))
                    .font(.setCustomFont(name: .InterExtraBold, size: 22))
                    .tracking(4)
            }
            .foregroundStyle(ThemeColors.cosmicBlack)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ThemeColors.electricYellow)
                    .shadow(color: ThemeColors.electricYellow.opacity(0.55), radius: 18)
            )
        }
        .padding(.horizontal, 32)
    }

    private var seferSecButton: some View {
        Button {
            HapticManager.shared.play(.selection)
            MainViewsRouter.shared.push(
                WorldSelectionView(slotId: slotId).environmentObject(UserEnvironment.shared)
            )
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "globe.europe.africa.fill")
                    .font(.system(size: 16, weight: .bold))
                Text(userEnv.localizedString("SEFER SEÇ", "SELECT CAMPAIGN"))
                    .font(.setCustomFont(name: .InterBold, size: 14))
                    .tracking(3)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(ThemeColors.surfaceDark.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(ThemeColors.neonCyan.opacity(0.35), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 32)
    }

    private var perkShopButton: some View {
        Button {
            HapticManager.shared.play(.selection)
            MainViewsRouter.shared.push(
                PerkShopView(slotId: slotId).environmentObject(UserEnvironment.shared)
            )
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                Text(userEnv.localizedString("PERK DÜKKANI", "PERK SHOP"))
                    .font(.setCustomFont(name: .InterBold, size: 14))
                    .tracking(3)
                Spacer()
                // Kilitli perk sayısı badge
                let locked = StartingPerk.available.filter {
                    $0.tier > 1 && !(slot?.unlockedPerkIDs.contains($0.id) ?? false)
                }.count
                if locked > 0 {
                    Text("\(locked) kilitli")
                        .font(.setCustomFont(name: .InterBold, size: 10))
                        .foregroundStyle(ThemeColors.electricYellow)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(ThemeColors.electricYellow.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(ThemeColors.electricYellow)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(ThemeColors.electricYellow.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(ThemeColors.electricYellow.opacity(0.35), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 32)
    }

    // MARK: - Pills (Market/Character/Gallery)

    private var hubPills: some View {
        HStack(spacing: 10) {
            hubPill(
                icon: "person.2.fill",
                title: userEnv.localizedString("KARAKTER", "CHARACTER"),
                color: ThemeColors.neonCyan
            ) {
                MainViewsRouter.shared.pushToCharacterSelection(slotId: slotId, mode: .changeInHub)
            }
            hubPill(
                icon: "storefront.fill",
                title: userEnv.localizedString("MARKET", "UPGRADES"),
                color: ThemeColors.electricYellow
            ) {
                MainViewsRouter.shared.present(view: MainNavigationView.builder.makeView(
                    UpgradesView(slotId: slotId).environmentObject(userEnv),
                    withNavigationTitle: "", navigationBarHidden: true
                ))
            }
            hubPill(
                icon: "books.vertical.fill",
                title: userEnv.localizedString("GALERİ", "GALLERY"),
                color: ThemeColors.neonPurple
            ) {
                MainViewsRouter.shared.present(view: MainNavigationView.builder.makeView(
                    CollectionMainView().environmentObject(userEnv),
                    withNavigationTitle: "", navigationBarHidden: true
                ))
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func hubPill(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.shared.play(.buttonTap)
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.setCustomFont(name: .InterBold, size: 12))
                    .tracking(1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.35), lineWidth: 1))
        }
    }

    // MARK: - Currency footer

    private var currencyFooter: some View {
        HStack(spacing: 24) {
            currencyBadge(iconName: "icon_gold", value: userEnv.gold, color: ThemeColors.electricYellow)
            currencyBadge(iconName: "icon_diamond", value: userEnv.diamonds, color: ThemeColors.neonCyan)
        }
    }

    private func currencyBadge(iconName: String, value: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(iconName).resizable().frame(width: 22, height: 22)
            Text("\(value)")
                .font(.setCustomFont(name: .InterBold, size: 15))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }

    // MARK: - Background decoration

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
    SlotHubView(slotId: 1)
        .environmentObject(UserEnvironment.shared)
}
