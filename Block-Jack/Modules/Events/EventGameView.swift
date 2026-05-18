import SwiftUI

struct EventGameView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let config: EventConfig
    
    @StateObject private var vm: EventGameViewModel
    @State private var showLeaderboard: Bool = false
    
    init(config: EventConfig) {
        self.config = config
        _vm = StateObject(wrappedValue: EventGameViewModel(config: config))
    }
    
    var body: some View {
        ZStack {
            // Arka plan
            ThemeColors.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Sadece ana oyun alanı (Kendi HUD'ını kullanacak)
                GameView(slotId: -1, nodeType: nil, eventConfig: config)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // MARK: - Boss Intent Overlay
            if let intent = vm.currentBossAnim {
                BossIntentOverlay(intent: intent)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(100)
            }
            
            // MARK: - Perk Choice Overlay
            if vm.showPerkChoice, let perks = vm.session.pendingPerkChoice {
                PerkChoiceOverlay(perks: perks, onSelect: vm.selectPerk)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(101)
            }
            
            // MARK: - Game Over Screen
            if vm.isGameOver {
                EventGameOverScreen(vm: vm)
                    .zIndex(102)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showLeaderboard) {
            EventLeaderboardSheet(vm: vm)
                .environmentObject(userEnv)
        }
        .animation(.spring(response: 0.3), value: vm.showPerkChoice)
        .animation(.easeOut(duration: 0.2), value: vm.currentBossAnim != nil)
    }
}

struct EventGameHeaderView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let config: EventConfig
    let lives: Int
    let maxLives: Int
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(config.title)
                    .font(.setCustomFont(name: .InterBlack, size: 16))
                    .foregroundStyle(ThemeColors.neonCyan)
                
                HStack(spacing: 4) {
                    ForEach(0..<maxLives, id: \.self) { i in
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(i < lives ? ThemeColors.neonPink : ThemeColors.textMuted.opacity(0.3))
                    }
                }
            }
            
            Spacer()
            
            Button {
                HapticManager.shared.play(.buttonTap)
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ThemeColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(ThemeColors.surfaceDark)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(ThemeColors.gridStroke, lineWidth: 1))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

struct EventGameHUDView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @ObservedObject var vm: EventGameViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Row 1: HUD Stats
            HStack(spacing: 10) {
                HUDBox(label: userEnv.labelRoundCaps, value: "\(vm.session.currentRound)", color: ThemeColors.neonCyan)
                HUDBox(label: userEnv.labelGoldCaps, value: "\(vm.session.goldEarned)", color: ThemeColors.electricYellow)
                HUDBox(label: userEnv.labelNextPerkCaps, value: "\(vm.session.roundsUntilPerk)", color: ThemeColors.neonPurple)
            }
            
            // Row 2: Active Perks
            if !vm.session.activePerks.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(vm.session.activePerks) { perk in
                            HStack(spacing: 6) {
                                Image(perk.iconName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                Text(perk.name)
                                    .font(.setCustomFont(name: .InterBold, size: 10))
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(ThemeColors.surfaceLight.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(ThemeColors.electricYellow.opacity(0.3), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .padding(.vertical, 12)
        .background(ThemeColors.surfaceDark.opacity(0.4))
    }
}

struct HUDBox: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.setCustomFont(name: .InterBold, size: 10))
                .foregroundStyle(ThemeColors.textMuted)
            Text(value)
                .font(.setCustomFont(name: .InterExtraBold, size: 16))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(ThemeColors.surfaceDark.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.2), lineWidth: 1))
    }
}

struct BossIntentOverlay: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let intent: BossIntentType
    
    var title: String {
        switch intent {
        case .lockCells:         return userEnv.labelBossLockCells
        case .stealTime:         return userEnv.labelBossStealTime
        case .blockTray:         return userEnv.labelBossBlockTray
        case .addJunkRow:        return userEnv.labelBossAddJunkRow
        case .shuffleBoard:      return userEnv.labelBossShuffleBoard
        case .invertControls:    return userEnv.labelBossInvertControls
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(ThemeColors.neonPink.opacity(0.2))
                    .frame(width: 80, height: 80)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(ThemeColors.neonPink)
            }
            
            Text(title)
                .font(.setCustomFont(name: .InterBlack, size: 18))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(ThemeColors.neonPink.opacity(0.5), lineWidth: 2))
        .shadow(color: ThemeColors.neonPink.opacity(0.3), radius: 20)
        .padding(.horizontal, 40)
    }
}

struct PerkChoiceOverlay: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let perks: [EventPerk]
    let onSelect: (EventPerk) -> Void
    
    @State private var selected: EventPerk? = nil
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(userEnv.labelRoundCompleteCaps)
                        .font(.setCustomFont(name: .InterBlack, size: 24))
                        .foregroundStyle(ThemeColors.electricYellow)
                    Text(userEnv.labelChooseAPerk)
                        .font(.setCustomFont(name: .InterMedium, size: 14))
                        .foregroundStyle(ThemeColors.textSecondary)
                }
                
                // Perk Cards
                VStack(spacing: 12) {
                    ForEach(perks) { perk in
                        PerkChoiceCard(perk: perk, isSelected: selected?.id == perk.id)
                            .onTapGesture {
                                selected = perk
                                HapticManager.shared.play(.buttonTap)
                            }
                    }
                }
                .padding(.horizontal, 24)
                
                // Select Button
                Button {
                    if let sel = selected {
                        onSelect(sel)
                    }
                } label: {
                    Text(userEnv.btnSelectAndContinue)
                        .font(.setCustomFont(name: .InterBlack, size: 16))
                        .foregroundStyle(ThemeColors.cosmicBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selected == nil ? ThemeColors.textMuted : ThemeColors.electricYellow)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: (selected == nil ? Color.clear : ThemeColors.electricYellow.opacity(0.3)), radius: 10)
                }
                .disabled(selected == nil)
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 32)
            .background(ThemeColors.surfaceDark)
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .overlay(RoundedRectangle(cornerRadius: 32).stroke(ThemeColors.gridStroke, lineWidth: 1))
            .padding(.horizontal, 24)
        }
    }
}

struct PerkChoiceCard: View {
    let perk: EventPerk
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(perk.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundStyle(isSelected ? ThemeColors.electricYellow : ThemeColors.textMuted)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(perk.name)
                    .font(.setCustomFont(name: .InterBold, size: 16))
                    .foregroundStyle(isSelected ? ThemeColors.electricYellow : .white)
                Text(perk.description)
                    .font(.setCustomFont(name: .InterRegular, size: 12))
                    .foregroundStyle(ThemeColors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(isSelected ? ThemeColors.electricYellow.opacity(0.1) : ThemeColors.surfaceLight.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? ThemeColors.electricYellow : ThemeColors.gridStroke, lineWidth: 1.5))
    }
}

struct EventGameOverScreen: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @ObservedObject var vm: EventGameViewModel
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text(userEnv.labelGameOverCaps)
                        .font(.setCustomFont(name: .InterBlack, size: 36))
                        .foregroundStyle(ThemeColors.neonPink)
                        .shadow(color: ThemeColors.neonPink.opacity(0.5), radius: 10)
                    
                    Text(userEnv.labelChallengeEnded)
                        .font(.setCustomFont(name: .InterMedium, size: 14))
                        .foregroundStyle(ThemeColors.textSecondary)
                }
                
                VStack(spacing: 16) {
                    ResultRow(label: userEnv.labelScore, value: vm.gameOverScore.formatted(), color: ThemeColors.neonCyan)
                    
                    if let rank = vm.gameOverRank {
                        ResultRow(label: userEnv.labelRankingCaps, value: "# \(rank)", color: ThemeColors.electricYellow)
                    }
                    
                    ResultRow(label: userEnv.labelGoldEarnedCaps, value: "+\(vm.session.goldEarned)", color: ThemeColors.electricYellow)
                }
                .padding(24)
                .background(ThemeColors.surfaceDark.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(ThemeColors.gridStroke, lineWidth: 1))
                
                VStack(spacing: 12) {
                    Button {
                        HapticManager.shared.play(.heavy)
                        MainViewsRouter.shared.nav?.popViewController(animated: true)
                    } label: {
                        Text(userEnv.btnBackToMenuCaps)
                            .font(.setCustomFont(name: .InterBlack, size: 16))
                            .foregroundStyle(ThemeColors.cosmicBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(ThemeColors.neonCyan)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding(32)
        }
    }
}

struct ResultRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.setCustomFont(name: .InterBold, size: 14))
                .foregroundStyle(ThemeColors.textSecondary)
            Spacer()
            Text(value)
                .font(.setCustomFont(name: .InterBlack, size: 20))
                .foregroundStyle(color)
        }
    }
}

struct EventLeaderboardSheet: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @ObservedObject var vm: EventGameViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            ThemeColors.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(userEnv.titleEventRankingCaps)
                        .font(.setCustomFont(name: .InterBlack, size: 18))
                        .foregroundStyle(ThemeColors.neonCyan)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(ThemeColors.textMuted)
                    }
                }
                .padding(24)
                .background(ThemeColors.surfaceDark.opacity(0.5))
                
                if vm.leaderboard.isEmpty {
                    Spacer()
                    ProgressView().tint(ThemeColors.neonCyan)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(vm.leaderboard) { entry in
                                EventLeaderboardRowView(entry: entry)
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .task {
            await vm.fetchLeaderboard()
        }
    }
}

struct EventLeaderboardRowView: View {
    let entry: EventLeaderboardEntry
    
    var body: some View {
        HStack(spacing: 16) {
            Text("#\(entry.rank)")
                .font(.setCustomFont(name: .InterBlack, size: 14))
                .foregroundStyle(entry.rank <= 3 ? ThemeColors.electricYellow : ThemeColors.textMuted)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.username)
                    .font(.setCustomFont(name: .InterBold, size: 15))
                    .foregroundStyle(.white)
                Text("Zone: \(entry.metric)")
                    .font(.setCustomFont(name: .InterMedium, size: 11))
                    .foregroundStyle(ThemeColors.textMuted)
            }
            
            Spacer()
            
            Text(entry.score.formatted())
                .font(.setCustomFont(name: .InterBlack, size: 16))
                .foregroundStyle(entry.isMe ? ThemeColors.neonCyan : .white)
        }
        .padding(16)
        .background(entry.isMe ? ThemeColors.neonCyan.opacity(0.1) : ThemeColors.surfaceDark.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(entry.isMe ? ThemeColors.neonCyan : ThemeColors.gridStroke.opacity(0.3), lineWidth: 1))
    }
}

