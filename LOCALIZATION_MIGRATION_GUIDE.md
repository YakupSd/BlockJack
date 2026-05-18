# Localization Migration Guide
## SwiftUI Projesi — `localizedString()` → `userEnv.<property>` Geçişi

---

## GENEL BAĞLAM

Bu proje bir SwiftUI iOS uygulamasıdır. Şu anda kullanılan lokalizasyon sistemi `userEnv.localizedString("TR_METIN", "EN_METIN")` şeklinde çalışmaktadır. Bu yaklaşım 2 dil için işe yarıyordu, ancak 5+ dile genişletmek için sürdürülebilir değil.

**Hedef:** Tüm string ifadeler `UserEnvironment` içinde dil-başına computed property olarak tanımlanacak. Kullanım `Text(userEnv.btnApprove)` şeklinde olacak.

---

## MEVCUT YAPI (ESKİ — DEĞİŞTİRİLECEK)

### UserEnvironment (mevcut hali, özet):
```swift
class UserEnvironment: ObservableObject {
    @Published var language: String = "TR" // "TR" veya "EN"

    func localizedString(_ tr: String, _ en: String) -> String {
        switch language {
        case "EN": return en
        default:   return tr
        }
    }
}
```

### Kullanım (mevcut — DEĞİŞECEK):
```swift
Text(userEnv.localizedString("En İyi:", "Best:"))
Text(userEnv.localizedString("PUAN", "SCORE"))
Text(userEnv.localizedString("Onayla", "Approve"))
Button(userEnv.localizedString("Vazgeç", "Cancel")) { ... }
```

---

## YENİ YAPI (HEDEF)

### Adım 1 — Desteklenen diller enum olarak tanımlanır:
```swift
enum AppLanguage: String, CaseIterable {
    case tr = "TR"
    case en = "EN"
    case de = "DE"   // Almanca
    case es = "ES"   // İspanyolca
    case zh = "ZH"   // Çince
}
```

### Adım 2 — UserEnvironment içinde her string bir computed property olur:
```swift
class UserEnvironment: ObservableObject {
    @Published var language: AppLanguage = .tr

    // MARK: - Genel / Butonlar
    var btnApprove: String {
        switch language {
        case .tr: return "Onayla"
        case .en: return "Approve"
        case .de: return "Genehmigen"
        case .es: return "Aprobar"
        case .zh: return "批准"
        }
    }

    var btnCancel: String {
        switch language {
        case .tr: return "Vazgeç"
        case .en: return "Cancel"
        case .de: return "Abbrechen"
        case .es: return "Cancelar"
        case .zh: return "取消"
        }
    }

    // MARK: - Oyun / Skor Ekranı
    var labelBestScore: String {
        switch language {
        case .tr: return "En İyi"
        case .en: return "Best"
        case .de: return "Bestleistung"
        case .es: return "Mejor"
        case .zh: return "最佳"
        }
    }

    var labelScore: String {
        switch language {
        case .tr: return "Puan"
        case .en: return "Score"
        case .de: return "Punkte"
        case .es: return "Puntuación"
        case .zh: return "分数"
        }
    }

    // ... (diğer tüm stringler aynı pattern ile eklenir)
}
```

### Adım 3 — Kullanım (yeni — HEDEF):
```swift
// Basit label
Text(userEnv.labelScore)

// Değer içeren format — interpolation dışarıda yapılır
Text("\(userEnv.labelBestScore): \(transition.bestScore.formatted())")

// Buton
Button(userEnv.btnCancel) { ... }
```

---

## YAPAY ZEKADAN İSTENECEK DÖNÜŞÜM GÖREVİ

### Görev Tanımı:
Aşağıda verilen Swift dosyalarını tara. İçinde geçen **her statik Türkçe/İngilizce string ifadeyi** bul. Bunları:

1. `UserEnvironment` içinde uygun bir `var propertyName: String { switch language { ... } }` bloğu olarak tanımla.
2. Orijinal kullanım yerlerinde `Text("sabit yazı")` veya `userEnv.localizedString(...)` yerine `Text(userEnv.propertyName)` kullan.

### Kurallar:
- **Interpolation içeren stringler** bölünür: sabit kısım property olur, dinamik değer dışarıda eklenir.
  - ESKİ: `Text("En İyi: \(score.formatted())")`
  - YENİ: `Text("\(userEnv.labelBestScore): \(score.formatted())")`
- **Property isimlendirme kuralı:**
  - Butonlar: `btn` prefix — `btnApprove`, `btnCancel`, `btnRetry`
  - Label/başlık: `label` prefix — `labelScore`, `labelBestScore`
  - Mesajlar: `msg` prefix — `msgGameOver`, `msgNoInternet`
  - Başlık (büyük ekran): `title` prefix — `titleMainMenu`
  - Placeholder: `placeholder` prefix — `placeholderSearch`
- **Hiçbir View dosyasında Türkçe veya İngilizce hardcoded string bırakılmaz** (SF Symbol isimleri, URL'ler, identifier'lar hariç).
- `userEnv.localizedString(...)` çağrısı **sıfırlanır**, bu fonksiyon silinir veya deprecated işaretlenir.
- Yeni `AppLanguage` enum eklenmezse, mevcut `String` tabanlı `language` property'si korunabilir ama switch case'ler `"TR"`, `"EN"` gibi string literal ile yazılır.

---

## ÖRNEK DÖNÜŞÜM (Referans)

### ÖNCE:
```swift
// GameOverView.swift
Text("En İyi: \(transition.bestScore.formatted())")
Text(userEnv.localizedString("PUAN", "SCORE"))
Button(userEnv.localizedString("Tekrar Oyna", "Play Again")) {
    viewModel.restart()
}
```

### SONRA:
```swift
// GameOverView.swift
Text("\(userEnv.labelBestScore): \(transition.bestScore.formatted())")
Text(userEnv.labelScore)
Button(userEnv.btnPlayAgain) {
    viewModel.restart()
}

// UserEnvironment.swift — eklenen propertyler:
var labelBestScore: String {
    switch language {
    case .tr: return "En İyi"
    case .en: return "Best"
    case .de: return "Bestleistung"
    case .es: return "Mejor"
    case .zh: return "最佳"
    }
}

var labelScore: String {
    switch language {
    case .tr: return "Puan"
    case .en: return "Score"
    case .de: return "Punkte"
    case .es: return "Puntuación"
    case .zh: return "分数"
    }
}

var btnPlayAgain: String {
    switch language {
    case .tr: return "Tekrar Oyna"
    case .en: return "Play Again"
    case .de: return "Nochmal spielen"
    case .es: return "Jugar de nuevo"
    case .zh: return "再玩一次"
    }
}
```

---

## DOSYA LİSTESİ VE YAPAY ZEKA TALİMATI

Yapay zekaya şu prompt verilecektir:

```
Aşağıdaki Swift kaynak dosyalarını analiz et.
Yukarıdaki Migration Guide kurallarına göre:
1. UserEnvironment.swift içine tüm lokalize edilmesi gereken stringleri computed property olarak ekle.
2. Her View dosyasındaki hardcoded ve localizedString() kullanımlarını yeni property'lerle değiştir.
3. Değiştirilen her dosyanın tam halini döndür.
4. Hangi stringleri bulduğunu ve hangi property ismini verdiğini bir özet tabloda listele.
```

---

## NOTLAR

- İleride yeni dil eklemek için sadece `AppLanguage` enum'a yeni case eklenir ve her property'ye yeni `case .xx: return "..."` satırı eklenir. View dosyaları **hiç değişmez**.
- Çince, Arapça gibi sağdan-sola veya çok farklı dillerde string doğruluğunu bir native speaker veya çeviri servisiyle doğrula; yapay zeka placeholder çeviri koyabilir.
- Bu migration tamamlandıktan sonra Apple'ın `.strings` / `Localizable.xcstrings` sistemiyle **entegre edilmesi gerekmez** — bu yapı onu tamamen bypass eder ve runtime'da `UserEnvironment.language` üzerinden çalışır.
