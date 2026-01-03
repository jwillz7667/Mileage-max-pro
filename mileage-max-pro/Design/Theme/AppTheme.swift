//
//  AppTheme.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI

/// Main theme configuration for MileageMax Pro
/// Implements iOS 26.1 Liquid Glass design language
@Observable
final class AppTheme {

    // MARK: - Singleton

    static let shared = AppTheme()

    // MARK: - Theme Mode

    var colorScheme: ColorScheme = .dark
    var isReducedMotion: Bool = false
    var isReducedTransparency: Bool = false

    // MARK: - Computed Properties

    var isDarkMode: Bool {
        colorScheme == .dark
    }

    // MARK: - Glass Properties

    var glassOpacity: Double {
        isReducedTransparency ? 0.9 : 0.7
    }

    var blurRadius: CGFloat {
        isReducedTransparency ? 10 : 20
    }

    // MARK: - Animation Properties

    var animationDuration: Double {
        isReducedMotion ? 0 : AppConstants.AnimationDuration.standard
    }

    var springResponse: Double {
        isReducedMotion ? 0 : 0.35
    }

    var springDamping: Double {
        0.7
    }

    // MARK: - Initialization

    private init() {
        // Observe accessibility settings
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isReducedMotion = UIAccessibility.isReduceMotionEnabled
        }

        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isReducedTransparency = UIAccessibility.isReduceTransparencyEnabled
        }

        // Set initial values
        isReducedMotion = UIAccessibility.isReduceMotionEnabled
        isReducedTransparency = UIAccessibility.isReduceTransparencyEnabled
    }

    // MARK: - Methods

    func standardSpring() -> Animation {
        isReducedMotion ? .linear(duration: 0) : .spring(response: springResponse, dampingFraction: springDamping)
    }

    func quickSpring() -> Animation {
        isReducedMotion ? .linear(duration: 0) : .spring(response: 0.25, dampingFraction: 0.8)
    }

    func smoothTransition() -> Animation {
        isReducedMotion ? .linear(duration: 0) : .easeInOut(duration: animationDuration)
    }
}

// MARK: - Theme Environment Key

private struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppTheme.shared
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - Theme View Modifier

struct ThemedViewModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .environment(\.appTheme, AppTheme.shared)
            .onAppear {
                AppTheme.shared.colorScheme = colorScheme
            }
            .onChange(of: colorScheme) { _, newValue in
                AppTheme.shared.colorScheme = newValue
            }
    }
}

extension View {
    /// Apply app theme to view hierarchy
    func withAppTheme() -> some View {
        modifier(ThemedViewModifier())
    }
}

// MARK: - Common Styles

extension AppTheme {
    // MARK: - Corner Radii

    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusXLarge: CGFloat = 24
    static let cornerRadiusCard: CGFloat = 20
    static let cornerRadiusPill: CGFloat = 100

    // MARK: - Shadow

    static let shadowRadiusSmall: CGFloat = 4
    static let shadowRadiusMedium: CGFloat = 8
    static let shadowRadiusLarge: CGFloat = 16
    static let shadowRadiusXLarge: CGFloat = 24

    static let shadowOpacity: Double = 0.1
    static let shadowOffsetY: CGFloat = 4

    // MARK: - Blur

    static let blurRadiusThin: CGFloat = 10
    static let blurRadiusRegular: CGFloat = 20
    static let blurRadiusThick: CGFloat = 40

    // MARK: - Icon Sizes

    static let iconSizeSmall: CGFloat = 16
    static let iconSizeMedium: CGFloat = 20
    static let iconSizeLarge: CGFloat = 24
    static let iconSizeXLarge: CGFloat = 32
    static let iconSizeXXLarge: CGFloat = 48

    // MARK: - Touch Targets

    static let minimumTouchTarget: CGFloat = 44
    static let buttonHeight: CGFloat = 50
    static let buttonHeightSmall: CGFloat = 36
    static let buttonHeightLarge: CGFloat = 56
}

// MARK: - Standard Gradients

extension LinearGradient {
    /// Primary app gradient
    static var primary: LinearGradient {
        LinearGradient(
            colors: [ColorConstants.primary, ColorConstants.secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Glass overlay gradient
    static var glassOverlay: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.25),
                Color.white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Neumorphic highlight gradient
    static var neumorphicHighlight: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.3),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .center
        )
    }
}

// MARK: - Standard Shadows

extension View {
    /// Apply card shadow
    func cardShadow() -> some View {
        self
            .shadow(
                color: Color.black.opacity(AppTheme.shadowOpacity),
                radius: AppTheme.shadowRadiusMedium,
                x: 0,
                y: AppTheme.shadowOffsetY
            )
    }

    /// Apply button shadow
    func buttonShadow() -> some View {
        self
            .shadow(
                color: Color.black.opacity(AppTheme.shadowOpacity * 0.5),
                radius: AppTheme.shadowRadiusSmall,
                x: 0,
                y: 2
            )
    }

    /// Apply elevated shadow
    func elevatedShadow() -> some View {
        self
            .shadow(
                color: Color.black.opacity(AppTheme.shadowOpacity * 1.5),
                radius: AppTheme.shadowRadiusLarge,
                x: 0,
                y: 8
            )
    }
}
