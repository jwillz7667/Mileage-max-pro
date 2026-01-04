//
//  GlassMorphicCard.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//  Premium Glass + Neomorphic Card Components
//

import SwiftUI

/// Premium glassmorphic card with iOS 26 Liquid Glass + 3D Neomorphism
struct GlassMorphicCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    let style: CardStyle

    @Environment(\.colorScheme) private var colorScheme

    enum CardStyle {
        case glass
        case neomorphic
        case frosted
        case elevated
    }

    init(
        cornerRadius: CGFloat = AppTheme.cornerRadiusCard,
        padding: EdgeInsets = Spacing.cardInsets,
        style: CardStyle = .glass,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.style = style
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(cardBorder)
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowOffset
            )
    }

    @ViewBuilder
    private var cardBackground: some View {
        switch style {
        case .glass:
            glassBackground
        case .neomorphic:
            neomorphicBackground
        case .frosted:
            frostedBackground
        case .elevated:
            elevatedBackground
        }
    }

    private var glassBackground: some View {
        ZStack {
            // White base
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(ColorConstants.Surface.card)

            // Subtle material overlay
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.3)

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

    private var neomorphicBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(ColorConstants.Surface.grouped)
    }

    private var frostedBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(ColorConstants.Surface.card)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.5)

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
    }

    private var elevatedBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(ColorConstants.Surface.card)
    }

    @ViewBuilder
    private var cardBorder: some View {
        switch style {
        case .glass, .frosted:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        case .neomorphic:
            EmptyView()
        case .elevated:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(ColorConstants.Border.standard, lineWidth: 0.5)
        }
    }

    private var shadowColor: Color {
        switch style {
        case .neomorphic:
            return ColorConstants.Neomorphic.darkShadow
        default:
            return Color.black.opacity(0.08)
        }
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .glass, .frosted:
            return 12
        case .neomorphic:
            return AppTheme.neomorphicBlur
        case .elevated:
            return 16
        }
    }

    private var shadowOffset: CGFloat {
        switch style {
        case .neomorphic:
            return AppTheme.neomorphicDarkOffset
        default:
            return 4
        }
    }
}

// MARK: - Tinted Glass Card

struct TintedGlassCard<Content: View>: View {
    let content: Content
    let tint: Color
    let cornerRadius: CGFloat
    let padding: EdgeInsets

    @Environment(\.colorScheme) private var colorScheme

    init(
        tint: Color = ColorConstants.primary,
        cornerRadius: CGFloat = AppTheme.cornerRadiusCard,
        padding: EdgeInsets = Spacing.cardInsets,
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // White base
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(ColorConstants.Surface.card)

                    // Tint overlay
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tint.opacity(0.06))

                    // Highlight gradient
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
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
                    .stroke(tint.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: tint.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Interactive Glass Card

struct InteractiveGlassCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let action: () -> Void

    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme

    init(
        cornerRadius: CGFloat = AppTheme.cornerRadiusCard,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            content
                .padding(Spacing.cardInsets)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(cardBorder)
                .shadow(
                    color: Color.black.opacity(isPressed ? 0.04 : 0.08),
                    radius: isPressed ? 4 : 12,
                    x: 0,
                    y: isPressed ? 2 : 4
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.quickResponse) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.premiumSpring) {
                        isPressed = false
                    }
                }
        )
    }

    @ViewBuilder
    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(ColorConstants.Surface.card)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isPressed ? 0.3 : 0.5),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.4),
                        Color.white.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

// MARK: - Card with Header

struct HeaderGlassCard<Header: View, Content: View>: View {
    let header: Header
    let content: Content
    let cornerRadius: CGFloat

    init(
        cornerRadius: CGFloat = AppTheme.cornerRadiusCard,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.header = header()
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(Spacing.cardInsets)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ColorConstants.primaryLight)

            Divider()
                .opacity(0.3)

            content
                .padding(Spacing.cardInsets)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(ColorConstants.Surface.card)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(ColorConstants.Border.standard, lineWidth: 0.5)
        )
        .cardShadow()
    }
}

// MARK: - Expandable Glass Card

struct ExpandableGlassCard<Header: View, Content: View>: View {
    let header: Header
    let content: Content
    let cornerRadius: CGFloat
    @Binding var isExpanded: Bool

    init(
        isExpanded: Binding<Bool>,
        cornerRadius: CGFloat = AppTheme.cornerRadiusCard,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self._isExpanded = isExpanded
        self.cornerRadius = cornerRadius
        self.header = header()
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.premiumSpring) {
                    isExpanded.toggle()
                }
                HapticManager.shared.selection()
            }) {
                HStack {
                    header
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ColorConstants.Text.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(Spacing.cardInsets)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                    .padding(.horizontal, Spacing.md)
                    .opacity(0.3)

                content
                    .padding(Spacing.cardInsets)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(ColorConstants.Surface.card)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(ColorConstants.Border.standard, lineWidth: 0.5)
        )
        .cardShadow()
    }
}

// MARK: - Feature Card (Hero Style)

struct FeatureCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        iconColor: Color = ColorConstants.primary,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                // Icon with background
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 48, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(iconColor.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.headline)
                        .foregroundStyle(ColorConstants.Text.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Typography.subheadline)
                            .foregroundStyle(ColorConstants.Text.secondary)
                    }
                }

                Spacer()
            }

            content
        }
        .padding(Spacing.lg)
        .background(ColorConstants.Surface.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .stroke(ColorConstants.Border.standard, lineWidth: 0.5)
        )
        .cardShadow()
    }
}

// MARK: - Preview

#Preview("Premium Cards") {
    ScrollView {
        VStack(spacing: Spacing.cardGap) {
            GlassMorphicCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Glass Card")
                        .font(Typography.headline)
                        .foregroundStyle(ColorConstants.Text.primary)
                    Text("Premium glassmorphic card with Liquid Glass styling.")
                        .font(Typography.body)
                        .foregroundStyle(ColorConstants.Text.secondary)
                }
            }

            GlassMorphicCard(style: .neomorphic) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Neomorphic Card")
                        .font(Typography.headline)
                        .foregroundStyle(ColorConstants.Text.primary)
                    Text("3D neomorphic style with soft shadows.")
                        .font(Typography.body)
                        .foregroundStyle(ColorConstants.Text.secondary)
                }
            }

            TintedGlassCard(tint: ColorConstants.primary) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tinted Card")
                        .font(Typography.headline)
                        .foregroundStyle(ColorConstants.Text.primary)
                    Text("This card has a blue tint.")
                        .font(Typography.body)
                        .foregroundStyle(ColorConstants.Text.secondary)
                }
            }

            InteractiveGlassCard(action: { print("Tapped") }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Interactive Card")
                            .font(Typography.headline)
                            .foregroundStyle(ColorConstants.Text.primary)
                        Text("Tap me!")
                            .font(Typography.subheadline)
                            .foregroundStyle(ColorConstants.Text.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(ColorConstants.Text.tertiary)
                }
            }

            FeatureCard(
                title: "Premium Feature",
                subtitle: "Unlock all benefits",
                icon: "star.fill",
                iconColor: ColorConstants.primary
            ) {
                Text("Feature content goes here")
                    .font(Typography.body)
                    .foregroundStyle(ColorConstants.Text.secondary)
            }
        }
        .padding()
    }
    .background(ColorConstants.Surface.grouped)
}

// MARK: - Type Aliases

typealias GlassCard = GlassMorphicCard
