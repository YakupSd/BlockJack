//
//  WorldMapDetailSheet.swift
//  Block-Jack
//

import SwiftUI

// MARK: - Detail Sheet
struct WorldMapDetailSheet: View {
    let slotId: Int
    let level: WorldLevel
    let onEnter: () -> Void
    let onDismiss: () -> Void

    @EnvironmentObject var userEnv: UserEnvironment

    var body: some View {
        ZStack {
            ThemeColors.mapBg.ignoresSafeArea()
            
            // Background ambient glow
            Circle()
                .fill(nodeHeaderBorder.opacity(0.12))
                .blur(radius: 80)
                .offset(y: -150)

            VStack(spacing: 0) {
                // Drag Indicator area
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 40, height: 4)
                    .padding(.top, 10)
                
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.vertical, 20)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        if level.type == .boss {
                            WorldSheetBossContent(slotId: slotId, level: level)
                        } else {
                            WorldSheetBattleContent(level: level)
                        }
                        
                        if let hint = modifierHintText {
                            hintView(hint)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }

                Spacer()

                WorldSheetActionButtonV2(level: level, onEnter: onEnter)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34)
            }
        }
    }

    // MARK: Header
    private var header: some View {
        HStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(nodeHeaderBorder.opacity(0.1))
                    .frame(width: 72, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(nodeHeaderBorder.opacity(0.4), lineWidth: 2)
                    )
                
                Image(systemName: level.type == .boss ? "skull.fill" : "cpu.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(nodeHeaderBorder)
                    .shadow(color: nodeHeaderBorder.opacity(0.6), radius: 10)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Text(typeBadgeText)
                        .font(.setCustomFont(name: .InterBold, size: 10))
                        .foregroundColor(nodeHeaderBorder)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(nodeHeaderBorder.opacity(0.15))
                        .clipShape(Capsule())
                    
                    difficultyStarsView
                }

                Text(title)
                    .font(.setCustomFont(name: .InterBlack, size: 26))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer()
        }
    }

    private var difficultyStarsView: some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { i in
                Circle()
                    .fill(i < difficultyStars ? ThemeColors.neonCyan : Color.white.opacity(0.1))
                    .frame(width: 7, height: 7)
            }
        }
    }

    private func hintView(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(ThemeColors.electricYellow)
                .font(.system(size: 14))
            Text(text)
                .font(.setCustomFont(name: .InterMedium, size: 13))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private var title: String {
        if level.type == .boss {
            return BossRegistry.shared.getBoss(for: level.id).name
        }
        return userEnv.formatSectorIndex(index: level.id)
    }

    private var typeBadgeText: String {
        switch (level.type, level.status) {
        case (.boss, _):
            return userEnv.labelCriticalTargetCaps
        case (_, .completed):
            return userEnv.labelDataPurgedCaps
        case (_, .locked):
            return userEnv.labelAccessDeniedCaps
        case (_, .available):
            return userEnv.labelActiveSignalCaps
        }
    }

    private var difficultyStars: Int {
        let base = max(1, min(5, (level.id + 3) / 4))
        return level.type == .boss ? min(5, base + 1) : base
    }

    private var modifierHintText: String? {
        let bucket = (level.id / 5) % 4
        return userEnv.formatModifierHint(bucket: bucket)
    }

    private var nodeHeaderBorder: Color {
        if level.type == .boss { return ThemeColors.nodeBoss }
        switch level.status {
        case .completed: return ThemeColors.nodeCompleted
        case .available: return ThemeColors.nodeCurrent
        case .locked:    return ThemeColors.nodeLocked
        }
    }
}

// MARK: - Normal Battle Content
struct WorldSheetBattleContent: View {
    let level: WorldLevel
    @EnvironmentObject var userEnv: UserEnvironment

    var body: some View {
        VStack(spacing: 24) {
            // Target Info
            VStack(alignment: .leading, spacing: 12) {
                Text(userEnv.labelEnemyAnalysisCaps)
                    .font(.setCustomFont(name: .InterBold, size: 10))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)

                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 64, height: 64)
                        Text(enemyEmoji)
                            .font(.system(size: 36))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(enemyName)
                            .font(.setCustomFont(name: .InterBold, size: 18))
                            .foregroundColor(ThemeColors.neonCyan)
                        Text(enemyIntent)
                            .font(.setCustomFont(name: .InterMedium, size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            // Rewards
            VStack(alignment: .leading, spacing: 14) {
                Text(userEnv.labelPotentialRewardsCaps)
                    .font(.setCustomFont(name: .InterBold, size: 10))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)
                
                HStack(spacing: 12) {
                    WorldRewardPillV3(icon: "star.fill", label: "SCORE", value: "\(estimatedScore)", color: ThemeColors.neonCyan)
                    WorldRewardPillV3(icon: "bitcoinsign.circle.fill", label: "GOLD", value: "\(estimatedGold)", color: ThemeColors.electricYellow)
                }
            }
        }
    }

    private var enemyEmoji: String {
        switch level.id {
        case 0...3:   return "🤖"
        case 4...7:   return "👾"
        case 8...11:  return "🛸"
        case 12...15: return "💀"
        default:      return "⚡"
        }
    }

    private var enemyName: String {
        let tr = ["VERİ BEKÇİSİ", "GLITCH PROBU", "SİBER AVCI", "NEON GLADIATÖR"]
        let en = ["DATA WARDEN", "GLITCH PROBE", "CYBER HUNTER", "NEON GLADIATOR"]
        let idx = abs(level.id - 1) % tr.count
        return userEnv.language == .turkish ? tr[idx] : en[idx]
    }

    private var enemyIntent: String {
        let tr = ["Gridini kilitleyecek.", "Hamle başına 2 saniye çalar.", "Blokları rastgele döndürür."]
        let en = ["Will lock your grid.", "Steals 2s per move.", "Spins blocks randomly."]
        let idx = (level.id * 7) % tr.count
        return userEnv.language == .turkish ? tr[idx] : en[idx]
    }

    private var estimatedScore: Int { 400 + level.id * 75 }
    private var estimatedGold: Int { 25 + level.id * 8 }
}

// MARK: - Boss Content
struct WorldSheetBossContent: View {
    let slotId: Int
    let level: WorldLevel
    @EnvironmentObject var userEnv: UserEnvironment
    @State private var warningPulse = false
    @State private var bossIntent: String = ""
    @State private var selectedContract: BossContract = .safe

    private var boss: BossEncounter {
        BossRegistry.shared.getBoss(for: level.id)
    }

    var body: some View {
        VStack(spacing: 28) {
            // Boss Identity
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(ThemeColors.neonPink.opacity(0.3), lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .scaleEffect(warningPulse ? 1.15 : 1.0)
                        .opacity(warningPulse ? 0 : 1)
                    
                    Image(boss.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(ThemeColors.neonPink, lineWidth: 2))
                        .shadow(color: ThemeColors.neonPink.opacity(0.4), radius: 15)
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                        warningPulse = true
                    }
                }

                VStack(spacing: 6) {
                    Text(userEnv.labelCriticalThreatDetectedCaps)
                        .font(.setCustomFont(name: .InterBold, size: 12))
                        .foregroundColor(ThemeColors.neonPink)
                        .tracking(2)
                    
                    Text(bossIntent.isEmpty ? boss.getRandomIntent() : bossIntent)
                        .font(.setCustomFont(name: .InterMedium, size: 15))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .background(ThemeColors.neonPink.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(ThemeColors.neonPink.opacity(0.2), lineWidth: 1))
            
            // Risk Analysis
            VStack(alignment: .leading, spacing: 12) {
                Text(userEnv.labelRiskAnalysisRewardsCaps)
                    .font(.setCustomFont(name: .InterBold, size: 10))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)
                
                HStack(spacing: 12) {
                    riskInfoCard(
                        title: userEnv.labelSafeCaps,
                        desc: userEnv.labelStandardDifficulty,
                        reward: "+0%",
                        color: ThemeColors.neonCyan,
                        isSelected: selectedContract == .safe,
                        onTap: { selectContract(.safe) }
                    )
                    
                    riskInfoCard(
                        title: userEnv.labelRiskyCaps,
                        desc: userEnv.labelRiskyHPModifier,
                        reward: "+50% GOLD",
                        color: ThemeColors.neonPink,
                        isSelected: selectedContract == .risky,
                        onTap: { selectContract(.risky) }
                    )
                }
            }
        }
        .onAppear {
            if bossIntent.isEmpty { bossIntent = boss.getRandomIntent() }
            let saved = SaveManager.shared.slots.first(where: { $0.id == slotId })?.activeBossContractId ?? BossContract.safe.rawValue
            selectedContract = BossContract(rawValue: saved) ?? .safe
        }
    }

    private func riskInfoCard(title: String, desc: String, reward: String, color: Color, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.setCustomFont(name: .InterBlack, size: 14))
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                    }
                }
                
                Text(desc)
                    .font(.setCustomFont(name: .InterMedium, size: 10))
                    .opacity(0.7)
                
                Text(reward)
                    .font(.setCustomFont(name: .InterBold, size: 12))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .clipShape(Capsule())
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? color : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(isSelected ? color : Color.white.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
    
    private func selectContract(_ c: BossContract) {
        HapticManager.shared.play(.selection)
        selectedContract = c
        SaveManager.shared.setBossContract(slotId: slotId, contractId: c.rawValue)
    }
}

// MARK: - Reward Pill
struct WorldRewardPillV3: View {
    let icon: String
    let label: String
    let value: String
    var color: Color = .white

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.setCustomFont(name: .InterBold, size: 9))
                    .foregroundColor(.white.opacity(0.4))
                Text(value)
                    .font(.setCustomFont(name: .InterBold, size: 16))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
}

// MARK: - Action Button
struct WorldSheetActionButtonV2: View {
    let level: WorldLevel
    let onEnter: () -> Void
    @EnvironmentObject var userEnv: UserEnvironment

    var body: some View {
        Button(action: onEnter) {
            let isAvailable = level.status != .locked
            let accent = level.type == .boss ? ThemeColors.neonPink : ThemeColors.neonCyan
            
            Text(label.uppercased())
                .font(.setCustomFont(name: .InterBlack, size: 15))
                .tracking(2)
                .foregroundColor(isAvailable ? .black : .white.opacity(0.2))
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(isAvailable ? accent : Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: isAvailable ? accent.opacity(0.5) : .clear, radius: 15, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(level.status == .locked)
    }

    private var label: String {
        switch (level.type, level.status) {
        case (_, .locked):     return userEnv.btnAccessRestrictedCaps
        case (.boss, _):       return userEnv.btnInitializeLinkCapsV2
        case (_, .completed):  return userEnv.btnReConnectCaps
        case (_, .available):  return userEnv.btnInitializeEntryCaps
        }
    }
}

enum BossContract: String, Codable {
    case safe
    case risky

    var color: Color {
        switch self {
        case .safe: return ThemeColors.neonCyan
        case .risky: return ThemeColors.neonPink
        }
    }
}
