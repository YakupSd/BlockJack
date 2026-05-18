//
//  HowToPlayView.swift
//  Block-Jack
//
//  Elite Step-by-Step Tutorial Guide.
//

import SwiftUI

struct TutorialStep: Identifiable {
    let id = UUID()
    let titleTR: String
    let titleEN: String
    let descriptionTR: String
    let descriptionEN: String
    let imageName: String

    func title(for lang: AppLanguage) -> String {
        lang == .turkish ? titleTR : titleEN
    }

    func description(for lang: AppLanguage) -> String {
        lang == .turkish ? descriptionTR : descriptionEN
    }
}

struct HowToPlayView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @Environment(\.dismiss) var dismiss
    
    @State private var currentPage = 0
    
    let steps = [
        TutorialStep(
            titleTR: "Blok Yerleştirme",
            titleEN: "Placing Blocks",
            descriptionTR: "Blokları sürükleyerek 10x10'luk alana yerleştir. Stratejik davran, alanın dolarsa oyun biter!",
            descriptionEN: "Drag and drop blocks onto the 10x10 grid. Think ahead, if you run out of space, it's game over!",
            imageName: "tutorial_step_1_basics"
        ),
        TutorialStep(
            titleTR: "21 Kuralı (Blackjack)",
            titleEN: "The 21 Rule",
            descriptionTR: "Bir satır veya sütun toplamda tam 21 puan ederse o hat temizlenir ve dev puan kazanırsın!",
            descriptionEN: "If a row or column sums up to exactly 21, it clears and you earn massive points!",
            imageName: "tutorial_step_2_blackjack"
        ),
        TutorialStep(
            titleTR: "Kombolar & Çarpanlar",
            titleEN: "Combos & Multipliers",
            descriptionTR: "Aynı anda birden fazla satır silerek kombo yap ve puan çarpanını göklere çıkar!",
            descriptionEN: "Clear multiple lines at once to trigger combos and boost your score multiplier to the sky!",
            imageName: "tutorial_step_3_combos"
        ),
        TutorialStep(
            titleTR: "Perkler & Güçler",
            titleEN: "Perks & Powers",
            descriptionTR: "Oyun içinde topladığın perklerle kritik anlarda avantaj sağla. Her karakterin kendine has güçleri vardır.",
            descriptionEN: "Use perks collected during the game to gain edges. Each character has unique powers to master.",
            imageName: "tutorial_step_4_perks"
        )
    ]
    
    var body: some View {
        ZStack {
            ThemeColors.cosmicBlack.ignoresSafeArea()
            
            // Subtle glow
            Circle()
                .fill(ThemeColors.neonCyan.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(y: -200)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(userEnv.labelHowToPlayQuestionCaps)
                        .font(.setCustomFont(name: .InterBlack, size: 24))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button {
                        HapticManager.shared.play(.buttonTap)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(ThemeColors.textMuted)
                    }
                }
                .padding(24)
                
                // Content
                TabView(selection: $currentPage) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        stepView(steps[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Footer (Dots & Button)
                VStack(spacing: 20) {
                    // Custom Page Indicators
                    HStack(spacing: 8) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            Capsule()
                                .fill(currentPage == index ? ThemeColors.neonCyan : Color.white.opacity(0.2))
                                .frame(width: currentPage == index ? 24 : 8, height: 8)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    
                    Button {
                        HapticManager.shared.play(.buttonTap)
                        if currentPage < steps.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text(currentPage == steps.count - 1 ? 
                             userEnv.btnGotItCaps : 
                             userEnv.btnNextCaps)
                            .font(.setCustomFont(name: .InterBlack, size: 18))
                            .foregroundStyle(ThemeColors.cosmicBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(ThemeColors.neonCyan)
                                    .shadow(color: ThemeColors.neonCyan.opacity(0.4), radius: 10)
                            )
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func stepView(_ step: TutorialStep) -> some View {
        VStack(spacing: 30) {
            // Main Image
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 300)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                Image(step.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
            }
            .padding(.horizontal, 24)
            
            // Text Content
            VStack(spacing: 12) {
                Text(step.title(for: userEnv.language))
                    .font(.setCustomFont(name: .InterBlack, size: 28))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text(step.description(for: userEnv.language))
                    .font(.setCustomFont(name: .InterMedium, size: 16))
                    .foregroundStyle(ThemeColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
            
            Spacer()
        }
    }
}

#Preview {
    HowToPlayView()
        .environmentObject(UserEnvironment.shared)
}
