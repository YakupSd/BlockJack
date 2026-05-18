# 🃏 Block-Jack Geliştirme Listesi

## 🚀 SONRAKİ ADIMLAR

### ✅ TAMAMLANAN
- [x] Backend email + password authentication controller (arkadaşa gönderildi)
- [x] **Daily Challenge & Live Events** - Frontend UI Sistemi (Modules/Events/) + Premium Vision #2
  - EventModels.swift - Veri modelleri
  - EventsViewModel.swift - Event yönetimi
  - EventsView.swift - Ana ekran (Daily/Weekly tabs)
  - EventDetailView.swift - Event kartı + Boss + Karakterler + Ödüller
  - EventGameView.swift - Oyun ekranı + HUD + Perk seçimi + Leaderboard
  - EventGameViewModel.swift - Event oyun state yönetimi
- [x] **GAME LOOP ENTEGRASYONU**
  - EventGameViewModel'i gerçek GameView ile entegre et (modifier'lar aktif)
  - Boss intent'leri BoardViewModel'e connect et
  - Perk efektlerini PerkEngine'e connect et (framework hazır)
  - Sonsuz mod (infinite time) TimeManager'a uygulandı

### 🎮 BACKEND ENTEGRASYONU (Sonraki)
- [ ] Backend için email + password login: Arkadaş gönderirse ExistingAccountLoginView'i güncelle
- [ ] Daily/Weekly Event API endpoints (GET /api/events/daily, GET /api/events/weekly)
- [ ] Event Leaderboard API (POST /api/events/:eventId/score, GET /api/events/:eventId/leaderboard)
- [ ] Event karakterlerin unlock/store API

## ✨ PREMIUM VİZYON: ELİTE GÜNCELLEMELER (Yol Haritası)

### 1. 🎨 Theme Store & Customization (Ekonomi Derinliği)
*   **Açıklama:** Oyuncuların oyun içi Elmas (Diamond) harcayabileceği en büyük kozmetik alanı. Sadece blokları değil, tüm oyun atmosferini değiştirir.
*   **Senaryo:** Oyuncu "Neon Sunset" temasını 2000 Elmas karşılığı satın alır. Oyunun arka planı batan bir güneş efektine dönüşür, bloklar retro-dalga renklerine bürünür ve satır silindiğinde çıkan efektler mor/turuncu bir patlamaya dönüşür.
*   **Hedef:** Elmas harcama motivasyonunu ve oyunun "tekrar oynanabilirliğini" görsel tazelemeyle artırmak.

### 4. 🔊 Premium VFX & Audio Polish (Hissiyat Zirvesi)
*   **Açıklama:** Oyunun her anını tatmin edici kılan ses ve efekt katmanı.
*   **Senaryo:** Oyuncu 4'lü kombo yaptığında ses efekti her adımda incelir (müzikal bir yükseliş). 10'lu kombo baremine ulaşıldığında ekranın kenarları parlamaya başlar ve bir dış ses (Announcer) "ULTRA COMBO!" diye bağırır. Boss yenildiğinde ekran ağır çekime girer ve devasa bir "SHATTER" efektiyle her yer dağılır.
*   **Hedef:** Oyuncuyu "akış" (Flow) durumuna sokmak ve kazanma hissini maksimize etmek.

### 5. ⚔️ Asenkron PvP Düelloları (Meydan Okuma)
*   **Açıklama:** Arkadaşlarına veya rastgele rakiplere doğrudan meydan okuma sistemi.
*   **Senaryo:** Oyuncu arkadaşına bir link gönderir veya oyun içinden davet atar. İkisi de aynı "Seed" (aynı blok sırası) ile oynar. Oyuncu 25.000 yaparken arkadaşı 22.000'de kalır. Oyuncu, arkadaşının ortaya koyduğu 500 Altını kazanır.
*   **Hedef:** Sosyal yayılımı (Virality) artırmak.

### 6. 📊 Player Career & Advanced Stats (Kişisel Başarı) ✅ TAMAMLANDI
*   **Açıklama:** Oyuncunun oyun içindeki tüm geçmişini havalı grafiklerle özetleyen profil sayfası.
*   **Senaryo:** Oyuncu profiline girdiğinde "Total Damage Dealt: 1M+", "Most Used Perk: Overkill", "Favorite Character: Cyber Ninja" gibi verilerini görür. Bu istatistikler geliştikçe oyuncu "Mastery" seviyeleri kazanır.
*   **Hedef:** Uzun vadeli bağlılık (Progression) sağlamak.
*   **Detaylar:**
    - ✅ 5-tier Mastery System (Çırak → Efsanevi)
    - ✅ Overall Career Stats (Total damage, lines, bosses, playtime)
    - ✅ Per-Character Mastery & Stats
    - ✅ Per-Perk Usage Tracking
    - ✅ 8 Special Achievement Titles (Grid Slayer, Damage Dealer, Eternal, vb.)
    - ✅ Dashboard'dan erişim (KARİYER butonu)
    - ✅ Persistence & Error Handling


## 🛠 MİMARİ VE TEKNİK İYİLEŞTİRMELER (Gelecek)
- [ ] **Event-Driven Perk Sistemi:** Perkleri tek tek `if` bloklarıyla kontrol etmek yerine, `onLineCleared` gibi global olayları dinleyen bağımsız sınıflara dönüştür.
- [ ] **Seed-Based RNG:** Tüm sandık ve blok içeriklerini `runSeed` üzerinden üreterek "Save-Scumming" hilesini engelle ve tutarlı bir oyun deneyimi sun.
- [ ] **SwiftData / CoreData Geçişi:** Kayıt dosyalarının güvenliği ve hızı için `UserDefaults` yerine modern bir veritabanı yapısına geç.

## 🎮 OYUN DENEYİMİ VE UX (Gelecek)
- [x] **Block Discard / Reroll:** Deadlock (kilitlenme) durumlarında altın karşılığı blok çöpe atma veya yenileme mekaniği ekle.
  - ✅ Discard: 25 Altın karşılığı bloğu tepsiyi kaldırır
  - ✅ Reroll: 50 Altın karşılığı bloğu yeni blokla değiştirir
  - ✅ Action menu: Her blokta ... tuşu ile işlemler menüsü
  - ✅ Deadlock indicator: Tepsinin üst köşesinde DEADLOCK! göstergesi
  - ✅ Refresh button: Klasik 100G refresh seçeneği hala mevcuttur
- [ ] **Yeni Bölüm: Ocean Depths:** Su altı temalı yeni map ve özel mekanikler.
- [ ] **Daha Fazla Boss Varyasyonu:** Her dünya için farklı saldırı kalıplarına sahip bosslar.
