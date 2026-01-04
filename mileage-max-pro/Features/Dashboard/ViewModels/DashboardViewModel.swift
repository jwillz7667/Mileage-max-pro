//
//  DashboardViewModel.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import SwiftUI
import SwiftData
import Combine
import os

/// ViewModel for the Dashboard feature
@MainActor
final class DashboardViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var dashboardState: LoadableState<DashboardData> = .idle
    @Published var recentTrips: [Trip] = []
    @Published var weeklyStats: [DailyMileage] = []
    @Published var activeRoute: DeliveryRoute?
    @Published var selectedPeriod: StatsPeriod = .month

    @Published var showingAddTrip = false
    @Published var showingAddExpense = false
    @Published var showingRoutePlanner = false

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let apiClient = APIClient.shared
    private let locationService = LocationTrackingService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var isTracking: Bool {
        locationService.trackingState == .tracking
    }

    var currentTrip: LocationTrackingService.ActiveTrip? {
        locationService.currentTrip
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupBindings()
    }

    private func setupBindings() {
        // Observe location service changes
        locationService.$trackingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        locationService.$currentTrip
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    func loadDashboard() async {
        dashboardState = .loading

        do {
            // Load local data first
            await loadLocalData()

            // Then fetch from API if online
            if NetworkMonitor.shared.isConnected {
                let data = try await fetchDashboardData()
                dashboardState = .loaded(data)
            } else {
                // Use local computed data
                let localData = computeLocalDashboardData()
                dashboardState = .loaded(localData)
            }
        } catch {
            if case .loaded = dashboardState {
                // Keep showing cached data
                dashboardState = .refreshing(getCachedData())
            } else {
                dashboardState = .error(AppError.from(error))
            }
        }
    }

    func refresh() async {
        guard case .loaded(let currentData) = dashboardState else {
            await loadDashboard()
            return
        }

        dashboardState = .refreshing(currentData)
        await loadDashboard()
    }

    private func loadLocalData() async {
        // Fetch recent trips from SwiftData
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        let completedStatus = TripStatus.completed.rawValue

        let descriptor = FetchDescriptor<Trip>(
            predicate: #Predicate<Trip> { trip in
                trip.startTime >= startOfMonth && trip.statusRaw == completedStatus
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        do {
            let trips = try modelContext.fetch(descriptor)
            recentTrips = Array(trips.prefix(5))
            weeklyStats = computeWeeklyStats(from: trips)
        } catch {
            AppLogger.data.error("Failed to fetch local trips: \(error.localizedDescription)")
        }

        // Check for active route
        let inProgressStatus = RouteStatus.inProgress.rawValue
        let routeDescriptor = FetchDescriptor<DeliveryRoute>(
            predicate: #Predicate<DeliveryRoute> { route in
                route.statusRaw == inProgressStatus
            }
        )

        do {
            let routes = try modelContext.fetch(routeDescriptor)
            activeRoute = routes.first
        } catch {
            AppLogger.data.error("Failed to fetch active route: \(error.localizedDescription)")
        }
    }

    private func fetchDashboardData() async throws -> DashboardData {
        // Only fetch from API if authenticated
        guard AuthenticationService.shared.authState == .authenticated else {
            return computeLocalDashboardData()
        }

        let endpoint = AnalyticsEndpoints.dashboard(period: selectedPeriod)
        let response: DashboardResponse = try await apiClient.request(endpoint)
        return DashboardData(from: response)
    }

    private func computeLocalDashboardData() -> DashboardData {
        let calendar = Calendar.current
        let now = Date()

        // Get date range based on period
        let startDate: Date
        switch selectedPeriod {
        case .day:
            startDate = calendar.startOfDay(for: now)
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        case .quarter:
            startDate = calendar.date(byAdding: .month, value: -3, to: now)!
        case .year:
            startDate = calendar.date(from: calendar.dateComponents([.year], from: now))!
        case .custom:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)!
        }

        // Fetch trips in range
        let completedStatus = TripStatus.completed.rawValue
        let descriptor = FetchDescriptor<Trip>(
            predicate: #Predicate<Trip> { trip in
                trip.startTime >= startDate && trip.statusRaw == completedStatus
            }
        )

        do {
            let trips = try modelContext.fetch(descriptor)

            let totalMiles = trips.reduce(0) { $0 + $1.distanceMiles }
            let businessMiles = trips.filter { $0.category == .business }.reduce(0) { $0 + $1.distanceMiles }
            let personalMiles = trips.filter { $0.category == .personal }.reduce(0) { $0 + $1.distanceMiles }
            let medicalMiles = trips.filter { $0.category == .medical }.reduce(0) { $0 + $1.distanceMiles }
            let charityMiles = trips.filter { $0.category == .charity }.reduce(0) { $0 + $1.distanceMiles }

            // Calculate tax deduction using current IRS rate
            let irsRate = AppConstants.IRSMileageRates.current
            let estimatedDeduction = (businessMiles * irsRate.business) +
                                     (medicalMiles * irsRate.medical) +
                                     (charityMiles * irsRate.charity)

            return DashboardData(
                totalTrips: trips.count,
                totalMiles: totalMiles,
                businessMiles: businessMiles,
                personalMiles: personalMiles,
                medicalMiles: medicalMiles,
                charityMiles: charityMiles,
                estimatedDeduction: estimatedDeduction,
                averageDailyMiles: totalMiles / max(1, Double(calendar.dateComponents([.day], from: startDate, to: now).day ?? 1)),
                tripsByCategory: [
                    .business: trips.filter { $0.category == .business }.count,
                    .personal: trips.filter { $0.category == .personal }.count,
                    .medical: trips.filter { $0.category == .medical }.count,
                    .charity: trips.filter { $0.category == .charity }.count
                ],
                weeklyTrend: weeklyStats
            )
        } catch {
            return DashboardData.empty
        }
    }

    private func computeWeeklyStats(from trips: [Trip]) -> [DailyMileage] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var stats: [DailyMileage] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let nextDate = calendar.date(byAdding: .day, value: 1, to: date)!

            let dayTrips = trips.filter { trip in
                trip.startTime >= date && trip.startTime < nextDate
            }

            let miles = dayTrips.reduce(0) { $0 + $1.distanceMiles }
            let businessMiles = dayTrips.filter { $0.category == .business }.reduce(0) { $0 + $1.distanceMiles }

            stats.append(DailyMileage(
                date: date,
                totalMiles: miles,
                businessMiles: businessMiles,
                tripCount: dayTrips.count
            ))
        }

        return stats
    }

    private func getCachedData() -> DashboardData {
        if case .loaded(let data) = dashboardState {
            return data
        }
        return DashboardData.empty
    }

    // MARK: - Actions

    func startTrip(vehicleId: UUID) {
        // Ensure location monitoring is active
        if !locationService.trackingState.isActive {
            locationService.startMonitoring()
        }

        // Check for current location - if not available yet, try to start anyway
        // LocationTrackingService.startTrip will handle the error case
        Task {
            // Give location manager a moment to get a fix if needed
            if locationService.currentLocation == nil {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }

            guard let location = locationService.currentLocation else {
                AppLogger.trip.error("Cannot start trip: location unavailable")
                return
            }

            let address = await locationService.reverseGeocode(location: location)
            locationService.startTrip(vehicleId: vehicleId, startAddress: address)
        }
    }

    func endTrip() async -> Trip? {
        guard let trip = await locationService.endTrip() else { return nil }

        // Save to SwiftData
        modelContext.insert(trip)

        do {
            try modelContext.save()

            // Sync with backend if online
            if NetworkMonitor.shared.isConnected {
                await syncTrip(trip)
            }

            // Refresh dashboard
            await loadDashboard()

            return trip
        } catch {
            AppLogger.data.error("Failed to save trip: \(error.localizedDescription)")
            return nil
        }
    }

    private func syncTrip(_ trip: Trip) async {
        // Only sync if authenticated
        guard AuthenticationService.shared.authState == .authenticated else {
            trip.syncStatus = .pending
            return
        }

        // Create API request
        let request = CreateTripRequest(
            startLatitude: trip.startLatitude,
            startLongitude: trip.startLongitude,
            startAddress: trip.startAddress,
            startPlaceName: nil,
            vehicleId: trip.vehicleId?.uuidString ?? "",
            category: trip.category.rawValue,
            purpose: trip.purpose,
            notes: trip.notes
        )

        do {
            let _: TripResponse = try await apiClient.request(TripEndpoints.create(trip: request))
            trip.syncStatus = .synced
            trip.lastSyncedAt = Date()
            try? modelContext.save()
        } catch {
            trip.syncStatus = .pending
            AppLogger.sync.error("Failed to sync trip: \(error.localizedDescription)")
        }
    }
}

// MARK: - Dashboard Data Model

struct DashboardData: Equatable {
    let totalTrips: Int
    let totalMiles: Double
    let businessMiles: Double
    let personalMiles: Double
    let medicalMiles: Double
    let charityMiles: Double
    let estimatedDeduction: Double
    let averageDailyMiles: Double
    let tripsByCategory: [TripCategory: Int]
    let weeklyTrend: [DailyMileage]

    static var empty: DashboardData {
        DashboardData(
            totalTrips: 0,
            totalMiles: 0,
            businessMiles: 0,
            personalMiles: 0,
            medicalMiles: 0,
            charityMiles: 0,
            estimatedDeduction: 0,
            averageDailyMiles: 0,
            tripsByCategory: [:],
            weeklyTrend: []
        )
    }
}

struct DailyMileage: Equatable, Identifiable {
    let date: Date
    let totalMiles: Double
    let businessMiles: Double
    let tripCount: Int

    var id: Date { date }

    var dayAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Dashboard Response

struct DashboardResponse: Codable {
    let totalTrips: Int
    let totalMiles: Double
    let businessMiles: Double
    let personalMiles: Double
    let medicalMiles: Double?
    let charityMiles: Double?
    let estimatedDeduction: Double
    let avgDailyMiles: Double
    let tripsByCategory: [String: Int]
    let weeklyTrend: [WeeklyDataPoint]

    struct WeeklyDataPoint: Codable {
        let date: Date
        let miles: Double
        let trips: Int
    }
}

extension DashboardData {
    init(from response: DashboardResponse) {
        self.totalTrips = response.totalTrips
        self.totalMiles = response.totalMiles
        self.businessMiles = response.businessMiles
        self.personalMiles = response.personalMiles
        self.medicalMiles = response.medicalMiles ?? 0
        self.charityMiles = response.charityMiles ?? 0
        self.estimatedDeduction = response.estimatedDeduction
        self.averageDailyMiles = response.avgDailyMiles

        var categoryMap: [TripCategory: Int] = [:]
        for (key, value) in response.tripsByCategory {
            if let category = TripCategory(rawValue: key) {
                categoryMap[category] = value
            }
        }
        self.tripsByCategory = categoryMap

        self.weeklyTrend = response.weeklyTrend.map { point in
            DailyMileage(
                date: point.date,
                totalMiles: point.miles,
                businessMiles: point.miles * 0.8, // Estimate
                tripCount: point.trips
            )
        }
    }
}

// MARK: - Analytics Endpoints

enum AnalyticsEndpoints {
    case dashboard(period: StatsPeriod)
    case taxSummary(year: Int)
    case trends(startDate: Date, endDate: Date)
}

extension AnalyticsEndpoints: APIEndpoint {
    var method: HTTPMethod { .get }

    var path: String {
        switch self {
        case .dashboard:
            return "/analytics/dashboard"
        case .taxSummary:
            return "/analytics/tax-summary"
        case .trends:
            return "/analytics/trends"
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .dashboard(let period):
            return ["period": period.rawValue]
        case .taxSummary(let year):
            return ["year": String(year)]
        case .trends(let startDate, let endDate):
            let formatter = ISO8601DateFormatter()
            return [
                "start_date": formatter.string(from: startDate),
                "end_date": formatter.string(from: endDate)
            ]
        }
    }
}
