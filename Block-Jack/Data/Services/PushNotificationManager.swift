//
//  PushNotificationManager.swift
//  Block-Jack
//

import Foundation
import UserNotifications
import UIKit
import Combine

// MARK: - Push Notification Manager
class PushNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = PushNotificationManager()
    
    @Published var deviceToken: String = ""
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.authorizationStatus = granted ? .authorized : .denied
            }
        }
    }
    
    // MARK: - Notification Permission Request
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.authorizationStatus = granted ? .authorized : .denied
                if let error = error {
                    print("Notification auth error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Local Notifications for Duel Events
    
    /// Yeni düello daveti bildirimi gönder
    func notifyIncomingDuelChallenge(from opponentName: String, duelID: String) {
        let content = UNMutableNotificationContent()
        content.title = "⚔ DÜELLO DAVETI"
        content.body = "\(opponentName) sana meydan okuyor!"
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        content.sound = .default
        content.userInfo = [
            "type": "duelChallenge",
            "duelID": duelID
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "duel_challenge_\(duelID)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Düello sonucu bildirimi gönder
    func notifyDuelCompleted(opponentName: String, won: Bool, duelID: String) {
        let content = UNMutableNotificationContent()
        content.title = won ? "🏆 KAZANDIN!" : "💔 KAYBETTİN"
        content.body = "\(opponentName) ile düellonun tamamlandı"
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        content.sound = .default
        content.userInfo = [
            "type": "duelResult",
            "duelID": duelID,
            "won": won
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "duel_result_\(duelID)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Arkadaşlık isteği bildirimi gönder
    func notifyFriendRequest(from playerName: String, playerID: String) {
        let content = UNMutableNotificationContent()
        content.title = "👤 ARKADAŞLIK İSTEĞİ"
        content.body = "\(playerName) arkadaş olmak istiyor"
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        content.sound = .default
        content.userInfo = [
            "type": "friendRequest",
            "playerID": playerID
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "friend_request_\(playerID)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // App açıkken bildirimleri göster
        let userInfo = notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String {
            switch type {
            case "duelChallenge", "duelResult", "friendRequest":
                // Bildirim badge'i güncelle
                DispatchQueue.main.async {
                    UIApplication.shared.applicationIconBadgeNumber = max(0, UIApplication.shared.applicationIconBadgeNumber - 1)
                }
                completionHandler([.banner, .sound, .badge])
                
            default:
                completionHandler([])
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String {
            switch type {
            case "duelChallenge":
                if let duelID = userInfo["duelID"] as? String {
                    print("Open duel challenge: \(duelID)")
                    // Duel detail view'a navigate et
                    // NotificationCenter ile bildir
                    NotificationCenter.default.post(name: NSNotification.Name("openDuel"), object: duelID)
                }
                
            case "friendRequest":
                if let playerID = userInfo["playerID"] as? String {
                    print("Open friend request: \(playerID)")
                    // Social view'a navigate et
                    NotificationCenter.default.post(name: NSNotification.Name("openFriendRequests"), object: nil)
                }
                
            default:
                break
            }
        }
        
        completionHandler()
    }
}
