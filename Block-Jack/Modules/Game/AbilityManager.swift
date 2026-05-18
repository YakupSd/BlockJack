//
//  AbilityManager.swift
//  Block-Jack
//
//  Orchestrator Pattern: Ability/Overdrive/Perk logic extracted from GameViewModel.
//  Handles: Overdrive activation, targeted overdrive, character passives loop,
//  phantom pulse, meta perk injection, synergy management, and consumable usage.
//

import Foundation
import SwiftUI
import Combine

final class AbilityManager {

    // MARK: - Back-Reference
    unowned let vm: GameViewModel

    // MARK: - Init
    init(vm: GameViewModel) {
        self.vm = vm
    }

    // MARK: - Overdrive Mechanics

    func activateOverdrive() {
        guard let charId = vm.activeCharacterId else { return }
        let tier = vm.currentOverdriveTier
        guard tier != .none else { return }
        
        // Store tier for targeting characters before resetting
        if charId == "block_e" || charId == "architect" {
            vm.activeOverdriveTierForTargeting = tier
            // Hedefli karakterlerde şarjı drop sonrası tüketeceğiz (stabil kullanım).
            vm.pendingTargetedOverdriveConsumption = true
        }
        
        OverdriveEngine.execute(tier: tier, charId: charId, vm: vm)
        
        // Şarjı tüket
        // - Hedefli (Architect/BLOCK-E): drop sonrası tüketilir.
        // - Diğerleri: anında tüketilir.
        if !(charId == "block_e" || charId == "architect") {
            vm.overdriveCharge = 0.0
            vm.currentOverdriveTier = .none
        }
    }
    
    func applyTargetedOverdrive(at pos: GridPosition) {
        guard vm.isTargetingOverdrive else { return }
        guard let charId = vm.activeCharacterId else { return }
        
        // Charge was already consumed in activateOverdrive()
        OverdriveEngine.executeTargeted(pos: pos, tier: vm.activeOverdriveTierForTargeting, charId: charId, vm: vm)
        vm.haptic.play(.flush)
        
        // Sadece UI bayrağını sıfırla — charge zaten activateOverdrive'da sıfırlandı
        vm.isTargetingOverdrive = false

        // Consume charge now (targeted characters)
        if vm.pendingTargetedOverdriveConsumption, (charId == "block_e" || charId == "architect") {
            vm.pendingTargetedOverdriveConsumption = false
            vm.overdriveCharge = 0.0
            vm.currentOverdriveTier = .none
        }
    }

    func cancelTargetedOverdrive() {
        vm.isTargetingOverdrive = false
        vm.pendingTargetedOverdriveConsumption = false
        vm.dragLocation = .zero
    }

    func updateOverdriveTier(previous: OverdriveTier) {
        guard let char = SaveManager.shared.slots.first(where: { $0.id == vm.activeSlotId })?.character else { return }
        vm.currentOverdriveTier = OverdriveEngine.currentTier(charge: vm.overdriveCharge, thresholds: char.overdriveThresholds)
        
        if vm.currentOverdriveTier != previous && vm.currentOverdriveTier != .none {
            vm.haptic.play(.success)
            vm.addPopup(text: "TIER \(vm.currentOverdriveTier.rawValue) READY!", color: ThemeColors.electricYellow)
        }
    }

    // MARK: - Perk Interactions

    func rotateSelectedBlock() {
        guard let block = vm.selectedBlock else { return }
        
        // Sculptor Kontrolü: Multi-tier logic
        let hasUnlimited = vm.run.maxRotationUses >= 999
        guard vm.run.maxRotationUses > 0 else { return }
        
        // SYNERGY: MASTER BUILDER (Wide Load + Sculptor)
        let isMasterBuilder = vm.activeSynergies.contains(where: { $0.synergyName == SynergyID.masterBuilder })
        let isFourthSlot = vm.blockTray.firstIndex(where: { $0.id == block.id }) == 3
        
        // Kullanım Sınırı Kontrolü (Master Builder ise 4. slot ücretsiz)
        if !hasUnlimited && (!isMasterBuilder || !isFourthSlot) {
            guard vm.run.currentRotationUses > 0 else {
                vm.addPopup(text: vm.userEnv.labelRotateLimit, color: ThemeColors.neonPink)
                return
            }
            vm.run.currentRotationUses -= 1
        } else if isMasterBuilder && isFourthSlot {
            vm.addPopup(text: "FREE ROTATE!", color: ThemeColors.neonPurple)
        } else if hasUnlimited {
            vm.addPopup(text: "UNLIMITED!", color: ThemeColors.neonPurple)
        }
        
        if let index = vm.blockTray.firstIndex(where: { $0.id == block.id }) {
            vm.blockTray[index].rotate()
            vm.selectedBlock = vm.blockTray[index]
            vm.haptic.play(.selection)
            vm.addPopup(text: vm.userEnv.labelRotated, color: ThemeColors.neonCyan)
        }
    }

    func rotateBlockInTray(id: UUID) {
        guard let index = vm.blockTray.firstIndex(where: { $0.id == id }) else { return }
        var block = vm.blockTray[index]
        
        // Sculptor Perk Check: Multi-tier logic
        let hasUnlimited = vm.run.maxRotationUses >= 999
        
        if vm.run.maxRotationUses > 0 {
            if !hasUnlimited && vm.run.currentRotationUses <= 0 {
                vm.haptic.play(.error)
                vm.addPopup(text: vm.userEnv.labelRotateLimit, color: ThemeColors.textMuted)
                return
            }
            
            if block.isRotatable {
                block.rotate()
                vm.blockTray[index] = block
                
                if !hasUnlimited {
                    vm.run.currentRotationUses -= 1
                    vm.addPopup(text: "SCULPTOR (\(vm.run.currentRotationUses))", color: ThemeColors.neonCyan)
                } else {
                    vm.addPopup(text: "UNLIMITED!", color: ThemeColors.neonPurple)
                }
                
                vm.haptic.play(.buttonTap)
            }
        } else if block.isRotatable {
            // Standart rotasyon (bazı özel bloklar için)
            block.rotate()
            vm.blockTray[index] = block
            vm.haptic.play(.buttonTap)
        }
    }

    // MARK: - Consumable Interactions
    
    func useItem(_ item: ConsumableItem) {
        guard vm.phase == .playing || vm.phase == .paused else { return }
        
        switch item.type {
        case .heal:
            // No-op: Can mantığı kaldırıldı
            vm.addPopup(text: "HEALED", color: ThemeColors.neonPink)
            vm.haptic.play(.success)
        case .energy:
            vm.overdriveCharge = 3.0
            updateOverdriveTier(previous: .none)
            vm.addPopup(text: "ENERGY MAXED!", color: ThemeColors.electricYellow)
            vm.haptic.play(.success)
        case .goldBag:
            vm.addRunGold(150)
            AudioManager.shared.playSFX(.coin)
            vm.addPopup(text: "+150 GOLD", color: ThemeColors.electricYellow)
            vm.haptic.play(.success)
        case .cleanup:
            vm.board.resetGrid()
            vm.addPopup(text: "SYSTEM CLEANUP", color: ThemeColors.neonCyan)
            vm.haptic.play(.flush)
        }
        
        // Remove from local and disk
        vm.run.inventory.removeAll(where: { $0.id == item.id })
        SaveManager.shared.removeConsumable(slotId: vm.activeSlotId, itemId: item.id)
    }

    // MARK: - Character Passives Loop
    
    func startPassiveLoop() {
        Timer.publish(every: 10.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.vm.phase == .playing else { return }

                if let charId = self.vm.activeCharacterId {
                    switch charId {
                    case "block_e":
                        // BLOCK-E: Her 10sn, 1 rastgele hücre temizle — max 3/round
                        if self.vm.blockEClearsThisRound >= 3 { break }
                        self.vm.blockEClearsThisRound += 1
                        self.clearRandomCell(count: 1)
                        self.vm.addPopup(
                            text: "BLOCK-E: CLEANUP (\(self.vm.blockEClearsThisRound)/3)",
                            color: ThemeColors.neonCyan
                        )
                        self.vm.haptic.play(.lineClear)
                        self.vm.userEnv.bumpAchievement("block_e_custodian", by: 1)
                        self.vm.userEnv.reportQuestEvent(characterId: "block_e", event: .blockEPassiveTicks, amount: 1)
                    case "ghost":
                        // Ghost pasifi: Her 10sn +3sn whisper bonusu (stealth zamanı)
                        self.vm.timer.addTime(3.0)
                        self.vm.addPopup(text: "GHOST WHISPER +3s", color: ThemeColors.neonPurple)
                    default: break
                    }
                }
            }
            .store(in: &vm.cancellables)
    }
    
    func clearRandomCell(count: Int) {
        let occupied = (0..<BoardViewModel.size).flatMap { r in
            (0..<BoardViewModel.size).compactMap { c in
                vm.board.grid[r][c].isOccupied ? GridPosition(row: r, col: c) : nil
            }
        }.shuffled()
        
        for pos in occupied.prefix(count) {
            vm.board.removeCell(at: pos)
            // Trigger a small flash
            vm.clearFlashPositions = [pos]
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.vm.clearFlashPositions = []
            }
        }
    }

    // MARK: - Boss Specific Logic
    
    func startPhantomPulse() {
        Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.vm.run.round.modifier == .phantom else { return }
                
                // Pulse visibility: 0.8s visible, then hide again
                self.vm.isPhantomVisible = true
                self.vm.addPopup(text: "PHANTOM DETECTED!", color: ThemeColors.neonPurple)
                self.vm.haptic.play(.heavy)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.vm.isPhantomVisible = false
                }
            }
            .store(in: &vm.cancellables)
    }

    // MARK: - Meta Perks Injection

    func applyMetaPerks() {
        let slot = SaveManager.shared.slots.first(where: { $0.id == vm.activeSlotId })
        let levels = slot?.perkLevels ?? [:]
        
        // Clear previous injections to avoid duplicates
        vm.run.activePassivePerks.removeAll { perk in
            ["wide_load", "sculptor", "last_stand", "golden_stamp", "overkill", "safe_house"].contains(perk.id)
        }
        
        // --- HARD-WIRED MECHANIC PERKS ---
        
        // Wide Load: Increases tray capacity
        let wideLoadTier = levels["wide_load"] ?? 0
        let wideLoadData = PerkUpgradeRegistry.tierData(for: .wideLoad, tier: wideLoadTier)
        vm.run.maxTraySlots = Int(wideLoadData.effectValue)
        
        // Sculptor: Rotation uses per round
        let sculptorTier = levels["sculptor"] ?? 0
        let sculptorData = PerkUpgradeRegistry.tierData(for: .sculptor, tier: sculptorTier)
        vm.run.maxRotationUses = Int(sculptorData.effectValue)
        vm.run.currentRotationUses = vm.run.maxRotationUses
        
        // Last Stand: Revive uses
        let lastStandTier = levels["last_stand"] ?? 0
        vm.run.lastStandUses = lastStandTier > 0 ? 1 : 0
        
        // --- PASSIVE PERKS INJECTION (Core only) ---
        // Core perks are always active if unlocked (Tier >= 1)
        let coreIds = ["golden_stamp", "overkill", "safe_house", "wide_load", "sculptor", "last_stand"]
        for id in coreIds {
            let tier = levels[id] ?? 0
            if tier > 0 {
                if let perk = PerkEngine.perk(for: id, lang: vm.userEnv.language, tier: tier) {
                    vm.run.activePassivePerks.append(perk)
                }
            }
        }
    }

    // MARK: - Synergy Management

    func addPerk(_ perk: PassivePerk) {
        let oldSynergies = Set(vm.activeSynergies.map { $0.synergyName })
        vm.run.activePassivePerks.append(perk)
        vm.activeSynergies = PerkEngine.evaluateSynergies(perks: vm.run.activePassivePerks)
        
        let newSynergies = vm.activeSynergies.filter { !oldSynergies.contains($0.synergyName) }
        for (index, synergy) in newSynergies.enumerated() {
            let delay = Double(index) * 0.4
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.vm.addPopup(text: "SYNERGY: \(synergy.synergyName.uppercased())", color: ThemeColors.neonPurple)
                HapticManager.shared.play(.success)
                AudioManager.shared.playSFX(.synergy)
            }
        }
        
        // Phase C: Discovery
        UserEnvironment.shared.discoverPerk(perk.id)
    }
}
