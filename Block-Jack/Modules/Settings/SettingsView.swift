//
//  SettingsView.swift
//  Block-Jack
//

import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    
    var body: some View {
        ZStack {
            ThemeColors.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 32) {
                // MARK: - Header
                HStack {
                    Button {
                        HapticManager.shared.play(.buttonTap)
                        MainViewsRouter.shared.dismissModal()
                    } label: {
                        Image("ui_close")
                            .resizable()
                            .frame(width: 44, height: 44)
                            .background(ThemeColors.surfaceDark)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text(userEnv.localizedString("AYARLAR", "SETTINGS"))
                        .font(.setCustomFont(name: .InterBlack, size: 24))
                        .foregroundStyle(ThemeColors.neonCyan)
                        .tracking(2)
                    
                    Spacer()
                    
                    // placeholder to balance header
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // MARK: - Settings List
                VStack(spacing: 20) {
                    
                    // Ses
                    settingToggleRow(
                        title: userEnv.localizedString("Ses Efektleri", "Sound Effects"),
                        icon: "icon_sound",
                        isOn: $userEnv.isSoundEnabled
                    )
                    
                    // Titreşim
                    settingToggleRow(
                        title: userEnv.localizedString("Titreşim (Haptic)", "Haptics"),
                        icon: "icon_haptic",
                        isOn: $userEnv.isHapticEnabled
                    )
                    
                    Divider().background(ThemeColors.gridStroke)
                    
                    // Dil Seçimi
                    VStack(alignment: .leading, spacing: 12) {
                        Text(userEnv.localizedString("Dil Seçimi", "Language"))
                            .font(.setCustomFont(name: .InterBold, size: 14))
                            .foregroundStyle(ThemeColors.textSecondary)
                        
                        HStack(spacing: 16) {
                            languageButton(for: .turkish)
                            languageButton(for: .english)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider().background(ThemeColors.gridStroke)
                    
                    // Apple Login
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            // Handle authentication
                            HapticManager.shared.play(.success)
                        case .failure(let error):
                            print("Auth failed: \(error.localizedDescription)")
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.top, 8)
                    
                    Divider().background(ThemeColors.gridStroke)
                    
                    // Nasıl Oynanır? (Re-run Tutorial)
                    Button {
                        HapticManager.shared.play(.selection)
                        userEnv.tutorialCompleted = false
                        MainViewsRouter.shared.dismissModal()
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                            Text(userEnv.localizedString("Nasıl Oynanır?", "How to Play"))
                                .font(.setCustomFont(name: .InterBold, size: 16))
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(ThemeColors.neonCyan)
                        .padding(.vertical, 8)
                    }
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(ThemeColors.gridStroke.opacity(0.5), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.3), radius: 20)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Subviews
    
    private func settingToggleRow(title: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            Image(icon)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(ThemeColors.neonCyan)
                .frame(width: 32, height: 32)
            
            Text(title)
                .font(.setCustomFont(name: .InterBold, size: 16))
                .foregroundStyle(.white)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .tint(ThemeColors.neonCyan)
                .onChange(of: isOn.wrappedValue) { newValue in
                    if newValue { HapticManager.shared.play(.buttonTap) }
                }
        }
    }
    
    private func languageButton(for lang: AppLanguage) -> some View {
        let isSelected = userEnv.language == lang
        
        return Button {
            HapticManager.shared.play(.buttonTap)
            userEnv.language = lang
        } label: {
            Text(lang.displayName)
                .font(.setCustomFont(name: isSelected ? .InterBold : .InterMedium, size: 14))
                .foregroundStyle(isSelected ? ThemeColors.cosmicBlack : .white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(isSelected ? ThemeColors.neonCyan : ThemeColors.gridDark)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : ThemeColors.gridStroke, lineWidth: 1)
                )
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(UserEnvironment.shared)
}
