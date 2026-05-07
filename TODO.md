# 🃏 Block-Jack Geliştirme Listesi

## ✅ TAMAMLANANLAR
- [x] **Generous Scoring Sistemi:** Puan kazanımı 2.5x arttırıldı, renk bonusları ve hibrit streak entegre edildi.
- [x] Satın aldığım perkerl oyunun haritalarıdna sandıklarda vs çıkmıyor. (FIXED: Pool logic updated to use slot.perkLevels)
- [x] Perk yükseltmesi etki etmiyor overkill mesela %25 oldu şuan fulledim ama hala %15 ? (FIXED: GameViewModel now syncs with PerkUpgradeRegistry tiers)
- [x] Aynı şekidle perklerin level mantığı kayıt bazlı olacak. Bir kayıdımda 4 level ise diğer kayıdımda 4 level olmyacak. (FIXED: perkLevels moved to SaveSlot)
- [x] Oyun Dengeleme
- [x] Ses Tasarımı
- [x] Performans

## 🚀 SONRAKİ ADIMLAR
(Tüm öncelikli teknik borçlar ve perk sistemi stabilizasyonu tamamlandı.)

## 🛠 MİMARİ VE TEKNİK İYİLEŞTİRMELER (Gelecek)
- [ ] **Event-Driven Perk Sistemi:** Perkleri tek tek `if` bloklarıyla kontrol etmek yerine, `onLineCleared` gibi global olayları dinleyen bağımsız sınıflara dönüştür.
- [ ] **Seed-Based RNG:** Tüm sandık ve blok içeriklerini `runSeed` üzerinden üreterek "Save-Scumming" hilesini engelle ve tutarlı bir oyun deneyimi sun.
- [ ] **SwiftData / CoreData Geçişi:** Kayıt dosyalarının güvenliği ve hızı için `UserDefaults` yerine modern bir veritabanı yapısına geç.

## 🎮 OYUN DENEYİMİ VE UX (Gelecek)
- [ ] **Block Discard / Reroll:** Deadlock (kilitlenme) durumlarında altın karşılığı blok çöpe atma veya yenileme mekaniği ekle.
- [ ] **Yeni Bölüm: Ocean Depths:** Su altı temalı yeni map ve özel mekanikler.
- [ ] **Daha Fazla Boss Varyasyonu:** Her dünya için farklı saldırı kalıplarına sahip bosslar.
- [ ] **Günlük Meydan Okuma (Daily Challenge):** Sabit seed ile tüm oyuncuların yarıştığı günlük mod.
