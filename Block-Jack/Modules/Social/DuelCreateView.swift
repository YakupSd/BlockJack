//
//  DuelCreateView.swift
//  Block-Jack
//

import SwiftUI

struct DuelCreateView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let opponent: FriendRelation
    @ObservedObject var duelVM: DuelViewModel
    @State private var stakeAmount: Int = 500
    @State private var isCreating = false
    
    private let stakeOptions = [250, 500, 1000]
    
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
                        Text(userEnv.labelStartDuel)
                            .font(.setCustomFont(name: .InterBlack, size: 22))
                            .foregroundStyle(ThemeColors.neonOrange)
                            .shadow(color: ThemeColors.neonOrange.opacity(0.5), radius: 8)
                        Text(userEnv.labelChallengeSingle)
                            .font(.setCustomFont(name: .InterMedium, size: 12))
                            .foregroundStyle(ThemeColors.textMuted)
                            .tracking(2)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // MARK: - Opponent Card
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(ThemeColors.neonPink.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                Text(String(opponent.username.prefix(2)).uppercased())
                                    .font(.setCustomFont(name: .InterBlack, size: 28))
                                    .foregroundStyle(ThemeColors.neonPink)
                            }
                            
                            Text(opponent.username)
                                .font(.setCustomFont(name: .InterBlack, size: 24))
                                .foregroundStyle(.white)
                            
                            if let rank = opponent.globalRank {
                                HStack(spacing: 6) {
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: 14))
                                    Text("\(userEnv.labelRank) #\(rank)")
                                        .font(.setCustomFont(name: .InterMedium, size: 14))
                                }
                                .foregroundStyle(ThemeColors.electricYellow)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(RoundedRectangle(cornerRadius: 24)
                            .stroke(ThemeColors.neonPink.opacity(0.3), lineWidth: 1))
                        
                        // MARK: - Stake Selection
                        VStack(spacing: 16) {
                            HStack {
                                Text(userEnv.labelSelectStake)
                                    .font(.setCustomFont(name: .InterBold, size: 13))
                                    .foregroundStyle(ThemeColors.textMuted)
                                    .tracking(2)
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                ForEach(stakeOptions, id: \.self) { amount in
                                    Button {
                                        withAnimation(.spring(response: 0.3)) {
                                            stakeAmount = amount
                                        }
                                        HapticManager.shared.play(.buttonTap)
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: "bitcoinsign.circle.fill")
                                                .font(.system(size: 20))
                                            Text("\(amount)")
                                                .font(.setCustomFont(name: .InterBlack, size: 16))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .foregroundStyle(stakeAmount == amount ? ThemeColors.cosmicBlack : ThemeColors.electricYellow)
                                        .background(stakeAmount == amount ? ThemeColors.electricYellow : ThemeColors.surfaceDark.opacity(0.5))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(RoundedRectangle(cornerRadius: 16)
                                            .stroke(stakeAmount == amount
                                                    ? ThemeColors.electricYellow
                                                    : ThemeColors.electricYellow.opacity(0.2), lineWidth: 1.5))
                                        .scaleEffect(stakeAmount == amount ? 1.05 : 1.0)
                                    }
                                }
                            }
                        }
                        
                        // MARK: - Start Button
                        Button {
                            isCreating = true
                            HapticManager.shared.play(.heavy)
                            Task {
                                _ = await duelVM.createDuel(
                                    opponentID: opponent.friendID,
                                    opponentName: opponent.username,
                                    stakeAmount: stakeAmount
                                )
                                MainViewsRouter.shared.nav?.popViewController(animated: true)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if isCreating {
                                    ProgressView()
                                        .tint(ThemeColors.cosmicBlack)
                                } else {
                                    Image(systemName: "shield.lefthalf.filled")
                                        .font(.system(size: 18, weight: .bold))
                                    Text(userEnv.btnChallenge)
                                        .font(.setCustomFont(name: .InterBlack, size: 18))
                                        .tracking(2)
                                }
                            }
                            .foregroundStyle(ThemeColors.cosmicBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(isCreating ? ThemeColors.textMuted : ThemeColors.neonOrange)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: ThemeColors.neonOrange.opacity(0.4), radius: 15)
                        }
                        .disabled(isCreating)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationBarHidden(true)
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
    DuelCreateView(
        opponent: FriendRelation(
            friendID: "f1",
            username: "PIXEL_GOD",
            avatarSlot: 1,
            globalRank: 5,
            isOnline: true
        ),
        duelVM: DuelViewModel()
    )
    .environmentObject(UserEnvironment.shared)
}
