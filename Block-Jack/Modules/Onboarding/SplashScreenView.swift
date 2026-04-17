//
//  SplashScreenView.swift
//  Block-Jack
//

import SwiftUI

struct SplashScreenView: View {
    var onFinished: () -> Void
    
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0.0
    @State private var glowRadius: CGFloat = 0
    @State private var loadingOpacity: Double = 0.0
    @State private var loadingText: String = "BOOTING..."
    @State private var screenOpacity: Double = 1.0
    @State private var loadingIndex: Int = 0
    
    private let loadingMessages = [
        "BOOTING...",
        "LOADING SYNTH-GRID...",
        "CALIBRATING NEON MATRIX...",
        "INITIALIZING OVERDRIVE...",
        "SYSTEM READY."
    ]
    
    var body: some View {
        ZStack {
            // MARK: - Background
            ThemeColors.backgroundGradient
                .ignoresSafeArea()
            
            // Synthwave grid pattern
            Canvas { ctx, size in
                let spacing: CGFloat = 40
                for x in stride(from: 0, through: size.width, by: spacing) {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    ctx.stroke(path, with: .color(ThemeColors.neonCyan.opacity(0.08)), lineWidth: 0.5)
                }
                for y in stride(from: 0, through: size.height, by: spacing) {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    ctx.stroke(path, with: .color(ThemeColors.neonCyan.opacity(0.08)), lineWidth: 0.5)
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // MARK: - Logo Area
                ZStack {
                    // Outer neon glow ring
                    Circle()
                        .stroke(ThemeColors.electricYellow.opacity(0.15), lineWidth: 1)
                        .frame(width: 220, height: 220)
                        .shadow(color: ThemeColors.electricYellow.opacity(0.3), radius: glowRadius)
                        .scaleEffect(logoScale * 1.1)
                    
                    Circle()
                        .stroke(ThemeColors.neonCyan.opacity(0.1), lineWidth: 1)
                        .frame(width: 280, height: 280)
                        .shadow(color: ThemeColors.neonCyan.opacity(0.2), radius: glowRadius * 0.7)
                        .scaleEffect(logoScale * 1.05)
                    
                    // App Icon / Logo
                    ZStack {
                        RoundedRectangle(cornerRadius: 36)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hue: 0.78, saturation: 0.8, brightness: 0.25),
                                        Color(hue: 0.72, saturation: 0.9, brightness: 0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 160, height: 160)
                            .shadow(color: ThemeColors.electricYellow.opacity(0.5), radius: glowRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: 36)
                                    .stroke(
                                        LinearGradient(
                                            colors: [ThemeColors.electricYellow.opacity(0.8), ThemeColors.neonCyan.opacity(0.4)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                        
                        VStack(spacing: 4) {
                            // B-J Logo
                            HStack(spacing: 2) {
                                Text("B")
                                    .font(.system(size: 52, weight: .black, design: .rounded))
                                    .foregroundStyle(ThemeColors.electricYellow)
                                Text("J")
                                    .font(.system(size: 52, weight: .black, design: .rounded))
                                    .foregroundStyle(ThemeColors.neonCyan)
                            }
                            .shadow(color: ThemeColors.electricYellow, radius: 8)
                            
                            // Block grid mini art
                            HStack(spacing: 3) {
                                ForEach(0..<3, id: \.self) { col in
                                    VStack(spacing: 3) {
                                        ForEach(0..<2, id: \.self) { row in
                                            let isYellow = (row + col) % 2 == 0
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(isYellow ? ThemeColors.electricYellow : ThemeColors.neonCyan)
                                                .frame(width: 14, height: 14)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 2)
                        }
                        .padding(16)
                    }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                // MARK: - Title Text
                VStack(spacing: 8) {
                    Text("BLOCK-JACK")
                        .font(.setCustomFont(name: .InterBlack, size: 38))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ThemeColors.electricYellow, ThemeColors.neonCyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: ThemeColors.electricYellow.opacity(0.6), radius: glowRadius * 0.5)
                        .tracking(4)
                    
                    Text("SYNTH-GRID PUZZLE")
                        .font(.setCustomFont(name: .InterMedium, size: 13))
                        .foregroundStyle(ThemeColors.neonCyan.opacity(0.7))
                        .tracking(6)
                }
                .opacity(logoOpacity)
                .padding(.top, 24)
                
                Spacer()
                
                // MARK: - Loading Text
                VStack(spacing: 12) {
                    // Animated dots row
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(ThemeColors.neonCyan)
                                .frame(width: 5, height: 5)
                                .opacity(loadingIndex % 3 == i ? 1.0 : 0.25)
                                .scaleEffect(loadingIndex % 3 == i ? 1.3 : 0.8)
                                .animation(.easeInOut(duration: 0.3), value: loadingIndex)
                        }
                    }
                    
                    Text(loadingText)
                        .font(.setCustomFont(name: .InterBold, size: 11))
                        .foregroundStyle(ThemeColors.textSecondary)
                        .tracking(3)
                        .animation(.easeInOut(duration: 0.2), value: loadingText)
                }
                .opacity(loadingOpacity)
                .padding(.bottom, 48)
            }
        }
        .opacity(screenOpacity)
        .onTapGesture {
            // Tap to skip
            finish()
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Animation Logic
    private func startAnimations() {
        // Phase 1: Logo fades & scales in
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Neon glow pulses
        withAnimation(.easeInOut(duration: 0.8).delay(0.4).repeatForever(autoreverses: true)) {
            glowRadius = 20
        }
        
        // Phase 2: Loading text appears
        withAnimation(.easeIn(duration: 0.4).delay(0.5)) {
            loadingOpacity = 1.0
        }
        
        // Cycle through loading messages
        for i in 0..<loadingMessages.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(i) * 0.28) {
                loadingText = loadingMessages[i]
                loadingIndex = i
            }
        }
        
        // Phase 3: Fade out and finish after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            finish()
        }
    }
    
    private func finish() {
        withAnimation(.easeInOut(duration: 0.4)) {
            screenOpacity = 0.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onFinished()
        }
    }
}

#Preview {
    SplashScreenView(onFinished: {})
}
