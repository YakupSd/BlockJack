//
//  DuelGamePlayView.swift
//  Block-Jack
//

import SwiftUI

struct DuelGamePlayView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let duel: DuelChallenge
    @StateObject private var gameVM: DuelGameViewModel
    
    init(duel: DuelChallenge) {
        self.duel = duel
        _gameVM = StateObject(
            wrappedValue: DuelGameViewModel(duel: duel, playerID: "player")
        )
    }
    
    private var opponentName: String {
        duel.challengedID == "player" || duel.challengedID == "current_player"
            ? duel.challengerName
            : duel.challengedName
    }
    
    var body: some View {
        ZStack {
            ThemeColors.backgroundGradient.ignoresSafeArea()
            
            GameView(slotId: -1, nodeType: nil, eventConfig: duelEventConfig())
        }
        .navigationBarHidden(true)
        .onChange(of: gameVM.isGameOver) { oldVal, newVal in
            if newVal {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    MainViewsRouter.shared.nav?.popViewController(animated: true)
                }
            }
        }
    }
    
    // MARK: - Helper: Convert Duel to EventConfig
    private func duelEventConfig() -> EventConfig {
        // Duel mode: EventConfig from duel data
        // Blok kuyruğu GameViewModel init ile seed'den üretilecek
        let now = Date()
        return EventConfig(
            id: duel.id,
            type: .daily,  // Mock type
            title: "DÜELLO",
            description: "PvP Düello Modu",
            startsAt: now,
            endsAt: now.addingTimeInterval(180), // 3 dakika
            modifiers: [
                EventModifier(
                    id: "duel_infinite_time",
                    type: .infiniteTime,
                    value: 1,
                    description: "Sonsuz Zaman",
                    iconName: "icon_time"
                )
            ],
            boss: EventBoss(
                id: "duel_neutral",
                name: "RAKIP",
                description: "Düello Modu",
                spriteKey: "cyber_battle_arena",
                intents: [],
                intentCycle: 0
            ),
            character: nil,
            rewards: [],
            rankingMetric: .score
        )
    }
}

#Preview {
    DuelGamePlayView(
        duel: DuelChallenge(
            challengerID: "player",
            challengerName: "Siz",
            challengedID: "opp1",
            challengedName: "BLOCKZILLA",
            stakeAmount: 500,
            status: .accepted
        )
    )
    .environmentObject(UserEnvironment.shared)
}
