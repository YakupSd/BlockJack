# Block-Jack — 100 Seviyelik Genişleme Roadmap'i

> **Durum:** Taslak / brainstorm. Uygulama başlamadı, mevcut kod dokunulmadı.
> **Hedef:** 1–20 seviyelik cyberpunk içeriğini 5 dünya × 20 seviye = 100 seviyelik
> tam bir kampanyaya genişletmek. Her dünyanın kendi teması, boss seti ve benzersiz
> gameplay twist'i olacak.

---

## 1. Navigation Mimarisi — 3 Katmanlı Harita Sistemi

Oyunun harita akışı **3 ayrı ekran** arasındaki drill-down ile çalışır. Her
katman bir sonrakini açar, geri dönüşte üstteki state korunur.

```
┌─────────────────────────────────────────────────────────────┐
│  KATMAN 1 · WorldSelectionView        (YENİ — eklenecek)   │
│  ─────────────────────────────────────                     │
│  5 dünya kartı (Neon / Concrete / Candy / Ocean / Void)    │
│  Her kart: isim + tema ikonu + progress % + kilit durumu   │
│  → Kart'a tıkla → Katman 2'ye geç                          │
└──────────────────┬──────────────────────────────────────────┘
                   │ pushToWorldMap(worldId:)
                   ▼
┌─────────────────────────────────────────────────────────────┐
│  KATMAN 2 · WorldMapView              (VAR — refactor OK)  │
│  ─────────────────────────────────────                     │
│  Seçili dünyanın 20 sektörü (örn. Dünya 2 → level 21-40)   │
│  Piksel-retro 2D harita, zigzag snake path                 │
│  Her node = 1 round; boss node'lar kırmızı                 │
│  → Node'a tıkla → Detail Sheet → "ENTER BATTLE"            │
│  → Katman 3'e geç                                          │
└──────────────────┬──────────────────────────────────────────┘
                   │ pushToChapterMap(worldId:, levelId:)
                   ▼
┌─────────────────────────────────────────────────────────────┐
│  KATMAN 3 · MapView                   (VAR — chapter map)  │
│  ─────────────────────────────────────                     │
│  O round'un iç node tree'si (Slay the Spire tarzı)         │
│  normal / elite / merchant / rest / treasure / mystery /   │
│  boss tiplerinde node'lar, dallanmalı path                 │
│  → Node'a tıkla → GameView'a geç (asıl oyun başlar)        │
└──────────────────┬──────────────────────────────────────────┘
                   │ startGame()
                   ▼
             [ GameView — oyun ekranı ]
```

**Mevcut durum:**
| Katman | Dosya | Durum |
|---|---|---|
| 1 · WorldSelectionView | *(eksik)* | ❌ Yazılacak |
| 2 · WorldMapView | `Modules/Map/WorldMapView.swift` | ✅ Refactor edildi (piksel-retro) |
| 3 · MapView (chapter) | `Modules/Map/MapView.swift` | ✅ Mevcut (ChapterMapGenerator kullanıyor) |

**Önemli:** Kullanıcı şu anda doğrudan Dashboard'dan **Katman 2**'ye iniyor
(`pushToWorldMap(slotId:)`). Faz 2'de Dashboard → Katman 1 → Katman 2 → Katman 3
akışına geçilecek.

---

## 2. Felsefe

Her dünya 3 temel eksende birbirinden ayrılmalı:

| Eksen | Ne demek |
|---|---|
| **Tema (görsel)** | Renk paleti, tile arkaplanı, blok skin'leri, müzik, boss karakter tasarımı |
| **Twist (mekanik)** | O dünyaya özel *kalıcı* kural değişimi — oyun hissi dönüşür |
| **Ritim (ekonomi/zorluk)** | Boss dağılımı, elite/rest frekansı, ödül eğrisi |

Sadece "skin swap" → oyuncu sıkılır. Sadece "mekanik bomba" → öğrenme eğrisi diker.
İkisi dengeli olmalı.

---

## 3. Dünya Haritası (Özet Tablo)

| # | Dünya Adı | Seviye | Tema | Kalıcı Twist | Boss Sayısı |
|---|---|---|---|---|---|
| 1 | **NEON CORE** | 1–20 | Cyberpunk / siber grid (mevcut) | Yok (tutorial dünya) | 5 |
| 2 | **CONCRETE RUINS** | 21–40 | Terk edilmiş endüstri / beton yıkıntı | **Ağırlık**: bloklar yerleştikten sonra bir alt satıra düşme eğilimi | 5 |
| 3 | **CANDY LAB** | 41–60 | Şekerleme fabrikası / neon pastel | **Yapışkan**: aynı renk bloklar zincirleniyor, 5'li kombo bonus | 5 |
| 4 | **DEEP OCEAN** | 61–80 | Biyolüminesan derin deniz | **Akıntı**: her 3 hamlede grid 1 hücre kayar (yan) | 5 |
| 5 | **VOID KERNEL** | 81–100 | Kara madde / boşluk / simülasyon çöküşü | **Reality-bend**: tüm önceki twist'ler rastgele rotasyon | 5 |

**Toplam:** 100 seviye · 25 boss · 5 unique müzik teması · 5 blok skin seti

---

## 4. Her Dünya — Detay

### 🌆 Dünya 1: NEON CORE (1–20)

> Mevcut içerik. Tutorial dünyası, oyuncu mekaniklerini bu dünyada tanıyor.

- **Renkler:** `neonCyan`, `neonPurple`, `neonPink`, koyu lacivert arkaplan
- **Blok skin'i:** Parlak neon kenarlı, iç boş solid renk (mevcut)
- **Modifier havuzu:** `.fog`, `.glitch`, `.phantom`, `.weight` (mevcut)
- **Boss'lar:** Viper X, Sentinel K, Ghost Mother, Juggernaut, Neon Overlord (mevcut)
- **Boss seviyeleri:** 1, 3, 5, 7, 9, 11, 15, 17, 20 (mevcut pattern — 9 boss slot)
  - **Not:** Mevcut `bossWorldLevels` 9 slot'a 5 boss mapping yapıyor (bazıları
    tekrarlıyor). Gelecek dünyalarda her slot için unique boss olacak → bu
    dünya için de 4 yeni boss eklenmesi gerekecek (opsiyonel polish).

**Duygu:** Öğrenme, yükseliş, "sistem içinde bir hacker"

---

### 🏭 Dünya 2: CONCRETE RUINS (21–40)

> Mega-yapıların çöktüğü post-endüstriyel sektör. Yerçekimi ağır basıyor.

- **Renkler:** `concreteGray` `#3a3a3a`, `rustOrange` `#a0522d`, `steelBlue` `#4a5a6a`
  - Arka plan: toz grisi çini + sprey boya "graffiti" rastgele
- **Blok skin'i:** Granit/beton doku, çatlak çizgiler, bazı hücrelerde "rebar"
  demirleri çıkmış
- **Kalıcı twist — Ağırlık:**
  - Yerleştirilen her blok 1 saniye sonra "settle" efekti verir (sallanır)
  - Elite ve boss seviyelerde, üstteki bloklar altındaki boş hücreye düşer
  - **Kod etkisi:** `GameBlock` üzerinde `hasSettled: Bool` + yeni `settle()` animation
- **Yeni mekanik: Çatlak bloklar (bonus)**
  - %15 ihtimalle yerleştirilen blok "cracked" gelir; 3 kez kullanınca kırılır
  - Kırılınca rastgele 3 hücre temizler (mini bomba gibi)
- **Boss seviyeleri:** 21, 23, 25, 27, 29, 31, 35, 37, 40 — yani dünya 1 pattern'i +20 offset
- **Önerilen boss isimleri** (aynı modifier'ları kullanarak başlangıçta):
  - **BULLDOZER Ω** (21,23) — `.weight` ağırlık katlı
  - **CRANE OF ASH** (25) — `.fog` toz fırtınası
  - **REBAR WRAITH** (27,29) — `.phantom` paslı hayaletler
  - **CONCRETE KING** (31,35) — `.glitch` yapısal çökmeler
  - **GODZILLITH** (37,40) — dünya finali, tüm modifier'ları döngüler
- **Müzik:** Industrial drum & bass, metal perküsyon
- **Dünya ödülü:** Yeni karakter **CRUSHER** (ağırlık bonusu passive)

**Duygu:** Ezilme, ağırlık, direnç

---

### 🍭 Dünya 3: CANDY LAB (41–60)

> Deneysel şekerleme laboratuvarı. Her şey yumuşak, her şey tatlı, her şey
> tehlikeli. Hafif absürt, neşeli ton.

- **Renkler:** `bubblegumPink` `#ff6fa3`, `mintGreen` `#6fe5b0`, `lemonYellow` `#ffe26f`
  - Arka plan: pastel tile + mini şeker sprite'ları (jellybean, lolipop)
- **Blok skin'i:** Gloss/parlak "candy" texture, saydam iç, şekerleme sarı/pembe
  parıltılar
- **Kalıcı twist — Yapışkan Zincir:**
  - Aynı renk 2 blok bitişikse otomatik "yapışır"
  - 5 veya daha fazla yapışık blok zinciri = **SWEET RUSH** (+%50 skor, 5sn)
  - **Kod etkisi:** `BoardViewModel.detectColorChains(minLength: 5)` — mevcut line
    clear mantığının kardeşi, renk-bazlı
- **Yeni mekanik: Eriyen bloklar**
  - Süre barı %20'nin altına düşünce **en alttaki** satır yavaşça erir
    (önce %40 opacity, sonra siliner)
  - Oyuncunun süreyi kritik seviyede yönetmesi gerekir
- **Boss seviyeleri:** 41, 43, 45, 47, 49, 51, 55, 57, 60
- **Önerilen boss isimleri:**
  - **JELLY WITCH** — `.fog` pembe sis
  - **GUMMY GOLEM** — `.weight` çiğneme efekti
  - **LOLLIPOP LICH** — `.phantom` tatlı hayaletler
  - **SUGAR SENTINEL** — `.glitch` karamel glitch
  - **THE CONFECTIONER** — final, **yeni modifier `.sticky`**
- **Müzik:** Chiptune + hafif pop
- **Dünya ödülü:** Yeni karakter **SUGAR RUSH** (renk zinciri x3 bonus)

**Duygu:** Neşe, yapışkanlık, kaos

---

### 🌊 Dünya 4: DEEP OCEAN (61–80)

> Biyolüminesan derin deniz. Sessiz ama hareketli. Grid kendisi akıntıdan
> etkileniyor — oyuncu artık statik değil.

- **Renkler:** `abyssTeal` `#0a3a4a`, `bioCyan` `#00ffcc`, `coralPink` `#ff6e88`
  - Arka plan: koyu mavi gradient + minik ışıldayan plankton nokta animasyonları
- **Blok skin'i:** Organik, mercan/cam deniz kabuğu benzeri, hafif translucent
- **Kalıcı twist — Akıntı:**
  - Her 3 hamlede bir grid **1 hücre yana kayar** (sağa veya sola, alternatif)
  - Ekran kenarından taşan bloklar kaybolur (ceza), ama kayma puan bonusuyla
    gelir (+50 her kaymada — motivasyon)
  - **Kod etkisi:** Yeni `GridShiftEvent` + `BoardViewModel.applyShift(dir:)`
- **Yeni mekanik: Işıltı komboları**
  - Aynı satırda **3+ bioluminescent** blok varsa **glow chain** — tüm satır
    "resonance"la +%30 skor
- **Boss seviyeleri:** 61, 63, 65, 67, 69, 71, 75, 77, 80
- **Önerilen boss isimleri:**
  - **KRAKEN-X** — `.phantom` mürekkep sisi
  - **CORAL QUEEN** — `.weight` kabuk düşürür
  - **TIDECALLER** — `.sticky` yapışkan tentakül
  - **ABYSS WATCHER** — `.glitch` su bozulması
  - **LEVIATHAN ZERO** — final, **yeni modifier `.currentShift`**
- **Müzik:** Ambient dub, sualtı filtre efekti
- **Dünya ödülü:** Yeni karakter **TIDE WALKER** (akıntı yönünü görebilir passive)

**Duygu:** Huzur + pusu, hareket, koreografi

---

### ⚫ Dünya 5: VOID KERNEL (81–100)

> Tüm sistemin dayandığı kernel. Gerçeklik burada çöküyor. Oyuncu sadece
> hayatta kalmaya çalışıyor — sistem kendi kurallarını kırıyor.

- **Renkler:** `voidBlack` `#000`, `stellarPurple` `#6a1ba0`, `cosmicWhite` `#fff`
  - Arka plan: saf siyah + binary "0/1" matrix yağmuru (çok ince)
- **Blok skin'i:** Glitch efektli, kenarları kırmızı-cyan kromatik aberasyon,
  her render'da hafif farklı görünür
- **Kalıcı twist — Reality Bend:**
  - Her yeni seviyede **önceki 4 dünyanın twist'lerinden 1'i rastgele aktif**
  - 91+ seviyede **2 twist aynı anda** çalışır
  - Final (100) — **TÜM twist'ler aynı anda**
  - **Kod etkisi:** `ActiveTwistStack` — enum case'lerini stack'e push eder
- **Yeni mekanik: Kernel Panic**
  - Her elite/boss seviyede oyuna girerken kısa bir "panic screen" — grid
    rastgele 3 hücre yanıp söner → o hücreler 5 saniye boyunca kullanılamaz
- **Boss seviyeleri:** 81, 83, 85, 87, 89, 91, 95, 97, 100
- **Önerilen boss isimleri:**
  - **NULL-0** — boş modifier, grid siyaha boyanır periyodik
  - **FRACTAL HEX** — self-similar phantom
  - **THE CENSOR** — puanları sansürler (skor görmez bir süre)
  - **EMPTY GOD** — `.currentShift` + `.sticky`
  - **TRUE PROTOCOL** — 100. seviye final. **Oyuncu tüm önceki boss'lara sırayla
    karşı gelir** (5 aşamalı boss fight)
- **Müzik:** Atonal drone + cam kırılma sampleları
- **Dünya ödülü:** Ultimate skin + "Block Jack" başarımı

**Duygu:** Mutlak baskı, zafer, katharsis

---

## 5. Sistem Değişiklikleri (Teknik)

### 5.1 Veri Modeli Genişletmeleri

**`ChapterProgression.swift` (MapModels.swift içinde):**

```swift
enum ChapterProgression {
    /// Dünya bazlı boss seviyeleri.
    static let bossLevelsByWorld: [Int: Set<Int>] = [
        1: [1, 3, 5, 7, 9, 11, 15, 17, 20],
        2: [21, 23, 25, 27, 29, 31, 35, 37, 40],
        3: [41, 43, 45, 47, 49, 51, 55, 57, 60],
        4: [61, 63, 65, 67, 69, 71, 75, 77, 80],
        5: [81, 83, 85, 87, 89, 91, 95, 97, 100]
    ]

    static let allBossLevels: Set<Int> =
        bossLevelsByWorld.values.reduce(into: Set<Int>()) { $0.formUnion($1) }

    static func isBossLevel(_ level: Int) -> Bool { allBossLevels.contains(level) }

    /// Seviye numarasından dünya ID'si (1-5).
    static func worldId(for level: Int) -> Int {
        return max(1, min(5, (level - 1) / 20 + 1))
    }
}
```

**Yeni dosya `WorldTheme.swift` (Data/Models/):**

```swift
enum WorldTheme: Int, CaseIterable {
    case neonCore = 1, concreteRuins, candyLab, deepOcean, voidKernel

    var name: (tr: String, en: String) { ... }
    var palette: WorldPalette { ... }      // renkler
    var twist: WorldTwist { ... }          // kalıcı kural
    var bossPool: [String] { ... }         // BossEncounter.id listesi
    var musicTrack: AudioTrack { ... }
}

struct WorldPalette {
    let bg: Color, tile1: Color, tile2: Color
    let nodeCompleted: Color, nodeCurrent: Color, nodeBoss: Color
    let blockSkinTint: Color
    let roadDark: Color, roadDash: Color
}
```

### 5.2 ThemeColors.swift

`ThemeColors.mapBg/Tile1/...` yerine `ThemeColors.world(_:).mapBg` gibi computed
— mevcut hard-coded değerler dünya 1'e default olur, geri uyum bozulmaz.

### 5.3 BossRegistry.swift

`bossesSnapshot: [BossEncounter]` → 25 boss'a çıkar. `getBoss(for level:)`
`ChapterProgression.worldId(for:)` ile dünya içindeki local ID'yi mapler.

### 5.4 UI/Navigation — 3 Katmanlı Akış

#### Katman 1: `WorldSelectionView.swift` (YENİ)

5 dünya kartı. Layout önerisi: **dikey scroll + büyük kartlar** (yatay swiper
yerine — iPhone SE'de parmak ulaşımı daha rahat, kart içine detay sığar).

Her kart:
- Dünya numarası + adı (örn. "WORLD 2 — CONCRETE RUINS")
- Tema piksel ikonu (mevcut `WorldCityPixelIcon` stili uzantısı)
- Progress çubuğu: `tamamlanan / 20`
- Kilit durumu:
  - **Açık + devam ediyor:** sarı glow, "DEVAM ET" butonu
  - **Bitmiş:** yeşil tik, "TEKRAR OYNA"
  - **Kilitli:** kilit ikonu, "Bir önceki dünyayı bitir"
- Kart arkaplanı dünya palette'ine göre (neon mavi / beton gri / candy pembe / deniz turkuaz / void siyah)

#### Katman 2: `WorldMapView.swift` (MEVCUT — imza değişecek)

Mevcut imza:
```swift
WorldMapView(vm: WorldMapViewModel(slotId: Int, userEnv:))
```

Yeni imza:
```swift
WorldMapView(vm: WorldMapViewModel(worldId: Int, slotId: Int, userEnv:))
```

`WorldMapViewModel` içi:
- `generateLevels()` artık `(worldId-1)*20 + 1 ... worldId*20` aralığında
- `ThemeColors.world(worldId).palette` kullanılıyor — tile, path, node renkleri otomatik değişir
- HUD'da dünya adı ve numarası (örn. "W2 · CONCRETE RUINS")
- Geri butonu → `WorldSelectionView`'a pop

#### Katman 3: `MapView.swift` (MEVCUT — küçük tweak)

Şu an `ChapterMapGenerator` chapter içi random node tree üretiyor. Değişiklik:
- `MapViewModel.init(worldId: Int, levelId: Int, ...)` — dünya ID'sini de alsın
- Chapter map'in arkaplan palette'i dünya temasıyla eşleşsin
  (`ThemeColors.world(worldId).mapBg`)
- Normal node'ların skin'i dünyaya göre değişsin (beton/şeker/mercan/void)

#### `MainViewsRouter` (veya `MainNavigationView`) — Yeni/değişen metotlar

```swift
// YENİ
func pushToWorldSelection(slotId: Int)

// DEĞİŞEN — mevcut pushToWorldMap(slotId:) yerine
func pushToWorldMap(worldId: Int, slotId: Int)

// DEĞİŞEN — MapView imzası dünyaya duyarlı
func pushToChapterMap(worldId: Int, levelId: Int, slotId: Int)
```

Dashboard'daki "PLAY" butonu artık direkt `pushToWorldSelection(slotId:)`
tetikler, doğrudan WorldMapView'a değil.

### 5.5 Save

`UserEnvironment.unlockedWorldLevel: Int` (1–100) yeterli — zaten linear.
Ama **dünya highscore'ları** için ek:
```swift
@Published var worldHighScores: [Int: Int]  // worldId -> best total score
```

---

## 6. Gameplay Mekanikleri (Eklenecek Enum'lar)

```swift
// Data/Models/RoundData.swift içine
enum BossModifier {
    case fog, glitch, phantom, weight     // mevcut
    case sticky          // Dünya 3 — renk zinciri
    case currentShift    // Dünya 4 — grid kayması
    case voidBend        // Dünya 5 — tüm twist'ler rastgele
    case crush           // Dünya 2 — ağırlık katlanır
    case censor          // Dünya 5 — skor görünmez
}
```

**Her modifier için OverdriveEngine + BoardViewModel küçük metotlar:**
~10 satır/mekanik, toplam ~60 satır yeni oyun mantığı (abartısız).

---

## 7. Uygulama Sırası (Faz Planı)

### ✅ Faz 0 — Bitti
- İlk 20 seviye neon cyberpunk tam
- WorldMapView piksel-retro refactor

### 🔵 Faz 1 — Veri modeli (mekaniğe dokunmadan)
1. `ChapterProgression.bossLevelsByWorld` ekle, `isBossLevel` hâlâ çalışsın
2. `WorldTheme` enum + `WorldPalette` struct ekle (boş palette Dünya 1'e döner)
3. `BossRegistry` dummy boss stub'larını Dünya 2-5 için ekle (imageName asset eksik olsa da crash olmasın)
4. `ThemeColors.world(_:)` computed ekle
5. **Build + WorldMapView Dünya 1 için aynı görünsün (regresyon yok)**

### 🔵 Faz 2 — UI katmanı (3 katmanlı navigation)
1. **Katman 1 yeni:** `WorldSelectionView` kart listesi (5 dünya, dikey scroll)
2. **Katman 2 güncelle:** `WorldMapViewModel(worldId:slotId:userEnv:)` imza geçişi
   — mevcut çağrı bozulmaması için eski imza `worldId: 1` default'uyla korunur
3. **Katman 3 güncelle:** `MapViewModel` `worldId` parametresi alsın, arkaplan
   palette'i dünyaya göre değişsin
4. `MainNavigationView.pushToWorldSelection(slotId:)` ekle
5. Dashboard "PLAY" artık önce Katman 1'e gitsin
6. Geri navigation zinciri test et: Katman 3 → 2 → 1 → Dashboard

### 🔵 Faz 3 — Görsel temalar (dünya 2-5 palette + tile)
- Sadece renk + piksel ikon varyasyonu
- Blok skin için `GameBlock.themedColor(world:)` computed
- **Gameplay hâlâ Dünya 1 mekaniği ile çalışsın**

### 🔵 Faz 4 — Mekanikler (twist'ler)
- **Her dünyanın twist'i ayrı branch'te geliştirilir:**
  - `feature/world-2-weight`
  - `feature/world-3-sticky`
  - `feature/world-4-current`
  - `feature/world-5-void`
- Hepsi toggled behind `WorldTheme` — Dünya 1 hiçbirinden etkilenmez

### 🔵 Faz 5 — Boss asset'leri + müzik
- Her dünya için 5 yeni boss portresi (AI-generated / custom)
- 4 yeni müzik track (`bgm_concrete`, `bgm_candy`, `bgm_ocean`, `bgm_void`)
- Dialogue line'ları her boss için 3 cümle

### 🔵 Faz 6 — Polish
- Her dünya bitince unique cutscene/celebration
- Yeni karakter unlock ödülleri (5 yeni karakter: CRUSHER, SUGAR RUSH, TIDE WALKER, + 2)
- Meta achievement'lar

---

## 8. Tahmini İş Gücü

| Faz | Effort (Solo + AI) |
|---|---|
| Faz 1 (data model) | 1 gün |
| Faz 2 (navigation) | 1 gün |
| Faz 3 (görsel temalar) | 2-3 gün |
| Faz 4 (mekanikler) | 4-5 gün (dünya başına 1 gün) |
| Faz 5 (asset + müzik) | 3-5 gün (asset'lere bağlı) |
| Faz 6 (polish) | 2-3 gün |
| **TOPLAM** | **~2-3 hafta full-time** / **~6-8 hafta akşam 2 saat** |

---

## 9. Riskler / Dikkat Edilecekler

1. **Mekanik çatışması:** Dünya 5'te "tüm twist'ler aktif" → `.sticky` + `.currentShift`
   aynı anda çalıştığında kod kilitlenebilir. Unit test her kombinasyon için şart.

2. **Balans:** Her dünyanın zorluk eğrisi test edilmeli. İlk sürüm için
   **içsel sınanmadan önce** son dünyayı kilitli tut.

3. **Asset maliyeti:** 25 boss portresi + 4 müzik + 5 dünya için tile/background
   asset gerekir. AI yardımıyla ama **tutarlı art direction** gerekli.

4. **Save migration:** Mevcut slot'lar (Dünya 1'de olanlar) geçişte bozulmamalı.
   `unlockedWorldLevel: Int` zaten forward-compat.

5. **Performans:** 100 seviyeyi tek ScrollView'de göstermek yok — zaten
   3 katmanlı mimari bunu çözüyor: her dünya kendi `WorldMapView`
   instance'ı, 20 seviye ile sınırlı. Katmanlar arası geçişte
   eski instance memory'den düşer.

6. **Narratif devamlılık:** 5 dünya bağımsız "izole" görünmemeli —
   ortak bir arc (örn: "sistemin çöküşünü durdur") olmalı. Boss diyalogları
   bu arc'ı besleyecek şekilde yazılsın.

---

## 10. İsteğe Bağlı Sonraki Adımlar (v2+)

- **Daily Challenge Mode** — rastgele dünya + twist kombosu her gün
- **Endless Mode** — Dünya 5 bittikten sonra sonsuz seviye, leaderboard
- **Co-op / Versus** — 2 oyuncu aynı grid üzerinde
- **Dünya 6: "New Game+"** — ilk 5 dünyayı tekrar oyna, tüm twist'ler aktif

---

## 11. Özet Karar

| Soru | Cevap |
|---|---|
| 100 seviye mantıklı mı? | **Evet** — 5 dünya × 20 kompakt, tamamlanabilir. |
| Mevcut kod dayanır mı? | **Evet** — minimal refactor (`ChapterProgression` dünya bazlı) yeterli. |
| Şu an hangi faz? | **Faz 0 bitmiş**, Faz 1 (data modeli) güvenli başlangıç. |
| Tek oturumda ne yapmak mantıklı? | Faz 1 + Faz 2 (veri + navigation) — hiçbir gameplay bozulmaz, **foundation** hazır olur. |

> **Sıradaki adım (hazır olduğunda):** "Kral, Faz 1'i başlat" de, ben
> `ChapterProgression` ve `WorldTheme` enum'unu ekleyip Dünya 1'in
> aynen çalıştığından emin olduktan sonra Faz 2'ye geçeyim.
