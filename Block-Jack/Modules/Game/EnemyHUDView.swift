//
//  EnemyHUDView.swift
//  Block-Jack
//

import SwiftUI

// MARK: - Düşman Saldırı Uyarı Overlay (3sn geri sayım)

struct EnemyAttackWarningOverlay: View {
    @ObservedObject var vm: GameViewModel
    @State private var shakeOffset: CGFloat = 0
    @State private var bgPulse: Double = 0.0
    
    var body: some View {
        guard let attack = vm.enemy.currentAttack else { return AnyView(EmptyView()) }
        
        return AnyView(
            ZStack {
                // Kırmızı kenar glow
                RoundedRectangle(cornerRadius: 0)
                    .stroke(attack.warningColor, lineWidth: 6)
                    .opacity(bgPulse)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Uyarı kartı
                    VStack(spacing: 8) {
                        // Geri sayım dairesi
                        ZStack {
                            Circle()
                                .stroke(attack.warningColor.opacity(0.3), lineWidth: 4)
                                .frame(width: 64, height: 64)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(max(0, vm.enemyCountdown) / 3.0))
                                .stroke(attack.warningColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 64, height: 64)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 0.1), value: vm.enemyCountdown)
                            
                            Text(String(format: "%.0f", max(0, vm.enemyCountdown)))
                                .font(.setCustomFont(name: .InterBlack, size: 28))
                                .foregroundStyle(attack.warningColor)
                        }
                        
                        Text("⚠️ SALDIRI GELİYOR!")
                            .font(.setCustomFont(name: .InterBlack, size: 11))
                            .foregroundStyle(ThemeColors.textMuted)
                            .tracking(2)
                        
                        HStack(spacing: 8) {
                            Text(attack.icon)
                                .font(.system(size: 28))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(attack.name)
                                    .font(.setCustomFont(name: .InterBlack, size: 18))
                                    .foregroundStyle(attack.warningColor)
                                
                                Text(attack.description)
                                    .font(.setCustomFont(name: .InterMedium, size: 11))
                                    .foregroundStyle(ThemeColors.textSecondary)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(attack.warningColor.opacity(0.5), lineWidth: 2)
                            )
                            .shadow(color: attack.warningColor.opacity(0.3), radius: 20)
                    )
                    .offset(x: shakeOffset)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 200) // Tray üzerinde konumlanır
                }
            }
            .onAppear {
                // Titreme efekti
                withAnimation(.easeInOut(duration: 0.08).repeatCount(6, autoreverses: true)) {
                    shakeOffset = 6
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation { shakeOffset = 0 }
                }
                // Kenar nabzı
                withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                    bgPulse = 0.5
                }
            }
        )
    }
}

// MARK: - Düşman HUD (Oyun sırasında alt köşede gösterilir)

struct EnemyHUDView: View {
    @ObservedObject var vm: GameViewModel
    @State private var pulseIcon: Bool = false
    
    var body: some View {
        guard let attack = vm.enemy.currentAttack else { return AnyView(EmptyView()) }
        
        return AnyView(
            HStack(spacing: 8) {
                // Düşman ikonu
                ZStack {
                    Circle()
                        .fill(attack.warningColor.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(attack.warningColor.opacity(0.4), lineWidth: 1))
                        .scaleEffect(pulseIcon ? 1.1 : 1.0)
                    
                    Text(attack.icon)
                        .font(.system(size: 18))
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("DÜŞMAN: " + attack.name)
                        .font(.setCustomFont(name: .InterBlack, size: 9))
                        .foregroundStyle(attack.warningColor)
                        .tracking(1)
                    
                    // Kilit süre göstergesi (sadece lockdown için)
                    if vm.enemy.isTrayLocked {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(ThemeColors.electricYellow)
                            Text("KİLİT: \(Int(vm.enemy.trayLockRemainingTime))sn")
                                .font(.setCustomFont(name: .InterBold, size: 9))
                                .foregroundStyle(ThemeColors.electricYellow)
                        }
                    } else {
                        Text(attack.description)
                            .font(.setCustomFont(name: .InterMedium, size: 8))
                            .foregroundStyle(ThemeColors.textMuted)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(ThemeColors.surfaceDark.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                vm.enemy.isTrayLocked
                                    ? ThemeColors.electricYellow.opacity(0.6)
                                    : attack.warningColor.opacity(0.25),
                                lineWidth: 1
                            )
                    )
            )
            // Kilit varken sarı titreşim
            .shadow(color: vm.enemy.isTrayLocked ? ThemeColors.electricYellow.opacity(0.4) : .clear, radius: 6)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseIcon = true
                }
            }
            .onChange(of: vm.enemy.currentAttack?.rawValue) { _ in
                // Yeni atak türü: icon nabzı yeniden başlat
                pulseIcon = false
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseIcon = true
                }
            }
        )
    }
}
