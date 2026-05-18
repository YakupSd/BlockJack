import SwiftUI

struct EventsView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @StateObject var vm = EventsViewModel()
    @State private var selectedTab: EventType = .daily
    
    var body: some View {
        ZStack {
            // Arka plan
            ThemeColors.backgroundGradient.ignoresSafeArea()
            backgroundGrid
            
            VStack(spacing: 0) {
                // MARK: - Topbar
                EventsTopBarView()
                
                // MARK: - Tab Seçici
                EventTabSelector(selected: $selectedTab)
                    .padding(.top, 8)
                
                // MARK: - İçerik
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if selectedTab == .daily {
                            if let event = vm.dailyEvent {
                                EventPanelCard(event: event) {
                                    MainViewsRouter.shared.pushToEventDetail(event: event, vm: vm)
                                }
                            } else if vm.isLoading {
                                loadingPlaceholder
                            } else {
                                emptyStateView(message: userEnv.labelNoDailyChallenges)
                            }
                        } else {
                            if let event = vm.weeklyEvent {
                                EventPanelCard(event: event) {
                                    MainViewsRouter.shared.pushToEventDetail(event: event, vm: vm)
                                }
                            } else if vm.isLoading {
                                loadingPlaceholder
                            } else {
                                emptyStateView(message: userEnv.labelNoWeeklyChallenges)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await vm.fetchEvents()
        }
    }
    
    private var loadingPlaceholder: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(ThemeColors.neonCyan)
            Text(userEnv.labelChallengesLoading)
                .font(.setCustomFont(name: .InterMedium, size: 14))
                .foregroundStyle(ThemeColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(ThemeColors.textMuted)
            Text(message)
                .font(.setCustomFont(name: .InterMedium, size: 16))
                .foregroundStyle(ThemeColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
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

struct EventsTopBarView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    
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
                Text(userEnv.titleChallengeCaps)
                    .font(.setCustomFont(name: .InterBlack, size: 24))
                    .foregroundStyle(ThemeColors.neonCyan)
                    .shadow(color: ThemeColors.neonCyan.opacity(0.5), radius: 8)
                Text(userEnv.labelSpecialModes)
                    .font(.setCustomFont(name: .InterMedium, size: 12))
                    .foregroundStyle(ThemeColors.textMuted)
                    .tracking(2)
            }
            
            Spacer()
            
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 22))
                .foregroundStyle(ThemeColors.neonCyan.opacity(0.8))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}

struct EventTabSelector: View {
    @Binding var selected: EventType
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(EventType.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selected = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab.label)
                            .font(.setCustomFont(name: .InterBold, size: 14))
                            .foregroundStyle(selected == tab ? ThemeColors.neonCyan : ThemeColors.textMuted)
                            .tracking(1)
                        
                        if selected == tab {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(ThemeColors.neonCyan)
                                .frame(width: 40, height: 3)
                                .matchedGeometryEffect(id: "tab", in: animation)
                                .shadow(color: ThemeColors.neonCyan, radius: 4)
                        } else {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.clear)
                                .frame(width: 40, height: 3)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
    }
}

struct EventPanelCard: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let event: EventConfig
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.play(.buttonTap)
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(event.title)
                            .font(.setCustomFont(name: .InterBlack, size: 22))
                            .foregroundStyle(ThemeColors.neonCyan)
                        Text(event.description)
                            .font(.setCustomFont(name: .InterMedium, size: 13))
                            .foregroundStyle(ThemeColors.textSecondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Time remaining
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(userEnv.labelEndingInCaps)
                            .font(.setCustomFont(name: .InterBold, size: 10))
                            .foregroundStyle(ThemeColors.neonPink)
                            .tracking(1)
                        Text(event.timeRemainingSince)
                            .font(.setCustomFont(name: .InterExtraBold, size: 14))
                            .foregroundStyle(ThemeColors.neonPink)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(ThemeColors.neonPink.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ThemeColors.neonPink.opacity(0.3), lineWidth: 1))
                }
                
                // Modifiers
                EventModifiersRow(modifiers: event.modifiers)
                
                // Boss Preview
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(ThemeColors.neonPink.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(ThemeColors.neonPink)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BOSS: \(event.boss.name)")
                            .font(.setCustomFont(name: .InterBold, size: 14))
                            .foregroundStyle(.white)
                        Text(event.boss.description)
                            .font(.setCustomFont(name: .InterRegular, size: 12))
                            .foregroundStyle(ThemeColors.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(ThemeColors.surfaceDark.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ThemeColors.neonPink.opacity(0.2), lineWidth: 1))
                
                // Action Button / Score Display
                let hasPlayed = userEnv.hasPlayedEvent(event.id)
                let savedScore = userEnv.savedEventScore(event.id) ?? 0
                
                if hasPlayed {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(userEnv.labelCompletedCaps)
                                .font(.setCustomFont(name: .InterBold, size: 12))
                                .foregroundStyle(ThemeColors.textMuted)
                            Text("\(savedScore.formatted()) \(userEnv.labelScore)")
                                .font(.setCustomFont(name: .InterBlack, size: 18))
                                .foregroundStyle(ThemeColors.neonCyan)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text(userEnv.labelDetailsCaps)
                                .font(.setCustomFont(name: .InterBold, size: 12))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(ThemeColors.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(ThemeColors.gridDark.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ThemeColors.gridStroke, lineWidth: 1))
                } else {
                    HStack {
                        Text(userEnv.btnExamineCaps)
                            .font(.setCustomFont(name: .InterBlack, size: 16))
                            .foregroundStyle(ThemeColors.cosmicBlack)
                            .tracking(2)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(ThemeColors.cosmicBlack)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(ThemeColors.neonCyan)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: ThemeColors.neonCyan.opacity(0.3), radius: 10)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24)
                .stroke(ThemeColors.gridStroke.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct EventModifiersRow: View {
    let modifiers: [EventModifier]
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(modifiers) { modifier in
                VStack(spacing: 6) {
                    Image(systemName: modifier.iconName)
                        .font(.system(size: 16))
                        .foregroundStyle(ThemeColors.electricYellow)
                    Text(modifier.description)
                        .font(.setCustomFont(name: .InterBold, size: 10))
                        .foregroundStyle(ThemeColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 4)
                .background(ThemeColors.surfaceLight.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(ThemeColors.electricYellow.opacity(0.2), lineWidth: 1))
            }
        }
    }
}

#Preview {
    EventsView()
        .environmentObject(UserEnvironment.shared)
}
