//
//  Block_JackApp.swift
//  Block-Jack
//

import SwiftUI

@main
struct Block_JackApp: App {
    @StateObject private var userEnv = UserEnvironment.shared
    @State private var isSplashActive = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                AppRootView()
                    .environmentObject(userEnv)
                    .preferredColorScheme(.dark)
                
                if isSplashActive {
                    SplashScreenView {
                        isSplashActive = false
                    }
                    .zIndex(10)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isSplashActive)
        }
    }
}

// MARK: - AppRootView
// UINavigationController'ı SwiftUI'ye bağlar ve MainViewsRouter'a kaydeder.
struct AppRootView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @State private var nav = UINavigationController()

    var body: some View {
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
    }
}
