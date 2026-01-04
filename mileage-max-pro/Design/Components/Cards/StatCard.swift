//
//  StatCard.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//  Premium Stat Display Components
//

import SwiftUI

/// Premium stat display card with neomorphic styling
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String?
    let iconColor: Color
    let trend: StatTrend?
    let size: StatCardSize

    @Environment(\.colorScheme) private var colorScheme

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String? = nil,
        iconColor: Color = ColorConstants.primary,
        trend: StatTrend? = nil,
        size: StatCardSize = .regular
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.trend = trend
        self.size = size
    }

    var body: some View {
        VStack(alignment: .leading, spacing: size.spacing) {
            // Header with icon and trend
            HStack {
                // Icon with background
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .semibold))
                        .foregroundStyle(iconColor)
                        .frame(width: size.iconSize + 12, height: size.iconSize + 12)
                        .background(
                            RoundedRectangle(cornerRadius: size.iconSize / 2.5, style: .continuous)
                                .fill(iconColor.opacity(0.1))
                        )
                }

                Spacer()

                // Trend indicator
                if let trend = trend {
                    TrendBadge(trend: trend)
                }
            }

            Spacer(minLength: 0)

            // Value
            Text(value)
                .font(size.valueFont)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .foregroundStyle(ColorConstants.Text.primary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(size.titleFont)
                    .foregroundStyle(ColorConstants.Text.secondary)
                    .lineLimit(1)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(size.subtitleFont)
                        .foregroundStyle(ColorConstants.Text.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(size.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: size.height)
        .background(ColorConstants.Surface.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusCard, style: .continuous)
                .stroke(ColorConstants.Border.standard, lineWidth: 0.5)
        )
        .cardShadow()
    }
}

// MARK: - Hero Stat Card (Large Feature Card)

struct HeroStatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    let trend: StatTrend?

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        iconColor: Color = ColorConstants.primary,
        trend: StatTrend? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.trend = trend
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                // Icon with gradient background
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(iconColor)
                    )
                    .shadow(color: iconColor.opacity(0.3), radius: 8, x: 0, y: 4)

                Spacer()

                if let trend = trend {
                    TrendBadge(trend: trend, size: .large)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(Typography.statLarge)
                    .foregroundStyle(ColorConstants.Text.primary)
                    .monospacedDigit()

                Text(title)
                    .font(Typography.headline)
                    .foregroundStyle(ColorConstants.Text.secondary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Typography.subheadline)
                        .foregroundStyle(ColorConstants.Text.tertiary)
                }
            }
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

// MARK: - Stat Card Size

enum StatCardSize {
    case compact
    case regular
    case large

    var height: CGFloat {
        switch self {
        case .compact: return 100
        case .regular: return 130
        case .large: return 160
        }
    }

    var padding: EdgeInsets {
        switch self {
        case .compact:
            return EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        case .regular:
            return EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)
        case .large:
            return EdgeInsets(top: 22, leading: 22, bottom: 22, trailing: 22)
        }
    }

    var spacing: CGFloat {
        switch self {
        case .compact: return 6
        case .regular: return 8
        case .large: return 10
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .compact: return 16
        case .regular: return 20
        case .large: return 24
        }
    }

    var valueFont: Font {
        switch self {
        case .compact: return Typography.statSmall
        case .regular: return Typography.statMedium
        case .large: return Typography.statLarge
        }
    }

    var titleFont: Font {
        switch self {
        case .compact: return Typography.caption1
        case .regular: return Typography.subheadline
        case .large: return Typography.body
        }
    }

    var subtitleFont: Font {
        switch self {
        case .compact: return Typography.caption2
        case .regular: return Typography.caption1
        case .large: return Typography.subheadline
        }
    }
}

// MARK: - Stat Trend

enum StatTrend {
    case up(String)
    case down(String)
    case neutral(String)

    var isPositive: Bool {
        if case .up = self { return true }
        return false
    }

    var isNegative: Bool {
        if case .down = self { return true }
        return false
    }

    var value: String {
        switch self {
        case .up(let v), .down(let v), .neutral(let v):
            return v
        }
    }

    var color: Color {
        switch self {
        case .up: return ColorConstants.success
        case .down: return ColorConstants.error
        case .neutral: return ColorConstants.Text.tertiary
        }
    }

    var icon: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .neutral: return "minus"
        }
    }
}

// MARK: - Trend Badge

struct TrendBadge: View {
    let trend: StatTrend
    let size: TrendBadgeSize

    init(trend: StatTrend, size: TrendBadgeSize = .regular) {
        self.trend = trend
        self.size = size
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: trend.icon)
                .font(.system(size: size.iconSize, weight: .bold))

            Text(trend.value)
                .font(.system(size: size.fontSize, weight: .semibold))
                .monospacedDigit()
        }
        .foregroundStyle(trend.color)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(
            Capsule()
                .fill(trend.color.opacity(0.1))
        )
    }

    enum TrendBadgeSize {
        case small
        case regular
        case large

        var iconSize: CGFloat {
            switch self {
            case .small: return 8
            case .regular: return 9
            case .large: return 11
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 10
            case .regular: return 11
            case .large: return 13
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 6
            case .regular: return 8
            case .large: return 10
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small: return 3
            case .regular: return 4
            case .large: return 6
            }
        }
    }
}

// MARK: - Quick Stat Row

struct QuickStatRow: View {
    let label: String
    let value: String
    let icon: String?
    let iconColor: Color

    init(
        label: String,
        value: String,
        icon: String? = nil,
        iconColor: Color = ColorConstants.primary
    ) {
        self.label = label
        self.value = value
        self.icon = icon
        self.iconColor = iconColor
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(iconColor.opacity(0.1))
                    )
            }

            Text(label)
                .font(Typography.subheadline)
                .foregroundStyle(ColorConstants.Text.secondary)

            Spacer()

            Text(value)
                .font(Typography.subheadlineBold)
                .foregroundStyle(ColorConstants.Text.primary)
                .monospacedDigit()
        }
    }
}

// MARK: - Stat Row Card

struct StatRowCard: View {
    let stats: [(label: String, value: String, icon: String?, color: Color)]

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
                if index > 0 {
                    Divider()
                        .padding(.leading, 36)
                }

                QuickStatRow(
                    label: stat.label,
                    value: stat.value,
                    icon: stat.icon,
                    iconColor: stat.color
                )
            }
        }
        .padding(Spacing.md)
        .background(ColorConstants.Surface.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusCard, style: .continuous)
                .stroke(ColorConstants.Border.standard, lineWidth: 0.5)
        )
        .cardShadow()
    }
}

// MARK: - Mini Stat Pill

struct MiniStatPill: View {
    let label: String
    let value: String
    let icon: String?
    let color: Color

    init(
        label: String,
        value: String,
        icon: String? = nil,
        color: Color = ColorConstants.primary
    ) {
        self.label = label
        self.value = value
        self.icon = icon
        self.color = color
    }

    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
            }

            Text(value)
                .font(Typography.caption1Bold)
                .foregroundStyle(ColorConstants.Text.primary)
                .monospacedDigit()

            Text(label)
                .font(Typography.caption2)
                .foregroundStyle(ColorConstants.Text.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(ColorConstants.Surface.card)
        )
        .overlay(
            Capsule()
                .stroke(ColorConstants.Border.standard, lineWidth: 0.5)
        )
    }
}

// MARK: - Preview

#Preview("Premium Stat Cards") {
    ScrollView {
        VStack(spacing: Spacing.md) {
            // Hero stat
            HeroStatCard(
                title: "Total Mileage",
                value: "2,847.5",
                subtitle: "This Month",
                icon: "car.fill",
                iconColor: ColorConstants.primary,
                trend: .up("+12.5%")
            )

            // Grid of stat cards
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.cardGap),
                GridItem(.flexible(), spacing: Spacing.cardGap)
            ], spacing: Spacing.cardGap) {
                StatCard(
                    title: "Business",
                    value: "1,234.5",
                    subtitle: "43% of total",
                    icon: "briefcase.fill",
                    iconColor: ColorConstants.primary,
                    trend: .up("+8%")
                )

                StatCard(
                    title: "Personal",
                    value: "613.0",
                    subtitle: "22% of total",
                    icon: "car.fill",
                    iconColor: ColorConstants.secondary,
                    trend: .down("-3%")
                )

                StatCard(
                    title: "Trips",
                    value: "48",
                    subtitle: "12 today",
                    icon: "location.fill",
                    iconColor: ColorConstants.success,
                    trend: .neutral("—"),
                    size: .compact
                )

                StatCard(
                    title: "Savings",
                    value: "$864",
                    icon: "dollarsign.circle.fill",
                    iconColor: ColorConstants.warning,
                    trend: .up("+$102"),
                    size: .compact
                )
            }

            // Stat row card
            StatRowCard(stats: [
                ("Average MPG", "28.5", "gauge.with.needle.fill", ColorConstants.primary),
                ("Total Fuel", "45.2 gal", "fuelpump.fill", ColorConstants.warning),
                ("CO2 Saved", "12.3 kg", "leaf.fill", ColorConstants.success)
            ])

            // Mini stat pills
            HStack(spacing: Spacing.sm) {
                MiniStatPill(label: "mi", value: "1,234", icon: "road.lanes", color: ColorConstants.primary)
                MiniStatPill(label: "trips", value: "48", icon: "car.fill", color: ColorConstants.success)
                MiniStatPill(label: "saved", value: "$864", icon: "dollarsign.circle", color: ColorConstants.warning)
            }
        }
        .padding()
    }
    .background(ColorConstants.Surface.grouped)
}
