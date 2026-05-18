import SwiftUI

struct EventDetailView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let event: EventConfig
    let vm: EventsViewModel
    
    @State private var selectedCharacter: EventCharacter?
    
    var body: some View {
        ZStack {
            // Arka plan
            ThemeColors.backgroundGradient.ignoresSafeArea()
            backgroundGrid
            
            VStack(spacing: 0) {
                // MARK: - Topbar
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
                        Text(userEnv.labelDetailsCaps)
                            .font(.setCustomFont(name: .InterBlack, size: 24))
                            .foregroundStyle(ThemeColors.neonCyan)
                            .shadow(color: ThemeColors.neonCyan.opacity(0.5), radius: 8)
                        Text(event.title)
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
                        // MARK: - Event Info Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(event.title)
                                .font(.setCustomFont(name: .InterBlack, size: 32))
                                .foregroundStyle(ThemeColors.neonCyan)
                            Text(event.description)
                                .font(.setCustomFont(name: .InterMedium, size: 16))
                                .foregroundStyle(ThemeColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        
                        // MARK: - Boss Card
                        EventBossDetailCard(boss: event.boss)
                            .padding(.horizontal, 24)
                        
                        // MARK: - Modifiers
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(userEnv.labelGameModifiers)
                            
                            EventModifiersRow(modifiers: event.modifiers)
                        }
                        .padding(.horizontal, 24)
                        
                        // MARK: - Event Character (Weekly only)
                        if let character = event.character {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader(userEnv.labelSpecialCharacter)
                                
                                EventCharacterCard(character: character, isSelected: selectedCharacter?.id == character.id)
                                    .onTapGesture {
                                        HapticManager.shared.play(.buttonTap)
                                        selectedCharacter = character
                                    }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // MARK: - Rewards
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(userEnv.labelRankingRewards)
                            
                            VStack(spacing: 10) {
                                ForEach(event.rewards) { reward in
                                    EventRewardRow(reward: reward)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        // MARK: - Start Button
                        let hasPlayed = userEnv.hasPlayedEvent(event.id)
                        let savedScore = userEnv.savedEventScore(event.id) ?? 0
                        
                        // Oynandıysa son puan göster
                        if hasPlayed {
                            VStack(spacing: 8) {
                                Text(userEnv.labelYourBestScore)
                                    .font(.setCustomFont(name: .InterBold, size: 11))
                                    .foregroundStyle(ThemeColors.textMuted)
                                    .tracking(2)
                                Text(savedScore.formatted())
                                    .font(.setCustomFont(name: .InterBlack, size: 36))
                                    .foregroundStyle(ThemeColors.neonCyan)
                                    .shadow(color: ThemeColors.neonCyan.opacity(0.5), radius: 10)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(20)
                            .background(ThemeColors.neonCyan.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(ThemeColors.neonCyan.opacity(0.3), lineWidth: 1))
                            .padding(.horizontal, 24)
                        }
                        
                        Button {
                            if !hasPlayed {
                                HapticManager.shared.play(.heavy)
                                // markEventStarted oyun başlınca startRound içinde çağrılıyor,
                                // burada da erken markala — router push ananından itibaren geçerli.
                                userEnv.markEventStarted(event.id)
                                MainViewsRouter.shared.pushToEventGame(config: event)
                            } else {
                                HapticManager.shared.play(.error)
                            }
                        } label: {
                            HStack {
                                Text(hasPlayed ? userEnv.labelChallengeCompleted : userEnv.btnStartChallenge)
                                    .font(.setCustomFont(name: .InterBlack, size: 16))
                                    .foregroundStyle(hasPlayed ? ThemeColors.textSecondary : ThemeColors.cosmicBlack)
                                    .tracking(2)
                                if !hasPlayed {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(ThemeColors.cosmicBlack)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(ThemeColors.success)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(hasPlayed ? ThemeColors.gridDark : ThemeColors.neonCyan)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: hasPlayed ? .clear : ThemeColors.neonCyan.opacity(0.4), radius: 15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16).stroke(hasPlayed ? ThemeColors.gridStroke : .clear, lineWidth: 1)
                            )
                        }
                        .disabled(hasPlayed)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 10)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.setCustomFont(name: .InterBold, size: 13))
            .foregroundStyle(ThemeColors.textMuted)
            .tracking(2)
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

struct EventBossDetailCard: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let boss: EventBoss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Boss Header
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(ThemeColors.neonPink.opacity(0.15))
                        .frame(width: 54, height: 54)
                    Image(systemName: "skull.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(ThemeColors.neonPink)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("BOSS: \(boss.name)")
                        .font(.setCustomFont(name: .InterBlack, size: 20))
                        .foregroundColor(ThemeColors.neonPink)
                    Text(boss.description)
                        .font(.setCustomFont(name: .InterMedium, size: 13))
                        .foregroundColor(ThemeColors.textSecondary)
                }
                
                Spacer()
            }
            
            // Boss Intents
            VStack(alignment: .leading, spacing: 10) {
                Text(userEnv.labelSabotageAbilitiesTemplate.replacingOccurrences(of: "{{value}}", with: "\(boss.intentCycle)"))
                    .font(.setCustomFont(name: .InterBold, size: 11))
                    .foregroundColor(ThemeColors.neonOrange)
                    .tracking(1)
                
                VStack(spacing: 8) {
                    ForEach(boss.intents) { intent in
                        HStack(spacing: 12) {
                            Text(intent.type.emoji)
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(intent.description)
                                    .font(.setCustomFont(name: .InterMedium, size: 14))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(ThemeColors.surfaceLight.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ThemeColors.neonPink.opacity(0.15), lineWidth: 1))
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(ThemeColors.neonPink.opacity(0.3), lineWidth: 1.5))
    }
}

struct EventCharacterCard: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let character: EventCharacter
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Character Info
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ThemeColors.electricYellow.opacity(0.1))
                        .frame(width: 50, height: 50)
                    Image(systemName: "person.fill.viewfinder")
                        .font(.system(size: 24))
                        .foregroundStyle(ThemeColors.electricYellow)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(character.name)
                        .font(.setCustomFont(name: .InterBold, size: 18))
                        .foregroundColor(ThemeColors.electricYellow)
                    Text(character.description)
                        .font(.setCustomFont(name: .InterMedium, size: 13))
                        .foregroundColor(ThemeColors.textSecondary)
                }
                
                Spacer()
                
                if character.isExclusive {
                    Text(userEnv.labelExclusive)
                        .font(.setCustomFont(name: .InterBlack, size: 10))
                        .foregroundColor(ThemeColors.cosmicBlack)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ThemeColors.neonCyan)
                        .clipShape(Capsule())
                }
            }
            
            // Bonus Modifiers
            if !character.bonusModifiers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(userEnv.labelCharacterBonuses)
                        .font(.setCustomFont(name: .InterBold, size: 10))
                        .foregroundColor(ThemeColors.electricYellow)
                    
                    EventModifiersRow(modifiers: character.bonusModifiers)
                }
            }
        }
        .padding(16)
        .background(isSelected ? ThemeColors.electricYellow.opacity(0.1) : ThemeColors.surfaceDark.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20)
            .stroke(isSelected ? ThemeColors.electricYellow : ThemeColors.gridStroke.opacity(0.5), lineWidth: isSelected ? 2 : 1))
    }
}

struct EventRewardRow: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let reward: EventReward
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank Range
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(ThemeColors.surfaceLight.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Text(reward.rankFrom == reward.rankTo ? "\(reward.rankFrom)" : "\(reward.rankFrom)-\(reward.rankTo)")
                    .font(.setCustomFont(name: .InterBlack, size: 12))
                    .foregroundColor(ThemeColors.electricYellow)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(reward.label)
                    .font(.setCustomFont(name: .InterBold, size: 14))
                    .foregroundColor(.white)
                Text(reward.rankFrom == 1 ? userEnv.labelChampionReward : userEnv.labelRankingReward)
                    .font(.setCustomFont(name: .InterRegular, size: 11))
                    .foregroundColor(ThemeColors.textMuted)
            }
            
            Spacer()
            
            // Rewards
            HStack(spacing: 12) {
                if reward.diamonds > 0 {
                    currencyView(icon: "icon_diamond", value: reward.diamonds, color: ThemeColors.neonCyan)
                }
                
                if reward.gold > 0 {
                    currencyView(icon: "icon_gold", value: reward.gold, color: ThemeColors.electricYellow)
                }
            }
        }
        .padding(12)
        .background(ThemeColors.surfaceDark.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(ThemeColors.gridStroke.opacity(0.3), lineWidth: 1))
    }
    
    private func currencyView(icon: String, value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(icon)
                .resizable()
                .frame(width: 16, height: 16)
            Text("\(value)")
                .font(.setCustomFont(name: .InterBold, size: 13))
                .foregroundColor(color)
        }
    }
}

