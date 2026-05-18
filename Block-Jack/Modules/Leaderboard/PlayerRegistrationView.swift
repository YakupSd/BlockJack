//
//  PlayerRegistrationView.swift
//  Block-Jack
//
//  Oyuncu kayıt formu — username, ad, soyad, email vb.
//

import SwiftUI
import Combine

struct PlayerRegistrationView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var vm = LeaderboardViewModel()
    
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var phone: String = ""
    
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    @State private var agreeToTerms: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    
    var body: some View {
        ZStack {
            ThemeColors.cosmicBlack.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if userEnv.isRegistered {
                        registeredView
                    } else {
                        formSection
                    }
                }
                .padding(24)
            }
        }
        .onAppear {
            // Load persisted data
            username = userEnv.username
            fullName = userEnv.fullName.isEmpty ? (UserDefaults.standard.string(forKey: "formFullName") ?? "") : userEnv.fullName
            email = userEnv.email.isEmpty ? (UserDefaults.standard.string(forKey: "formEmail") ?? "") : userEnv.email
        }
        .onDisappear {
            // Save form data even if dismissed
            UserDefaults.standard.set(fullName, forKey: "formFullName")
            UserDefaults.standard.set(email, forKey: "formEmail")
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Dismiss Button
            HStack {
                Button {
                    HapticManager.shared.play(.buttonTap)
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
                Spacer()
            }
            .padding(.bottom, -20) // Bring icon closer to dismiss
            
            // Icon background container
            ZStack {
                Circle()
                    .fill(ThemeColors.neonCyan.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .stroke(ThemeColors.neonCyan.opacity(0.3), lineWidth: 2)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                ThemeColors.electricYellow,
                                ThemeColors.neonCyan
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: ThemeColors.neonCyan.opacity(0.5), radius: 15)
            }
            .padding(.top, 12)
            
            Text(userEnv.labelLeaderboardProfile)
                .font(.setCustomFont(name: .InterBlack, size: 28))
                .foregroundStyle(.white)
                .tracking(-0.5)
            
            Text(userEnv.labelLeaderboardProfileDesc)
                .font(.setCustomFont(name: .InterMedium, size: 15))
                .foregroundStyle(ThemeColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }
    
    // MARK: - Form
    
    private var formSection: some View {
        VStack(spacing: 20) {
            inputField(
                icon: "at",
                placeholder: userEnv.labelUsernameInGame,
                text: $username
            )
            
            // Username validation hint
            if !username.isEmpty && !isValidUsername(username) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeColors.neonOrange)
                    
                    Text(userEnv.labelUsernameValidation)
                        .font(.setCustomFont(name: .InterMedium, size: 12))
                        .foregroundStyle(ThemeColors.neonOrange)
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            inputField(
                icon: "person.fill",
                placeholder: userEnv.labelFullName,
                text: $fullName
            )
            
            // Fullname validation hint
            if !fullName.isEmpty && !isValidFullName(fullName) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeColors.neonOrange)
                    
                    Text(userEnv.labelFullNameValidation)
                        .font(.setCustomFont(name: .InterMedium, size: 12))
                        .foregroundStyle(ThemeColors.neonOrange)
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            inputField(
                icon: "envelope.fill",
                placeholder: userEnv.labelEmailAddress,
                text: $email,
                keyboardType: .emailAddress
            )
            
            // Email validation hint
            if !email.isEmpty && !isValidEmail(email) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeColors.neonOrange)
                    
                    Text(userEnv.labelEmailValidation)
                        .font(.setCustomFont(name: .InterMedium, size: 12))
                        .foregroundStyle(ThemeColors.neonOrange)
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            secureInputField(
                icon: "lock.fill",
                placeholder: userEnv.labelPassword,
                text: $password
            )
            
            if !password.isEmpty && !isValidPassword(password) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeColors.neonOrange)
                    
                    Text(userEnv.labelPasswordValidation)
                        .font(.setCustomFont(name: .InterMedium, size: 12))
                        .foregroundStyle(ThemeColors.neonOrange)
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            secureInputField(
                icon: "lock.rotation",
                placeholder: userEnv.labelConfirmPassword,
                text: $confirmPassword
            )
            
            if !confirmPassword.isEmpty && password != confirmPassword {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeColors.neonOrange)
                    
                    Text(userEnv.labelPasswordMismatch)
                        .font(.setCustomFont(name: .InterMedium, size: 12))
                        .foregroundStyle(ThemeColors.neonOrange)
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            if let err = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeColors.danger)
                    
                    Text(err)
                        .font(.setCustomFont(name: .InterMedium, size: 12))
                        .foregroundStyle(ThemeColors.danger)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(ThemeColors.danger.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            if let msg = successMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeColors.success)
                    
                    Text(msg)
                        .font(.setCustomFont(name: .InterBold, size: 12))
                        .foregroundStyle(ThemeColors.success)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(ThemeColors.success.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Terms & Privacy Checkbox
            HStack(spacing: 12) {
                Button {
                    HapticManager.shared.play(.selection)
                    agreeToTerms.toggle()
                } label: {
                    Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                        .font(.system(size: 18))
                        .foregroundStyle(agreeToTerms ? ThemeColors.electricYellow : ThemeColors.textMuted)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 2) {
                        Text(userEnv.labelAgreeTo)
                            .font(.setCustomFont(name: .InterMedium, size: 12))
                            .foregroundStyle(ThemeColors.textMuted)
                        
                        Link(destination: URL(string: "https://frimpeksservice.com/terms") ?? URL(fileURLWithPath: "")) {
                            Text(userEnv.labelTermsOfService)
                                .font(.setCustomFont(name: .InterMedium, size: 12))
                                .foregroundStyle(ThemeColors.neonCyan)
                                .underline()
                        }
                    }
                    
                    HStack(spacing: 2) {
                        Text(userEnv.labelAnd)
                            .font(.setCustomFont(name: .InterMedium, size: 12))
                            .foregroundStyle(ThemeColors.textMuted)
                        
                        Link(destination: URL(string: "https://frimpeksservice.com/privacy") ?? URL(fileURLWithPath: "")) {
                            Text(userEnv.labelPrivacyPolicy)
                                .font(.setCustomFont(name: .InterMedium, size: 12))
                                .foregroundStyle(ThemeColors.neonCyan)
                                .underline()
                        }
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(agreeToTerms ? ThemeColors.neonCyan.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
            )
            
            Button {
                HapticManager.shared.play(.buttonTap)
                submitForm()
            } label: {
                ZStack {
                    Capsule()
                        .fill(isValid && agreeToTerms ? ThemeColors.electricYellow : ThemeColors.surfaceDark)
                    
                    if isSubmitting {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(ThemeColors.cosmicBlack)
                            
                            Text(userEnv.labelRegisteringCaps)
                                .font(.setCustomFont(name: .InterBlack, size: 14))
                                .foregroundStyle(ThemeColors.cosmicBlack)
                        }
                    } else {
                        Text(userEnv.labelRegisterCaps)
                            .font(.setCustomFont(name: .InterBlack, size: 16))
                            .foregroundStyle(isValid && agreeToTerms ? ThemeColors.cosmicBlack : ThemeColors.textMuted)
                    }
                }
                .frame(height: 56)
                .shadow(
                    color: isValid && agreeToTerms ? ThemeColors.electricYellow.opacity(0.4) : .clear,
                    radius: isValid && agreeToTerms ? 15 : 0
                )
            }
            .disabled(!isValid || !agreeToTerms || isSubmitting)
            .opacity(isSubmitting ? 0.8 : 1.0)
        }
    }
    
    // MARK: - Registered View
    
    private var registeredView: some View {
        VStack(spacing: 24) {
            // Profile card
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(ThemeColors.success)
                    
                    Text(userEnv.labelRegisteredProfile)
                        .font(.setCustomFont(name: .InterBold, size: 14))
                        .foregroundStyle(ThemeColors.success)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(userEnv.labelUsername)
                        .font(.setCustomFont(name: .InterMedium, size: 12))
                        .foregroundStyle(ThemeColors.textMuted)
                        .tracking(0.5)
                    
                    Text(userEnv.username)
                        .font(.setCustomFont(name: .InterBlack, size: 28))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.system(size: 12))
                            .foregroundStyle(ThemeColors.neonCyan)
                        
                        Text(userEnv.playerCountryCode)
                            .font(.setCustomFont(name: .InterBold, size: 14))
                            .foregroundStyle(ThemeColors.neonPurple)
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ThemeColors.success.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ThemeColors.success.opacity(0.2), lineWidth: 1.5)
            )
            
            // Action buttons
            VStack(spacing: 12) {
                Button {
                    HapticManager.shared.play(.buttonTap)
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                        
                        Text(userEnv.labelContinue)
                            .font(.setCustomFont(name: .InterBold, size: 16))
                    }
                    .foregroundStyle(ThemeColors.cosmicBlack)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(ThemeColors.electricYellow)
                    .clipShape(Capsule())
                    .shadow(color: ThemeColors.electricYellow.opacity(0.4), radius: 15)
                }
                
                Button {
                    HapticManager.shared.play(.buttonTap)
                    showDeleteConfirmation = true
                } label: {
                    Text(userEnv.labelDeleteAccount)
                        .font(.setCustomFont(name: .InterMedium, size: 14))
                        .foregroundStyle(ThemeColors.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ThemeColors.danger.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ThemeColors.danger.opacity(0.2), lineWidth: 1)
                        )
                }
            }
        }
        .alert(userEnv.labelDeleteAccount, isPresented: $showDeleteConfirmation) {
            Button(userEnv.labelCancel, role: .cancel) {
                HapticManager.shared.play(.buttonTap)
            }
            
            Button(userEnv.labelDeleteCaps, role: .destructive) {
                HapticManager.shared.play(.warning)
                deleteAccount()
            }
        } message: {
            Text(userEnv.labelDeleteAccountDesc)
        }
    }
    
    // MARK: - Helpers
    
    private func inputField(icon: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(text.wrappedValue.isEmpty ? ThemeColors.textMuted : ThemeColors.neonCyan)
                .frame(width: 24)
                .transition(.scale)
            
            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.setCustomFont(name: .InterMedium, size: 16))
                        .foregroundStyle(ThemeColors.textMuted)
                }
                TextField("", text: text)
                    .font(.setCustomFont(name: .InterMedium, size: 16))
                    .foregroundStyle(.white)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .tint(ThemeColors.neonCyan)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(text.wrappedValue.isEmpty ? 
                    Color.black.opacity(0.3) : 
                    Color.black.opacity(0.5)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    text.wrappedValue.isEmpty ? 
                        Color.white.opacity(0.15) : 
                        ThemeColors.neonCyan.opacity(0.6),
                    lineWidth: text.wrappedValue.isEmpty ? 1 : 2
                )
        )
        .shadow(
            color: text.wrappedValue.isEmpty ? 
                .clear : 
                ThemeColors.neonCyan.opacity(0.25),
            radius: 12,
            x: 0,
            y: 0
        )
    }
    
    // MARK: - Validators
    
    private var isValid: Bool {
        isValidUsername(username) &&
        isValidFullName(fullName) &&
        isValidEmail(email) &&
        isValidPassword(password) &&
        password == confirmPassword &&
        agreeToTerms
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        let upperCase = CharacterSet.uppercaseLetters
        let lowerCase = CharacterSet.lowercaseLetters
        let digits = CharacterSet.decimalDigits
        return password.count >= 8 &&
            password.rangeOfCharacter(from: upperCase) != nil &&
            password.rangeOfCharacter(from: lowerCase) != nil &&
            password.rangeOfCharacter(from: digits) != nil
    }

    private func secureInputField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(text.wrappedValue.isEmpty ? ThemeColors.textMuted : ThemeColors.neonCyan)
                .frame(width: 24)
                .transition(.scale)
            
            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.setCustomFont(name: .InterMedium, size: 16))
                        .foregroundStyle(ThemeColors.textMuted)
                }
                SecureField("", text: text)
                    .font(.setCustomFont(name: .InterMedium, size: 16))
                    .foregroundStyle(.white)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .tint(ThemeColors.neonCyan)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(text.wrappedValue.isEmpty ?
                    Color.black.opacity(0.3) :
                    Color.black.opacity(0.5)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    text.wrappedValue.isEmpty ?
                        Color.white.opacity(0.15) :
                        ThemeColors.neonCyan.opacity(0.6),
                    lineWidth: text.wrappedValue.isEmpty ? 1 : 2
                )
        )
        .shadow(
            color: text.wrappedValue.isEmpty ?
                .clear :
                ThemeColors.neonCyan.opacity(0.25),
            radius: 12,
            x: 0,
            y: 0
        )
    }

    private func isValidEmail(_ email: String) -> Bool {
        // RFC 5322 simplified pattern
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailPattern)
        return predicate.evaluate(with: email)
    }
    
    private func isValidUsername(_ username: String) -> Bool {
        // 3-20 karakter, alphanumeric + underscore + hyphen
        let usernamePattern = "^[a-zA-Z0-9_-]{3,20}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", usernamePattern)
        return predicate.evaluate(with: username)
    }
    
    private func isValidFullName(_ name: String) -> Bool {
        // En az 3 karakter, sadece harf ve boşluk/tire
        let namePattern = "^[a-zA-ZçğıöşüÇĞİÖŞÜ\\s-]{3,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", namePattern)
        return predicate.evaluate(with: name)
    }
    
    private func submitForm() {
        guard isValid else { return }
        isSubmitting = true
        errorMessage = nil
        successMessage = nil
        
        Task { @MainActor in
            // 1. Check username availability
            let usernameCheck = await vm.checkUsernameAvailable(username)
            if case .failure(let err) = usernameCheck {
                HapticManager.shared.play(.error)
                errorMessage = err.localizedDescription ?? userEnv.labelUsernameTaken
                isSubmitting = false
                return
            }
            
            // 2. Update Username (if different)
            if username != userEnv.username {
                let userResult = await vm.updatePlayer(username: username)
                if case .failure(let err) = userResult {
                    HapticManager.shared.play(.error)
                    errorMessage = err.localizedDescription
                    isSubmitting = false
                    return
                }
                userEnv.username = username
            }
            
            // 3. Oyuncu kaydını API'da garanti altına al (0 veya mevcut rekor ile)
            await vm.ensurePlayerExistsOnServer(username: username)
            
            // 4. Register
            let regResult = await vm.registerPlayer(
                fullName: fullName,
                email: email
            )
            
            isSubmitting = false
            
            switch regResult {
            case .success:
                userEnv.isRegistered = true
                userEnv.fullName = fullName
                userEnv.email = email
                userEnv.setLeaderboardPassword(password)
                
                // 4. Transfer guest scores to server
                await vm.transferGuestScoresToServer(username: username, userEnv: userEnv)
                
                successMessage = userEnv.labelRegistrationSuccessful
                HapticManager.shared.play(.success)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            case .failure(let error):
                HapticManager.shared.play(.error)
                if case .conflict(let message) = error {
                    if message.lowercased().contains("email") {
                        errorMessage = userEnv.labelEmailTaken
                    } else if message.lowercased().contains("username") || message.lowercased().contains("player") {
                        errorMessage = userEnv.labelUsernameTaken
                    } else {
                        errorMessage = message
                    }
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func deleteAccount() {
        Task { @MainActor in
            isSubmitting = true
            errorMessage = nil
            
            let result = await vm.deleteAllData()
            isSubmitting = false
            
            switch result {
            case .success:
                HapticManager.shared.play(.success)
                userEnv.clearRegistration()
                userEnv.username = "Player_\(String(DeviceIdentifier.deviceID.prefix(6)))"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            case .failure(let error):
                HapticManager.shared.play(.error)
                errorMessage = userEnv.labelDeleteFailedTemplate.replacingOccurrences(of: "{{error}}", with: error.localizedDescription)
            }
        }
    }
}
