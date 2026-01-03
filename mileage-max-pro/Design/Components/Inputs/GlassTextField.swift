//
//  GlassTextField.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI

/// Glass-styled text field with Liquid Glass effect
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
                    .font(Typography.caption1)
                    .fontWeight(.medium)
                    .foregroundStyle(ColorConstants.Text.secondary)
            }

            // Input field
            HStack(spacing: Spacing.sm) {
                // Leading icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isFocused ? ColorConstants.primary : ColorConstants.Text.tertiary)
                        .frame(width: 24)
                        .animation(.easeInOut(duration: 0.2), value: isFocused)
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
                        showSecureText.toggle()
                    } label: {
                        Image(systemName: showSecureText ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(ColorConstants.Text.tertiary)
                    }
                } else if !text.isEmpty && !isSecure {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(ColorConstants.Text.tertiary)
                    }
                }

                // Validation indicator
                if case .invalid = validationResult {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(ColorConstants.error)
                } else if case .valid = validationResult, validation != nil, !text.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(ColorConstants.success)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm + 2)
            .background(fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous))
            .overlay(fieldBorder)
            .opacity(isEnabled ? 1 : 0.6)

            // Error message
            if case .invalid(let message) = validationResult {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 11))
                    Text(message)
                        .font(Typography.caption2)
                }
                .foregroundStyle(ColorConstants.error)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: validationResult.isValid)
    }

    @ViewBuilder
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                    .fill(Color.white.opacity(isFocused ? 0.1 : 0.05))
            )
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
        return isFocused ? ColorConstants.primary : Color.white.opacity(0.2)
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

// MARK: - Glass Text Area

struct GlassTextArea: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat
    let maxHeight: CGFloat

    @FocusState private var isFocused: Bool

    init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        minHeight: CGFloat = 100,
        maxHeight: CGFloat = 200
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.minHeight = minHeight
        self.maxHeight = maxHeight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if !title.isEmpty {
                Text(title)
                    .font(Typography.caption1)
                    .fontWeight(.medium)
                    .foregroundStyle(ColorConstants.Text.secondary)
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(Typography.body)
                        .foregroundStyle(ColorConstants.Text.tertiary)
                        .padding(.horizontal, 4)
                        .padding(.top, 8)
                }

                TextEditor(text: $text)
                    .font(Typography.body)
                    .foregroundStyle(ColorConstants.Text.primary)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: minHeight, maxHeight: maxHeight)
            }
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                    .stroke(isFocused ? ColorConstants.primary : Color.white.opacity(0.2), lineWidth: isFocused ? 2 : 1)
            )

            // Character count
            HStack {
                Spacer()
                Text("\(text.count) characters")
                    .font(Typography.caption2)
                    .foregroundStyle(ColorConstants.Text.tertiary)
            }
        }
    }
}

// MARK: - Glass Search Field

struct GlassSearchField: View {
    @Binding var text: String
    let placeholder: String
    let onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

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
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(ColorConstants.Text.tertiary)

            TextField(placeholder, text: $text)
                .font(Typography.body)
                .foregroundStyle(ColorConstants.Text.primary)
                .focused($isFocused)
                .onSubmit { onSubmit?() }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(ColorConstants.Text.tertiary)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule()
                .stroke(isFocused ? ColorConstants.primary.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Glass Text Fields") {
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

            GlassTextField(
                "Mileage",
                text: .constant("12345"),
                placeholder: "Current odometer",
                icon: "gauge",
                keyboardType: .numberPad,
                validation: TextValidators.numeric
            )

            GlassSearchField(text: .constant("coffee shop"))

            GlassTextArea(
                "Notes",
                text: .constant("This is a sample note for the trip."),
                placeholder: "Add trip notes..."
            )
        }
        .padding()
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
