//
//  AppTheme.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//  Premium Design System - iOS 26 Liquid Glass + 3D Neomorphism
//

import SwiftUI

/// Main theme configuration for MileageMax Pro
/// Implements iOS 26 Liquid Glass + Premium Neomorphism
@Observable
final class AppTheme {

    // MARK: - Singleton

    static let shared = AppTheme()

    // MARK: - Theme Mode

    var colorScheme: ColorScheme = .light
    var isReducedMotion: Bool = false
    var isReducedTransparency: Bool = false

    // MARK: - Computed Properties

    var isDarkMode: Bool {
        colorScheme == .dark
    }

    // MARK: - Glass Properties

    var glassOpacity: Double {
        isReducedTransparency ? 0.95 : 0.85
    }

    var blurRadius: CGFloat {
        isReducedTransparency ? 8 : 16
    }

    // MARK: - Animation Properties

    var animationDuration: Double {
        isReducedMotion ? 0 : AppConstants.AnimationDuration.standard
    }

    var springResponse: Double {
        isReducedMotion ? 0 : 0.4
    }

    var springDamping: Double {
        0.75
    }

    // MARK: - Initialization

    private init() {
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

        isReducedMotion = UIAccessibility.isReduceMotionEnabled
        isReducedTransparency = UIAccessibility.isReduceTransparencyEnabled
    }

    // MARK: - Animation Methods

    func standardSpring() -> Animation {
        isReducedMotion ? .linear(duration: 0) : .spring(response: springResponse, dampingFraction: springDamping)
    }

    func quickSpring() -> Animation {
        isReducedMotion ? .linear(duration: 0) : .spring(response: 0.25, dampingFraction: 0.8)
    }

    func smoothTransition() -> Animation {
        isReducedMotion ? .linear(duration: 0) : .easeInOut(duration: animationDuration)
    }

    func bounceSpring() -> Animation {
        isReducedMotion ? .linear(duration: 0) : .spring(response: 0.5, dampingFraction: 0.6)
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
    func withAppTheme() -> some View {
        modifier(ThemedViewModifier())
    }
}

// MARK: - Design Constants

extension AppTheme {

    // MARK: - Corner Radii (iOS 26 Style)

    static let cornerRadiusXS: CGFloat = 6
    static let cornerRadiusSmall: CGFloat = 10
    static let cornerRadiusMedium: CGFloat = 14
    static let cornerRadiusLarge: CGFloat = 18
    static let cornerRadiusXLarge: CGFloat = 24
    static let cornerRadiusXXLarge: CGFloat = 32
    static let cornerRadiusCard: CGFloat = 20
    static let cornerRadiusPill: CGFloat = 100

    // MARK: - Shadow Radii

    static let shadowRadiusXS: CGFloat = 2
    static let shadowRadiusSmall: CGFloat = 4
    static let shadowRadiusMedium: CGFloat = 8
    static let shadowRadiusLarge: CGFloat = 16
    static let shadowRadiusXLarge: CGFloat = 24
    static let shadowRadiusXXLarge: CGFloat = 40

    // MARK: - Shadow Properties

    static let shadowOpacity: Double = 0.08
    static let shadowOffsetY: CGFloat = 4

    // MARK: - Blur Radii

    static let blurRadiusThin: CGFloat = 8
    static let blurRadiusRegular: CGFloat = 16
    static let blurRadiusThick: CGFloat = 32

    // MARK: - Icon Sizes (iOS 26 Guidelines)

    static let iconSizeXS: CGFloat = 12
    static let iconSizeSmall: CGFloat = 16
    static let iconSizeMedium: CGFloat = 20
    static let iconSizeLarge: CGFloat = 24
    static let iconSizeXLarge: CGFloat = 32
    static let iconSizeXXLarge: CGFloat = 48
    static let iconSizeHero: CGFloat = 64

    // MARK: - Touch Targets (HIG Compliance)

    static let minimumTouchTarget: CGFloat = 44
    static let buttonHeight: CGFloat = 52
    static let buttonHeightSmall: CGFloat = 40
    static let buttonHeightLarge: CGFloat = 56

    // MARK: - Neomorphic Properties

    static let neomorphicLightOffset: CGFloat = -4
    static let neomorphicDarkOffset: CGFloat = 4
    static let neomorphicBlur: CGFloat = 8
    static let neomorphicIntensity: Double = 0.15
}

// MARK: - Premium Gradients

extension LinearGradient {
    /// Primary brand gradient
    static var appPrimary: LinearGradient {
        ColorConstants.Gradients.primary
    }

    /// Glass overlay gradient for light mode
    static var glassOverlay: LinearGradient {
        ColorConstants.Gradients.glassOverlay
    }

    /// Glass highlight for top edge
    static var glassHighlight: LinearGradient {
        ColorConstants.Gradients.glassHighlight
    }

    /// Neomorphic highlight gradient
    static var neomorphicHighlight: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.8),
                Color.white.opacity(0.0)
            ],
            startPoint: .topLeading,
            endPoint: .center
        )
    }

    /// Subtle surface gradient
    static var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                ColorConstants.Surface.card,
                ColorConstants.Surface.elevated
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Premium Shadow Styles

extension View {
    /// Apply premium card shadow
    func cardShadow() -> some View {
        self
            .shadow(
                color: ColorConstants.Neomorphic.darkShadow,
                radius: AppTheme.shadowRadiusMedium,
                x: 0,
                y: AppTheme.shadowOffsetY
            )
    }

    /// Apply subtle button shadow
    func buttonShadow() -> some View {
        self
            .shadow(
                color: ColorConstants.Neomorphic.darkShadow,
                radius: AppTheme.shadowRadiusSmall,
                x: 0,
                y: 2
            )
    }

    /// Apply elevated shadow for floating elements
    func elevatedShadow() -> some View {
        self
            .shadow(
                color: Color.black.opacity(0.12),
                radius: AppTheme.shadowRadiusLarge,
                x: 0,
                y: 8
            )
    }

    /// Apply primary color glow shadow
    func primaryGlow() -> some View {
        self
            .shadow(
                color: ColorConstants.primary.opacity(0.3),
                radius: AppTheme.shadowRadiusMedium,
                x: 0,
                y: 4
            )
    }

    /// Apply 3D neomorphic shadow (raised effect)
    func neomorphicRaised() -> some View {
        self
            .shadow(
                color: ColorConstants.Neomorphic.lightShadow,
                radius: AppTheme.neomorphicBlur,
                x: AppTheme.neomorphicLightOffset,
                y: AppTheme.neomorphicLightOffset
            )
            .shadow(
                color: ColorConstants.Neomorphic.darkShadow,
                radius: AppTheme.neomorphicBlur,
                x: AppTheme.neomorphicDarkOffset,
                y: AppTheme.neomorphicDarkOffset
            )
    }

    /// Apply 3D neomorphic shadow (pressed/recessed effect)
    func neomorphicPressed() -> some View {
        self
            .shadow(
                color: ColorConstants.Neomorphic.innerDark,
                radius: 4,
                x: 2,
                y: 2
            )
            .shadow(
                color: ColorConstants.Neomorphic.innerLight,
                radius: 4,
                x: -2,
                y: -2
            )
    }

    /// Apply soft ambient shadow
    func ambientShadow() -> some View {
        self
            .shadow(
                color: Color.black.opacity(0.04),
                radius: AppTheme.shadowRadiusXLarge,
                x: 0,
                y: 12
            )
    }
}

// MARK: - Premium Animation Curves

extension Animation {
    /// Premium spring animation
    static var premiumSpring: Animation {
        .spring(response: 0.4, dampingFraction: 0.75)
    }

    /// Quick responsive animation
    static var quickResponse: Animation {
        .spring(response: 0.25, dampingFraction: 0.8)
    }

    /// Smooth ease animation
    static var smoothEase: Animation {
        .easeInOut(duration: 0.3)
    }

    /// Bouncy animation for playful interactions
    static var bouncy: Animation {
        .spring(response: 0.5, dampingFraction: 0.6)
    }

    /// Gentle fade animation
    static var gentleFade: Animation {
        .easeOut(duration: 0.2)
    }
}
