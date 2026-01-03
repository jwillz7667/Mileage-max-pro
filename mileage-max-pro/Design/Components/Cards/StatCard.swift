//
//  StatCard.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI

/// A stat display card for dashboard metrics
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
        GlassMorphicCard(
            padding: size.padding,
            material: .regular
        ) {
            VStack(alignment: .leading, spacing: size.spacing) {
                // Header with icon and trend
                HStack {
                    // Icon
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: size.iconSize, weight: .semibold))
                            .foregroundStyle(iconColor)
                            .frame(width: size.iconSize + 4, height: size.iconSize + 4)
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: size.height)
        }
    }
}

// MARK: - Stat Card Size

enum StatCardSize {
    case compact
    case regular
    case large

    var height: CGFloat {
        switch self {
        case .compact: return 90
        case .regular: return 120
        case .large: return 150
        }
    }

    var padding: EdgeInsets {
        switch self {
        case .compact:
            return EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        case .regular:
            return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        case .large:
            return EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        }
    }

    var spacing: CGFloat {
        switch self {
        case .compact: return 4
        case .regular: return 6
        case .large: return 8
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
        case .compact: return .system(size: 22, weight: .bold, design: .rounded)
        case .regular: return .system(size: 28, weight: .bold, design: .rounded)
        case .large: return .system(size: 36, weight: .bold, design: .rounded)
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

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: trend.icon)
                .font(.system(size: 9, weight: .bold))

            Text(trend.value)
                .font(.system(size: 11, weight: .semibold))
                .monospacedDigit()
        }
        .foregroundStyle(trend.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(trend.color.opacity(0.15))
        )
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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(iconColor)
                    .frame(width: 20)
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
        GlassMorphicCard {
            VStack(spacing: Spacing.sm) {
                ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
                    if index > 0 {
                        Divider().opacity(0.2)
                    }

                    QuickStatRow(
                        label: stat.label,
                        value: stat.value,
                        icon: stat.icon,
                        iconColor: stat.color
                    )
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Stat Cards") {
    ScrollView {
        VStack(spacing: Spacing.md) {
            // Grid of stat cards
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.cardGap),
                GridItem(.flexible(), spacing: Spacing.cardGap)
            ], spacing: Spacing.cardGap) {
                StatCard(
                    title: "Total Miles",
                    value: "1,234.5",
                    subtitle: "This month",
                    icon: "car.fill",
                    iconColor: .blue,
                    trend: .up("+12%")
                )

                StatCard(
                    title: "Business",
                    value: "987.3",
                    subtitle: "80% of total",
                    icon: "briefcase.fill",
                    iconColor: .green,
                    trend: .up("+5%")
                )

                StatCard(
                    title: "Trips",
                    value: "48",
                    subtitle: "12 today",
                    icon: "location.fill",
                    iconColor: .orange,
                    trend: .down("-3%"),
                    size: .compact
                )

                StatCard(
                    title: "Fuel Cost",
                    value: "$234",
                    icon: "fuelpump.fill",
                    iconColor: .red,
                    trend: .neutral("—"),
                    size: .compact
                )
            }

            // Large stat card
            StatCard(
                title: "Estimated Tax Deduction",
                value: "$864.42",
                subtitle: "Based on IRS rate of $0.70/mile",
                icon: "dollarsign.circle.fill",
                iconColor: .green,
                trend: .up("+$102"),
                size: .large
            )

            // Stat row card
            StatRowCard(stats: [
                ("Average MPG", "28.5", "gauge.with.needle.fill", .blue),
                ("Total Fuel", "45.2 gal", "fuelpump.fill", .orange),
                ("CO2 Saved", "12.3 kg", "leaf.fill", .green)
            ])
        }
        .padding()
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
