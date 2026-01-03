//
//  LoadingView.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI

/// Animated loading indicator with Liquid Glass styling
struct LoadingView: View {
    let message: String?
    let style: LoadingStyle

    @State private var isAnimating = false

    init(message: String? = nil, style: LoadingStyle = .spinner) {
        self.message = message
        self.style = style
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            switch style {
            case .spinner:
                spinnerView

            case .dots:
                dotsView

            case .pulse:
                pulseView

            case .progress(let value):
                progressView(value: value)

            case .car:
                carAnimationView
            }

            if let message = message {
                Text(message)
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorConstants.Text.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }

    // MARK: - Spinner

    @ViewBuilder
    private var spinnerView: some View {
        ZStack {
            Circle()
                .stroke(ColorConstants.primary.opacity(0.2), lineWidth: 4)

            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    ColorConstants.primary,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
        }
        .frame(width: 44, height: 44)
    }

    // MARK: - Dots

    @ViewBuilder
    private var dotsView: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(ColorConstants.primary)
                    .frame(width: 10, height: 10)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .opacity(isAnimating ? 1 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
    }

    // MARK: - Pulse

    @ViewBuilder
    private var pulseView: some View {
        ZStack {
            Circle()
                .fill(ColorConstants.primary.opacity(0.3))
                .frame(width: 60, height: 60)
                .scaleEffect(isAnimating ? 1.5 : 1)
                .opacity(isAnimating ? 0 : 0.5)

            Circle()
                .fill(ColorConstants.primary)
                .frame(width: 20, height: 20)
        }
    }

    // MARK: - Progress

    @ViewBuilder
    private func progressView(value: Double) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(ColorConstants.primary.opacity(0.2))
                    .frame(height: 8)

                Capsule()
                    .fill(ColorConstants.primary)
                    .frame(width: max(8, CGFloat(value) * 200), height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: value)
            }
            .frame(width: 200)

            Text("\(Int(value * 100))%")
                .font(Typography.caption1)
                .fontWeight(.medium)
                .monospacedDigit()
                .foregroundStyle(ColorConstants.Text.secondary)
        }
    }

    // MARK: - Car Animation

    @ViewBuilder
    private var carAnimationView: some View {
        ZStack {
            // Road line
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    Capsule()
                        .fill(ColorConstants.Text.tertiary.opacity(0.3))
                        .frame(width: 20, height: 2)
                        .offset(x: isAnimating ? -100 : 0)
                        .animation(
                            .linear(duration: 1)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.1),
                            value: isAnimating
                        )
                }
            }
            .offset(y: 15)

            // Car
            Image(systemName: "car.fill")
                .font(.system(size: 32))
                .foregroundStyle(ColorConstants.primary)
                .offset(y: isAnimating ? -2 : 2)
                .animation(
                    .easeInOut(duration: 0.3)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
        .frame(width: 120, height: 60)
    }
}

// MARK: - Loading Style

enum LoadingStyle {
    case spinner
    case dots
    case pulse
    case progress(Double)
    case car
}

// MARK: - Full Screen Loading

struct FullScreenLoadingView: View {
    let message: String?
    let style: LoadingStyle

    init(message: String? = "Loading...", style: LoadingStyle = .spinner) {
        self.message = message
        self.style = style
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            GlassMorphicCard(
                cornerRadius: AppTheme.cornerRadiusXLarge,
                padding: EdgeInsets(top: 32, leading: 40, bottom: 32, trailing: 40)
            ) {
                LoadingView(message: message, style: style)
            }
        }
    }
}

// MARK: - Inline Loading

struct InlineLoadingView: View {
    let message: String?

    init(_ message: String? = nil) {
        self.message = message
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ProgressView()
                .scaleEffect(0.9)

            if let message = message {
                Text(message)
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorConstants.Text.secondary)
            }
        }
        .padding(Spacing.sm)
    }
}

// MARK: - Shimmer Loading

struct ShimmerView: View {
    let cornerRadius: CGFloat

    @State private var startPoint: UnitPoint = .init(x: -1.8, y: -1.2)
    @State private var endPoint: UnitPoint = .init(x: 0, y: -0.2)

    init(cornerRadius: CGFloat = AppTheme.cornerRadiusMedium) {
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        LinearGradient(
            colors: [
                Color.gray.opacity(0.2),
                Color.gray.opacity(0.3),
                Color.gray.opacity(0.2)
            ],
            startPoint: startPoint,
            endPoint: endPoint
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                startPoint = .init(x: 1, y: 1)
                endPoint = .init(x: 2.2, y: 2.2)
            }
        }
    }
}

// MARK: - Skeleton Loading

struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                ShimmerView(cornerRadius: 20)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 6) {
                    ShimmerView()
                        .frame(width: 120, height: 14)
                    ShimmerView()
                        .frame(width: 80, height: 12)
                }
            }

            ShimmerView()
                .frame(height: 14)

            ShimmerView()
                .frame(width: 200, height: 14)
        }
        .padding(Spacing.cardInsets)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(AppTheme.cornerRadiusCard)
    }
}

// MARK: - View Modifier for Loading State

struct LoadingModifier: ViewModifier {
    let isLoading: Bool
    let message: String?

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 2 : 0)

            if isLoading {
                FullScreenLoadingView(message: message)
            }
        }
    }
}

extension View {
    /// Show loading overlay
    func loadingOverlay(_ isLoading: Bool, message: String? = nil) -> some View {
        modifier(LoadingModifier(isLoading: isLoading, message: message))
    }
}

// MARK: - Preview

#Preview("Loading Views") {
    ScrollView {
        VStack(spacing: 40) {
            // Spinner
            VStack {
                Text("Spinner").font(.caption)
                LoadingView(message: "Loading trips...", style: .spinner)
            }

            // Dots
            VStack {
                Text("Dots").font(.caption)
                LoadingView(style: .dots)
            }

            // Pulse
            VStack {
                Text("Pulse").font(.caption)
                LoadingView(style: .pulse)
            }

            // Progress
            VStack {
                Text("Progress").font(.caption)
                LoadingView(message: "Uploading...", style: .progress(0.65))
            }

            // Car
            VStack {
                Text("Car").font(.caption)
                LoadingView(message: "Recording trip...", style: .car)
            }

            // Skeleton
            VStack(alignment: .leading) {
                Text("Skeleton").font(.caption)
                SkeletonCard()
                SkeletonCard()
            }
        }
        .padding()
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
