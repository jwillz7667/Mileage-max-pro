//
//  GlassToggle.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI

/// Glass-styled toggle with Liquid Glass effect
struct GlassToggle: View {
    let title: String
    let subtitle: String?
    let icon: String?
    @Binding var isOn: Bool

    @Environment(\.isEnabled) private var isEnabled

    init(
        _ title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        isOn: Binding<Bool>
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self._isOn = isOn
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isOn ? ColorConstants.primary : ColorConstants.Text.tertiary)
                    .frame(width: 28)
                    .animation(.easeInOut(duration: 0.2), value: isOn)
            }

            // Labels
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

            // Toggle
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
        .opacity(isEnabled ? 1 : 0.6)
    }
}

// MARK: - Glass Toggle Switch

struct GlassToggleSwitch: View {
    @Binding var isOn: Bool

    private let width: CGFloat = 51
    private let height: CGFloat = 31
    private let knobSize: CGFloat = 27
    private let padding: CGFloat = 2

    private var trackColor: Color {
        isOn ? ColorConstants.primary : Color.gray.opacity(0.3)
    }

    private var knobOffset: CGFloat {
        isOn ? (width - knobSize) / 2 - padding : -(width - knobSize) / 2 + padding
    }

    var body: some View {
        ZStack {
            // Track
            trackView

            // Knob
            knobView
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
        .onTapGesture {
            HapticManager.shared.lightImpact()
            isOn.toggle()
        }
    }

    private var trackView: some View {
        Capsule()
            .fill(trackColor)
            .frame(width: width, height: height)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }

    private var knobView: some View {
        Circle()
            .fill(.white)
            .frame(width: knobSize, height: knobSize)
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            .offset(x: knobOffset)
    }
}

// MARK: - Glass Checkbox

struct GlassCheckbox: View {
    let title: String
    @Binding var isChecked: Bool

    var body: some View {
        Button {
            HapticManager.shared.lightImpact()
            isChecked.toggle()
        } label: {
            HStack(spacing: Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isChecked ? ColorConstants.primary : Color.clear)
                        .frame(width: 22, height: 22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(isChecked ? ColorConstants.primary : ColorConstants.Text.tertiary, lineWidth: 2)
                        )

                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isChecked)

                Text(title)
                    .font(Typography.body)
                    .foregroundStyle(ColorConstants.Text.primary)

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Glass Radio Button

struct GlassRadioButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.lightImpact()
            action()
        } label: {
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? ColorConstants.primary : ColorConstants.Text.tertiary, lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(ColorConstants.primary)
                            .frame(width: 12, height: 12)
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)

                Text(title)
                    .font(Typography.body)
                    .foregroundStyle(ColorConstants.Text.primary)

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Glass Radio Group

struct GlassRadioGroup<T: Hashable & CaseIterable & CustomStringConvertible>: View where T.AllCases: RandomAccessCollection {
    let title: String
    @Binding var selection: T
    let options: [T]

    init(_ title: String, selection: Binding<T>, options: [T]? = nil) {
        self.title = title
        self._selection = selection
        self.options = options ?? Array(T.allCases)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if !title.isEmpty {
                Text(title)
                    .font(Typography.caption1)
                    .fontWeight(.medium)
                    .foregroundStyle(ColorConstants.Text.secondary)
            }

            VStack(spacing: Spacing.xs) {
                ForEach(options, id: \.self) { option in
                    GlassRadioButton(
                        title: option.description,
                        isSelected: selection == option
                    ) {
                        selection = option
                    }
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Glass Segmented Control

struct GlassSegmentedControl<T: Hashable>: View {
    @Binding var selection: T
    let options: [(value: T, label: String, icon: String?)]

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(options.enumerated()), id: \.element.value) { index, option in
                Button {
                    HapticManager.shared.lightImpact()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = option.value
                    }
                } label: {
                    HStack(spacing: 6) {
                        if let icon = option.icon {
                            Image(systemName: icon)
                                .font(.system(size: 14, weight: .medium))
                        }
                        Text(option.label)
                            .font(Typography.subheadlineBold)
                    }
                    .foregroundStyle(selection == option.value ? .white : ColorConstants.Text.secondary)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .background {
                        if selection == option.value {
                            Capsule()
                                .fill(ColorConstants.primary)
                                .matchedGeometryEffect(id: "segment", in: namespace)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Glass Toggles & Controls") {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            // Toggle
            GlassToggle(
                "Auto-Track Trips",
                subtitle: "Automatically detect and record trips",
                icon: "location.fill",
                isOn: .constant(true)
            )

            GlassToggle(
                "Dark Mode",
                icon: "moon.fill",
                isOn: .constant(false)
            )

            // Toggle switch alone
            HStack {
                Text("Simple Toggle")
                Spacer()
                GlassToggleSwitch(isOn: .constant(true))
            }
            .padding()

            // Checkboxes
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Categories")
                    .font(Typography.caption1)
                    .foregroundStyle(ColorConstants.Text.secondary)

                GlassCheckbox(title: "Business", isChecked: .constant(true))
                GlassCheckbox(title: "Personal", isChecked: .constant(false))
                GlassCheckbox(title: "Medical", isChecked: .constant(true))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                    .fill(.ultraThinMaterial)
            )

            // Segmented control
            GlassSegmentedControl(
                selection: .constant(0),
                options: [
                    (0, "Day", "calendar"),
                    (1, "Week", nil),
                    (2, "Month", nil),
                    (3, "Year", nil)
                ]
            )
        }
        .padding()
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
