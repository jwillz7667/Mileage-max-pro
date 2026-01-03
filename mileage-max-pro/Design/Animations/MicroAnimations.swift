//
//  MicroAnimations.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI

/// Micro-animation definitions for polished UI interactions
enum MicroAnimations {

    // MARK: - Animation Curves

    /// Standard spring for most interactions
    static var standard: Animation {
        .spring(response: 0.35, dampingFraction: 0.7)
    }

    /// Quick spring for responsive feedback
    static var quick: Animation {
        .spring(response: 0.25, dampingFraction: 0.8)
    }

    /// Smooth transition for content changes
    static var smooth: Animation {
        .easeInOut(duration: 0.3)
    }

    /// Elastic bounce for playful elements
    static var elastic: Animation {
        .spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.1)
    }

    /// Gentle animation for subtle changes
    static var gentle: Animation {
        .easeOut(duration: 0.2)
    }

    /// Slow animation for emphasis
    static var slow: Animation {
        .easeInOut(duration: 0.5)
    }

    // MARK: - Animation Values

    /// Button tap scale
    static let buttonTapScale: CGFloat = 0.95

    /// Card selection scale
    static let cardSelectionScale: CGFloat = 1.02

    /// Icon bounce scale
    static let iconBounceScale: CGFloat = 1.3

    /// Subtle pulse range
    static let pulseOpacityRange: ClosedRange<Double> = 0.7...1.0

    /// Shake amplitude
    static let shakeAmplitude: CGFloat = 10

    /// Number counter step duration
    static let counterStepDuration: Double = 0.05
}

// MARK: - Animation View Modifiers

/// Bounce animation on tap
struct BounceAnimationModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? MicroAnimations.buttonTapScale : 1.0)
            .onTapGesture {
                withAnimation(MicroAnimations.quick) {
                    isAnimating = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(MicroAnimations.quick) {
                        isAnimating = false
                    }
                }
            }
    }
}

/// Pulse animation for attention
struct PulseAnimationModifier: ViewModifier {
    @State private var isPulsing = false
    let duration: Double

    init(duration: Double = 1.5) {
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? MicroAnimations.pulseOpacityRange.lowerBound : MicroAnimations.pulseOpacityRange.upperBound)
            .scaleEffect(isPulsing ? 0.98 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

/// Shake animation for errors
struct ShakeAnimationModifier: ViewModifier {
    @Binding var trigger: Bool

    func body(content: Content) -> some View {
        content
            .offset(x: trigger ? MicroAnimations.shakeAmplitude : 0)
            .animation(
                .default.repeatCount(3, autoreverses: true).speed(6),
                value: trigger
            )
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        trigger = false
                    }
                }
            }
    }
}

/// Pop-in animation for appearing elements
struct PopInAnimationModifier: ViewModifier {
    @State private var hasAppeared = false
    let delay: Double

    init(delay: Double = 0) {
        self.delay = delay
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(hasAppeared ? 1.0 : 0.5)
            .opacity(hasAppeared ? 1.0 : 0)
            .onAppear {
                withAnimation(MicroAnimations.elastic.delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

/// Slide-in animation for list items
struct SlideInAnimationModifier: ViewModifier {
    @State private var hasAppeared = false
    let edge: Edge
    let delay: Double

    init(from edge: Edge = .bottom, delay: Double = 0) {
        self.edge = edge
        self.delay = delay
    }

    func body(content: Content) -> some View {
        content
            .offset(
                x: edge == .leading ? (hasAppeared ? 0 : -30) : (edge == .trailing ? (hasAppeared ? 0 : 30) : 0),
                y: edge == .top ? (hasAppeared ? 0 : -20) : (edge == .bottom ? (hasAppeared ? 0 : 20) : 0)
            )
            .opacity(hasAppeared ? 1.0 : 0)
            .onAppear {
                withAnimation(MicroAnimations.standard.delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

/// Continuous rotation animation
struct RotatingAnimationModifier: ViewModifier {
    @State private var rotation: Double = 0
    let duration: Double

    init(duration: Double = 1.0) {
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

/// Breathing animation for subtle emphasis
struct BreathingAnimationModifier: ViewModifier {
    @State private var isBreathing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isBreathing ? 1.05 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isBreathing = true
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Add bounce animation on tap
    func bounceOnTap() -> some View {
        modifier(BounceAnimationModifier())
    }

    /// Add continuous pulse animation
    func pulsing(duration: Double = 1.5) -> some View {
        modifier(PulseAnimationModifier(duration: duration))
    }

    /// Add shake animation triggered by binding
    func shake(trigger: Binding<Bool>) -> some View {
        modifier(ShakeAnimationModifier(trigger: trigger))
    }

    /// Add pop-in animation on appear
    func popIn(delay: Double = 0) -> some View {
        modifier(PopInAnimationModifier(delay: delay))
    }

    /// Add slide-in animation on appear
    func slideIn(from edge: Edge = .bottom, delay: Double = 0) -> some View {
        modifier(SlideInAnimationModifier(from: edge, delay: delay))
    }

    /// Add continuous rotation
    func rotating(duration: Double = 1.0) -> some View {
        modifier(RotatingAnimationModifier(duration: duration))
    }

    /// Add breathing animation
    func breathing() -> some View {
        modifier(BreathingAnimationModifier())
    }

    /// Staggered animation for list items
    func staggeredAnimation(index: Int, baseDelay: Double = 0.05) -> some View {
        self.slideIn(from: .bottom, delay: Double(index) * baseDelay)
    }
}

// MARK: - Animated Number Counter

struct AnimatedCounter: View {
    let value: Double
    let format: String
    let duration: Double

    @State private var displayValue: Double = 0

    init(value: Double, format: String = "%.0f", duration: Double = 0.5) {
        self.value = value
        self.format = format
        self.duration = duration
    }

    var body: some View {
        Text(String(format: format, displayValue))
            .monospacedDigit()
            .onAppear {
                animateValue(to: value)
            }
            .onChange(of: value) { _, newValue in
                animateValue(to: newValue)
            }
    }

    private func animateValue(to target: Double) {
        let steps = 20
        let stepDuration = duration / Double(steps)
        let increment = (target - displayValue) / Double(steps)

        for step in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) {
                displayValue += increment
            }
        }

        // Ensure final value is exact
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            displayValue = target
        }
    }
}

// MARK: - Animated Checkmark

struct AnimatedCheckmark: View {
    let size: CGFloat
    let color: Color

    @State private var progress: CGFloat = 0

    init(size: CGFloat = 60, color: Color = ColorConstants.success) {
        self.size = size
        self.color = color
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: size, height: size)

            CheckmarkShape()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.5, height: size * 0.5)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                progress = 1
            }
        }
    }
}

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width * 0.35, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

// MARK: - Preview

#Preview("Micro Animations") {
    VStack(spacing: 40) {
        // Bounce
        GlassButton("Bounce Me", style: .primary) {}
            .bounceOnTap()

        // Pulse
        Circle()
            .fill(ColorConstants.primary)
            .frame(width: 60, height: 60)
            .pulsing()

        // Pop-in
        HStack(spacing: 16) {
            ForEach(0..<4) { index in
                Circle()
                    .fill(ColorConstants.chartColors[index])
                    .frame(width: 40, height: 40)
                    .popIn(delay: Double(index) * 0.1)
            }
        }

        // Rotating
        Image(systemName: "arrow.triangle.2.circlepath")
            .font(.system(size: 30))
            .foregroundStyle(ColorConstants.primary)
            .rotating(duration: 2)

        // Animated counter
        AnimatedCounter(value: 1234.5, format: "%.1f")
            .font(Typography.statLarge)

        // Animated checkmark
        AnimatedCheckmark(size: 80)
    }
    .padding()
}
