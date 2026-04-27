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
    @State private var hasAutoNavigated = false  // tek seferlik auto-skip guard
    @State private var shakeWorldId: Int? = nil

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    header
                        .padding(.horizontal, 16)
                        .padding(.top, 14)

                    ForEach(Array(worldCards.enumerated()), id: \.element.id) { idx, vm in
                        WorldCard(
                            vm: vm,
                            isShaking: shakeWorldId == vm.worldId,
                            onTap: { onWorldCardTap(vm: vm) }
                        )
                        .opacity(didAppear ? 1 : 0)
                        .offset(y: didAppear ? 0 : 14)
                        .animation(.easeOut(duration: 0.30).delay(Double(idx) * 0.05), value: didAppear)
                    }
                }
                .padding(.bottom, 28)
            }
            .background(ThemeColors.backgroundGradient.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                didAppear = true
                // TODO 5: Sadece 1 world açıksa (yeni oyuncu) ekran gösterme,
                // direkt o world'e git.
                // hasAutoNavigated flag'i sayesinde WorldMap'ten geri dönüldüğünde
                // bu blok tekrar çalışmaz → sonsuz döngü önlenir.
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Button {
                    HapticManager.shared.play(.buttonTap)
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(ThemeColors.gridDark)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(ThemeColors.gridStroke, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Spacer()
            }

            Text("BLOCK JACK")
                .font(.setCustomFont(name: .InterBlack, size: 20))
                .foregroundStyle(.white)
                .tracking(2)

            Text(userEnv.localizedString("DÜNYA SEÇİMİ · 5 DÜNYA", "WORLD SELECT · 5 WORLDS"))
                .font(.setCustomFont(name: .InterMedium, size: 11))
                .foregroundStyle(Color(hex: "#8888aa"))
                .tracking(1)

            HStack(spacing: 8) {
                let completedWorlds = completedWorldCount
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < completedWorlds ? ThemeColors.neonCyan : ThemeColors.gridDark)
                        .frame(width: 8, height: 8)
                        .rotationEffect(.degrees(45))
                }
                Spacer()
            }
            .padding(.top, 2)
        }
    }

    // MARK: - Data
    private var completedWorldCount: Int {
        // completed world count: unlockedLevel > worldEnd
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
        case 1: return "NEON CORE"
        case 2: return "CONCRETE RUINS"
        case 3: return "CANDY LAB"
        case 4: return "DEEP OCEAN"
        default: return "VOID KERNEL"
        }
    }

    private func worldTwist(_ wid: Int) -> String {
        switch wid {
        case 1:
            return userEnv.localizedString("Eğitim dünyası · Twist yok", "Tutorial world · No twist")
        case 2:
            return userEnv.localizedString("Twist: Ağırlık · Bloklar düşer", "Twist: Weight · Blocks fall")
        case 3:
            return userEnv.localizedString("Twist: Yapışkan · Renk zincirleri", "Twist: Sticky · Color chains")
        case 4:
            return userEnv.localizedString("Twist: Basınç · Daha kısa süre", "Twist: Pressure · Shorter timers")
        default:
            return userEnv.localizedString("Twist: Boşluk · Gerçeklik bükülür", "Twist: Void · Reality bends")
        }
    }

    private func worldIcon(_ wid: Int) -> String {
        switch wid {
        case 1: return "bolt.fill"
        case 2: return "building.2.fill"
        case 3: return "sparkles"
        case 4: return "drop.fill"
        default: return "circle.hexagongrid.fill"
        }
    }

    // MARK: - Navigation
    private func onWorldCardTap(vm: WorldCardViewModel) {
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

// MARK: - World Card
private struct WorldCard: View {
    let vm: WorldCardViewModel
    let isShaking: Bool
    let onTap: () -> Void

    @EnvironmentObject var userEnv: UserEnvironment
    @State private var pressed: Bool = false

    var body: some View {
        let accent = vm.palette.accentColor
        let scale: CGFloat = pressed ? 0.97 : 1.0

        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    WorldIconView(icon: vm.icon, accent: accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("WORLD \(vm.worldId) · \(vm.levelRange)")
                            .font(.setCustomFont(name: .InterBold, size: 10))
                            .foregroundStyle(accent)
                            .tracking(1.5)
                        Text(vm.title)
                            .font(.setCustomFont(name: .InterSemiBold, size: 14))
                            .foregroundStyle(.white)
                    }

                    Spacer(minLength: 0)

                    BadgeView(state: vm.state, accent: accent)
                }

                Text(vm.twist)
                    .font(.setCustomFont(name: .InterMedium, size: 10))
                    .foregroundStyle(accent.opacity(0.55))

                if let hint = upcomingHintText(worldId: vm.worldId) {
                    Text(hint)
                        .font(.setCustomFont(name: .InterBold, size: 10))
                        .foregroundStyle(accent.opacity(0.85))
                        .tracking(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(accent.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(accent.opacity(0.25), lineWidth: 1))
                }

                HStack(spacing: 10) {
                    ProgressBar(progress: Double(vm.completedLevels) / Double(max(1, vm.totalLevels)), tint: accent)
                    Text("\(vm.completedLevels) / \(vm.totalLevels)")
                        .font(.setCustomFont(name: .InterMedium, size: 10))
                        .foregroundStyle(Color(hex: "#8888aa"))
                }

                ActionButton(state: vm.state, accent: accent)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(vm.palette.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(accent.opacity(0.27), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .scaleEffect(scale)
        .offset(x: isShaking ? -4 : 0)
        .animation(isShaking ? .easeInOut(duration: 0.08).repeatCount(3, autoreverses: true) : .spring(response: 0.4, dampingFraction: 0.7), value: isShaking)
        .onLongPressGesture(minimumDuration: 0.01, pressing: { isPressing in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                pressed = isPressing && vm.state != .locked
            }
        }, perform: {})
        .allowsHitTesting(true)
        .opacity(vm.state == .locked ? 0.55 : 1.0)
    }

    private func upcomingHintText(worldId: Int) -> String? {
        switch worldId {
        case 2:
            return userEnv.localizedString("UPCOMING: WEIGHT → TITAN", "UPCOMING: WEIGHT → TITAN")
        case 3:
            return userEnv.localizedString("UPCOMING: FOG → TIME BENDER", "UPCOMING: FOG → TIME BENDER")
        case 4:
            return userEnv.localizedString("UPCOMING: PRESSURE → NEON WRAITH", "UPCOMING: PRESSURE → NEON WRAITH")
        case 5:
            return userEnv.localizedString("UPCOMING: VOID → GHOST", "UPCOMING: VOID → GHOST")
        default:
            return nil
        }
    }
}

private struct WorldIconView: View {
    let icon: String
    let accent: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(accent.opacity(0.12))
            .frame(width: 36, height: 36)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(accent)
            )
    }
}

private struct BadgeView: View {
    let state: WorldState
    let accent: Color

    var body: some View {
        let (bg, fg, text): (Color, Color, String) = {
            switch state {
            case .active:
                return (accent.opacity(0.12), accent, "ACTIVE")
            case .completed:
                return (Color(hex: "#00ff77").opacity(0.12), Color(hex: "#00ff77"), "DONE")
            case .locked:
                return (Color.white.opacity(0.06), Color(hex: "#555577"), "LOCKED")
            }
        }()

        Text(text)
            .font(.setCustomFont(name: .InterBold, size: 10))
            .foregroundStyle(fg)
            .tracking(0.5)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct ProgressBar: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.06))
                Capsule()
                    .fill(tint)
                    .frame(width: geo.size.width * CGFloat(min(1, max(0, progress))))
            }
        }
        .frame(height: 4)
    }
}

private struct ActionButton: View {
    let state: WorldState
    let accent: Color
    @EnvironmentObject var userEnv: UserEnvironment

    var body: some View {
        let (bg, fg, text): (Color, Color, String) = {
            switch state {
            case .active:
                return (accent.opacity(0.12), accent, userEnv.localizedString("DEVAM ET", "CONTINUE"))
            case .completed:
                return (Color(hex: "#00ff77").opacity(0.12), Color(hex: "#00ff77"), userEnv.localizedString("TEKRAR OYNA", "REPLAY"))
            case .locked:
                return (ThemeColors.gridDark, Color(hex: "#44445A"), userEnv.localizedString("🔒 Bir önceki dünyayı bitir", "🔒 Finish the previous world"))
            }
        }()

        Text(text)
            .font(.setCustomFont(name: .InterMedium, size: 12))
            .foregroundStyle(fg)
            .tracking(1)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    WorldSelectionView(slotId: 1)
        .environmentObject(UserEnvironment.shared)
}

