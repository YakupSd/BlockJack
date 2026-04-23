//
//  GameHUDComponents.swift
//  Block-Jack
//
//  UI Revize — Game Screen HUD bileşenleri.
//  Sadece View katmanı: ViewModel ve oyun mantığına dokunmaz.
//  Tüm bileşenler kompakt yatay şeritler halinde çalışacak şekilde tasarlandı
//  (bkz. Block-Jack — Game Screen UI Revize Talimatları).
//

import SwiftUI

// MARK: - Layout Constants
enum GameLayout {
    /// Ekranın sol/sağ yatay padding'i (tüm şeritlerde ortak)
    static let horizontalPadding: CGFloat = 14
    /// Bölümler arası dikey boşluk (sıkı — SE'de grid için alan bırakır)
    static let sectionSpacing: CGFloat = 4
    /// Grid ile tray arasındaki boşluk
    static let gridTrayGap: CGFloat = 6
    /// Top HUD yüksekliği (avatar 32 + padding)
    static let topHudHeight: CGFloat = 42
    /// Can + zaman şeridi yüksekliği
    static let lifeTimerStripHeight: CGFloat = 16
    /// Düşman banner yüksekliği
    static let enemyBannerHeight: CGFloat = 42
    /// Overdrive kart yüksekliği
    static let overdriveHeight: CGFloat = 52
    /// Tray yüksekliği (slot 72 + vertical padding 16 + marj)
    static let trayHeight: CGFloat = 88
    /// Perk şeridi yüksekliği
    static let perkStripHeight: CGFloat = 34
    /// Skor satırı yüksekliği
    static let scoreHeight: CGFloat = 32
}

// MARK: - Top HUD Bar (karakter | bölüm | süre)
/// Ekranın en tepesinde, 3 parçalı tek yatay şerit.
/// Sol: karakter rozeti (avatar + ad + zorluk).
/// Orta: chapter + round bilgisi.
/// Sağ: kalan süre — renk süreyle değişir.
struct TopHUDBar: View {
    @ObservedObject var vm: GameViewModel
    @EnvironmentObject var userEnv: UserEnvironment
    
    var body: some View {
        HStack(spacing: 10) {
            // HOME
            Button {
                HapticManager.shared.play(.buttonTap)
                vm.saveGameState()
                MainViewsRouter.shared.popToSlotHub(slotId: vm.activeSlotId)
            } label: {
                Image(systemName: "house.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(ThemeColors.hudBg))
                    .overlay(Circle().stroke(ThemeColors.hudBorder, lineWidth: 1))
            }
            
            // SOL: Karakter rozeti
            characterBadge
            
            Spacer(minLength: 4)
            
            // ORTA: Chapter + Round
            chapterBadge
            
            Spacer(minLength: 4)
            
            // SAĞ: Süre
            timeBadge
            
            // PAUSE
            Button {
                vm.pauseGame()
                HapticManager.shared.play(.buttonTap)
            } label: {
                Image(systemName: "pause.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(ThemeColors.hudBg))
                    .overlay(Circle().stroke(ThemeColors.hudBorder, lineWidth: 1))
            }
        }
        .padding(.horizontal, GameLayout.horizontalPadding)
        .padding(.top, 4)
        .frame(height: GameLayout.topHudHeight + 4)
    }
    
    // MARK: Sol — Karakter
    @ViewBuilder
    private var characterBadge: some View {
        let charId = vm.activeCharacterId
        let char = GameCharacter.roster.first(where: { $0.id == charId })
        
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(ThemeColors.hudBg)
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(ThemeColors.neonCyan.opacity(0.6), lineWidth: 1.2))
                
                if let c = char {
                    Image(c.icon)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeColors.neonCyan)
                }
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(char?.name.uppercased() ?? "PILOT")
                    .font(.setCustomFont(name: .InterBlack, size: 11))
                    .foregroundStyle(ThemeColors.neonCyan)
                    .tracking(1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text(difficultyLabel)
                    .font(.setCustomFont(name: .InterMedium, size: 8))
                    .foregroundStyle(ThemeColors.textMuted)
                    .tracking(1)
                    .lineLimit(1)
            }
        }
        .layoutPriority(1)
    }
    
    private var difficultyLabel: String {
        let charId = vm.activeCharacterId
        guard let diff = GameCharacter.roster.first(where: { $0.id == charId })?.difficulty else {
            return userEnv.localizedString("Pilot", "Pilot")
        }
        switch diff {
        case .beginner:
            return userEnv.localizedString("Acemi", "Beginner")
        case .advanced:
            return userEnv.localizedString("İleri", "Advanced")
        case .expert:
            return userEnv.localizedString("Uzman", "Expert")
        }
    }
    
    // MARK: Orta — Chapter
    @ViewBuilder
    private var chapterBadge: some View {
        VStack(spacing: 1) {
            Text(String(format: userEnv.localizedString("BÖLÜM %d", "CHAPTER %d"), vm.run.worldLevel))
                .font(.setCustomFont(name: .InterBold, size: 9))
                .foregroundStyle(ThemeColors.textMuted)
                .tracking(1.4)
                .lineLimit(1)
            
            Text(String(format: userEnv.localizedString("Tur %d", "Round %d"), vm.run.currentRound))
                .font(.setCustomFont(name: .InterBlack, size: 13))
                .foregroundStyle(.white)
                .lineLimit(1)
                .monospacedDigit()
        }
        .fixedSize(horizontal: true, vertical: false)
    }
    
    // MARK: Sağ — Süre
    @ViewBuilder
    private var timeBadge: some View {
        let ratio = vm.timer.ratio
        let color: Color = {
            if ratio < 0.2 { return ThemeColors.neonPink }
            if ratio < 0.45 { return ThemeColors.electricYellow }
            return .white
        }()
        
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(0.6), radius: 3)
                .phaseAnimator([0.4, 1.0]) { c, o in
                    c.opacity(ratio < 0.3 ? o : 1.0)
                } animation: { _ in
                    .easeInOut(duration: 0.45).repeatForever(autoreverses: true)
                }
            
            Text("\(Int(max(0, vm.timer.timeRemaining)))s")
                .font(.setCustomFont(name: .InterBlack, size: 13))
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .monospacedDigit()
                .frame(minWidth: 30, alignment: .trailing)
                .lineLimit(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(ThemeColors.hudBg)
        )
        .overlay(
            Capsule().stroke(color.opacity(0.35), lineWidth: 1)
        )
    }
}

// MARK: - Life & Timer Strip (tek ince şerit)
/// Sol: can kalpleri. Sağ: zaman progress barı.
/// Top HUD'un hemen altında, göz kaymadan bakılabilen tek sıra.
struct LifeAndTimerStrip: View {
    @ObservedObject var vm: GameViewModel
    
    var body: some View {
        HStack(spacing: 10) {
            // Kalpler
            HStack(spacing: 3) {
                ForEach(1...vm.run.maxLives, id: \.self) { i in
                    Image(systemName: i <= vm.run.lives ? "heart.fill" : "heart")
                        .font(.system(size: 10))
                        .foregroundStyle(i <= vm.run.lives ? ThemeColors.neonPink : ThemeColors.gridStroke)
                        .scaleEffect(i == vm.run.lives && vm.run.lives <= 2 ? 1.15 : 1.0)
                        .animation(.spring(response: 0.3), value: vm.run.lives)
                }
            }
            
            // Zaman barı
            TimerBarView(
                ratio: vm.timer.ratio,
                isFogMode: vm.run.round.modifier == .fog
            )
            .frame(height: 6)
        }
        .padding(.horizontal, GameLayout.horizontalPadding)
        .frame(height: GameLayout.lifeTimerStripHeight)
    }
}

// MARK: - Modifier Counter Tip
/// Aktif modifier varsa kısa öneri pill'i.
struct ModifierCounterTipPill: View {
    @ObservedObject var vm: GameViewModel
    @EnvironmentObject var userEnv: UserEnvironment

    var body: some View {
        guard let mod = vm.run.activeModifier else { return AnyView(EmptyView()) }
        let recId = mod.recommendedCharacterId
        let recName = GameCharacter.roster.first(where: { $0.id == recId })?.name ?? "?"
        let text = userEnv.localizedString(mod.counterTipTR(recommendedName: recName), mod.counterTipEN(recommendedName: recName))

        return AnyView(
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ThemeColors.electricYellow)
                Text(text)
                    .font(.setCustomFont(name: .InterBold, size: 10))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(ThemeColors.hudBg))
            .overlay(Capsule().stroke(ThemeColors.electricYellow.opacity(0.35), lineWidth: 1))
            .padding(.horizontal, GameLayout.horizontalPadding)
        )
    }
}

// MARK: - Boss Intent Pill
/// Boss savaşlarında tetiklenen "saldırı uyarısı" pill'i.
struct BossIntentPill: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
                .foregroundStyle(ThemeColors.neonPink)
            
            Text(text)
                .font(.setCustomFont(name: .InterBlack, size: 10))
                .foregroundStyle(.white)
                .tracking(1)
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
                .foregroundStyle(ThemeColors.neonPink)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(ThemeColors.neonPink.opacity(0.15))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(ThemeColors.neonPink.opacity(0.4), lineWidth: 1))
        .phaseAnimator([0.6, 1.0]) { content, opacity in
            content.opacity(opacity)
        } animation: { _ in
            .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
        }
    }
}
