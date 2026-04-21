//
//  BossDialogueOverlay.swift
//  Block-Jack
//

import SwiftUI

struct BossDialogueOverlay: View {
    @ObservedObject var vm: GameViewModel
    @EnvironmentObject var userEnv: UserEnvironment
    
    @State private var currentLineIndex = 0
    @State private var showUI = false
    
    let boss: BossEncounter
    
    var currentLine: BossEncounter.LocalizedDialogueLine {
        boss.dialogues[currentLineIndex]
    }
    
    var playerPortrait: String {
        guard let charId = vm.activeCharacterId,
              let char = GameCharacter.roster.first(where: { $0.id == charId }) else {
            return "port_architect"
        }
        return char.icon
    }
    
    var body: some View {
        ZStack {
            // Dark base
            Color.black.ignoresSafeArea()
            
            VStack(spacing: -60) { // Overlap for slanted effect
                // PLAYER PANEL (Top)
                ZStack(alignment: .topLeading) {
                    Image(playerPortrait)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 450, height: 400) // Fixed size for slant control
                        .clipped()
                        .grayscale(currentLine.speaker == .boss ? 0.4 : 0)
                        .opacity(currentLine.speaker == .boss ? 0.4 : 1.0)
                        .offset(x: currentLine.speaker == .player ? 0 : -20)
                    
                    // Slant mask
                    if currentLine.speaker == .player {
                        LuminescentSpeechBubble(
                            text: userEnv.language == .turkish ? currentLine.textTR : currentLine.textEN,
                            speaker: .player,
                            speakerName: userEnv.localizedString("SİBER ŞÖVALYE", "CYBER KNIGHT")
                        )
                        .padding(.top, 60)
                        .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .opacity))
                    }
                }
                .mask(
                    UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 100, topTrailingRadius: 0)
                        .rotationEffect(.degrees(-5))
                        .offset(y: -20)
                )
                .zIndex(currentLine.speaker == .player ? 1 : 0)
                
                // BOSS PANEL (Bottom)
                ZStack(alignment: .bottomTrailing) {
                    Image(boss.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 450, height: 400)
                        .clipped()
                        .grayscale(currentLine.speaker == .player ? 0.4 : 0)
                        .opacity(currentLine.speaker == .player ? 0.4 : 1.0)
                        .offset(x: currentLine.speaker == .boss ? 0 : 20)
                        .overlay(
                            // Boss Glitch Effect when speaking
                            Group {
                                if currentLine.speaker == .boss {
                                    Color.red.opacity(0.1)
                                        .blendMode(.overlay)
                                }
                            }
                        )
                    
                    if currentLine.speaker == .boss {
                        LuminescentSpeechBubble(
                            text: userEnv.language == .turkish ? currentLine.textTR : currentLine.textEN,
                            speaker: .boss,
                            speakerName: boss.name.uppercased()
                        )
                        .padding(.bottom, 120)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                    }
                }
                .mask(
                    UnevenRoundedRectangle(topLeadingRadius: 100, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 0)
                        .rotationEffect(.degrees(-5))
                        .offset(y: 20)
                )
            }
            
            // Central VS Badge
            VSBadge()
                .offset(x: -20, y: -20)
            
            // Action Button
            VStack {
                Spacer()
                Button(action: advanceDialogue) {
                    Text(currentLineIndex < boss.dialogues.count - 1 ? 
                         userEnv.localizedString("DEVAM ET", "CONTINUE") : 
                         userEnv.localizedString("SAVAŞI BAŞLAT", "INITIATE COMBAT"))
                        .font(.setCustomFont(name: .InterExtraBold, size: 16))
                        .foregroundStyle(Color.black)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(ThemeColors.electricYellow)
                        .clipShape(Capsule())
                        .shadow(color: ThemeColors.electricYellow.opacity(0.4), radius: 15)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentLineIndex)
        .onAppear {
            withAnimation { showUI = true }
        }
    }
    
    private func advanceDialogue() {
        HapticManager.shared.play(.selection)
        if currentLineIndex < boss.dialogues.count - 1 {
            currentLineIndex += 1
        } else {
            vm.startBossFightAfterDialogue()
        }
    }
}

// MARK: - Components

struct LuminescentSpeechBubble: View {
    let text: String
    let speaker: BossEncounter.LocalizedDialogueLine.SpeakerType
    let speakerName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(speakerName)
                .font(.setCustomFont(name: .InterBlack, size: 12))
                .foregroundStyle(speaker == .boss ? ThemeColors.neonPink : ThemeColors.neonCyan)
                .tracking(2)
            
            Text(text)
                .font(.setCustomFont(name: .InterBold, size: 18))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(speaker == .boss ? ThemeColors.neonPink : ThemeColors.neonCyan, lineWidth: 1)
                )
        )
        .shadow(color: (speaker == .boss ? ThemeColors.neonPink : ThemeColors.neonCyan).opacity(0.2), radius: 20)
        .padding(.horizontal, 40)
    }
}

struct VSBadge: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(ThemeColors.surfaceContainerLowest.opacity(0.5))
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .stroke(ThemeColors.glassGradient, lineWidth: 1)
                )
                .blur(radius: 0.5)
            
            VisualEffectBlur(blurStyle: .systemUltraThinMaterialLight)
                .frame(width: 110, height: 110)
                .clipShape(Circle())
            
            Text("VS")
                .font(.setCustomFont(name: .ManropeExtraBold, size: 48))
                .foregroundStyle(ThemeColors.luminescentPrimary.opacity(0.8))
                .shadow(color: ThemeColors.luminescentPrimary.opacity(0.2), radius: 10)
        }
        .shadow(color: Color.black.opacity(0.1), radius: 30)
    }
}

// Blur effect helper is now in UIComponents.swift
