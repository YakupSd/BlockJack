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

    // Mode geriye uyumluluk için korunuyor ancak yeni Slot Hub akışında
    // tek bir "BAŞLA" davranışı mevcut: boş slot → ilk kurulum, dolu
    // slot → Hub. Mode parametresi artık yalnızca başlık rengi/metni
    // etkiler; eski çağıran yerler kırılmasın diye default'u olan bir
    // init sunuyoruz.
    enum Mode { case newGame, continueGame }
    let mode: Mode

    init(mode: Mode = .newGame) { self.mode = mode }
    
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
                    
                    Text(userEnv.localizedString("SLOT SEÇ", "SELECT SLOT"))
                        .font(.setCustomFont(name: .InterBlack, size: 20))
                        .foregroundStyle(ThemeColors.neonCyan)
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
                        .font(.setCustomFont(name: .InterBold, size: 12))
                        .foregroundStyle(ThemeColors.textSecondary)
                        .tracking(1.5)
                    
                    if slot.isEmpty {
                        Text(userEnv.localizedString("Boş Kayıt", "Empty Slot"))
                            .font(.setCustomFont(name: .InterBold, size: 18))
                            .foregroundStyle(.white)
                    } else {
                        // Karakter adı (varsa)
                        if let characterName = slot.character?.name {
                            Text(characterName)
                                .font(.setCustomFont(name: .InterExtraBold, size: 16))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }

                        // Bölüm · Tur · Skor — tek satır
                        HStack(spacing: 6) {
                            Text(userEnv.localizedString(
                                "Bölüm \(slot.unlockedWorldLevel)",
                                "Chapter \(slot.unlockedWorldLevel)"
                            ))
                                .font(.setCustomFont(name: .InterBold, size: 12))
                                .foregroundStyle(ThemeColors.neonPurple)

                            Text("·")
                                .font(.setCustomFont(name: .InterBold, size: 12))
                                .foregroundStyle(ThemeColors.textMuted)

                            Text(userEnv.localizedString(
                                "Tur \(slot.currentRound)",
                                "Round \(slot.currentRound)"
                            ))
                                .font(.setCustomFont(name: .InterBold, size: 12))
                                .foregroundStyle(ThemeColors.neonCyan)
                        }

                        // Skor + altın rozetleri
                        HStack(spacing: 8) {
                            statBadge(
                                iconName: "trophy.fill",
                                value: "\(slot.currentScore)",
                                color: ThemeColors.electricYellow
                            )
                            statBadge(
                                iconName: "bitcoinsign.circle.fill",
                                value: "\(slot.gold)",
                                color: ThemeColors.success
                            )
                        }
                        .padding(.top, 2)
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
                    slot.isEmpty ? ThemeColors.neonCyan.opacity(0.45)
                                 : ThemeColors.electricYellow.opacity(0.55),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Stat Badge

    @ViewBuilder
    private func statBadge(iconName: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
            Text(value)
                .font(.setCustomFont(name: .InterBold, size: 11))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 0.8))
    }

    // MARK: - Actions
    
    private func handleSlotTap(_ slot: SaveSlot) {
        HapticManager.shared.play(.buttonTap)

        // Yeni Slot Hub akışı:
        //  - Boş slot → ilk kurulum: Karakter seç → Perk seç → Map
        //  - Dolu slot → Hub ekranı (devam etme / market / karakter / galeri)
        // Not: loadFromSlot Hub içinde tekrar çağrılıyor, ama burada da
        // çağırıyoruz ki Hub açılmadan önce userEnv.gold gibi bağlamlar
        // güncel olsun (Hub'ın background/header okuduğu değerler için).
        if slot.isEmpty {
            MainViewsRouter.shared.pushToCharacterSelection(slotId: slot.id, mode: .firstSetup)
        } else {
            userEnv.loadFromSlot(slot)
            MainViewsRouter.shared.pushToSlotHub(slotId: slot.id)
        }
    }
}

#Preview {
    SaveSlotSelectionView(mode: .newGame)
        .environmentObject(UserEnvironment.shared)
}
