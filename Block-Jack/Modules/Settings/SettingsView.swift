//
//  SettingsView.swift
//  Block-Jack
//
//  Premium Settings View — Glassmorphism, Profile Info, & Advanced Controls.
//

import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @State private var showDeleteConfirmation = false
    @State private var showLogoutConfirmation = false
    @State private var showHowToPlay = false
    
    var body: some View {
        ZStack {
            // Base Background
            ThemeColors.cosmicBlack.ignoresSafeArea()
            
            // Animated Background Glows
            BackgroundGlows()
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                settingsHeader
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // 1. Profile Hero Section
                        profileHeroSection
                        
                        // 2. Game Settings (Audio & Experience)
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel(userEnv.labelExperienceCaps)
                            
                            VStack(spacing: 0) {
                                settingRow(
                                    title: userEnv.labelSoundEffects,
                                    icon: "speaker.wave.3.fill",
                                    isOn: $userEnv.isSoundEnabled,
                                    color: ThemeColors.neonCyan
                                )
                                
                                rowDivider
                                
                                settingRow(
                                    title: userEnv.labelHaptics,
                                    icon: "iphone.radiowaves.left.and.right",
                                    isOn: $userEnv.isHapticEnabled,
                                    color: ThemeColors.neonPurple
                                )
                            }
                            .background(premiumCardBackground)
                        }
                        
                        // 3. Language Selection
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel(userEnv.labelLanguageCaps)
                            
                            HStack(spacing: 12) {
                                languageToggle(lang: .turkish, flag: "🇹🇷")
                                languageToggle(lang: .english, flag: "🇺🇸")
                            }
                        }
                        
                        // 4. Information & Support
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel(userEnv.labelInfoCaps)
                            
                            VStack(spacing: 0) {
                                actionLink(
                                    title: userEnv.labelHowToPlayQuestion,
                                    icon: "questionmark.circle.fill",
                                    color: ThemeColors.electricYellow
                                ) {
                                    HapticManager.shared.play(.buttonTap)
                                    showHowToPlay = true
                                }
                                
                                rowDivider
                                
                                Link(destination: URL(string: "https://frimpeksservice.com")!) {
                                    HStack {
                                        Image(systemName: "safari.fill")
                                            .foregroundStyle(ThemeColors.neonCyan)
                                        Text(userEnv.labelOurWebsite)
                                            .font(.setCustomFont(name: .InterBold, size: 16))
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 12))
                                            .foregroundStyle(ThemeColors.textMuted)
                                    }
                                    .padding(16)
                                }
                            }
                            .background(premiumCardBackground)
                        }
                        
                        // 5. Danger Zone (Condensed)
                        if userEnv.isRegistered {
                            logoutButton
                        }
                        
                        deleteAccountButton
                        
                        // Version Info
                        versionFooter
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .alert(userEnv.labelLogout, isPresented: $showLogoutConfirmation) {
            Button(userEnv.btnCancel, role: .cancel) { }
            Button(userEnv.labelLogoutCaps, role: .destructive) {
                HapticManager.shared.play(.warning)
                userEnv.clearRegistration()
            }
        } message: {
            Text(userEnv.msgLogoutMessage)
        }
        .sheet(isPresented: $showHowToPlay) {
            HowToPlayView()
                .environmentObject(userEnv)
        }
    }
    
    // MARK: - Components
    
    private var settingsHeader: some View {
        HStack {
            Button {
                HapticManager.shared.play(.buttonTap)
                MainViewsRouter.shared.dismissModal()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(userEnv.titleSettingsCaps)
                    .font(.setCustomFont(name: .InterBlack, size: 20))
                    .foregroundStyle(.white)
                    .tracking(2)
                
                // Currency Display
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .foregroundStyle(ThemeColors.electricYellow)
                        Text("\(userEnv.gold)")
                            .font(.setCustomFont(name: .InterBold, size: 12))
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill")
                            .foregroundStyle(ThemeColors.neonCyan)
                        Text("\(userEnv.diamonds)")
                            .font(.setCustomFont(name: .InterBold, size: 12))
                    }
                }
                .foregroundStyle(.white)
            }
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }
    
    private var profileHeroSection: some View {
        VStack(spacing: 24) {
            if userEnv.isRegistered {
                HStack(spacing: 20) {
                    // Avatar with Glow
                    ZStack {
                        let selectedAvatar = AvatarItem.allAvatars.first(where: { $0.id == userEnv.selectedAvatarID }) ?? AvatarItem.allAvatars[0]
                        
                        Circle()
                            .fill(ThemeColors.neonCyan.opacity(0.1))
                            .frame(width: 90, height: 90)
                        
                        Image(selectedAvatar.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(colors: [ThemeColors.neonCyan, ThemeColors.neonPurple], startPoint: .top, endPoint: .bottom),
                                        lineWidth: 2
                                    )
                            )
                            .shadow(color: ThemeColors.neonCyan.opacity(0.5), radius: 10)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(userEnv.fullName)
                            .font(.setCustomFont(name: .InterBlack, size: 22))
                            .foregroundStyle(.white)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "at")
                                .font(.system(size: 10))
                                .foregroundStyle(ThemeColors.neonCyan)
                            Text(userEnv.username)
                                .font(.setCustomFont(name: .InterBold, size: 14))
                                .foregroundStyle(ThemeColors.textSecondary)
                        }
                        
                        Text(userEnv.email)
                            .font(.setCustomFont(name: .InterMedium, size: 12))
                            .foregroundStyle(ThemeColors.textMuted)
                    }
                    
                    Spacer()
                }
                .padding(20)
                .background(premiumCardBackground)
            } else {
                // Guest Header
                HStack(spacing: 16) {
                    let selectedAvatar = AvatarItem.allAvatars.first(where: { $0.id == userEnv.selectedAvatarID }) ?? AvatarItem.allAvatars[0]
                    
                    Image(selectedAvatar.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(ThemeColors.electricYellow.opacity(0.5), lineWidth: 2))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(userEnv.labelGuestPlayerCaps)
                            .font(.setCustomFont(name: .InterBlack, size: 18))
                            .foregroundStyle(.white)
                        Text(userEnv.labelGuestSubtitle)
                            .font(.setCustomFont(name: .InterMedium, size: 12))
                            .foregroundStyle(ThemeColors.textMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(ThemeColors.textMuted)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(ThemeColors.electricYellow.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(ThemeColors.electricYellow.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            
            // 1.1 Avatar Selection Grid
            avatarSelectionSection
        }
    }
    
    private var avatarSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel(userEnv.labelProfileIconCaps)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(AvatarCategory.allCases, id: \.self) { category in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category.displayName(lang: userEnv.language))
                                .font(.setCustomFont(name: .InterBold, size: 10))
                                .foregroundStyle(ThemeColors.textSecondary)
                                .padding(.horizontal, 4)
                            
                            HStack(spacing: 12) {
                                ForEach(AvatarItem.allAvatars.filter({ $0.category == category })) { avatar in
                                    avatarThumbnail(avatar)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private func avatarThumbnail(_ avatar: AvatarItem) -> some View {
        let isUnlocked = userEnv.unlockedAvatarIDs.contains(avatar.id)
        let isSelected = userEnv.selectedAvatarID == avatar.id
        
        return Button {
            if isUnlocked {
                HapticManager.shared.play(.selection)
                userEnv.selectedAvatarID = avatar.id
            } else {
                // Try to unlock
                if userEnv.unlockAvatar(avatar) {
                    userEnv.selectedAvatarID = avatar.id
                }
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Image(avatar.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .grayscale(isUnlocked ? 0 : 1)
                        .opacity(isUnlocked ? 1 : 0.6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? ThemeColors.neonCyan : Color.white.opacity(0.1), lineWidth: isSelected ? 3 : 1)
                        )
                    
                    if !isUnlocked {
                        VStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                            
                            HStack(spacing: 2) {
                                Image(systemName: "bitcoinsign.circle.fill")
                                    .font(.system(size: 10))
                                Text("\(avatar.cost)")
                                    .font(.setCustomFont(name: .InterBlack, size: 10))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.black.opacity(0.6)))
                            .foregroundStyle(userEnv.gold >= avatar.cost ? ThemeColors.electricYellow : ThemeColors.danger)
                        }
                    }
                }
                
                Text(avatar.name)
                    .font(.setCustomFont(name: isSelected ? .InterBold : .InterMedium, size: 10))
                    .foregroundStyle(isSelected ? ThemeColors.neonCyan : ThemeColors.textMuted)
            }
        }
    }
    
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.setCustomFont(name: .InterBlack, size: 12))
            .foregroundStyle(ThemeColors.textMuted)
            .tracking(1.5)
            .padding(.horizontal, 4)
    }
    
    private var premiumCardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
    
    private var rowDivider: some View {
        Divider().background(Color.white.opacity(0.05)).padding(.horizontal, 16)
    }
    
    private func settingRow(title: String, icon: String, isOn: Binding<Bool>, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(color.opacity(0.1)).frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
            }
            
            Text(title)
                .font(.setCustomFont(name: .InterBold, size: 16))
                .foregroundStyle(.white)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .tint(color)
                .scaleEffect(0.9)
        }
        .padding(16)
    }
    
    private func languageToggle(lang: AppLanguage, flag: String) -> some View {
        let isSelected = userEnv.language == lang
        return Button {
            HapticManager.shared.play(.selection)
            withAnimation { userEnv.language = lang }
        } label: {
            HStack {
                Text(flag).font(.system(size: 20))
                Text(lang.displayName)
                    .font(.setCustomFont(name: isSelected ? .InterBlack : .InterBold, size: 14))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                }
            }
            .foregroundStyle(isSelected ? ThemeColors.cosmicBlack : .white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(isSelected ? ThemeColors.neonCyan : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    private func actionLink(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(color.opacity(0.1)).frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(color)
                }
                
                Text(title)
                    .font(.setCustomFont(name: .InterBold, size: 16))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(ThemeColors.textMuted)
            }
            .padding(16)
        }
    }
    
    private var logoutButton: some View {
        Button {
            showLogoutConfirmation = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text(userEnv.labelLogoutCaps)
            }
            .font(.setCustomFont(name: .InterBlack, size: 14))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var deleteAccountButton: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            Text(userEnv.btnDeleteAccount)
                .font(.setCustomFont(name: .InterBold, size: 12))
                .foregroundStyle(ThemeColors.danger.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .alert(userEnv.labelDeleteAccount, isPresented: $showDeleteConfirmation) {
            Button(userEnv.btnCancel, role: .cancel) { }
            Button(userEnv.btnDeleteCaps, role: .destructive) {
                HapticManager.shared.play(.error)
                userEnv.clearRegistration()
            }
        } message: {
            Text(userEnv.msgDeleteAccountMessage)
        }
    }
    
    private var versionFooter: some View {
        VStack(spacing: 4) {
            Text("BLOCK-JACK ELITE")
                .font(.setCustomFont(name: .InterBlack, size: 10))
                .foregroundStyle(ThemeColors.textMuted)
                .tracking(3)
            Text("V 1.0.4")
                .font(.setCustomFont(name: .InterMedium, size: 10))
                .foregroundStyle(ThemeColors.textMuted.opacity(0.5))
        }
        .padding(.top, 20)
    }
}

// MARK: - Background Helpers
struct BackgroundGlows: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(ThemeColors.neonCyan.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: -150, y: -300)
            
            Circle()
                .fill(ThemeColors.neonPurple.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: 150, y: 300)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(UserEnvironment.shared)
}
