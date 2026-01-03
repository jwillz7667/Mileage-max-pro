//
//  GlassButton.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI

/// Glass-styled button with Liquid Glass effect
struct GlassButton: View {
    let title: String
    let icon: String?
    let style: GlassButtonStyle
    let size: GlassButtonSize
    let isLoading: Bool
    let action: () -> Void

    @State private var isPressed = false
    @Environment(\.isEnabled) private var isEnabled

    init(
        _ title: String,
        icon: String? = nil,
        style: GlassButtonStyle = .primary,
        size: GlassButtonSize = .regular,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: {
            guard !isLoading else { return }
            HapticManager.shared.lightImpact()
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(style.foregroundColor)
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .semibold))
                }

                if !title.isEmpty {
                    Text(title)
                        .font(size.font)
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(isEnabled ? style.foregroundColor : style.disabledForegroundColor)
            .frame(height: size.height)
            .frame(maxWidth: size.isFullWidth ? .infinity : nil)
            .padding(.horizontal, size.horizontalPadding)
            .background(buttonBackground)
            .clipShape(Capsule())
            .overlay(buttonBorder)
            .shadow(
                color: style.shadowColor.opacity(isPressed ? 0.1 : 0.2),
                radius: isPressed ? 4 : 8,
                x: 0,
                y: isPressed ? 2 : 4
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isEnabled ? 1 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard isEnabled && !isLoading else { return }
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
    private var buttonBackground: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: [ColorConstants.primary, ColorConstants.primary.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .secondary:
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                )

        case .tertiary:
            Color.clear

        case .destructive:
            LinearGradient(
                colors: [ColorConstants.error, ColorConstants.error.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .success:
            LinearGradient(
                colors: [ColorConstants.success, ColorConstants.success.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .glass:
            Capsule()
                .fill(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private var buttonBorder: some View {
        switch style {
        case .secondary, .glass:
            Capsule()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        case .tertiary:
            Capsule()
                .stroke(ColorConstants.primary.opacity(0.3), lineWidth: 1)
        default:
            EmptyView()
        }
    }
}

// MARK: - Glass Button Style

enum GlassButtonStyle {
    case primary
    case secondary
    case tertiary
    case destructive
    case success
    case glass

    var foregroundColor: Color {
        switch self {
        case .primary, .destructive, .success:
            return .white
        case .secondary, .glass:
            return ColorConstants.Text.primary
        case .tertiary:
            return ColorConstants.primary
        }
    }

    var disabledForegroundColor: Color {
        ColorConstants.Text.tertiary
    }

    var shadowColor: Color {
        switch self {
        case .primary:
            return ColorConstants.primary
        case .destructive:
            return ColorConstants.error
        case .success:
            return ColorConstants.success
        default:
            return Color.black
        }
    }
}

// MARK: - Glass Button Size

enum GlassButtonSize {
    case small
    case regular
    case large
    case fullWidth

    var height: CGFloat {
        switch self {
        case .small: return 36
        case .regular: return 44
        case .large: return 52
        case .fullWidth: return 52
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 16
        case .regular: return 20
        case .large: return 24
        case .fullWidth: return 24
        }
    }

    var font: Font {
        switch self {
        case .small: return Typography.buttonSmall
        case .regular: return Typography.buttonSecondary
        case .large, .fullWidth: return Typography.buttonPrimary
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return 14
        case .regular: return 16
        case .large, .fullWidth: return 18
        }
    }

    var isFullWidth: Bool {
        self == .fullWidth
    }
}

// MARK: - Icon Button

struct GlassIconButton: View {
    let icon: String
    let style: GlassButtonStyle
    let size: CGFloat
    let action: () -> Void

    @State private var isPressed = false
    @Environment(\.isEnabled) private var isEnabled

    init(
        icon: String,
        style: GlassButtonStyle = .secondary,
        size: CGFloat = 44,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(isEnabled ? style.foregroundColor : style.disabledForegroundColor)
                .frame(width: size, height: size)
                .background(buttonBackground)
                .clipShape(Circle())
                .overlay(buttonBorder)
                .shadow(
                    color: style.shadowColor.opacity(isPressed ? 0.1 : 0.15),
                    radius: isPressed ? 2 : 6,
                    x: 0,
                    y: isPressed ? 1 : 3
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .opacity(isEnabled ? 1 : 0.6)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard isEnabled else { return }
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
    private var buttonBackground: some View {
        switch style {
        case .primary:
            ColorConstants.primary
        case .secondary, .glass:
            Circle()
                .fill(.ultraThinMaterial)
        case .tertiary:
            Color.clear
        case .destructive:
            ColorConstants.error
        case .success:
            ColorConstants.success
        }
    }

    @ViewBuilder
    private var buttonBorder: some View {
        switch style {
        case .secondary, .glass, .tertiary:
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        default:
            EmptyView()
        }
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let icon: String
    let label: String?
    let action: () -> Void

    @State private var isPressed = false

    init(icon: String = "plus", label: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.mediumImpact()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))

                if let label = label {
                    Text(label)
                        .font(Typography.buttonSecondary)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, label != nil ? 20 : 0)
            .frame(width: label != nil ? nil : 56, height: 56)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [ColorConstants.primary, ColorConstants.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(
                color: ColorConstants.primary.opacity(0.4),
                radius: isPressed ? 8 : 16,
                x: 0,
                y: isPressed ? 4 : 8
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
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
}

// MARK: - Preview

#Preview("Glass Buttons") {
    VStack(spacing: 24) {
        // Primary buttons
        VStack(spacing: 12) {
            GlassButton("Primary Button", icon: "plus", style: .primary, action: {})
            GlassButton("Full Width", icon: "car.fill", style: .primary, size: .fullWidth, action: {})
            GlassButton("Loading", style: .primary, isLoading: true, action: {})
        }

        // Secondary buttons
        HStack(spacing: 12) {
            GlassButton("Secondary", style: .secondary, action: {})
            GlassButton("Glass", icon: "star.fill", style: .glass, action: {})
        }

        // Other styles
        HStack(spacing: 12) {
            GlassButton("Success", style: .success, size: .small, action: {})
            GlassButton("Destructive", style: .destructive, size: .small, action: {})
            GlassButton("Tertiary", style: .tertiary, size: .small, action: {})
        }

        // Icon buttons
        HStack(spacing: 16) {
            GlassIconButton(icon: "plus", style: .primary, action: {})
            GlassIconButton(icon: "heart.fill", style: .secondary, action: {})
            GlassIconButton(icon: "trash", style: .destructive, size: 36, action: {})
        }

        Spacer()

        // FAB
        HStack {
            Spacer()
            FloatingActionButton(icon: "plus", action: {})
        }
        .padding()
    }
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}

// MARK: - Glass Button Style Modifier

/// A ButtonStyle that applies glass morphic styling to any button
struct GlassButtonStyleModifier: ButtonStyle {
    let style: GlassButtonStyle

    init(_ style: GlassButtonStyle = .primary) {
        self.style = style
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundStyle(style.foregroundColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backgroundView)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                .fill(ColorConstants.primary)
        case .secondary, .glass:
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                .fill(.ultraThinMaterial)
        case .tertiary:
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                .fill(Color.clear)
        case .destructive:
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                .fill(ColorConstants.error)
        case .success:
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                .fill(ColorConstants.success)
        }
    }
}

/// Extension to use with .buttonStyle modifier
extension View {
    func glassButtonStyle(_ style: GlassButtonStyle = .primary) -> some View {
        self.buttonStyle(GlassButtonStyleModifier(style))
    }
}

// MARK: - Glass Button Style Wrapper for .buttonStyle() usage

/// ButtonStyle wrapper that matches `.buttonStyle(GlassButtonStyle())` pattern
/// This allows using GlassButtonStyle as a ButtonStyle conforming type
struct GlassButtonStyleWrapper: ButtonStyle {
    enum Variant {
        case primary
        case secondary
        case destructive
    }

    let variant: Variant

    init(variant: Variant = .primary) {
        self.variant = variant
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.buttonSecondary)
            .fontWeight(.semibold)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary, .destructive:
            return .white
        case .secondary:
            return ColorConstants.Text.primary
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .primary:
            LinearGradient(
                colors: [ColorConstants.primary, ColorConstants.primary.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        case .destructive:
            LinearGradient(
                colors: [ColorConstants.error, ColorConstants.error.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

