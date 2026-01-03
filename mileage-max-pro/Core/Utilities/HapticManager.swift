//
//  HapticManager.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import UIKit
import CoreHaptics

/// Centralized haptic feedback manager following iOS 26.1 guidelines
final class HapticManager {

    // MARK: - Singleton

    static let shared = HapticManager()

    // MARK: - Properties

    private var impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [:]
    private var selectionGenerator: UISelectionFeedbackGenerator?
    private var notificationGenerator: UINotificationFeedbackGenerator?

    private var hapticEngine: CHHapticEngine?
    private var supportsHaptics: Bool = false

    private var isEnabled: Bool = true

    // MARK: - Initialization

    private init() {
        setupGenerators()
        setupHapticEngine()
    }

    private func setupGenerators() {
        // Pre-create feedback generators for performance
        let styles: [UIImpactFeedbackGenerator.FeedbackStyle] = [.light, .medium, .heavy, .soft, .rigid]
        for style in styles {
            impactGenerators[style] = UIImpactFeedbackGenerator(style: style)
        }

        selectionGenerator = UISelectionFeedbackGenerator()
        notificationGenerator = UINotificationFeedbackGenerator()

        // Prepare generators
        prepareAll()
    }

    private func setupHapticEngine() {
        // Skip haptics setup on simulator - they're not supported
        #if targetEnvironment(simulator)
        supportsHaptics = false
        return
        #endif

        // Check for Core Haptics support
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            supportsHaptics = false
            return
        }

        supportsHaptics = true

        do {
            hapticEngine = try CHHapticEngine()
            hapticEngine?.playsHapticsOnly = true
            hapticEngine?.stoppedHandler = { [weak self] reason in
                Logger.shared.debug("Haptic engine stopped: \(reason.rawValue)", category: .general)
                self?.restartHapticEngine()
            }
            hapticEngine?.resetHandler = { [weak self] in
                Logger.shared.debug("Haptic engine reset", category: .general)
                self?.restartHapticEngine()
            }
            try hapticEngine?.start()
        } catch {
            Logger.shared.error("Failed to create haptic engine", error: error)
            supportsHaptics = false
        }
    }

    private func restartHapticEngine() {
        guard supportsHaptics else { return }
        do {
            try hapticEngine?.start()
        } catch {
            Logger.shared.error("Failed to restart haptic engine", error: error)
        }
    }

    // MARK: - Configuration

    /// Enable or disable haptic feedback globally
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        Logger.shared.debug("Haptics \(enabled ? "enabled" : "disabled")")
    }

    /// Prepare all generators for immediate response
    func prepareAll() {
        impactGenerators.values.forEach { $0.prepare() }
        selectionGenerator?.prepare()
        notificationGenerator?.prepare()
    }

    // MARK: - Impact Feedback

    /// Light impact - for button taps
    func lightImpact() {
        impact(.light)
    }

    /// Medium impact - for toggle switches
    func mediumImpact() {
        impact(.medium)
    }

    /// Heavy impact - for destructive actions
    func heavyImpact() {
        impact(.heavy)
    }

    /// Soft impact - for subtle feedback
    func softImpact() {
        impact(.soft)
    }

    /// Rigid impact - for drag thresholds
    func rigidImpact() {
        impact(.rigid)
    }

    /// Custom intensity impact
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1.0) {
        guard isEnabled else { return }
        impactGenerators[style]?.impactOccurred(intensity: intensity)
        impactGenerators[style]?.prepare()
    }

    // MARK: - Selection Feedback

    /// Selection change haptic
    func selection() {
        guard isEnabled else { return }
        selectionGenerator?.selectionChanged()
        selectionGenerator?.prepare()
    }

    // MARK: - Notification Feedback

    /// Success notification haptic
    func success() {
        notification(.success)
    }

    /// Warning notification haptic
    func warning() {
        notification(.warning)
    }

    /// Error notification haptic
    func error() {
        notification(.error)
    }

    private func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        notificationGenerator?.notificationOccurred(type)
        notificationGenerator?.prepare()
    }

    // MARK: - Custom Patterns

    /// Play button tap pattern
    func buttonTap() {
        lightImpact()
    }

    /// Play toggle switch pattern
    func toggleSwitch() {
        mediumImpact()
    }

    /// Play swipe action pattern
    func swipeAction() {
        softImpact()
    }

    /// Play delete action pattern
    func deleteAction() {
        heavyImpact()
    }

    /// Play trip start pattern
    func tripStart() {
        guard isEnabled, supportsHaptics else {
            success()
            return
        }
        playPattern(.tripStart)
    }

    /// Play trip end pattern
    func tripEnd() {
        guard isEnabled, supportsHaptics else {
            success()
            return
        }
        playPattern(.tripEnd)
    }

    /// Play stop arrived pattern
    func stopArrived() {
        guard isEnabled, supportsHaptics else {
            success()
            return
        }
        playPattern(.stopArrived)
    }

    /// Play countdown tick pattern
    func countdownTick() {
        selection()
    }

    /// Play milestone reached pattern
    func milestoneReached() {
        guard isEnabled, supportsHaptics else {
            success()
            return
        }
        playPattern(.milestone)
    }

    // MARK: - Core Haptics Patterns

    private func playPattern(_ pattern: HapticPattern) {
        guard supportsHaptics, let engine = hapticEngine else { return }

        do {
            let events = pattern.events
            let hapticPattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: hapticPattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            Logger.shared.error("Failed to play haptic pattern: \(pattern)", error: error)
            // Fallback to simple haptic
            mediumImpact()
        }
    }
}

// MARK: - Haptic Patterns

private enum HapticPattern {
    case tripStart
    case tripEnd
    case stopArrived
    case milestone

    var events: [CHHapticEvent] {
        switch self {
        case .tripStart:
            return [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ],
                    relativeTime: 0.1
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ],
                    relativeTime: 0.2
                )
            ]

        case .tripEnd:
            return [
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ],
                    relativeTime: 0,
                    duration: 0.3
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ],
                    relativeTime: 0.35
                )
            ]

        case .stopArrived:
            return [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ],
                    relativeTime: 0.15
                )
            ]

        case .milestone:
            return [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ],
                    relativeTime: 0.1,
                    duration: 0.4
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ],
                    relativeTime: 0.5
                )
            ]
        }
    }
}
