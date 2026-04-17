//
//  BossDialogueOverlay.swift
//  Block-Jack
//

import SwiftUI

struct BossDialogueOverlay: View {
    @ObservedObject var vm: GameViewModel
    @EnvironmentObject var userEnv: UserEnvironment
    
    @State private var currentLineIndex = 0
    @State private var animateText = false
    @State private var showBoss = false
    @State private var showPlayer = false
    
    let boss: BossEncounter
    
    var currentLine: BossEncounter.DialogueLine {
        boss.dialogues[currentLineIndex]
    }
    
    var playerPortrait: String {
        guard let charId = vm.activeCharacterId,
              let char = GameCharacter.roster.first(where: { $0.id == charId }) else {
            return "port_architect"
        }
        return char.icon // e.g. "port_architect"
    }
    
    var body: some View {
        ZStack {
            // Dark comic background
            Color.black.opacity(0.95).ignoresSafeArea()
            
            // Background grid pattern
            GridPattern()
                .stroke(ThemeColors.gridStroke.opacity(0.1), lineWidth: 1)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Comic Panel Area
                ZStack {
                    // Boss Portrait (Right)
                    HStack {
                        Spacer()
                        Image(boss.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 300)
                            .offset(x: showBoss ? 0 : 200)
                            .opacity(showBoss ? 1 : 0)
                            .mask(
                                LinearGradient(gradient: Gradient(colors: [.black, .black, .clear]), startPoint: .leading, endPoint: .trailing)
                            )
                            .shadow(color: ThemeColors.neonPink.opacity(0.5), radius: 20)
                    }
                    
                    // Player Portrait (Left)
                    HStack {
                        Image(playerPortrait)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 250)
                            .offset(x: showPlayer ? 0 : -200)
                            .opacity(showPlayer ? 1 : 0)
                            .mask(
                                LinearGradient(gradient: Gradient(colors: [.clear, .black, .black]), startPoint: .leading, endPoint: .trailing)
                            )
                            .shadow(color: ThemeColors.neonCyan.opacity(0.5), radius: 20)
                        Spacer()
                    }
                    
                    // Speech Bubble
                    VStack {
                        Spacer()
                        HStack {
                            if currentLine.speaker == .boss { Spacer() }
                            
                            SpeechBubble(text: currentLine.text, speaker: currentLine.speaker)
                                .padding(.horizontal, 20)
                                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                                .id(currentLineIndex)
                            
                            if currentLine.speaker == .player { Spacer() }
                        }
                        .padding(.bottom, 120)
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Advance Indicator
                HStack {
                    Text(currentLineIndex < boss.dialogues.count - 1 ? "DEVAM ET >>" : "SAVAŞA BAŞLA!")
                        .font(.setCustomFont(name: .InterBlack, size: 14))
                        .foregroundStyle(ThemeColors.electricYellow)
                        .padding()
                        .onTapGesture {
                            advanceDialogue()
                        }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6)) {
                showBoss = true
                showPlayer = true
            }
        }
        .onTapGesture {
            advanceDialogue()
        }
    }
    
    private func advanceDialogue() {
        HapticManager.shared.play(.selection)
        if currentLineIndex < boss.dialogues.count - 1 {
            withAnimation {
                currentLineIndex += 1
            }
        } else {
            // Dialogue finished
            vm.startBossFightAfterDialogue()
        }
    }
}

struct SpeechBubble: View {
    let text: String
    let speaker: BossEncounter.DialogueLine.SpeakerType
    
    var body: some View {
        VStack(alignment: speaker == .boss ? .trailing : .leading, spacing: 5) {
            Text(speaker == .boss ? "TARGET" : "SYSTEM")
                .font(.setCustomFont(name: .InterBlack, size: 10))
                .foregroundStyle(speaker == .boss ? ThemeColors.neonPink : ThemeColors.neonCyan)
                .tracking(2)
            
            Text(text)
                .font(.setCustomFont(name: .InterBold, size: 18))
                .foregroundStyle(.white)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(speaker == .boss ? ThemeColors.neonPink : ThemeColors.neonCyan, lineWidth: 2)
                        )
                )
        }
        .frame(maxWidth: 280, alignment: speaker == .boss ? .trailing : .leading)
    }
}

struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 40
        for x in stride(from: 0, through: rect.width, by: step) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        for y in stride(from: 0, through: rect.height, by: step) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        return path
    }
}
