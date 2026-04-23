//
//  RunSetupView.swift
//  Block-Jack
//

import SwiftUI

/// Pre-run tek ekran: slot + karakter + starting perk + world seçimi.
struct RunSetupView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @StateObject private var saveManager = SaveManager.shared
    @Environment(\.dismiss) private var dismiss

    let slotId: Int

    @State private var selectedWorldId: Int = 1
    @State private var selectedCharacterId: String = "block_e"
    @State private var selectedPerkId: String = "none"
    @State private var selectedStartingItemId: String = ""

    private var slot: SaveSlot? { saveManager.slots.first(where: { $0.id == slotId }) }

    var body: some View {
        ZStack {
            ThemeColors.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 16) {
                header

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 14) {
                        worldPicker
                        characterPicker
                        perkPicker
                        startingItemPicker
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }

                Spacer(minLength: 0)
            }

            VStack {
                Spacer()
                startButton
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if let s = slot, !s.isEmpty {
                userEnv.loadFromSlot(s)
                selectedCharacterId = s.characterId ?? userEnv.selectedCharacterID
                selectedPerkId = s.selectedPerkId ?? "none"
                selectedWorldId = ChapterProgression.world(for: max(1, s.unlockedWorldLevel))
            } else {
                selectedCharacterId = userEnv.selectedCharacterID
            }
            selectedStartingItemId = userEnv.runConfig?.startingItemId ?? ""
        }
    }

    private var header: some View {
        HStack {
            Button {
                HapticManager.shared.play(.buttonTap)
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ThemeColors.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(ThemeColors.surfaceDark)
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text(userEnv.localizedString("SEFER KURULUMU", "RUN SETUP"))
                    .font(.setCustomFont(name: .InterBlack, size: 18))
                    .foregroundStyle(ThemeColors.electricYellow)
                    .tracking(2)
                Text(userEnv.localizedString("Slot, karakter, perk ve dünya seç", "Choose slot, character, perk and world"))
                    .font(.setCustomFont(name: .InterMedium, size: 10))
                    .foregroundStyle(ThemeColors.textMuted)
            }

            Spacer()

            Text(userEnv.localizedString("SLOT \(slotId)", "SLOT \(slotId)"))
                .font(.setCustomFont(name: .InterBold, size: 11))
                .foregroundStyle(ThemeColors.neonCyan)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(ThemeColors.surfaceDark)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(ThemeColors.gridStroke.opacity(0.4), lineWidth: 1))
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private var worldPicker: some View {
        let cards = (1...5).map { wid -> WorldCardViewModel in
            let paletteTuple = ThemeColors.worldCardPalette(worldId: wid)
            let palette = WorldCardPalette(cardBg: paletteTuple.cardBg, accentColor: paletteTuple.accent)
            let start = (wid - 1) * 20 + 1
            let end = wid * 20
            let unlocked = max(1, userEnv.unlockedWorldLevel)

            let state: WorldState
            if unlocked > end { state = .completed }
            else if unlocked >= start { state = .active }
            else { state = .locked }

            let completedLevels = unlocked <= start ? 0 : min(20, max(0, unlocked - start))

            return WorldCardViewModel(
                id: wid,
                worldId: wid,
                title: ["NEON CORE", "CONCRETE RUINS", "CANDY LAB", "DEEP OCEAN", "VOID KERNEL"][wid - 1],
                levelRange: "LVL \(start)–\(end)",
                twist: userEnv.localizedString("Dünya \(wid)", "World \(wid)"),
                icon: "globe",
                completedLevels: completedLevels,
                totalLevels: 20,
                state: state,
                palette: palette
            )
        }

        return VStack(alignment: .leading, spacing: 10) {
            Text(userEnv.localizedString("DÜNYA", "WORLD"))
                .font(.setCustomFont(name: .InterBlack, size: 12))
                .tracking(2)
                .foregroundStyle(ThemeColors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(cards) { card in
                        let isSelected = selectedWorldId == card.worldId
                        Button {
                            guard card.state != .locked else {
                                HapticManager.shared.play(.error)
                                return
                            }
                            HapticManager.shared.play(.selection)
                            selectedWorldId = card.worldId
                        } label: {
                            HStack(spacing: 10) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(card.palette.accentColor.opacity(0.15))
                                    .frame(width: 34, height: 34)
                                    .overlay(
                                        Text("\(card.worldId)")
                                            .font(.setCustomFont(name: .InterBlack, size: 14))
                                            .foregroundStyle(card.palette.accentColor)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("WORLD \(card.worldId)")
                                        .font(.setCustomFont(name: .InterBold, size: 11))
                                        .foregroundStyle(.white)
                                    Text(card.levelRange)
                                        .font(.setCustomFont(name: .InterMedium, size: 9))
                                        .foregroundStyle(ThemeColors.textMuted)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(12)
                            .frame(width: 210)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(card.palette.cardBg)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(isSelected ? card.palette.accentColor : card.palette.accentColor.opacity(0.27), lineWidth: isSelected ? 2 : 1)
                                    )
                            )
                            .opacity(card.state == .locked ? 0.55 : 1.0)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .background(ThemeColors.surfaceDark.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(ThemeColors.gridStroke.opacity(0.35), lineWidth: 1))
    }

    private var characterPicker: some View {
        let roster = GameCharacter.roster
        return VStack(alignment: .leading, spacing: 10) {
            Text(userEnv.localizedString("KARAKTER", "CHARACTER"))
                .font(.setCustomFont(name: .InterBlack, size: 12))
                .tracking(2)
                .foregroundStyle(ThemeColors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(roster) { c in
                        let isSelected = selectedCharacterId == c.id
                        let isUnlocked = !c.isPremium || userEnv.unlockedCharacterIDs.contains(c.id)
                        Button {
                            HapticManager.shared.play(.selection)
                            selectedCharacterId = c.id
                        } label: {
                            VStack(spacing: 8) {
                                Image(c.icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .grayscale(isUnlocked ? 0 : 1)
                                    .opacity(isUnlocked ? 1 : 0.4)

                                Text(c.name)
                                    .font(.setCustomFont(name: .InterBold, size: 10))
                                    .foregroundStyle(isSelected ? ThemeColors.neonCyan : ThemeColors.textMuted)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .padding(10)
                            .frame(width: 90)
                            .background(ThemeColors.surfaceDark.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(isSelected ? ThemeColors.neonCyan.opacity(0.6) : ThemeColors.gridStroke.opacity(0.35), lineWidth: isSelected ? 2 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .background(ThemeColors.surfaceDark.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(ThemeColors.gridStroke.opacity(0.35), lineWidth: 1))
    }

    private var perkPicker: some View {
        return VStack(alignment: .leading, spacing: 10) {
            Text(userEnv.localizedString("STARTING PERK", "STARTING PERK"))
                .font(.setCustomFont(name: .InterBlack, size: 12))
                .tracking(2)
                .foregroundStyle(ThemeColors.textSecondary)

            VStack(spacing: 10) {
                ForEach(StartingPerk.available) { p in
                    let isSelected = selectedPerkId == p.id
                    Button {
                        HapticManager.shared.play(.selection)
                        selectedPerkId = p.id
                    } label: {
                        HStack(spacing: 12) {
                            if p.icon.hasPrefix("item_") {
                                Image(p.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 26, height: 26)
                            } else {
                                Text(p.icon).font(.system(size: 18))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(userEnv.localizedString(p.nameTR, p.nameEN))
                                    .font(.setCustomFont(name: .InterBold, size: 12))
                                    .foregroundStyle(.white)
                                Text(userEnv.localizedString(p.descTR, p.descEN))
                                    .font(.setCustomFont(name: .InterMedium, size: 10))
                                    .foregroundStyle(ThemeColors.textMuted)
                                    .lineLimit(2)
                            }
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(ThemeColors.electricYellow)
                            }
                        }
                        .padding(12)
                        .background(ThemeColors.surfaceDark.opacity(isSelected ? 0.9 : 0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? ThemeColors.electricYellow.opacity(0.6) : ThemeColors.gridStroke.opacity(0.25), lineWidth: isSelected ? 2 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(ThemeColors.surfaceDark.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(ThemeColors.gridStroke.opacity(0.35), lineWidth: 1))
    }

    private var startingItemPicker: some View {
        let items: [(id: String, tr: String, en: String, icon: String, descTR: String, descEN: String)] = [
            ("", "Yok", "None", "🚫", "Bonus yok.", "No bonus."),
            ("life_plus1", "+1 Can", "+1 Life", "❤️", "Run başında +1 can.", "+1 life at run start."),
            ("time_plus30", "+30sn", "+30s", "⏱️", "Run başında +30 saniye.", "+30 seconds at run start."),
            ("overdrive_50", "Overdrive %50", "Overdrive 50%", "⚡", "Run başında overdrive %50.", "Start with 50% overdrive."),
            ("bomb_block", "1 Bomb Block", "1 Bomb Block", "💣", "İlk tepside 1 bomb blok.", "First tray includes 1 bomb block.")
        ]

        return VStack(alignment: .leading, spacing: 10) {
            Text(userEnv.localizedString("STARTING ITEM", "STARTING ITEM"))
                .font(.setCustomFont(name: .InterBlack, size: 12))
                .tracking(2)
                .foregroundStyle(ThemeColors.textSecondary)

            VStack(spacing: 10) {
                ForEach(items, id: \.id) { it in
                    let isSelected = selectedStartingItemId == it.id
                    Button {
                        HapticManager.shared.play(.selection)
                        selectedStartingItemId = it.id
                    } label: {
                        HStack(spacing: 12) {
                            Text(it.icon).font(.system(size: 18))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(userEnv.localizedString(it.tr, it.en))
                                    .font(.setCustomFont(name: .InterBold, size: 12))
                                    .foregroundStyle(.white)
                                Text(userEnv.localizedString(it.descTR, it.descEN))
                                    .font(.setCustomFont(name: .InterMedium, size: 10))
                                    .foregroundStyle(ThemeColors.textMuted)
                                    .lineLimit(2)
                            }
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(ThemeColors.electricYellow)
                            }
                        }
                        .padding(12)
                        .background(ThemeColors.surfaceDark.opacity(isSelected ? 0.9 : 0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? ThemeColors.electricYellow.opacity(0.6) : ThemeColors.gridStroke.opacity(0.25), lineWidth: isSelected ? 2 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(ThemeColors.surfaceDark.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(ThemeColors.gridStroke.opacity(0.35), lineWidth: 1))
    }

    private var startButton: some View {
        Button {
            HapticManager.shared.play(.heavy)

            // Slot yoksa oluştur
            if slot?.isEmpty != false {
                SaveManager.shared.createNewSave(in: slotId, characterId: selectedCharacterId, perkId: selectedPerkId)
            } else {
                SaveManager.shared.setCharacter(slotId: slotId, characterID: selectedCharacterId)
                SaveManager.shared.setStartingPerk(slotId: slotId, perkId: selectedPerkId)
            }

            if let s = SaveManager.shared.slots.first(where: { $0.id == slotId }) {
                userEnv.loadFromSlot(s)
            }

            userEnv.setRunConfig(RunConfig(
                slotId: slotId,
                characterId: selectedCharacterId,
                startingPerkId: selectedPerkId,
                worldId: selectedWorldId,
                startingItemId: selectedStartingItemId.isEmpty ? nil : selectedStartingItemId
            ))

            MainViewsRouter.shared.push(
                WorldSelectionView(slotId: slotId).environmentObject(UserEnvironment.shared)
            )
        } label: {
            Text(userEnv.localizedString("DÜNYA SEÇ", "SELECT WORLD"))
                .font(.setCustomFont(name: .InterExtraBold, size: 20))
                .tracking(4)
                .foregroundStyle(ThemeColors.cosmicBlack)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(ThemeColors.electricYellow)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: ThemeColors.electricYellow.opacity(0.55), radius: 16)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.bottom, 26)
    }
}

#Preview {
    RunSetupView(slotId: 1).environmentObject(UserEnvironment.shared)
}

