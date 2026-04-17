# 🕹️ BLOCK-JACK — Master Game Design Document (GDD)
### Version 1.0 · SwiftUI / Xcode · Roguelite Puzzle

---

## 1. OYUNUN RUHU VE KİMLİĞİ

| Alan | Detay |
|---|---|
| **Tür** | Roguelite Puzzle Strategy |
| **İlham** | Block Blast × Balatro × Hades |
| **Tema** | Minimalist Neon · Synthwave · Retro-Futuristik |
| **Platform** | iOS (SwiftUI + Xcode) |
| **Mimari** | MVVM + Service Pattern |

> [!NOTE]
> Oyunun ruhu, verdiğin her hamlenin hem anlık skor hem de uzun vadeli strateji (joker sinerjisi, renk yönetimi) açısından önemli hissettirmesidir. Balatro'daki gibi "Oh ya! Bu kombinasyon böyle çalışıyormuş!" anları.

---

## 2. TEMEL MEKANİKLER — The Core Loop

```
Blok Yerleştir ➔ Satır/Sütun Patlat ➔ Skor/Altın Kazan
        ↑                                        ↓
    Tekrar Dene ← Kalıcı Güçlen (Elmas) ← Öl (Can Bitti)
```

### 2.1 Izgara (Grid)
- **Boyut:** 8×8 dinamik grid → `[[GameCell]]` matrisi
- **Hücre Durumları:** `.empty`, `.filled(color:)`, `.locked`, `.heavy`
- **Snap-to-Grid:** `DragGesture` ile gerçek zamanlı önizleme ve yerleştirme

### 2.2 Blok Tipleri

| Tip | Açıklama | Nadir |
|---|---|---|
| I, L, O, T, S, Z | Standart Tetris şekilleri | Yaygın |
| 1×1 | Kurtarıcı küçük blok | Az |
| 3×3 | Riskli dev blok | Nadir |
| L-Mirror, S-Mirror | Ayna şekilleri | Orta |

### 2.3 Renkler (5 Ana Renk)
`Kırmızı · Mavi · Yeşil · Sarı · Mor`
- Renkler görsel değil, **çarpan (Mult) sistemi** için kritik
- Her yeni run'da renk dağılımı hafifçe randomize edilir

---

## 3. MATEMATİKSEL MOTOR — Balatro Ruhu

### Ana Formül
```
Total Score = (Base Chips) × (Multiplier)
```

### 3.1 Base Puan (Chips)
| Durum | Chips |
|---|---|
| Her patlayan kare | +10 |
| Kare blok (The Architect pasifi) | +10 × 1.2 |

### 3.2 Çarpan (Mult) Tablosu

| Tetikleyici | Mult Değişimi |
|---|---|
| Karışık renk patlatma | ×1 (baz) |
| Satır/sütunun >%50'si aynı renk | ×2 |
| Satır/sütun %100 aynı renk (**Flush!**) | ×5 |
| Flush + Flush (çift) | ×5 × ×5 = ×25 |

### 3.3 Streak Sistemi
- Üst üste başarılı her yerleştirme: **Mult +0.1**
- Boş hamle (yer yok) veya yerleştirme yapılamıyorsa: **Streak = 0**
- Maksimum streak bonusu: **+3.0** (30 üst üste)

### 3.4 Örnek Hesap
```
Durum: 2 satır patlatıldı, her ikisi de %100 Mavi (Flush x2)
Base: 16 kare × 10 = 160 Chips
Mult: 5 × 5 = 25
Streak: 3 hamle = +0.3 → Mult = 25.3
Toplam: 160 × 25.3 = 4.048 puan 🔥
```

---

## 4. ZAMAN VE GERİLİM — The Tension

### 4.1 Round Hedefi (The Blind)
- Her round başında: **Hedef Skor** + **Hamle Sınırı (15 hamle)**
- Hedefe ulaşamazsan → Can kaybı
- Hedefe 15 hamlede veya süre dolmadan ulaşırsan → Satıcı / Sonraki round

### 4.2 The Clock (Geri Sayım Barı)
- Üstte sürekli azalan, renk değiştiren bar
- **Bar Renkleri:** Yeşil → Sarı → Turuncu → Kırmızı → Kırmızı Yanıp Söner

### 4.3 Süre Kazanma

| Olay | Süre Bonusu |
|---|---|
| Normal patlatma | +2 sn |
| Flush patlatma | +5 sn |
| Kombo zinciri (×2) | +3 sn |
| Kombo zinciri (×3) | +6 sn |
| Kombo zinciri (×4+) | +12 sn |
| Hedefin %50'sine ulaşma | +15 sn (tek seferlik) |

---

## 5. KARAKTERLERİN ROSTER'I

### BLOCK-E ⭐ (Başlangıç Karakteri)
| | |
|---|---|
| **Pasif (Eraser)** | Her 10 saniyede bir sahadaki bir bloğu siler (max 3/maç) |
| **Aktif (Overdrive)** | Kombo çarpan artışı 5 saniye boyunca ×5 olur |
| **Unlock** | Başlangıç — Ücretsiz |

### THE ARCHITECT 🏗️
| | |
|---|---|
| **Pasif** | Kare (O) bloklara +%20 puan verir |
| **Aktif** | 3×3 alanı anında temizler |
| **Unlock** | 500 Elmas |

### TIME BENDER ⏳
| | |
|---|---|
| **Pasif** | Kombo süresi %50 yavaş düşer |
| **Aktif** | Zamanı ve çarpanı 3 hamle boyunca dondurur |
| **Unlock** | 800 Elmas |

### THE GAMBLER 🎲
| | |
|---|---|
| **Pasif** | %7 ihtimalle o hamlenin puanı ×10 olur |
| **Aktif** | Mevcut ve sahadaki 3 bloğu rastgele yeniler |
| **Unlock** | 1200 Elmas |

### NEON WRAITH 👻 (Premium)
| | |
|---|---|
| **Pasif** | Süre <%10 ise tüm puanlar ×3 olur |
| **Aktif** | Dolu karenin üzerine blok koyup alttakileri siler |
| **Unlock** | 3000 Elmas |

---

## 6. JOKERLER & İTEMLER (Inventory)

### Slot Sistemi
- **3 aktif slot** — run sırasında satıcıdan doldurulur
- Joker: Pasif, her hamlede otomatik çalışır
- Aktif Item: Bir kez kullanılır, cooldown veya sınır olabilir

### 6.1 Jokerler (Pasif)

| İsim | Etki | Nadirlik |
|---|---|---|
| **Blue Pill** 💊 | Mavi bloklar ×2 Chips verir | Yaygın |
| **Golden Stamp** 🏅 | Hedef skor -%15 | Nadir |
| **Hourglass** ⏳ | Her 1000 puanda +3 saniye | Orta |
| **Prism** 🔷 | Flush yapınca +0.5 Mult ek olarak eklenir | Nadir |
| **Lucky Clover** 🍀 | Streak maxı +10 artırır | Orta |

### 6.2 Aktif İtemler (Sarf)

| İsim | Etki |
|---|---|
| **Balyoz** 🔨 | Seçilen hücreyi/bloğu siler |
| **Boya Bombası** 🎨 | Seçilen rengi değiştirir |
| **Vakum** 🌀 | Tablodaki tüm 1×1 boşlukları siler |

---

## 7. BOSS ROUNDS — Dönüm Noktaları

Her 5. roundda gelir. Özel engeller içerir:

| Boss | Engel |
|---|---|
| **Glitch** | Rastgele kareler kilitlenir (blok konulamaz) |
| **Fog** | Süre barı gizlenir |
| **Weight** | Bloklar "ağır" olur — 2 kez patlatılması gerekir |
| **Phantom** | Bloklar grid'e yerleşince kaybolur, kör oynarsın |

---

## 8. EKONOMİ VE MARKET

### Para Birimleri

| Birim | Tür | Kullanım |
|---|---|---|
| 💰 **Altın** | Soft (geçici) | Run içi satıcıdan joker/item almak |
| 💎 **Elmas** | Hard (kalıcı) | Karakter kilitleri, meta-upgrade'ler |

### Meta-Upgrades (Elmasla)
- **Altın Göz:** Her round sonunda +%10 altın
- **Şanslı Zar:** The Gambler'ın tetiklenme şansı +%3
- **Extra Slot:** Inventory slot sayısı 3→4
- **Iron Will:** Başlangıç süresini +10 saniye artırır

### Adil Denge
- Elmaslar Boss roundlarda, günlük görev ödüllerinde kazanılabilir
- Reklam izleyerek ücretsiz "canlanma" seçeneği

---

## 9. "JUICINESS" — HASSİYET SİSTEMİ

| Katman | Detay |
|---|---|
| **Haptic** | `sensoryFeedback`: Light (blok koy), Medium (patlatma), Heavy (Flush/Boss) |
| **Parçacık** | `Canvas API` ile neon ışık parçacıkları, zincirleme patlama efektleri |
| **Skor Uçuşu** | Patlayan karelerden uçan "+120 pts", "FLUSH ×5!" yazıları |
| **Shake** | Süre bitince kamera sarsılması |
| **Ses** | Retro "tık" + "boom" + Flush özel sesi; arka planda Synthwave/Lo-fi |

---

## 10. TUTORIAL SİSTEMİ

İlk girişte 3 adımlık metin tabanlı yönlendirme:
1. "Bloğu sürükle ve grid'e bırak! İlk hamle hazır."
2. "Aynı rengi diz — bak, Flush yaptın, çarpan ×5 oldu! 🔥"
3. "Süren azalıyor! Kombo yap → zaman kazan!"

Tutorial, `@AppStorage` ile tek seferlik gösterilir.

---

## 11. TEKNİK MİMARİ

```
Block-Jack/
├── App/
│   ├── Block_JackApp.swift
│   └── ContentView.swift (Router)
├── Models/
│   ├── GameCell.swift
│   ├── GameBlock.swift
│   ├── RoundData.swift
│   ├── Character.swift
│   ├── Joker.swift
│   └── PlayerData.swift
├── ViewModels/
│   ├── GameViewModel.swift       ← Ana oyun mantığı
│   ├── ScoreEngine.swift         ← Chips × Mult hesabı
│   ├── BoardViewModel.swift      ← Grid state yönetimi
│   └── ShopViewModel.swift
├── Services/
│   ├── TimerManager.swift        ← Countdown, streak süresi
│   ├── HapticManager.swift       ← sensoryFeedback wrapper
│   ├── SoundManager.swift        ← AVFoundation ses
│   └── SaveManager.swift         ← UserDefaults / SwiftData
├── Views/
│   ├── Game/
│   │   ├── GameView.swift
│   │   ├── GridView.swift
│   │   ├── BlockTrayView.swift
│   │   └── TimerBarView.swift
│   ├── HUD/
│   │   ├── ScoreHUDView.swift
│   │   └── InventoryHUDView.swift
│   ├── Menus/
│   │   ├── MainMenuView.swift
│   │   ├── CharacterSelectView.swift
│   │   └── ShopView.swift
│   └── Overlays/
│       ├── RoundCompleteView.swift
│       ├── GameOverView.swift
│       └── TutorialOverlayView.swift
├── Utils/
│   ├── ThemeColors.swift         ← (mevcut, güncellenecek)
│   ├── NeonTheme.swift           ← Synthwave renk paleti
│   └── Extensions/
└── Resources/
    ├── Sounds/
    └── Assets.xcassets
```

---

## 12. NEON RENK PALETİ (Synthwave)

| Renk | Hex | Kullanım |
|---|---|---|
| Cosmic Black | `#0A0A0F` | Arka plan |
| Neon Cyan | `#00F5FF` | Vurgu, aktif elemanlar |
| Neon Purple | `#BF5FFF` | Çarpan göstergesi |
| Neon Pink | `#FF2D78` | Can barı, tehlike |
| Electric Yellow | `#FFE600` | Altın, bonus puan |
| Grid Dark | `#1A1A2E` | Grid hücre arka planı |
| Grid Stroke | `#2A2A4A` | Grid çizgileri |

---
