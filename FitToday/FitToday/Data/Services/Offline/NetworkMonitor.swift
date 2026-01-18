//
//  NetworkMonitor.swift
//  FitToday
//
//  Created by Claude on 17/01/26.
//

import Foundation
import Network

// MARK: - NetworkMonitor

/// Monitors network connectivity using NWPathMonitor.
/// Notifies when connection is restored to trigger offline sync queue processing.
@MainActor
@Observable
final class NetworkMonitor {

    // MARK: - Properties

    private(set) var isConnected: Bool = false
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.fittoday.networkmonitor")
    private var isMonitoring = false

    /// Callback triggered when connection is restored (goes from disconnected to connected).
    var onConnectionRestored: (@Sendable @MainActor () async -> Void)?

    // MARK: - Initialization

    init() {
        setupPathHandler()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Public Methods

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        monitor.start(queue: monitorQueue)

        #if DEBUG
        print("[NetworkMonitor] Started monitoring network connectivity")
        #endif
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        monitor.cancel()

        #if DEBUG
        print("[NetworkMonitor] Stopped monitoring network connectivity")
        #endif
    }

    // MARK: - Private Methods

    private func setupPathHandler() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }

                let wasConnected = self.isConnected
                let nowConnected = path.status == .satisfied

                self.isConnected = nowConnected

                #if DEBUG
                print("[NetworkMonitor] Network status changed: \(nowConnected ? "Connected" : "Disconnected")")
                #endif

                // Trigger callback if connection was restored
                if !wasConnected && nowConnected {
                    #if DEBUG
                    print("[NetworkMonitor] Connection restored, triggering callback")
                    #endif

                    await self.onConnectionRestored?()
                }
            }
        }
    }
}
