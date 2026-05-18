//
//  NotificationToastView.swift
//  Block-Jack
//
//  Yeni bildirim sistemi — Minimal Ticker Toast.
//  Sağ üstte TEK bir kompakt bildirim gösterilir.
//  Yeni bildirim gelince eski smooth replace edilir (kuyruk yok).
//  Dikkat dağıtmaz, oyun akışını bozmaz.
//

import SwiftUI

// MARK: - Minimal Ticker Toast (Tek satır, kompakt)

struct NotificationToastView: View {
    let notification: GameNotification
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 7) {
            // Sol: İkon (küçük, renkli)
            Image(systemName: notification.type.icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(notification.color)
                .frame(width: 16, height: 16)
            
            // Metin
            Text(notification.title)
                .font(.setCustomFont(name: .InterBold, size: 11))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
            
            // Puan değeri (varsa)
            if let value = notification.value {
                Text(value)
                    .font(.setCustomFont(name: .InterBlack, size: 11))
                    .foregroundStyle(notification.color)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(hex: "#0d0d18").opacity(0.82))
        )
        .overlay(
            Capsule()
                .stroke(notification.color.opacity(0.2), lineWidth: 0.5)
        )
        .onTapGesture {
            onDismiss?()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(notification.title) \(notification.value ?? "")")
    }
}

// MARK: - Toast Panel Container (Sağ üst — tek toast ticker)

struct NotificationPanelView: View {
    @ObservedObject var notificationManager: NotificationManager
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            if let toast = notificationManager.currentToast {
                NotificationToastView(
                    notification: toast,
                    onDismiss: {
                        notificationManager.dismissToast(id: toast.id)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
                .id(toast.id) // Animasyon için benzersiz ID
            }
            
            Spacer()
        }
        .padding(.trailing, 12)
        .padding(.top, 6)
        .frame(maxHeight: .infinity, alignment: .topTrailing)
        .animation(.spring(response: 0.2, dampingFraction: 0.85), value: notificationManager.currentToast?.id)
    }
}

// MARK: - Attack Inline Banner (Kategori B)
/// Düşman saldırı uyarısı — düşman satırı altına kayan inline banner.
/// Grid kararır (opacity: 0.45) ama tıklanabilir kalır.

struct AttackBannerView: View {
    let banner: AttackBannerState
    @EnvironmentObject var userEnv: UserEnvironment
    
    @State private var slideIn: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Sol: Sayaç dairesi (kırmızı border, koyu fill)
            ZStack {
                Circle()
                    .fill(Color(hex: "#2d1515"))
                    .frame(width: 38, height: 38)
                
                Circle()
                    .trim(from: 0, to: CGFloat(max(0, banner.countdown) / 2.0))
                    .stroke(
                        banner.color,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 38, height: 38)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: banner.countdown)
                
                Text(String(format: "%.0f", max(0, banner.countdown)))
                    .font(.setCustomFont(name: .InterBlack, size: 16))
                    .foregroundStyle(banner.color)
                    .monospacedDigit()
            }
            
            // Orta: Uyarı yazıları
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text("⚠️")
                        .font(.system(size: 10))
                    Text(userEnv.labelIncomingAttack)
                        .font(.setCustomFont(name: .InterBold, size: 10))
                        .foregroundStyle(ThemeColors.textMuted)
                        .tracking(0.5)
                }
                
                HStack(spacing: 6) {
                    Text(banner.icon)
                        .font(.system(size: 16))
                    
                    Text(banner.attackName.uppercased())
                        .font(.setCustomFont(name: .InterBlack, size: 13))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Text("—")
                        .font(.setCustomFont(name: .InterMedium, size: 11))
                        .foregroundStyle(ThemeColors.textMuted)
                    
                    Text(banner.description)
                        .font(.setCustomFont(name: .InterMedium, size: 11))
                        .foregroundStyle(ThemeColors.textSecondary)
                        .lineLimit(1)
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
            // Sol kenarda kırmızı border accent
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(banner.color)
                    .frame(width: 3)
                    .padding(.vertical, 4)
                Spacer()
            }
            .padding(.leading, 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(banner.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: banner.color.opacity(0.3), radius: 10)
        .offset(y: slideIn ? 0 : -60)
        .opacity(slideIn ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                slideIn = true
            }
        }
    }
}

// MARK: - Round Transition Overlay (Kategori D)
/// Tur bitti overlay — sadece grid alanını kapsar (tam ekran değil).
/// Geri sayım (3 → 0), tap ile atlanır.

struct RoundTransitionOverlay: View {
    let transition: RoundTransitionState
    var onSkip: (() -> Void)? = nil
    @EnvironmentObject var userEnv: UserEnvironment
    
    @State private var fadeIn: Bool = false
    @State private var scoreScale: CGFloat = 0.5
    
    var body: some View {
        ZStack {
            // Koyu yarı saydam arka plan — sadece grid alanı
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 10/255, green: 10/255, blue: 24/255).opacity(0.85))
            
            VStack(spacing: 16) {
                // Tur başlığı
                Text("\(userEnv.labelRound) \(transition.roundNumber) \(userEnv.labelComplete)")
                    .font(.setCustomFont(name: .InterBlack, size: 22))
                    .foregroundStyle(.white)
                    .tracking(2)
                    .shadow(color: ThemeColors.neonCyan.opacity(0.5), radius: 8)
                
                // Büyük skor sayısı
                Text(transition.score.formatted())
                    .font(.setCustomFont(name: .InterBlack, size: 42))
                    .foregroundStyle(ThemeColors.electricYellow)
                    .monospacedDigit()
                    .scaleEffect(scoreScale)
                    .shadow(color: ThemeColors.electricYellow.opacity(0.4), radius: 12)
                
                // En iyi skor
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(ThemeColors.electricYellow.opacity(0.7))
                    Text("\(userEnv.labelBestScore): \(transition.bestScore.formatted())")
                        .font(.setCustomFont(name: .InterBold, size: 14))
                        .foregroundStyle(ThemeColors.textSecondary)
                        .monospacedDigit()
                }
                
                // Aktif bonus chip'leri
                HStack(spacing: 10) {
                    if transition.streak > 0 {
                        bonusChip(
                            text: "Streak ×\(transition.streak)",
                            color: ThemeColors.neonPurple
                        )
                    }
                    
                    if transition.isFrenzyActive {
                        bonusChip(
                            text: "Frenzy",
                            color: ThemeColors.neonOrange
                        )
                    }
                }
                
                // Sayaç metni
                Text("\(userEnv.labelNextRound) \(Int(max(0, transition.countdown)))\(userEnv.labelSecondsSuffix)")
                    .font(.setCustomFont(name: .InterMedium, size: 12))
                    .foregroundStyle(ThemeColors.textMuted)
                    .monospacedDigit()
                
                // Tap to skip
                Text(userEnv.labelTapToSkip)
                    .font(.setCustomFont(name: .InterBold, size: 10))
                    .foregroundStyle(ThemeColors.textMuted.opacity(0.6))
                    .tracking(1)
            }
            .padding(24)
        }
        .opacity(fadeIn ? 1 : 0)
        .onTapGesture {
            onSkip?()
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.15)) {
                fadeIn = true
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                scoreScale = 1.0
            }
        }
    }
    
    @ViewBuilder
    private func bonusChip(text: String, color: Color) -> some View {
        Text(text)
            .font(.setCustomFont(name: .InterBold, size: 11))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(color.opacity(0.2))
            )
            .overlay(
                Capsule().stroke(color.opacity(0.5), lineWidth: 1)
            )
    }
}

// MARK: - Overdrive Ready Pulse View (Kategori C)
/// Overdrive çubuğu dolunca 3 pulse vurur.

struct OverdriveReadyPulseView: View {
    @State private var pulseCount: Int = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.8
    
    let color: Color = Color(hex: "#0d1f17")
    let accentColor: Color = ThemeColors.neonGreen
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(accentColor, lineWidth: 2)
                .scaleEffect(pulseScale)
                .opacity(pulseOpacity)
        }
        .onAppear {
            triggerPulse()
        }
    }
    
    private func triggerPulse() {
        guard pulseCount < 3 else { return }
        
        withAnimation(.easeOut(duration: 0.4)) {
            pulseScale = 1.5
            pulseOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            pulseScale = 1.0
            pulseOpacity = 0.8
            pulseCount += 1
            
            if pulseCount < 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    triggerPulse()
                }
            }
        }
    }
}

#Preview {
    ZStack {
        ThemeColors.cosmicBlack.ignoresSafeArea()
        
        VStack(spacing: 20) {
            // Attack Banner
            AttackBannerView(banner: AttackBannerState(
                attackName: "Ağır Zırh",
                description: "4 ağır engel yerleştirir",
                icon: "🛡️",
                color: Color(hex: "#ef4444")
            ))
            .padding(.horizontal, 14)
            
            Spacer()
            
            // Round Transition
            RoundTransitionOverlay(transition: RoundTransitionState(
                roundNumber: 2,
                score: 5260,
                bestScore: 18909,
                streak: 4,
                isFrenzyActive: true
            ))
            .frame(height: 300)
            .padding(.horizontal, 14)
            
            Spacer()
        }
        
        // Ticker toast
        NotificationPanelView(
            notificationManager: {
                let nm = NotificationManager()
                nm.enqueue(GameNotification(
                    type: .pattern("GRADIENT"),
                    title: "GRADIENT!",
                    value: "+9.0",
                    color: ThemeColors.neonCyan
                ))
                return nm
            }()
        )
    }
}
