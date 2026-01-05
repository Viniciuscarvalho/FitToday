//
//  WorkoutTimerStore.swift
//  FitToday
//
//  Gerencia o cronômetro do treino ativo.
//

import Foundation
import Combine

@MainActor
final class WorkoutTimerStore: ObservableObject {
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var hasStarted: Bool = false
    
    private var timerTask: Task<Void, Never>?
    private var startDate: Date?
    private var accumulatedTime: TimeInterval = 0
    
    // MARK: - Formatted Time
    
    var formattedTime: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Actions
    
    func start() {
        guard !isRunning else { return }
        hasStarted = true
        isRunning = true
        startDate = Date()
        
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 segundo
                guard !Task.isCancelled else { break }
                self?.tick()
            }
        }
    }
    
    func pause() {
        guard isRunning else { return }
        isRunning = false
        
        if let startDate {
            accumulatedTime += Date().timeIntervalSince(startDate)
        }
        startDate = nil
        
        timerTask?.cancel()
        timerTask = nil
    }
    
    func toggle() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }
    
    func reset() {
        pause()
        elapsedSeconds = 0
        accumulatedTime = 0
        hasStarted = false
    }
    
    // MARK: - Private
    
    private func tick() {
        guard isRunning else { return }
        
        var totalTime = accumulatedTime
        if let startDate {
            totalTime += Date().timeIntervalSince(startDate)
        }
        elapsedSeconds = Int(totalTime)
    }
    
    deinit {
        timerTask?.cancel()
    }
}


