# 🌍 Localization Migration TODO List

This file tracks the systematic, step-by-step page-by-page migration of all old-style `userEnv.localizedString(...)` calls to modern, computed properties inside `UserEnvironment.swift`.

---

## 🛠️ General Migration Strategy
1. **Identify**: Find all `userEnv.localizedString("TR", "EN")` calls in the view.
2. **Exhaustive Extraction**: Define a computed property inside `UserEnvironment.swift` using prefix conventions:
   - `btn...` for Buttons
   - `label...` for Labels/Texts
   - `title...` for Titles
   - `msg...` for Alert/Status messages
   - `placeholder...` for text input placeholders
3. **Replace**: Swap in the view file to use `userEnv.propertyName`.
4. **Compile & Verify**: Run simulator builds regularly to ensure 100% type safety and stability.

---

## 📋 Module Checklist

### 1. 💬 Social Module (`Modules/Social`)
- [x] [ActiveDuelRow.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Social/ActiveDuelRow.swift)
- [x] [DuelGamePlayView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Social/DuelGamePlayView.swift)
- [x] [DuelResultsView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Social/DuelResultsView.swift)
- [x] [SocialView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Social/SocialView.swift)
- [x] [PendingDuelCard.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Social/PendingDuelCard.swift)
- [x] [DuelHistoryRow.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Social/DuelHistoryRow.swift)
- [x] [DuelDetailView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Social/DuelDetailView.swift)
- [x] [DuelCreateView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Social/DuelCreateView.swift)
- [x] [FriendRow.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Social/FriendRow.swift)

### 2. 🏪 Store Module (`Modules/Store`)
- [x] [StoreView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Store/StoreView.swift)

### 3. 📊 Career Module (`Modules/Career`)
- [x] [CareerView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Career/CareerView.swift)
- [x] [CareerStatsView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Career/CareerStatsView.swift)
- [x] [CharacterStatsView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Career/CharacterStatsView.swift)
- [x] [PerkStatsView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Career/PerkStatsView.swift)
- [x] [TitlesAndAchievementsView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Career/TitlesAndAchievementsView.swift)

### 4. ⚔️ Upgrades Module (`Modules/Upgrades`)
- [x] [CharacterShopView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Upgrades/CharacterShopView.swift)
- [x] [UpgradesView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Upgrades/UpgradesView.swift)

### 5. 📅 Live Events Module (`Modules/Events`)
- [x] [EventsView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Events/EventsView.swift)
- [x] [EventDetailView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Events/EventDetailView.swift)
- [x] [EventGameView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Events/EventGameView.swift)

### 6. 🎮 Main Game Module (`Modules/Game`)
- [x] [EnemyHUDView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Game/EnemyHUDView.swift)
- [x] [AbilityManager.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Game/AbilityManager.swift)
- [x] [PassivePerkHUDView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Game/PassivePerkHUDView.swift)
- [x] [GameView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Game/GameView.swift)
- [x] [ScoringInfoView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Game/Overlays/ScoringInfoView.swift)
- [x] [RunSummaryView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Game/RunSummaryView.swift)
- [x] [GameOverlays.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Game/GameOverlays.swift)
- [x] [GameHUDComponents.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Game/GameHUDComponents.swift)
- [x] [BattleRewardView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Game/Overlays/BattleRewardView.swift)

### 7. 🗺️ Map Module (`Modules/Map`)
- [x] [WorldMapDetailSheet.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Map/WorldMapDetailSheet.swift)
- [x] [WorldSelectionView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Map/WorldSelectionView.swift)
- [x] [MapView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Map/MapView.swift)
- [x] [MysteryEventView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Map/NodeOverlays/MysteryEventView.swift)
- [x] [MerchantView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Map/NodeOverlays/MerchantView.swift)
- [x] [RestSiteView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Map/NodeOverlays/RestSiteView.swift)
- [x] [TreasureRoomView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Map/NodeOverlays/TreasureRoomView.swift)

### 8. 🏆 Leaderboard Module (`Modules/Leaderboard`)
- [x] [PlayerRegistrationView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Leaderboard/PlayerRegistrationView.swift)
- [x] [LeaderboardRowView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Leaderboard/LeaderboardRowView.swift)
- [x] [ExistingAccountLoginView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Leaderboard/ExistingAccountLoginView.swift)
- [x] [LeaderboardTabContent.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Leaderboard/LeaderboardTabContent.swift)

### 9. 🏠 Dashboard Module (`Modules/Dashboard`)
- [x] [DashboardView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Dashboard/DashboardView.swift)
- [x] [DailyRewardOverlay.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Dashboard/DailyRewardOverlay.swift)

### 10. ⚙️ PreGame, Collection, Settings & AppStart
- [x] [SlotHubView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/PreGame/SlotHubView.swift)
- [x] [CollectionMainView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Collection/CollectionMainView.swift)
- [x] [HowToPlayView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/Settings/HowToPlayView.swift)
- [x] [OnboardingLoginView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/AppStart/OnboardingLoginView.swift)
- [x] [AppStartView.swift](file:///Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Modules/AppStartView.swift)
