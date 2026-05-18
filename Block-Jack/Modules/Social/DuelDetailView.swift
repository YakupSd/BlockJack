//
//  DuelDetailView.swift
//  Block-Jack
//

import SwiftUI

struct DuelDetailView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let duel: DuelChallenge
    @ObservedObject var duelVM: DuelViewModel
    
    var playerIsChallenger: Bool {
        duel.challengerID == "player" || duel.challengerID == "current_player"
    }
    
    var playerHasPlayed: Bool {
        playerIsChallenger ? duel.challengerScore != nil : duel.challengedScore != nil
    }
    
    var opponentHasPlayed: Bool {
        playerIsChallenger ? duel.challengedScore != nil : duel.challengerScore != nil
    }
    
    var playerName: String {
        playerIsChallenger ? duel.challengerName : duel.challengedName
    }
    
    var opponentName: String {
        playerIsChallenger ? duel.challengedName : duel.challengerName
    }
    
    var body: some View {
        ZStack {
            ThemeColors.backgroundGradient.ignoresSafeArea()
            backgroundGrid
            
            VStack(spacing: 0) {
                // MARK: - Top Bar
                HStack(spacing: 16) {
                    Button {
                        HapticManager.shared.play(.buttonTap)
                        MainViewsRouter.shared.nav?.popViewController(animated: true)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(ThemeColors.textSecondary)
                            .frame(width: 44, height: 44)
                            .background(ThemeColors.surfaceDark)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(ThemeColors.gridStroke, lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(userEnv.labelDuelDetails)
                            .font(.setCustomFont(name: .InterBlack, size: 22))
                            .foregroundStyle(ThemeColors.neonOrange)
                            .shadow(color: ThemeColors.neonOrange.opacity(0.5), radius: 8)
                        Text("vs \(opponentName)")
                            .font(.setCustomFont(name: .InterMedium, size: 12))
                            .foregroundStyle(ThemeColors.textMuted)
                            .tracking(2)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // MARK: - VS Card
                        vsCard
                        
                        // MARK: - Stake Info
                        stakeInfoCard
                        
                        // MARK: - Status
                        statusCard
                        
                        // MARK: - Action
                        actionSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - VS Card
    private var vsCard: some View {
        HStack(spacing: 0) {
            // Player
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(ThemeColors.neonCyan.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Text(String(playerName.prefix(2)).uppercased())
                        .font(.setCustomFont(name: .InterBlack, size: 18))
                        .foregroundStyle(ThemeColors.neonCyan)
                }
                
                Text(playerName)
                    .font(.setCustomFont(name: .InterBold, size: 14))
                    .foregroundStyle(ThemeColors.neonCyan)
                
                if let score = playerIsChallenger ? duel.challengerScore : duel.challengedScore {
                    Text(score.formatted())
                        .font(.setCustomFont(name: .InterBlack, size: 22))
                        .foregroundStyle(ThemeColors.electricYellow)
                        .shadow(color: ThemeColors.electricYellow.opacity(0.3), radius: 5)
                } else {
                    Text("—")
                        .font(.setCustomFont(name: .InterBlack, size: 22))
                        .foregroundStyle(ThemeColors.textMuted)
                }
            }
            .frame(maxWidth: .infinity)
            
            // VS
            VStack(spacing: 4) {
                Text("VS")
                    .font(.setCustomFont(name: .InterBlack, size: 24))
                    .foregroundStyle(ThemeColors.neonOrange)
                    .shadow(color: ThemeColors.neonOrange.opacity(0.5), radius: 8)
            }
            .frame(width: 50)
            
            // Opponent
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(ThemeColors.neonPink.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Text(String(opponentName.prefix(2)).uppercased())
                        .font(.setCustomFont(name: .InterBlack, size: 18))
                        .foregroundStyle(ThemeColors.neonPink)
                }
                
                Text(opponentName)
                    .font(.setCustomFont(name: .InterBold, size: 14))
                    .foregroundStyle(ThemeColors.neonPink)
                
                if let score = playerIsChallenger ? duel.challengedScore : duel.challengerScore {
                    Text(score.formatted())
                        .font(.setCustomFont(name: .InterBlack, size: 22))
                        .foregroundStyle(ThemeColors.electricYellow)
                        .shadow(color: ThemeColors.electricYellow.opacity(0.3), radius: 5)
                } else {
                    Text("—")
                        .font(.setCustomFont(name: .InterBlack, size: 22))
                        .foregroundStyle(ThemeColors.textMuted)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24)
            .stroke(ThemeColors.neonOrange.opacity(0.3), lineWidth: 1.5))
    }
    
    // MARK: - Stake Info
    private var stakeInfoCard: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(ThemeColors.electricYellow.opacity(0.1))
                    .frame(width: 48, height: 48)
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(ThemeColors.electricYellow)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(userEnv.labelStakeAmount)
                    .font(.setCustomFont(name: .InterBold, size: 11))
                    .foregroundStyle(ThemeColors.textMuted)
                    .tracking(1)
                Text("\(duel.stakeAmount) \(userEnv.labelGoldUnit)")
                    .font(.setCustomFont(name: .InterBlack, size: 20))
                    .foregroundStyle(ThemeColors.electricYellow)
            }
            
            Spacer()
            
            // Potential win
            VStack(alignment: .trailing, spacing: 2) {
                Text(userEnv.labelPotential)
                    .font(.setCustomFont(name: .InterMedium, size: 10))
                    .foregroundStyle(ThemeColors.textMuted)
                Text("+\(duel.stakeAmount * 2)")
                    .font(.setCustomFont(name: .InterBlack, size: 16))
                    .foregroundStyle(ThemeColors.neonPurple)
            }
        }
        .padding(20)
        .background(ThemeColors.surfaceDark.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20)
            .stroke(ThemeColors.electricYellow.opacity(0.2), lineWidth: 1))
    }
    
    // MARK: - Status Card
    private var statusCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text(userEnv.labelStatus)
                    .font(.setCustomFont(name: .InterBold, size: 13))
                    .foregroundStyle(ThemeColors.textMuted)
                    .tracking(2)
                Spacer()
            }
            
            HStack(spacing: 20) {
                statusItem(
                    label: playerName,
                    status: playerHasPlayed
                        ? userEnv.labelPlayed
                        : userEnv.labelWaiting,
                    played: playerHasPlayed
                )
                
                statusItem(
                    label: opponentName,
                    status: opponentHasPlayed
                        ? userEnv.labelPlayed
                        : userEnv.labelWaiting,
                    played: opponentHasPlayed
                )
            }
        }
        .padding(20)
        .background(ThemeColors.surfaceDark.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20)
            .stroke(ThemeColors.gridStroke.opacity(0.3), lineWidth: 1))
    }
    
    private func statusItem(label: String, status: String, played: Bool) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.setCustomFont(name: .InterBold, size: 14))
                .foregroundStyle(.white)
            
            Text(status)
                .font(.setCustomFont(name: .InterMedium, size: 12))
                .foregroundStyle(played ? ThemeColors.neonPurple : ThemeColors.neonOrange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(played ? ThemeColors.neonPurple.opacity(0.1) : ThemeColors.neonOrange.opacity(0.1))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Action Section
    @ViewBuilder
    private var actionSection: some View {
        if !playerHasPlayed && duel.status == .accepted {
            Button {
                HapticManager.shared.play(.heavy)
                MainViewsRouter.shared.push(
                    DuelGamePlayView(duel: duel)
                        .environmentObject(userEnv)
                )
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text(userEnv.btnStartGame)
                        .font(.setCustomFont(name: .InterBlack, size: 18))
                        .tracking(2)
                }
                .foregroundStyle(ThemeColors.cosmicBlack)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(ThemeColors.neonOrange)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: ThemeColors.neonOrange.opacity(0.4), radius: 15)
            }
        } else if duel.status == .completed {
            Button {
                HapticManager.shared.play(.buttonTap)
                MainViewsRouter.shared.push(
                    DuelResultsView(duel: duel)
                        .environmentObject(userEnv)
                )
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text(userEnv.btnViewResults)
                        .font(.setCustomFont(name: .InterBlack, size: 18))
                        .tracking(2)
                }
                .foregroundStyle(ThemeColors.cosmicBlack)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(ThemeColors.neonCyan)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: ThemeColors.neonCyan.opacity(0.4), radius: 15)
            }
        } else if playerHasPlayed && !opponentHasPlayed {
            // Waiting for opponent
            VStack(spacing: 12) {
                Image(systemName: "hourglass")
                    .font(.system(size: 32))
                    .foregroundStyle(ThemeColors.neonOrange)
                    .symbolEffect(.bounce, options: .repeating)
                Text(userEnv.labelWaitingOpponent)
                    .font(.setCustomFont(name: .InterMedium, size: 15))
                    .foregroundStyle(ThemeColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(ThemeColors.surfaceDark.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20)
                .stroke(ThemeColors.neonOrange.opacity(0.2), lineWidth: 1))
        }
    }
    
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
    DuelDetailView(
        duel: DuelChallenge(
            challengerID: "player",
            challengerName: "Siz",
            challengedID: "opp1",
            challengedName: "BLOCKZILLA",
            stakeAmount: 500,
            status: .accepted
        ),
        duelVM: DuelViewModel()
    )
    .environmentObject(UserEnvironment.shared)
}
