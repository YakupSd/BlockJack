# Block-Jack — Açık Görevler

> Slot Hub refactor + clear hint + achievements bitimi sonrası açık kalan iş
> kalemleri. Sıralama önerisiyle; yukarıdan başlayarak al.
>
> Son güncelleme: 2026-04-21

---

## 🔴 Yüksek Öncelik — UX Bütünlüğü

### ~~1. MapView / GameView "Ana Menü" butonları Hub'a dönsün~~ ✅ (2026-04-22)
- **Çözüm:** `MainViewsRouter`'a `popToSlotHub(slotId:)` helper'ı eklendi.
  Run bağlamındaki tüm "Ana Menü" aksiyonları Hub'a yönlendirildi:
  - `MapView` üst-sol "ANA MENÜ" butonu
  - `GameHUDComponents.TopHUDBar` HOME (ev) butonu
  - `GameOverlays.GameOverOverlay` "ANA MENÜYE DÖN" (run bitti) ve "PES ET"
  - `GameOverlays.PauseOverlay` "KAYDET VE ÇIK"
- **Stack davranışı:** `setViewControllers([Dashboard, Hub])` ile stack
  iki seviyeye reset ediliyor; böylece Hub'daki "SLOT" butonu Dashboard'a
  temiz şekilde düşüyor, geri-gesture AppStartView'i diriltmiyor.

### 2. Merchant / Treasure shop başlıklarına slot rozeti
- **Neden:** `UpgradesView`'a eklediğimiz "SLOT N" rozetini tüm shop
  ekranlarına taşıyarak tutarlılık sağlamak.
- **Nerede:** `MerchantView.swift`, `TreasureRoomView.swift`
- **Nasıl:** `UpgradesView`'daki başlık VStack pattern'ını kopyala
  (`SLOT \(slotId)` rozeti).
- **Tahmin:** ~15 dk

### 3. Tutorial / onboarding akışı
- **Neden:** Yeni oyuncu ilk açışta hiçbir şey anlatılmıyor — overdrive,
  perk, boss, shape sınıflandırması için hız tanıtımı yok.
- **Nerede:** Yeni dosya: `Modules/Onboarding/TutorialView.swift` (veya
  in-game overlay)
- **Nasıl:** En basit haliyle 3-4 adım "tek tıkla geç" tooltip. Splash
  sonrası `userEnv.hasSeenTutorial` flag'ine göre tetiklensin. Ayrıca
  ilk kez Hub'a girince 2 saniyelik spotlight tooltip.
- **Tahmin:** 2-3 saat (tasarıma göre değişir)

### 4. Pause menu ikinci sürümü
- **Neden:** Oyun sırasında duraklatma ekranının durumunu denetle — müzik
  kapatma, çıkış (Hub'a dön), settings erişimi, "cayır cayır" yeniden
  başlatma olabilir.
- **Nerede:** `GameView.swift` pause overlay'i
- **Nasıl:** Önce mevcut pause overlay'ine bak; eksik aksiyonları ekle,
  layout'u overflow'dan koru (AdaptiveOverlayLayout wrapper zaten var).
- **Tahmin:** 1 saat

---

## 🟡 Orta Öncelik — İçerik & Polish

### 5. World 3-5 için özel background temaları
- **Neden:** Şu an sadece W1 (Neon Cyber) + W2 (Concrete Ruins) var. W3
  (Candy Lab), W4 (Deep Abyss), W5 (Core Singularity) neon fallback'te.
- **Nerede:** Yeni dosyalar: `WorldMapCandyBackground.swift`,
  `WorldMapAbyssBackground.swift`, `WorldMapCoreBackground.swift`
- **Nasıl:** `WorldMapConcreteBackground` pattern'ını kopyala, paleti
  değiştir (`ThemeColors` içinde w3/w4/w5 tonları tanımla), `themedBackground`
  switch'ini genişlet.
- **Tahmin:** Her biri 1-2 saat (toplam 4-6 saat)

### 6. Kalan Turkish-only metinler için localization sweep
- **Neden:** Boss dialogları, bazı perk açıklamaları, karakter aktif/pasif
  açıklamaları hâlâ `localizedString` kullanmıyor olabilir.
- **Nerede:** `BossRegistry.swift` dialogue, `PerkEngine.swift` descriptions,
  `GameCharacter.roster` passive/active desc, `SaveModels.swift` lore
- **Nasıl:** Grep ile hardcoded TR metinleri bul (ör. "ğ|ş|ı|ö|ü"
  filtreleriyle), her birini EN karşılığıyla `localizedString` içine
  sararak çevir.
- **Tahmin:** 1-2 saat

### 7. İlk kurulum sonrası Hub tanıtımı
- **Neden:** Yeni slot → Karakter → Perk → **Map** yerine **Hub** üzerinden
  geçmek. Menüyü kullanıcıya tanıtır.
- **Nerede:** `PerkSelectionView.swift` "OYUNA BAŞLA" action
- **Nasıl:** İki seçenek:
  - A) `pushToWorldMap` yerine `pushToSlotHub` ile Hub'a düşür, kullanıcı
    "SEFERE BAŞLA" butonuna kendisi basar.
  - B) Direkt Map'e gitsin ama Hub'a ilk kez girildiğinde spotlight tooltip
    göster.
- **Tahmin:** 30 dk (A), 1.5 saat (B)

### 8. Achievement unlock toast/banner
- **Neden:** Şu an unlock olunca sadece ses çalıyor. Görsel feedback yok.
- **Nerede:** `UserEnvironment.reportAchievement` + yeni bir
  `Modules/Overlays/AchievementToastView.swift`
- **Nasıl:** Unlock anında üstten düşen toast ("🏆 Başarı açıldı: Boss
  Avcısı +500 altın"), Galeri buton/pill'inde bildirim noktası. Bir
  `@Published var pendingAchievementToast: Achievement?` eklenir;
  root'taki view bunu dinler.
- **Tahmin:** 1-1.5 saat

### 9. Shape balance QA
- **Neden:** Yeni shape'lerden sonra rarity/frekans dağılımı oyunun
  zorluğunu etkiliyor.
- **Nerede:** `GameBlock.swift` `generate*` / rarity dağılımı
- **Nasıl:** Her run'da hangi shape'lerin kaç kez çıktığını logla
  (geçici debug print). 5-10 run oyna, dağılımı gör, gerekirse weight'leri
  ayarla.
- **Tahmin:** 1-2 saat

---

## 🟢 Düşük Öncelik — Uzun Vade

### 10. iCloud save + Game Center
- **Neden:** Save slotlar şu an cihaza bağlı; çoklu cihaz sync yok.
  Global leaderboard yok.
- **Nerede:** `SaveManager.swift`, yeni `GameCenterManager.swift`
- **Nasıl:** NSUbiquitousKeyValueStore ile slot senkronu + GKLeaderboard
  ile global skor + GKAchievement ile achievement mirror.
- **Tahmin:** 1-2 gün (test dahil)

### 11. Accessibility
- **Neden:** VoiceOver, dynamic type, renk-körü paletleri yok.
- **Nerede:** Tüm `Canvas` çizimli viewlar (grid, HUD), stat textleri
- **Nasıl:** `.accessibilityLabel`, `.accessibilityValue`, `.dynamicTypeSize`
  kısıtları, renk-körü modunda neonlar yerine desen ekle.
- **Tahmin:** 1 gün

### 12. Telemetri / analytics
- **Neden:** Dengeleme için veri yok — hangi bölüm kaç çöküşte biter,
  hangi perk popüler, boss yenilme oranları?
- **Nerede:** Yeni `Data/Services/TelemetryService.swift`
- **Nasıl:** Firebase Analytics veya Aptabase gibi hafif bir SDK. Event'ler:
  `run_start`, `run_end`, `boss_encounter`, `boss_defeated`, `perk_pick`,
  `shop_purchase`, `daily_claim`.
- **Tahmin:** 4-6 saat

### 13. Ses mixing pass
- **Neden:** SFX seviyeleri arası tutarsızlık; müzik savaş sırasında
  kalıyor tam güçte.
- **Nerede:** `AudioManager.swift`
- **Nasıl:** SFX'leri yeniden normalize et (dB seviyeleri), combat
  sırasında music'i `-6 dB duck` uygula, overdrive aktifken filtre
  ekle (LPF/HPF).
- **Tahmin:** 2-3 saat

### 14. Galeri → Lore sekmesi
- **Neden:** Dünya hikayesi / boss biyografileri `EXPANSION_ROADMAP.md`'de
  taslak var ama oyunda sunulmuyor.
- **Nerede:** `CollectionMainView.swift` + yeni `LoreEngine.swift`
  veya `MapModels.swift` içinde `WorldLore` struct
- **Nasıl:** Her dünya için giriş paragrafı, her boss için kısa biyografi.
  Keşfedildikçe açılır (spoiler free).
- **Tahmin:** 3-4 saat (yazı + UI)

---

## İş Oturumu Önerisi — "Polish Pass"

Bir oturumda birlikte ele alırsa temiz sonuç veren küme:

> **Paket A — Hub tamamlama** (~2 saat)
> - #1 MapView/GameView → Hub dönüş
> - #2 Merchant/Treasure slot rozeti
> - #7A PerkSelection sonrası Hub'a düşüş

> **Paket B — Retention feedback** (~2 saat)
> - #8 Achievement toast
> - #3 (minimum) Splash sonrası 3 adım tutorial

> **Paket C — Dünya içerikleri** (~1 gün)
> - #5 W3/W4/W5 backgroundlar
> - #6 Localization sweep

---

## Notlar

- Bu dosyayı iş bittikçe güncelle; tamamlananı ✅ olarak işaretle veya sil.
- Yeni görevler çıkarsa alt bölüme ekle; önceliğini renk emoji ile belirt.
- Her maddenin yanındaki "Nerede" kısmı doğrudan tıklanabilir dosya yolu
  olmasa da referans için tut.
