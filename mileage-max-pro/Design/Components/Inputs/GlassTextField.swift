//
//  GlassTextField.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//  Premium Input Components - iOS 26 Liquid Glass
//

import SwiftUI

/// Premium glass-styled text field with Liquid Glass effect
struct GlassTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String?
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    let isSecure: Bool
    let validation: ((String) -> ValidationResult)?
    let onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool
    @State private var showSecureText = false
    @State private var validationResult: ValidationResult = .valid
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme

    init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        icon: String? = nil,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        isSecure: Bool = false,
        validation: ((String) -> ValidationResult)? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.isSecure = isSecure
        self.validation = validation
        self.onSubmit = onSubmit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Label
            if !title.isEmpty {
                Text(title)
                    .font(Typography.label)
                    .foregroundStyle(ColorConstants.Text.secondary)
            }

            // Input field
            HStack(spacing: Spacing.sm) {
                // Leading icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(iconColor)
                        .frame(width: 24)
                        .animation(.premiumSpring, value: isFocused)
                }

                // Text field
                Group {
                    if isSecure && !showSecureText {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(Typography.body)
                .foregroundStyle(ColorConstants.Text.primary)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .autocorrectionDisabled(isSecure)
                .textInputAutocapitalization(isSecure ? .never : .sentences)
                .focused($isFocused)
                .onSubmit {
                    validate()
                    onSubmit?()
                }
                .onChange(of: text) { _, newValue in
                    if validation != nil {
                        validationResult = .valid // Reset while typing
                    }
                }

                // Secure toggle / Clear button
                if isSecure && !text.isEmpty {
                    Button {
                        HapticManager.shared.lightImpact()
                        showSecureText.toggle()
                    } label: {
                        Image(systemName: showSecureText ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(ColorConstants.Text.tertiary)
                    }
                    .buttonStyle(.plain)
                } else if !text.isEmpty && !isSecure {
                    Button {
                        HapticManager.shared.lightImpact()
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(ColorConstants.Text.quaternary)
                    }
                    .buttonStyle(.plain)
                }

                // Validation indicator
                if case .invalid = validationResult {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(ColorConstants.error)
                        .transition(.scale.combined(with: .opacity))
                } else if case .valid = validationResult, validation != nil, !text.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(ColorConstants.success)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 14)
            .background(fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous))
            .overlay(fieldBorder)
            .shadow(
                color: isFocused ? ColorConstants.primary.opacity(0.15) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
            .opacity(isEnabled ? 1 : 0.5)
            .animation(.premiumSpring, value: isFocused)

            // Error message
            if case .invalid(let message) = validationResult {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 11, weight: .medium))
                    Text(message)
                        .font(Typography.caption2)
                }
                .foregroundStyle(ColorConstants.error)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.premiumSpring, value: validationResult.isValid)
    }

    private var iconColor: Color {
        if case .invalid = validationResult {
            return ColorConstants.error
        }
        return isFocused ? ColorConstants.primary : ColorConstants.Text.tertiary
    }

    @ViewBuilder
    private var fieldBackground: some View {
        ZStack {
            // Base neomorphic background
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                .fill(ColorConstants.Surface.card)

            // Subtle inner shadow for depth
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.02),
                            Color.clear,
                            Color.white.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Focused highlight
            if isFocused {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                    .fill(ColorConstants.Glass.primaryTint)
            }
        }
    }

    @ViewBuilder
    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
            .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
    }

    private var borderColor: Color {
        if case .invalid = validationResult {
            return ColorConstants.error
        }
        return isFocused ? ColorConstants.primary : ColorConstants.Border.standard
    }

    private func validate() {
        guard let validation = validation else { return }
        validationResult = validation(text)
    }
}

// MARK: - Validation Result

enum ValidationResult: Equatable {
    case valid
    case invalid(String)

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }
}

// MARK: - Common Validators

enum TextValidators {
    static func email(_ text: String) -> ValidationResult {
        guard !text.isEmpty else { return .valid }
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: text) ? .valid : .invalid("Invalid email format")
    }

    static func minLength(_ length: Int) -> (String) -> ValidationResult {
        return { text in
            guard !text.isEmpty else { return .valid }
            return text.count >= length ? .valid : .invalid("Must be at least \(length) characters")
        }
    }

    static func required(_ text: String) -> ValidationResult {
        text.isEmpty ? .invalid("This field is required") : .valid
    }

    static func phone(_ text: String) -> ValidationResult {
        guard !text.isEmpty else { return .valid }
        let digits = text.filter { $0.isNumber }
        return digits.count >= 10 ? .valid : .invalid("Invalid phone number")
    }

    static func numeric(_ text: String) -> ValidationResult {
        guard !text.isEmpty else { return .valid }
        return Double(text) != nil ? .valid : .invalid("Must be a number")
    }
}

// MARK: - Premium Glass Text Area

struct GlassTextArea: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat
    let maxHeight: CGFloat
    let maxCharacters: Int?

    @FocusState private var isFocused: Bool

    init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        minHeight: CGFloat = 100,
        maxHeight: CGFloat = 200,
        maxCharacters: Int? = nil
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.maxCharacters = maxCharacters
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if !title.isEmpty {
                Text(title)
                    .font(Typography.label)
                    .foregroundStyle(ColorConstants.Text.secondary)
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(Typography.body)
                        .foregroundStyle(ColorConstants.Text.placeholder)
                        .padding(.horizontal, 4)
                        .padding(.top, 8)
                }

                TextEditor(text: $text)
                    .font(Typography.body)
                    .foregroundStyle(ColorConstants.Text.primary)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: minHeight, maxHeight: maxHeight)
                    .onChange(of: text) { _, newValue in
                        if let max = maxCharacters, newValue.count > max {
                            text = String(newValue.prefix(max))
                        }
                    }
            }
            .padding(Spacing.sm)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                        .fill(ColorConstants.Surface.card)

                    if isFocused {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                            .fill(ColorConstants.Glass.primaryTint)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                    .stroke(isFocused ? ColorConstants.primary : ColorConstants.Border.standard, lineWidth: isFocused ? 2 : 1)
            )
            .shadow(
                color: isFocused ? ColorConstants.primary.opacity(0.1) : Color.clear,
                radius: 6,
                x: 0,
                y: 3
            )
            .animation(.premiumSpring, value: isFocused)

            // Character count
            HStack {
                Spacer()
                if let max = maxCharacters {
                    Text("\(text.count)/\(max)")
                        .font(Typography.caption2)
                        .foregroundStyle(text.count >= max ? ColorConstants.warning : ColorConstants.Text.tertiary)
                        .monospacedDigit()
                } else {
                    Text("\(text.count) characters")
                        .font(Typography.caption2)
                        .foregroundStyle(ColorConstants.Text.tertiary)
                }
            }
        }
    }
}

// MARK: - Premium Glass Search Field

struct GlassSearchField: View {
    @Binding var text: String
    let placeholder: String
    let onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool
    @State private var isAnimating = false

    init(
        text: Binding<String>,
        placeholder: String = "Search...",
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isFocused ? ColorConstants.primary : ColorConstants.Text.tertiary)
                .scaleEffect(isFocused ? 1.1 : 1.0)
                .animation(.premiumSpring, value: isFocused)

            TextField(placeholder, text: $text)
                .font(Typography.body)
                .foregroundStyle(ColorConstants.Text.primary)
                .focused($isFocused)
                .onSubmit { onSubmit?() }

            if !text.isEmpty {
                Button {
                    HapticManager.shared.lightImpact()
                    withAnimation(.premiumSpring) {
                        text = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(ColorConstants.Text.quaternary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(ColorConstants.Surface.card)
                .shadow(
                    color: ColorConstants.Neomorphic.darkShadow,
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            Capsule()
                .stroke(
                    isFocused ? ColorConstants.primary : ColorConstants.Border.standard,
                    lineWidth: isFocused ? 2 : 1
                )
        )
        .shadow(
            color: isFocused ? ColorConstants.primary.opacity(0.15) : Color.clear,
            radius: 8,
            x: 0,
            y: 4
        )
        .animation(.premiumSpring, value: isFocused)
        .animation(.premiumSpring, value: text.isEmpty)
    }
}

// MARK: - Premium Number Input Field

struct GlassNumberField: View {
    let title: String
    @Binding var value: Double
    let placeholder: String
    let icon: String?
    let suffix: String?
    let formatter: NumberFormatter
    let range: ClosedRange<Double>?

    @FocusState private var isFocused: Bool
    @State private var textValue: String = ""

    init(
        _ title: String,
        value: Binding<Double>,
        placeholder: String = "0",
        icon: String? = nil,
        suffix: String? = nil,
        decimals: Int = 2,
        range: ClosedRange<Double>? = nil
    ) {
        self.title = title
        self._value = value
        self.placeholder = placeholder
        self.icon = icon
        self.suffix = suffix
        self.range = range

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = decimals
        self.formatter = formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if !title.isEmpty {
                Text(title)
                    .font(Typography.label)
                    .foregroundStyle(ColorConstants.Text.secondary)
            }

            HStack(spacing: Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isFocused ? ColorConstants.primary : ColorConstants.Text.tertiary)
                        .frame(width: 24)
                }

                TextField(placeholder, text: $textValue)
                    .font(Typography.statSmall)
                    .fontDesign(.rounded)
                    .foregroundStyle(ColorConstants.Text.primary)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .monospacedDigit()
                    .multilineTextAlignment(suffix != nil ? .trailing : .leading)
                    .onChange(of: textValue) { _, newValue in
                        if let number = formatter.number(from: newValue) {
                            var val = number.doubleValue
                            if let range = range {
                                val = min(max(val, range.lowerBound), range.upperBound)
                            }
                            value = val
                        }
                    }
                    .onAppear {
                        textValue = value > 0 ? formatter.string(from: NSNumber(value: value)) ?? "" : ""
                    }

                if let suffix = suffix {
                    Text(suffix)
                        .font(Typography.body)
                        .foregroundStyle(ColorConstants.Text.tertiary)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                        .fill(ColorConstants.Surface.card)

                    if isFocused {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                            .fill(ColorConstants.Glass.primaryTint)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                    .stroke(isFocused ? ColorConstants.primary : ColorConstants.Border.standard, lineWidth: isFocused ? 2 : 1)
            )
            .shadow(
                color: isFocused ? ColorConstants.primary.opacity(0.1) : Color.clear,
                radius: 6,
                x: 0,
                y: 3
            )
            .animation(.premiumSpring, value: isFocused)
        }
    }
}

// MARK: - Premium Picker Field

struct GlassPickerField<T: Hashable>: View {
    let title: String
    @Binding var selection: T
    let options: [T]
    let optionLabel: (T) -> String
    let icon: String?

    @State private var isExpanded = false

    init(
        _ title: String,
        selection: Binding<T>,
        options: [T],
        icon: String? = nil,
        optionLabel: @escaping (T) -> String
    ) {
        self.title = title
        self._selection = selection
        self.options = options
        self.icon = icon
        self.optionLabel = optionLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if !title.isEmpty {
                Text(title)
                    .font(Typography.label)
                    .foregroundStyle(ColorConstants.Text.secondary)
            }

            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        HapticManager.shared.selection()
                        selection = option
                    } label: {
                        HStack {
                            Text(optionLabel(option))
                            if option == selection {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(ColorConstants.primary)
                            .frame(width: 24)
                    }

                    Text(optionLabel(selection))
                        .font(Typography.body)
                        .foregroundStyle(ColorConstants.Text.primary)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ColorConstants.Text.tertiary)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                        .fill(ColorConstants.Surface.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                        .stroke(ColorConstants.Border.standard, lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Preview

#Preview("Premium Glass Input Fields") {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            GlassTextField(
                "Email",
                text: .constant(""),
                placeholder: "Enter your email",
                icon: "envelope.fill",
                keyboardType: .emailAddress,
                validation: TextValidators.email
            )

            GlassTextField(
                "Password",
                text: .constant("secret123"),
                placeholder: "Enter password",
                icon: "lock.fill",
                isSecure: true,
                validation: TextValidators.minLength(8)
            )

            GlassNumberField(
                "Odometer",
                value: .constant(12345.6),
                placeholder: "Current reading",
                icon: "gauge",
                suffix: "mi"
            )

            GlassSearchField(text: .constant("coffee shop"))

            GlassTextArea(
                "Trip Notes",
                text: .constant("This is a sample note for the trip."),
                placeholder: "Add notes about your trip...",
                maxCharacters: 500
            )
        }
        .padding()
    }
    .background(ColorConstants.Surface.grouped)
}
