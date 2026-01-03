//
//  TripsListViewModel.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import os
import SwiftUI
import SwiftData
import Combine

/// ViewModel for the Trips List feature
@MainActor
final class TripsListViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var trips: [Trip] = []
    @Published var filteredTrips: [Trip] = []
    @Published var loadState: LoadableState<[Trip]> = .idle
    @Published var searchText = ""
    @Published var selectedCategory: TripCategory?
    @Published var selectedVehicle: Vehicle?
    @Published var dateRange: DateRange = .thisMonth
    @Published var sortOrder: TripSortOrder = .dateDescending

    @Published var showingFilters = false
    @Published var showingAddTrip = false
    @Published var showingTripDetail: Trip?

    // MARK: - Properties

    private let modelContext: ModelContext
    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Date Range

    enum DateRange: String, CaseIterable, Identifiable {
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case thisQuarter = "This Quarter"
        case thisYear = "This Year"
        case custom = "Custom"

        var id: String { rawValue }

        var dateInterval: (start: Date, end: Date) {
            let calendar = Calendar.current
            let now = Date()

            switch self {
            case .today:
                let start = calendar.startOfDay(for: now)
                return (start, now)
            case .thisWeek:
                let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
                return (start, now)
            case .thisMonth:
                let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                return (start, now)
            case .thisQuarter:
                let quarter = (calendar.component(.month, from: now) - 1) / 3
                let startMonth = quarter * 3 + 1
                var components = calendar.dateComponents([.year], from: now)
                components.month = startMonth
                components.day = 1
                let start = calendar.date(from: components)!
                return (start, now)
            case .thisYear:
                let start = calendar.date(from: calendar.dateComponents([.year], from: now))!
                return (start, now)
            case .custom:
                // Default to last 30 days
                let start = calendar.date(byAdding: .day, value: -30, to: now)!
                return (start, now)
            }
        }
    }

    // MARK: - Sort Order

    enum TripSortOrder: String, CaseIterable, Identifiable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case distanceDescending = "Longest First"
        case distanceAscending = "Shortest First"
        case categoryAscending = "Category A-Z"

        var id: String { rawValue }
    }

    // MARK: - Computed Properties

    var totalMiles: Double {
        filteredTrips.reduce(0) { $0 + $1.distanceMiles }
    }

    var businessMiles: Double {
        filteredTrips.filter { $0.category == .business }.reduce(0) { $0 + $1.distanceMiles }
    }

    var estimatedDeduction: Double {
        let rate = AppConstants.IRSMileageRates.current
        return filteredTrips.reduce(0) { total, trip in
            switch trip.category {
            case .business:
                return total + (trip.distanceMiles * rate.business)
            case .medical:
                return total + (trip.distanceMiles * rate.medical)
            case .charity:
                return total + (trip.distanceMiles * rate.charity)
            default:
                return total
            }
        }
    }

    var tripsByDate: [Date: [Trip]] {
        let calendar = Calendar.current
        return Dictionary(grouping: filteredTrips) { trip in
            calendar.startOfDay(for: trip.startTime)
        }
    }

    var sortedDates: [Date] {
        tripsByDate.keys.sorted(by: >)
    }

    var hasActiveFilters: Bool {
        selectedCategory != nil || selectedVehicle != nil || !searchText.isEmpty
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupBindings()
    }

    private func setupBindings() {
        // React to filter changes
        Publishers.CombineLatest4(
            $searchText.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main),
            $selectedCategory,
            $selectedVehicle,
            $sortOrder
        )
        .combineLatest($dateRange)
        .sink { [weak self] _, _ in
            self?.applyFilters()
        }
        .store(in: &cancellables)
    }

    // MARK: - Data Loading

    func loadTrips() async {
        loadState = .loading

        let interval = dateRange.dateInterval

        // Build fetch descriptor - fetch all and filter in memory
        // to avoid SwiftData predicate issues with captured variables
        var descriptor = FetchDescriptor<Trip>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = 500

        do {
            let allTrips = try modelContext.fetch(descriptor)
            // Filter by date range in memory
            trips = allTrips.filter { trip in
                trip.startTime >= interval.start && trip.startTime <= interval.end
            }
            applyFilters()
            loadState = .loaded(filteredTrips)

            // Sync from server if online
            if NetworkMonitor.shared.isConnected {
                await syncTrips()
            }
        } catch {
            loadState = .error(AppError.from(error))
            AppLogger.data.error("Failed to fetch trips: \(error.localizedDescription)")
        }
    }

    func refresh() async {
        guard case .loaded = loadState else {
            await loadTrips()
            return
        }

        loadState = .refreshing(filteredTrips)
        await loadTrips()
    }

    private func syncTrips() async {
        let interval = dateRange.dateInterval

        var filters = TripFilters()
        filters.startDate = interval.start
        filters.endDate = interval.end

        let pagination = PaginationParameters(page: 1, limit: 100)
        let endpoint = TripEndpoints.list(pagination: pagination, filters: filters)

        do {
            let response: PaginatedResponse<TripResponse> = try await apiClient.request(endpoint)

            // Merge with local data
            for tripResponse in response.data {
                await mergeTrip(tripResponse)
            }

            try modelContext.save()
        } catch {
            AppLogger.sync.error("Failed to sync trips: \(error.localizedDescription)")
        }
    }

    private func mergeTrip(_ response: TripResponse) async {
        // Check if trip exists locally
        guard let tripId = UUID(uuidString: response.id) else {
            AppLogger.data.error("Invalid trip ID: \(response.id)")
            return
        }

        // Fetch all trips and filter in memory to avoid predicate issues
        let descriptor = FetchDescriptor<Trip>()

        do {
            let allTrips = try modelContext.fetch(descriptor)
            let existing = allTrips.filter { $0.id == tripId }

            if let localTrip = existing.first {
                // Update local trip with server data
                localTrip.syncStatus = .synced
                localTrip.lastSyncedAt = Date()
            } else {
                // Create new local trip from server
                let trip = Trip(
                    id: tripId,
                    startLatitude: response.startLatitude,
                    startLongitude: response.startLongitude,
                    startTime: response.startTime,
                    category: TripCategory(rawValue: response.category) ?? .business
                )
                trip.endTime = response.endTime
                trip.endLatitude = response.endLatitude
                trip.endLongitude = response.endLongitude
                trip.startAddress = response.startAddress
                trip.endAddress = response.endAddress
                // Convert miles to meters for storage
                trip.distanceMeters = Int(response.distanceMiles / 0.000621371)
                trip.durationSeconds = response.durationSeconds
                trip.status = TripStatus(rawValue: response.status) ?? .completed
                trip.purpose = response.purpose
                trip.notes = response.notes
                trip.syncStatus = .synced
                trip.lastSyncedAt = Date()

                modelContext.insert(trip)
            }
        } catch {
            AppLogger.data.error("Failed to merge trip: \(error.localizedDescription)")
        }
    }

    // MARK: - Filtering

    private func applyFilters() {
        var result = trips

        // Search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { trip in
                trip.startAddress?.lowercased().contains(query) == true ||
                trip.endAddress?.lowercased().contains(query) == true ||
                trip.purpose?.lowercased().contains(query) == true ||
                trip.notes?.lowercased().contains(query) == true
            }
        }

        // Category filter
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // Vehicle filter
        if let vehicle = selectedVehicle {
            result = result.filter { $0.vehicleId == vehicle.id }
        }

        // Apply sort
        result = sortTrips(result)

        filteredTrips = result
    }

    private func sortTrips(_ trips: [Trip]) -> [Trip] {
        switch sortOrder {
        case .dateDescending:
            return trips.sorted { $0.startTime > $1.startTime }
        case .dateAscending:
            return trips.sorted { $0.startTime < $1.startTime }
        case .distanceDescending:
            return trips.sorted { $0.distanceMiles > $1.distanceMiles }
        case .distanceAscending:
            return trips.sorted { $0.distanceMiles < $1.distanceMiles }
        case .categoryAscending:
            return trips.sorted { $0.category.rawValue < $1.category.rawValue }
        }
    }

    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedVehicle = nil
        sortOrder = .dateDescending
    }

    // MARK: - Actions

    func deleteTrip(_ trip: Trip) async {
        modelContext.delete(trip)

        do {
            try modelContext.save()

            // Delete from server
            if NetworkMonitor.shared.isConnected {
                try await apiClient.requestVoid(TripEndpoints.delete(id: trip.id.uuidString))
            }

            // Remove from lists
            trips.removeAll { $0.id == trip.id }
            applyFilters()
        } catch {
            AppLogger.data.error("Failed to delete trip: \(error.localizedDescription)")
        }
    }

    func classifyTrips(_ tripIds: [UUID], category: TripCategory) async {
        for tripId in tripIds {
            if let trip = trips.first(where: { $0.id == tripId }) {
                trip.category = category
                trip.syncStatus = .pending
            }
        }

        do {
            try modelContext.save()
            applyFilters()

            // Sync to server
            if NetworkMonitor.shared.isConnected {
                let classifications = tripIds.map { TripClassification(tripId: $0.uuidString, category: category.rawValue) }
                try await apiClient.requestVoid(TripEndpoints.batchClassify(classifications: classifications))

                for tripId in tripIds {
                    if let trip = trips.first(where: { $0.id == tripId }) {
                        trip.syncStatus = .synced
                    }
                }
                try modelContext.save()
            }
        } catch {
            AppLogger.data.error("Failed to classify trips: \(error.localizedDescription)")
        }
    }
}
