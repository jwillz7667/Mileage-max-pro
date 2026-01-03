//
//  LocationTrackingService.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import CoreLocation
import Combine
import SwiftUI
import os

/// Manages location tracking for trip detection and recording
@MainActor
final class LocationTrackingService: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = LocationTrackingService()

    // MARK: - Published Properties

    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var trackingState: TrackingState = .idle
    @Published private(set) var currentTrip: ActiveTrip?
    @Published private(set) var speed: CLLocationSpeed = 0
    @Published private(set) var heading: CLLocationDirection = 0

    // MARK: - Properties

    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()

    private var waypointBuffer: [TripWaypoint] = []
    private var lastWaypointTime: Date?
    private var tripStartLocation: CLLocation?
    private var tripDistance: CLLocationDistance = 0
    private var lastLocation: CLLocation?

    // Trip detection
    private var movementDetectionTimer: Timer?
    private var stationaryDuration: TimeInterval = 0
    private var lastMovementTime: Date?

    // Configuration
    private let waypointInterval: TimeInterval = 5.0 // Seconds between waypoints
    private let minDistanceFilter: CLLocationDistance = 10 // Meters
    private let significantSpeedThreshold: CLLocationSpeed = AppConstants.TripDetection.minimumDrivingSpeed

    // MARK: - Tracking State

    enum TrackingState: Equatable {
        case idle
        case monitoring
        case tracking
        case paused
        case error(String)

        var isActive: Bool {
            switch self {
            case .monitoring, .tracking:
                return true
            default:
                return false
            }
        }
    }

    // MARK: - Active Trip

    struct ActiveTrip {
        let id: UUID
        let vehicleId: UUID
        let startTime: Date
        let startLocation: CLLocation
        let startAddress: String?
        var waypoints: [TripWaypoint]
        var distance: CLLocationDistance
        var currentLocation: CLLocation?
        var category: TripCategory
        var purpose: String?
        var notes: String?

        var durationSeconds: Int {
            Int(Date().timeIntervalSince(startTime))
        }

        var distanceMiles: Double {
            distance * 0.000621371
        }

        var averageSpeedMph: Double {
            guard durationSeconds > 0 else { return 0 }
            return distanceMiles / (Double(durationSeconds) / 3600)
        }

        var startLatitude: Double {
            startLocation.coordinate.latitude
        }

        var startLongitude: Double {
            startLocation.coordinate.longitude
        }
    }

    // MARK: - Initialization

    private override init() {
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = minDistanceFilter
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .automotiveNavigation

        authorizationStatus = locationManager.authorizationStatus
        updateBackgroundLocationMode()
    }

    private func updateBackgroundLocationMode() {
        // Only enable background location updates when user has granted "Always" permission
        // Setting this without proper authorization or background mode capability will crash
        if authorizationStatus == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = true
        }
    }

    // MARK: - Authorization

    func requestAuthorization() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        default:
            break
        }
    }

    var hasFullAuthorization: Bool {
        authorizationStatus == .authorizedAlways
    }

    var hasAnyAuthorization: Bool {
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
    }

    // MARK: - Tracking Control

    func startMonitoring() {
        guard hasAnyAuthorization else {
            trackingState = .error("Location permission required")
            return
        }

        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()

        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }

        trackingState = .monitoring
        startMovementDetection()

        AppLogger.location.info("Started monitoring")
    }

    func stopMonitoring() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.stopUpdatingHeading()

        stopMovementDetection()
        trackingState = .idle

        AppLogger.location.info("Stopped monitoring")
    }

    func startTrip(vehicleId: UUID, startAddress: String? = nil) {
        guard let location = currentLocation else {
            trackingState = .error("Unable to determine current location")
            return
        }

        let trip = ActiveTrip(
            id: UUID(),
            vehicleId: vehicleId,
            startTime: Date(),
            startLocation: location,
            startAddress: startAddress,
            waypoints: [],
            distance: 0,
            currentLocation: location,
            category: .business,
            purpose: nil,
            notes: nil
        )

        currentTrip = trip
        tripStartLocation = location
        tripDistance = 0
        lastLocation = location
        waypointBuffer = []
        lastWaypointTime = Date()

        // Increase accuracy during active trip
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5

        trackingState = .tracking
        HapticManager.shared.tripStart()

        AppLogger.trip.info("Trip started: \(trip.id)")
    }

    func endTrip() async -> Trip? {
        guard let activeTrip = currentTrip else { return nil }

        // Finalize waypoints
        if let lastLoc = currentLocation {
            addWaypoint(from: lastLoc)
        }

        // Create Trip model
        let trip = createTripFromActive(activeTrip)

        // Reset state
        currentTrip = nil
        tripStartLocation = nil
        tripDistance = 0
        lastLocation = nil
        waypointBuffer = []

        // Reduce accuracy to save battery
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = minDistanceFilter

        trackingState = .monitoring
        HapticManager.shared.tripEnd()

        AppLogger.trip.info("Trip ended: \(activeTrip.id), distance: \(activeTrip.distanceMiles) miles")

        return trip
    }

    func pauseTrip() {
        guard trackingState == .tracking else { return }
        trackingState = .paused

        // Reduce accuracy during pause
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 50

        AppLogger.location.info("Trip paused")
    }

    func resumeTrip() {
        guard trackingState == .paused else { return }
        trackingState = .tracking

        // Restore high accuracy
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5

        AppLogger.location.info("Trip resumed")
    }

    /// Alias for pauseTrip for backward compatibility
    func pauseTracking() {
        pauseTrip()
    }

    /// Alias for resumeTrip for backward compatibility
    func resumeTracking() {
        resumeTrip()
    }

    func cancelTrip() {
        currentTrip = nil
        tripStartLocation = nil
        tripDistance = 0
        lastLocation = nil
        waypointBuffer = []

        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = minDistanceFilter

        trackingState = .monitoring

        AppLogger.location.info("Trip cancelled")
    }

    // MARK: - Waypoint Management

    private func addWaypoint(from location: CLLocation) {
        let waypoint = TripWaypoint(
            from: location,
            sequenceNumber: waypointBuffer.count
        )

        waypointBuffer.append(waypoint)

        // Update current trip
        if var trip = currentTrip {
            trip.waypoints = waypointBuffer
            trip.currentLocation = location
            trip.distance = tripDistance
            currentTrip = trip
        }
    }

    // MARK: - Movement Detection

    private func startMovementDetection() {
        movementDetectionTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkMovementStatus()
            }
        }
    }

    private func stopMovementDetection() {
        movementDetectionTimer?.invalidate()
        movementDetectionTimer = nil
    }

    private func checkMovementStatus() {
        guard trackingState == .monitoring else { return }

        // Auto-detect trip start based on speed
        if speed > significantSpeedThreshold {
            if lastMovementTime == nil {
                lastMovementTime = Date()
            } else if let movementStart = lastMovementTime,
                      Date().timeIntervalSince(movementStart) > AppConstants.TripDetection.speedConfirmationDuration {
                // Auto-start trip detection triggered
                // Note: In a real app, this would prompt the user or use default vehicle
                AppLogger.location.info("Movement detected - auto-trip candidate")
            }
        } else {
            lastMovementTime = nil
        }

        // Auto-detect trip end based on stationary time
        if trackingState == .tracking && speed < 1.0 {
            stationaryDuration += 10
            if stationaryDuration > AppConstants.TripDetection.defaultStopDetectionDelay {
                AppLogger.location.info("Stationary detected - auto-end candidate")
                // Note: In a real app, this would prompt the user
            }
        } else {
            stationaryDuration = 0
        }
    }

    // MARK: - Trip Creation

    private func createTripFromActive(_ activeTrip: ActiveTrip) -> Trip {
        let trip = Trip(
            id: activeTrip.id,
            startLatitude: activeTrip.startLocation.coordinate.latitude,
            startLongitude: activeTrip.startLocation.coordinate.longitude,
            startTime: activeTrip.startTime,
            category: activeTrip.category,
            detectionMethod: .manual
        )

        trip.startAddress = activeTrip.startAddress
        trip.endTime = Date()

        if let endLocation = currentLocation {
            trip.endLatitude = endLocation.coordinate.latitude
            trip.endLongitude = endLocation.coordinate.longitude
        }

        trip.distanceMeters = Int(activeTrip.distance) // distance is in meters
        trip.durationSeconds = activeTrip.durationSeconds
        trip.status = .completed
        trip.purpose = activeTrip.purpose
        trip.notes = activeTrip.notes

        // Calculate stats from waypoints
        if !waypointBuffer.isEmpty {
            let speeds = waypointBuffer.compactMap { $0.speedMPS }.filter { $0 > 0 }
            if !speeds.isEmpty {
                trip.avgSpeedMPH = speeds.reduce(0, +) / Double(speeds.count) * 2.23694
                trip.maxSpeedMPH = (speeds.max() ?? 0) * 2.23694
            }

            // Encode route polyline
            trip.routePolyline = encodePolyline(waypointBuffer)
        }

        // Add waypoints
        for waypoint in waypointBuffer {
            waypoint.trip = trip
        }
        trip.waypoints = waypointBuffer

        return trip
    }

    private func encodePolyline(_ waypoints: [TripWaypoint]) -> String {
        // Simplified polyline encoding
        var encoded = ""
        var lastLat = 0
        var lastLng = 0

        for waypoint in waypoints {
            let lat = Int(round(waypoint.latitude * 1e5))
            let lng = Int(round(waypoint.longitude * 1e5))

            encoded += encodeNumber(lat - lastLat)
            encoded += encodeNumber(lng - lastLng)

            lastLat = lat
            lastLng = lng
        }

        return encoded
    }

    private func encodeNumber(_ num: Int) -> String {
        var n = num < 0 ? ~(num << 1) : (num << 1)
        var result = ""

        while n >= 0x20 {
            result += String(UnicodeScalar((0x20 | (n & 0x1f)) + 63)!)
            n >>= 5
        }
        result += String(UnicodeScalar(n + 63)!)

        return result
    }

    // MARK: - Geocoding

    func reverseGeocode(location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }

            var components: [String] = []
            if let name = placemark.name {
                components.append(name)
            }
            if let locality = placemark.locality {
                components.append(locality)
            }
            if let administrativeArea = placemark.administrativeArea {
                components.append(administrativeArea)
            }

            return components.joined(separator: ", ")
        } catch {
            AppLogger.location.error("Geocoding failed: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationTrackingService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            handleLocationUpdate(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus

            switch authorizationStatus {
            case .authorizedAlways:
                updateBackgroundLocationMode()
                if trackingState == .error("Location permission required") {
                    trackingState = .idle
                }
            case .authorizedWhenInUse:
                if trackingState == .error("Location permission required") {
                    trackingState = .idle
                }
            case .denied, .restricted:
                trackingState = .error("Location access denied")
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            AppLogger.location.error("Location error: \(error.localizedDescription)")

            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    trackingState = .error("Location access denied")
                case .locationUnknown:
                    // Temporary error, keep trying
                    break
                default:
                    trackingState = .error(error.localizedDescription)
                }
            }
        }
    }

    @MainActor
    private func handleLocationUpdate(_ location: CLLocation) {
        // Filter out inaccurate readings
        guard location.horizontalAccuracy >= 0,
              location.horizontalAccuracy < 100 else {
            return
        }

        currentLocation = location
        speed = max(0, location.speed)

        // Update trip if tracking
        if trackingState == .tracking, let last = lastLocation {
            let distance = location.distance(from: last)
            tripDistance += distance

            // Add waypoint at intervals
            if let lastTime = lastWaypointTime,
               Date().timeIntervalSince(lastTime) >= waypointInterval {
                addWaypoint(from: location)
                lastWaypointTime = Date()
            }
        }

        lastLocation = location
    }
}

// MARK: - Environment Key

private struct LocationTrackingServiceKey: EnvironmentKey {
    static let defaultValue: LocationTrackingService = .shared
}

extension EnvironmentValues {
    var locationService: LocationTrackingService {
        get { self[LocationTrackingServiceKey.self] }
        set { self[LocationTrackingServiceKey.self] = newValue }
    }
}
