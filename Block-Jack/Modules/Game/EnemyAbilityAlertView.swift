//
//  EnemyAbilityAlertView.swift
//  Block-Jack
//
//  Yeni bildirim sistemi: Düşman yetenek uyarısı.
//  Artık full-modal değil — düşman satırı altına kayan inline banner.
//  Grid kararır (opacity: 0.45) ama tıklanabilir kalır.
//

import SwiftUI

// MARK: - New Inline Enemy Alert (Kategori B)

struct EnemyAbilityAlertView: View {
    let alert: EnemyAbilityAlert
    @State private var slideIn: Bool = false
    
    var body: some View {
        HStack(spacing: 10) {
            // Sol kenarda kırmızı accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(alert.color)
                .frame(width: 3, height: 36)
            
            // Icon
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(alert.color)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(alert.color.opacity(0.15))
                )
            
            // Title + Description
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title.uppercased())
                    .font(.setCustomFont(name: .InterBlack, size: 11))
                    .foregroundStyle(alert.color)
                    .tracking(0.8)
                    .lineLimit(1)
                
                Text(alert.description)
                    .font(.setCustomFont(name: .InterMedium, size: 10))
                    .foregroundStyle(ThemeColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#2d1515").opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(alert.color.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: alert.color.opacity(0.3), radius: 8)
        .offset(y: slideIn ? 0 : -40)
        .opacity(slideIn ? 1 : 0)
        .onAppear {
            // slideDown 250ms
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                slideIn = true
            }
        }
    }
}

// MARK: - Enemy Ability Panel (Under enemy banner)

struct EnemyAbilityPanelView: View {
    @ObservedObject var notificationManager: NotificationManager
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // New attack banner (takes priority)
            if let banner = notificationManager.attackBanner {
                AttackBannerView(banner: banner)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .padding(.horizontal, GameLayout.horizontalPadding)
            }
            
            // Legacy enemy ability alerts
            ForEach(notificationManager.enemyAbilities) { alert in
                EnemyAbilityAlertView(alert: alert)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .id(alert.id)
                    .padding(.horizontal, GameLayout.horizontalPadding)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .animation(.spring(response: 0.3), value: notificationManager.attackBanner?.id)
        .animation(.spring(response: 0.3), value: notificationManager.enemyAbilities.count)
    }
}

#Preview {
    ZStack {
        ThemeColors.cosmicBlack.ignoresSafeArea()
        
        VStack {
            EnemyAbilityPanelView(
                notificationManager: {
                    let nm = NotificationManager()
                    nm.addEnemyAbility(EnemyAbilityAlert(
                        title: "Sildirme ve Kaçış",
                        description: "4 adet ağır engel yerleştirildi!",
                        color: ThemeColors.neonPink
                    ))
                    return nm
                }()
            )
            
            Spacer()
        }
    }
}
