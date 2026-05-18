//
//  NotificationSystem.swift
//  Block-Jack
//
//  Centralized notification/toast system for game events.
//  4 Kategori: A (Combo/Skor) · B (Saldırı) · C (Perk/Overdrive) · D (Tur Geçiş)
//  Öncelik: Attack > Round > Perk > Combo
//
//  Toast Kuralları:
//  - Aynı anda MAX 1 toast gösterilir (ticker style)
//  - Yeni bildirim gelince eski toast smooth replace edilir (kuyruk biriktirmez)
//  - Combo/pattern gibi sık bildirimler birleştirilir (merge)
//  - Auto-dismiss: 1.2s (combo) / 1.5s (perk) / 2s (system)
//

import Foundation
import SwiftUI
import Combine

// MARK: - Notification Category & Type

enum NotificationCategory: Int, Comparable {
    /// Kategori A — Skor / Combo (Frenzy, Gradient, Flush, Streak)
    case combo   = 0
    /// Kategori C — Perk / Overdrive
    case perk    = 1
    /// Kategori D — Tur / Bölüm geçiş
    case round   = 2
    /// Kategori B — Düşman saldırısı (TEK kritik durum)
    case attack  = 3
    
    static func < (lhs: NotificationCategory, rhs: NotificationCategory) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum NotificationType: Equatable {
    // Kategori A — Combo / Skor
    case pattern(String)           // "GRADIENT! +9.0", "FLUSH! +16"
    case frenzy(String)            // "FRENZY MODE! ×1.25"
    case streak(String)            // "STREAK ×5"
    
    // Kategori B — Düşman saldırısı
    case enemy(String)             // "AĞIR ZIRH", "SİL & KAÇIŞ"
    
    // Kategori C — Perk / Overdrive
    case perk(String)              // "MOMENTUM! +25", "OVERKILL +500"
    case overdrive(String)         // "OVERDRIVE HAZIR!"
    
    // Kategori D — Tur / Bölüm geçiş
    case roundComplete(String)     // "TUR 2 TAMAMLANDI"
    
    // Genel
    case system(String)            // "BOSS PHASE 2", "TIER 3 READY!"
    case achievement(String)       // Milestone notifications
    
    var category: NotificationCategory {
        switch self {
        case .pattern, .frenzy, .streak:
            return .combo
        case .enemy:
            return .attack
        case .perk, .overdrive:
            return .perk
        case .roundComplete:
            return .round
        case .system:
            return .perk
        case .achievement:
            return .combo
        }
    }
    
    /// Kısa süreler — dikkat dağıtma alanını minimize eder
    var defaultDuration: Double {
        switch self {
        case .pattern, .streak:     return 1.0   // Çok kısa — sık oluyor
        case .frenzy:               return 1.2
        case .perk, .system:        return 1.5   // Önemli ama kısa
        case .overdrive:            return 1.5
        case .enemy:                return 2.0   // Blocking
        case .roundComplete:        return 3.0   // Blocking
        case .achievement:          return 1.8
        }
    }
    
    /// Whether this notification blocks gameplay
    var isBlocking: Bool {
        switch self {
        case .enemy, .roundComplete: return true
        default: return false
        }
    }
    
    /// Icon for the notification toast
    var icon: String {
        switch self {
        case .pattern:       return "square.grid.2x2"
        case .frenzy:        return "flame.fill"
        case .streak:        return "bolt.fill"
        case .enemy:         return "exclamationmark.shield.fill"
        case .perk:          return "sparkles"
        case .overdrive:     return "bolt.circle.fill"
        case .roundComplete: return "checkmark.seal.fill"
        case .system:        return "flag.fill"
        case .achievement:   return "star.fill"
        }
    }
    
    /// Emoji for the notification toast
    var emoji: String {
        switch self {
        case .frenzy:       return "🔥"
        case .enemy:        return "⚠️"
        case .overdrive:    return "⚡"
        case .roundComplete: return "🏆"
        case .streak:       return "🔥"
        default:            return ""
        }
    }
    
    /// Bildirim birleştirilebilir mi? (Aynı tipteki yeni bildirim eskiyi replace eder)
    var isMergeable: Bool {
        switch self {
        case .pattern, .streak, .frenzy: return true  // Sık olan combo bildirimleri merge
        default: return false
        }
    }
}

// MARK: - Notification Item

struct GameNotification: Identifiable, Equatable {
    let id: UUID
    let category: NotificationCategory
    let type: NotificationType
    let title: String
    let subtitle: String
    let value: String?
    let color: Color
    let duration: TimeInterval
    let createdAt: Date
    
    init(type: NotificationType, title: String, subtitle: String = "", value: String? = nil, color: Color, duration: TimeInterval? = nil) {
        self.id = UUID()
        self.category = type.category
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.color = color
        self.duration = duration ?? type.defaultDuration
        self.createdAt = Date()
    }
    
    static func == (lhs: GameNotification, rhs: GameNotification) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Attack Banner State

struct AttackBannerState: Identifiable {
    let id = UUID()
    let attackName: String
    let description: String
    let icon: String
    let color: Color
    var countdown: Double = 2.0
}

// MARK: - Round Transition State

struct RoundTransitionState: Identifiable {
    let id = UUID()
    let roundNumber: Int
    let score: Int
    let bestScore: Int
    let streak: Int
    let isFrenzyActive: Bool
    var countdown: Double = 3.0
}

// MARK: - Legacy Compatibility Aliases

struct NotificationItem: Identifiable {
    let id = UUID()
    let text: String
    let type: NotificationType
    let color: Color
    var showTime: Double = 0
    let createdAt: Date = Date()
    
    var duration: Double { type.defaultDuration }
    var priority: Int { type.category.rawValue }
}

struct EnemyAbilityAlert: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let color: Color
    let icon: String? = nil
}

// MARK: - Notification Manager

class NotificationManager: ObservableObject {
    
    // MARK: - Published State
    
    /// Şu an görünen TEK toast (ticker style — yeni gelen eskiyi replace eder)
    @Published var currentToast: GameNotification? = nil
    
    /// Attack banner state (Kategori B — inline banner)
    @Published var attackBanner: AttackBannerState? = nil
    
    /// Round transition state (Kategori D — grid overlay card)
    @Published var roundTransition: RoundTransitionState? = nil
    
    /// Grid dim opacity for attack banners
    @Published var gridDimOpacity: Double = 0.0
    
    // Legacy compatibility
    @Published var notifications: [NotificationItem] = []
    @Published var enemyAbilities: [EnemyAbilityAlert] = []
    
    // Legacy bridge — eski kod hala activeToasts'a bakıyor olabilir
    var activeToasts: [GameNotification] {
        if let toast = currentToast { return [toast] }
        return []
    }
    
    // MARK: - Private
    
    private var dismissTimer: Timer?
    private var dismissTimers: [UUID: Timer] = [:]
    private var isBlockingActive: Bool = false
    
    /// Son bildirim zamanı — throttle için
    private var lastToastTime: Date = .distantPast
    /// Minimum aralık — çok hızlı bildirim spam'ini önler
    private let minToastInterval: TimeInterval = 0.3
    
    // MARK: - Public API
    
    /// Tek giriş noktası — bildirim göster (toast veya blocking)
    func enqueue(_ notification: GameNotification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Blocking notifications (attack, round) ayrı kanal
            if notification.type.isBlocking {
                self.handleBlockingNotification(notification)
                return
            }
            
            // Blocking aktifken non-blocking toast gösterme
            guard !self.isBlockingActive else { return }
            
            // Throttle: çok hızlı peş peşe bildirim geliyorsa düşür
            let now = Date()
            let elapsed = now.timeIntervalSince(self.lastToastTime)
            
            // Mergeable bildirimler (combo/pattern): aktif toast'u replace et
            if notification.type.isMergeable, self.currentToast != nil {
                // Minimum interval kontrolü — çok hızlıysa düşür
                if elapsed < self.minToastInterval { return }
            }
            
            // Yeni toast göster (eskiyi otomatik replace eder)
            self.showToast(notification)
        }
    }
    
    /// Legacy API — backwards compatible (TEK fonksiyon, çift çağrı yok)
    func addNotification(text: String, type: NotificationType, color: Color) {
        let notification = GameNotification(
            type: type,
            title: text,
            color: color
        )
        enqueue(notification)
    }
    
    /// Show attack banner (Kategori B)
    func showAttackBanner(name: String, description: String, icon: String = "⚠️", color: Color = Color(hex: "#ef4444")) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.attackBanner = AttackBannerState(
                attackName: name,
                description: description,
                icon: icon,
                color: color
            )
            
            // Grid karartma
            withAnimation(.easeIn(duration: 0.25)) {
                self.gridDimOpacity = 0.45
            }
            
            // Haptic — warning
            HapticManager.shared.play(.timerWarning)
            
            // Countdown timer
            let countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                guard let self = self else { timer.invalidate(); return }
                if var banner = self.attackBanner {
                    banner.countdown -= 0.1
                    if banner.countdown <= 0 {
                        timer.invalidate()
                        self.dismissAttackBanner()
                    } else {
                        self.attackBanner = banner
                    }
                }
            }
            self.dismissTimers[self.attackBanner!.id] = countdownTimer
            
            // Accessibility
            UIAccessibility.post(notification: .announcement, argument: "Saldırı geliyor: \(name)")
        }
    }
    
    /// Show round transition overlay (Kategori D)
    func showRoundTransition(round: Int, score: Int, bestScore: Int, streak: Int, isFrenzy: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.roundTransition = RoundTransitionState(
                roundNumber: round,
                score: score,
                bestScore: bestScore,
                streak: streak,
                isFrenzyActive: isFrenzy
            )
            
            // Haptic — success
            HapticManager.shared.play(.success)
            
            // Countdown timer
            let countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                guard let self = self else { timer.invalidate(); return }
                if var transition = self.roundTransition {
                    transition.countdown -= 0.1
                    if transition.countdown <= 0 {
                        timer.invalidate()
                        self.dismissRoundTransition()
                    } else {
                        self.roundTransition = transition
                    }
                }
            }
            self.dismissTimers[self.roundTransition!.id] = countdownTimer
            
            // Accessibility
            UIAccessibility.post(notification: .announcement, argument: "Tur \(round) tamamlandı")
        }
    }
    
    /// Dismiss round transition (tap to skip)
    func dismissRoundTransition() {
        guard let transition = roundTransition else { return }
        dismissTimers[transition.id]?.invalidate()
        dismissTimers.removeValue(forKey: transition.id)
        
        withAnimation(.easeOut(duration: 0.15)) {
            roundTransition = nil
        }
        
        isBlockingActive = false
    }
    
    /// Legacy enemy ability API
    func addEnemyAbility(_ alert: EnemyAbilityAlert) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.enemyAbilities.append(alert)
            
            // Also trigger the new attack banner
            self.showAttackBanner(
                name: alert.title,
                description: alert.description,
                icon: "⚠️",
                color: alert.color
            )
            
            let timer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { [weak self] _ in
                self?.removeEnemyAbility(id: alert.id)
            }
            self.dismissTimers[alert.id] = timer
        }
    }
    
    func removeEnemyAbility(id: UUID) {
        DispatchQueue.main.async { [weak self] in
            self?.enemyAbilities.removeAll { $0.id == id }
            self?.dismissTimers[id]?.invalidate()
            self?.dismissTimers.removeValue(forKey: id)
        }
    }
    
    func clearAll() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentToast = nil
            self.dismissTimer?.invalidate()
            self.notifications.removeAll()
            self.enemyAbilities.removeAll()
            self.attackBanner = nil
            self.roundTransition = nil
            self.gridDimOpacity = 0.0
            self.isBlockingActive = false
            self.dismissTimers.values.forEach { $0.invalidate() }
            self.dismissTimers.removeAll()
        }
    }
    
    // MARK: - Toast Management
    
    /// Dismiss a toast by ID (tap to dismiss)
    func dismissToast(id: UUID) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.currentToast?.id == id {
                withAnimation(.easeOut(duration: 0.12)) {
                    self.currentToast = nil
                }
                self.dismissTimer?.invalidate()
            }
        }
    }
    
    // MARK: - Private
    
    private func showToast(_ notification: GameNotification) {
        // Eski toast'u temizle
        dismissTimer?.invalidate()
        
        // Smooth replace: eski toast varsa hızlıca çık, yenisi gir
        withAnimation(.easeOut(duration: 0.1)) {
            currentToast = nil
        }
        
        // Kısa gecikme ile yeniyi göster (smooth transition hissi)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            guard let self = self else { return }
            
            withAnimation(.spring(response: 0.2, dampingFraction: 0.85)) {
                self.currentToast = notification
            }
            
            self.lastToastTime = Date()
            
            // Auto-dismiss
            self.dismissTimer = Timer.scheduledTimer(withTimeInterval: notification.duration, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.15)) {
                        self?.currentToast = nil
                    }
                }
            }
        }
    }
    
    private func handleBlockingNotification(_ notification: GameNotification) {
        isBlockingActive = true
        
        switch notification.type {
        case .enemy:
            showAttackBanner(
                name: notification.title,
                description: notification.subtitle,
                color: notification.color
            )
        case .roundComplete:
            break
        default:
            isBlockingActive = false
            enqueue(notification)
        }
    }
    
    private func dismissAttackBanner() {
        guard let banner = attackBanner else { return }
        dismissTimers[banner.id]?.invalidate()
        dismissTimers.removeValue(forKey: banner.id)
        
        withAnimation(.easeOut(duration: 0.2)) {
            attackBanner = nil
        }
        withAnimation(.easeOut(duration: 0.2)) {
            gridDimOpacity = 0.0
        }
        
        isBlockingActive = false
    }
    
    // Legacy alias
    func removeNotification(id: UUID) {
        dismissToast(id: id)
        DispatchQueue.main.async { [weak self] in
            self?.notifications.removeAll { $0.id == id }
        }
    }
}
