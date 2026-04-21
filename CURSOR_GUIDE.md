# Project Block-Jack: Context & Coding Guidelines

Bu döküman, projenin mimarisini, kurallarını ve dikkat edilmesi gereken performans standartlarını Cursor veya diğer AI asistanlarının hızlıca kavraması için hazırlanmıştır.

## 1. Proje Özeti
Block-Jack, Tetris benzeri blok yerleştirme mekanikleri ile Roguelite elementlerini (Karakter güçleri, pasif yetenekler, düşman saldırıları) birleştiren bir mobil puzzle oyunudur.
- **Teknoloji**: Native Swift / SwiftUI.
- **Mimari**: MVVM (Model-View-ViewModel).
- **Core Loop**: Harita üzerinden ilerleme -> Savaş/Puzzle -> Ödül/Geliştirme -> Boss.

## 2. Klasör Yapısı (Key Paths)
- `Block-Jack/Modules/Game`: Ana oyun motoru, Viewlar ve GameViewModel.
- `Block-Jack/Data/Models`: Bloklar, Karakterler, Perkler ve Map modelleri.
- `Block-Jack/Data/Services`: Puan motoru (`ScoreEngine`), Overdrive motoru, Haptic manager.
- `Block-Jack/Utils`: `ThemeColors`, View extension'ları ve Helperlar.

## 3. Mimari Kurallar ve State Yönetimi

### ⚠️ Performans Standartları (KRİTİK)
Oyunun akıcılığını korumak için aşağıdaki kurallara **kesinlikle** uyulmalıdır:
1. **Drag Location**: `GameViewModel` içindeki `dragLocation` parametresi **asla @Published olmamalıdır**. Sürükleme sırasında her frame render tetiklenmesini önlemek için koordinatlar `GameView` içinde yerel `@State` ile tutulmalı, VM'e callback ile beslenmelidir.
2. **Throttling**: Ghost block, Hint detection gibi yoğun grid taramaları her frame (60fps) değil, bir throttle (örn: 33ms) ile çalıştırılmalıdır.
3. **Grid Rendering**: `GridView` 13x13 (169 hücre) olduğu için her hücrenin body'si olabildiğince hafif tutulmalıdır.

### Puanlama Mantığı (`ScoreEngine`)
- Sadece satır, sütun veya zone (4x4, 5x5) temizlendiğinde puan verilir.
- Sıradan blok yerleştirmeleri (match-olmayan) puan kazandırmaz.
- Streak, Flush (renk uyumu) ve Multiplier çarpanları `ScoreEngine` üzerinden merkezi olarak hesaplanır.

## 4. Roguelite Mekanikleri
- **Characters**: Her karakterin kendine has `Overdrive` (Tier 1-2-3) gücü vardır.
- **Perks**: `UserEnvironment` ve `RunManager` pasif perklerin (örn: momentum, gold_eye) aktifliğini takip eder. Perk check'leri `run.hasPerk("id")` ile yapılır.
- **Enemies**: Düşmanlar `Intents` kullanarak tahtayı sabote eder (Kilitli hücreler, tray kilidi, süre çalma vb.).

## 5. UI & UX Standartları
- **Renkler**: Her zaman `ThemeColors` struct'ı kullanılmalıdır (Neon etkili, Dark mode odaklı).
- **Haptic**: Önemli olaylarda (blok yerleşimi, clear, hata) `HapticManager.shared` çağrılmalıdır.
- **Popuplar**: Skor veya uyarılar için `GameViewModel.addPopup` metodu kullanılmalıdır.

## 6. Grid Koordinat Sistemi
- Grid: 13x13. Index: (row, col) formatında `GridPosition` struct'ı ile takip edilir.
- `BoardViewModel`: Board state'ini (filled, empty, occupied) ve clear tespitlerini yönetir.

---
**Not**: Yeni bir özellik eklerken mevcut `GameViewModel.handleClear` veya `GameViewModel.tryPlace` akışlarını bozmadığınızdan ve performans kurallarını ihlal etmediğinizden emin olun.
