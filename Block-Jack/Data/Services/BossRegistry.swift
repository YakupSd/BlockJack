//
//  BossRegistry.swift
//  Block-Jack
//

import Foundation

struct BossEncounter: Identifiable {
    let id: String
    let name: String
    let imageName: String
    let modifier: BossModifier
    let dialogues: [LocalizedDialogueLine]
    
    struct LocalizedDialogueLine: Identifiable {
        let id = UUID()
        let speaker: SpeakerType
        let textTR: String
        let textEN: String
        
        enum SpeakerType {
            case player
            case boss
        }
    }
    
    func getRandomIntent() -> String {
        switch modifier {
        case .fog:
            return ["VERİ SİSİ GELİYOR!", "GÖRÜŞ ALANI DARALIYOR", "SİSTEM KARARMASI BEKLENİYOR"].randomElement()!
        case .glitch:
            return ["GLITCH PROTOKOLÜ 1.0", "GRID BOZULMASI TESPİT EDİLDİ", "SİSTEM HATASI OLUŞTURULUYOR"].randomElement()!
        case .phantom:
            return ["PHANTOM YÜKLENİYOR", "HAYALET BLOKLAR GELİYOR", "GERÇEKLİK KIRILMASI"].randomElement()!
        case .weight:
            return ["AĞIRLIK ARTIŞI!", "AĞIR BLOKLAR YOLDA", "YERÇEKİMİ ANOMALİSİ"].randomElement()!
        }
    }
}

class BossRegistry {
    static let shared = BossRegistry()
    
    let bossesSnapshot: [BossEncounter] = [
        // LEVEL 3 BOSS
        BossEncounter(
            id: "viper_x",
            name: "VIPER X",
            imageName: "boss_viper_x",
            modifier: .fog,
            dialogues: [
                .init(speaker: .boss, textTR: "Sisteminde bir açık buldum küçük Jack. İzleniyorsun.", textEN: "I found a breach in your system, little Jack. You're being watched."),
                .init(speaker: .player, textTR: "Hızın beni korkutamaz Viper. Görüş alanım kapansa bile ritmi biliyorum.", textEN: "Speed doesn't scare me, Viper. Even if my vision fades, I know the rhythm."),
                .init(speaker: .boss, textTR: "Sisin içinde hata yapmanı izlemek... İşte bu gerçek sanat.", textEN: "Watching you fail in the fog... That is true art.")
            ]
        ),
        // LEVEL 5 BOSS
        BossEncounter(
            id: "sentinel_k",
            name: "SENTINEL K",
            imageName: "boss_sentinel_k",
            modifier: .glitch,
            dialogues: [
                .init(speaker: .boss, textTR: "Bu bölge koruma altında. İzinsiz veri girişi tespit edildi.", textEN: "This sector is under protection. Unauthorized data entry detected."),
                .init(speaker: .player, textTR: "Sadece geçip gidiyorum Sentinel. Kuralların benim için geçerli değil.", textEN: "I'm just passing through, Sentinel. Your rules don't apply to me."),
                .init(speaker: .boss, textTR: "O zaman sistemini bozmam gerekecek. Glitch modülü aktif!", textEN: "Then I must corrupt your system. Glitch module activated!")
            ]
        ),
        // LEVEL 10 BOSS
        BossEncounter(
            id: "ghost_mother",
            name: "GHOST MOTHER",
            imageName: "boss_ghost_mother",
            modifier: .phantom,
            dialogues: [
                .init(speaker: .boss, textTR: "Dijital rüyalarımızda sadece biz varız. Neden buradasın?", textEN: "In our digital dreams, only we exist. Why are you here?"),
                .init(speaker: .player, textTR: "Gerçek dünyaya dönmeye çalışıyorum. Gölgelerin beni durduramaz.", textEN: "I'm trying to return to the physical world. Your shadows can't stop me."),
                .init(speaker: .boss, textTR: "Gördüğün yerlerin sadece birer hayalet olduğunu anladığında... çok geç olacak.", textEN: "By the time you realize everything you see is a ghost... it will be too late.")
            ]
        ),
        // LEVEL 15 BOSS
        BossEncounter(
            id: "juggernaut",
            name: "JUGGERNAUT",
            imageName: "boss_juggernaut",
            modifier: .weight,
            dialogues: [
                .init(speaker: .boss, textTR: "Ezilmeye hazır ol. Hafif sıkletlerin burada yeri yok.", textEN: "Prepare to be crushed. Lightweights have no place here."),
                .init(speaker: .player, textTR: "Büyük lokma ye ama büyük konuşma Juggernaut. Esneklik ağırlığı yener.", textEN: "Don't bite off more than you can chew. Flexibility beats gravity."),
                .init(speaker: .boss, textTR: "Bu blokların ağırlığı altında can verirken o esnekliğini göreceğiz!", textEN: "We'll see that flexibility when you're dying under the weight of these blocks!")
            ]
        ),
        // LEVEL 20 BOSS
        BossEncounter(
            id: "neon_overlord",
            name: "NEON OVERLORD",
            imageName: "boss_neon_overlord",
            modifier: .glitch,
            dialogues: [
                .init(speaker: .boss, textTR: "Tüm sistemlerim senin için hazırlandı. Kaçacak yerin yok.", textEN: "Every system I have was built for you. There is no escape."),
                .init(speaker: .player, textTR: "Sen sadece bir yazılımsın Overlord. Ben ise iradeyim.", textEN: "You are just software, Overlord. I am will."),
                .init(speaker: .boss, textTR: "İrade mi? Bu kaosta sadece kodlar baki kalır. PROTOKOL 0'I BAŞLAT!", textEN: "Will? In this chaos, only codes endure. INITIATE PROTOCOL ZERO!")
            ]
        )
    ]
    
    /// Hangi dünya seviyesinde hangi boss çıkar.
    /// ChapterProgression.bossWorldLevels = [1,3,5,7,9,11,15,17,20] ile hizalı.
    /// - 1,3 → Viper X (fog)
    /// - 5,7 → Sentinel K (glitch)
    /// - 9,11 → Ghost Mother (phantom)
    /// - 15,17 → Juggernaut (weight)
    /// - 20+ → Neon Overlord (glitch)
    func getBoss(for worldLevel: Int) -> BossEncounter {
        switch worldLevel {
        case ...3:    return bossesSnapshot[0] // viper_x
        case 4...7:   return bossesSnapshot[1] // sentinel_k
        case 8...11:  return bossesSnapshot[2] // ghost_mother
        case 12...17: return bossesSnapshot[3] // juggernaut
        default:      return bossesSnapshot[4] // neon_overlord (18+)
        }
    }

    /// Verilen boss id'sine karşılık gelen seviye aralığının kullanıcıya
    /// gösterilecek kısa etiketi (Koleksiyon gibi yerlerde "Sektör 1-3"
    /// şeklinde hint olarak gösterilir).
    func levelRangeLabel(for bossId: String) -> String {
        switch bossId {
        case "viper_x":       return "SEKTÖR 1-3"
        case "sentinel_k":    return "SEKTÖR 4-7"
        case "ghost_mother":  return "SEKTÖR 8-11"
        case "juggernaut":    return "SEKTÖR 12-17"
        case "neon_overlord": return "SEKTÖR 18-20"
        default:              return "?"
        }
    }
}
