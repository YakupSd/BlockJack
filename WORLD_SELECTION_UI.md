# WorldSelectionView — UI + Kod Dokümanı

Bu doküman, `WorldSelectionView` için UI spec’i ve projedeki uygulanmış kod noktalarını tek yerde toplar.

## Genel Amaç

- Oyuncu 5 dünya arasında seçim yapar (her dünya 20 level).
- Kilitli dünyaya tıklanınca yalnızca hafif haptic + shake olur.
- Açık dünyaya tıklanınca `WorldMapView` worldId ile açılır.

## Dosyalar

- `Block-Jack/Modules/Map/WorldSelectionView.swift`
- `Block-Jack/Modules/Map/WorldMapViewModel.swift` (worldId destekli)
- `Block-Jack/Utils/ThemeColors.swift` (`worldCardPalette(worldId:)`)
- `Block-Jack/Utils/Navigation/MainNavigation/MainNavigationView.swift`

## Data Model

`WorldSelectionView` içinde UI için bu model kullanılır:

```swift
struct WorldCardViewModel: Identifiable {
    let worldId: Int
    let title: String
    let levelRange: String
    let twist: String
    let icon: String
    let completedLevels: Int
    let totalLevels: Int
    let state: WorldState
    let palette: WorldCardPalette
}
```

World state:

```swift
enum WorldState { case active, completed, locked }
```

## Kilit Hesabı

Kural:

- Dünya \(i\) açık sayılırsa: `unlockedWorldLevel >= (i-1)*20 + 1`
- Dünya \(i\) tamamlandıysa: `unlockedWorldLevel > i*20`

UI tarafında `state` buna göre hesaplanır.

## Palette

`ThemeColors.worldCardPalette(worldId:)` dönüşü:

- World 1: bg `#0E1A2B`, accent `#00F5FF`
- World 2: bg `#1A1512`, accent `#A0522D`
- World 3: bg `#1A0D14`, accent `#FF6FA3`
- World 4: bg `#071419`, accent `#00FFCC`
- World 5: bg `#0D0A12`, accent `#9B59FF`

## Navigation

World seçimi:

```swift
MainViewsRouter.shared.pushToWorldMap(worldId: vm.worldId, slotId: slotId)
```

Router:

- `pushToWorldMap(worldId:slotId:)` eklendi.
- Mevcut `pushToWorldMap(slotId:)` backward-compatible kaldı.

## WorldMapViewModel — worldId desteği

- `WorldMapViewModel(slotId:worldId:userEnv:)`
- `generateLevels()` artık world range’i üretir:
  - start = `(worldId-1)*20+1`
  - end = `worldId*20`
- `buildLayout(worldId:)` local 1…20 layout’u absolute levelId’ye map eder.

## Animasyonlar

- İlk açılış: kartlar alt→üst `opacity + offset` ile stagger (0.05s delay).
- Kilitli tap: shake (±4pt, 3 tekrar).
- Açık tap: kart scale (0.97 → 1.0).

## Notlar / Genişletme

- Dünya başlıkları/twist metinleri şu an statik; ileride `LoreEngine` veya ayrı bir `WorldCatalog` ile data-driven yapılabilir.
- WorldMap’in background’ları zaten `WorldTheme` üzerinden seçiliyor; world selection sadece “hangi 20’lik blok” gösterilecek onu belirler.

