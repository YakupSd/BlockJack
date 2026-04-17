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
    let dialogues: [DialogueLine]
    
    struct DialogueLine: Identifiable {
        let id = UUID()
        let speaker: SpeakerType
        let text: String
        
        enum SpeakerType {
            case player
            case boss
        }
    }
}

class BossRegistry {
    static let shared = BossRegistry()
    
    let bosses: [BossEncounter] = [
        BossEncounter(
            id: "viper_x",
            name: "VIPER X",
            imageName: "boss_viper_x",
            modifier: .fog,
            dialogues: [
                .init(speaker: .boss, text: "Sisteminde bir açık buldum küçük Jack. İzleniyorsun."),
                .init(speaker: .player, text: "Hızın beni korkutamaz Viper. Görüş alanım kapansa bile ritmi biliyorum."),
                .init(speaker: .boss, text: "Sisin içinde hata yapmanı izlemek... İşte bu gerçek sanat.")
            ]
        ),
        BossEncounter(
            id: "sentinel_k",
            name: "SENTINEL K",
            imageName: "boss_sentinel_k",
            modifier: .glitch,
            dialogues: [
                .init(speaker: .boss, text: "Bu bölge koruma altında. İzinsiz veri girişi tespit edildi."),
                .init(speaker: .player, text: "Sadece geçip gidiyorum Sentinel. Kuralların benim için geçerli değil."),
                .init(speaker: .boss, text: "O zaman sistemini bozmam gerekecek. Glitch modülü aktif!")
            ]
        ),
        BossEncounter(
            id: "ghost_mother",
            name: "GHOST MOTHER",
            imageName: "boss_ghost_mother",
            modifier: .phantom,
            dialogues: [
                .init(speaker: .boss, text: "Dijital rüyalarımızda sadece biz varız. Neden buradasın?"),
                .init(speaker: .player, text: "Gerçek dünyaya dönmeye çalışıyorum. Gölgelerin beni durduramaz."),
                .init(speaker: .boss, text: "Gördüğün yerlerin sadece birer hayalet olduğunu anladığında... çok geç olacak.")
            ]
        ),
        BossEncounter(
            id: "juggernaut",
            name: "JUGGERNAUT",
            imageName: "boss_juggernaut",
            modifier: .weight,
            dialogues: [
                .init(speaker: .boss, text: "Ezilmeye hazır ol. Hafif sıkletlerin burada yeri yok."),
                .init(speaker: .player, text: "Büyük lokma ye ama büyük konuşma Juggernaut. Esneklik ağırlığı yener."),
                .init(speaker: .boss, text: "Bu blokların ağırlığı altında can verirken esnekliğini göreceğiz!")
            ]
        ),
        BossEncounter(
            id: "neon_overlord",
            name: "NEON OVERLORD",
            imageName: "boss_neon_overlord",
            modifier: .glitch, // Combinations can be added later
            dialogues: [
                .init(speaker: .boss, text: "Tüm sistemlerim senin için hazırlandı. Kaçacak yerin yok."),
                .init(speaker: .player, text: "Sen sadece bir yazılımsın Overlord. Ben ise iradeyim."),
                .init(speaker: .boss, text: "İrade mi? Bu kaosta sadece kodlar baki kalır. SONYA, PROTOKOL 0'I BAŞLAT!")
            ]
        )
    ]
    
    func getBoss(for chapter: Int) -> BossEncounter {
        let index = (chapter - 1) % bosses.count
        return bosses[index]
    }
}
