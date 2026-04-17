//
//  AppStartView.swift
//  Block-Jack
//

import SwiftUI

struct AppStartView: View {
    @StateObject var vm = AppStartViewModel()
    @EnvironmentObject var userEnv: UserEnvironment
    
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Arka Plan
            ThemeColors.backgroundGradient
                .ignoresSafeArea()
            
            // Synthwave Grid (Splash versiyonu)
            splashGridPattern
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo & Title Section
                VStack(spacing: 12) {
                    Text("BLOCK")
                        .font(.setCustomFont(name: .InterExtraBold, size: 72))
                        .foregroundStyle(.white)
                        .shadow(color: ThemeColors.neonCyan, radius: 15)
                    
                    Text("JACK")
                        .font(.setCustomFont(name: .InterExtraBold, size: 72))
                        .foregroundStyle(ThemeColors.neonPink)
                        .shadow(color: ThemeColors.neonPink, radius: 15)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .overlay {
                    // Ekstra Parlama (Glow)
                    VStack(spacing: 12) {
                        Text("BLOCK").font(.setCustomFont(name: .InterExtraBold, size: 72))
                        Text("JACK").font(.setCustomFont(name: .InterExtraBold, size: 72))
                    }
                    .foregroundStyle(.white)
                    .blur(radius: 20)
                    .opacity(glowOpacity)
                }
                
                Spacer()
                
                // Loading Indicator
                if vm.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(ThemeColors.neonCyan)
                            .scaleEffect(1.5)
                        
                        Text(userEnv.localizedString("YÜKLENİYOR...", "LOADING..."))
                            .font(.setCustomFont(name: .InterBold, size: 14))
                            .foregroundStyle(ThemeColors.textSecondary)
                            .kerning(4)
                    }
                    .transition(.opacity)
                }
                
                Text("v1.0.0")
                    .font(.setCustomFont(name: .InterLight, size: 10))
                    .foregroundStyle(ThemeColors.textMuted)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowOpacity = 0.6
            }
        }
        .onChange(of: vm.initializationComplete) { complete in
            if complete {
                // Navigasyon: Ana Menüye git
                MainViewsRouter.shared.popToDashboard()
            }
        }
    }
    
    // Dekoratif Arka Plan Izgarası
    private var splashGridPattern: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 40
            for x in stride(from: 0, through: size.width, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                ctx.stroke(path, with: .color(ThemeColors.gridStroke.opacity(0.1)), lineWidth: 0.5)
            }
            for y in stride(from: 0, through: size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                ctx.stroke(path, with: .color(ThemeColors.gridStroke.opacity(0.1)), lineWidth: 0.5)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    AppStartView()
        .environmentObject(UserEnvironment.shared)
}
