//
//  ExistingAccountLoginView.swift
//  Block-Jack
//
//  Zaten hesabı olanlar için giriş view'ı.
//  Username girerek var olan hesaba bağlanır ve skorları transfer edilir.
//

import SwiftUI

struct ExistingAccountLoginView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @Binding var isPresented: Bool
    
    @State private var enteredEmail: String = ""
    @State private var password: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    
    var isValid: Bool {
        isValidEmail(enteredEmail) &&
        !password.isEmpty
    }
    
    var body: some View {
        ZStack {
            ThemeColors.cosmicBlack.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(ThemeColors.neonCyan.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Circle()
                                .stroke(ThemeColors.neonCyan.opacity(0.3), lineWidth: 2)
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "person.crop.circle.badge.checkmark.fill")
                                .font(.system(size: 50, weight: .semibold))
                                .foregroundStyle(ThemeColors.neonCyan)
                                .shadow(color: ThemeColors.neonCyan.opacity(0.5), radius: 12)
                        }
                        
                        VStack(spacing: 8) {
                            Text(userEnv.titleLoginAccount)
                                .font(.setCustomFont(name: .InterBlack, size: 24))
                                .foregroundStyle(.white)
                                .tracking(-0.5)
                            
                            Text(userEnv.labelLoginAccountDesc)
                                .font(.setCustomFont(name: .InterMedium, size: 13))
                                .foregroundStyle(ThemeColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 20) {
                        // Email field
                        HStack(spacing: 16) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(enteredEmail.isEmpty ? ThemeColors.textMuted : ThemeColors.neonCyan)
                                .frame(width: 24)
                                .transition(.scale)
                            
                            ZStack(alignment: .leading) {
                                if enteredEmail.isEmpty {
                                    Text(userEnv.labelEmailPlaceholder)
                                        .font(.setCustomFont(name: .InterMedium, size: 16))
                                        .foregroundStyle(ThemeColors.textMuted)
                                }
                                TextField("", text: $enteredEmail)
                                    .font(.setCustomFont(name: .InterMedium, size: 16))
                                    .foregroundStyle(.white)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .tint(ThemeColors.neonCyan)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(enteredEmail.isEmpty ? 
                                    Color.black.opacity(0.3) : 
                                    Color.black.opacity(0.5)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(enteredEmail.isEmpty ? Color.white.opacity(0.1) : ThemeColors.neonCyan.opacity(0.3), lineWidth: 1)
                        )

                        if !enteredEmail.isEmpty && !isValidEmail(enteredEmail) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(ThemeColors.neonOrange)
                                Text(userEnv.labelInvalidEmail)
                                    .font(.setCustomFont(name: .InterMedium, size: 12))
                                    .foregroundStyle(ThemeColors.neonOrange)
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Password field
                        HStack(spacing: 16) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(password.isEmpty ? ThemeColors.textMuted : ThemeColors.neonCyan)
                                .frame(width: 24)
                                .transition(.scale)

                            ZStack(alignment: .leading) {
                                if password.isEmpty {
                                    Text(userEnv.labelPasswordPlaceholder)
                                        .font(.setCustomFont(name: .InterMedium, size: 16))
                                        .foregroundStyle(ThemeColors.textMuted)
                                }
                                SecureField("", text: $password)
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
                                .fill(password.isEmpty ? 
                                    Color.black.opacity(0.3) : 
                                    Color.black.opacity(0.5)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(password.isEmpty ? Color.white.opacity(0.1) : ThemeColors.neonCyan.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Error message
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
                        
                        // Success message
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
                        
                        // Info box
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(ThemeColors.neonCyan)
                                
                                Text(userEnv.labelLoginScoreLinkInfo)
                                    .font(.setCustomFont(name: .InterMedium, size: 12))
                                    .foregroundStyle(ThemeColors.textSecondary)
                            }
                        }
                        .padding(12)
                        .background(ThemeColors.neonCyan.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(ThemeColors.neonCyan.opacity(0.2), lineWidth: 1)
                        )
                        
                        // Submit button
                        Button {
                            HapticManager.shared.play(.buttonTap)
                            submitLogin()
                        } label: {
                            ZStack {
                                Capsule()
                                    .fill(isValid ? ThemeColors.neonCyan : ThemeColors.surfaceDark)
                                
                                if isSubmitting {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .tint(isValid ? ThemeColors.cosmicBlack : ThemeColors.textMuted)
                                        
                                        Text(userEnv.labelLoggingInCaps)
                                            .font(.setCustomFont(name: .InterBlack, size: 14))
                                            .foregroundStyle(isValid ? ThemeColors.cosmicBlack : ThemeColors.textMuted)
                                    }
                                } else {
                                    Text(userEnv.labelLogInCaps)
                                        .font(.setCustomFont(name: .InterBlack, size: 16))
                                        .foregroundStyle(isValid ? ThemeColors.cosmicBlack : ThemeColors.textMuted)
                                }
                            }
                            .frame(height: 56)
                            .shadow(
                                color: isValid ? ThemeColors.neonCyan.opacity(0.4) : .clear,
                                radius: isValid ? 15 : 0
                            )
                        }
                        .disabled(!isValid || isSubmitting)
                        .opacity(isSubmitting ? 0.8 : 1.0)
                        
                        // Cancel button
                        Button {
                            HapticManager.shared.play(.buttonTap)
                            isPresented = false
                        } label: {
                            Text(userEnv.btnCancelCaps)
                                .font(.setCustomFont(name: .InterMedium, size: 14))
                                .foregroundStyle(ThemeColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(ThemeColors.surfaceDark)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(ThemeColors.gridStroke, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    private func submitLogin() {
        guard isValid else { return }
        isSubmitting = true
        errorMessage = nil
        successMessage = nil
        
        let email = enteredEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard email == userEnv.email.lowercased() else {
            HapticManager.shared.play(.error)
            errorMessage = userEnv.labelEmailNotPersisted
            isSubmitting = false
            return
        }
        
        guard userEnv.verifyLeaderboardPassword(password) else {
            HapticManager.shared.play(.error)
            errorMessage = userEnv.labelEmailOrPasswordIncorrect
            isSubmitting = false
            return
        }
        
        userEnv.isRegistered = true
        successMessage = userEnv.labelLoginSuccessful
        HapticManager.shared.play(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSubmitting = false
            isPresented = false
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailPattern)
        return predicate.evaluate(with: email)
    }
}
