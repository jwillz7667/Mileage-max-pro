//
//  GlassPicker.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI

/// Glass-styled picker with Liquid Glass effect
struct GlassPicker<T: Hashable & CustomStringConvertible>: View {
    let title: String
    @Binding var selection: T
    let options: [T]
    let icon: String?

    @State private var isExpanded = false

    init(
        _ title: String,
        selection: Binding<T>,
        options: [T],
        icon: String? = nil
    ) {
        self.title = title
        self._selection = selection
        self.options = options
        self.icon = icon
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if !title.isEmpty {
                Text(title)
                    .font(Typography.caption1)
                    .fontWeight(.medium)
                    .foregroundStyle(ColorConstants.Text.secondary)
            }

            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        HapticManager.shared.lightImpact()
                        selection = option
                    } label: {
                        HStack {
                            Text(option.description)
                            if selection == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(ColorConstants.primary)
                            .frame(width: 24)
                    }

                    Text(selection.description)
                        .font(Typography.body)
                        .foregroundStyle(ColorConstants.Text.primary)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(ColorConstants.Text.tertiary)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm + 2)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Glass Date Picker

struct GlassDatePicker: View {
    let title: String
    @Binding var date: Date
    let displayedComponents: DatePicker.Components
    let range: ClosedRange<Date>?

    init(
        _ title: String,
        date: Binding<Date>,
        displayedComponents: DatePicker.Components = [.date],
        range: ClosedRange<Date>? = nil
    ) {
        self.title = title
        self._date = date
        self.displayedComponents = displayedComponents
        self.range = range
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if !title.isEmpty {
                Text(title)
                    .font(Typography.caption1)
                    .fontWeight(.medium)
                    .foregroundStyle(ColorConstants.Text.secondary)
            }

            HStack {
                Image(systemName: displayedComponents.contains(.hourAndMinute) ? "clock.fill" : "calendar")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(ColorConstants.primary)
                    .frame(width: 24)

                if let range = range {
                    DatePicker("", selection: $date, in: range, displayedComponents: displayedComponents)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                } else {
                    DatePicker("", selection: $date, displayedComponents: displayedComponents)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Glass Date Range Picker

struct GlassDateRangePicker: View {
    let title: String
    @Binding var startDate: Date
    @Binding var endDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if !title.isEmpty {
                Text(title)
                    .font(Typography.caption1)
                    .fontWeight(.medium)
                    .foregroundStyle(ColorConstants.Text.secondary)
            }

            HStack(spacing: Spacing.md) {
                // Start date
                VStack(alignment: .leading, spacing: 4) {
                    Text("From")
                        .font(Typography.caption2)
                        .foregroundStyle(ColorConstants.Text.tertiary)

                    DatePicker("", selection: $startDate, in: ...endDate, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }

                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ColorConstants.Text.tertiary)

                // End date
                VStack(alignment: .leading, spacing: 4) {
                    Text("To")
                        .font(Typography.caption2)
                        .foregroundStyle(ColorConstants.Text.tertiary)

                    DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Glass Stepper

struct GlassStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let formatter: ((Int) -> String)?

    init(
        _ title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int = 1,
        formatter: ((Int) -> String)? = nil
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.formatter = formatter
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.body)
                    .foregroundStyle(ColorConstants.Text.primary)

                Text(formatter?(value) ?? "\(value)")
                    .font(Typography.caption1)
                    .foregroundStyle(ColorConstants.Text.secondary)
                    .monospacedDigit()
            }

            Spacer()

            HStack(spacing: 0) {
                // Decrement
                Button {
                    HapticManager.shared.lightImpact()
                    if value - step >= range.lowerBound {
                        value -= step
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(value > range.lowerBound ? ColorConstants.Text.primary : ColorConstants.Text.tertiary)
                        .frame(width: 36, height: 36)
                }
                .disabled(value <= range.lowerBound)

                Divider()
                    .frame(height: 20)

                // Value
                Text("\(value)")
                    .font(Typography.bodyBold)
                    .foregroundStyle(ColorConstants.Text.primary)
                    .monospacedDigit()
                    .frame(minWidth: 40)

                Divider()
                    .frame(height: 20)

                // Increment
                Button {
                    HapticManager.shared.lightImpact()
                    if value + step <= range.upperBound {
                        value += step
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(value < range.upperBound ? ColorConstants.Text.primary : ColorConstants.Text.tertiary)
                        .frame(width: 36, height: 36)
                }
                .disabled(value >= range.upperBound)
            }
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
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

// MARK: - Glass Slider

struct GlassSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double?
    let formatter: ((Double) -> String)?

    init(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double? = nil,
        formatter: ((Double) -> String)? = nil
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.formatter = formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(title)
                    .font(Typography.body)
                    .foregroundStyle(ColorConstants.Text.primary)

                Spacer()

                Text(formatter?(value) ?? String(format: "%.1f", value))
                    .font(Typography.bodyBold)
                    .foregroundStyle(ColorConstants.primary)
                    .monospacedDigit()
            }

            if let step = step {
                Slider(value: $value, in: range, step: step)
                    .tint(ColorConstants.primary)
            } else {
                Slider(value: $value, in: range)
                    .tint(ColorConstants.primary)
            }
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

// MARK: - Sample Enum for Preview

private enum SampleCategory: String, CaseIterable, Hashable, CustomStringConvertible {
    case business = "Business"
    case personal = "Personal"
    case medical = "Medical"
    case charity = "Charity"

    var description: String { rawValue }
}

// MARK: - Preview

#Preview("Glass Pickers") {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            // Picker
            GlassPicker(
                "Trip Category",
                selection: .constant(SampleCategory.business),
                options: SampleCategory.allCases,
                icon: "folder.fill"
            )

            // Date picker
            GlassDatePicker(
                "Trip Date",
                date: .constant(Date()),
                displayedComponents: [.date]
            )

            // Time picker
            GlassDatePicker(
                "Start Time",
                date: .constant(Date()),
                displayedComponents: [.hourAndMinute]
            )

            // Date range
            GlassDateRangePicker(
                title: "Report Period",
                startDate: .constant(Calendar.current.date(byAdding: .day, value: -30, to: Date())!),
                endDate: .constant(Date())
            )

            // Stepper
            GlassStepper(
                "Passengers",
                value: .constant(2),
                range: 0...8,
                formatter: { "\($0) passengers" }
            )

            // Slider
            GlassSlider(
                "Detection Sensitivity",
                value: .constant(0.7),
                range: 0...1,
                step: 0.1,
                formatter: { String(format: "%.0f%%", $0 * 100) }
            )
        }
        .padding()
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
