//
//  TripWaypoint.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import SwiftData
import CoreLocation

/// Trip waypoint model - GPS breadcrumb for trip routes
@Model
final class TripWaypoint {
    // MARK: - Primary Identifiers

    @Attribute(.unique)
    var id: UUID

    // MARK: - Sequence

    var sequenceNumber: Int

    // MARK: - Location Data

    var latitude: Double
    var longitude: Double
    var altitudeMeters: Double?

    // MARK: - Accuracy

    var horizontalAccuracy: Double?
    var verticalAccuracy: Double?

    // MARK: - Motion Data

    var speedMPS: Double?
    var heading: Double?

    // MARK: - Timing

    var timestamp: Date

    // MARK: - Stop Detection

    var isStop: Bool
    var stopDurationSeconds: Int?

    // MARK: - Timestamps

    var createdAt: Date

    // MARK: - Relationships

    var trip: Trip?

    // MARK: - Computed Properties

    /// Coordinate as CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Location as CLLocation
    var location: CLLocation {
        CLLocation(
            coordinate: coordinate,
            altitude: altitudeMeters ?? 0,
            horizontalAccuracy: horizontalAccuracy ?? -1,
            verticalAccuracy: verticalAccuracy ?? -1,
            course: heading ?? -1,
            speed: speedMPS ?? -1,
            timestamp: timestamp
        )
    }

    /// Speed in miles per hour
    var speedMPH: Double? {
        guard let mps = speedMPS, mps >= 0 else { return nil }
        return mps * 2.23694
    }

    /// Formatted speed string
    var formattedSpeed: String? {
        guard let mph = speedMPH else { return nil }
        return "\(Int(mph)) mph"
    }

    /// Altitude in feet
    var altitudeFeet: Double? {
        altitudeMeters.map { $0 * 3.28084 }
    }

    /// Cardinal direction from heading
    var cardinalDirection: String? {
        guard let heading = heading, heading >= 0 else { return nil }
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                          "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((heading + 11.25) / 22.5) % 16
        return directions[index]
    }

    /// Check if waypoint has acceptable accuracy
    var hasAcceptableAccuracy: Bool {
        guard let accuracy = horizontalAccuracy else { return false }
        return accuracy >= 0 && accuracy <= AppConstants.LocationAccuracy.maximumAcceptableAccuracy
    }

    /// Stop duration as TimeInterval
    var stopDuration: TimeInterval? {
        stopDurationSeconds.map { TimeInterval($0) }
    }

    /// Formatted stop duration
    var formattedStopDuration: String? {
        stopDuration?.compactDuration
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        sequenceNumber: Int = 0,
        latitude: Double,
        longitude: Double,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.sequenceNumber = sequenceNumber
        self.latitude = latitude
        self.longitude = longitude
        self.altitudeMeters = nil
        self.horizontalAccuracy = nil
        self.verticalAccuracy = nil
        self.speedMPS = nil
        self.heading = nil
        self.timestamp = timestamp
        self.isStop = false
        self.stopDurationSeconds = nil
        self.createdAt = Date()
        self.trip = nil
    }

    /// Initialize from CLLocation
    convenience init(
        from location: CLLocation,
        sequenceNumber: Int = 0
    ) {
        self.init(
            sequenceNumber: sequenceNumber,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timestamp: location.timestamp
        )

        self.altitudeMeters = location.altitude
        self.horizontalAccuracy = location.horizontalAccuracy >= 0 ? location.horizontalAccuracy : nil
        self.verticalAccuracy = location.verticalAccuracy >= 0 ? location.verticalAccuracy : nil
        self.speedMPS = location.speed >= 0 ? location.speed : nil
        self.heading = location.course >= 0 ? location.course : nil
    }

    // MARK: - Methods

    /// Calculate distance to another waypoint
    func distance(to waypoint: TripWaypoint) -> CLLocationDistance {
        location.distance(from: waypoint.location)
    }

    /// Calculate bearing to another waypoint
    func bearing(to waypoint: TripWaypoint) -> Double {
        location.bearing(to: waypoint.location)
    }

    /// Mark as stop
    func markAsStop(duration: TimeInterval) {
        isStop = true
        stopDurationSeconds = Int(duration)
    }

    /// Calculate time interval to next waypoint
    func timeInterval(to waypoint: TripWaypoint) -> TimeInterval {
        waypoint.timestamp.timeIntervalSince(timestamp)
    }
}

// MARK: - Waypoint DTO

struct TripWaypointDTO: Codable, Identifiable, Equatable {
    let id: UUID
    let sequenceNumber: Int
    let latitude: Double
    let longitude: Double
    let altitudeMeters: Double?
    let horizontalAccuracy: Double?
    let verticalAccuracy: Double?
    let speedMPS: Double?
    let heading: Double?
    let timestamp: Date
    let isStop: Bool
    let stopDurationSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case id, latitude, longitude, timestamp
        case sequenceNumber = "sequence_number"
        case altitudeMeters = "altitude_meters"
        case horizontalAccuracy = "horizontal_accuracy"
        case verticalAccuracy = "vertical_accuracy"
        case speedMPS = "speed_mps"
        case heading
        case isStop = "is_stop"
        case stopDurationSeconds = "stop_duration_seconds"
    }

    func toModel() -> TripWaypoint {
        let waypoint = TripWaypoint(
            id: id,
            sequenceNumber: sequenceNumber,
            latitude: latitude,
            longitude: longitude,
            timestamp: timestamp
        )
        waypoint.altitudeMeters = altitudeMeters
        waypoint.horizontalAccuracy = horizontalAccuracy
        waypoint.verticalAccuracy = verticalAccuracy
        waypoint.speedMPS = speedMPS
        waypoint.heading = heading
        waypoint.isStop = isStop
        waypoint.stopDurationSeconds = stopDurationSeconds
        return waypoint
    }
}

extension TripWaypoint {
    func toDTO() -> TripWaypointDTO {
        TripWaypointDTO(
            id: id,
            sequenceNumber: sequenceNumber,
            latitude: latitude,
            longitude: longitude,
            altitudeMeters: altitudeMeters,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            speedMPS: speedMPS,
            heading: heading,
            timestamp: timestamp,
            isStop: isStop,
            stopDurationSeconds: stopDurationSeconds
        )
    }
}

// MARK: - Waypoint Batch Upload

struct WaypointBatchDTO: Codable {
    let tripId: UUID
    let waypoints: [TripWaypointDTO]

    enum CodingKeys: String, CodingKey {
        case tripId = "trip_id"
        case waypoints
    }
}

// MARK: - Polyline Encoding

extension Array where Element == TripWaypoint {
    /// Encode waypoints to polyline string
    func encodeToPolyline() -> String {
        var encoded = ""
        var previousLatitude = 0
        var previousLongitude = 0

        for waypoint in self {
            let latitude = Int(round(waypoint.latitude * 1e5))
            let longitude = Int(round(waypoint.longitude * 1e5))

            let deltaLatitude = latitude - previousLatitude
            let deltaLongitude = longitude - previousLongitude

            encoded += encodeSignedNumber(deltaLatitude)
            encoded += encodeSignedNumber(deltaLongitude)

            previousLatitude = latitude
            previousLongitude = longitude
        }

        return encoded
    }

    private func encodeSignedNumber(_ number: Int) -> String {
        var num = number < 0 ? ~(number << 1) : (number << 1)
        var encoded = ""

        while num >= 0x20 {
            encoded += String(UnicodeScalar((0x20 | (num & 0x1f)) + 63)!)
            num >>= 5
        }

        encoded += String(UnicodeScalar(num + 63)!)
        return encoded
    }
}

extension String {
    /// Decode polyline string to coordinates
    func decodePolyline() -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        var index = startIndex
        var latitude = 0
        var longitude = 0

        while index < endIndex {
            var result = 0
            var shift = 0
            var byte: Int

            repeat {
                byte = Int(self[index].asciiValue! - 63)
                result |= (byte & 0x1f) << shift
                shift += 5
                index = self.index(after: index)
            } while byte >= 0x20 && index < endIndex

            let deltaLatitude = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1)
            latitude += deltaLatitude

            if index >= endIndex { break }

            result = 0
            shift = 0

            repeat {
                byte = Int(self[index].asciiValue! - 63)
                result |= (byte & 0x1f) << shift
                shift += 5
                index = self.index(after: index)
            } while byte >= 0x20 && index < endIndex

            let deltaLongitude = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1)
            longitude += deltaLongitude

            let coordinate = CLLocationCoordinate2D(
                latitude: Double(latitude) / 1e5,
                longitude: Double(longitude) / 1e5
            )
            coordinates.append(coordinate)
        }

        return coordinates
    }
}
