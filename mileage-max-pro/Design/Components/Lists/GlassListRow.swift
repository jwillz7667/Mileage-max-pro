//
//  GlassListRow.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI

/// Glass-styled list row with Liquid Glass effect
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
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ColorConstants.Text.tertiary)
                }
            }
            .padding(Spacing.cardInsets)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusCard, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(isPressed ? 0.8 : 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusCard, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard action != nil else { return }
                    withAnimation(.easeOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Icon Leading View

struct IconLeadingView: View {
    let icon: String
    let color: Color
    let size: CGFloat

    init(icon: String, color: Color = ColorConstants.primary, size: CGFloat = 36) {
        self.icon = icon
        self.color = color
        self.size = size
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)

            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Trip List Row

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
                    color: category.color
                )
            },
            trailing: {
                Text(category.rawValue)
                    .font(Typography.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(category.color.opacity(0.15))
                    )
            }
        )
    }
}

// MARK: - Vehicle List Row

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
                    color: isActive ? ColorConstants.primary : ColorConstants.Text.tertiary
                )
            },
            trailing: {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(odometer)
                        .font(Typography.caption1)
                        .fontWeight(.medium)
                        .foregroundStyle(ColorConstants.Text.primary)
                        .monospacedDigit()

                    if isActive {
                        Text("Active")
                            .font(Typography.caption2)
                            .foregroundStyle(ColorConstants.success)
                    }
                }
            }
        )
    }
}

// MARK: - Expense List Row

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
                IconLeadingView(icon: icon, color: iconColor)
            },
            trailing: {
                Text(amount)
                    .font(Typography.bodyBold)
                    .foregroundStyle(ColorConstants.Text.primary)
                    .monospacedDigit()
            }
        )
    }
}

// MARK: - Settings Row

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
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor.gradient)
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
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

// MARK: - Settings Toggle Row

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
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.gradient)
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }

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
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusCard, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Section Header

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

            Spacer()

            if let actionTitle = actionTitle, let action = action {
                Button {
                    action()
                } label: {
                    Text(actionTitle)
                        .font(Typography.subheadline)
                        .foregroundStyle(ColorConstants.primary)
                }
            }
        }
        .padding(.horizontal, Spacing.xs)
    }
}

// MARK: - Preview

#Preview("Glass List Rows") {
    ScrollView {
        VStack(spacing: Spacing.md) {
            // Section: Trips
            GlassSectionHeader("Recent Trips", actionTitle: "See All") {}

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

            // Section: Vehicles
            GlassSectionHeader("My Vehicles")
                .padding(.top, Spacing.md)

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

            // Section: Expenses
            GlassSectionHeader("Recent Expenses")
                .padding(.top, Spacing.md)

            ExpenseListRow(
                title: "Shell Gas Station",
                category: "Fuel",
                amount: "$45.23",
                date: "Dec 15",
                icon: "fuelpump.fill",
                iconColor: .orange,
                action: {}
            )

            // Section: Settings
            GlassSectionHeader("Settings")
                .padding(.top, Spacing.md)

            SettingsRow(
                title: "Auto-Tracking",
                subtitle: "Detect trips automatically",
                icon: "location.fill",
                iconColor: .blue,
                value: "On",
                action: {}
            )

            SettingsToggleRow(
                title: "Dark Mode",
                icon: "moon.fill",
                iconColor: .purple,
                isOn: .constant(true)
            )
        }
        .padding()
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
