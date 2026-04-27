# Block-Jack — TODO

> Son güncelleme: **2026-04-24**


## 🚨 Kritik — Kayıt Sistemi (Save/Load) & Yaşam Döngüsü Açıkları

### 11) Arka Plana Atıldığında Otomatik Kayıt Yokluğu (ScenePhase)
- **Sorun:** Savaş ortasında uygulama arka plana atılıp iOS tarafından sonlandırılırsa tahta (grid) ve süre durumu kaybediliyor. Oyuncu o anki ilerlemesini yitiriyor.
- **Hedef:** `GameView` içine `@Environment(\.scenePhase)` ekleyerek, `.inactive` veya `.background` durumunda oyunu otomatik duraklatıp (`vm.pauseGame()`) anında `vm.saveGameState()` fonksiyonunu çağırmak.
- **Nerede:** `GameView.swift`

### 12) Altın İstismarı (Savescumming) ve Sınırsız Altın Bug'ı
- **Sorun:** Oyun içinde kazanılan altınlar (`addRunGold`), anında `SaveManager` ile kalıcı cüzdana yazılıyor. Oyuncu savaştayken altın kazanıp oyunu zorla (force quit) kapatırsa, harita ilerlemediği için aynı savaşı baştan oynayıp aynı altını defalarca kazanabiliyor (sınırsız altın açığı). Aynı zamanda ölmeden önce çıkıp can (Life) kaybını önleyebiliyor.
- **Hedef:** Savaş sırasında kazanılan altınlar "pending (bekleyen)" olarak tutulmalı ve sadece savaş bittiğinde diske yazılmalı. Veya yarım bırakılmış oyundan çıkıp tekrar aynı yere girme istismarını önlemek için düğümler (Node) kilitlenmeli.
- **Nerede:** `GameViewModel.swift` (`addRunGold` ve `saveGameState` fonksiyonları)

### 13) Yarım Kalan Savaşın Farklı Düğüme Taşınması (State Leak)
- **Sorun:** `SaveManager`, savaş grid'ini (`slot.grid`) diskte tutuyor ancak bu grid'in hangi Node'a ait olduğunu kaydetmiyor. Oyuncu Node A'da oyunu kapatıp haritada Node B'ye tıklarsa, Node A'nın yarım kalan tahtası Node B'ye yükleniyor.
- **Hedef:** `SaveSlot`'a `activeBattleNodeId: UUID?` eklenmeli. `GameViewModel` başlatılırken bu ID kontrol edilmeli; eğer girilen Node ID'siyle eşleşmiyorsa eski tahta (grid) temizlenmeli.
- **Nerede:** `SaveModels.swift`, `SaveManager.swift`, `GameViewModel.swift`
