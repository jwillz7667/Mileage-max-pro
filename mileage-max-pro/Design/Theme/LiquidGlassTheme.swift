//
//  LiquidGlassTheme.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//  Premium iOS 26 Liquid Glass Design System
//

import SwiftUI

/// iOS 26 Liquid Glass + 3D Neomorphism Design System
struct LiquidGlassTheme {

    // MARK: - Glass Material Properties

    struct GlassMaterial {
        let blur: CGFloat
        let opacity: Double
        let borderOpacity: Double
        let shadowOpacity: Double
        let shadowRadius: CGFloat
        let tintOpacity: Double

        static let ultraThin = GlassMaterial(
            blur: 32,
            opacity: 0.4,
            borderOpacity: 0.15,
            shadowOpacity: 0.04,
            shadowRadius: 6,
            tintOpacity: 0.02
        )

        static let thin = GlassMaterial(
            blur: 24,
            opacity: 0.6,
            borderOpacity: 0.2,
            shadowOpacity: 0.06,
            shadowRadius: 8,
            tintOpacity: 0.04
        )

        static let regular = GlassMaterial(
            blur: 16,
            opacity: 0.8,
            borderOpacity: 0.25,
            shadowOpacity: 0.08,
            shadowRadius: 12,
            tintOpacity: 0.06
        )

        static let thick = GlassMaterial(
            blur: 12,
            opacity: 0.9,
            borderOpacity: 0.3,
            shadowOpacity: 0.1,
            shadowRadius: 16,
            tintOpacity: 0.08
        )

        static let ultraThick = GlassMaterial(
            blur: 8,
            opacity: 0.95,
            borderOpacity: 0.35,
            shadowOpacity: 0.12,
            shadowRadius: 20,
            tintOpacity: 0.1
        )

        /// Premium frosted glass for cards
        static let frosted = GlassMaterial(
            blur: 20,
            opacity: 0.85,
            borderOpacity: 0.2,
            shadowOpacity: 0.08,
            shadowRadius: 16,
            tintOpacity: 0.05
        )
    }

    // MARK: - Refraction Properties

    struct Refraction {
        let highlightIntensity: Double
        let highlightOffset: CGFloat
        let specularSize: CGFloat

        static let subtle = Refraction(
            highlightIntensity: 0.3,
            highlightOffset: 2,
            specularSize: 0.4
        )

        static let standard = Refraction(
            highlightIntensity: 0.5,
            highlightOffset: 4,
            specularSize: 0.5
        )

        static let prominent = Refraction(
            highlightIntensity: 0.7,
            highlightOffset: 6,
            specularSize: 0.6
        )
    }
}

// MARK: - Premium Liquid Glass Modifier

struct LiquidGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let material: LiquidGlassTheme.GlassMaterial
    let showBorder: Bool
    let shadowEnabled: Bool
    let tintColor: Color?

    @Environment(\.colorScheme) private var colorScheme

    init(
        cornerRadius: CGFloat = AppTheme.cornerRadiusCard,
        material: LiquidGlassTheme.GlassMaterial = .regular,
        showBorder: Bool = true,
        shadowEnabled: Bool = true,
        tintColor: Color? = nil
    ) {
        self.cornerRadius = cornerRadius
        self.material = material
        self.showBorder = showBorder
        self.shadowEnabled = shadowEnabled
        self.tintColor = tintColor
    }

    func body(content: Content) -> some View {
        content
            .background(glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(borderOverlay)
            .if(shadowEnabled) { view in
                view
                    .shadow(
                        color: Color.black.opacity(material.shadowOpacity),
                        radius: material.shadowRadius,
                        x: 0,
                        y: material.shadowRadius / 3
                    )
            }
    }

    @ViewBuilder
    private var glassBackground: some View {
        ZStack {
            // Base frosted glass
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(material.opacity)

            // White overlay for light mode brightness
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.7))

            // Optional tint color
            if let tint = tintColor {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tint.opacity(material.tintOpacity))
            }

            // Premium highlight gradient
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if showBorder {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(material.borderOpacity * 1.5),
                            Color.white.opacity(material.borderOpacity * 0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - Premium Glass Card Modifier

struct GlassCardModifier: ViewModifier {
    let padding: EdgeInsets
    let cornerRadius: CGFloat

    init(
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        cornerRadius: CGFloat = AppTheme.cornerRadiusCard
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .modifier(LiquidGlassModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Premium Frosted Glass Modifier

struct FrostedGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color
    let tintOpacity: Double

    @Environment(\.colorScheme) private var colorScheme

    init(
        cornerRadius: CGFloat = AppTheme.cornerRadiusCard,
        tint: Color = ColorConstants.primary,
        tintOpacity: Double = 0.05
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.tintOpacity = tintOpacity
    }

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base white
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(ColorConstants.Surface.card)

                    // Frosted material
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.5)

                    // Tint overlay
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tint.opacity(tintOpacity))

                    // Highlight
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(ColorConstants.Border.standard, lineWidth: 0.5)
            )
            .cardShadow()
    }
}

// MARK: - Neomorphic Card Modifier

struct NeomorphicCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let isPressed: Bool

    init(
        cornerRadius: CGFloat = AppTheme.cornerRadiusCard,
        isPressed: Bool = false
    ) {
        self.cornerRadius = cornerRadius
        self.isPressed = isPressed
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(ColorConstants.Surface.card)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .if(!isPressed) { view in
                view.neomorphicRaised()
            }
            .if(isPressed) { view in
                view
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(ColorConstants.Gradients.neomorphicInner)
                    )
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply Premium Liquid Glass effect
    func liquidGlassStyle(
        cornerRadius: CGFloat = AppTheme.cornerRadiusCard,
        material: LiquidGlassTheme.GlassMaterial = .regular,
        showBorder: Bool = true,
        shadowEnabled: Bool = true,
        tintColor: Color? = nil
    ) -> some View {
        modifier(LiquidGlassModifier(
            cornerRadius: cornerRadius,
            material: material,
            showBorder: showBorder,
            shadowEnabled: shadowEnabled,
            tintColor: tintColor
        ))
    }

    /// Apply Glass Card styling with padding
    func glassCardStyle(
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        cornerRadius: CGFloat = AppTheme.cornerRadiusCard
    ) -> some View {
        modifier(GlassCardModifier(padding: padding, cornerRadius: cornerRadius))
    }

    /// Apply Premium Frosted Glass effect with optional tint
    func frostedGlass(
        cornerRadius: CGFloat = AppTheme.cornerRadiusCard,
        tint: Color = ColorConstants.primary,
        tintOpacity: Double = 0.05
    ) -> some View {
        modifier(FrostedGlassModifier(
            cornerRadius: cornerRadius,
            tint: tint,
            tintOpacity: tintOpacity
        ))
    }

    /// Apply 3D Neomorphic card style
    func neomorphicCard(
        cornerRadius: CGFloat = AppTheme.cornerRadiusCard,
        isPressed: Bool = false
    ) -> some View {
        modifier(NeomorphicCardModifier(
            cornerRadius: cornerRadius,
            isPressed: isPressed
        ))
    }

    /// Apply ultra-thin glass for overlays
    func ultraThinGlass(cornerRadius: CGFloat = AppTheme.cornerRadiusCard) -> some View {
        modifier(LiquidGlassModifier(
            cornerRadius: cornerRadius,
            material: .ultraThin,
            showBorder: false,
            shadowEnabled: false
        ))
    }

    /// Apply thick glass for prominent cards
    func prominentGlass(cornerRadius: CGFloat = AppTheme.cornerRadiusCard) -> some View {
        modifier(LiquidGlassModifier(
            cornerRadius: cornerRadius,
            material: .thick,
            showBorder: true,
            shadowEnabled: true
        ))
    }

    /// Apply primary-tinted glass
    func primaryTintedGlass(cornerRadius: CGFloat = AppTheme.cornerRadiusCard) -> some View {
        modifier(LiquidGlassModifier(
            cornerRadius: cornerRadius,
            material: .regular,
            showBorder: true,
            shadowEnabled: true,
            tintColor: ColorConstants.primary
        ))
    }
}

// MARK: - Glass Background Shapes

struct GlassBackground: View {
    let cornerRadius: CGFloat
    let material: LiquidGlassTheme.GlassMaterial

    @Environment(\.colorScheme) private var colorScheme

    init(
        cornerRadius: CGFloat = AppTheme.cornerRadiusCard,
        material: LiquidGlassTheme.GlassMaterial = .regular
    ) {
        self.cornerRadius = cornerRadius
        self.material = material
    }

    var body: some View {
        ZStack {
            // Base
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(ColorConstants.Surface.card)

            // Material overlay
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(material.opacity * 0.3)

            // Highlight
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(material.borderOpacity),
                            Color.white.opacity(material.borderOpacity * 0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color.black.opacity(material.shadowOpacity),
            radius: material.shadowRadius,
            x: 0,
            y: material.shadowRadius / 3
        )
    }
}

// MARK: - Glass Capsule

struct GlassCapsule: View {
    let material: LiquidGlassTheme.GlassMaterial

    init(material: LiquidGlassTheme.GlassMaterial = .thin) {
        self.material = material
    }

    var body: some View {
        Capsule()
            .fill(ColorConstants.Surface.card)
            .overlay(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .opacity(material.opacity * 0.3)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(material.borderOpacity), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(material.shadowOpacity),
                radius: material.shadowRadius / 2,
                x: 0,
                y: 2
            )
    }
}

// MARK: - Glass Circle

struct GlassCircle: View {
    let material: LiquidGlassTheme.GlassMaterial

    init(material: LiquidGlassTheme.GlassMaterial = .regular) {
        self.material = material
    }

    var body: some View {
        Circle()
            .fill(ColorConstants.Surface.card)
            .overlay(
                Circle()
                    .fill(.ultraThinMaterial)
                    .opacity(material.opacity * 0.3)
            )
            .overlay(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(material.borderOpacity), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(material.shadowOpacity),
                radius: material.shadowRadius / 2,
                x: 0,
                y: material.shadowRadius / 4
            )
    }
}

// MARK: - Premium Pill Badge

struct GlassPill: View {
    let text: String
    let icon: String?
    let color: Color

    init(_ text: String, icon: String? = nil, color: Color = ColorConstants.primary) {
        self.text = text
        self.icon = icon
        self.color = color
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(color.opacity(0.2), lineWidth: 0.5)
        )
    }
}
