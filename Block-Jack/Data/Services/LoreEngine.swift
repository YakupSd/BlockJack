//
//  LoreEngine.swift
//  Block-Jack
//
//  Lore / dünya metinleri — UI-only içerik katmanı.
//  Keşif durumuna göre (boss discovery) spoiler-free şekilde açılır.
//

import Foundation

struct WorldLore: Identifiable, Codable, Equatable {
    let id: Int            // World number (1..5)
    let titleTR: String
    let titleEN: String
    let bodyTR: String
    let bodyEN: String
}

struct BossLore: Identifiable, Codable, Equatable {
    let id: String         // boss id (viper_x, sentinel_k, ...)
    let titleTR: String
    let titleEN: String
    let bodyTR: String
    let bodyEN: String
}

enum LoreEngine {
    static let worlds: [WorldLore] = [
        WorldLore(
            id: 1,
            titleTR: "DÜNYA 1 — NEON GRID",
            titleEN: "WORLD 1 — NEON GRID",
            bodyTR: """
Neon Grid, dijital şehrin kalbidir: ışıklar canlı, kurallar katıdır.
Jack burada sadece hayatta kalmak için değil, kim olduğunu hatırlamak için savaşır.

Her sektör bir testtir: zaman, ritim ve hata toleransı. Ama asıl tehlike…
sistemin kendi “protokolleri”dir.
""",
            bodyEN: """
Neon Grid is the heart of the digital city: lights are alive, rules are strict.
Jack fights here not only to survive, but to remember who he is.

Each sector is a trial: time, rhythm, and tolerance for error. But the real danger…
is the system’s own “protocols.”
"""
        ),
        WorldLore(
            id: 2,
            titleTR: "DÜNYA 2 — CONCRETE RUINS",
            titleEN: "WORLD 2 — CONCRETE RUINS",
            bodyTR: """
Beton Harabeler’de neon söner, yankı kalır. Paslı duvarlar ve kırık veri kanalları…
burada her adım bir kayıp paket gibi hissedilir.

Jack’in karşısında sadece düşmanlar değil, çöküşün kendisi vardır.
""",
            bodyEN: """
In the Concrete Ruins, neon fades and only echoes remain. Rusted walls and broken data channels…
every step feels like a lost packet.

Jack faces not only enemies here, but collapse itself.
"""
        ),
        WorldLore(
            id: 3,
            titleTR: "DÜNYA 3 — CANDY LAB",
            titleEN: "WORLD 3 — CANDY LAB",
            bodyTR: """
Candy Lab parlak görünür: pastel renkler, sevimli simgeler, şeker gibi bir arayüz.
Ama “tatlı” olan sadece kaplamadır. Altında deneyler, senkron hataları ve sahte ödüller yatar.

Burada kural basit: Gördüğüne güvenme.
""",
            bodyEN: """
Candy Lab looks bright: pastel colors, cute icons, a sugar-coated interface.
But the “sweetness” is only the surface. Underneath are experiments, sync errors, and fake rewards.

The rule here is simple: Don’t trust what you see.
"""
        ),
        WorldLore(
            id: 4,
            titleTR: "DÜNYA 4 — DEEP ABYSS",
            titleEN: "WORLD 4 — DEEP ABYSS",
            bodyTR: """
Deep Abyss’te ışık azalır, sessizlik artar. Biyolüminesans noktalar…
gerçek mi, yoksa sadece dikkat dağıtıcı mı?

Jack burada zamanla değil, “boşluk”la pazarlık eder.
""",
            bodyEN: """
In the Deep Abyss, light fades and silence grows. Bioluminescent specks…
are they real, or just distractions?

Here, Jack bargains not with time, but with the void.
"""
        ),
        WorldLore(
            id: 5,
            titleTR: "DÜNYA 5 — CORE SINGULARITY",
            titleEN: "WORLD 5 — CORE SINGULARITY",
            bodyTR: """
Core Singularity sistemin merkezidir: tüm protokoller burada doğar ve burada ölür.
Manyetik çizgiler, çekirdek pulse’ları… sanki şehir kendi kalbini dinletir.

Bu noktadan sonra “kaçış” yok. Sadece karar var.
""",
            bodyEN: """
Core Singularity is the system’s center: every protocol is born here—and dies here.
Magnetic streaks, core pulses… the city forces you to hear its heartbeat.

After this point, there is no “escape.” Only a decision.
"""
        )
    ]

    static let bosses: [BossLore] = [
        BossLore(
            id: "viper_x",
            titleTR: "VIPER X",
            titleEN: "VIPER X",
            bodyTR: """
Viper X hızın kendisidir. Sis onun silahı, panik senin zayıflığındır.
Zamanı göremediğinde ritmin ne kadar sağlam?
""",
            bodyEN: """
Viper X is speed incarnate. Fog is its weapon; panic is your weakness.
When you can’t see the time—how strong is your rhythm?
"""
        ),
        BossLore(
            id: "sentinel_k",
            titleTR: "SENTINEL K",
            titleEN: "SENTINEL K",
            bodyTR: """
Sentinel K bir bekçidir. Kilitler, kurallar, sınırlar…
Sistemi korumak için gerçekliği bozar.
""",
            bodyEN: """
Sentinel K is a warden. Locks, rules, boundaries…
It corrupts reality to protect the system.
"""
        ),
        BossLore(
            id: "ghost_mother",
            titleTR: "GHOST MOTHER",
            titleEN: "GHOST MOTHER",
            bodyTR: """
Ghost Mother görünmeyeni sever. Phantom katmanı, şüpheyi büyütür:
Gördüğün bloklar gerçek mi, yoksa sadece bir yankı mı?
""",
            bodyEN: """
Ghost Mother thrives in the unseen. The phantom layer breeds doubt:
Are the blocks you see real—or just an echo?
"""
        ),
        BossLore(
            id: "juggernaut",
            titleTR: "JUGGERNAUT",
            titleEN: "JUGGERNAUT",
            bodyTR: """
Juggernaut ağırlıktır. Heavy hücreler iki kez kırılır; sabırsızlık cezalandırılır.
Güç mü, plan mı? Burada ikisi de gerekir.
""",
            bodyEN: """
Juggernaut is weight. Heavy cells must be broken twice; impatience is punished.
Power or planning? Here, you need both.
"""
        ),
        BossLore(
            id: "neon_overlord",
            titleTR: "NEON OVERLORD",
            titleEN: "NEON OVERLORD",
            bodyTR: """
Neon Overlord, protokolün ta kendisidir. Kaosu bir tasarım gibi kullanır.
Bu savaş bir final değil; bir “kilit açma” anıdır.
""",
            bodyEN: """
Neon Overlord is the protocol itself. It uses chaos like design.
This fight isn’t an ending—it’s an “unlock” moment.
"""
        )
    ]

    static func worldLore(for world: Int) -> WorldLore? {
        worlds.first(where: { $0.id == world })
    }

    static func bossLore(for bossId: String) -> BossLore? {
        bosses.first(where: { $0.id == bossId })
    }
}

