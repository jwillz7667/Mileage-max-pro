//
//  GlassListRow.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//  Premium List Components - iOS 26 Liquid Glass
//

import SwiftUI

/// Premium glass-styled list row with Liquid Glass effect
struct GlassListRow<LeadingContent: View, TrailingContent: View>: View {
    let title: String
    let subtitle: String?
    let leadingContent: LeadingContent
    let trailingContent: TrailingContent
    let showChevron: Bool
    let action: (() -> Void)?

    @State private var isPressed = false

    init(
        title: String,
        subtitle: String? = nil,
        showChevron: Bool = true,
        action: (() -> Void)? = nil,
        @ViewBuilder leading: () -> LeadingContent = { EmptyView() },
        @ViewBuilder trailing: () -> TrailingContent = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.action = action
        self.leadingContent = leading()
        self.trailingContent = trailing()
    }

    var body: some View {
        Button {
            HapticManager.shared.lightImpact()
            action?()
        } label: {
            HStack(spacing: Spacing.md) {
                leadingContent

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.body)
                        .foregroundStyle(ColorConstants.Text.primary)
                        .lineLimit(1)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Typography.caption1)
                            .foregroundStyle(ColorConstants.Text.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                trailingContent

                if showChevron && action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(ColorConstants.Text.quaternary)
                }
            }
            .padding(Spacing.cardInsets)
            .background(
                ZStack {
                    // Base card background
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusCard, style: .continuous)
                        .fill(ColorConstants.Surface.card)

                    // Pressed state overlay
                    if isPressed {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusCard, style: .continuous)
                            .fill(ColorConstants.primary.opacity(0.05))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusCard, style: .continuous)
                    .stroke(ColorConstants.Border.standard, lineWidth: 0.5)
            )
            .shadow(
                color: ColorConstants.Neomorphic.darkShadow,
                radius: isPressed ? 2 : 4,
                x: 0,
                y: isPressed ? 1 : 2
            )
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard action != nil else { return }
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

// MARK: - Premium Icon Leading View

struct IconLeadingView: View {
    let icon: String
    let color: Color
    let size: CGFloat
    let style: IconStyle

    enum IconStyle {
        case filled
        case gradient
        case outline
        case neomorphic
    }

    init(
        icon: String,
        color: Color = ColorConstants.primary,
        size: CGFloat = 40,
        style: IconStyle = .filled
    ) {
        self.icon = icon
        self.color = color
        self.size = size
        self.style = style
    }

    var body: some View {
        ZStack {
            switch style {
            case .filled:
                RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: size, height: size)

                Image(systemName: icon)
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundStyle(color)

            case .gradient:
                RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                    .fill(color.gradient)
                    .frame(width: size, height: size)

                Image(systemName: icon)
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundStyle(.white)

            case .outline:
                RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                    .stroke(color.opacity(0.3), lineWidth: 1.5)
                    .frame(width: size, height: size)

                Image(systemName: icon)
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundStyle(color)

            case .neomorphic:
                RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                    .fill(ColorConstants.Surface.card)
                    .frame(width: size, height: size)
                    .shadow(color: ColorConstants.Neomorphic.lightShadow, radius: 2, x: -1, y: -1)
                    .shadow(color: ColorConstants.Neomorphic.darkShadow, radius: 2, x: 1, y: 1)

                Image(systemName: icon)
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundStyle(color)
            }
        }
    }
}

// MARK: - Premium Trip List Row

struct TripListRow: View {
    let startLocation: String
    let endLocation: String
    let distance: String
    let date: String
    let category: TripCategory
    let action: () -> Void

    var body: some View {
        GlassListRow(
            title: "\(startLocation) → \(endLocation)",
            subtitle: "\(date) • \(distance)",
            action: action,
            leading: {
                IconLeadingView(
                    icon: category.icon,
                    color: category.color,
                    size: 44,
                    style: .filled
                )
            },
            trailing: {
                PremiumCategoryBadge(category: category)
            }
        )
    }
}

// MARK: - Trip Category Badge (Premium)

struct PremiumCategoryBadge: View {
    let category: TripCategory

    var body: some View {
        Text(category.rawValue)
            .font(Typography.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(category.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(category.color.opacity(0.12))
            )
    }
}

// MARK: - Premium Vehicle List Row

struct VehicleListRow: View {
    let name: String
    let details: String
    let odometer: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        GlassListRow(
            title: name,
            subtitle: details,
            action: action,
            leading: {
                IconLeadingView(
                    icon: "car.fill",
                    color: isActive ? ColorConstants.primary : ColorConstants.Text.tertiary,
                    size: 44,
                    style: isActive ? .gradient : .filled
                )
            },
            trailing: {
                VStack(alignment: .trailing, spacing: 3) {
                    Text(odometer)
                        .font(Typography.subheadlineBold)
                        .foregroundStyle(ColorConstants.Text.primary)
                        .monospacedDigit()

                    if isActive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(ColorConstants.success)
                                .frame(width: 6, height: 6)
                            Text("Active")
                                .font(Typography.caption2)
                                .foregroundStyle(ColorConstants.success)
                        }
                    }
                }
            }
        )
    }
}

// MARK: - Premium Expense List Row

struct ExpenseListRow: View {
    let title: String
    let category: String
    let amount: String
    let date: String
    let icon: String
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        GlassListRow(
            title: title,
            subtitle: "\(category) • \(date)",
            action: action,
            leading: {
                IconLeadingView(icon: icon, color: iconColor, size: 44, style: .filled)
            },
            trailing: {
                Text(amount)
                    .font(Typography.headline)
                    .foregroundStyle(ColorConstants.Text.primary)
                    .monospacedDigit()
            }
        )
    }
}

// MARK: - Premium Settings Row

struct SettingsRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    let value: String?
    let showChevron: Bool
    let action: (() -> Void)?

    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        iconColor: Color = ColorConstants.primary,
        value: String? = nil,
        showChevron: Bool = true,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.value = value
        self.showChevron = showChevron
        self.action = action
    }

    var body: some View {
        GlassListRow(
            title: title,
            subtitle: subtitle,
            showChevron: showChevron,
            action: action,
            leading: {
                IconLeadingView(
                    icon: icon,
                    color: iconColor,
                    size: 36,
                    style: .gradient
                )
            },
            trailing: {
                if let value = value {
                    Text(value)
                        .font(Typography.body)
                        .foregroundStyle(ColorConstants.Text.secondary)
                }
            }
        )
    }
}

// MARK: - Premium Settings Toggle Row

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool

    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        iconColor: Color = ColorConstants.primary,
        isOn: Binding<Bool>
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self._isOn = isOn
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            IconLeadingView(
                icon: icon,
                color: iconColor,
                size: 36,
                style: .gradient
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.body)
                    .foregroundStyle(ColorConstants.Text.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Typography.caption1)
                        .foregroundStyle(ColorConstants.Text.secondary)
                }
            }

            Spacer()

            GlassToggleSwitch(isOn: $isOn)
        }
        .padding(Spacing.cardInsets)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusCard, style: .continuous)
                .fill(ColorConstants.Surface.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusCard, style: .continuous)
                .stroke(ColorConstants.Border.standard, lineWidth: 0.5)
        )
        .shadow(
            color: ColorConstants.Neomorphic.darkShadow,
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

// MARK: - Premium Section Header

struct GlassSectionHeader: View {
    let title: String
    let action: (() -> Void)?
    let actionTitle: String?

    init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack {
            Text(title)
                .font(Typography.subheadlineBold)
                .foregroundStyle(ColorConstants.Text.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Spacer()

            if let actionTitle = actionTitle, let action = action {
                Button {
                    HapticManager.shared.lightImpact()
                    action()
                } label: {
                    HStack(spacing: 4) {
                        Text(actionTitle)
                            .font(Typography.subheadlineBold)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(ColorConstants.primary)
                }
            }
        }
        .padding(.horizontal, Spacing.xs)
    }
}

// MARK: - Grouped List Container

struct GlassListSection<Content: View>: View {
    let header: String?
    let footer: String?
    let content: Content

    init(
        header: String? = nil,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let header = header {
                GlassSectionHeader(header)
            }

            VStack(spacing: Spacing.sm) {
                content
            }

            if let footer = footer {
                Text(footer)
                    .font(Typography.caption1)
                    .foregroundStyle(ColorConstants.Text.tertiary)
                    .padding(.horizontal, Spacing.xs)
            }
        }
    }
}

// MARK: - Inline List Row (No Card Background)

struct InlineListRow: View {
    let title: String
    let value: String?
    let icon: String?
    let iconColor: Color
    let action: (() -> Void)?

    init(
        title: String,
        value: String? = nil,
        icon: String? = nil,
        iconColor: Color = ColorConstants.primary,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.iconColor = iconColor
        self.action = action
    }

    var body: some View {
        Button {
            HapticManager.shared.lightImpact()
            action?()
        } label: {
            HStack(spacing: Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(iconColor)
                        .frame(width: 24)
                }

                Text(title)
                    .font(Typography.body)
                    .foregroundStyle(ColorConstants.Text.primary)

                Spacer()

                if let value = value {
                    Text(value)
                        .font(Typography.body)
                        .foregroundStyle(ColorConstants.Text.secondary)
                }

                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(ColorConstants.Text.quaternary)
                }
            }
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

// MARK: - Preview

#Preview("Premium Glass List Rows") {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            // Section: Trips
            GlassListSection(header: "Recent Trips") {
                TripListRow(
                    startLocation: "Home",
                    endLocation: "Office",
                    distance: "12.5 mi",
                    date: "Today, 8:30 AM",
                    category: .business,
                    action: {}
                )

                TripListRow(
                    startLocation: "Office",
                    endLocation: "Client Meeting",
                    distance: "8.2 mi",
                    date: "Today, 2:15 PM",
                    category: .business,
                    action: {}
                )
            }

            // Section: Vehicles
            GlassListSection(header: "My Vehicles") {
                VehicleListRow(
                    name: "Tesla Model 3",
                    details: "2023 • Electric",
                    odometer: "12,345 mi",
                    isActive: true,
                    action: {}
                )

                VehicleListRow(
                    name: "Honda Civic",
                    details: "2020 • Gasoline",
                    odometer: "45,678 mi",
                    isActive: false,
                    action: {}
                )
            }

            // Section: Expenses
            GlassListSection(header: "Recent Expenses") {
                ExpenseListRow(
                    title: "Shell Gas Station",
                    category: "Fuel",
                    amount: "$45.23",
                    date: "Dec 15",
                    icon: "fuelpump.fill",
                    iconColor: ColorConstants.warning,
                    action: {}
                )
            }

            // Section: Settings
            GlassListSection(header: "Settings", footer: "Configure your tracking preferences") {
                SettingsRow(
                    title: "Auto-Tracking",
                    subtitle: "Detect trips automatically",
                    icon: "location.fill",
                    iconColor: ColorConstants.primary,
                    value: "On",
                    action: {}
                )

                SettingsToggleRow(
                    title: "Dark Mode",
                    subtitle: "Use dark theme",
                    icon: "moon.fill",
                    iconColor: .purple,
                    isOn: .constant(true)
                )
            }
        }
        .padding()
    }
    .background(ColorConstants.Surface.grouped)
}
