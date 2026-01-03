//
//  GlassMorphicCard.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI

/// A glassmorphic card component with Liquid Glass styling
struct GlassMorphicCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    let material: LiquidGlassTheme.GlassMaterial

    @Environment(\.colorScheme) private var colorScheme

    init(
        cornerRadius: CGFloat = AppTheme.cornerRadiusCard,
        padding: EdgeInsets = Spacing.cardInsets,
        material: LiquidGlassTheme.GlassMaterial = .regular,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.material = material
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(cardBorder)
            .shadow(
                color: Color.black.opacity(material.shadowOpacity),
                radius: material.shadowRadius,
                x: 0,
                y: material.shadowRadius / 2
            )
    }

    @ViewBuilder
    private var cardBackground: some View {
        ZStack {
            // Base material
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(material.opacity)

            // Highlight gradient
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.15),
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
                        Color.white.opacity(material.borderOpacity),
                        Color.white.opacity(material.borderOpacity * 0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
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
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tint.opacity(colorScheme == .dark ? 0.15 : 0.1))

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
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
                    .stroke(tint.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: tint.opacity(0.2), radius: 10, x: 0, y: 5)
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
                    color: Color.black.opacity(isPressed ? 0.05 : 0.1),
                    radius: isPressed ? 4 : 10,
                    x: 0,
                    y: isPressed ? 2 : 5
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
        )
    }

    @ViewBuilder
    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.15),
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
                        Color.white.opacity(0.2),
                        Color.white.opacity(0.05)
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
                .background(Color.white.opacity(0.05))

            Divider()
                .opacity(0.2)

            content
                .padding(Spacing.cardInsets)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .liquidGlassStyle(cornerRadius: cornerRadius)
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
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
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
                    .opacity(0.2)

                content
                    .padding(Spacing.cardInsets)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .liquidGlassStyle(cornerRadius: cornerRadius)
    }
}

// MARK: - Preview

#Preview("Glass Cards") {
    ScrollView {
        VStack(spacing: Spacing.cardGap) {
            GlassMorphicCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Glass Card")
                        .font(Typography.headline)
                    Text("This is a glassmorphic card with Liquid Glass styling.")
                        .font(Typography.body)
                        .foregroundStyle(.secondary)
                }
            }

            TintedGlassCard(tint: .blue) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tinted Card")
                        .font(Typography.headline)
                    Text("This card has a blue tint.")
                        .font(Typography.body)
                        .foregroundStyle(.secondary)
                }
            }

            InteractiveGlassCard(action: { print("Tapped") }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Interactive Card")
                            .font(Typography.headline)
                        Text("Tap me!")
                            .font(Typography.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
    }
    .background(Color(uiColor: .systemGroupedBackground))
}

// MARK: - Type Aliases

/// Alias for GlassMorphicCard for backward compatibility
typealias GlassCard = GlassMorphicCard
