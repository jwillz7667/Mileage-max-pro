//
//  GlassButton.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//  Premium Button Components - iOS 26 Design System
//

import SwiftUI

/// Premium Glass-styled button with iOS 26 design
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
            .foregroundStyle(isEnabled ? style.foregroundColor : ColorConstants.Text.disabled)
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
    private var buttonBackground: some View {
        switch style {
        case .primary:
            ColorConstants.primary

        case .secondary:
            ZStack {
                Capsule()
                    .fill(ColorConstants.Surface.card)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.5), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
            }

        case .tertiary:
            Color.clear

        case .destructive:
            ColorConstants.error

        case .success:
            ColorConstants.success

        case .glass:
            ZStack {
                Capsule()
                    .fill(ColorConstants.Surface.card)
                Capsule()
                    .fill(.ultraThinMaterial)
                    .opacity(0.3)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.4), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
            }

        case .outline:
            Color.clear
        }
    }

    @ViewBuilder
    private var buttonBorder: some View {
        switch style {
        case .secondary, .glass:
            Capsule()
                .stroke(ColorConstants.Border.standard, lineWidth: 1)
        case .tertiary:
            Capsule()
                .stroke(ColorConstants.primary.opacity(0.3), lineWidth: 1.5)
        case .outline:
            Capsule()
                .stroke(ColorConstants.primary, lineWidth: 1.5)
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
    case outline

    var foregroundColor: Color {
        switch self {
        case .primary, .destructive, .success:
            return .white
        case .secondary, .glass:
            return ColorConstants.Text.primary
        case .tertiary, .outline:
            return ColorConstants.primary
        }
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
            return Color.black.opacity(0.5)
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
        case .small: return 40
        case .regular: return 48
        case .large: return 56
        case .fullWidth: return 56
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 16
        case .regular: return 24
        case .large: return 28
        case .fullWidth: return 28
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
        size: CGFloat = 48,
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
                .foregroundStyle(isEnabled ? style.foregroundColor : ColorConstants.Text.disabled)
                .frame(width: size, height: size)
                .background(buttonBackground)
                .clipShape(Circle())
                .overlay(buttonBorder)
                .shadow(
                    color: style.shadowColor.opacity(isPressed ? 0.08 : 0.12),
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
    private var buttonBackground: some View {
        switch style {
        case .primary:
            ColorConstants.primary
        case .secondary, .glass:
            ZStack {
                Circle()
                    .fill(ColorConstants.Surface.card)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.4), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
            }
        case .tertiary, .outline:
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
        case .secondary, .glass:
            Circle()
                .stroke(ColorConstants.Border.standard, lineWidth: 1)
        case .tertiary, .outline:
            Circle()
                .stroke(ColorConstants.primary.opacity(0.3), lineWidth: 1)
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
                    .font(.system(size: 22, weight: .semibold))

                if let label = label {
                    Text(label)
                        .font(Typography.buttonPrimary)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, label != nil ? 24 : 0)
            .frame(width: label != nil ? nil : 60, height: 60)
            .background(
                Capsule()
                    .fill(ColorConstants.primary)
            )
            .overlay(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.25), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
            )
            .shadow(
                color: ColorConstants.primary.opacity(isPressed ? 0.2 : 0.4),
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
}

// MARK: - Segmented Control Button

struct SegmentedButton: View {
    let segments: [String]
    @Binding var selectedIndex: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                Button {
                    withAnimation(.premiumSpring) {
                        selectedIndex = index
                    }
                    HapticManager.shared.selection()
                } label: {
                    Text(segment)
                        .font(Typography.buttonSmall)
                        .foregroundStyle(selectedIndex == index ? .white : ColorConstants.Text.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            selectedIndex == index
                                ? Capsule().fill(ColorConstants.primary)
                                : Capsule().fill(Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(ColorConstants.Surface.grouped)
        )
        .overlay(
            Capsule()
                .stroke(ColorConstants.Border.standard, lineWidth: 0.5)
        )
    }
}

// MARK: - Preview

#Preview("Premium Buttons") {
    ScrollView {
        VStack(spacing: 24) {
            // Primary buttons
            VStack(spacing: 12) {
                Text("Primary Buttons")
                    .font(Typography.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                GlassButton("Start Trip", icon: "car.fill", style: .primary, size: .fullWidth, action: {})
                GlassButton("Loading", style: .primary, isLoading: true, action: {})

                HStack(spacing: 12) {
                    GlassButton("Regular", style: .primary, action: {})
                    GlassButton("Small", style: .primary, size: .small, action: {})
                }
            }

            Divider()

            // Secondary buttons
            VStack(spacing: 12) {
                Text("Secondary Buttons")
                    .font(Typography.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    GlassButton("Secondary", style: .secondary, action: {})
                    GlassButton("Glass", icon: "star.fill", style: .glass, action: {})
                }

                HStack(spacing: 12) {
                    GlassButton("Tertiary", style: .tertiary, action: {})
                    GlassButton("Outline", style: .outline, action: {})
                }
            }

            Divider()

            // Semantic buttons
            VStack(spacing: 12) {
                Text("Semantic Buttons")
                    .font(Typography.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    GlassButton("Success", icon: "checkmark", style: .success, size: .small, action: {})
                    GlassButton("Destructive", icon: "trash", style: .destructive, size: .small, action: {})
                }
            }

            Divider()

            // Icon buttons
            VStack(spacing: 12) {
                Text("Icon Buttons")
                    .font(Typography.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 16) {
                    GlassIconButton(icon: "plus", style: .primary, action: {})
                    GlassIconButton(icon: "heart.fill", style: .secondary, action: {})
                    GlassIconButton(icon: "bell.fill", style: .glass, action: {})
                    GlassIconButton(icon: "trash", style: .destructive, size: 40, action: {})
                }
            }

            Divider()

            // Segmented control
            VStack(spacing: 12) {
                Text("Segmented Control")
                    .font(Typography.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                SegmentedButton(
                    segments: ["Day", "Week", "Month"],
                    selectedIndex: .constant(1)
                )
            }

            Spacer()

            // FAB
            HStack {
                Spacer()
                FloatingActionButton(icon: "plus", action: {})
            }
        }
        .padding()
    }
    .background(ColorConstants.Surface.grouped)
}

// MARK: - Glass Button Style Modifier

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
            .padding(.vertical, 14)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.quickResponse, value: configuration.isPressed)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            ColorConstants.primary
        case .secondary, .glass:
            ColorConstants.Surface.card
        case .tertiary, .outline:
            Color.clear
        case .destructive:
            ColorConstants.error
        case .success:
            ColorConstants.success
        }
    }
}

extension View {
    func glassButtonStyle(_ style: GlassButtonStyle = .primary) -> some View {
        self.buttonStyle(GlassButtonStyleModifier(style))
    }
}

// MARK: - Button Style Wrapper

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
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous))
            .overlay(borderView)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.quickResponse, value: configuration.isPressed)
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
            ColorConstants.primary
        case .secondary:
            ColorConstants.Surface.card
        case .destructive:
            ColorConstants.error
        }
    }

    @ViewBuilder
    private var borderView: some View {
        switch variant {
        case .secondary:
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                .stroke(ColorConstants.Border.standard, lineWidth: 1)
        default:
            EmptyView()
        }
    }
}
