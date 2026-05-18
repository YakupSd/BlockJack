# Block-Jack — Daily Challenge & Live Events
## Mimari Genel Bakış

Bu sistem, mevcut roguelite döngüsünden tamamen bağımsız çalışır.
`RunManager` ve `GameViewModel` değişmez — event sistemi kendi izole flow'unu kullanır.

```
EventsView (tab: Daily / Weekly)
  └─ EventDetailView          ← event kartı + boss bilgisi + modifier'lar
  └─ EventGameView            ← oyun ekranı (GameView klonu, event config ile)
       └─ EventGameViewModel  ← GameViewModel'den miras alır, event override'ları ekler
  └─ PerkChoiceView           ← her 5 roundda açılır (3 perk seç)
  └─ EventLeaderboardView     ← günlük/haftalık canlı sıralama
```

---

## 1. VERİ MODELLERİ

### EventConfig — Günlük/Haftalık Event Tanımı

```swift
// Models/EventConfig.swift

struct EventConfig: Codable, Identifiable {
    let id:           String          // "daily_2026_05_13" / "weekly_2026_W20"
    let type:         EventType       // .daily / .weekly
    let title:        String          // "SPEED DEMON"
    let description:  String          // Kısa açıklama
    let startsAt:     Date
    let endsAt:       Date

    let modifiers:    [EventModifier] // aktif modifier listesi
    let boss:         EventBoss       // bu evente özel boss
    let character:    EventCharacter? // weekly exclusive karakter (opsiyonel)
    let rewards:      [EventReward]   // sıralamaya göre ödüller

    // Skor metriği: .score (puan), .zoneCount, .comboCount vb.
    let rankingMetric: RankingMetric

    var isActive: Bool { Date() >= startsAt && Date() <= endsAt }

    var timeRemaining: TimeInterval { endsAt.timeIntervalSince(Date()) }
}

enum EventType: String, Codable { case daily, weekly }

enum RankingMetric: String, Codable {
    case score       // toplam puan — varsayılan
    case zoneCount   // zone temizleme sayısı
    case comboCount  // maksimum kombo
    case goldEarned  // kazanılan altın
}
```

### EventModifier — Oyun Kuralı Değişiklikleri

```swift
// Models/EventModifier.swift

struct EventModifier: Codable, Identifiable {
    let id:          String
    let type:        ModifierType
    let value:       Double        // çarpan veya sabit değer
    let description: String        // UI'da gösterilecek açıklama
    let iconName:    String        // SF Symbol adı
}

enum ModifierType: String, Codable {
    case blockSpeedMultiplier   // blok düşme hızı çarpanı (2.0 = 2x hız)
    case goldPerLineClear        // satır temizlemede bonus altın
    case scoreMultiplier         // genel puan çarpanı
    case infiniteTime            // süre sınırı yok
    case noShuffle               // tray yenilenemiyor
    case mirrorBoard             // tahta aynalı
    case ghostBlocks             // bloklar yarı saydam
    case extraLife               // başlangıçta +1 can
}
```

### EventBoss — Event Boss Yapısı

```swift
// Models/EventBoss.swift

struct EventBoss: Codable {
    let id:          String
    let name:        String          // "CHRONO WRAITH"
    let description: String
    let spriteKey:   String          // asset adı

    // Sabotaj aksiyonları — her N roundda bir tetiklenir
    let intents:     [BossIntent]
    let intentCycle: Int             // kaç roundda bir intent tetiklenir (varsayılan: 3)
}

struct BossIntent: Codable, Identifiable {
    let id:          String
    let type:        BossIntentType
    let value:       Int             // kaç hücre, kaç saniye vs.
    let description: String          // "3 hücreyi kilitler"
}

enum BossIntentType: String, Codable {
    case lockCells          // X hücreyi kilitler
    case stealTime          // X saniye çalar (infinite modda penaltı puan)
    case blockTray          // tray'i X round kilitler
    case addJunkRow         // tahtaya 1 çöp satırı ekler
    case shuffleBoard       // rastgele 5 bloğun yerini değiştirir
    case invertControls     // X saniye kontrolleri tersine çevirir
}
```

### EventCharacter — Event'e Özel Karakter

```swift
// Models/EventCharacter.swift

struct EventCharacter: Codable {
    let id:           String
    let name:         String          // "GRID PHANTOM"
    let description:  String
    let spriteKey:    String
    let isExclusive:  Bool            // true = sadece bu event süresince oynanabilir
    let bonusModifiers: [EventModifier] // karaktere özel ek modifier'lar
}
```

### EventReward — Ödül Yapısı

```swift
// Models/EventReward.swift

struct EventReward: Codable, Identifiable {
    let id:         String
    let rankFrom:   Int   // 1
    let rankTo:     Int   // 10  (1'den 10'a kadar herkes bu ödülü alır)
    let diamonds:   Int
    let gold:       Int
    let perkUnlock: String? // opsiyonel: özel perk ID'si
    let label:      String  // "TOP 100"
}
```

### EventPerk — Round Ödülü Perk

```swift
// Models/EventPerk.swift
// Mevcut Perk modelinden türer, sadece tier ve event flag'i eklenir

struct EventPerk: Identifiable {
    let id:          String
    let name:        String          // "MOMENTUM"
    let description: String          // "Ardışık 3 blok sonra +%20 puan"
    let iconName:    String          // SF Symbol
    let tier:        Int             // 1 (event'te sadece T1 dağıtılır)
    let effect:      PerkEffectType  // mevcut PerkEffectType enum'u kullan
}

// Her 5 roundda sunulacak havuz — en az 10 perk olmalı
// Örnek havuz:
let eventPerkPool: [EventPerk] = [
    EventPerk(id:"momentum",     name:"MOMENTUM",     description:"Ardışık 3 blok sonra +%20 puan",    iconName:"bolt.fill",        tier:1, effect:.scoreMultiplier),
    EventPerk(id:"gold_eye",     name:"GOLD EYE",     description:"Altın blok şansı +%15",             iconName:"eye.fill",         tier:1, effect:.goldBonus),
    EventPerk(id:"block_shield", name:"BLOCK SHIELD", description:"Her 5 roundda 1 can koruması",      iconName:"shield.fill",      tier:1, effect:.lifeShield),
    EventPerk(id:"line_rush",    name:"LINE RUSH",    description:"Satır temizlemede 2x combo",        iconName:"arrow.up.circle",  tier:1, effect:.comboMultiplier),
    EventPerk(id:"zone_magnet",  name:"ZONE MAGNET",  description:"Zone doluluk göstergesi görünür",   iconName:"scope",            tier:1, effect:.zoneHint),
    EventPerk(id:"time_warp",    name:"TIME WARP",    description:"Boss süre çalma etkisi -1 sn",      iconName:"clock.badge.minus",tier:1, effect:.bossResist),
    EventPerk(id:"double_tap",   name:"DOUBLE TAP",   description:"İlk blok yerleşimde puan 2x",       iconName:"hand.tap.fill",    tier:1, effect:.firstPlaceBonus),
    EventPerk(id:"iron_grip",    name:"IRON GRIP",    description:"Kilitli hücre açma +1/round",       iconName:"lock.open.fill",   tier:1, effect:.unlockBonus),
    EventPerk(id:"ghost_trace",  name:"GHOST TRACE",  description:"Ghost preview daha uzun görünür",   iconName:"wand.and.stars",   tier:1, effect:.ghostExtend),
    EventPerk(id:"combo_chain",  name:"COMBO CHAIN",  description:"Combo düşmesi 1 round gecikir",     iconName:"link",             tier:1, effect:.comboDelay),
]
```

### EventSessionState — Oyun Sırasında Tutulan State

```swift
// Models/EventSessionState.swift

struct EventSessionState {
    var currentRound:    Int = 1
    var totalScore:      Int = 0
    var goldEarned:      Int = 0
    var lives:           Int = 3
    var activePerks:     [EventPerk] = []       // seçilen perkler
    var pendingPerkChoice: [EventPerk]? = nil   // 3'lü perk seçim ekranı için
    var bossIntentIndex: Int = 0                // hangi intent sırada
    var nextPerkRound:   Int = 5                // bir sonraki perk round'u (5, 10, 15...)
    var metricValue:     Int = 0                // ranking metric sayacı (zone count vb.)

    // Her round bitişinde çağrılır
    mutating func advanceRound() {
        currentRound += 1
        if currentRound % 5 == 0 {
            // perk seçim tetikle
            pendingPerkChoice = EventPerkPool.drawThree(excluding: activePerks.map(\.id))
        }
        if currentRound % 3 == 0 {
            // boss intent tetikle
            bossIntentIndex = (bossIntentIndex + 1) % currentEvent.boss.intents.count
        }
    }
}
```

---

## 2. VIEWMODEL

### EventGameViewModel

```swift
// ViewModels/EventGameViewModel.swift
// GameViewModel'den inherit ETME — composition kullan, bağımsız tut

class EventGameViewModel: ObservableObject {

    // ── State ──────────────────────────────────────────────────────────────
    @Published var session:         EventSessionState = EventSessionState()
    @Published var showPerkChoice:  Bool = false
    @Published var currentBossAnim: BossIntentType? = nil  // animasyon tetikleyici
    @Published var leaderboard:     [EventLeaderboardEntry] = []
    @Published var isGameOver:      Bool = false

    let config: EventConfig

    // ── Init ───────────────────────────────────────────────────────────────
    init(config: EventConfig) {
        self.config = config
        applyModifiers(config.modifiers)
    }

    // ── Modifier uygulama ──────────────────────────────────────────────────
    private func applyModifiers(_ modifiers: [EventModifier]) {
        for mod in modifiers {
            switch mod.type {
            case .blockSpeedMultiplier:
                // BlockDropEngine.shared.speedMultiplier = mod.value
                break
            case .goldPerLineClear:
                // ScoreEngine.shared.eventGoldBonus = Int(mod.value)
                break
            case .infiniteTime:
                // TimeManager.shared.isInfinite = true
                break
            default:
                break
            }
        }
    }

    // ── Round bitti ────────────────────────────────────────────────────────
    func onRoundComplete(score: Int, metric: Int) {
        session.totalScore += score
        session.metricValue += metric
        session.advanceRound()

        if session.pendingPerkChoice != nil {
            showPerkChoice = true
        }

        triggerBossIntentIfNeeded()
        submitScoreToLeaderboard()
    }

    // ── Perk seçildi ───────────────────────────────────────────────────────
    func selectPerk(_ perk: EventPerk) {
        session.activePerks.append(perk)
        session.pendingPerkChoice = nil
        showPerkChoice = false
        applyPerkEffect(perk)
        HapticManager.shared.trigger(.success)
    }

    // ── Boss intent tetikle ────────────────────────────────────────────────
    private func triggerBossIntentIfNeeded() {
        guard session.currentRound % config.boss.intentCycle == 0 else { return }
        let intent = config.boss.intents[session.bossIntentIndex % config.boss.intents.count]
        currentBossAnim = intent.type
        executeBossIntent(intent)
        GameViewModel.addPopup("BOSS: \(intent.description)", type: .warning)
        HapticManager.shared.trigger(.heavy)
    }

    private func executeBossIntent(_ intent: BossIntent) {
        switch intent.type {
        case .lockCells:
            // BoardViewModel.shared.lockRandomCells(count: intent.value)
            break
        case .stealTime:
            // EventScoreEngine.applyTimePenalty(seconds: intent.value)
            break
        case .blockTray:
            // TrayViewModel.shared.lockFor(rounds: intent.value)
            break
        case .addJunkRow:
            // BoardViewModel.shared.addJunkRow()
            break
        default:
            break
        }
    }

    // ── Perk efekti uygula ─────────────────────────────────────────────────
    private func applyPerkEffect(_ perk: EventPerk) {
        // Mevcut PerkEngine üzerinden: PerkEngine.shared.activate(perk.id)
    }

    // ── Canlı sıralama ────────────────────────────────────────────────────
    func submitScoreToLeaderboard() {
        // EventLeaderboardService.shared.submit(
        //   eventId: config.id,
        //   score: session.totalScore,
        //   metric: session.metricValue
        // )
    }

    func fetchLeaderboard() async {
        // leaderboard = await EventLeaderboardService.shared.fetch(eventId: config.id)
    }
}
```

---

## 3. VIEW KATMANI

### EventsView — Ana Ekran (Daily / Weekly Tab)

```swift
// Views/Events/EventsView.swift

struct EventsView: View {
    @StateObject var vm = EventsViewModel()
    @State private var selectedTab: EventType = .daily

    var body: some View {
        ZStack {
            Color(hex: "#0a0e1a").ignoresSafeArea()

            VStack(spacing: 0) {
                // Topbar
                EventsTopBarView()

                // Tab seçici
                EventTabSelector(selected: $selectedTab)

                // İçerik
                ScrollView(showsIndicators: false) {
                    if selectedTab == .daily {
                        EventDailyPanel(event: vm.dailyEvent)
                    } else {
                        EventWeeklyPanel(event: vm.weeklyEvent)
                    }
                }
            }
        }
        .task { await vm.fetchEvents() }
    }
}
```

### EventDetailView — Event Hero Kartı

```swift
// Views/Events/EventDetailView.swift

struct EventDetailView: View {
    let event: EventConfig
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Event başlık + süre sayacı
            EventHeroCard(event: event)

            // Boss bilgisi
            EventBossCard(boss: event.boss)

            // Aktif modifier'lar
            EventModifiersRow(modifiers: event.modifiers)

            // Ödül tablosu
            EventRewardsRow(rewards: event.rewards)

            // Event'e özel karakter (weekly'de)
            if let char = event.character {
                EventCharacterCard(character: char)
            }

            // Giriş butonu
            Button("BAŞLA →") {
                isPresented = false
                // EventGameCoordinator.shared.start(event: event)
            }
            .font(.pixel(8))
            .foregroundColor(ThemeColors.neonCyan)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(hex: "#0d1a2e"))
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6)
                .stroke(ThemeColors.neonCyan, lineWidth: 1.5))
            .padding(.horizontal, 14)
            .padding(.bottom, 24)
        }
    }
}
```

### EventGameView — Oyun Ekranı

```swift
// Views/Events/EventGameView.swift
// GameView ile aynı yapı — sadece event overlay'leri eklenir

struct EventGameView: View {
    @StateObject var vm: EventGameViewModel

    var body: some View {
        ZStack {
            // Ana oyun alanı (mevcut GameView içeriği)
            EventGameBoardView(vm: vm)

            // Boss sabotaj animasyonu
            if let intent = vm.currentBossAnim {
                BossIntentOverlay(intent: intent)
                    .transition(.scale.combined(with: .opacity))
            }

            // Perk seçim sheet (her 5 roundda)
            if vm.showPerkChoice, let perks = vm.session.pendingPerkChoice {
                PerkChoiceOverlay(perks: perks, onSelect: vm.selectPerk)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: vm.showPerkChoice)
        .animation(.easeOut(duration: 0.2), value: vm.currentBossAnim != nil)
    }
}
```

### EventGameHUDView — Event'e Özel HUD

```swift
// Views/Events/EventGameHUDView.swift
// Mevcut GameView HUD'una ek olarak gösterilir

struct EventGameHUDView: View {
    @ObservedObject var vm: EventGameViewModel

    var body: some View {
        HStack(spacing: 6) {
            // Round sayacı
            HUDBox(label: "ROUND", value: "\(vm.session.currentRound)", color: ThemeColors.neonCyan)

            // Toplam puan
            HUDBox(label: "PUAN", value: vm.session.totalScore.formatted(), color: .white)

            // Altın (event modifier varsa göster)
            if vm.config.modifiers.contains(where: { $0.type == .goldPerLineClear }) {
                HUDBox(label: "ALTIN", value: "\(vm.session.goldEarned)", color: ThemeColors.gold)
            }

            // Can
            HUDBox(label: "CAN", value: String(repeating: "♥", count: vm.session.lives), color: Color(hex: "#44dd88"))

            // Sonraki perk round'u
            let roundsLeft = vm.session.nextPerkRound - vm.session.currentRound
            HUDBox(label: "PERK", value: "+\(roundsLeft)", color: ThemeColors.gold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}
```

### PerkChoiceOverlay — 3'lü Perk Seçimi

```swift
// Views/Events/PerkChoiceOverlay.swift

struct PerkChoiceOverlay: View {
    let perks: [EventPerk]
    let onSelect: (EventPerk) -> Void

    @State private var selected: EventPerk? = nil

    var body: some View {
        // Arka plan karart
        Color.black.opacity(0.75).ignoresSafeArea()

        VStack(spacing: 16) {
            // Başlık
            VStack(spacing: 4) {
                Text("ROUND TAMAMLANDI")
                    .font(.pixel(7))
                    .foregroundColor(ThemeColors.gold)
                Text("Bir perk seç")
                    .font(.pixel(5))
                    .foregroundColor(Color(hex: "#665533"))
            }

            // Perk kartları
            HStack(spacing: 10) {
                ForEach(perks) { perk in
                    PerkChoiceCard(perk: perk, isSelected: selected?.id == perk.id)
                        .onTapGesture {
                            selected = perk
                            HapticManager.shared.trigger(.light)
                        }
                }
            }
            .padding(.horizontal, 14)

            // Seç butonu
            Button("SEÇ VE DEVAM ET →") {
                if let sel = selected { onSelect(sel) }
            }
            .font(.pixel(7))
            .foregroundColor(selected == nil ? Color(hex: "#334") : ThemeColors.neonCyan)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(selected == nil ? Color(hex: "#0a0e1a") : Color(hex: "#0d1a2e"))
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6)
                .stroke(selected == nil ? Color(hex: "#1a2040") : ThemeColors.neonCyan, lineWidth: 1.5))
            .padding(.horizontal, 14)
            .disabled(selected == nil)
        }
        .padding(.vertical, 28)
        .background(Color(hex: "#0d1120"))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}

struct PerkChoiceCard: View {
    let perk: EventPerk
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            // Tier badge
            Text("T\(perk.tier)")
                .font(.pixel(4))
                .foregroundColor(Color(hex: "#44aa66"))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color(hex: "#002a10"))
                .cornerRadius(2)
                .frame(maxWidth: .infinity, alignment: .trailing)

            // İkon (SF Symbol)
            Image(systemName: perk.iconName)
                .font(.system(size: 22))
                .foregroundColor(isSelected ? ThemeColors.gold : Color(hex: "#445566"))

            // İsim
            Text(perk.name)
                .font(.pixel(5))
                .foregroundColor(isSelected ? ThemeColors.gold : .white)
                .multilineTextAlignment(.center)

            // Açıklama
            Text(perk.description)
                .font(.pixel(4))
                .foregroundColor(Color(hex: "#665533"))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color(hex: "#1a1600") : Color(hex: "#0d1120"))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? ThemeColors.gold : Color(hex: "#1e2a40"), lineWidth: isSelected ? 1.5 : 1)
        )
    }
}
```

### EventLeaderboardView — Canlı Sıralama

```swift
// Views/Events/EventLeaderboardView.swift

struct EventLeaderboardView: View {
    @ObservedObject var vm: EventGameViewModel
    let myDeviceID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Başlık
            HStack {
                Text("GÜNLÜK SIRA")
                    .font(.pixel(7))
                    .foregroundColor(Color(hex: "#aac"))
                Spacer()
                // Canlı güncelleme göstergesi
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: "#ff4444"))
                        .frame(width: 5, height: 5)
                    Text("CANLI")
                        .font(.pixel(5))
                        .foregroundColor(Color(hex: "#ff6666"))
                }
            }
            .padding(.horizontal, 14)

            // Top 3
            ForEach(vm.leaderboard.prefix(3)) { entry in
                EventLeaderboardRow(entry: entry, isMe: entry.deviceID == myDeviceID)
            }

            // Ayraç
            if let myEntry = vm.leaderboard.first(where: { $0.deviceID == myDeviceID }),
               (myEntry.rank ?? 999) > 3 {
                SeparatorView()
                EventLeaderboardRow(entry: myEntry, isMe: true)
            }
        }
    }
}

struct EventLeaderboardEntry: Identifiable {
    let id:       String
    let deviceID: String
    let username: String
    let score:    Int
    let metric:   Int    // ranking metric değeri
    var rank:     Int?
}
```

### BossIntentOverlay — Boss Sabotaj Animasyonu

```swift
// Views/Events/BossIntentOverlay.swift

struct BossIntentOverlay: View {
    let intent: BossIntentType

    var title: String {
        switch intent {
        case .lockCells:    return "BOSS: 3 HÜCRE KİLİTLENDİ!"
        case .stealTime:    return "BOSS: 10 SANİYE ÇALINDI!"
        case .blockTray:    return "BOSS: TRAY 2 ROUND KİLİTLİ!"
        case .addJunkRow:   return "BOSS: ÇÖP SATIRI EKLENDİ!"
        case .shuffleBoard: return "BOSS: TAHTA KARIŞTIRILDI!"
        case .invertControls: return "BOSS: KONTROLLER TERS!"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundColor(Color(hex: "#ff4444"))
            Text(title)
                .font(.pixel(7))
                .foregroundColor(Color(hex: "#ff6666"))
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(Color(hex: "#1a0808"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color(hex: "#ff444455"), lineWidth: 1.5))
        .padding(.horizontal, 30)
    }
}
```

---

## 4. ÖRNEK EVENT TANIMLARI

```swift
// Data/SampleEvents.swift

// ─── DAILY: Speed Demon ───────────────────────────────────────────────────
let dailySpeedDemon = EventConfig(
    id:           "daily_2026_05_13",
    type:         .daily,
    title:        "SPEED DEMON",
    description:  "Bloklar 2x hızlı düşer, her satır +50 Altın",
    startsAt:     Calendar.current.startOfDay(for: Date()),
    endsAt:       Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400),
    modifiers: [
        EventModifier(id:"speed",   type:.blockSpeedMultiplier, value:2.0,  description:"2x HIZ",        iconName:"bolt.fill"),
        EventModifier(id:"gold",    type:.goldPerLineClear,     value:50,   description:"+50 ALTIN/SATIR",iconName:"bitcoinsign.circle"),
        EventModifier(id:"infinite",type:.infiniteTime,         value:0,    description:"SINIRSIZ",       iconName:"infinity"),
    ],
    boss: EventBoss(
        id:          "chrono_wraith",
        name:        "CHRONO WRAITH",
        description: "Süre çalar, hücreleri kilitler",
        spriteKey:   "boss_chrono",
        intents: [
            BossIntent(id:"lock",  type:.lockCells,  value:3, description:"3 hücreyi kilitler"),
            BossIntent(id:"steal", type:.stealTime,  value:10,description:"10 sn süre çalar"),
            BossIntent(id:"tray",  type:.blockTray,  value:2, description:"Tray 2 round kilitli"),
        ],
        intentCycle: 3
    ),
    character:     nil,
    rewards: [
        EventReward(id:"r1", rankFrom:1,   rankTo:1,   diamonds:500, gold:200, perkUnlock:nil,          label:"1. SIRADA"),
        EventReward(id:"r2", rankFrom:2,   rankTo:10,  diamonds:200, gold:100, perkUnlock:nil,          label:"TOP 10"),
        EventReward(id:"r3", rankFrom:11,  rankTo:100, diamonds:100, gold:50,  perkUnlock:nil,          label:"TOP 100"),
        EventReward(id:"r4", rankFrom:101, rankTo:999, diamonds:10,  gold:0,   perkUnlock:"speed_perk", label:"KATILIM"),
    ],
    rankingMetric: .score
)

// ─── WEEKLY: Zone Master League ──────────────────────────────────────────
let weeklyZoneMaster = EventConfig(
    id:           "weekly_2026_W20",
    type:         .weekly,
    title:        "ZONE MASTER LEAGUE",
    description:  "7 gün boyunca en fazla zone temizle",
    startsAt:     /* haftanın başlangıcı */Date(),
    endsAt:       /* haftanın bitişi */Date().addingTimeInterval(604800),
    modifiers: [
        EventModifier(id:"infinite",type:.infiniteTime,      value:0,   description:"SINIRSIZ",      iconName:"infinity"),
        EventModifier(id:"zone",    type:.scoreMultiplier,   value:1.5, description:"ZONE x1.5",     iconName:"scope"),
    ],
    boss: EventBoss(
        id:          "grid_titan",
        name:        "GRID TITAN",
        description: "Köşe zone'larını kilitler",
        spriteKey:   "boss_grid_titan",
        intents: [
            BossIntent(id:"corners", type:.lockCells,   value:4, description:"Köşe hücreler kilitlendi"),
            BossIntent(id:"junk",    type:.addJunkRow,  value:1, description:"Çöp satırı eklendi"),
            BossIntent(id:"shuffle", type:.shuffleBoard,value:5, description:"5 blok yer değiştirdi"),
        ],
        intentCycle: 5
    ),
    character: EventCharacter(
        id:           "grid_phantom",
        name:         "GRID PHANTOM",
        description:  "Zone temizlemede +%30 puan, weekly exclusive",
        spriteKey:    "char_grid_phantom",
        isExclusive:  true,
        bonusModifiers:[
            EventModifier(id:"zone_bonus",type:.scoreMultiplier,value:1.3,description:"ZONE +30%",iconName:"scope"),
        ]
    ),
    rewards: [
        EventReward(id:"w1", rankFrom:1,  rankTo:1,   diamonds:1000,gold:500, perkUnlock:"grid_phantom_unlock", label:"ŞAMPIYON"),
        EventReward(id:"w2", rankFrom:2,  rankTo:10,  diamonds:500, gold:200, perkUnlock:nil,                   label:"TOP 10"),
        EventReward(id:"w3", rankFrom:11, rankTo:100, diamonds:200, gold:100, perkUnlock:nil,                   label:"TOP 100"),
        EventReward(id:"w4", rankFrom:101,rankTo:999, diamonds:50,  gold:0,   perkUnlock:nil,                   label:"KATILIM"),
    ],
    rankingMetric: .zoneCount
)
```

---

## 5. DOSYA YAPISI

```
Block-Jack/Modules/Events/
├── EventsView.swift               ← ana ekran, daily/weekly tab
├── EventDailyPanel.swift          ← günlük event paneli
├── EventWeeklyPanel.swift         ← haftalık event paneli
├── EventDetailView.swift          ← event hero kartı + boss + ödüller
├── EventGameView.swift            ← event oyun ekranı
├── EventGameViewModel.swift       ← event oyun state yönetimi
├── EventGameHUDView.swift         ← event'e özel HUD (round, altın vs)
├── PerkChoiceOverlay.swift        ← 3'lü perk seçim ekranı
├── PerkChoiceCard.swift           ← tekil perk kartı
├── EventLeaderboardView.swift     ← canlı sıralama şeridi
├── BossIntentOverlay.swift        ← boss sabotaj animasyon overlay'i
└── EventsTopBarView.swift         ← topbar

Block-Jack/Data/Models/
├── EventConfig.swift
├── EventModifier.swift
├── EventBoss.swift
├── EventCharacter.swift
├── EventReward.swift
├── EventPerk.swift
└── EventSessionState.swift

Block-Jack/Data/
└── SampleEvents.swift             ← örnek event tanımları (dev/test için)
```

---

## 6. GAME LOOP — EVENT AKIŞ ŞEMASI

```
EventsView
  │
  ├─ Karta tıkla → EventDetailView (sheet)
  │                    │
  │                    └─ "BAŞLA" → EventGameView açılır
  │
  └─ EventGameView
        │
        ├─ Round başlar
        │     └─ Bloklar modifier'lara göre düşer (2x hız vs.)
        │
        ├─ Round biter (satır/zone temizlendi)
        │     ├─ onRoundComplete() çağrılır
        │     ├─ Boss intent tetiklenir mi? (round % intentCycle == 0)
        │     │     └─ Evet → BossIntentOverlay göster + tahta sabote et
        │     │
        │     └─ Perk sunulacak mı? (round % 5 == 0)
        │           └─ Evet → PerkChoiceOverlay göster (3 perk)
        │                 └─ Oyuncu seçer → perk aktif olur → oyun devam eder
        │
        ├─ Can bitince → EventGameOver ekranı
        │     ├─ Final skor + sıra gösterilir
        │     ├─ Kazanılan ödüller gösterilir
        │     └─ "Tekrar Oyna" / "Çıkış"
        │
        └─ Skor her round sonunda EventLeaderboardService'e gönderilir
```

---

## 7. PERFORMANS KURALLARI (Mevcut Standartlarla Uyumlu)

> Projenin mevcut performans kuralları burada da geçerlidir:

1. `EventGameViewModel.dragLocation` **asla @Published olmamalı** — mevcut `GameView` kuralının aynısı.
2. Boss intent overlay animasyonları `withAnimation` içinde tetiklenir, doğrudan state mutation yapılmaz.
3. `EventLeaderboardView` polling için `Timer.publish` kullanır, `Task { while true { } }` kullanılmaz.
4. Perk havuzu `EventPerkPool.drawThree()` her çağrıda yeni bir array oluşturmaz — `reservoirSample` algoritması kullanılır.
5. `EventSessionState` struct'tır (value type) — `@Published` ile VM içinde tutulur, ekstra ObservableObject açılmaz.

---

## 8. ENTEGRASYON NOTLARI

- Backend entegrasyonu bu fazda yapılmıyor. `EventLeaderboardService` ve `EventConfigService` mock data ile çalışır.
- `EventConfig` lokal JSON dosyasından okunur (`Events/daily.json`, `Events/weekly.json`).
- Backend hazır olduğunda sadece servis katmanı güncellenir — View ve ViewModel değişmez.
- `RunManager` ve mevcut `GameViewModel`'e hiç dokunulmaz.

---

> Bu dökümanı Cursor'a ver ve şunu söyle:
> *"Mevcut GameViewModel ve RunManager'a dokunma. Sadece Events/ modülünü bu dokümana göre oluştur."*
