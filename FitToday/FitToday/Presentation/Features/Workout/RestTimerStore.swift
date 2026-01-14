//
//  RestTimerStore.swift
//  FitToday
//
//  Timer de countdown para descanso entre séries.
//

import Foundation
import UIKit

// 💡 Learn: @Observable substitui ObservableObject para gerenciamento de estado moderno
@MainActor
@Observable final class RestTimerStore {
    // MARK: - State

    private(set) var remainingSeconds: Int = 0
    private(set) var totalSeconds: Int = 0
    private(set) var isActive: Bool = false
    private(set) var isFinished: Bool = false

    // MARK: - Private

    // 💡 Learn: nonisolated(unsafe) permite acesso de deinit sem isolamento do MainActor
    private nonisolated(unsafe) var timerTask: Task<Void, Never>?
    private var startDate: Date?
    private var pausedRemainingTime: TimeInterval = 0
    
    // MARK: - Computed Properties
    
    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var progressPercentage: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(totalSeconds))
    }
    
    // MARK: - Actions
    
    /// Inicia o timer de descanso com duração específica
    func start(duration: TimeInterval) {
        stop()
        
        totalSeconds = Int(duration)
        remainingSeconds = Int(duration)
        pausedRemainingTime = duration
        isFinished = false
        isActive = true
        startDate = Date()
        
        startTicking()
    }
    
    /// Pausa o timer
    func pause() {
        guard isActive else { return }
        isActive = false
        
        if let startDate {
            let elapsed = Date().timeIntervalSince(startDate)
            pausedRemainingTime = max(0, pausedRemainingTime - elapsed)
        }
        
        timerTask?.cancel()
        timerTask = nil
    }
    
    /// Retoma o timer pausado
    func resume() {
        guard !isActive, pausedRemainingTime > 0 else { return }
        
        isActive = true
        startDate = Date()
        
        startTicking()
    }
    
    /// Alterna entre pausado e rodando
    func toggle() {
        if isActive {
            pause()
        } else {
            resume()
        }
    }
    
    /// Para e reseta o timer
    func stop() {
        isActive = false
        isFinished = false
        remainingSeconds = 0
        totalSeconds = 0
        pausedRemainingTime = 0
        startDate = nil
        
        timerTask?.cancel()
        timerTask = nil
    }
    
    /// Adiciona tempo ao timer (ex: +30s)
    func addTime(_ seconds: Int) {
        guard isActive || pausedRemainingTime > 0 else { return }
        
        pausedRemainingTime += Double(seconds)
        totalSeconds += seconds
        remainingSeconds = Int(pausedRemainingTime)
    }
    
    /// Pula o descanso
    func skip() {
        finish()
    }
    
    // MARK: - Private Methods
    
    private func startTicking() {
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms para precisão
                guard !Task.isCancelled else { break }
                await self?.tick()
            }
        }
    }
    
    private func tick() {
        guard isActive, let startDate else { return }
        
        let elapsed = Date().timeIntervalSince(startDate)
        let remaining = pausedRemainingTime - elapsed
        
        if remaining <= 0 {
            finish()
        } else {
            remainingSeconds = Int(ceil(remaining))
        }
    }
    
    private func finish() {
        isActive = false
        isFinished = true
        remainingSeconds = 0
        
        timerTask?.cancel()
        timerTask = nil
        
        // Haptic feedback
        triggerHapticFeedback()
    }
    
    private func triggerHapticFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    deinit {
        timerTask?.cancel()
    }
}

// MARK: - Testability

extension RestTimerStore {
    /// Para testes: força término do timer
    func forceFinish() {
        finish()
    }
}

