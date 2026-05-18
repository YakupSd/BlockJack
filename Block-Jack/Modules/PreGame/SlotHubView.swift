//
//  SlotHubView.swift
//  Block-Jack
//
//  Slot-bağlamlı ana menü. Slot seçildikten sonra kullanıcı buraya düşer
//  ve tüm shop/karakter/galeri/sefer aksiyonları slot kimliği taşıyarak
//  buradan açılır. Böylece "hangi oyuncu için alışveriş yapıyorum"
//  sorusu her ekranda net kalır; Market/Karakter'e slot seçmeden
//  girme bug'ı ortadan kalkar.
//

import SwiftUI

struct SlotHubView: View {

    @EnvironmentObject var userEnv: UserEnvironment
    @StateObject private var saveManager = SaveManager.shared
    @State private var showDailyReward = false
    @State private var showHubIntro = false

    let slotId: Int

    private var slot: SaveSlot? {
        saveManager.slots.first { $0.id == slotId }
    }

    private var character: GameCharacter {
        let id = slot?.characterId ?? userEnv.selectedCharacterID
        return GameCharacter.roster.first(where: { $0.id == id })
            ?? GameCharacter.roster[0]
    }

    /// Devam edilebilir bir run var mı?
    /// - Slot dolu OLMALI.
    /// - `currentChapterMap` null DEĞİL.
    /// - Map bitmemiş (finale node tamamlanmamış). Eskiden bu kontrol yoktu
    ///   ve bölüm bittikten sonra da "SEFERE DEVAM" çıkıp bitik haritaya
    ///   geri atıyor, loop yapıyordu.
    private var hasActiveRun: Bool {
        guard let s = slot, !s.isEmpty, let map = s.currentChapterMap else { return false }
        return !map.isCleared
    }

    var body: some View {
        ZStack {
            ThemeColors.backgroundGradient.ignoresSafeArea()
            backgroundGrid

            VStack(spacing: 0) {
                topBar
                    .padding(.bottom, 8)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        // 1. Character Neural Link (Hero Section)
                        characterNeuralLinkHeader

                        // 2. Core Telemetry Dashboard
                        if let s = slot, !s.isEmpty {
                            coreTelemetryDashboard(slot: s)
                                .padding(.horizontal, 20)
                        }

                        // 3. Primary Terminal Actions
                        VStack(spacing: 12) {
                            primaryActionButton
                            
                            if hasActiveRun {
                                seferSecButton
                            }
                            
                            perkShopButton
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 10)
                }

                // 4. Fixed System Navigation
                VStack(spacing: 12) {
                    hubPills
                    currencyFooter
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
                .background(
                    ZStack {
                        ThemeColors.cosmicBlack.opacity(0.8)
                            .background(.ultraThinMaterial)
                        
                        // Cyber-edge line
                        VStack {
                            Rectangle()
                                .fill(ThemeColors.neonCyan.opacity(0.3))
                                .frame(height: 1)
                            Spacer()
                        }
                    }
                    .ignoresSafeArea()
                )
            }

            // High-Fidelity CRT Scanline (Subtle)
            SlotHubCyberOverlay()
                .allowsHitTesting(false)
                .opacity(0.4)

            if showDailyReward {
                DailyRewardOverlay(isPresented: $showDailyReward)
                    .environmentObject(userEnv)
                    .zIndex(10)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            AudioManager.shared.playMusic(.menu)
            if let s = slot, !s.isEmpty {
                userEnv.loadFromSlot(s)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                HapticManager.shared.play(.buttonTap)
                userEnv.clearActiveSlot()
                MainViewsRouter.shared.popToDashboard()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text(userEnv.btnBackCaps)
                }
                .font(.setCustomFont(name: .InterBold, size: 10))
                .tracking(2)
                .foregroundStyle(ThemeColors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(ThemeColors.surfaceDark.opacity(0.6))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(ThemeColors.neonCyan.opacity(0.3), lineWidth: 1))
            }

            Spacer()

            HStack(spacing: 12) {
                Button { showDailyReward = true } label: {
                    Image(systemName: "gift.fill")
                        .foregroundStyle(userEnv.canClaimDaily ? ThemeColors.electricYellow : ThemeColors.textMuted)
                        .frame(width: 40, height: 40)
                        .background(ThemeColors.surfaceDark.opacity(0.6))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(ThemeColors.gridStroke, lineWidth: 1))
                }

                Button {
                    HapticManager.shared.play(.buttonTap)
                    MainViewsRouter.shared.present(view: MainNavigationView.builder.makeView(
                        SettingsView().environmentObject(userEnv),
                        withNavigationTitle: "", navigationBarHidden: true
                    ))
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(ThemeColors.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(ThemeColors.surfaceDark.opacity(0.8))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    // MARK: - Character Neural Link

    private var characterNeuralLinkHeader: some View {
        VStack(spacing: 24) {
            ZStack {
                // Subtle Holographic Aura
                Circle()
                    .fill(ThemeColors.neonCyan.opacity(0.1))
                    .frame(width: 180, height: 180)
                    .blur(radius: 40)

                ZStack(alignment: .bottom) {
                    // Portrait Frame
                    ZStack {
                        RoundedRectangle(cornerRadius: 44)
                            .fill(ThemeColors.surfaceDark)
                            .frame(width: 170, height: 170)
                            .overlay(
                                RoundedRectangle(cornerRadius: 44)
                                    .stroke(ThemeColors.neonCyan.opacity(0.5), lineWidth: 1)
                            )
                        
                        Image(character.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 160, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 40))
                    }
                    .characterMasteryFrame(characterId: character.id, cornerRadius: 44)
                    .shadow(color: ThemeColors.neonCyan.opacity(0.3), radius: 20)

                    CharacterMasteryBadge(characterId: character.id)
                        .offset(y: 18)
                }
            }

            VStack(spacing: 8) {
                // Status Bar
                HStack(spacing: 6) {
                    Circle().fill(ThemeColors.neonGreen).frame(width: 6, height: 6)
                    Text(userEnv.labelNeuralLinkStableCaps)
                        .font(.setCustomFont(name: .InterBold, size: 8))
                        .tracking(2)
                        .foregroundStyle(ThemeColors.neonGreen)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(ThemeColors.neonGreen.opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(ThemeColors.neonGreen.opacity(0.3), lineWidth: 1))

                // Refined Title
                SlotHubGlitchText(text: character.name.uppercased())
                
                HStack(spacing: 8) {
                    pillTag(text: "SLOT \(slotId)", color: ThemeColors.electricYellow)
                    if let s = slot, !s.isEmpty {
                        pillTag(text: "SEC: \(s.unlockedWorldLevel)", color: ThemeColors.neonPurple)
                        pillTag(text: "RND: \(s.currentRound)", color: ThemeColors.neonPink)
                    }
                }
            }
        }
    }

    private func pillTag(text: String, color: Color) -> some View {
        Text(text)
            .font(.setCustomFont(name: .InterBold, size: 9))
            .tracking(1)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Core Telemetry Dashboard

    private func coreTelemetryDashboard(slot: SaveSlot) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text(userEnv.labelSystemTelemetryCaps)
                    .font(.setCustomFont(name: .InterBlack, size: 10))
                    .tracking(3)
                    .foregroundStyle(ThemeColors.textSecondary)
                Spacer()
                Text("EST. 2026")
                    .font(.setCustomFont(name: .InterBold, size: 8))
                    .foregroundStyle(ThemeColors.textMuted)
            }

            // Telemetry Grid
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                telemetryBox(title: userEnv.labelMaxSectorCaps, value: "W\(slot.bestWorldLevel)", color: ThemeColors.neonPurple, icon: "map.fill")
                telemetryBox(title: userEnv.labelCreditsCaps, value: "\(slot.gold)", color: ThemeColors.electricYellow, icon: "bitcoinsign.circle.fill")
                telemetryBox(title: userEnv.labelStabilityCaps, value: "R\(slot.currentRound)", color: ThemeColors.neonCyan, icon: "waveform.path.ecg")
                telemetryBox(title: userEnv.labelModulesCaps, value: "\(slot.perkLevels.filter { $0.value >= 1 }.count)", color: ThemeColors.neonPink, icon: "cpu.fill")
            }

            // Run Logs
            if !slot.recentRuns.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(userEnv.labelRecentDataLogsCaps)
                        .font(.setCustomFont(name: .InterBold, size: 9))
                        .tracking(2)
                        .foregroundStyle(ThemeColors.textMuted)

                    ForEach(slot.recentRuns.prefix(2)) { r in
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(ThemeColors.neonCyan.opacity(0.1))
                                .frame(width: 2, height: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                let name = GameCharacter.roster.first(where: { $0.id == r.characterId })?.name ?? r.characterId
                                Text(name.uppercased())
                                    .font(.setCustomFont(name: .InterBlack, size: 10))
                                    .foregroundStyle(.white)
                                Text(userEnv.formatSectorDataLog(sectorIndex: r.worldLevelReached))
                                    .font(.setCustomFont(name: .InterMedium, size: 8))
                                    .foregroundStyle(ThemeColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Text("\(r.score)")
                                .font(.setCustomFont(name: .InterBlack, size: 14))
                                .foregroundStyle(ThemeColors.electricYellow)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.02))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(20)
        .background(
            ZStack {
                ThemeColors.surfaceDark.opacity(0.6)
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(ThemeColors.gridStroke.opacity(0.4), lineWidth: 1))
    }

    private func telemetryBox(title: String, value: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)
                Spacer()
                Text("LIVE")
                    .font(.setCustomFont(name: .InterBold, size: 7))
                    .foregroundStyle(color.opacity(0.6))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.setCustomFont(name: .InterBold, size: 9))
                    .tracking(1)
                    .foregroundStyle(ThemeColors.textMuted)
                Text(value)
                    .font(.setCustomFont(name: .InterBlack, size: 20))
                    .foregroundStyle(.white)
            }
            
            // Subtle indicator
            Rectangle()
                .fill(color.opacity(0.3))
                .frame(height: 1)
                .overlay(
                    Rectangle().fill(color).frame(width: 30),
                    alignment: .leading
                )
        }
        .padding(16)
        .background(ThemeColors.surfaceDark.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }

    // MARK: - Actions

    private var primaryActionButton: some View {
        Button {
            HapticManager.shared.play(.buttonTap)
            if hasActiveRun {
                MainViewsRouter.shared.pushToMap(slotId: slotId)
            } else {
                if let s = SaveManager.shared.slots.first(where: { $0.id == slotId }) {
                    userEnv.loadFromSlot(s)
                }
                MainViewsRouter.shared.push(
                    WorldSelectionView(slotId: slotId).environmentObject(UserEnvironment.shared)
                )
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(ThemeColors.electricYellow)
                    .shadow(color: ThemeColors.electricYellow.opacity(0.4), radius: 15)
                
                SlotHubButtonGlint()
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                HStack(spacing: 12) {
                    Image(systemName: hasActiveRun ? "play.circle.fill" : "bolt.fill")
                        .font(.system(size: 24, weight: .bold))
                    Text(hasActiveRun 
                         ? userEnv.btnContinueRunCaps
                         : userEnv.btnStartNewRunCaps)
                        .font(.setCustomFont(name: .InterBlack, size: 18))
                        .tracking(1)
                }
                .foregroundStyle(ThemeColors.cosmicBlack)
            }
            .frame(height: 70)
        }
    }

    private var seferSecButton: some View {
        Button {
            HapticManager.shared.play(.selection)
            MainViewsRouter.shared.push(
                WorldSelectionView(slotId: slotId).environmentObject(UserEnvironment.shared)
            )
        } label: {
            HStack {
                Text(userEnv.btnChangeSectorCaps)
                Spacer()
                Image(systemName: "arrow.triangle.2.circlepath")
            }
            .font(.setCustomFont(name: .InterBold, size: 13))
            .tracking(1)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .frame(height: 56)
            .background(ThemeColors.surfaceDark.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(ThemeColors.neonCyan.opacity(0.3), lineWidth: 1))
        }
    }

    private var perkShopButton: some View {
        Button {
            MainViewsRouter.shared.push(
                PerkUpgradeView(userEnv: userEnv)
            )
        } label: {
            HStack {
                Text(userEnv.btnPerkUpgradesCaps)
                Spacer()
                Image(systemName: "sparkles")
            }
            .font(.setCustomFont(name: .InterBold, size: 13))
            .tracking(1)
            .foregroundStyle(ThemeColors.electricYellow)
            .padding(.horizontal, 20)
            .frame(height: 56)
            .background(ThemeColors.electricYellow.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(ThemeColors.electricYellow.opacity(0.3), lineWidth: 1))
        }
    }

    // MARK: - Navigation

    private var hubPills: some View {
        HStack(spacing: 12) {
            hubPill(icon: "person.fill", title: userEnv.labelHeroCaps, color: ThemeColors.neonCyan) {
                MainViewsRouter.shared.pushToCharacterSelection(slotId: slotId, mode: .changeInHub)
            }
            hubPill(icon: "cart.fill", title: userEnv.labelMarketCaps, color: ThemeColors.electricYellow) {
                MainViewsRouter.shared.present(view: MainNavigationView.builder.makeView(
                    UpgradesView(slotId: slotId).environmentObject(userEnv),
                    withNavigationTitle: "", navigationBarHidden: true
                ))
            }
            hubPill(icon: "book.fill", title: userEnv.labelLoreCaps, color: ThemeColors.neonPurple) {
                MainViewsRouter.shared.present(view: MainNavigationView.builder.makeView(
                    CollectionMainView().environmentObject(userEnv),
                    withNavigationTitle: "", navigationBarHidden: true
                ))
            }
        }
        .padding(.horizontal, 20)
    }

    private func hubPill(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.setCustomFont(name: .InterBold, size: 10))
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(ThemeColors.surfaceDark.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.2), lineWidth: 1))
        }
    }

    private var currencyFooter: some View {
        HStack(spacing: 24) {
            currencyBadge(icon: "icon_gold", value: userEnv.gold, color: ThemeColors.electricYellow)
            currencyBadge(icon: "icon_diamond", value: userEnv.diamonds, color: ThemeColors.neonCyan)
        }
    }

    private func currencyBadge(icon: String, value: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(icon).resizable().frame(width: 20, height: 20)
            Text("\(value)")
                .font(.setCustomFont(name: .InterBlack, size: 14))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .clipShape(Capsule())
    }

    private var backgroundGrid: some View {
        ZStack {
            Canvas { ctx, size in
                let spacing: CGFloat = 50
                let color = GraphicsContext.Shading.color(ThemeColors.gridStroke.opacity(0.1))
                for x in stride(from: 0, through: size.width, by: spacing) {
                    var p = Path(); p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height))
                    ctx.stroke(p, with: color, lineWidth: 0.5)
                }
                for y in stride(from: 0, through: size.height, by: spacing) {
                    var p = Path(); p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y))
                    ctx.stroke(p, with: color, lineWidth: 0.5)
                }
            }
            
            SlotHubAmbientGlow()
        }
        .ignoresSafeArea()
    }
}

// MARK: - Ultimate Cyber Components

struct SlotHubCyberOverlay: View {
    @State private var flicker = false
    
    var body: some View {
        GeometryReader { geo in
            // Scanlines
            Path { path in
                for y in stride(from: 0, through: geo.size.height, by: 4) {
                    path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(Color.white.opacity(flicker ? 0.03 : 0.01), lineWidth: 0.5)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in flicker.toggle() }
            }
        }
    }
}

struct SlotHubGlitchText: View {
    let text: String
    @State private var offset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Text(text)
                .font(.setCustomFont(name: .InterBlack, size: 28))
                .foregroundStyle(ThemeColors.neonPink.opacity(0.3))
                .offset(x: offset)
            
            Text(text)
                .font(.setCustomFont(name: .InterBlack, size: 28))
                .foregroundStyle(ThemeColors.neonCyan.opacity(0.3))
                .offset(x: -offset)
            
            Text(text)
                .font(.setCustomFont(name: .InterBlack, size: 28))
                .foregroundStyle(.white)
        }
        .tracking(1) // Reduced tracking
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                withAnimation(.interpolatingSpring(stiffness: 500, damping: 10)) {
                    offset = 1.5
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { offset = 0 }
                }
            }
        }
    }
}

struct SlotHubButtonGlint: View {
    @State private var xOffset: CGFloat = -1.2
    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(LinearGradient(colors: [.clear, .white.opacity(0.6), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(width: geo.size.width * 0.3)
                .rotationEffect(.degrees(25))
                .offset(x: xOffset * geo.size.width)
                .onAppear {
                    withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) { xOffset = 1.5 }
                }
        }
    }
}

struct SlotHubAmbientGlow: View {
    var body: some View {
        ZStack {
            RadialGradient(colors: [ThemeColors.neonCyan.opacity(0.1), .clear], center: .topLeading, startRadius: 0, endRadius: 600)
            RadialGradient(colors: [ThemeColors.neonPurple.opacity(0.1), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 600)
        }
    }
}

#Preview {
    SlotHubView(slotId: 1)
        .environmentObject(UserEnvironment.shared)
}
