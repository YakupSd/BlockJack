//
//  TimerManager.swift
//  Block-Jack
//

import Foundation
import Combine

// MARK: - TimerManager
final class TimerManager: ObservableObject {

    // MARK: - Published State
    @Published var timeRemaining: Double = 60.0 {
        didSet { updateComputedProperties() }
    }
    @Published var isRunning: Bool = false
    @Published var didExpire: Bool = false
    @Published var ratio: Double = 1.0  // Artık @Published

    // MARK: - Properties
    private var totalTime: Double = 60.0
    private var cancellable: AnyCancellable?
    private let tickInterval: Double = 0.05  // 50ms → smooth animasyon

    // MARK: - Computed (Helper for logic outside publishers)
    var isCritical: Bool { ratio < 0.1 }
    var isWarning:  Bool { ratio < 0.25 }

    // MARK: - Controls
    func setup(seconds: Double) {
        didExpire = false
        stop()
        totalTime = seconds
        timeRemaining = seconds
        ratio = 1.0
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        cancellable = Timer.publish(every: tickInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func pause() {
        isRunning = false
        cancellable?.cancel()
    }

    func resume() {
        guard !isRunning else { return }
        start()
    }

    func stop() {
        isRunning = false
        cancellable?.cancel()
        cancellable = nil
    }

    func addTime(_ seconds: Double) {
        timeRemaining = min(timeRemaining + seconds, totalTime)
    }

    // MARK: - Private
    private func tick() {
        guard isRunning else { return }
        timeRemaining -= tickInterval
        if timeRemaining <= 0 {
            timeRemaining = 0
            stop()
            didExpire = true
        }
    }

    private func updateComputedProperties() {
        guard totalTime > 0 else {
            ratio = 0
            return
        }
        let newRatio = max(0, min(1, timeRemaining / totalTime))
        if ratio != newRatio {
            ratio = newRatio
        }
    }
}
