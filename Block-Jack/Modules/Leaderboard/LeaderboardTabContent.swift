//
//  LeaderboardTabContent.swift
//  Block-Jack
//
//  Premium Leaderboard View — Global, Local, and Personal rankings.
//

import SwiftUI

struct LeaderboardTabContent: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @StateObject private var vm = LeaderboardViewModel()
    @State private var showRegistration = false
    @State private var isRefreshing = false
    
    var body: some View {
        ZStack {
            // Base Background
            ThemeColors.cosmicBlack.ignoresSafeArea()
            
            // Dynamic Background Glows
            BackgroundGlows()
            
            VStack(spacing: 20) {
                // Header with Navigation Control
                headerSection
                
                // Scope Selector (Premium Glassmorphic)
                scopeSelector
                
                // Content area
                ZStack {
                    switch vm.state {
                    case .loaded:
                        loadedContent
                    case .loading:
                        loadingView
                    case .empty:
                        emptyView
                    case .offline, .error:
                        errorView
                    case .idle:
                        Color.clear
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            if vm.globalEntries.isEmpty {
                refreshData()
            }
        }
        .sheet(isPresented: $showRegistration) {
            PlayerRegistrationView()
                .environmentObject(userEnv)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            // Back Button
            Button {
                HapticManager.shared.play(.buttonTap)
                MainViewsRouter.shared.dismissModal()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.1)))
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(userEnv.labelLeaderboardCaps)
                    .font(.setCustomFont(name: .InterBlack, size: 26))
                    .foregroundStyle(.white)
                    .shadow(color: ThemeColors.neonCyan.opacity(0.3), radius: 10)
                
                Text(userEnv.labelLeaderboardDesc)
                    .font(.setCustomFont(name: .InterMedium, size: 12))
                    .foregroundStyle(ThemeColors.textMuted)
            }
            
            Spacer()
            
            Button {
                refreshData()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.1)))
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Scope Selector
    
    private var scopeSelector: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardScope.allCases, id: \.self) { scope in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        vm.scope = scope
                    }
                    HapticManager.shared.play(.selection)
                    refreshData()
                } label: {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: scope.icon)
                                .font(.system(size: 12, weight: .bold))
                            
                            Text(scope.displayName(for: userEnv.language))
                                .font(.setCustomFont(name: .InterBold, size: 13))
                        }
                        .foregroundStyle(vm.scope == scope ? .white : ThemeColors.textMuted)
                        
                        // Indicator line
                        RoundedRectangle(cornerRadius: 2)
                            .fill(vm.scope == scope ? ThemeColors.neonCyan : Color.clear)
                            .frame(height: 3)
                            .shadow(color: vm.scope == scope ? ThemeColors.neonCyan.opacity(0.5) : .clear, radius: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                }
            }
        }
        .background(Color.black.opacity(0.3))
        .overlay(VStack { Spacer(); Divider().background(Color.white.opacity(0.1)) })
    }
    
    // MARK: - Loaded Content
    
    @ViewBuilder
    private var loadedContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                switch vm.scope {
                case .global:
                    if !vm.globalEntries.isEmpty {
                        podiumSection(entries: Array(vm.globalEntries.prefix(3)))
                        entryList(Array(vm.globalEntries.dropFirst(3)), title: userEnv.labelGlobalRankings)
                    } else {
                        emptyView
                    }
                case .local:
                    if !vm.localEntries.isEmpty {
                        podiumSection(entries: Array(vm.localEntries.prefix(3)))
                        entryList(Array(vm.localEntries.dropFirst(3)), title: userEnv.labelCountryRankingsTemplate.replacingOccurrences(of: "{{code}}", with: userEnv.playerCountryCode))
                    } else {
                        emptyView
                    }
                case .me:
                    meTabContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .refreshable {
            refreshData()
        }
    }
    
    // MARK: - Podium
    
    private func podiumSection(entries: [LeaderboardEntry]) -> some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Rank 2
            if entries.count > 1 {
                podiumItem(entry: entries[1], rank: 2, height: 130, color: ThemeColors.neonCyan)
            }
            
            // Rank 1
            if entries.count > 0 {
                podiumItem(entry: entries[0], rank: 1, height: 160, color: ThemeColors.electricYellow)
            }
            
            // Rank 3
            if entries.count > 2 {
                podiumItem(entry: entries[2], rank: 3, height: 110, color: ThemeColors.neonOrange)
            }
        }
        .padding(.vertical, 20)
    }
    
    private func podiumItem(entry: LeaderboardEntry, rank: Int, height: CGFloat, color: Color) -> some View {
        VStack(spacing: 12) {
            // Avatar + Winner Badge
            ZStack {
                // Background Glow
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: rank == 1 ? 80 : 66, height: rank == 1 ? 80 : 66)
                    .blur(radius: 10)
                
                Circle()
                    .stroke(color.opacity(0.4), lineWidth: 2)
                    .frame(width: rank == 1 ? 80 : 66, height: rank == 1 ? 80 : 66)
                
                if rank == 1 {
                    VStack(spacing: -10) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(color)
                            .shadow(color: color.opacity(0.8), radius: 10)
                            .offset(y: -15)
                        
                        Spacer()
                    }
                    .frame(height: 110)
                }
                
                Text(entry.username.prefix(1).uppercased())
                    .font(.setCustomFont(name: .InterBlack, size: rank == 1 ? 32 : 26))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 4) {
                Text(entry.username)
                    .font(.setCustomFont(name: .InterBold, size: 13))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text(entry.score.formatted())
                    .font(.setCustomFont(name: .InterBlack, size: 16))
                    .foregroundStyle(color)
                    .shadow(color: color.opacity(0.4), radius: 5)
            }
            
            // The Premium Pillar
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .frame(height: height)
                .overlay(
                    VStack {
                        Text("#\(rank)")
                            .font(.setCustomFont(name: .InterBlack, size: 32))
                            .foregroundStyle(color.opacity(0.4))
                            .padding(.top, 12)
                        
                        if rank == 1 {
                            Text("CHAMPION")
                                .font(.setCustomFont(name: .InterBlack, size: 10))
                                .tracking(2)
                                .foregroundStyle(color)
                                .padding(.top, -10)
                        }
                        Spacer()
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1.5)
                )
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(rank == 1 ? 1.05 : 0.95)
    }
    
    private func entryList(_ entries: [LeaderboardEntry], title: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Rectangle()
                    .fill(ThemeColors.neonCyan)
                    .frame(width: 4, height: 16)
                
                Text(title.uppercased())
                    .font(.setCustomFont(name: .InterBlack, size: 14))
                    .foregroundStyle(.white)
                    .tracking(1)
                
                Spacer()
                
                Text("TOP \(entries.count + 3)")
                    .font(.setCustomFont(name: .InterBold, size: 11))
                    .foregroundStyle(ThemeColors.textMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Capsule())
            }
            
            VStack(spacing: 12) {
                ForEach(entries) { entry in
                    LeaderboardRowView(
                        entry: entry,
                        isCurrentPlayer: entry.username == userEnv.username
                    )
                }
            }
        }
    }
    
    // MARK: - Me Tab
    
    private var meTabContent: some View {
        VStack(spacing: 24) {
            // My Rank Card
            if let rank = vm.myRank {
                MyRankCardView(rank: rank)
            } else {
                unrankedCard
            }
            
            // Personal Bests (Offline)
            if !userEnv.topScores.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(userEnv.labelPersonalBestsCaps)
                            .font(.setCustomFont(name: .InterBold, size: 12))
                            .foregroundStyle(ThemeColors.textMuted)
                            .tracking(1)
                        Spacer()
                        Image(systemName: "iphone.badge.play")
                            .font(.system(size: 14))
                            .foregroundStyle(ThemeColors.textMuted.opacity(0.5))
                    }
                    .padding(.horizontal, 4)
                    
                    VStack(spacing: 10) {
                        ForEach(Array(userEnv.topScores.prefix(5).enumerated()), id: \.element.id) { index, entry in
                            localScoreRow(rank: index + 1, entry: entry)
                        }
                    }
                }
            }
            
            // Registration CTA if not registered
            if !userEnv.isRegistered {
                registrationCTA
            }
        }
    }
    
    private var unrankedCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(ThemeColors.textMuted)
            
            Text(userEnv.labelUnrankedInfo)
            .font(.setCustomFont(name: .InterMedium, size: 14))
            .foregroundStyle(ThemeColors.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.04)))
    }
    
    private var registrationCTA: some View {
        Button {
            HapticManager.shared.play(.buttonTap)
            showRegistration = true
        } label: {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(ThemeColors.electricYellow)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(userEnv.labelPublishScoresTitle)
                            .font(.setCustomFont(name: .InterBold, size: 16))
                            .foregroundStyle(.white)
                        Text(userEnv.labelPublishScoresDesc)
                            .font(.setCustomFont(name: .InterMedium, size: 13))
                            .foregroundStyle(ThemeColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(ThemeColors.textMuted)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                     .fill(ThemeColors.electricYellow.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(ThemeColors.electricYellow.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private func localScoreRow(rank: Int, entry: LocalScoreEntry) -> some View {
        let date = Date(timeIntervalSince1970: entry.timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        
        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 32, height: 32)
                Text("\(rank)")
                    .font(.setCustomFont(name: .InterBlack, size: 14))
                    .foregroundStyle(ThemeColors.textMuted)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.score.formatted())
                    .font(.setCustomFont(name: .InterBlack, size: 18))
                    .foregroundStyle(.white)
                
                HStack(spacing: 8) {
                    Text(userEnv.labelWorldLevelTemplate.replacingOccurrences(of: "{{value}}", with: "\(entry.worldLevelReached)"))
                        .font(.setCustomFont(name: .InterMedium, size: 10))
                        .foregroundStyle(ThemeColors.neonPurple)
                    
                    Text(formatter.string(from: date))
                        .font(.setCustomFont(name: .InterMedium, size: 10))
                        .foregroundStyle(ThemeColors.textMuted)
                }
            }
            
            Spacer()
            
            if let char = GameCharacter.roster.first(where: { $0.id == entry.characterID }) {
                Image(char.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04)))
    }
    
    // MARK: - States
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(ThemeColors.neonCyan)
                .scaleEffect(1.5)
            
            Text(userEnv.labelLoadingEllipsis)
                .font(.setCustomFont(name: .InterBold, size: 14))
                .foregroundStyle(ThemeColors.textMuted)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "crown.slash")
                .font(.system(size: 64))
                .foregroundStyle(ThemeColors.textMuted.opacity(0.3))
            
            Text(userEnv.labelNoRankingsYet)
                .font(.setCustomFont(name: .InterBold, size: 18))
                .foregroundStyle(ThemeColors.textMuted)
            
            Button {
                refreshData()
            } label: {
                Text(userEnv.btnRefresh)
                    .font(.setCustomFont(name: .InterBold, size: 14))
                    .foregroundStyle(ThemeColors.cosmicBlack)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(ThemeColors.neonCyan)
                    .clipShape(Capsule())
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(ThemeColors.danger.opacity(0.6))
            
            Text(userEnv.labelConnectionError)
                .font(.setCustomFont(name: .InterBold, size: 18))
                .foregroundStyle(.white)
            
            Text(userEnv.labelCheckConnectionDesc)
                .font(.setCustomFont(name: .InterMedium, size: 14))
                .foregroundStyle(ThemeColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                refreshData()
            } label: {
                Text(userEnv.btnTryAgain)
                    .font(.setCustomFont(name: .InterBold, size: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(ThemeColors.surfaceDark)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
            }
        }
        .padding(40)
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Helpers
    
    private func refreshData() {
        guard !isRefreshing else { return }
        isRefreshing = true
        Task {
            await vm.fetchCurrentScope(forceRefresh: true)
            isRefreshing = false
        }
    }
}
