//
//  Block_JackApp.swift
//  Block-Jack
//

import SwiftUI

@main
struct Block_JackApp: App {
    @StateObject private var userEnv = UserEnvironment.shared
    @StateObject private var pushNotifications = PushNotificationManager.shared
    @State private var isSplashActive = true
    @State private var showOfflineSyncToast = false
    @State private var deepLinkAction: DeepLinkAction? = nil

    var body: some Scene {
        WindowGroup {
            ZStack {
                AppRootView(deepLinkAction: $deepLinkAction)
                    .environmentObject(userEnv)
                    .preferredColorScheme(.dark)

                if let id = userEnv.pendingAchievementToastId,
                   let ach = AchievementEngine.achievement(for: id) {
                    VStack {
                        AchievementToastView(achievement: ach)
                            .environmentObject(userEnv)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        Spacer()
                    }
                    .zIndex(20)
                }
                
                if isSplashActive {
                    SplashScreenView {
                        isSplashActive = false
                    }
                    .zIndex(10)
                    .transition(.opacity)
                }
                if showOfflineSyncToast {
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.icloud.fill")
                                .foregroundStyle(ThemeColors.electricYellow)
                            Text(userEnv.msgOfflineScoresSynced)
                                .font(.setCustomFont(name: .InterBold, size: 14))
                                .foregroundStyle(.white)
                        }
                        .padding(16)
                        .background(ThemeColors.surfaceDark.opacity(0.95))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(ThemeColors.electricYellow.opacity(0.5), lineWidth: 1))
                        .padding(.top, 40)
                        
                        Spacer()
                    }
                    .zIndex(30)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isSplashActive)
            .animation(.spring(), value: showOfflineSyncToast)
            .onAppear {
                Task {
                    let didSync = await LeaderboardAPIService.shared.retryPendingSubmissions()
                    if didSync {
                        withAnimation { showOfflineSyncToast = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation { showOfflineSyncToast = false }
                        }
                    }
                }
            }
            .onOpenURL { url in
                if let action = DeepLinkHandler.handle(url) {
                    self.deepLinkAction = action
                }
            }
        }
    }
}

// MARK: - AppRootView
// UINavigationController'ı SwiftUI'ye bağlar ve MainViewsRouter'a kaydeder.
struct AppRootView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @State private var nav = UINavigationController()
    @Binding var deepLinkAction: DeepLinkAction?

    var body: some View {
        ZStack {
            RootNavigationController(
                nav: nav,
                rootView: AppStartView().environmentObject(userEnv), // AppStartView'dan başlıyoruz
                navigationBarTitle: "",
                navigationBarHidden: true
            )
            .ignoresSafeArea()
            .onAppear {
                MainViewsRouter.shared.nav = nav
            }
            .onChange(of: deepLinkAction) { oldVal, newVal in
                handleDeepLink(newVal)
            }
        }
    }
    
    private func handleDeepLink(_ action: DeepLinkAction?) {
        guard let action = action else { return }
        
        switch action {
        case .friendInvite(let code):
            // Davet kodunu işle
            print("Deep Link: Friend invite code \(code)")
            // SocialView'a navigate et ve kodun kabulünü başlat
            // TODO: SocialView'a geçiş + davet kodu redemption
            
        case .viewDuel(let duelID):
            // Düello detayını aç
            print("Deep Link: View duel \(duelID)")
            // TODO: Düello detay view'a navigate et
        }
    }
}
