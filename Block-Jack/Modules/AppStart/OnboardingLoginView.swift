//
//  OnboardingLoginView.swift
//  Block-Jack
//

import SwiftUI
import AuthenticationServices

struct OnboardingLoginView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @StateObject private var vm = LeaderboardViewModel()
    @ObservedObject private var appleAuth = AppleAuthManager.shared
    
    @State private var showEmailRegistration = false
    @State private var isRegisteringApple = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            ThemeColors.cosmicBlack.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Logo & Welcome Text
                VStack(spacing: 16) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(ThemeColors.electricYellow)
                        .shadow(color: ThemeColors.electricYellow.opacity(0.5), radius: 20)
                    
                    Text(userEnv.labelWelcome)
                        .font(.setCustomFont(name: .InterBlack, size: 28))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(userEnv.labelWelcomeDesc)
                        .font(.setCustomFont(name: .InterMedium, size: 14))
                        .foregroundStyle(ThemeColors.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    if let err = errorMessage {
                        Text(err)
                            .font(.setCustomFont(name: .InterMedium, size: 12))
                            .foregroundStyle(ThemeColors.neonOrange)
                            .padding(.bottom, 8)
                    }
                    
                    if isRegisteringApple {
                        HStack(spacing: 12) {
                            ProgressView()
                                .tint(ThemeColors.electricYellow)
                            
                            Text(userEnv.labelConnectingApple)
                                .font(.setCustomFont(name: .InterMedium, size: 14))
                                .foregroundStyle(ThemeColors.electricYellow)
                        }
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(ThemeColors.surfaceDark)
                        .clipShape(Capsule())
                        .padding(.horizontal, 32)
                    } else {
                        // Apple Sign In Button
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                handleAppleCompletion(result: result)
                            }
                        )
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 56)
                        .clipShape(Capsule())
                        .padding(.horizontal, 32)
                        
                        // Email Registration Button
                        Button {
                            HapticManager.shared.play(.buttonTap)
                            showEmailRegistration = true
                        } label: {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text(userEnv.labelRegisterWithEmail)
                                    .font(.setCustomFont(name: .InterBold, size: 16))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            .padding(.horizontal, 32)
                        }
                    }
                    
                    // Guest Button
                    Button {
                        HapticManager.shared.play(.buttonTap)
                        completeOnboarding()
                    } label: {
                        Text(userEnv.labelContinueAsGuest)
                            .font(.setCustomFont(name: .InterMedium, size: 14))
                            .foregroundStyle(ThemeColors.textMuted)
                            .underline()
                            .padding(.vertical, 8)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showEmailRegistration) {
            PlayerRegistrationView()
                .environmentObject(userEnv)
        }
        // Eğer PlayerRegistrationView'den başarılı kayıt dönerse
        .onChange(of: userEnv.isRegistered) { _, registered in
            if registered {
                completeOnboarding()
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleAppleCompletion(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let email = credential.email ?? ""
                var fullName = ""
                if let nameComponents = credential.fullName {
                    let formatter = PersonNameComponentsFormatter()
                    fullName = formatter.string(from: nameComponents)
                }
                let userId = credential.user // This is unique per user
                
                // Eğer isim/email yoksa bile (ikinci giriş) credential.user (userId) her zaman vardır.
                // Apple ile login olan kullanıcıyı Leaderboard'a otomatik register edeceğiz.
                // İsim boşsa "AppleUser_XXX" yapacağız.
                let finalName = fullName.isEmpty ? "Oyuncu_\(String(userId.prefix(6)))" : fullName
                
                registerWithApple(fullName: finalName, email: email, userId: userId)
            }
        case .failure(let error):
            HapticManager.shared.play(.error)
            errorMessage = error.localizedDescription
        }
    }
    
    private func registerWithApple(fullName: String, email: String, userId: String) {
        isRegisteringApple = true
        errorMessage = nil
        
        Task { @MainActor in
            // Generate meaningful username from fullName or email
            let generatedUsername = generateAppleUsername(from: fullName, email: email, userId: userId)
            
            // Önce username update edelim
            _ = await vm.updatePlayer(username: generatedUsername)
            userEnv.username = generatedUsername
            
            // Oyuncu kaydını API'da garanti altına al (0 veya mevcut rekor ile)
            await vm.ensurePlayerExistsOnServer(username: generatedUsername)
            
            // Sonra register
            let result = await vm.registerPlayer(fullName: fullName, email: email)
            
            isRegisteringApple = false
            switch result {
            case .success:
                userEnv.isRegistered = true
                // The onChange handler will call completeOnboarding()
            case .failure(let error):
                HapticManager.shared.play(.error)
                if case .conflict = error {
                    // Zaten kayıtlıysa devam et
                    userEnv.isRegistered = true
                    // The onChange handler will call completeOnboarding()
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func generateAppleUsername(from fullName: String, email: String, userId: String) -> String {
        // 1. Try from fullName: first name + last initial
        let nameParts = fullName.split(separator: " ").map(String.init)
        if nameParts.count >= 2 {
            let firstName = nameParts[0].prefix(8).lowercased()
            let lastInitial = String(nameParts.last?.first ?? Character("")).lowercased()
            let candidate = "\(firstName)\(lastInitial)"
            if candidate.count >= 3 && isValidUsername(candidate) {
                return candidate
            }
        }
        
        // 2. Try from email prefix
        let emailPrefix = email.split(separator: "@").first.map(String.init) ?? ""
        let cleanEmail = emailPrefix.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" }
        if cleanEmail.count >= 3 && cleanEmail.count <= 20 {
            return String(cleanEmail.prefix(15))
        }
        
        // 3. Fallback: Use userId first 6 chars with random suffix
        let randomSuffix = String(userId.suffix(4)).lowercased()
        return "Player_\(randomSuffix)"
    }
    
    private func isValidUsername(_ username: String) -> Bool {
        let pattern = "^[a-zA-Z0-9_-]{3,20}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: username)
    }
    
    private func completeOnboarding() {
        userEnv.hasCompletedOnboarding = true
        MainViewsRouter.shared.popToDashboard()
    }
}
