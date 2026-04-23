//
//  CharacterQuestEngine.swift
//  Block-Jack
//
//  UI-only retention layer: 7 günlük karakter görev zinciri.
//  Amaç: her karakter için “oyna & dene” motivasyonu + küçük ödül döngüsü.
//

import Foundation

enum CharacterQuestEvent: String, Codable, CaseIterable {
    case linesCleared
    case flushScored
    case overdriveUsed
    case heavyCellsCleared
    case phantomOverwriteCells
    case blockEPassiveTicks
    case gamblerJackpot
    case neonWraithLowTimeClears
    case alchemistMonoResonance
    case titanEarthquake
}

struct CharacterQuest: Identifiable, Codable, Equatable {
    let id: String
    let characterId: String
    let day: Int                 // 1..7
    let titleTR: String
    let titleEN: String
    let descTR: String
    let descEN: String
    let goal: Int
    let rewardGold: Int
    let rewardDiamonds: Int
    let icon: String
    let event: CharacterQuestEvent
}

enum CharacterQuestEngine {
    static let chainLength: Int = 7

    static let catalog: [CharacterQuest] = [
        // BLOCK-E
        .init(id: "q_block_e_1", characterId: "block_e", day: 1,
              titleTR: "BLOCK-E • İlk Mesai", titleEN: "BLOCK-E • First Shift",
              descTR: "10 satır temizle", descEN: "Clear 10 lines",
              goal: 10, rewardGold: 150, rewardDiamonds: 5, icon: "cpu.fill", event: .linesCleared),
        .init(id: "q_block_e_2", characterId: "block_e", day: 2,
              titleTR: "BLOCK-E • Otomatik Temizlik", titleEN: "BLOCK-E • Auto Cleanup",
              descTR: "5 pasif temizlik tetikle", descEN: "Trigger 5 passive cleanups",
              goal: 5, rewardGold: 200, rewardDiamonds: 8, icon: "sparkles", event: .blockEPassiveTicks),
        .init(id: "q_block_e_3", characterId: "block_e", day: 3,
              titleTR: "BLOCK-E • Serilik", titleEN: "BLOCK-E • Streak",
              descTR: "20 satır temizle", descEN: "Clear 20 lines",
              goal: 20, rewardGold: 250, rewardDiamonds: 10, icon: "flame.fill", event: .linesCleared),
        .init(id: "q_block_e_4", characterId: "block_e", day: 4,
              titleTR: "BLOCK-E • Parlak İş", titleEN: "BLOCK-E • Shiny Work",
              descTR: "3 flush yap", descEN: "Score 3 flushes",
              goal: 3, rewardGold: 300, rewardDiamonds: 12, icon: "crown.fill", event: .flushScored),
        .init(id: "q_block_e_5", characterId: "block_e", day: 5,
              titleTR: "BLOCK-E • Overdrive Pratiği", titleEN: "BLOCK-E • Overdrive Practice",
              descTR: "3 kez overdrive kullan", descEN: "Use overdrive 3 times",
              goal: 3, rewardGold: 350, rewardDiamonds: 15, icon: "bolt.fill", event: .overdriveUsed),
        .init(id: "q_block_e_6", characterId: "block_e", day: 6,
              titleTR: "BLOCK-E • Usta Temizlik", titleEN: "BLOCK-E • Expert Cleanup",
              descTR: "40 satır temizle", descEN: "Clear 40 lines",
              goal: 40, rewardGold: 400, rewardDiamonds: 18, icon: "checkmark.seal.fill", event: .linesCleared),
        .init(id: "q_block_e_7", characterId: "block_e", day: 7,
              titleTR: "BLOCK-E • Efsane Mesai", titleEN: "BLOCK-E • Legendary Shift",
              descTR: "10 flush yap", descEN: "Score 10 flushes",
              goal: 10, rewardGold: 500, rewardDiamonds: 25, icon: "star.fill", event: .flushScored),

        // TIME BENDER
        .init(id: "q_timebender_1", characterId: "timebender", day: 1,
              titleTR: "Time Bender • Çarklar", titleEN: "Time Bender • Gears",
              descTR: "15 satır temizle", descEN: "Clear 15 lines",
              goal: 15, rewardGold: 200, rewardDiamonds: 8, icon: "hourglass", event: .linesCleared),
        .init(id: "q_timebender_2", characterId: "timebender", day: 2,
              titleTR: "Time Bender • Zaman Dokunuşu", titleEN: "Time Bender • Time Touch",
              descTR: "3 kez overdrive kullan", descEN: "Use overdrive 3 times",
              goal: 3, rewardGold: 250, rewardDiamonds: 12, icon: "clock.fill", event: .overdriveUsed),
        .init(id: "q_timebender_3", characterId: "timebender", day: 3,
              titleTR: "Time Bender • Ritm", titleEN: "Time Bender • Rhythm",
              descTR: "25 satır temizle", descEN: "Clear 25 lines",
              goal: 25, rewardGold: 300, rewardDiamonds: 15, icon: "metronome.fill", event: .linesCleared),
        .init(id: "q_timebender_4", characterId: "timebender", day: 4,
              titleTR: "Time Bender • Parlak Zaman", titleEN: "Time Bender • Shiny Time",
              descTR: "5 flush yap", descEN: "Score 5 flushes",
              goal: 5, rewardGold: 350, rewardDiamonds: 18, icon: "crown.fill", event: .flushScored),
        .init(id: "q_timebender_5", characterId: "timebender", day: 5,
              titleTR: "Time Bender • Duraklat", titleEN: "Time Bender • Pause",
              descTR: "5 kez overdrive kullan", descEN: "Use overdrive 5 times",
              goal: 5, rewardGold: 450, rewardDiamonds: 22, icon: "pause.fill", event: .overdriveUsed),
        .init(id: "q_timebender_6", characterId: "timebender", day: 6,
              titleTR: "Time Bender • Tempolu", titleEN: "Time Bender • Upbeat",
              descTR: "40 satır temizle", descEN: "Clear 40 lines",
              goal: 40, rewardGold: 500, rewardDiamonds: 25, icon: "waveform.path.ecg", event: .linesCleared),
        .init(id: "q_timebender_7", characterId: "timebender", day: 7,
              titleTR: "Time Bender • Usta", titleEN: "Time Bender • Master",
              descTR: "10 kez overdrive kullan", descEN: "Use overdrive 10 times",
              goal: 10, rewardGold: 650, rewardDiamonds: 35, icon: "star.fill", event: .overdriveUsed),

        // GHOST
        .init(id: "q_ghost_1", characterId: "ghost", day: 1,
              titleTR: "Ghost • İz", titleEN: "Ghost • Trace",
              descTR: "10 satır temizle", descEN: "Clear 10 lines",
              goal: 10, rewardGold: 200, rewardDiamonds: 8, icon: "eye.slash.fill", event: .linesCleared),
        .init(id: "q_ghost_2", characterId: "ghost", day: 2,
              titleTR: "Ghost • Phantom", titleEN: "Ghost • Phantom",
              descTR: "10 hücre phantom overwrite yap", descEN: "Phantom overwrite 10 cells",
              goal: 10, rewardGold: 250, rewardDiamonds: 12, icon: "scribble.variable", event: .phantomOverwriteCells),
        .init(id: "q_ghost_3", characterId: "ghost", day: 3,
              titleTR: "Ghost • Sessiz Temizlik", titleEN: "Ghost • Silent Sweep",
              descTR: "25 satır temizle", descEN: "Clear 25 lines",
              goal: 25, rewardGold: 300, rewardDiamonds: 15, icon: "checkmark.circle.fill", event: .linesCleared),
        .init(id: "q_ghost_4", characterId: "ghost", day: 4,
              titleTR: "Ghost • Bonus", titleEN: "Ghost • Bonus",
              descTR: "3 kez overdrive kullan", descEN: "Use overdrive 3 times",
              goal: 3, rewardGold: 350, rewardDiamonds: 18, icon: "bolt.fill", event: .overdriveUsed),
        .init(id: "q_ghost_5", characterId: "ghost", day: 5,
              titleTR: "Ghost • Üst Yazım", titleEN: "Ghost • Overwrite",
              descTR: "20 hücre phantom overwrite yap", descEN: "Phantom overwrite 20 cells",
              goal: 20, rewardGold: 450, rewardDiamonds: 22, icon: "pencil.and.outline", event: .phantomOverwriteCells),
        .init(id: "q_ghost_6", characterId: "ghost", day: 6,
              titleTR: "Ghost • Zenginlik", titleEN: "Ghost • Riches",
              descTR: "5 flush yap", descEN: "Score 5 flushes",
              goal: 5, rewardGold: 500, rewardDiamonds: 25, icon: "crown.fill", event: .flushScored),
        .init(id: "q_ghost_7", characterId: "ghost", day: 7,
              titleTR: "Ghost • Efsane", titleEN: "Ghost • Legend",
              descTR: "40 hücre phantom overwrite yap", descEN: "Phantom overwrite 40 cells",
              goal: 40, rewardGold: 650, rewardDiamonds: 35, icon: "star.fill", event: .phantomOverwriteCells),

        // TITAN
        .init(id: "q_titan_1", characterId: "titan", day: 1,
              titleTR: "Titan • Ağırlık", titleEN: "Titan • Weight",
              descTR: "8 heavy hücresi kır", descEN: "Break 8 heavy cells",
              goal: 8, rewardGold: 220, rewardDiamonds: 10, icon: "hammer.fill", event: .heavyCellsCleared),
        .init(id: "q_titan_2", characterId: "titan", day: 2,
              titleTR: "Titan • Güç", titleEN: "Titan • Power",
              descTR: "2 kez overdrive kullan", descEN: "Use overdrive 2 times",
              goal: 2, rewardGold: 260, rewardDiamonds: 12, icon: "bolt.fill", event: .overdriveUsed),
        .init(id: "q_titan_3", characterId: "titan", day: 3,
              titleTR: "Titan • Kır", titleEN: "Titan • Smash",
              descTR: "16 heavy hücresi kır", descEN: "Break 16 heavy cells",
              goal: 16, rewardGold: 320, rewardDiamonds: 15, icon: "cube.fill", event: .heavyCellsCleared),
        .init(id: "q_titan_4", characterId: "titan", day: 4,
              titleTR: "Titan • Parlak", titleEN: "Titan • Shiny",
              descTR: "3 flush yap", descEN: "Score 3 flushes",
              goal: 3, rewardGold: 380, rewardDiamonds: 18, icon: "crown.fill", event: .flushScored),
        .init(id: "q_titan_5", characterId: "titan", day: 5,
              titleTR: "Titan • Deprem", titleEN: "Titan • Earthquake",
              descTR: "1 kez Earthquake kullan", descEN: "Use Earthquake once",
              goal: 1, rewardGold: 450, rewardDiamonds: 22, icon: "waveform.path.ecg", event: .titanEarthquake),
        .init(id: "q_titan_6", characterId: "titan", day: 6,
              titleTR: "Titan • Yüksek Ağırlık", titleEN: "Titan • Heavy Duty",
              descTR: "30 heavy hücresi kır", descEN: "Break 30 heavy cells",
              goal: 30, rewardGold: 520, rewardDiamonds: 28, icon: "shield.fill", event: .heavyCellsCleared),
        .init(id: "q_titan_7", characterId: "titan", day: 7,
              titleTR: "Titan • Efsane", titleEN: "Titan • Legend",
              descTR: "3 kez Earthquake kullan", descEN: "Use Earthquake 3 times",
              goal: 3, rewardGold: 700, rewardDiamonds: 40, icon: "star.fill", event: .titanEarthquake),

        // ALCHEMIST
        .init(id: "q_alchemist_1", characterId: "alchemist", day: 1,
              titleTR: "Alchemist • Başlangıç", titleEN: "Alchemist • Start",
              descTR: "3 mono-rezonans tetikle", descEN: "Trigger 3 mono resonances",
              goal: 3, rewardGold: 220, rewardDiamonds: 10, icon: "flask.fill", event: .alchemistMonoResonance),
        .init(id: "q_alchemist_2", characterId: "alchemist", day: 2,
              titleTR: "Alchemist • Karışım", titleEN: "Alchemist • Mix",
              descTR: "2 flush yap", descEN: "Score 2 flushes",
              goal: 2, rewardGold: 260, rewardDiamonds: 12, icon: "crown.fill", event: .flushScored),
        .init(id: "q_alchemist_3", characterId: "alchemist", day: 3,
              titleTR: "Alchemist • Rezonans", titleEN: "Alchemist • Resonance",
              descTR: "10 mono-rezonans tetikle", descEN: "Trigger 10 mono resonances",
              goal: 10, rewardGold: 320, rewardDiamonds: 15, icon: "sparkles", event: .alchemistMonoResonance),
        .init(id: "q_alchemist_4", characterId: "alchemist", day: 4,
              titleTR: "Alchemist • Overdrive", titleEN: "Alchemist • Overdrive",
              descTR: "3 kez overdrive kullan", descEN: "Use overdrive 3 times",
              goal: 3, rewardGold: 380, rewardDiamonds: 18, icon: "bolt.fill", event: .overdriveUsed),
        .init(id: "q_alchemist_5", characterId: "alchemist", day: 5,
              titleTR: "Alchemist • Parlak", titleEN: "Alchemist • Shiny",
              descTR: "5 flush yap", descEN: "Score 5 flushes",
              goal: 5, rewardGold: 450, rewardDiamonds: 22, icon: "crown.fill", event: .flushScored),
        .init(id: "q_alchemist_6", characterId: "alchemist", day: 6,
              titleTR: "Alchemist • Usta", titleEN: "Alchemist • Adept",
              descTR: "25 mono-rezonans tetikle", descEN: "Trigger 25 mono resonances",
              goal: 25, rewardGold: 520, rewardDiamonds: 28, icon: "checkmark.seal.fill", event: .alchemistMonoResonance),
        .init(id: "q_alchemist_7", characterId: "alchemist", day: 7,
              titleTR: "Alchemist • Efsane", titleEN: "Alchemist • Legend",
              descTR: "10 flush yap", descEN: "Score 10 flushes",
              goal: 10, rewardGold: 700, rewardDiamonds: 40, icon: "star.fill", event: .flushScored),

        // GAMBLER
        .init(id: "q_gambler_1", characterId: "gambler", day: 1,
              titleTR: "Gambler • Isınma", titleEN: "Gambler • Warmup",
              descTR: "1 jackpot tetikle", descEN: "Trigger 1 jackpot",
              goal: 1, rewardGold: 220, rewardDiamonds: 10, icon: "dice.fill", event: .gamblerJackpot),
        .init(id: "q_gambler_2", characterId: "gambler", day: 2,
              titleTR: "Gambler • Çılgınlık", titleEN: "Gambler • Madness",
              descTR: "10 satır temizle", descEN: "Clear 10 lines",
              goal: 10, rewardGold: 260, rewardDiamonds: 12, icon: "flame.fill", event: .linesCleared),
        .init(id: "q_gambler_3", characterId: "gambler", day: 3,
              titleTR: "Gambler • Şans", titleEN: "Gambler • Luck",
              descTR: "2 jackpot tetikle", descEN: "Trigger 2 jackpots",
              goal: 2, rewardGold: 320, rewardDiamonds: 15, icon: "dice", event: .gamblerJackpot),
        .init(id: "q_gambler_4", characterId: "gambler", day: 4,
              titleTR: "Gambler • Parlak", titleEN: "Gambler • Shiny",
              descTR: "3 flush yap", descEN: "Score 3 flushes",
              goal: 3, rewardGold: 380, rewardDiamonds: 18, icon: "crown.fill", event: .flushScored),
        .init(id: "q_gambler_5", characterId: "gambler", day: 5,
              titleTR: "Gambler • Patlama", titleEN: "Gambler • Blast",
              descTR: "4 jackpot tetikle", descEN: "Trigger 4 jackpots",
              goal: 4, rewardGold: 450, rewardDiamonds: 22, icon: "sparkles", event: .gamblerJackpot),
        .init(id: "q_gambler_6", characterId: "gambler", day: 6,
              titleTR: "Gambler • Overdrive", titleEN: "Gambler • Overdrive",
              descTR: "5 kez overdrive kullan", descEN: "Use overdrive 5 times",
              goal: 5, rewardGold: 520, rewardDiamonds: 28, icon: "bolt.fill", event: .overdriveUsed),
        .init(id: "q_gambler_7", characterId: "gambler", day: 7,
              titleTR: "Gambler • Efsane Jackpot", titleEN: "Gambler • Legendary Jackpot",
              descTR: "6 jackpot tetikle", descEN: "Trigger 6 jackpots",
              goal: 6, rewardGold: 700, rewardDiamonds: 40, icon: "star.fill", event: .gamblerJackpot),

        // NEON WRAITH
        .init(id: "q_neonwraith_1", characterId: "neonwraith", day: 1,
              titleTR: "Wraith • Isınma", titleEN: "Wraith • Warmup",
              descTR: "%20 altı sürede 5 clear", descEN: "5 clears under 20% time",
              goal: 5, rewardGold: 220, rewardDiamonds: 10, icon: "bolt.fill", event: .neonWraithLowTimeClears),
        .init(id: "q_neonwraith_2", characterId: "neonwraith", day: 2,
              titleTR: "Wraith • Hız", titleEN: "Wraith • Speed",
              descTR: "10 satır temizle", descEN: "Clear 10 lines",
              goal: 10, rewardGold: 260, rewardDiamonds: 12, icon: "flame.fill", event: .linesCleared),
        .init(id: "q_neonwraith_3", characterId: "neonwraith", day: 3,
              titleTR: "Wraith • Son Saniye", titleEN: "Wraith • Clutch",
              descTR: "%20 altı sürede 10 clear", descEN: "10 clears under 20% time",
              goal: 10, rewardGold: 320, rewardDiamonds: 15, icon: "bolt.fill", event: .neonWraithLowTimeClears),
        .init(id: "q_neonwraith_4", characterId: "neonwraith", day: 4,
              titleTR: "Wraith • Overdrive", titleEN: "Wraith • Overdrive",
              descTR: "3 kez overdrive kullan", descEN: "Use overdrive 3 times",
              goal: 3, rewardGold: 380, rewardDiamonds: 18, icon: "bolt.fill", event: .overdriveUsed),
        .init(id: "q_neonwraith_5", characterId: "neonwraith", day: 5,
              titleTR: "Wraith • Parlak", titleEN: "Wraith • Shiny",
              descTR: "5 flush yap", descEN: "Score 5 flushes",
              goal: 5, rewardGold: 450, rewardDiamonds: 22, icon: "crown.fill", event: .flushScored),
        .init(id: "q_neonwraith_6", characterId: "neonwraith", day: 6,
              titleTR: "Wraith • Çok Yakın", titleEN: "Wraith • So Close",
              descTR: "%20 altı sürede 20 clear", descEN: "20 clears under 20% time",
              goal: 20, rewardGold: 520, rewardDiamonds: 28, icon: "bolt.circle.fill", event: .neonWraithLowTimeClears),
        .init(id: "q_neonwraith_7", characterId: "neonwraith", day: 7,
              titleTR: "Wraith • Efsane", titleEN: "Wraith • Legend",
              descTR: "%20 altı sürede 35 clear", descEN: "35 clears under 20% time",
              goal: 35, rewardGold: 700, rewardDiamonds: 40, icon: "star.fill", event: .neonWraithLowTimeClears),

        // ARCHITECT (daha genel)
        .init(id: "q_architect_1", characterId: "architect", day: 1,
              titleTR: "Architect • Başlangıç", titleEN: "Architect • Start",
              descTR: "10 satır temizle", descEN: "Clear 10 lines",
              goal: 10, rewardGold: 200, rewardDiamonds: 8, icon: "square.grid.3x3.fill", event: .linesCleared),
        .init(id: "q_architect_2", characterId: "architect", day: 2,
              titleTR: "Architect • Parlak", titleEN: "Architect • Shiny",
              descTR: "2 flush yap", descEN: "Score 2 flushes",
              goal: 2, rewardGold: 240, rewardDiamonds: 10, icon: "crown.fill", event: .flushScored),
        .init(id: "q_architect_3", characterId: "architect", day: 3,
              titleTR: "Architect • Tempo", titleEN: "Architect • Tempo",
              descTR: "25 satır temizle", descEN: "Clear 25 lines",
              goal: 25, rewardGold: 300, rewardDiamonds: 15, icon: "flame.fill", event: .linesCleared),
        .init(id: "q_architect_4", characterId: "architect", day: 4,
              titleTR: "Architect • Overdrive", titleEN: "Architect • Overdrive",
              descTR: "3 kez overdrive kullan", descEN: "Use overdrive 3 times",
              goal: 3, rewardGold: 360, rewardDiamonds: 18, icon: "bolt.fill", event: .overdriveUsed),
        .init(id: "q_architect_5", characterId: "architect", day: 5,
              titleTR: "Architect • Büyük Temizlik", titleEN: "Architect • Big Sweep",
              descTR: "40 satır temizle", descEN: "Clear 40 lines",
              goal: 40, rewardGold: 450, rewardDiamonds: 22, icon: "checkmark.seal.fill", event: .linesCleared),
        .init(id: "q_architect_6", characterId: "architect", day: 6,
              titleTR: "Architect • Parlak Usta", titleEN: "Architect • Shiny Adept",
              descTR: "8 flush yap", descEN: "Score 8 flushes",
              goal: 8, rewardGold: 520, rewardDiamonds: 28, icon: "crown.fill", event: .flushScored),
        .init(id: "q_architect_7", characterId: "architect", day: 7,
              titleTR: "Architect • Efsane", titleEN: "Architect • Legend",
              descTR: "10 kez overdrive kullan", descEN: "Use overdrive 10 times",
              goal: 10, rewardGold: 650, rewardDiamonds: 35, icon: "star.fill", event: .overdriveUsed)
    ]

    static func currentQuest(for characterId: String, day: Int) -> CharacterQuest? {
        catalog.first(where: { $0.characterId == characterId && $0.day == day })
    }

    static func chain(for characterId: String) -> [CharacterQuest] {
        catalog.filter { $0.characterId == characterId }.sorted { $0.day < $1.day }
    }
}

