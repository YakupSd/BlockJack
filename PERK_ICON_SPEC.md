# Block-Jack — Perk Icon Pack Spec (PNG)

Bu doküman, oyundaki **tüm perk ikonlarını** (şu an emoji/dummy olanlar dahil) AI ile üretip uygulamaya **sabit PNG** olarak entegre edebilmen için hazırlanmıştır.

## Genel Stil (tüm ikonlar için ortak kurallar)

- **Format**: PNG, **transparent background**
- **Boyut**: `256×256` (master). Uygulamada `64×64`, `48×48`, `32×32` downscale edilecek.
- **Kompozisyon**:
  - Tek bir “ana siluet” + 1 adet yardımcı detay (maksimum).
  - Çerçeve/rozet hissi: dışta ince “neon rim light” kabul; ama **kalın border yok**.
  - **Yazı yok**, rakam yok, logo/marka yok.
- **Okunabilirlik**:
  - 32×32’de okunabilir olacak kadar **kalın form**.
  - İnce detaylardan kaçın (noise, micro-texture, çok ince çizgi).
- **Sanat dili (uyum)**:
  - Cyberpunk / neon / arcade UI ile uyumlu, “premium game icon” hissi.
  - 2.5D / flat + glow karışımı; fotogerçekçilik yok.
- **Renk paleti** (ikon başına 2–4 ana renk):
  - Ana neon: `#00F5FF` (neon cyan) veya `#FF4FD8` (neon pink) veya `#9B59FF` (neon purple)
  - Vurgu: `#FFD84D` (electric yellow) veya `#00FF77` (success green)
  - Gövde koyu: `#0B1020` / `#101427`
- **Işık**:
  - Yumuşak dış glow + hafif iç highlight.
  - Aşırı bloom yok (ikon “leke” gibi olmasın).

## Dosya yerleşimi ve isimlendirme (öneri)

- **Passive perk ikonları**: `Block-Jack/Block-Jack/Assets.xcassets/PerkIcons/`
  - Dosya adı: `perk_<perkId>.png`
  - Örnek: `perk_momentum.png`
- **Starting perk ikonları**: `Block-Jack/Block-Jack/Assets.xcassets/StartingPerkIcons/`
  - Dosya adı: `start_<perkId>.png`
  - Örnek: `start_blue_pill.png`

> Not: Şu an bazı starting perk ikonları zaten asset string’i kullanıyor (`item_blue_pill`, `item_golden_stamp`, `item_green_pill`). Bu dokümanda hepsi “PNG standart”a çekilecek şekilde listelenmiştir.

## Üretim Prompt Şablonu (her ikon için kopyala-yapıştır)

Aşağıdaki prompt’u her ikona özel “Concept” satırı ile birlikte kullan:

```
Create a 256x256 PNG icon with transparent background.
Style: cyberpunk neon arcade UI, clean 2.5D, bold silhouette, high readability at 32x32.
No text, no numbers, no logos, no watermark.
Lighting: subtle outer neon glow + inner highlights, not over-bloomed.
Palette: dark navy base (#0B1020) with neon accents (cyan #00F5FF, pink #FF4FD8, purple #9B59FF, yellow #FFD84D).
Center the subject, keep generous padding so it doesn’t clip when masked into a rounded square.
Concept: <ICON_CONCEPT_HERE>
```

## Passive Perks (PerkEngine.perkCatalog) — İkon Listesi

Her madde: **perkId → dosya adı → ikon fikri → prompt için Concept**

### `momentum`
- **PNG**: `perk_momentum.png`
- **İkon fikri**: ileri itiş, hız, elektriksel ivme
- **Concept**: “a forward-leaning neon lightning bolt wrapped with motion trails, small arrow chevrons behind it”

### `glass_cannon`
- **PNG**: `perk_glass_cannon.png`
- **İkon fikri**: kırılgan ama güçlü, kristal çekirdek + çatlak
- **Concept**: “a glowing crystal orb with a hairline crack and a sharp energy burst inside”

### `overkill`
- **PNG**: `perk_overkill.png`
- **İkon fikri**: taşan enerji, hedefi aşan hasar
- **Concept**: “a target reticle being pierced by an oversized neon impact wave spilling beyond the circle”

### `last_stand`
- **PNG**: `perk_last_stand.png`
- **İkon fikri**: son anda kurtuluş, kalkan + kalp çekirdeği
- **Concept**: “a compact shield emblem with a heart-shaped neon core and a faint ‘revive’ spark”

### `safe_house`
- **PNG**: `perk_safe_house.png`
- **İkon fikri**: güvenli sığınak, neon çadır / barınak
- **Concept**: “a minimal neon tent/house silhouette with a protective dome glow”

### `echoes`
- **PNG**: `perk_echoes.png`
- **İkon fikri**: yankı/tekrar, ses halkaları
- **Concept**: “concentric neon soundwave rings emanating from a small core node”

### `wide_load`
- **PNG**: `perk_wide_load.png`
- **İkon fikri**: ekstra slot / kapasite, genişleyen tray
- **Concept**: “a block tray module expanding sideways with an added slot highlighted in cyan”

### `clockwork`
- **PNG**: `perk_clockwork.png`
- **İkon fikri**: saat mekanizması, dişli + zaman
- **Concept**: “a neon gear merged with a clock face, subtle tick marks, glowing hands”

### `sculptor`
- **PNG**: `perk_sculptor.png`
- **İkon fikri**: şekil verme, keski/çekiç
- **Concept**: “a stylized neon hammer and chisel forming a clean block silhouette”

### `golden_stamp`
- **PNG**: `perk_golden_stamp.png`
- **İkon fikri**: damga/onay, hedefi düşürme
- **Concept**: “a golden seal stamp pressing onto a simplified score-chip card leaving a glowing imprint”

### `blue_pill`
- **PNG**: `perk_blue_pill.png`
- **İkon fikri**: mavi kapsül + data
- **Concept**: “a blue capsule pill with circuit traces and tiny sparkles, cyber-med style”

### `lucky_clover`
- **PNG**: `perk_lucky_clover.png`
- **İkon fikri**: şans, yonca + neon parıltı
- **Concept**: “a four-leaf clover with a neon rim and small luck particles”

### `lead_pill`
- **PNG**: `perk_lead_pill.png`
- **İkon fikri**: yeşil kapsül + toksik ama güçlü
- **Concept**: “a green capsule pill with biohazard-like micro motif, still sleek and gamey”

### `midas_touch`
- **PNG**: `perk_midas_touch.png`
- **İkon fikri**: altına çevirme, el/parmaksız glove + coin spark
- **Concept**: “a cyber glove fingertip touching a block that turns into gold fragments”

### `vampiric_core`
- **PNG**: `perk_vampiric_core.png`
- **İkon fikri**: yaşam çalma, çekirdek + kan kırmızısı enerji
- **Concept**: “a dark core reactor with crimson neon veins siphoning energy into a small heart spark”

### `recycler`
- **PNG**: `perk_recycler.png`
- **İkon fikri**: geri dönüşüm, döngü okları + tray
- **Concept**: “a clean neon recycle loop around a mini tray block, tech-style”

### `chain_pulse`
- **PNG**: `perk_chain_pulse.png`
- **İkon fikri**: zincirleme etki, bağlantılı düğümler
- **Concept**: “linked neon nodes with a pulse wave traveling along the chain”

### `heavy_duty`
- **PNG**: `perk_heavy_duty.png`
- **İkon fikri**: ağır/industrial, vinç kancası veya ağırlık bloğu
- **Concept**: “a heavy plated cube with hazard stripes and a subtle neon lift hook silhouette”

### `phantom_siphon`
- **PNG**: `perk_phantom_siphon.png`
- **İkon fikri**: hayalet + emiş, sisli siphon
- **Concept**: “a ghostly wisp being siphoned into a vial/tube with neon suction swirl”

### `double_down`
- **PNG**: `perk_double_down.png`
- **İkon fikri**: risk artırma, iki kat bahis
- **Concept**: “two stacked wager chips with a sharp neon X overlay, dynamic and bold”

### `static_charge`
- **PNG**: `perk_static_charge.png`
- **İkon fikri**: statik elektrik, kıvılcım hücre
- **Concept**: “a square grid cell icon with crackling static bolts and a charged aura”

### `tactical_lens`
- **PNG**: `perk_tactical_lens.png`
- **İkon fikri**: hedefleme lensi, HUD nişangah
- **Concept**: “a neon magnifying lens fused with a HUD reticle, scanning line passing through”

## Starting Perks — İkon Listesi (sabit PNG’ye çekilecekler)

Starting perk tarafında da aynı perkId’ler var; burada **starting seçim ekranında** daha “item” hissi verecek versiyon isteniyor.

### `none`
- **PNG**: `start_none.png`
- **Concept**: “a clean ‘empty slot’ token: a hollow neon circle with a small slash mark, no text”

### `blue_pill`
- **PNG**: `start_blue_pill.png` (mevcut: `item_blue_pill`)
- **Concept**: “a premium cyber blue pill with glow capsule halves and micro-circuit engraving”

### `golden_stamp`
- **PNG**: `start_golden_stamp.png` (mevcut: `item_golden_stamp`)
- **Concept**: “a golden wax seal / stamp device with neon rim and a minimal imprint sparkle”

### `lucky_clover`
- **PNG**: `start_lucky_clover.png`
- **Concept**: “a clover charm keychain with neon edge, small floating particles”

### `lead_pill`
- **PNG**: `start_lead_pill.png` (mevcut: `item_green_pill`)
- **Concept**: “a green pill with slightly darker toxic-tech vibe, still readable and cute”

## “Dummy icon” temizliği için entegrasyon notu (kısa)

İkonlar üretildikten sonra:
- `PerkEngine.perkCatalog.icon` alanındaki emoji string’leri → `perk_<id>` asset adına dönüştürülecek.
- `StartingPerk.available.icon` alanındaki emoji / `item_*` string’leri → `start_<id>` asset adına dönüştürülecek.

