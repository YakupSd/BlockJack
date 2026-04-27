//
//  DashboardView.swift
//  Block-Jack
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @StateObject private var saveManager = SaveManager.shared
    @State private var showDailyReward: Bool = false
    @State private var titleScale: CGFloat = 0.92
    @State private var titleOpacity: Double = 0.0

    /// En son kaydedilmiş dolu slot (devam için)
    private var latestActiveSlot: SaveSlot? {
        saveManager.slots
            .filter { !$0.isEmpty }
            .sorted { ($0.lastSaved ?? .distantPast) > ($1.lastSaved ?? .distantPast) }
            .first
    }

    /// Hiç dolu slot yok mu?
    private var hasNoSaves: Bool {
        saveManager.slots.allSatisfy { $0.isEmpty }
    }

    var body: some View {
        ZStack {
            // Arka plan
            ThemeColors.backgroundGradient.ignoresSafeArea()
            backgroundGrid

            VStack(spacing: 0) {
                // Üst bar
                HStack(spacing: 12) {
                    Button {
                        HapticManager.shared.play(.buttonTap)
                        showDailyReward = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(ThemeColors.surfaceDark)
                                .frame(width: 44, height: 44)
                                .overlay(Circle().stroke(ThemeColors.gridStroke, lineWidth: 1))
                            Image(systemName: "gift.fill")
                                .foregroundStyle(userEnv.canClaimDaily ? ThemeColors.electricYellow : ThemeColors.textMuted)
                                .font(.system(size: 18, weight: .bold))
                            if userEnv.canClaimDaily {
                                Circle()
                                    .fill(ThemeColors.neonPink)
                                    .frame(width: 10, height: 10)
                                    .offset(x: 14, y: -14)
                            }
                        }
                    }
                    .padding(.leading, 24)

                    Spacer()

                    Button {
                        HapticManager.shared.play(.buttonTap)
                        openStore()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(ThemeColors.surfaceDark)
                                .frame(width: 44, height: 44)
                                .overlay(Circle().stroke(ThemeColors.neonCyan.opacity(0.5), lineWidth: 1))
                            Image(systemName: "cart.fill")
                                .foregroundStyle(ThemeColors.neonCyan)
                                .font(.system(size: 18, weight: .bold))
                            Text("NEW")
                                .font(.setCustomFont(name: .InterBlack, size: 8))
                                .tracking(1)
                                .foregroundStyle(ThemeColors.cosmicBlack)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(ThemeColors.neonPink))
                                .offset(x: 14, y: -14)
                        }
                    }
                    .padding(.trailing, 6)

                    Button {
                        HapticManager.shared.play(.buttonTap)
                        MainViewsRouter.shared.present(view: MainNavigationView.builder.makeView(SettingsView().environmentObject(userEnv), withNavigationTitle: "", navigationBarHidden: true))
                    } label: {
                        Image("ui_settings")
                            .resizable()
                            .frame(width: 44, height: 44)
                            .background(ThemeColors.surfaceDark)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(ThemeColors.gridStroke, lineWidth: 1))
                    }
                    .padding(.trailing, 24)
                }
                .padding(.top, 16)

                Spacer()

                // Logo
                VStack(spacing: 8) {
                    Text("BLOCK")
                        .font(.setCustomFont(name: .InterBlack, size: 56))
                        .foregroundStyle(ThemeColors.neonCyan)
                        .shadow(color: ThemeColors.neonCyan.opacity(0.8), radius: 25)
                        .tracking(10)
                    Text("JACK")
                        .font(.setCustomFont(name: .InterBlack, size: 56))
                        .foregroundStyle(ThemeColors.neonPurple)
                        .shadow(color: ThemeColors.neonPurple.opacity(0.8), radius: 25)
                        .tracking(10)
                    Text("ROGUELITE PUZZLE")
                        .font(.setCustomFont(name: .InterMedium, size: 14))
                        .foregroundStyle(ThemeColors.textSecondary)
                        .tracking(6)
                        .padding(.top, 4)
                        .opacity(0.8)
                }
                .scaleEffect(titleScale)
                .opacity(titleOpacity)
                .padding(.vertical, 20)

                Spacer()

                // En Yüksek Skor
                VStack(spacing: 4) {
                    Text(userEnv.localizedString("EN YÜKSEK SKOR", "HIGH SCORE"))
                        .font(.setCustomFont(name: .InterMedium, size: 11))
                        .foregroundStyle(ThemeColors.textMuted)
                        .tracking(3)
                    Text(userEnv.highScore.formatted())
                        .font(.setCustomFont(name: .InterExtraBold, size: 32))
                        .foregroundStyle(ThemeColors.electricYellow)
                        .shadow(color: ThemeColors.electricYellow.opacity(0.5), radius: 8)
                }
                .padding(.bottom, 32)

                // MAIN ACTION BUTTONS
                VStack(spacing: 12) {
                    if let slot = latestActiveSlot {
                        // — Dolu slot var: Büyük DEVAM ET + küçük Yeni Run
                        continueButton(slot: slot)
                        newRunButton()
                    } else {
                        // — Hiç save yok: tek büyük OYNA butonu
                        firstPlayButton()
                    }

                    // Çoklu slot seçimi için küçük link
                    if saveManager.slots.filter({ !$0.isEmpty }).count > 1 {
                        Button {
                            HapticManager.shared.play(.buttonTap)
                            MainViewsRouter.shared.pushToSaveSlotSelection()
                        } label: {
                            Text(userEnv.localizedString("Diğer Profiller ›", "Other Profiles ›"))
                                .font(.setCustomFont(name: .InterBold, size: 13))
                                .foregroundStyle(ThemeColors.textMuted)
                                .underline()
                        }
                    }
                }
                .padding(.horizontal, 32)

                HStack {
                    dashboardPill(
                        icon: "books.vertical.fill",
                        title: userEnv.localizedString("GALERİ", "GALLERY"),
                        color: ThemeColors.neonPurple
                    ) {
                        MainViewsRouter.shared.present(view: MainNavigationView.builder.makeView(CollectionMainView().environmentObject(userEnv), withNavigationTitle: "", navigationBarHidden: true))
                    }
                    .frame(maxWidth: 200)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)

                HStack(spacing: 24) {
                    Button {
                        HapticManager.shared.play(.buttonTap)
                        openStore()
                    } label: {
                        currencyBadge(iconName: "icon_gold", value: userEnv.gold, color: ThemeColors.electricYellow)
                    }
                    .buttonStyle(.plain)

                    Button {
                        HapticManager.shared.play(.buttonTap)
                        openStore()
                    } label: {
                        currencyBadge(iconName: "icon_diamond", value: userEnv.diamonds, color: ThemeColors.neonCyan)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 24)
                .padding(.bottom, 48)
            }

            if showDailyReward {
                DailyRewardOverlay(isPresented: $showDailyReward)
                    .environmentObject(userEnv)
                    .zIndex(10)
            }
        }
        .onAppear {
            AudioManager.shared.playMusic(.menu)
            userEnv.clearActiveSlot()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                titleScale = 1.0
                titleOpacity = 1.0
            }
        }
    }

    // MARK: - DEVAM ET Butonu (dolu slot)
    @ViewBuilder
    private func continueButton(slot: SaveSlot) -> some View {
        let charName = slot.character?.name ?? ""
        Button {
            HapticManager.shared.play(.heavy)
            userEnv.loadFromSlot(slot)
            // Her zaman SlotHub'a git — oradan
            // "SEFERE DEVAM" (aktif map varsa) veya
            // "SEFERE BAŞLA" (yoksa) secilir.
            MainViewsRouter.shared.pushToSlotHub(slotId: slot.id)
        } label: {
            HStack(spacing: 14) {
                // Karakter portresi
                if let icon = slot.character?.icon {
                    Image(icon)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(ThemeColors.neonCyan.opacity(0.5), lineWidth: 1.5))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(userEnv.localizedString("DEVAM ET", "CONTINUE"))
                        .font(.setCustomFont(name: .InterExtraBold, size: 20))
                        .tracking(3)
                        .foregroundStyle(ThemeColors.cosmicBlack)
                    if !charName.isEmpty {
                        Text("\(charName) · W\(slot.unlockedWorldLevel)")
                            .font(.setCustomFont(name: .InterBold, size: 12))
                            .foregroundStyle(ThemeColors.cosmicBlack.opacity(0.65))
                    }
                }
                Spacer()
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(ThemeColors.cosmicBlack.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(ThemeColors.neonCyan)
                    .shadow(color: ThemeColors.neonCyan.opacity(0.6), radius: 20)
            )
        }
    }

    // MARK: - YENİ RUN Butonu
    @ViewBuilder
    private func newRunButton() -> some View {
        Button {
            HapticManager.shared.play(.buttonTap)
            // Slot seçim ekranı — birden fazla slot varsa seçsin, yoksa ilk boş
            let emptySlot = saveManager.slots.first(where: { $0.isEmpty })
            if let empty = emptySlot {
                MainViewsRouter.shared.pushToCharacterSelection(slotId: empty.id, mode: .firstSetup)
            } else {
                MainViewsRouter.shared.pushToSaveSlotSelection()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 18, weight: .bold))
                Text(userEnv.localizedString("YENİ RUN", "NEW RUN"))
                    .font(.setCustomFont(name: .InterBold, size: 16))
                    .tracking(2)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(ThemeColors.gridStroke.opacity(0.5), lineWidth: 1))
        }
    }

    // MARK: - İLK KERE OynananBUTON
    @ViewBuilder
    private func firstPlayButton() -> some View {
        Button {
            HapticManager.shared.play(.heavy)
            // Slot 1'i kullan (yeni oyuncu için)
            MainViewsRouter.shared.pushToCharacterSelection(slotId: 1, mode: .firstSetup)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 20, weight: .black))
                Text(userEnv.localizedString("OYNA", "PLAY"))
                    .font(.setCustomFont(name: .InterExtraBold, size: 26))
                    .tracking(8)
            }
            .foregroundStyle(ThemeColors.cosmicBlack)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ThemeColors.electricYellow)
                    .shadow(color: ThemeColors.electricYellow, radius: 22)
            )
        }
    }

    // MARK: - Pill Button
    @ViewBuilder
    private func dashboardPill(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
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
    
    // MARK: - Para Göstergesi (tap → mağaza)
    private func currencyBadge(iconName: String, value: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(iconName)
                .resizable()
                .frame(width: 24, height: 24)
            Text("\(value)")
                .font(.setCustomFont(name: .InterBold, size: 16))
                .foregroundStyle(color)
                .contentTransition(.numericText())
            // Eklenti "+" bir mağaza ipucu olarak görünür
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
                .opacity(0.85)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
        .shadow(color: color.opacity(0.1), radius: 5)
    }

    // MARK: - Store Açma
    private func openStore() {
        MainViewsRouter.shared.present(
            view: MainNavigationView.builder.makeView(
                StoreView().environmentObject(userEnv),
                withNavigationTitle: "",
                navigationBarHidden: true
            )
        )
    }

    // MARK: - Decorative grid
    private var backgroundGrid: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 40
            let color = GraphicsContext.Shading.color(ThemeColors.gridStroke.opacity(0.12))
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
    DashboardView()
        .environmentObject(UserEnvironment.shared)
}
