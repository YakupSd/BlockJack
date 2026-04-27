## 📊 BLOCK-JACK: SCORING ENGINE V2 (Technical Spec)

- **Versiyon**: 2.0  
- **Konsept**: Logaritmik büyüme & stratejik çarpan yönetimi  
- **İlham**: Balatro (Order of Operations) & Block Blast (Spatial Logic)

---

## 1) Temel felsefe ve altın formül

Bu sistem doğrusal artış yerine, doğru dizilim + renk yönetimiyle üstel büyümeyi hedefler. Puanlama 5 ana fazdan geçer.

### Altın Formül

\[
\text{TotalScore}=(\text{BaseChips})\times(1.0+\sum \text{AdditiveMult})\times\prod \text{MultiplicativeMult}
\]

---

## 2) Puanlama fazları (The Pipeline)

### Faz 1: THE SNAP (Yerleştirme baz puanı)

Bloğu grid üzerine bıraktığın an hesaplanan ham değerdir.

- **Block Mass (M)**: Bloğun kapladığı kare sayısı (örn. L-Blok = 4)
- **Neighbor Bonus (N)**: Yerleştirilen konumdaki dolu komşu hücre sayısı  
  Sıkışık yere koymak risklidir, ödüllendirilir.

**Formül**:

\[
\text{BaseChips}=(M\times10)+(N\times5)
\]

---

### Faz 2: DETECTION (Patlama ve renk mühendisliği)

Satır/sütun dolunca tetiklenen **toplamsal çarpan** (+Mult) katmanıdır.

- **Mixed Line**: karışık renk hat → **+1.0**
- **Duo‑Tone**: sadece 2 renk hat → **+2.5**
- **Gradient**: 5 rengin de bulunduğu hat → **+4.5**
- **FLUSH!**: 8 karenin tamamı aynı renk → **+8.0**

#### Combo Stack (aynı anda çoklu hat patlaması)
- 2 hat: **+2.0**
- 3 hat: **+5.0**
- 4 hat (Quad): **+12.0**

---

### Faz 3: JOKER MODIFIERS (Aktif sinerji)

Inventory’deki Joker’lar **soldan sağa** işlenir. Dizilim sırası kritiktir.

- **Additive Jokers (+)**: şartlara göre çarpan ekler  
  Örn: “Mavi hat patlarsa +10 Mult ver.”
- **Scaling Jokers (📈)**: run boyunca biriken değeri ekler  
  Örn: “Bu run boyunca patlattığın her Flush başına +0.5 Mult ver.”

---

### Faz 4: THE X‑FACTOR (Çarpımsal çarpan)

Toplama işlemleri bittikten sonra devreye giren “X‑Mult” katmanıdır. Skorun patladığı yer burasıdır.

- **X‑Mult Jokers**: toplam çarpanı çarpar (örn. Total Mult × 2.0)
- **Streak Bonus**: üst üste başarılı patlatma serisi ( \(1.1^{streak}\) ) bazında çarpan

---

### Faz 5: OVERFLOW (Overkill ekonomisi)

Round hedefi (The Blind) geçildiyse, artan skor ekonomiye dönüşür.

- **Interest**: hedefin her %25 üstüne çıkışında **+2 Altın**
- **Diamond Dust**: hedefin 5 katı skor yapılırsa %10 ihtimalle kalıcı **Elmas**

---

## 3) Örnek hesaplama senaryosu

**Durum**: 4 karelik mavi blok yerleştirildi ve mavi **Flush** yapıldı.

- Joker 1: “Her hamlede +1 Mult verir” (10. hamle → +10)
- Joker 2: “Mavi patlamalarda x1.5 Mult verir”

**İşlem sırası**:

- Base Chips: 40 (kütle) + 10 (komşu) = **50**
- Detection: +8.0 (Flush)
- Joker Additive: +10.0 (Joker 1)
- Toplama: 1.0 (baz) + 8.0 + 10.0 = **19.0 Mult**
- X‑Mult: 19.0 × 1.5 (Joker 2) = **28.5 Mult**

**Final**:

\[
50\times28.5=1425
\]

---

## 4) Teknik implementasyon (Swift)

Senior seviye bir yapı için `ScoreEngine` decouple (bağımsız) olmalıdır.

```swift
struct ScoreContext {
    var baseChips: Double = 0
    var addedMult: Double = 0
    var multiplicativeMult: Double = 1.0

    var finalScore: Int {
        Int(baseChips * (1.0 + addedMult) * multiplicativeMult)
    }
}

protocol JokerEffect {
    func apply(to context: inout ScoreContext, gameEvent: GameEvent)
}
```

---

## 5) UI & hassiyet (Juiciness) önerileri

Puanlama sisteminin derinliğini oyuncuya hissettirmek için şu görsel feedback’ler kritik:

- **Counting Animation**: Chips sayılırken grid üzerinde küçük beyaz sayılar uçar.
- **Mult Flare**: +Mult eklendiğinde sayaç Neon Mor yanıp söner.
- **The Bang**: X‑Mult devreye girdiğinde ekran hafif sarsılır (Haptic: Heavy) ve puan rengi Altın sarısına döner.
- **Order Matters**: Joker sırası UI üzerinde soldan sağa bir ışık hüzmesiyle geçilerek hesaplandığı gösterilir (Balatro benzeri).

