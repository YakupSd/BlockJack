//
//  CareerView.swift
//  Block-Jack
//

import SwiftUI

struct CareerView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @StateObject private var careerVM = CareerStatsViewModel()
    @State private var selectedTab: Int = 0
    @Namespace private var tabAnimation
    
    var body: some View {
        ZStack {
            ThemeColors.backgroundGradient.ignoresSafeArea()
            backgroundGrid
            
            VStack(spacing: 0) {
                // MARK: - Top Bar
                HStack {
                    Button(action: {
                        HapticManager.shared.play(.buttonTap)
                        MainViewsRouter.shared.dismissModal()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(ThemeColors.neonCyan)
                    }
                    
                    Text(userEnv.labelCareerTitle)
                        .font(.setCustomFont(name: .InterBlack, size: 20))
                        .foregroundStyle(ThemeColors.neonCyan)
                        .tracking(5)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                // MARK: - Profile Header
                CareerProfileHeader(careerVM: careerVM)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                
                // MARK: - Tab Selector
                CareerTabSelector(selected: $selectedTab, animation: tabAnimation)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                
                // MARK: - Content
                ScrollView(.vertical, showsIndicators: false) {
                    if selectedTab == 0 {
                        CareerStatsView(careerVM: careerVM)
                    } else if selectedTab == 1 {
                        CharacterStatsView(careerVM: careerVM)
                    } else if selectedTab == 2 {
                        PerkStatsView(careerVM: careerVM)
                    } else {
                        TitlesAndAchievementsView(careerVM: careerVM)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 0)
            }
        }
        .navigationBarHidden(true)
    }
    
    private var backgroundGrid: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 40
            let color = GraphicsContext.Shading.color(ThemeColors.gridStroke.opacity(0.12))
            
            var path = Path()
            for i in stride(from: 0, through: size.width, by: spacing) {
                path.move(to: CGPoint(x: i, y: 0))
                path.addLine(to: CGPoint(x: i, y: size.height))
            }
            for i in stride(from: 0, through: size.height, by: spacing) {
                path.move(to: CGPoint(x: 0, y: i))
                path.addLine(to: CGPoint(x: size.width, y: i))
            }
            ctx.stroke(path, with: color, lineWidth: 0.5)
        }
    }
}

// MARK: - Profile Header
struct CareerProfileHeader: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @ObservedObject var careerVM: CareerStatsViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // User Info + Avatar
            HStack(spacing: 16) {
                let selectedAvatar = AvatarItem.allAvatars.first(where: { $0.id == userEnv.selectedAvatarID })
                Image(selectedAvatar?.imageName ?? "profile_male_1_free")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .background(Circle().fill(ThemeColors.surfaceDark))
                    .overlay(Circle().stroke(ThemeColors.neonCyan, lineWidth: 2))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(userEnv.username)
                        .font(.setCustomFont(name: .InterBold, size: 16))
                        .foregroundStyle(ThemeColors.neonCyan)
                    
                    // Mastery Level Badge
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(ThemeColors.electricYellow)
                        Text(careerVM.careerStats.masteryLevel.title(lang: userEnv.language))
                            .font(.setCustomFont(name: .InterBold, size: 12))
                            .foregroundStyle(ThemeColors.electricYellow)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(ThemeColors.surfaceDark))
                    .overlay(Capsule().stroke(ThemeColors.electricYellow.opacity(0.5), lineWidth: 1))
                }
                
                Spacer()
            }
            
            // Mastery Progress Bar
            VStack(spacing: 6) {
                HStack {
                    Text("Mastery XP")
                        .font(.setCustomFont(name: .InterMedium, size: 11))
                        .foregroundStyle(ThemeColors.textMuted)
                    Spacer()
                    Text("\(careerVM.careerStats.masteryXP)")
                        .font(.setCustomFont(name: .InterBold, size: 11))
                        .foregroundStyle(ThemeColors.electricYellow)
                }
                
                ProgressView(value: getMasteryProgress())
                    .tint(ThemeColors.neonCyan)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ThemeColors.surfaceDark)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ThemeColors.gridStroke, lineWidth: 1))
        )
    }
    
    private func getMasteryProgress() -> Double {
        let currentLevel = careerVM.careerStats.masteryLevel
        let nextLevel = MasteryLevel.levels.first { $0.level == currentLevel.level + 1 }
        
        let currentXP = currentLevel.requiredXP
        let nextXP = nextLevel?.requiredXP ?? (currentLevel.requiredXP + 50000)
        
        let progress = Double(careerVM.careerStats.masteryXP - currentXP) / Double(nextXP - currentXP)
        return min(max(progress, 0), 1)
    }
}

// MARK: - Tab Selector
struct CareerTabSelector: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @Binding var selected: Int
    var animation: Namespace.ID
    
    private var tabs: [String] {
        [
            userEnv.tabCareerOverall,
            userEnv.tabCareerCharacters,
            userEnv.tabCareerPerks,
            userEnv.tabCareerTitles
        ]
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selected = index
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(tabs[index])
                                .font(.setCustomFont(name: .InterBold, size: 12))
                            
                            if selected == index {
                                Capsule()
                                    .fill(ThemeColors.neonCyan)
                                    .frame(height: 2)
                                    .matchedGeometryEffect(id: "tab", in: animation)
                            }
                        }
                        .foregroundStyle(selected == index ? ThemeColors.neonCyan : ThemeColors.textMuted)
                    }
                    
                    if index < tabs.count - 1 {
                        Divider()
                            .frame(height: 20)
                            .foregroundStyle(ThemeColors.gridStroke)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    CareerView()
        .environmentObject(UserEnvironment.shared)
}
