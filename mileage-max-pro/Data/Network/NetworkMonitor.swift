//
//  NetworkMonitor.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import Network
import Combine
import os

/// Monitors network connectivity status
@MainActor
final class NetworkMonitor: ObservableObject {

    // MARK: - Singleton

    static let shared = NetworkMonitor()

    // MARK: - Published Properties

    @Published private(set) var isConnected = true
    @Published private(set) var connectionType: ConnectionType = .unknown
    @Published private(set) var isExpensive = false
    @Published private(set) var isConstrained = false

    // MARK: - Properties

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.mileagemaxpro.networkmonitor")
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Connection Type

    enum ConnectionType {
        case wifi
        case cellular
        case wiredEthernet
        case loopback
        case unknown

        var displayName: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .wiredEthernet: return "Ethernet"
            case .loopback: return "Loopback"
            case .unknown: return "Unknown"
            }
        }

        var icon: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .wiredEthernet: return "cable.connector"
            case .loopback: return "arrow.2.circlepath"
            case .unknown: return "questionmark.circle"
            }
        }
    }

    // MARK: - Initialization

    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.handlePathUpdate(path)
            }
        }
        monitor.start(queue: queue)
    }

    private func handlePathUpdate(_ path: NWPath) {
        let previouslyConnected = isConnected
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained

        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else if path.usesInterfaceType(.loopback) {
            connectionType = .loopback
        } else {
            connectionType = .unknown
        }

        // Log connectivity changes
        if isConnected != previouslyConnected {
            if isConnected {
                AppLogger.network.info("Network connected via \(self.connectionType.displayName)")
            } else {
                AppLogger.network.warning("Network disconnected")
            }
        }
    }

    // MARK: - Public Methods

    /// Wait for network connectivity
    func waitForConnection(timeout: TimeInterval = 30) async -> Bool {
        if isConnected {
            return true
        }

        return await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            var completed = false

            // Timeout task
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                guard !completed else { return }
                completed = true
                cancellable?.cancel()
                continuation.resume(returning: false)
            }

            // Wait for connection
            cancellable = $isConnected
                .filter { $0 }
                .first()
                .sink { _ in
                    guard !completed else { return }
                    completed = true
                    timeoutTask.cancel()
                    continuation.resume(returning: true)
                }
        }
    }

    /// Check if the current connection is suitable for syncing
    var isSuitableForSync: Bool {
        guard isConnected else { return false }

        // Don't sync on expensive connections if user prefers Wi-Fi only
        // This should be configurable via UserSettings
        if isExpensive {
            return UserDefaults.standard.bool(forKey: "syncOnCellular")
        }

        return true
    }

    /// Check if the current connection is suitable for large uploads
    var isSuitableForLargeUploads: Bool {
        guard isConnected else { return false }
        return connectionType == .wifi && !isConstrained
    }
}

// MARK: - Network Reachability Extension

extension NetworkMonitor {
    /// Publisher for network status changes
    var networkStatusPublisher: AnyPublisher<Bool, Never> {
        $isConnected.eraseToAnyPublisher()
    }

    /// Publisher for connection type changes
    var connectionTypePublisher: AnyPublisher<ConnectionType, Never> {
        $connectionType.eraseToAnyPublisher()
    }
}

// MARK: - SwiftUI Environment

import SwiftUI

private struct NetworkMonitorKey: EnvironmentKey {
    static let defaultValue: NetworkMonitor = .shared
}

extension EnvironmentValues {
    var networkMonitor: NetworkMonitor {
        get { self[NetworkMonitorKey.self] }
        set { self[NetworkMonitorKey.self] = newValue }
    }
}

// MARK: - View Modifier for Offline Banner

struct OfflineBannerModifier: ViewModifier {
    @StateObject private var networkMonitor = NetworkMonitor.shared

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            if !networkMonitor.isConnected {
                offlineBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            content
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: networkMonitor.isConnected)
    }

    private var offlineBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .medium))

            Text("You're offline")
                .font(Typography.caption1)
                .fontWeight(.medium)

            Spacer()

            if NetworkMonitor.shared.connectionType != .unknown {
                Text("Last: \(networkMonitor.connectionType.displayName)")
                    .font(Typography.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(ColorConstants.warning)
    }
}

extension View {
    /// Show offline banner when network is unavailable
    func offlineBanner() -> some View {
        modifier(OfflineBannerModifier())
    }
}

// MARK: - Network Quality

extension NetworkMonitor {
    /// Assess network quality for adaptive behavior
    var networkQuality: NetworkQuality {
        guard isConnected else { return .offline }

        if isConstrained {
            return .poor
        }

        switch connectionType {
        case .wifi:
            return .excellent
        case .wiredEthernet:
            return .excellent
        case .cellular:
            return isExpensive ? .fair : .good
        default:
            return .unknown
        }
    }

    enum NetworkQuality: Int, Comparable {
        case offline = 0
        case poor = 1
        case fair = 2
        case good = 3
        case excellent = 4
        case unknown = -1

        static func < (lhs: NetworkQuality, rhs: NetworkQuality) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        var displayName: String {
            switch self {
            case .offline: return "Offline"
            case .poor: return "Poor"
            case .fair: return "Fair"
            case .good: return "Good"
            case .excellent: return "Excellent"
            case .unknown: return "Unknown"
            }
        }

        var recommendedImageQuality: ImageQuality {
            switch self {
            case .offline, .poor:
                return .low
            case .fair, .unknown:
                return .medium
            case .good, .excellent:
                return .high
            }
        }
    }

    enum ImageQuality {
        case low
        case medium
        case high

        var compressionQuality: CGFloat {
            switch self {
            case .low: return 0.3
            case .medium: return 0.6
            case .high: return 0.9
            }
        }

        var maxDimension: CGFloat {
            switch self {
            case .low: return 800
            case .medium: return 1200
            case .high: return 2000
            }
        }
    }
}
