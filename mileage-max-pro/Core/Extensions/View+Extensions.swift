//
//  View+Extensions.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI

// MARK: - Conditional Modifiers

extension View {
    /// Apply a modifier conditionally
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Apply a modifier conditionally with else clause
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }

    /// Apply a modifier if value is non-nil
    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - Liquid Glass Effects

extension View {
    /// Apply Liquid Glass background effect
    func glassBackground(
        cornerRadius: CGFloat = 20,
        blur: CGFloat = 20,
        opacity: Double = 0.7
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(opacity)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }

    /// Apply enhanced Liquid Glass effect with refraction
    func liquidGlass(
        cornerRadius: CGFloat = 24,
        shadowRadius: CGFloat = 10
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: shadowRadius, x: 0, y: 5)
            .shadow(color: Color.black.opacity(0.05), radius: shadowRadius / 2, x: 0, y: 2)
    }

    /// Apply Liquid Glass card styling
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Neumorphic Effects

extension View {
    /// Apply neumorphic styling
    func neumorphic(
        isPressed: Bool = false,
        cornerRadius: CGFloat = 16,
        lightColor: Color = .white,
        darkColor: Color = Color.black.opacity(0.15),
        shadowRadius: CGFloat = 10
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(uiColor: .systemBackground))
                    .shadow(
                        color: isPressed ? darkColor : lightColor,
                        radius: shadowRadius,
                        x: isPressed ? 5 : -5,
                        y: isPressed ? 5 : -5
                    )
                    .shadow(
                        color: isPressed ? lightColor : darkColor,
                        radius: shadowRadius,
                        x: isPressed ? -5 : 5,
                        y: isPressed ? -5 : 5
                    )
            )
    }

    /// Apply neumorphic button styling
    func neumorphicButton(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .neumorphic(isPressed: isPressed)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isPressed)
    }
}

// MARK: - Shadows

extension View {
    /// Apply soft shadow
    func softShadow(
        color: Color = .black.opacity(0.1),
        radius: CGFloat = 10,
        x: CGFloat = 0,
        y: CGFloat = 5
    ) -> some View {
        self.shadow(color: color, radius: radius, x: x, y: y)
    }

    /// Apply elevation shadow (Material Design inspired)
    func elevation(_ level: ElevationLevel) -> some View {
        self
            .shadow(color: .black.opacity(level.opacity1), radius: level.radius1, x: 0, y: level.y1)
            .shadow(color: .black.opacity(level.opacity2), radius: level.radius2, x: 0, y: level.y2)
    }
}

enum ElevationLevel {
    case none
    case low
    case medium
    case high
    case highest

    var radius1: CGFloat {
        switch self {
        case .none: return 0
        case .low: return 2
        case .medium: return 6
        case .high: return 12
        case .highest: return 24
        }
    }

    var y1: CGFloat {
        switch self {
        case .none: return 0
        case .low: return 1
        case .medium: return 3
        case .high: return 6
        case .highest: return 12
        }
    }

    var radius2: CGFloat {
        switch self {
        case .none: return 0
        case .low: return 4
        case .medium: return 10
        case .high: return 20
        case .highest: return 40
        }
    }

    var y2: CGFloat {
        switch self {
        case .none: return 0
        case .low: return 2
        case .medium: return 5
        case .high: return 10
        case .highest: return 20
        }
    }

    var opacity1: Double {
        switch self {
        case .none: return 0
        case .low: return 0.1
        case .medium: return 0.12
        case .high: return 0.14
        case .highest: return 0.16
        }
    }

    var opacity2: Double {
        switch self {
        case .none: return 0
        case .low: return 0.08
        case .medium: return 0.1
        case .high: return 0.12
        case .highest: return 0.14
        }
    }
}

// MARK: - Layout Helpers

extension View {
    /// Align view to leading edge
    func alignLeading() -> some View {
        HStack {
            self
            Spacer()
        }
    }

    /// Align view to trailing edge
    func alignTrailing() -> some View {
        HStack {
            Spacer()
            self
        }
    }

    /// Align view to top
    func alignTop() -> some View {
        VStack {
            self
            Spacer()
        }
    }

    /// Align view to bottom
    func alignBottom() -> some View {
        VStack {
            Spacer()
            self
        }
    }

    /// Center view in frame
    func centered() -> some View {
        HStack {
            Spacer()
            self
            Spacer()
        }
    }

}

// MARK: - Spacing

enum SpacingSize {
    case xxs
    case xs
    case sm
    case md
    case lg
    case xl
    case xxl

    var value: CGFloat {
        switch self {
        case .xxs: return 4
        case .xs: return 8
        case .sm: return 12
        case .md: return 16
        case .lg: return 24
        case .xl: return 32
        case .xxl: return 48
        }
    }
}

// MARK: - Loading States

extension View {
    /// Overlay with loading indicator
    func loading(_ isLoading: Bool) -> some View {
        self
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    }
                }
            }
            .allowsHitTesting(!isLoading)
    }

    /// Apply shimmer loading effect
    func shimmer(isLoading: Bool) -> some View {
        self.modifier(ShimmerModifier(isLoading: isLoading))
    }

    /// Apply redacted with shimmer
    func redactedWithShimmer(if condition: Bool) -> some View {
        self
            .redacted(reason: condition ? .placeholder : [])
            .shimmer(isLoading: condition)
    }
}

struct ShimmerModifier: ViewModifier {
    let isLoading: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                if isLoading {
                    LinearGradient(
                        colors: [
                            Color.gray.opacity(0.2),
                            Color.gray.opacity(0.3),
                            Color.gray.opacity(0.2)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .mask(content)
                    .offset(x: phase)
                    .onAppear {
                        withAnimation(
                            .linear(duration: 1.5)
                            .repeatForever(autoreverses: false)
                        ) {
                            phase = 200
                        }
                    }
                }
            }
    }
}

// MARK: - Animations

extension View {
    /// Apply standard spring animation
    func springAnimation() -> some View {
        self.animation(.spring(response: 0.35, dampingFraction: 0.7), value: UUID())
    }

    /// Apply quick spring animation
    func quickSpring() -> some View {
        self.animation(.spring(response: 0.25, dampingFraction: 0.8), value: UUID())
    }
}

// MARK: - Accessibility

extension View {
    /// Apply accessibility label and hint
    func accessible(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .if(hint != nil) { view in
                view.accessibilityHint(hint!)
            }
    }

    /// Hide from accessibility
    func accessibilityHide() -> some View {
        self.accessibilityHidden(true)
    }
}

// MARK: - Keyboard

extension View {
    /// Dismiss keyboard on tap
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }

    /// Add keyboard toolbar with done button
    func keyboardDoneButton() -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
            }
        }
    }
}

// MARK: - Safe Area

extension View {
    /// Read safe area insets
    func readSafeAreaInsets(_ insets: Binding<EdgeInsets>) -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SafeAreaInsetsKey.self, value: geometry.safeAreaInsets)
            }
        )
        .onPreferenceChange(SafeAreaInsetsKey.self) { value in
            insets.wrappedValue = value
        }
    }
}

struct SafeAreaInsetsKey: PreferenceKey {
    static var defaultValue: EdgeInsets = .init()

    static func reduce(value: inout EdgeInsets, nextValue: () -> EdgeInsets) {
        value = nextValue()
    }
}

// MARK: - Size Reading

extension View {
    /// Read view size
    func readSize(_ size: Binding<CGSize>) -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self) { value in
            size.wrappedValue = value
        }
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
