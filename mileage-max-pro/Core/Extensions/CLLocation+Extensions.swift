//
//  CLLocation+Extensions.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import CoreLocation
import Foundation

extension CLLocation {

    // MARK: - Distance Formatting

    /// Distance to another location in miles
    func distanceInMiles(from location: CLLocation) -> Double {
        distance(from: location) * 0.000621371
    }

    /// Distance to another location in kilometers
    func distanceInKilometers(from location: CLLocation) -> Double {
        distance(from: location) / 1000
    }

    /// Formatted distance to another location
    func formattedDistance(to location: CLLocation, unit: DistanceUnit = .miles) -> String {
        let distanceMeters = distance(from: location)
        switch unit {
        case .miles:
            return distanceMeters.metersToMiles.formattedMiles
        case .kilometers:
            return distanceMeters.metersToKilometers.formattedKilometers
        }
    }

    // MARK: - Speed Formatting

    /// Speed in miles per hour
    var speedMPH: Double {
        guard speed >= 0 else { return 0 }
        return speed * 2.23694
    }

    /// Speed in kilometers per hour
    var speedKMH: Double {
        guard speed >= 0 else { return 0 }
        return speed * 3.6
    }

    /// Formatted speed string
    var formattedSpeedMPH: String {
        guard speed >= 0 else { return "0 mph" }
        return "\(Int(speedMPH)) mph"
    }

    /// Formatted speed string in km/h
    var formattedSpeedKMH: String {
        guard speed >= 0 else { return "0 km/h" }
        return "\(Int(speedKMH)) km/h"
    }

    // MARK: - Heading Formatting

    /// Heading as cardinal direction
    var cardinalDirection: String {
        guard course >= 0 else { return "N/A" }
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                          "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((course + 11.25) / 22.5) % 16
        return directions[index]
    }

    /// Heading as full cardinal direction name
    var fullCardinalDirection: String {
        guard course >= 0 else { return "Unknown" }
        let directions = ["North", "North-Northeast", "Northeast", "East-Northeast",
                          "East", "East-Southeast", "Southeast", "South-Southeast",
                          "South", "South-Southwest", "Southwest", "West-Southwest",
                          "West", "West-Northwest", "Northwest", "North-Northwest"]
        let index = Int((course + 11.25) / 22.5) % 16
        return directions[index]
    }

    // MARK: - Altitude Formatting

    /// Altitude in feet
    var altitudeFeet: Double {
        altitude * 3.28084
    }

    /// Formatted altitude in meters
    var formattedAltitudeMeters: String {
        "\(Int(altitude)) m"
    }

    /// Formatted altitude in feet
    var formattedAltitudeFeet: String {
        "\(Int(altitudeFeet)) ft"
    }

    // MARK: - Coordinate Formatting

    /// Formatted coordinate string (e.g., "37.7749°N, 122.4194°W")
    var formattedCoordinates: String {
        let latDirection = coordinate.latitude >= 0 ? "N" : "S"
        let lonDirection = coordinate.longitude >= 0 ? "E" : "W"
        let lat = String(format: "%.4f°%@", abs(coordinate.latitude), latDirection)
        let lon = String(format: "%.4f°%@", abs(coordinate.longitude), lonDirection)
        return "\(lat), \(lon)"
    }

    /// Compact coordinate string
    var compactCoordinates: String {
        String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }

    // MARK: - Accuracy Checks

    /// Check if location has acceptable accuracy for trip tracking
    var hasAcceptableAccuracy: Bool {
        horizontalAccuracy >= 0 &&
        horizontalAccuracy <= AppConstants.LocationAccuracy.maximumAcceptableAccuracy
    }

    /// Check if location has precise accuracy
    var hasPreciseAccuracy: Bool {
        horizontalAccuracy >= 0 &&
        horizontalAccuracy <= 10
    }

    /// Check if location is valid (not default/invalid coordinates)
    var isValid: Bool {
        coordinate.latitude != 0 || coordinate.longitude != 0
    }

    /// Accuracy level description
    var accuracyDescription: String {
        guard horizontalAccuracy >= 0 else { return "Unknown" }
        switch horizontalAccuracy {
        case 0..<5: return "Excellent"
        case 5..<10: return "Very Good"
        case 10..<25: return "Good"
        case 25..<50: return "Fair"
        case 50..<100: return "Poor"
        default: return "Very Poor"
        }
    }

    // MARK: - Movement Detection

    /// Check if location represents movement (based on speed)
    var isMoving: Bool {
        speed > AppConstants.TripDetection.minimumDrivingSpeed
    }

    /// Check if location represents driving
    var isDriving: Bool {
        speed > AppConstants.TripDetection.confirmDrivingSpeed
    }

    /// Check if location is stationary
    var isStationary: Bool {
        speed < 0.5 // Less than ~1 mph
    }

    // MARK: - Comparison

    /// Check if location is within radius of another location
    func isWithinRadius(_ radius: CLLocationDistance, of location: CLLocation) -> Bool {
        distance(from: location) <= radius
    }

    /// Check if location is within radius of coordinate
    func isWithinRadius(_ radius: CLLocationDistance, of coordinate: CLLocationCoordinate2D) -> Bool {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return distance(from: location) <= radius
    }

    // MARK: - Bearing Calculation

    /// Calculate bearing to another location in degrees
    func bearing(to location: CLLocation) -> Double {
        let lat1 = coordinate.latitude.degreesToRadians
        let lon1 = coordinate.longitude.degreesToRadians
        let lat2 = location.coordinate.latitude.degreesToRadians
        let lon2 = location.coordinate.longitude.degreesToRadians

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)

        return (radiansBearing.radiansToDegrees + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Calculate bearing as cardinal direction
    func bearingDirection(to location: CLLocation) -> String {
        let bearing = bearing(to: location)
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((bearing + 22.5) / 45) % 8
        return directions[index]
    }
}

// MARK: - CLLocationCoordinate2D Extensions

extension CLLocationCoordinate2D {
    /// Create from latitude and longitude
    init(latitude: Double, longitude: Double) {
        self.init()
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Check if coordinate is valid (not 0,0 or out of range)
    var isValid: Bool {
        (latitude != 0 || longitude != 0) &&
        latitude >= -90 && latitude <= 90 &&
        longitude >= -180 && longitude <= 180
    }

    /// Distance to another coordinate in meters
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: latitude, longitude: longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location1.distance(from: location2)
    }

    /// Distance to another coordinate in miles
    func distanceInMiles(to coordinate: CLLocationCoordinate2D) -> Double {
        distance(to: coordinate) * 0.000621371
    }

    /// Formatted coordinate string
    var formattedString: String {
        let latDirection = latitude >= 0 ? "N" : "S"
        let lonDirection = longitude >= 0 ? "E" : "W"
        return String(format: "%.4f°%@, %.4f°%@",
                      abs(latitude), latDirection,
                      abs(longitude), lonDirection)
    }

    /// Convert to CLLocation
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    /// Calculate midpoint between two coordinates
    func midpoint(to coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let lat1 = latitude.degreesToRadians
        let lon1 = longitude.degreesToRadians
        let lat2 = coordinate.latitude.degreesToRadians
        let lon2 = coordinate.longitude.degreesToRadians

        let dLon = lon2 - lon1

        let bx = cos(lat2) * cos(dLon)
        let by = cos(lat2) * sin(dLon)

        let lat3 = atan2(sin(lat1) + sin(lat2),
                         sqrt((cos(lat1) + bx) * (cos(lat1) + bx) + by * by))
        let lon3 = lon1 + atan2(by, cos(lat1) + bx)

        return CLLocationCoordinate2D(
            latitude: lat3.radiansToDegrees,
            longitude: lon3.radiansToDegrees
        )
    }
}

// MARK: - CLLocationCoordinate2D Equatable

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

// MARK: - CLLocationCoordinate2D Hashable

extension CLLocationCoordinate2D: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}

// MARK: - Degree/Radian Conversion

extension Double {
    /// Convert degrees to radians
    var degreesToRadians: Double {
        self * .pi / 180
    }

    /// Convert radians to degrees
    var radiansToDegrees: Double {
        self * 180 / .pi
    }
}

// MARK: - CLAuthorizationStatus Extensions

extension CLAuthorizationStatus {
    /// Human-readable description
    var description: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When In Use"
        @unknown default: return "Unknown"
        }
    }

    /// Check if location is authorized
    var isAuthorized: Bool {
        self == .authorizedAlways || self == .authorizedWhenInUse
    }

    /// Check if background location is authorized
    var isBackgroundAuthorized: Bool {
        self == .authorizedAlways
    }
}

// MARK: - CLAccuracyAuthorization Extensions

extension CLAccuracyAuthorization {
    /// Human-readable description
    var description: String {
        switch self {
        case .fullAccuracy: return "Full Accuracy"
        case .reducedAccuracy: return "Reduced Accuracy"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Region Helpers

extension CLCircularRegion {
    /// Create from saved location
    convenience init(
        center: CLLocationCoordinate2D,
        radius: CLLocationDistance,
        identifier: String
    ) {
        self.init(center: center, radius: radius, identifier: identifier)
        self.notifyOnEntry = true
        self.notifyOnExit = true
    }
}
