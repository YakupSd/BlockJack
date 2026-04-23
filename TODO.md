# Block-Jack — TODO

> Son güncelleme: **2026-04-24**

---

## 🔴 Kritik — Oyun Akışı Yeniden Tasarımı

### 1) "Save Slot" konseptini kaldır / modernize et
- **Sorun:** Kullanıcı uygulamayı açınca ilk gördüğü şey "Slot 1 / Slot 2 / Slot 3" — bu PC oyunu hissi veriyor, 14-28 yaş mobil oyuncusu için yabancı ve soğuk.
- **Hedef:** Slot yerine **karakter portreleri** göster ("Kim olarak oynuyorsun?")
- **Nerede:** `SaveSlotSelectionView.swift` → tamamen yeniden tasarla veya ana menüye entegre et

---

### 2) Ana Menü akışını modernize et
- **Sorun:** Geri dönen oyuncu 4-7 adım geçiyor, devam etmek için çok tıklama var.
- **Hedef yeni akış:**

  **İlk kez oynayan:**
  ```
  Ana Menü → Karakter Seç → OYNA  (2 adım)
  ```

  **Geri dönen oyuncu:**
  ```
  Ana Menü
    → [büyük] DEVAM ET  → Harita (1 adım, otomatik resume)
    → [küçük] Yeni Run  → Karakter Seç → OYNA
  ```

- **Nerede:** `AppStartView.swift`, `SaveSlotSelectionView.swift`, `SlotHubView.swift`

---

### 3) PerkSelectionView → SlotHub yerine WorldSelectionView'e yönlendir
- **Sorun:** "Oyuna Başla" tıklayınca SlotHub'a düşüyor, oradan tekrar "Sefere Başla" demen gerekiyor.
- **Değişiklik:**
  ```swift
  // ESKİ:
  MainViewsRouter.shared.pushToSlotHub(slotId: slotId)

  // YENİ:
  MainViewsRouter.shared.push(WorldSelectionView(slotId: slotId).environmentObject(UserEnvironment.shared))
  ```
- **Nerede:** `PerkSelectionView.swift` — startButton aksiyonu

---

### 4) RunSetupView'ı kaldır
- **Sorun:** Karakter + Perk başta seçiliyor, RunSetupView bunları **tekrar** seçtiriyor; WorldSelectionView de **tekrar** gösteriliyor. Tamamen gereksiz ekran.
- **İş:**
  - `SlotHubView` → `primaryActionButton` else bloğunu `RunSetupView` yerine `WorldSelectionView`'e yönlendir
  - `RunSetupView.swift` dosyasını sil veya `// DEPRECATED` olarak işaretle
- **Nerede:** `SlotHubView.swift`, `RunSetupView.swift`

---

### 5) Yeni oyuncu için World Selection'ı atla
- **Sorun:** İlk oyunda sadece World 1 açık. Boşu boşuna ekran gösteriliyor.
- **Hedef:** Sadece 1 world açıksa direkt o world'ün haritasına git, seçim ekranı gösterme.
- **Nerede:** `WorldSelectionView.swift` veya push eden yer — açık world sayısı 1 ise `pushToWorldMap(worldId: 1, slotId: slotId)` direkt çağır

---

### 6) Starting Perk konseptini run içine taşı
- **Sorun:** "Hangi dünyaya gideceğimi bilmeden perk mi seçiyorum?" — referans oyunlarda (Hades, Dead Cells) perk **run içinde** kazanılır, başlamadan önce değil.
- **Hedef:** `PerkSelectionView` ekranını kaldır. İlk perk'i run başında veya ilk level'dan sonra ver.
- **Etki:** Akış 1 adım daha kısalır: `Karakter Seç → OYNA → [ilk level sonrası perk seç]`
- **Nerede:** `PerkSelectionView.swift`, `CharacterSelectionView.swift`, `GameViewModel.swift`

---

### 7) CharacterSelectionView — Layout Bug
- **Sorun:** Karakter ikonlarının bir kısmı navigation bar altında kalıyor, görünmüyor.
- **Düzeltme:** `ScrollView` içindeki `HStack`'e yeterli `.padding(.top, ...)` ekle veya
  `VStack` üstüne safe area padding'i manuel ver.
- **Nerede:** `CharacterSelectionView.swift` — karakter listesi ScrollView

---

## 🟡 Orta Öncelik — Post-run Akış

### 8) Post-run yönlendirme kuralını tek standarda bağla
- **Kural:**
  - **RoundComplete** → `MapView`'e geri dön
  - **ChapterComplete** → `WorldMap`'e dön
  - **GameOver / Run bitti** → Ana Menü'ye dön (yeni akışa göre)
- **Nerede:** `GameView.swift`, `ChapterCompleteOverlay`, `GameOverOverlay`, `MainViewsRouter`

### 9) Run Summary ekranı
- **Amaç:** Run sonrası "ne kazandım / nereye geldim" hissi — modern roguelite standardı.
- **İçerik:** Skor, ulaşılan world, karakter, kazanılan altın, alınan perk sayısı
- **Nerede:** `SaveModels.swift`, `SaveManager.swift`, yeni `RunSummaryView.swift`

### 10) Boss Contract UX netliği
- **İş:**
  - Boss'a girince "CONTRACT ACTIVE" pill/banner
  - Boss bitince reward ekranında "Contract Bonus" etiketi
- **Nerede:** `WorldMapDetailSheet.swift`, `BattleRewardView.swift`
