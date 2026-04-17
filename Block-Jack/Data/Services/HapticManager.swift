//
//  HapticManager.swift
//  Block-Jack
//

import UIKit
import SwiftUI

// MARK: - HapticManager
final class HapticManager {
    static let shared = HapticManager()
    private init() {}

    // MARK: - Haptic Types
    enum FeedbackType {
        case blockPlace     // Blok yerleştirme → medium
        case blockFail      // Yerleştirme başarısız → light
        case lineClear      // Satır patlatma → heavy
        case flush          // Flush! → heavy + extra
        case gameOver       // Oyun bitti → error
        case buttonTap      // UI butonu → light
        case timerWarning   // Süre kritik → medium
        case success
        case error
        case heavy
        case selection
    }

    func play(_ type: FeedbackType) {
        switch type {
        case .blockPlace:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .blockFail:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .lineClear:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .flush:
            let gen = UIImpactFeedbackGenerator(style: .heavy)
            gen.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                gen.impactOccurred(intensity: 0.6)
            }
        case .gameOver:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .buttonTap:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .timerWarning:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }

    func playSelection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
