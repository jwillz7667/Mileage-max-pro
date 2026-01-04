//
//  DashboardView.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//  Premium Dashboard - iOS 26 Liquid Glass Design
//

import SwiftUI
import SwiftData
import Charts
import CoreLocation

/// Main dashboard view showing mileage statistics and quick actions
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        DashboardContentView(modelContext: modelContext)
    }
}

/// Internal content view with initialized ViewModel
private struct DashboardContentView: View {
    @StateObject private var viewModel: DashboardViewModel
    @EnvironmentObject private var locationService: LocationTrackingService

    @State private var showingVehiclePicker = false
    @State private var selectedVehicleId: UUID?
    @State private var shouldStartTrip = false

    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Active tracking banner
                    if viewModel.isTracking {
                        PremiumTrackingBanner(
                            trip: viewModel.currentTrip,
                            speed: locationService.speed,
                            onStop: {
                                Task {
                                    _ = await viewModel.endTrip()
                                }
                            }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Active route card
                    if let route = viewModel.activeRoute {
                        PremiumActiveRouteCard(route: route)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Period selector
                    PremiumPeriodSelector(selection: $viewModel.selectedPeriod)

                    // Hero stat card - Total miles
                    switch viewModel.dashboardState {
                    case .idle, .loading:
                        HeroStatSkeleton()

                    case .loaded(let data), .refreshing(let data):
                        HeroMileageCard(data: data)

                    case .error(let error):
                        ErrorStateView(error: error) {
                            Task { await viewModel.loadDashboard() }
                        }
                    }

                    // Stats grid
                    switch viewModel.dashboardState {
                    case .idle, .loading:
                        StatsGridSkeleton()

                    case .loaded(let data), .refreshing(let data):
                        PremiumStatsGrid(data: data)

                    case .error:
                        EmptyView()
                    }

                    // Quick actions
                    PremiumQuickActionsSection(
                        isTracking: viewModel.isTracking,
                        onStartTrip: { showingVehiclePicker = true },
                        onStopTrip: {
                            Task { _ = await viewModel.endTrip() }
                        },
                        onAddTrip: { viewModel.showingAddTrip = true },
                        onPlanRoute: { viewModel.showingRoutePlanner = true }
                    )

                    // Weekly chart
                    if !viewModel.weeklyStats.isEmpty {
                        PremiumWeeklyChartSection(data: viewModel.weeklyStats)
                    }

                    // Recent trips
                    PremiumRecentTripsSection(
                        trips: viewModel.recentTrips,
                        onSeeAll: { /* Navigate to trips */ }
                    )
                }
                .padding()
            }
            .background(ColorConstants.Surface.grouped)
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Spacing.sm) {
                        // Sync status
                        if case .refreshing = viewModel.dashboardState {
                            ProgressView()
                                .scaleEffect(0.8)
                        }

                        // Notifications
                        GlassIconButton(icon: "bell.fill", style: .secondary, size: 36) {
                            // Show notifications
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadDashboard()
            }
            .sheet(isPresented: $showingVehiclePicker, onDismiss: {
                // Start trip AFTER sheet is fully dismissed to avoid presentation conflict
                if shouldStartTrip, let vehicleId = selectedVehicleId {
                    shouldStartTrip = false
                    viewModel.startTrip(vehicleId: vehicleId)
                }
            }) {
                VehiclePickerSheet(selectedVehicleId: $selectedVehicleId, shouldStartTrip: $shouldStartTrip)
            }
            .sheet(isPresented: $viewModel.showingAddTrip) {
                ManualTripEntryView()
            }
            .sheet(isPresented: $viewModel.showingRoutePlanner) {
                RoutePlannerView()
            }
        }
        .animation(.premiumSpring, value: viewModel.isTracking)
        .animation(.smoothEase, value: viewModel.dashboardState)
    }
}

// MARK: - Premium Period Selector

struct PremiumPeriodSelector: View {
    @Binding var selection: StatsPeriod

    var body: some View {
        HStack(spacing: 0) {
            ForEach([StatsPeriod.day, .week, .month, .year], id: \.self) { period in
                Button {
                    HapticManager.shared.selection()
                    withAnimation(.premiumSpring) {
                        selection = period
                    }
                } label: {
                    Text(period.shortLabel)
                        .font(Typography.subheadlineBold)
                        .foregroundStyle(selection == period ? ColorConstants.Text.inverse : ColorConstants.Text.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selection == period ?
                            Capsule().fill(ColorConstants.primary) :
                            Capsule().fill(Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(ColorConstants.Surface.card)
                .shadow(color: ColorConstants.Neomorphic.darkShadow, radius: 4, x: 0, y: 2)
        )
        .overlay(
            Capsule()
                .stroke(ColorConstants.Border.standard, lineWidth: 0.5)
        )
    }
}

extension StatsPeriod {
    var shortLabel: String {
        switch self {
        case .day: return "Today"
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "Qtr"
        case .year: return "Year"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Hero Mileage Card

struct HeroMileageCard: View {
    let data: DashboardData

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Mileage")
                        .font(Typography.subheadline)
                        .foregroundStyle(ColorConstants.Text.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(data.totalMiles.formatted(.number.precision(.fractionLength(1))))
                            .font(Typography.statHero)
                            .foregroundStyle(ColorConstants.Text.primary)
                            .monospacedDigit()

                        Text("mi")
                            .font(Typography.headline)
                            .foregroundStyle(ColorConstants.Text.tertiary)
                    }
                }

                Spacer()

                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ColorConstants.primary, ColorConstants.primary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: ColorConstants.primary.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: "car.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }

            // Stats row
            HStack(spacing: Spacing.lg) {
                HeroStatPill(
                    value: "\(data.totalTrips)",
                    label: "trips",
                    icon: "location.fill"
                )

                HeroStatPill(
                    value: data.averageDailyMiles.formatted(.number.precision(.fractionLength(1))),
                    label: "avg/day",
                    icon: "chart.line.uptrend.xyaxis"
                )

                HeroStatPill(
                    value: data.estimatedDeduction.asCurrency(),
                    label: "savings",
                    icon: "dollarsign.circle.fill"
                )
            }
        }
        .padding(Spacing.lg)
        .background(ColorConstants.Surface.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .stroke(ColorConstants.Border.standard, lineWidth: 0.5)
        )
        .shadow(color: ColorConstants.Neomorphic.darkShadow, radius: 8, x: 0, y: 4)
    }
}

struct HeroStatPill: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ColorConstants.primary)

            Text(value)
                .font(Typography.subheadlineBold)
                .foregroundStyle(ColorConstants.Text.primary)
                .monospacedDigit()

            Text(label)
                .font(Typography.caption2)
                .foregroundStyle(ColorConstants.Text.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                .fill(ColorConstants.Surface.elevated)
        )
    }
}

struct HeroStatSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ColorConstants.Surface.elevated)
                        .frame(width: 100, height: 16)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(ColorConstants.Surface.elevated)
                        .frame(width: 150, height: 48)
                }

                Spacer()

                Circle()
                    .fill(ColorConstants.Surface.elevated)
                    .frame(width: 56, height: 56)
            }

            HStack(spacing: Spacing.lg) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                        .fill(ColorConstants.Surface.elevated)
                        .frame(height: 70)
                }
            }
        }
        .padding(Spacing.lg)
        .background(ColorConstants.Surface.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous))
        .shimmer(isLoading: true)
    }
}

// MARK: - Premium Stats Grid

struct PremiumStatsGrid: View {
    let data: DashboardData

    private var businessPercentage: Int {
        guard data.totalMiles > 0 else { return 0 }
        return Int(data.businessMiles / data.totalMiles * 100)
    }

    private var personalPercentage: Int {
        guard data.totalMiles > 0 else { return 0 }
        return Int(data.personalMiles / data.totalMiles * 100)
    }

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: Spacing.cardGap),
            GridItem(.flexible(), spacing: Spacing.cardGap)
        ], spacing: Spacing.cardGap) {
            StatCard(
                title: "Business",
                value: data.businessMiles.formatted(.number.precision(.fractionLength(1))),
                subtitle: "\(businessPercentage)% of total",
                icon: "briefcase.fill",
                iconColor: ColorConstants.TripCategory.business,
                size: .regular
            )

            StatCard(
                title: "Personal",
                value: data.personalMiles.formatted(.number.precision(.fractionLength(1))),
                subtitle: "\(personalPercentage)% of total",
                icon: "person.fill",
                iconColor: ColorConstants.TripCategory.personal,
                size: .regular
            )

            StatCard(
                title: "Tax Savings",
                value: data.estimatedDeduction.asCurrency(),
                subtitle: "@ $\(String(format: "%.3f", AppConstants.IRSMileageRates.current.business))/mi",
                icon: "dollarsign.circle.fill",
                iconColor: ColorConstants.success,
                size: .regular
            )

            StatCard(
                title: "Daily Avg",
                value: data.averageDailyMiles.formatted(.number.precision(.fractionLength(1))),
                subtitle: "miles per day",
                icon: "chart.line.uptrend.xyaxis",
                iconColor: ColorConstants.primary,
                size: .regular
            )
        }
    }
}

struct StatsGridSkeleton: View {
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: Spacing.cardGap),
            GridItem(.flexible(), spacing: Spacing.cardGap)
        ], spacing: Spacing.cardGap) {
            ForEach(0..<4, id: \.self) { _ in
                SkeletonCard()
            }
        }
    }
}

// MARK: - Premium Tracking Banner

struct PremiumTrackingBanner: View {
    let trip: LocationTrackingService.ActiveTrip?
    let speed: CLLocationSpeed
    let onStop: () -> Void

    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Header with pulsing indicator
            HStack {
                HStack(spacing: Spacing.sm) {
                    Circle()
                        .fill(ColorConstants.success)
                        .frame(width: 10, height: 10)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0.7 : 1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulseAnimation)

                    Text("Trip in Progress")
                        .font(Typography.headline)
                        .foregroundStyle(ColorConstants.Text.primary)
                }

                Spacer()

                Text(formatDuration(trip?.durationSeconds ?? 0))
                    .font(Typography.statSmall)
                    .foregroundStyle(ColorConstants.success)
                    .monospacedDigit()
            }

            // Live stats
            HStack(spacing: 0) {
                LiveStatItem(
                    value: String(format: "%.1f", trip?.distanceMiles ?? 0),
                    unit: "mi",
                    icon: "road.lanes",
                    color: ColorConstants.primary
                )

                Divider()
                    .frame(height: 40)

                LiveStatItem(
                    value: String(format: "%.0f", max(0, speed * 2.23694)),
                    unit: "mph",
                    icon: "speedometer",
                    color: ColorConstants.warning
                )

                Divider()
                    .frame(height: 40)

                LiveStatItem(
                    value: String(format: "%.1f", avgSpeed),
                    unit: "avg",
                    icon: "gauge.with.needle",
                    color: ColorConstants.success
                )
            }
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                    .fill(ColorConstants.Surface.elevated)
            )

            // Stop button
            GlassButton("End Trip", icon: "stop.fill", style: .destructive, size: .fullWidth) {
                HapticManager.shared.warning()
                onStop()
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .fill(ColorConstants.Surface.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .stroke(ColorConstants.success.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: ColorConstants.success.opacity(0.15), radius: 12, x: 0, y: 6)
        .onAppear {
            pulseAnimation = true
        }
    }

    private var avgSpeed: Double {
        guard let trip = trip, trip.durationSeconds > 0 else { return 0 }
        return (trip.distanceMiles / Double(trip.durationSeconds)) * 3600
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}

struct LiveStatItem: View {
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)

            Text(value)
                .font(Typography.statSmall)
                .foregroundStyle(ColorConstants.Text.primary)
                .monospacedDigit()

            Text(unit)
                .font(Typography.caption2)
                .foregroundStyle(ColorConstants.Text.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Premium Active Route Card

struct PremiumActiveRouteCard: View {
    let route: DeliveryRoute

    var completedStops: Int {
        route.stops.filter { $0.status == .completed }.count
    }

    var progress: Double {
        guard route.stops.count > 0 else { return 0 }
        return Double(completedStops) / Double(route.stops.count)
    }

    var body: some View {
        NavigationLink(destination: ActiveNavigationView(route: route)) {
            VStack(spacing: Spacing.md) {
                HStack {
                    IconLeadingView(
                        icon: "map.fill",
                        color: ColorConstants.secondary,
                        size: 44,
                        style: .gradient
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Active Route")
                            .font(Typography.caption1)
                            .foregroundStyle(ColorConstants.Text.tertiary)

                        Text(route.name ?? "Unnamed Route")
                            .font(Typography.headline)
                            .foregroundStyle(ColorConstants.Text.primary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(ColorConstants.Text.quaternary)
                }

                // Progress bar
                VStack(spacing: 6) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(ColorConstants.Border.standard)
                                .frame(height: 6)

                            Capsule()
                                .fill(ColorConstants.secondary)
                                .frame(width: geometry.size.width * progress, height: 6)
                        }
                    }
                    .frame(height: 6)

                    HStack {
                        Text("\(completedStops) of \(route.stops.count) stops")
                            .font(Typography.caption1)
                            .foregroundStyle(ColorConstants.Text.secondary)

                        Spacer()

                        if let nextStop = route.stops.first(where: { $0.status == .pending }) {
                            Text("Next: \(nextStop.name ?? "Unknown")")
                                .font(Typography.caption1)
                                .fontWeight(.medium)
                                .foregroundStyle(ColorConstants.secondary)
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .background(ColorConstants.Surface.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusCard, style: .continuous)
                    .stroke(ColorConstants.Border.standard, lineWidth: 0.5)
            )
            .shadow(color: ColorConstants.Neomorphic.darkShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Premium Quick Actions Section

struct PremiumQuickActionsSection: View {
    let isTracking: Bool
    let onStartTrip: () -> Void
    let onStopTrip: () -> Void
    let onAddTrip: () -> Void
    let onPlanRoute: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            GlassSectionHeader("Quick Actions")

            HStack(spacing: Spacing.md) {
                PremiumQuickActionButton(
                    icon: isTracking ? "stop.fill" : "play.fill",
                    title: isTracking ? "Stop" : "Start",
                    color: isTracking ? ColorConstants.error : ColorConstants.success,
                    action: isTracking ? onStopTrip : onStartTrip
                )

                PremiumQuickActionButton(
                    icon: "plus",
                    title: "Add Trip",
                    color: ColorConstants.primary,
                    action: onAddTrip
                )

                PremiumQuickActionButton(
                    icon: "map.fill",
                    title: "Route",
                    color: ColorConstants.secondary,
                    action: onPlanRoute
                )

                PremiumQuickActionButton(
                    icon: "doc.text.fill",
                    title: "Report",
                    color: ColorConstants.warning,
                    action: { /* Navigate to reports */ }
                )
            }
        }
    }
}

struct PremiumQuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            VStack(spacing: Spacing.sm) {
                ZStack {
                    // Neomorphic circle
                    Circle()
                        .fill(ColorConstants.Surface.card)
                        .frame(width: 56, height: 56)
                        .shadow(color: ColorConstants.Neomorphic.lightShadow, radius: 4, x: -2, y: -2)
                        .shadow(color: ColorConstants.Neomorphic.darkShadow, radius: 4, x: 2, y: 2)

                    // Color overlay
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(color)
                }
                .scaleEffect(isPressed ? 0.9 : 1.0)

                Text(title)
                    .font(Typography.caption1)
                    .fontWeight(.semibold)
                    .foregroundStyle(ColorConstants.Text.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.quickResponse) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.premiumSpring) { isPressed = false }
                }
        )
    }
}

// MARK: - Premium Weekly Chart Section

struct PremiumWeeklyChartSection: View {
    let data: [DailyMileage]

    var totalMiles: Double {
        data.reduce(0) { $0 + $1.totalMiles }
    }

    var totalTrips: Int {
        data.reduce(0) { $0 + $1.tripCount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                GlassSectionHeader("This Week")

                Spacer()

                HStack(spacing: Spacing.md) {
                    MiniStatPill(label: "mi", value: totalMiles.formatted(.number.precision(.fractionLength(1))), color: ColorConstants.primary)
                    MiniStatPill(label: "trips", value: "\(totalTrips)", color: ColorConstants.success)
                }
            }

            GlassMorphicCard {
                VStack(spacing: Spacing.md) {
                    Chart {
                        ForEach(data) { day in
                            BarMark(
                                x: .value("Day", day.dayAbbreviation),
                                y: .value("Miles", day.totalMiles)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [ColorConstants.primary, ColorConstants.primary.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(6)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let miles = value.as(Double.self) {
                                    Text("\(Int(miles))")
                                        .font(Typography.caption2)
                                        .foregroundStyle(ColorConstants.Text.tertiary)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let day = value.as(String.self) {
                                    Text(day)
                                        .font(Typography.caption2)
                                        .fontWeight(.medium)
                                        .foregroundStyle(ColorConstants.Text.secondary)
                                }
                            }
                        }
                    }
                    .frame(height: 180)

                    // Legend
                    HStack(spacing: Spacing.lg) {
                        LegendItem(color: ColorConstants.primary, label: "Total Miles")
                        LegendItem(color: ColorConstants.TripCategory.business, label: "Business")
                    }
                }
            }
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .font(Typography.caption1)
                .foregroundStyle(ColorConstants.Text.secondary)
        }
    }
}

// MARK: - Premium Recent Trips Section

struct PremiumRecentTripsSection: View {
    let trips: [Trip]
    let onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            GlassSectionHeader("Recent Trips", actionTitle: "See All", action: onSeeAll)

            if trips.isEmpty {
                EmptyStateView(
                    icon: "car.fill",
                    title: "No Recent Trips",
                    message: "Start tracking to see your trips here"
                )
                .frame(height: 150)
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(trips.prefix(3)) { trip in
                        TripListRow(
                            startLocation: trip.startAddress ?? "Unknown",
                            endLocation: trip.endAddress ?? "In Progress",
                            distance: trip.distanceMiles.asMiles(),
                            date: trip.startTime.smartFormatted,
                            category: trip.category,
                            action: { /* Navigate to trip detail */ }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Vehicle Picker Sheet

struct VehiclePickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedVehicleId: UUID?
    @Binding var shouldStartTrip: Bool

    @Query(sort: \Vehicle.nickname) private var vehicles: [Vehicle]
    @State private var showingAddVehicle = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    if vehicles.isEmpty {
                        VStack(spacing: Spacing.lg) {
                            Image(systemName: "car.2.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(ColorConstants.Text.tertiary)

                            VStack(spacing: Spacing.xs) {
                                Text("No Vehicles")
                                    .font(Typography.headline)
                                    .foregroundStyle(ColorConstants.Text.primary)

                                Text("Add a vehicle to start tracking trips")
                                    .font(Typography.body)
                                    .foregroundStyle(ColorConstants.Text.secondary)
                            }

                            GlassButton("Add Vehicle", icon: "plus.circle.fill", style: .primary, size: .regular) {
                                showingAddVehicle = true
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xxl)
                    } else {
                        ForEach(vehicles) { vehicle in
                            Button {
                                HapticManager.shared.selection()
                                selectedVehicleId = vehicle.id
                                shouldStartTrip = true
                                dismiss()
                            } label: {
                                HStack(spacing: Spacing.md) {
                                    IconLeadingView(
                                        icon: "car.fill",
                                        color: vehicle.isActive ? ColorConstants.primary : ColorConstants.secondary,
                                        size: 44,
                                        style: vehicle.isActive ? .gradient : .filled
                                    )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(vehicle.name)
                                            .font(Typography.body)
                                            .foregroundStyle(ColorConstants.Text.primary)

                                        Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                                            .font(Typography.caption1)
                                            .foregroundStyle(ColorConstants.Text.secondary)
                                    }

                                    Spacer()

                                    if vehicle.isActive {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundStyle(ColorConstants.success)
                                    }
                                }
                                .padding(Spacing.md)
                                .background(ColorConstants.Surface.card)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusCard, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusCard, style: .continuous)
                                        .stroke(ColorConstants.Border.standard, lineWidth: 0.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .background(ColorConstants.Surface.grouped)
            .navigationTitle("Select Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(ColorConstants.Text.secondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddVehicle = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(ColorConstants.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddVehicle) {
                AddVehicleView { vehicle in
                    modelContext.insert(vehicle)
                    try? modelContext.save()
                    selectedVehicleId = vehicle.id
                    shouldStartTrip = true
                    dismiss()
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Placeholder Views

struct ManualTripEntryView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    Text("Manual trip entry form will be implemented here")
                        .font(Typography.body)
                        .foregroundStyle(ColorConstants.Text.secondary)
                }
                .padding()
            }
            .background(ColorConstants.Surface.grouped)
            .navigationTitle("Add Trip")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(ColorConstants.Text.secondary)
                }
            }
        }
    }
}

struct RoutePlannerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    Text("Route planner will be implemented here")
                        .font(Typography.body)
                        .foregroundStyle(ColorConstants.Text.secondary)
                }
                .padding()
            }
            .background(ColorConstants.Surface.grouped)
            .navigationTitle("Plan Route")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(ColorConstants.Text.secondary)
                }
            }
        }
    }
}

struct ActiveNavigationView: View {
    let route: DeliveryRoute

    var body: some View {
        Text("Active Navigation for \(route.name ?? "Route")")
            .navigationTitle("Navigation")
    }
}
