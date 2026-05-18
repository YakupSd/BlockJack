//
//  SocialView.swift
//  Block-Jack
//

import SwiftUI

struct SocialView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @StateObject private var friendVM = FriendViewModel()
    @StateObject private var duelVM = DuelViewModel()
    @State private var selectedTab: Int = 0
    @Namespace private var tabAnimation
    
    var body: some View {
        ZStack {
            ThemeColors.backgroundGradient.ignoresSafeArea()
            backgroundGrid
            
            VStack(spacing: 0) {
                // MARK: - Top Bar
                SocialTopBar(friendCount: friendVM.friends.count)
                
                // MARK: - Tab Selector
                SocialTabSelector(selected: $selectedTab, animation: tabAnimation)
                    .padding(.top, 8)
                    .padding(.horizontal, 24)
                
                // MARK: - Content
                if selectedTab == 0 {
                    FriendsTabView(vm: friendVM, duelVM: duelVM)
                } else {
                    DuelsTabView(vm: duelVM)
                }
                
                Spacer(minLength: 0)
            }
        }
        .navigationBarHidden(true)
        .task {
            await friendVM.fetchFriends()
            await friendVM.generateInviteCode()
            await duelVM.fetchAllDuels()
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

// MARK: - Top Bar
struct SocialTopBar: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let friendCount: Int
    
    var body: some View {
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
                Text(userEnv.labelSocial)
                    .font(.setCustomFont(name: .InterBlack, size: 24))
                    .foregroundStyle(ThemeColors.neonOrange)
                    .shadow(color: ThemeColors.neonOrange.opacity(0.5), radius: 8)
                Text(userEnv.labelFriendsAndDuels)
                    .font(.setCustomFont(name: .InterMedium, size: 12))
                    .foregroundStyle(ThemeColors.textMuted)
                    .tracking(2)
            }
            
            Spacer()
            
            // Friend count badge
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 14))
                Text("\(friendCount)")
                    .font(.setCustomFont(name: .InterBlack, size: 14))
            }
            .foregroundStyle(ThemeColors.neonCyan)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(ThemeColors.surfaceDark)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(ThemeColors.neonCyan.opacity(0.3), lineWidth: 1))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}

// MARK: - Tab Selector
struct SocialTabSelector: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @Binding var selected: Int
    var animation: Namespace.ID
    
    var body: some View {
        HStack(spacing: 0) {
            tabButton(
                title: userEnv.labelFriends,
                icon: "person.2.fill",
                tag: 0
            )
            tabButton(
                title: userEnv.labelDuels,
                icon: "shield.lefthalf.filled",
                tag: 1
            )
        }
        .padding(4)
        .background(ThemeColors.surfaceDark.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(ThemeColors.gridStroke, lineWidth: 1))
    }
    
    private func tabButton(title: String, icon: String, tag: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selected = tag
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.setCustomFont(name: .InterBold, size: 13))
                    .tracking(1)
            }
            .foregroundStyle(selected == tag ? ThemeColors.cosmicBlack : ThemeColors.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Group {
                    if selected == tag {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ThemeColors.neonOrange)
                            .matchedGeometryEffect(id: "socialTab", in: animation)
                    }
                }
            )
        }
    }
}

// MARK: - Friends Tab
struct FriendsTabView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @ObservedObject var vm: FriendViewModel
    @ObservedObject var duelVM: DuelViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Davet kodu
                if let invite = vm.myInviteCode {
                    InviteCodeCard(code: invite.code)
                }
                
                // Arkadaş listesi
                if vm.friends.isEmpty && !vm.isLoading {
                    emptyFriendsView
                } else {
                    VStack(spacing: 12) {
                        ForEach(vm.friends) { friend in
                            FriendRow(
                                friend: friend,
                                onDuel: {
                                    MainViewsRouter.shared.push(
                                        DuelCreateView(opponent: friend, duelVM: duelVM)
                                            .environmentObject(userEnv)
                                    )
                                }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }
    
    private var emptyFriendsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(ThemeColors.textMuted)
            Text(userEnv.labelNoFriendsYet)
                .font(.setCustomFont(name: .InterMedium, size: 16))
                .foregroundStyle(ThemeColors.textSecondary)
            Text(userEnv.labelShareInviteCode)
                .font(.setCustomFont(name: .InterRegular, size: 13))
                .foregroundStyle(ThemeColors.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
}

// MARK: - Invite Code Card
struct InviteCodeCard: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let code: String
    @State private var copied = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(userEnv.btnShareYourInvite)
                    .font(.setCustomFont(name: .InterBold, size: 11))
                    .foregroundStyle(ThemeColors.textMuted)
                    .tracking(2)
                Spacer()
                Image(systemName: "link")
                    .font(.system(size: 14))
                    .foregroundStyle(ThemeColors.neonCyan.opacity(0.6))
            }
            
            HStack(spacing: 12) {
                Text(code)
                    .font(.setCustomFont(name: .InterBlack, size: 20))
                    .foregroundStyle(ThemeColors.neonCyan)
                    .tracking(4)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Button {
                    UIPasteboard.general.string = code
                    HapticManager.shared.play(.success)
                    withAnimation(.spring(response: 0.3)) {
                        copied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { copied = false }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12, weight: .bold))
                        Text(copied
                             ? userEnv.labelCopied
                             : userEnv.labelCopy)
                            .font(.setCustomFont(name: .InterBold, size: 12))
                    }
                    .foregroundStyle(ThemeColors.cosmicBlack)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(copied ? ThemeColors.neonPurple : ThemeColors.neonCyan)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20)
            .stroke(ThemeColors.neonCyan.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Duels Tab
struct DuelsTabView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @ObservedObject var vm: DuelViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Gelen Davetler
                if !vm.pendingDuels.isEmpty {
                    DuelSection(
                        title: userEnv.labelIncomingChallenges,
                        icon: "envelope.badge.fill",
                        color: ThemeColors.electricYellow
                    ) {
                        ForEach(vm.pendingDuels) { duel in
                            PendingDuelCard(
                                duel: duel,
                                onAccept: {
                                    Task {
                                        await vm.acceptDuel(duel.id)
                                        // After accept, push to duel detail
                                        if let accepted = vm.activeDuels.last {
                                            MainViewsRouter.shared.push(
                                                DuelDetailView(duel: accepted, duelVM: vm)
                                                    .environmentObject(UserEnvironment.shared)
                                            )
                                        }
                                    }
                                },
                                onDecline: { Task { await vm.declineDuel(duel.id) } }
                            )
                        }
                    }
                }
                
                // Aktif Düellolar
                if !vm.activeDuels.isEmpty {
                    DuelSection(
                        title: userEnv.labelActiveDuels,
                        icon: "flame.fill",
                        color: ThemeColors.neonOrange
                    ) {
                        ForEach(vm.activeDuels) { duel in
                            ActiveDuelRow(duel: duel)
                                .onTapGesture {
                                    HapticManager.shared.play(.buttonTap)
                                    MainViewsRouter.shared.push(
                                        DuelDetailView(duel: duel, duelVM: vm)
                                            .environmentObject(UserEnvironment.shared)
                                    )
                                }
                        }
                    }
                }
                
                // Geçmiş Düellolar
                if !vm.historyDuels.isEmpty {
                    DuelSection(
                        title: userEnv.labelHistory,
                        icon: "clock.arrow.circlepath",
                        color: ThemeColors.textMuted
                    ) {
                        ForEach(vm.historyDuels) { duel in
                            DuelHistoryRow(duel: duel)
                                .onTapGesture {
                                    HapticManager.shared.play(.buttonTap)
                                    MainViewsRouter.shared.push(
                                        DuelResultsView(duel: duel)
                                            .environmentObject(UserEnvironment.shared)
                                    )
                                }
                        }
                    }
                }
                
                // Empty state
                if vm.pendingDuels.isEmpty && vm.activeDuels.isEmpty && vm.historyDuels.isEmpty && !vm.isLoading {
                    emptyDuelsView
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }
    
    private var emptyDuelsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.slash")
                .font(.system(size: 48))
                .foregroundStyle(ThemeColors.textMuted)
            Text(userEnv.labelNoDuelsYet)
                .font(.setCustomFont(name: .InterMedium, size: 16))
                .foregroundStyle(ThemeColors.textSecondary)
            Text(userEnv.labelChallengeYourFriends)
                .font(.setCustomFont(name: .InterRegular, size: 13))
                .foregroundStyle(ThemeColors.textMuted)
        }
        .padding(.top, 60)
    }
}

// MARK: - Duel Section Header
struct DuelSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                Text(title)
                    .font(.setCustomFont(name: .InterBold, size: 13))
                    .foregroundStyle(color)
                    .tracking(2)
            }
            
            content
        }
    }
}

#Preview {
    SocialView()
        .environmentObject(UserEnvironment.shared)
}
