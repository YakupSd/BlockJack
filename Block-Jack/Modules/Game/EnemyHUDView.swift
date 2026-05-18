//
//  EnemyHUDView.swift
//  Block-Jack
//
//  Yeni bildirim sistemi: Düşman saldırı uyarısı.
//  Eski full-screen modal overlay KALDIRILDI.
//  Yeni tasarım: Düşman satırı altına kayan inline banner + grid karartma.
//  Grid opacity: 0.45 (tıklanabilir kalır).
//

import SwiftUI

// MARK: - Düşman Saldırı Uyarı — Inline Banner (Eski overlay yerine)
/// Artık tam ekran overlay değil.
/// Düşman banner'ının hemen altına kayar.
/// Grid 0.45 opacity ile kararır ama tıklanabilir kalır.

struct EnemyAttackWarningOverlay: View {
    @ObservedObject var vm: GameViewModel
    @State private var slideIn: Bool = false
    @State private var bgPulse: Double = 0.0
    
    var body: some View {
        guard let attack = vm.enemy.currentAttack else { return AnyView(EmptyView()) }
        
        return AnyView(
            VStack(spacing: 0) {
                // Inline banner (düşman satırı altına eklenir)
                HStack(spacing: 12) {
                    // Sol: Sayaç dairesi
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#2d1515"))
                            .frame(width: 42, height: 42)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(max(0, vm.enemyCountdown) / 3.0))
                            .stroke(
                                attack.warningColor,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 42, height: 42)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.1), value: vm.enemyCountdown)
                        
                        Text(String(format: "%.0f", max(0, vm.enemyCountdown)))
                            .font(.setCustomFont(name: .InterBlack, size: 18))
                            .foregroundStyle(attack.warningColor)
                            .monospacedDigit()
                    }
                    
                    // Orta: Uyarı yazıları
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Text("⚠️")
                                .font(.system(size: 10))
                            Text(vm.userEnv.labelAttackIncoming)
                                .font(.setCustomFont(name: .InterBold, size: 10))
                                .foregroundStyle(ThemeColors.textMuted)
                                .tracking(0.5)
                        }
                        
                        HStack(spacing: 6) {
                            Text(attack.icon)
                                .font(.system(size: 18))
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(attack.name.uppercased())
                                    .font(.setCustomFont(name: .InterBlack, size: 13))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                
                                Text(attack.description)
                                    .font(.setCustomFont(name: .InterMedium, size: 10))
                                    .foregroundStyle(ThemeColors.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "#2d1515").opacity(0.92))
                )
                .overlay(
                    // Sol kenarda kırmızı border accent (3px)
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(attack.warningColor)
                            .frame(width: 3)
                            .padding(.vertical, 4)
                        Spacer()
                    }
                    .padding(.leading, 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(attack.warningColor.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: attack.warningColor.opacity(0.3), radius: 10)
                .padding(.horizontal, GameLayout.horizontalPadding)
                .offset(y: slideIn ? 0 : -60)
                .opacity(slideIn ? 1 : 0)
            }
            .onAppear {
                // slideDown 250ms
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    slideIn = true
                }
                // Kenar nabzı (ince vurgu)
                withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                    bgPulse = 0.3
                }
            }
        )
    }
}

// MARK: - Düşman HUD (UI Revize — Kompakt 44pt banner)
/// Tek yatay satır, maksimum 44pt yükseklik.
/// Layout: [icon]  Düşman: <isim> — <açıklama>                 DÜŞMAN
struct EnemyHUDView: View {
    @ObservedObject var vm: GameViewModel
    @EnvironmentObject var userEnv: UserEnvironment
    @State private var pulseIcon: Bool = false
    
    var body: some View {
        guard let attack = vm.enemy.currentAttack else { return AnyView(EmptyView()) }
        
        let borderColor: Color = vm.enemy.isTrayLocked
            ? ThemeColors.electricYellow.opacity(0.6)
            : ThemeColors.danger.opacity(0.35)
        
        return AnyView(
            HStack(spacing: 10) {
                // Düşman ikonu
                ZStack {
                    Circle()
                        .fill(attack.warningColor.opacity(0.18))
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(attack.warningColor.opacity(0.5), lineWidth: 1))
                        .scaleEffect(pulseIcon ? 1.08 : 1.0)
                    
                    Text(attack.icon)
                        .font(.system(size: 15))
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(userEnv.labelEnemyPrefix + attack.name)
                        .font(.setCustomFont(name: .InterBlack, size: 10))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    if vm.enemy.isTrayLocked {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(ThemeColors.electricYellow)
                            Text(userEnv.labelEnemyTrayLockRemainingTemplate.replacingOccurrences(of: "{{time}}", with: "\(Int(vm.enemy.trayLockRemainingTime))"))
                                .font(.setCustomFont(name: .InterBold, size: 9))
                                .foregroundStyle(ThemeColors.electricYellow)
                        }
                    } else {
                        Text(attack.description)
                            .font(.setCustomFont(name: .InterMedium, size: 9))
                            .foregroundStyle(ThemeColors.textMuted)
                            .lineLimit(1)
                    }
                }
                
                Spacer(minLength: 4)
                
                // Sağ: DÜŞMAN etiketi
                Text(userEnv.labelEnemyCaps)
                    .font(.setCustomFont(name: .InterBlack, size: 9))
                    .foregroundStyle(attack.warningColor)
                    .tracking(2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(attack.warningColor.opacity(0.12))
                    )
                    .overlay(
                        Capsule().stroke(attack.warningColor.opacity(0.4), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 10)
            .frame(height: GameLayout.enemyBannerHeight)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(ThemeColors.enemyBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
            .shadow(color: vm.enemy.isTrayLocked ? ThemeColors.electricYellow.opacity(0.35) : .clear, radius: 6)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseIcon = true
                }
            }
            .onChange(of: vm.enemy.currentAttack?.rawValue) { _ in
                pulseIcon = false
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseIcon = true
                }
            }
        )
    }
}
