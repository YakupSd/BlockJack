//
//  WorldSelectionView.swift
//  Block-Jack
//

import SwiftUI

// MARK: - ViewModel types (UI Spec)
struct WorldCardViewModel: Identifiable {
    let id: Int
    let worldId: Int          // 1–5
    let title: String         // "NEON CORE"
    let levelRange: String    // "LVL 1–20"
    let twist: String         // "Tutorial world · No twist"
    let icon: String          // SF Symbol name
    let completedLevels: Int  // 0–20
    let totalLevels: Int      // 20
    let state: WorldState     // .active / .completed / .locked
    let palette: WorldCardPalette
}

enum WorldState { case active, completed, locked }

struct WorldCardPalette {
    let cardBg: Color
    let accentColor: Color
}

// MARK: - View
struct WorldSelectionView: View {
    let slotId: Int
    @EnvironmentObject var userEnv: UserEnvironment
    @Environment(\.dismiss) private var dismiss

    @State private var didAppear = false
    @State private var selectedWorldIndex = 0
    @State private var hasAutoNavigated = false
    @State private var shakeWorldId: Int? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Dynamic Background
                DynamicBackground(palette: worldCards[selectedWorldIndex].palette)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                    Spacer()

                    // MARK: - Horizontal Carousel
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                Spacer().frame(width: 20)
                                ForEach(Array(worldCards.enumerated()), id: \.element.id) { idx, vm in
                                    WorldCardV2(
                                        vm: vm,
                                        isFocused: selectedWorldIndex == idx,
                                        isShaking: shakeWorldId == vm.worldId,
                                        onTap: { onWorldCardTap(vm: vm, index: idx) }
                                    )
                                    .id(idx)
                                    .opacity(didAppear ? 1 : 0)
                                    .offset(x: didAppear ? 0 : 50)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(idx) * 0.08), value: didAppear)
                                }
                                Spacer().frame(width: 20)
                            }
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .onScrollTargetVisibilityChange(idType: Int.self) { visibleIds in
                            if let first = visibleIds.first {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedWorldIndex = first
                                }
                            }
                        }
                    }

                    Spacer()

                    // MARK: - Page Indicator
                    HStack(spacing: 8) {
                        ForEach(0..<worldCards.count, id: \.self) { i in
                            Circle()
                                .fill(i == selectedWorldIndex ? worldCards[i].palette.accentColor : Color.white.opacity(0.2))
                                .frame(width: i == selectedWorldIndex ? 10 : 6, height: i == selectedWorldIndex ? 10 : 6)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Initialize selection to current unlocked world
                let unlocked = max(1, userEnv.unlockedWorldLevel)
                let currentWorldId = min(5, max(1, (unlocked - 1) / 20 + 1))
                selectedWorldIndex = currentWorldId - 1
                
                didAppear = true
                
                guard !hasAutoNavigated else { return }
                let availableWorlds = worldCards.filter { $0.state != .locked }
                if availableWorlds.count == 1, let only = availableWorlds.first {
                    hasAutoNavigated = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        MainViewsRouter.shared.pushToWorldMap(worldId: only.worldId, slotId: slotId)
                    }
                }
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button {
                    HapticManager.shared.play(.buttonTap)
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.05))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(userEnv.localizedString("TOPLAM İLERLEME", "TOTAL PROGRESS"))
                        .font(.setCustomFont(name: .InterBold, size: 9))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(1)
                    Text("\(completedWorldCount * 20 + worldCards[min(4, completedWorldCount)].completedLevels)%")
                        .font(.setCustomFont(name: .InterBlack, size: 16))
                        .foregroundStyle(.white)
                }
            }

            Text(userEnv.localizedString("SEKTÖR SEÇİMİ", "SECTOR SELECTION"))
                .font(.setCustomFont(name: .InterBlack, size: 28))
                .foregroundStyle(.white)
                .padding(.top, 10)

            Text(userEnv.localizedString("Giriş yapılacak bölgeyi seçin", "Select the region to initialize entry"))
                .font(.setCustomFont(name: .InterMedium, size: 14))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Data
    private var completedWorldCount: Int {
        let wl = max(1, userEnv.unlockedWorldLevel)
        return min(5, max(0, (wl - 1) / 20))
    }

    private var worldCards: [WorldCardViewModel] {
        (1...5).map { wid in
            let paletteTuple = ThemeColors.worldCardPalette(worldId: wid)
            let palette = WorldCardPalette(cardBg: paletteTuple.cardBg, accentColor: paletteTuple.accent)

            let start = (wid - 1) * 20 + 1
            let end = wid * 20
            let unlocked = max(1, userEnv.unlockedWorldLevel)

            let state: WorldState
            if unlocked > end {
                state = .completed
            } else if unlocked >= start {
                state = .active
            } else {
                state = .locked
            }

            let completedLevels: Int = {
                if unlocked <= start { return 0 }
                return min(20, max(0, unlocked - start))
            }()

            return WorldCardViewModel(
                id: wid,
                worldId: wid,
                title: worldTitle(wid),
                levelRange: "LVL \(start)–\(end)",
                twist: worldTwist(wid),
                icon: worldIcon(wid),
                completedLevels: completedLevels,
                totalLevels: 20,
                state: state,
                palette: palette
            )
        }
    }

    private func worldTitle(_ wid: Int) -> String {
        switch wid {
        case 1: return userEnv.localizedString("NEON ÇEKİRDEK", "NEON CORE")
        case 2: return userEnv.localizedString("BETON HARABELER", "CONCRETE RUINS")
        case 3: return userEnv.localizedString("ŞEKER LABORATUVARI", "CANDY LAB")
        case 4: return userEnv.localizedString("DERİN OKYANUS", "DEEP OCEAN")
        default: return userEnv.localizedString("BOŞLUK ÇEKİRDEĞİ", "VOID KERNEL")
        }
    }

    private func worldTwist(_ wid: Int) -> String {
        switch wid {
        case 1: return userEnv.localizedString("Eğitim dünyası · Twist yok", "Tutorial world · No twist")
        case 2: return userEnv.localizedString("Ağırlık: Bloklar daha hızlı düşer", "Weight: Blocks fall faster")
        case 3: return userEnv.localizedString("Yapışkan: Bloklar birbirine bağlanır", "Sticky: Blocks chain together")
        case 4: return userEnv.localizedString("Basınç: Karar verme süresi azalır", "Pressure: Reduced decision time")
        default: return userEnv.localizedString("Boşluk: Gerçeklik katmanları bükülür", "Void: Reality layers distort")
        }
    }

    private func worldIcon(_ wid: Int) -> String {
        switch wid {
        case 1: return "bolt.fill"
        case 2: return "building.2.fill"
        case 3: return "bubbles.and.sparkles.fill"
        case 4: return "drop.fill"
        default: return "cpu.fill"
        }
    }

    private func onWorldCardTap(vm: WorldCardViewModel, index: Int) {
        if index != selectedWorldIndex {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedWorldIndex = index
            }
            return
        }
        
        switch vm.state {
        case .locked:
            HapticManager.shared.play(.selection)
            withAnimation(.easeInOut(duration: 0.08)) {
                shakeWorldId = vm.worldId
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                shakeWorldId = nil
            }
        default:
            HapticManager.shared.play(.selection)
            MainViewsRouter.shared.pushToWorldMap(worldId: vm.worldId, slotId: slotId)
        }
    }
}

// MARK: - Dynamic Background
private struct DynamicBackground: View {
    let palette: WorldCardPalette
    
    var body: some View {
        ZStack {
            ThemeColors.backgroundGradient
            
            // Large ambient glow
            Circle()
                .fill(palette.accentColor.opacity(0.15))
                .blur(radius: 100)
                .offset(x: 100, y: -200)
            
            Circle()
                .fill(palette.accentColor.opacity(0.1))
                .blur(radius: 120)
                .offset(x: -150, y: 300)
            
            // Grid Overlay
            GridPattern()
                .stroke(palette.accentColor.opacity(0.05), lineWidth: 1)
        }
        .animation(.easeInOut(duration: 0.8), value: palette.accentColor)
    }
}

// MARK: - World Card V2
private struct WorldCardV2: View {
    let vm: WorldCardViewModel
    let isFocused: Bool
    let isShaking: Bool
    let onTap: () -> Void

    @State private var pressed: Bool = false

    var body: some View {
        let accent = vm.palette.accentColor
        let cardWidth: CGFloat = 280
        let cardHeight: CGFloat = 420
        
        Button {
            onTap()
        } label: {
            ZStack(alignment: .bottom) {
                // Background & Border
                RoundedRectangle(cornerRadius: 32)
                    .fill(vm.palette.cardBg.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(isFocused ? accent : accent.opacity(0.2), lineWidth: isFocused ? 2 : 1)
                    )
                    .shadow(color: isFocused ? accent.opacity(0.3) : Color.clear, radius: 20)

                // Large background number
                Text("0\(vm.worldId)")
                    .font(.system(size: 140, weight: .black))
                    .foregroundStyle(accent.opacity(0.05))
                    .offset(x: 40, y: -180)

                VStack(alignment: .leading, spacing: 0) {
                    // Top: Icon and Badge
                    HStack {
                        WorldIconViewV2(icon: vm.icon, accent: accent)
                        Spacer()
                        BadgeViewV2(state: vm.state, accent: accent)
                    }
                    .padding(24)

                    Spacer()

                    // Middle: Titles
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.levelRange)
                            .font(.setCustomFont(name: .InterBold, size: 11))
                            .foregroundStyle(accent)
                            .tracking(2)
                        
                        Text(vm.title)
                            .font(.setCustomFont(name: .InterBlack, size: 24))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 24)

                    // Bottom: Progress & Action
                    VStack(alignment: .leading, spacing: 16) {
                        Text(vm.twist)
                            .font(.setCustomFont(name: .InterMedium, size: 12))
                            .foregroundStyle(.white.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: 12) {
                            ProgressBarV2(progress: Double(vm.completedLevels) / Double(max(1, vm.totalLevels)), tint: accent)
                            Text("\(vm.completedLevels)/\(vm.totalLevels)")
                                .font(.setCustomFont(name: .InterBold, size: 10))
                                .foregroundStyle(.white.opacity(0.4))
                        }

                        ActionButtonV2(state: vm.state, accent: accent)
                    }
                    .padding(24)
                }
            }
            .frame(width: cardWidth, height: cardHeight)
            .background(
                // Ambient shadow behind card
                RoundedRectangle(cornerRadius: 32)
                    .fill(accent.opacity(0.05))
                    .blur(radius: 20)
                    .offset(y: 10)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isFocused ? 1.0 : 0.9)
        .opacity(isFocused ? 1.0 : 0.6)
        .offset(x: isShaking ? -4 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isFocused)
        .animation(isShaking ? .easeInOut(duration: 0.08).repeatCount(3, autoreverses: true) : .none, value: isShaking)
        .allowsHitTesting(true)
    }
}

private struct WorldIconViewV2: View {
    let icon: String
    let accent: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.15))
                .frame(width: 56, height: 56)
            
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(accent)
                .shadow(color: accent.opacity(0.5), radius: 5)
        }
    }
}

private struct BadgeViewV2: View {
    let state: WorldState
    let accent: Color

    var body: some View {
        let (bg, fg, text): (Color, Color, String) = {
            switch state {
            case .active:
                return (accent.opacity(0.15), accent, "ACTIVE")
            case .completed:
                return (Color(hex: "#00ff77").opacity(0.15), Color(hex: "#00ff77"), "DONE")
            case .locked:
                return (Color.white.opacity(0.08), Color.white.opacity(0.4), "LOCKED")
            }
        }()

        Text(text)
            .font(.setCustomFont(name: .InterBold, size: 10))
            .foregroundStyle(fg)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(bg)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(fg.opacity(0.2), lineWidth: 1))
    }
}

private struct ProgressBarV2: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.1))
                Capsule()
                    .fill(
                        LinearGradient(colors: [tint, tint.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: geo.size.width * CGFloat(min(1, max(0, progress))))
                    .shadow(color: tint.opacity(0.5), radius: 4)
            }
        }
        .frame(height: 6)
    }
}

private struct ActionButtonV2: View {
    let state: WorldState
    let accent: Color
    @EnvironmentObject var userEnv: UserEnvironment

    var body: some View {
        let (bg, fg, text): (Color, Color, String) = {
            switch state {
            case .active:
                return (accent, Color.white, userEnv.localizedString("SİSTEME GİRİŞ", "INITIALIZE ENTRY"))
            case .completed:
                return (Color.white.opacity(0.1), .white, userEnv.localizedString("TEKRAR BAĞLAN", "RE-CONNECT"))
            case .locked:
                return (Color.white.opacity(0.05), Color.white.opacity(0.3), userEnv.localizedString("ERİŞİM ENGELLENDİ", "ACCESS DENIED"))
            }
        }()

        Text(text)
            .font(.setCustomFont(name: .InterBold, size: 12))
            .foregroundStyle(fg)
            .tracking(1)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: state == .active ? accent.opacity(0.4) : .clear, radius: 10, y: 5)
    }
}

#Preview {
    WorldSelectionView(slotId: 1)
        .environmentObject(UserEnvironment.shared)
}

