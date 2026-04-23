//
//  GameOverlays.swift
//  Block-Jack
//

import SwiftUI

struct GameOverOverlay: View {
    @ObservedObject var vm: GameViewModel
    @EnvironmentObject var userEnv: UserEnvironment

    var isRunOver: Bool { vm.run.lives <= 0 }

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 20) {
                // Başlık
                Text(isRunOver
                     ? userEnv.localizedString("RUN BİTTİ", "RUN OVER")
                     : userEnv.localizedString("ROUND KAYBEDILDI", "ROUND LOST"))
                    .font(.setCustomFont(name: .InterBlack, size: 34))
                    .foregroundStyle(ThemeColors.neonPink)
                    .shadow(color: ThemeColors.neonPink, radius: 12)

                // Kalan Can Göstergesi
                HStack(spacing: 6) {
                    ForEach(1...vm.run.maxLives, id: \.self) { i in
                        Image(systemName: i <= vm.run.lives ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundStyle(i <= vm.run.lives ? ThemeColors.neonPink : ThemeColors.gridDark)
                    }
                }

                VStack(spacing: 4) {
                    Text(isRunOver
                         ? userEnv.localizedString("Tüm canlarını kaybettin.", "You've lost all your lives.")
                         : userEnv.localizedString("Grid sıkıştı veya süren bitti.", "Grid locked or time ran out."))
                        .font(.setCustomFont(name: .InterMedium, size: 14))
                        .foregroundStyle(ThemeColors.textSecondary)
                        .multilineTextAlignment(.center)

                    if !isRunOver {
                        Text(userEnv.localizedString("Kalan: \(vm.run.lives) can", "Lives remaining: \(vm.run.lives)"))
                            .font(.setCustomFont(name: .InterBold, size: 12))
                            .foregroundStyle(ThemeColors.neonPink.opacity(0.8))
                    }
                }
                .padding(.horizontal, 32)

                if isRunOver {
                    // Tüm canlar bitti → Özet ekranı göster, sonra Dashboard'a dön
                    Button {
                        HapticManager.shared.play(.buttonTap)
                        if let summary = SaveManager.shared.slots
                            .first(where: { $0.id == vm.activeSlotId })?.lastRunSummary {
                            MainViewsRouter.shared.push(
                                RunSummaryView(summary: summary, slotId: vm.activeSlotId)
                                    .environmentObject(UserEnvironment.shared)
                            )
                        } else {
                            MainViewsRouter.shared.popToDashboard()
                        }
                    } label: {
                        Text(userEnv.localizedString("ÖZETİ GÖR", "VIEW SUMMARY"))
                            .font(.setCustomFont(name: .InterExtraBold, size: 20))
                            .foregroundStyle(ThemeColors.cosmicBlack)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 32)
                            .background(ThemeColors.neonPink)
                            .clipShape(Capsule())
                    }
                } else {
                    // Kalan can var → retry
                    Button {
                        HapticManager.shared.play(.buttonTap)
                        vm.board.resetGrid()
                        vm.startRound()
                    } label: {
                        Text(userEnv.localizedString("TEKRAR DENE (\(vm.run.lives) CAN)", "RETRY (\(vm.run.lives) LIVES)"))
                            .font(.setCustomFont(name: .InterExtraBold, size: 20))
                            .foregroundStyle(ThemeColors.cosmicBlack)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 32)
                            .background(ThemeColors.electricYellow)
                            .clipShape(Capsule())
                    }

                    Button {
                        HapticManager.shared.play(.buttonTap)
                        MainViewsRouter.shared.popToDashboard()
                    } label: {
                        Text(userEnv.localizedString("PES ET", "GIVE UP"))
                            .font(.setCustomFont(name: .InterBold, size: 16))
                            .foregroundStyle(ThemeColors.textMuted)
                            .padding(.vertical, 12)
                    }
                }
            }
        }
    }
}

struct RoundCompleteOverlay: View {
    @ObservedObject var vm: GameViewModel
    @EnvironmentObject var userEnv: UserEnvironment
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text(userEnv.localizedString("ROUND TAMAMLANDI", "ROUND CLEAR"))
                        .font(.setCustomFont(name: .InterBlack, size: 30))
                        .foregroundStyle(ThemeColors.success)
                        .shadow(color: ThemeColors.success, radius: 10)
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 3) {
                            ForEach(1...vm.run.maxLives, id: \.self) { i in
                                Image(systemName: i <= vm.run.lives ? "heart.fill" : "heart")
                                    .font(.system(size: 12))
                                    .foregroundStyle(i <= vm.run.lives ? ThemeColors.neonPink : ThemeColors.gridDark)
                            }
                        }
                        HStack(spacing: 4) {
                            Image("icon_gold").resizable().frame(width: 16, height: 16)
                            Text("\(userEnv.gold)")
                                .font(.setCustomFont(name: .InterBold, size: 14))
                                .foregroundStyle(ThemeColors.electricYellow)
                        }
                    }
                }
                .padding(.top, 32)
                .padding(.bottom, 16)
                
                Spacer()
                
                Button {
                    HapticManager.shared.play(.buttonTap)
                    // Phase 9: Haritaya Dönüş
                    MainViewsRouter.shared.popToMap(slotId: vm.activeSlotId)
                } label: {
                    Text(userEnv.localizedString("HARİTAYA DÖN", "BACK TO MAP"))
                        .font(.setCustomFont(name: .InterExtraBold, size: 18))
                        .foregroundStyle(ThemeColors.cosmicBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [ThemeColors.neonCyan, ThemeColors.electricYellow.opacity(0.8)],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
    }
}


struct PauseOverlay: View {
    @ObservedObject var vm: GameViewModel
    @EnvironmentObject var userEnv: UserEnvironment
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.82).ignoresSafeArea()
            
            AdaptiveOverlay(
                header: {
                    OverlayTitleBlock(
                        userEnv.localizedString("DURAKLATILDI", "PAUSED"),
                        subtitle: userEnv.localizedString("Sistem ayarlarını yönet ve devam et.", "Manage system settings and continue."),
                        color: ThemeColors.electricYellow
                    )
                },
                content: {
                    VStack(spacing: 14) {
                        // Quick toggles
                        toggleRow(
                            title: userEnv.localizedString("Ses", "Sound"),
                            systemIcon: "speaker.wave.2.fill",
                            isOn: $userEnv.isSoundEnabled,
                            tint: ThemeColors.neonCyan
                        )
                        toggleRow(
                            title: userEnv.localizedString("Titreşim", "Haptics"),
                            systemIcon: "waveform.path",
                            isOn: $userEnv.isHapticEnabled,
                            tint: ThemeColors.neonPurple
                        )
                        
                        // Actions
                        actionButton(
                            title: userEnv.localizedString("DEVAM ET", "RESUME"),
                            color: ThemeColors.neonCyan
                        ) {
                            HapticManager.shared.play(.buttonTap)
                            vm.resumeGame()
                        }
                        
                        actionButton(
                            title: userEnv.localizedString("ROUND'U YENİDEN BAŞLAT", "RESTART ROUND"),
                            color: ThemeColors.electricYellow
                        ) {
                            HapticManager.shared.play(.buttonTap)
                            vm.board.resetGrid()
                            vm.startRound()
                        }
                        
                        actionButton(
                            title: userEnv.localizedString("AYARLAR", "SETTINGS"),
                            color: ThemeColors.neonPink
                        ) {
                            HapticManager.shared.play(.buttonTap)
                            MainViewsRouter.shared.present(view: MainNavigationView.builder.makeView(
                                SettingsView().environmentObject(userEnv),
                                withNavigationTitle: "", navigationBarHidden: true
                            ))
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                },
                footer: {
                    Button {
                        HapticManager.shared.play(.buttonTap)
                        vm.saveGameState()
                        MainViewsRouter.shared.popToSlotHub(slotId: vm.activeSlotId)
                    } label: {
                        Text(userEnv.localizedString("KAYDET VE HUB'A DÖN", "SAVE & BACK TO HUB"))
                            .font(.setCustomFont(name: .InterExtraBold, size: 18))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ThemeColors.gridStroke.opacity(0.7), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                }
            )
        }
    }
    
    private func actionButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.setCustomFont(name: .InterExtraBold, size: 16))
                .foregroundStyle(ThemeColors.cosmicBlack)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: color.opacity(0.35), radius: 10)
        }
        .buttonStyle(.plain)
    }
    
    private func toggleRow(title: String, systemIcon: String, isOn: Binding<Bool>, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemIcon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 28)
            
            Text(title)
                .font(.setCustomFont(name: .InterBold, size: 14))
                .foregroundStyle(.white)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(tint)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(tint.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Boss Intro Overlay
struct BossIntroOverlay: View {
    @ObservedObject var vm: GameViewModel
    @EnvironmentObject var userEnv: UserEnvironment
    @State private var animate = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text(userEnv.localizedString("DİKKAT", "WARNING"))
                    .font(.setCustomFont(name: .InterBlack, size: 24))
                    .foregroundStyle(ThemeColors.neonPink)
                    .tracking(8)
                    .opacity(animate ? 1 : 0.3)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: animate)
                
                Text(userEnv.localizedString("BOSS ROUND", "BOSS ROUND"))
                    .font(.setCustomFont(name: .InterBlack, size: 48))
                    .foregroundStyle(.white)
                    .shadow(color: ThemeColors.neonPink, radius: animate ? 20 : 5)
                    .scaleEffect(animate ? 1.05 : 0.95)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animate)
                
                if let mod = vm.run.round.modifier {
                    VStack(spacing: 8) {
                        Text(mod.title)
                            .font(.setCustomFont(name: .InterExtraBold, size: 24))
                            .foregroundStyle(ThemeColors.electricYellow)
                        Text(mod.description)
                            .font(.setCustomFont(name: .InterMedium, size: 16))
                            .foregroundStyle(ThemeColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 20)
                }
                
                Spacer().frame(height: 40)
                
                Button {
                    HapticManager.shared.play(.heavy)
                    vm.startBossRound()
                } label: {
                    Text(userEnv.localizedString("SAVAŞ", "FIGHT"))
                        .font(.setCustomFont(name: .InterBlack, size: 28))
                        .foregroundStyle(ThemeColors.cosmicBlack)
                        .frame(width: 200, height: 60)
                        .background(ThemeColors.neonPink)
                        .clipShape(Capsule())
                        .shadow(color: ThemeColors.neonPink.opacity(0.8), radius: 10)
                }
            }
            .padding(.vertical, 50)
        }
        .onAppear { animate = true }
    }
}

// MARK: - Chapter Complete Overlay
struct ChapterCompleteOverlay: View {
    @ObservedObject var vm: GameViewModel
    @EnvironmentObject var userEnv: UserEnvironment
    
    var chapterNumber: Int {
        // Round 6 başlıyorsa Chapter 2'ye geçiliyor demektir
        (vm.run.currentRound - 1) / 5 + 1
    }
    
    var body: some View {
        ZStack {
            ThemeColors.backgroundGradient.ignoresSafeArea()
            Color.black.opacity(0.6).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text(userEnv.localizedString("BÖLÜM TAMAMLANDI", "CHAPTER CLEARED"))
                    .font(.setCustomFont(name: .InterBlack, size: 28))
                    .foregroundStyle(ThemeColors.success)
                    .tracking(4)
                
                Text(userEnv.localizedString("Bölüm \(chapterNumber - 1) bitti.", "Chapter \(chapterNumber - 1) complete."))
                    .font(.setCustomFont(name: .InterMedium, size: 18))
                    .foregroundStyle(ThemeColors.textSecondary)
                
                Spacer().frame(height: 20)
                
                VStack(spacing: 8) {
                    Text(userEnv.localizedString("SONRAKİ DURAK:", "NEXT STOP:"))
                        .font(.setCustomFont(name: .InterBold, size: 14))
                        .foregroundStyle(ThemeColors.textMuted)
                    
                    Text(userEnv.localizedString("BÖLÜM \(chapterNumber)", "CHAPTER \(chapterNumber)"))
                        .font(.setCustomFont(name: .InterBlack, size: 40))
                        .foregroundStyle(ThemeColors.neonCyan)
                        .shadow(color: ThemeColors.neonCyan, radius: 10)
                }
                
                Spacer().frame(height: 40)
                
                Button {
                    // Post-run standard: chapter bitti → mini map state’i temizle,
                    // WorldMap’e dön ve bir sonraki level’ı oradan seç.
                    SaveManager.shared.clearChapterMap(slotId: vm.activeSlotId)
                    MainViewsRouter.shared.popToWorldMap(slotId: vm.activeSlotId)
                } label: {
                    Text(userEnv.localizedString("DEVAM ET", "CONTINUE"))
                        .font(.setCustomFont(name: .InterExtraBold, size: 24))
                        .foregroundStyle(ThemeColors.cosmicBlack)
                        .frame(height: 60)
                        .padding(.horizontal, 40)
                        .background(ThemeColors.neonCyanGradient)
                        .clipShape(Capsule())
                        .shadow(color: ThemeColors.neonCyan.opacity(0.6), radius: 10)
                }
            }
        }
    }
}

// MARK: - Tutorial Overlay
struct TutorialOverlay: View {
    @ObservedObject var vm: GameViewModel
    @EnvironmentObject var userEnv: UserEnvironment
    @State private var currentStep = 0
    
    struct TutorialStep {
        let titleTR: String
        let titleEN: String
        let icon: String
        let descTR: String
        let descEN: String
    }
    
    private let steps = [
        TutorialStep(
            titleTR: "BLOKLARI YERLEŞTİR", titleEN: "PLACE BLOCKS",
            icon: "🧩",
            descTR: "Blokları ızgaraya sürükle bırak. Dolu satır ve sütunlar silinirken puan ve zaman kazandırır.",
            descEN: "Drag blocks to the grid. Clearing full rows and columns earns you points and extra time."
        ),
        TutorialStep(
            titleTR: "ROGUELITE AKIŞI", titleEN: "ROGUELITE LOOP",
            icon: "🔄",
            descTR: "Round hedefine zaman dolmadan ulaşmalısın. Her 5 round'da bir Boss karşına çıkar!",
            descEN: "Reach the score target before time runs out. Every 5 rounds, you'll face a Boss!"
        ),
        TutorialStep(
            titleTR: "BÜYÜK KOMBOLAR", titleEN: "BIG COMBOS",
            icon: "🔥",
            descTR: "Aynı anda çoklu hat silerek büyük çarpanlar kazan. Renk uyumu (Flush) ekstra altın verir.",
            descEN: "Clear multiple lines at once for huge multipliers. Matching colors (Flush) earns extra gold."
        ),
        TutorialStep(
            titleTR: "ÖZEL GÜÇLER", titleEN: "SPECIAL POWERS",
            icon: "⚡",
            descTR: "Karakterinin Overdrive gücünü doldur ve kullan. ⚡💣🌀 gibi özel blokları kaçırma!",
            descEN: "Charge and activate your Character's Overdrive. Don't miss special blocks like ⚡💣🌀!"
        )
    ]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                Text(userEnv.localizedString("NASIL OYNANIR?", "HOW TO PLAY"))
                    .font(.setCustomFont(name: .InterBlack, size: 20))
                    .foregroundStyle(ThemeColors.textMuted)
                    .tracking(2)
                
                // Content
                VStack(spacing: 20) {
                    Text(steps[currentStep].icon)
                        .font(.system(size: 80))
                        .shadow(color: ThemeColors.neonCyan.opacity(0.5), radius: 20)
                        
                    Text(userEnv.localizedString(steps[currentStep].titleTR, steps[currentStep].titleEN))
                        .font(.setCustomFont(name: .InterBlack, size: 28))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(userEnv.localizedString(steps[currentStep].descTR, steps[currentStep].descEN))
                        .font(.setCustomFont(name: .InterMedium, size: 18))
                        .foregroundStyle(ThemeColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                .id(currentStep)
                
                Spacer()
                
                // Indicators
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Circle()
                            .fill(i == currentStep ? ThemeColors.neonCyan : ThemeColors.gridStroke)
                            .frame(width: 8, height: 8)
                            .scaleEffect(i == currentStep ? 1.2 : 1.0)
                    }
                }
                
                // Button
                Button {
                    withAnimation {
                        if currentStep < steps.count - 1 {
                            HapticManager.shared.play(.selection)
                            currentStep += 1
                        } else {
                            HapticManager.shared.play(.success)
                            vm.dismissTutorial()
                        }
                    }
                } label: {
                    Text(currentStep < steps.count - 1 ? 
                         userEnv.localizedString("SONRAKİ", "NEXT") : 
                         userEnv.localizedString("BAŞLA!", "START!"))
                        .font(.setCustomFont(name: .InterExtraBold, size: 22))
                        .foregroundStyle(ThemeColors.cosmicBlack)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(ThemeColors.neonCyanGradient)
                        .clipShape(Capsule())
                        .shadow(color: ThemeColors.neonCyan.opacity(0.4), radius: 10)
                }
                .padding(.horizontal, 40)
            }
            .padding(.vertical, 60)
        }
    }
}
