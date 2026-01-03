//
//  ActiveTripViewModel.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import SwiftUI
import CoreLocation
import Combine

/// ViewModel for active trip tracking
@MainActor
final class ActiveTripViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var distanceMiles: Double = 0
    @Published var durationSeconds: Int = 0
    @Published var currentSpeed: Double = 0
    @Published var averageSpeed: Double = 0
    @Published var maxSpeed: Double = 0

    @Published var isPaused: Bool = false
    @Published var pulseAnimation: Bool = false

    @Published var tripCategory: TripCategory = .business
    @Published var tripPurpose: String?
    @Published var tripNotes: String?

    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var startLocation: CLLocationCoordinate2D?
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []

    // MARK: - Computed Properties

    var formattedDuration: String {
        let hours = durationSeconds / 3600
        let minutes = (durationSeconds % 3600) / 60
        let seconds = durationSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var estimatedDeduction: Double {
        let rate = AppConstants.IRSMileageRates.current
        switch tripCategory {
        case .business:
            return distanceMiles * rate.business
        case .medical:
            return distanceMiles * rate.medical
        case .charity:
            return distanceMiles * rate.charity
        default:
            return 0
        }
    }

    // MARK: - Private Properties

    private let locationService = LocationTrackingService.shared
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0
    private var lastPauseStart: Date?

    // MARK: - Initialization

    init() {
        setupBindings()
    }

    private func setupBindings() {
        // Observe location updates
        locationService.$currentLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)

        // Observe current trip
        locationService.$currentTrip
            .receive(on: DispatchQueue.main)
            .sink { [weak self] trip in
                self?.handleTripUpdate(trip)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func startUpdates() {
        // Start timer for duration updates
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateDuration()
            }
        }

        // Start pulse animation
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }

        // Get initial data from location service
        if let trip = locationService.currentTrip {
            startTime = trip.startTime
            startLocation = CLLocationCoordinate2D(
                latitude: trip.startLatitude,
                longitude: trip.startLongitude
            )
            tripCategory = trip.category
            tripPurpose = trip.purpose
        }

        currentLocation = locationService.currentLocation?.coordinate
    }

    func stopUpdates() {
        timer?.invalidate()
        timer = nil
    }

    func togglePause() {
        if isPaused {
            // Resuming
            if let pauseStart = lastPauseStart {
                pausedTime += Date().timeIntervalSince(pauseStart)
            }
            lastPauseStart = nil
            locationService.resumeTracking()
        } else {
            // Pausing
            lastPauseStart = Date()
            locationService.pauseTracking()
        }

        isPaused.toggle()
    }

    func updateCategory() {
        // Update the category in the location service
        if var trip = locationService.currentTrip {
            trip.category = tripCategory
        }
    }

    func updatePurpose() {
        // Update purpose in the location service
        if var trip = locationService.currentTrip {
            trip.purpose = tripPurpose
            trip.notes = tripNotes
        }
    }

    func endTrip() async -> Trip? {
        stopUpdates()

        guard let trip = await locationService.endTrip() else {
            return nil
        }

        // Update with our settings
        trip.category = tripCategory
        trip.purpose = tripPurpose
        trip.notes = tripNotes
        trip.durationSeconds = durationSeconds

        // Encode route as JSON string
        if !routeCoordinates.isEmpty {
            var coordArray = [[Double]]()
            for coord in routeCoordinates {
                coordArray.append([coord.latitude, coord.longitude])
            }
            if let jsonData = try? JSONEncoder().encode(coordArray),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                trip.routePolyline = jsonString
            }
        }

        return trip
    }

    func discardTrip() {
        stopUpdates()
        locationService.cancelTrip()
    }

    // MARK: - Private Methods

    private func handleLocationUpdate(_ location: CLLocation) {
        guard !isPaused else { return }

        let coordinate = location.coordinate
        currentLocation = coordinate

        // Update speed (convert m/s to mph)
        if location.speed >= 0 {
            currentSpeed = location.speed * 2.237
            maxSpeed = max(maxSpeed, currentSpeed)
        }

        // Add to route
        routeCoordinates.append(coordinate)

        // Calculate distance
        if routeCoordinates.count > 1 {
            let lastIndex = routeCoordinates.count - 1
            let lastCoord = routeCoordinates[lastIndex - 1]
            let lastLocation = CLLocation(latitude: lastCoord.latitude, longitude: lastCoord.longitude)
            let currentLoc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

            let distance = currentLoc.distance(from: lastLocation)
            distanceMiles += distance / 1609.34 // Convert meters to miles
        }
    }

    private func handleTripUpdate(_ trip: LocationTrackingService.ActiveTrip?) {
        guard let trip = trip else { return }

        distanceMiles = trip.distanceMiles
        startTime = trip.startTime

        if startLocation == nil {
            startLocation = CLLocationCoordinate2D(
                latitude: trip.startLatitude,
                longitude: trip.startLongitude
            )
        }
    }

    private func updateDuration() {
        guard let start = startTime, !isPaused else { return }

        let elapsed = Date().timeIntervalSince(start)
        durationSeconds = Int(elapsed - pausedTime)

        // Calculate average speed
        if durationSeconds > 0 {
            averageSpeed = (distanceMiles / Double(durationSeconds)) * 3600
        }
    }
}
