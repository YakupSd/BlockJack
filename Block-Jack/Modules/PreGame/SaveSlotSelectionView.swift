//
//  SaveSlotSelectionView.swift
//  Block-Jack
//

import SwiftUI

struct SaveSlotSelectionView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @StateObject private var saveManager = SaveManager.shared
    
    @State private var showingDeleteAlert = false
    @State private var slotToDelete: Int? = nil
    
    // Yönlendirme tipleri (Yeni oyun ise karakter seçimine, devam ise direkt oyuna)
    enum Mode { case newGame, continueGame }
    let mode: Mode
    
    var body: some View {
        ZStack {
            ThemeColors.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button {
                        HapticManager.shared.play(.buttonTap)
                        MainViewsRouter.shared.popFromBottom()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(ThemeColors.textSecondary)
                            .frame(width: 44, height: 44)
                            .background(ThemeColors.surfaceDark)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text(mode == .newGame ? userEnv.localizedString("YENİ OYUN", "NEW GAME") : userEnv.localizedString("KAYITLI OYUN", "CONTINUE"))
                        .font(.setCustomFont(name: .InterBlack, size: 20))
                        .foregroundStyle(mode == .newGame ? ThemeColors.neonCyan : ThemeColors.electricYellow)
                        .tracking(2)
                    
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Slots
                VStack(spacing: 16) {
                    ForEach(saveManager.slots) { slot in
                        slotRow(slot)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .alert(userEnv.localizedString("Kaydı Sil", "Delete Save"), isPresented: $showingDeleteAlert) {
            Button(userEnv.localizedString("İptal", "Cancel"), role: .cancel) { }
            Button(userEnv.localizedString("Sil", "Delete"), role: .destructive) {
                if let id = slotToDelete {
                    HapticManager.shared.play(.buttonTap)
                    saveManager.deleteSave(slotId: id)
                }
            }
        } message: {
            Text(userEnv.localizedString("Bu kaydı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.", "Are you sure you want to delete this save? This action cannot be undone."))
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func slotRow(_ slot: SaveSlot) -> some View {
        Button {
            handleSlotTap(slot)
        } label: {
            HStack(spacing: 16) {
                // Icon Area
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ThemeColors.gridDark)
                        .frame(width: 60, height: 60)
                    
                    if slot.isEmpty {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(ThemeColors.textMuted)
                    } else if let icon = slot.character?.icon {
                        Image(icon)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Text("❓")
                            .font(.system(size: 32))
                    }
                }
                
                // Details Area
                VStack(alignment: .leading, spacing: 4) {
                    Text("Slot \(slot.id)")
                        .font(.setCustomFont(name: .InterBold, size: 14))
                        .foregroundStyle(ThemeColors.textSecondary)
                    
                    if slot.isEmpty {
                        Text(userEnv.localizedString("Boş Kayıt", "Empty Slot"))
                            .font(.setCustomFont(name: .InterBold, size: 18))
                            .foregroundStyle(.white)
                    } else {
                        HStack {
                            Text("Round \(slot.currentRound)")
                                .font(.setCustomFont(name: .InterExtraBold, size: 16))
                                .foregroundStyle(ThemeColors.neonCyan)
                            
                            Text("·")
                                .foregroundStyle(ThemeColors.textMuted)
                            
                            Text("\(slot.currentScore) pts")
                                .font(.setCustomFont(name: .InterBold, size: 16))
                                .foregroundStyle(ThemeColors.electricYellow)
                        }
                    }
                }
                
                Spacer()
                
                // Delete Button (if not empty)
                if !slot.isEmpty {
                    Button {
                        HapticManager.shared.play(.buttonTap)
                        slotToDelete = slot.id
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(ThemeColors.neonPink)
                            .padding(12)
                            .background(ThemeColors.neonPink.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    slot.isEmpty && mode == .newGame ? ThemeColors.neonCyan :
                    !slot.isEmpty && mode == .continueGame ? ThemeColors.electricYellow :
                    ThemeColors.gridStroke.opacity(0.3),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Actions
    
    private func handleSlotTap(_ slot: SaveSlot) {
        HapticManager.shared.play(.buttonTap)
        
        if mode == .newGame {
            guard slot.isEmpty else {
                // Alert we can only create on empty, or ask to overwrite
                slotToDelete = slot.id
                showingDeleteAlert = true
                return
            }
            // Navigate to Character Select
            MainViewsRouter.shared.pushToCharacterSelection(slotId: slot.id)
        } else {
            guard !slot.isEmpty else { return }
            // Load game with save data (For now, just pushes to game)
            // TODO: In Future, GameViewModel needs to load `slot` 
            MainViewsRouter.shared.pushToGame(slotId: slot.id)
        }
    }
}

#Preview {
    SaveSlotSelectionView(mode: .newGame)
        .environmentObject(UserEnvironment.shared)
}
