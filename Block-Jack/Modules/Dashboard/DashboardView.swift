//
//  DashboardView.swift
//  Block-Jack
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var userEnv: UserEnvironment

    var body: some View {
        ZStack {
            // Arka plan
            ThemeColors.backgroundGradient.ignoresSafeArea()
            backgroundGrid

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    // AYARLAR BUTONU
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
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                
                Spacer()

                // Logo / Başlık
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
                .padding(.bottom, 40)

                // SEFER (Campaign) Butonu
                Button {
                    HapticManager.shared.play(.buttonTap)
                    MainViewsRouter.shared.pushToSaveSlotSelection(mode: .newGame) // Slot seçilir sonra WorldMap açılır
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text(userEnv.localizedString("SEFER MODU", "CAMPAIGN"))
                            .font(.setCustomFont(name: .InterExtraBold, size: 22))
                            .tracking(4)
                    }
                    .foregroundStyle(ThemeColors.cosmicBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(ThemeColors.neonCyan)
                            .shadow(color: ThemeColors.neonCyan, radius: 16)
                    )
                }
                .padding(.horizontal, 32)

                // DEVAM ET Butonu
                Button {
                    HapticManager.shared.play(.buttonTap)
                    MainViewsRouter.shared.pushToSaveSlotSelection(mode: .continueGame)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text(userEnv.localizedString("KAYITLI OYUN", "CONTINUE"))
                            .font(.setCustomFont(name: .InterExtraBold, size: 20))
                            .tracking(2)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(ThemeColors.gridStroke.opacity(0.3), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.2), radius: 10)
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
                
                // MARKET & GALERİ
                HStack(spacing: 12) {
                    // KAHRAMANLAR (NEW)
                    Button {
                        HapticManager.shared.play(.buttonTap)
                        MainViewsRouter.shared.present(view: MainNavigationView.builder.makeView(CharacterShopView().environmentObject(userEnv), withNavigationTitle: "", navigationBarHidden: true))
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 16))
                            Text(userEnv.localizedString("KAHRAMANLAR", "HEROES"))
                                .font(.setCustomFont(name: .InterBold, size: 14))
                        }
                        .foregroundStyle(ThemeColors.neonCyan)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(ThemeColors.neonCyan.opacity(0.3), lineWidth: 1))
                    }

                    // MARKET
                    Button {
                        HapticManager.shared.play(.buttonTap)
                        MainViewsRouter.shared.present(view: MainNavigationView.builder.makeView(UpgradesView().environmentObject(userEnv), withNavigationTitle: "", navigationBarHidden: true))
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "storefront.fill")
                                .font(.system(size: 16))
                            Text(userEnv.localizedString("MARKET", "UPGRADES"))
                                .font(.setCustomFont(name: .InterBold, size: 14))
                        }
                        .foregroundStyle(ThemeColors.electricYellow)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(ThemeColors.electricYellow.opacity(0.3), lineWidth: 1))
                    }
                }
                .padding(.top, 24)

                // Alt ikonlar (para gösterge)
                HStack(spacing: 24) {
                    currencyBadge(iconName: "icon_gold", value: userEnv.gold, color: ThemeColors.electricYellow)
                    currencyBadge(iconName: "icon_diamond", value: userEnv.diamonds, color: ThemeColors.neonCyan)
                }
                .padding(.top, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            AudioManager.shared.playMusic(.menu)
        }
    }

    // MARK: - Para Göstergesi
    private func currencyBadge(iconName: String, value: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(iconName)
                .resizable()
                .frame(width: 24, height: 24)
            Text("\(value)")
                .font(.setCustomFont(name: .InterBold, size: 16))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
        .shadow(color: color.opacity(0.1), radius: 5)
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
