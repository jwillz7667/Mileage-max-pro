//
//  LiquidGlassTheme.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI

/// iOS 26.1 Liquid Glass design implementation
struct LiquidGlassTheme {

    // MARK: - Glass Material Properties

    struct GlassMaterial {
        let blur: CGFloat
        let opacity: Double
        let borderOpacity: Double
        let shadowOpacity: Double
        let shadowRadius: CGFloat

        static let ultraThin = GlassMaterial(
            blur: 40,
            opacity: 0.3,
            borderOpacity: 0.1,
            shadowOpacity: 0.05,
            shadowRadius: 8
        )

        static let thin = GlassMaterial(
            blur: 30,
            opacity: 0.5,
            borderOpacity: 0.15,
            shadowOpacity: 0.08,
            shadowRadius: 10
        )

        static let regular = GlassMaterial(
            blur: 20,
            opacity: 0.7,
            borderOpacity: 0.2,
            shadowOpacity: 0.1,
            shadowRadius: 12
        )

        static let thick = GlassMaterial(
            blur: 15,
            opacity: 0.85,
            borderOpacity: 0.25,
            shadowOpacity: 0.12,
            shadowRadius: 16
        )

        static let ultraThick = GlassMaterial(
            blur: 10,
            opacity: 0.95,
            borderOpacity: 0.3,
            shadowOpacity: 0.15,
            shadowRadius: 20
        )
    }

    // MARK: - Refraction Properties

    struct Refraction {
        let highlightIntensity: Double
        let highlightOffset: CGFloat
        let specularSize: CGFloat
    }
}

// MARK: - Liquid Glass View Modifier

struct LiquidGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let material: LiquidGlassTheme.GlassMaterial
    let showBorder: Bool
    let shadowEnabled: Bool

    @Environment(\.colorScheme) private var colorScheme

    init(
        cornerRadius: CGFloat = AppTheme.cornerRadiusCard,
        material: LiquidGlassTheme.GlassMaterial = .regular,
        showBorder: Bool = true,
        shadowEnabled: Bool = true
    ) {
        self.cornerRadius = cornerRadius
        self.material = material
        self.showBorder = showBorder
        self.shadowEnabled = shadowEnabled
    }

    func body(content: Content) -> some View {
        content
            .background(glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(borderOverlay)
            .if(shadowEnabled) { view in
                view.shadow(
                    color: Color.black.opacity(material.shadowOpacity),
                    radius: material.shadowRadius,
                    x: 0,
                    y: material.shadowRadius / 2
                )
            }
    }

    @ViewBuilder
    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .opacity(material.opacity)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(highlightGradient)
            )
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if showBorder {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(borderGradient, lineWidth: 1)
        }
    }

    private var highlightGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2),
                Color.white.opacity(0)
            ],
            startPoint: .topLeading,
            endPoint: .center
        )
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(material.borderOpacity * (colorScheme == .dark ? 0.5 : 1.0)),
                Color.white.opacity(material.borderOpacity * 0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Glass Card Modifier

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

// MARK: - Frosted Glass Modifier

struct FrostedGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color
    let tintOpacity: Double

    @Environment(\.colorScheme) private var colorScheme

    init(
        cornerRadius: CGFloat = AppTheme.cornerRadiusCard,
        tint: Color = .white,
        tintOpacity: Double = 0.1
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.tintOpacity = tintOpacity
    }

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tint.opacity(tintOpacity))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - View Extensions

extension View {
    /// Apply Liquid Glass effect
    func liquidGlassStyle(
        cornerRadius: CGFloat = AppTheme.cornerRadiusCard,
        material: LiquidGlassTheme.GlassMaterial = .regular,
        showBorder: Bool = true,
        shadowEnabled: Bool = true
    ) -> some View {
        modifier(LiquidGlassModifier(
            cornerRadius: cornerRadius,
            material: material,
            showBorder: showBorder,
            shadowEnabled: shadowEnabled
        ))
    }

    /// Apply Glass Card styling with padding
    func glassCardStyle(
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        cornerRadius: CGFloat = AppTheme.cornerRadiusCard
    ) -> some View {
        modifier(GlassCardModifier(padding: padding, cornerRadius: cornerRadius))
    }

    /// Apply Frosted Glass effect with optional tint
    func frostedGlass(
        cornerRadius: CGFloat = AppTheme.cornerRadiusCard,
        tint: Color = .white,
        tintOpacity: Double = 0.1
    ) -> some View {
        modifier(FrostedGlassModifier(
            cornerRadius: cornerRadius,
            tint: tint,
            tintOpacity: tintOpacity
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
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .opacity(material.opacity)
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
                y: material.shadowRadius / 2
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
            .fill(.ultraThinMaterial)
            .opacity(material.opacity)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(material.borderOpacity), lineWidth: 1)
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
            .fill(.ultraThinMaterial)
            .opacity(material.opacity)
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
