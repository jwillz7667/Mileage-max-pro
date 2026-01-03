//
//  EmptyStateView.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI

/// Empty state view for when there's no content to display
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: CGFloat = 0

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(ColorConstants.primary.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(ColorConstants.primary)
            }
            .scaleEffect(iconScale)
            .opacity(iconOpacity)

            // Text content
            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.title3)
                    .foregroundStyle(ColorConstants.Text.primary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(Typography.body)
                    .foregroundStyle(ColorConstants.Text.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, Spacing.lg)

            // Action button
            if let actionTitle = actionTitle, let action = action {
                GlassButton(actionTitle, style: .primary) {
                    action()
                }
                .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.xl)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
        }
    }
}

// MARK: - Preset Empty States

extension EmptyStateView {
    /// No trips recorded
    static func noTrips(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "car.fill",
            title: "No Trips Yet",
            message: "Start driving to automatically record your first trip, or add one manually.",
            actionTitle: "Add Trip Manually",
            action: action
        )
    }

    /// No vehicles added
    static func noVehicles(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "car.2.fill",
            title: "No Vehicles",
            message: "Add your vehicle to start tracking mileage and fuel economy.",
            actionTitle: "Add Vehicle",
            action: action
        )
    }

    /// No expenses recorded
    static func noExpenses(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "dollarsign.circle.fill",
            title: "No Expenses",
            message: "Track your vehicle-related expenses to see spending insights.",
            actionTitle: "Add Expense",
            action: action
        )
    }

    /// No saved locations
    static func noLocations(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "mappin.circle.fill",
            title: "No Saved Locations",
            message: "Save frequent destinations for automatic trip classification.",
            actionTitle: "Add Location",
            action: action
        )
    }

    /// No routes planned
    static func noRoutes(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "map.fill",
            title: "No Routes",
            message: "Plan and optimize multi-stop routes for efficient deliveries.",
            actionTitle: "Create Route",
            action: action
        )
    }

    /// No reports generated
    static func noReports(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "doc.text.fill",
            title: "No Reports",
            message: "Generate IRS-compliant mileage reports for tax deductions.",
            actionTitle: "Create Report",
            action: action
        )
    }

    /// Search returned no results
    static func noSearchResults(query: String) -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: "No results found for \"\(query)\". Try a different search term."
        )
    }

    /// Offline state
    static func offline(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "You're offline. Some features may be limited.",
            actionTitle: "Try Again",
            action: action
        )
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let error: AppError
    let retryAction: (() -> Void)?

    init(error: AppError, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(ColorConstants.error.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(ColorConstants.error)
            }

            // Error details
            VStack(spacing: Spacing.xs) {
                Text("Something Went Wrong")
                    .font(Typography.title3)
                    .foregroundStyle(ColorConstants.Text.primary)

                Text(error.localizedDescription)
                    .font(Typography.body)
                    .foregroundStyle(ColorConstants.Text.secondary)
                    .multilineTextAlignment(.center)

                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(Typography.caption1)
                        .foregroundStyle(ColorConstants.Text.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing.xs)
                }
            }
            .padding(.horizontal, Spacing.lg)

            // Retry button
            if let retryAction = retryAction, error.isRetryable {
                GlassButton("Try Again", icon: "arrow.clockwise", style: .primary) {
                    retryAction()
                }
                .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.xl)
    }
}

// MARK: - Success State View

struct SuccessStateView: View {
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkOpacity: CGFloat = 0

    init(
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Animated checkmark
            ZStack {
                Circle()
                    .fill(ColorConstants.success.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(ColorConstants.success)
                    .scaleEffect(checkmarkScale)
                    .opacity(checkmarkOpacity)
            }

            // Text content
            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.title3)
                    .foregroundStyle(ColorConstants.Text.primary)

                Text(message)
                    .font(Typography.body)
                    .foregroundStyle(ColorConstants.Text.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.lg)

            // Action button
            if let actionTitle = actionTitle, let action = action {
                GlassButton(actionTitle, style: .success) {
                    action()
                }
                .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.xl)
        .onAppear {
            HapticManager.shared.success()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1)) {
                checkmarkScale = 1.0
                checkmarkOpacity = 1.0
            }
        }
    }
}

// MARK: - Preview

#Preview("Empty States") {
    ScrollView {
        VStack(spacing: 40) {
            EmptyStateView.noTrips {}

            Divider()

            ErrorStateView(
                error: .networkUnavailable,
                retryAction: {}
            )

            Divider()

            SuccessStateView(
                title: "Trip Saved",
                message: "Your trip has been successfully recorded.",
                actionTitle: "View Trip"
            ) {}
        }
        .padding()
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
