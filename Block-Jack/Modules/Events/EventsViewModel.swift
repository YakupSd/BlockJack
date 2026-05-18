import SwiftUI
import Combine

class EventsViewModel: ObservableObject {
    @Published var dailyEvent: EventConfig?
    @Published var weeklyEvent: EventConfig?
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetchEvents() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        await MainActor.run {
            // Load sample events
            self.dailyEvent = sampleDailyEvent
            self.weeklyEvent = sampleWeeklyEvent
            isLoading = false
        }
    }
}

// MARK: - Sample Events

let sampleDailyEvent = EventConfig(
    id: "daily_2026_05_13",
    type: .daily,
    title: "SPEED DEMON",
    description: "Bloklar 2x hızlı düşer, sınırsız oyun",
    startsAt: Date(),
    endsAt: Date().addingTimeInterval(86400),
    modifiers: [
        EventModifier(id: "speed", type: .blockSpeedMultiplier, value: 2.0, description: "2x HIZ", iconName: "bolt.fill"),
        EventModifier(id: "gold", type: .goldPerLineClear, value: 50, description: "+50 ALTIN", iconName: "bitcoinsign.circle"),
        EventModifier(id: "infinite", type: .infiniteTime, value: 0, description: "SINIRSIZ", iconName: "infinity"),
    ],
    boss: EventBoss(
        id: "chrono_wraith",
        name: "CHRONO WRAITH",
        description: "Süre çalar ve hücreleri kilitler",
        spriteKey: "boss_chrono",
        intents: [
            BossIntent(id: "lock", type: .lockCells, value: 3, description: "3 hücreyi kilitler"),
            BossIntent(id: "steal", type: .stealTime, value: 10, description: "Puan çalar"),
            BossIntent(id: "tray", type: .blockTray, value: 2, description: "Tray kilitlenir"),
        ],
        intentCycle: 3
    ),
    character: nil,
    rewards: [
        EventReward(id: "r1", rankFrom: 1, rankTo: 1, diamonds: 500, gold: 200, perkUnlock: nil, label: "1. SIRADA"),
        EventReward(id: "r2", rankFrom: 2, rankTo: 10, diamonds: 200, gold: 100, perkUnlock: nil, label: "TOP 10"),
        EventReward(id: "r3", rankFrom: 11, rankTo: 100, diamonds: 100, gold: 50, perkUnlock: nil, label: "TOP 100"),
        EventReward(id: "r4", rankFrom: 101, rankTo: 999, diamonds: 10, gold: 0, perkUnlock: nil, label: "KATILIM"),
    ],
    rankingMetric: .score
)

let sampleWeeklyEvent = EventConfig(
    id: "weekly_2026_W20",
    type: .weekly,
    title: "ZONE MASTER LEAGUE",
    description: "7 gün boyunca en fazla zone temizle",
    startsAt: Date(),
    endsAt: Date().addingTimeInterval(604800),
    modifiers: [
        EventModifier(id: "infinite", type: .infiniteTime, value: 0, description: "SINIRSIZ", iconName: "infinity"),
        EventModifier(id: "zone", type: .scoreMultiplier, value: 1.5, description: "ZONE x1.5", iconName: "scope"),
    ],
    boss: EventBoss(
        id: "grid_titan",
        name: "GRID TITAN",
        description: "Köşe zone'larını kilitler",
        spriteKey: "boss_grid_titan",
        intents: [
            BossIntent(id: "corners", type: .lockCells, value: 4, description: "Köşe hücreler kilitlendi"),
            BossIntent(id: "junk", type: .addJunkRow, value: 1, description: "Çöp satırı eklendi"),
            BossIntent(id: "shuffle", type: .shuffleBoard, value: 5, description: "Tahta karıştirildi"),
        ],
        intentCycle: 5
    ),
    character: EventCharacter(
        id: "grid_phantom",
        name: "GRID PHANTOM",
        description: "Zone temizlemede +%30 puan, haftalık exclusive",
        spriteKey: "char_grid_phantom",
        isExclusive: true,
        bonusModifiers: [
            EventModifier(id: "zone_bonus", type: .scoreMultiplier, value: 1.3, description: "ZONE +30%", iconName: "scope"),
        ]
    ),
    rewards: [
        EventReward(id: "w1", rankFrom: 1, rankTo: 1, diamonds: 1000, gold: 500, perkUnlock: "grid_phantom_unlock", label: "ŞAMPIYON"),
        EventReward(id: "w2", rankFrom: 2, rankTo: 10, diamonds: 500, gold: 200, perkUnlock: nil, label: "TOP 10"),
        EventReward(id: "w3", rankFrom: 11, rankTo: 100, diamonds: 200, gold: 100, perkUnlock: nil, label: "TOP 100"),
        EventReward(id: "w4", rankFrom: 101, rankTo: 999, diamonds: 50, gold: 0, perkUnlock: nil, label: "KATILIM"),
    ],
    rankingMetric: .zoneCount
)
