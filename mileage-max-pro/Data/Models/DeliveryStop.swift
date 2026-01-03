//
//  DeliveryStop.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import SwiftData
import CoreLocation

/// Delivery stop model for route stops
@Model
final class DeliveryStop {
    // MARK: - Primary Identifiers

    @Attribute(.unique)
    var id: UUID

    // MARK: - Sequence

    var sequenceOriginal: Int
    var sequenceOptimized: Int?

    // MARK: - Status

    var statusRaw: String

    // MARK: - Location

    var address: String
    var latitude: Double
    var longitude: Double

    // MARK: - Recipient

    var recipientName: String?
    var recipientPhone: String?
    var deliveryInstructions: String?

    // MARK: - Time Window

    var timeWindowStart: Date?
    var timeWindowEnd: Date?

    // MARK: - Priority

    var priority: Int

    // MARK: - Timing

    var estimatedArrival: Date?
    var actualArrival: Date?
    var departureTime: Date?

    // MARK: - Service Time

    var serviceDurationSeconds: Int
    var actualServiceDuration: Int?

    // MARK: - Distance

    var distanceFromPrevious: Int?

    // MARK: - Proof of Delivery

    var proofOfDeliveryURL: String?
    var signatureURL: String?
    var deliveryNotes: String?

    // MARK: - Failure

    var failureReasonRaw: String?
    var failureNotes: String?

    // MARK: - Timestamps

    var createdAt: Date
    var updatedAt: Date

    // MARK: - Relationships

    var route: DeliveryRoute?
    var savedLocation: SavedLocation?

    // MARK: - Computed Properties

    var status: StopStatus {
        get { StopStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    var failureReason: DeliveryFailureReason? {
        get {
            guard let raw = failureReasonRaw else { return nil }
            return DeliveryFailureReason(rawValue: raw)
        }
        set { failureReasonRaw = newValue?.rawValue }
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    var displaySequence: Int {
        sequenceOptimized ?? sequenceOriginal
    }

    /// Alias for sequenceOriginal for backward compatibility
    var orderIndex: Int {
        get { sequenceOriginal }
        set { sequenceOriginal = newValue }
    }

    /// Alias for recipientName for backward compatibility
    var name: String? {
        get { recipientName }
        set { recipientName = newValue }
    }

    /// Alias for deliveryNotes for backward compatibility
    var notes: String? {
        get { deliveryNotes }
        set { deliveryNotes = newValue }
    }

    var shortAddress: String {
        let components = address.components(separatedBy: ",")
        return components.first?.trimmingCharacters(in: .whitespaces) ?? address
    }

    var displayName: String {
        recipientName ?? shortAddress
    }

    var hasTimeWindow: Bool {
        timeWindowStart != nil || timeWindowEnd != nil
    }

    var timeWindowDescription: String? {
        guard hasTimeWindow else { return nil }

        let formatter = FormatterCache.shared.timeOnlyFormatter

        if let start = timeWindowStart, let end = timeWindowEnd {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        } else if let start = timeWindowStart {
            return "After \(formatter.string(from: start))"
        } else if let end = timeWindowEnd {
            return "Before \(formatter.string(from: end))"
        }

        return nil
    }

    var isWithinTimeWindow: Bool {
        let now = Date()
        if let start = timeWindowStart, now < start {
            return false
        }
        if let end = timeWindowEnd, now > end {
            return false
        }
        return true
    }

    var isPastTimeWindow: Bool {
        guard let end = timeWindowEnd else { return false }
        return Date() > end
    }

    var estimatedServiceDuration: TimeInterval {
        TimeInterval(serviceDurationSeconds)
    }

    var formattedServiceDuration: String {
        estimatedServiceDuration.compactDuration
    }

    var distanceFromPreviousMiles: Double? {
        distanceFromPrevious.map { Double($0) * 0.000621371 }
    }

    var hasProofOfDelivery: Bool {
        proofOfDeliveryURL != nil || signatureURL != nil
    }

    var isPending: Bool {
        status == .pending
    }

    var isCompleted: Bool {
        status == .completed
    }

    var isFailed: Bool {
        status == .failed
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        sequenceOriginal: Int = 0,
        address: String,
        latitude: Double,
        longitude: Double,
        priority: Int = 5
    ) {
        self.id = id
        self.sequenceOriginal = sequenceOriginal
        self.sequenceOptimized = nil
        self.statusRaw = StopStatus.pending.rawValue
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.recipientName = nil
        self.recipientPhone = nil
        self.deliveryInstructions = nil
        self.timeWindowStart = nil
        self.timeWindowEnd = nil
        self.priority = priority
        self.estimatedArrival = nil
        self.actualArrival = nil
        self.departureTime = nil
        self.serviceDurationSeconds = 300 // Default 5 minutes
        self.actualServiceDuration = nil
        self.distanceFromPrevious = nil
        self.proofOfDeliveryURL = nil
        self.signatureURL = nil
        self.deliveryNotes = nil
        self.failureReasonRaw = nil
        self.failureNotes = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.route = nil
        self.savedLocation = nil
    }

    // MARK: - Methods

    func update() {
        updatedAt = Date()
    }

    func markInTransit() {
        status = .inTransit
        update()
    }

    func markArrived() {
        status = .arrived
        actualArrival = Date()
        update()
    }

    func complete(
        notes: String? = nil,
        proofURL: String? = nil,
        signatureURL: String? = nil
    ) {
        status = .completed
        departureTime = Date()
        deliveryNotes = notes
        proofOfDeliveryURL = proofURL
        self.signatureURL = signatureURL

        if let arrival = actualArrival {
            actualServiceDuration = Int(Date().timeIntervalSince(arrival))
        }

        route?.updateCompletedCount()
        update()
    }

    func fail(reason: DeliveryFailureReason, notes: String? = nil) {
        status = .failed
        failureReason = reason
        failureNotes = notes
        departureTime = Date()
        update()
    }

    func skip(notes: String? = nil) {
        status = .skipped
        failureNotes = notes
        update()
    }

    func setTimeWindow(start: Date?, end: Date?) {
        timeWindowStart = start
        timeWindowEnd = end
        update()
    }

    func setRecipient(name: String?, phone: String?, instructions: String?) {
        recipientName = name
        recipientPhone = phone
        deliveryInstructions = instructions
        update()
    }
}

// MARK: - Stop Status

enum StopStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case inTransit = "in_transit"
    case arrived = "arrived"
    case completed = "completed"
    case failed = "failed"
    case skipped = "skipped"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inTransit: return "In Transit"
        case .arrived: return "Arrived"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .skipped: return "Skipped"
        }
    }

    var iconName: String {
        switch self {
        case .pending: return "clock.fill"
        case .inTransit: return "car.fill"
        case .arrived: return "mappin.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .skipped: return "forward.fill"
        }
    }

    var isTerminal: Bool {
        self == .completed || self == .failed || self == .skipped
    }
}

// MARK: - Delivery Failure Reason

enum DeliveryFailureReason: String, Codable, CaseIterable {
    case notHome = "not_home"
    case wrongAddress = "wrong_address"
    case refused = "refused"
    case damaged = "damaged"
    case other = "other"

    var displayName: String {
        switch self {
        case .notHome: return "Not Home"
        case .wrongAddress: return "Wrong Address"
        case .refused: return "Refused"
        case .damaged: return "Package Damaged"
        case .other: return "Other"
        }
    }
}

// MARK: - Delivery Stop DTO

struct DeliveryStopDTO: Codable, Identifiable, Equatable {
    let id: UUID
    let sequenceOriginal: Int
    let sequenceOptimized: Int?
    let status: String
    let address: String
    let latitude: Double
    let longitude: Double
    let recipientName: String?
    let recipientPhone: String?
    let deliveryInstructions: String?
    let timeWindowStart: Date?
    let timeWindowEnd: Date?
    let priority: Int
    let estimatedArrival: Date?
    let actualArrival: Date?
    let serviceDurationSeconds: Int
    let distanceFromPrevious: Int?
    let proofOfDeliveryURL: String?
    let signatureURL: String?
    let deliveryNotes: String?
    let failureReason: String?
    let failureNotes: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, status, address, latitude, longitude, priority
        case sequenceOriginal = "sequence_original"
        case sequenceOptimized = "sequence_optimized"
        case recipientName = "recipient_name"
        case recipientPhone = "recipient_phone"
        case deliveryInstructions = "delivery_instructions"
        case timeWindowStart = "time_window_start"
        case timeWindowEnd = "time_window_end"
        case estimatedArrival = "estimated_arrival"
        case actualArrival = "actual_arrival"
        case serviceDurationSeconds = "service_duration_seconds"
        case distanceFromPrevious = "distance_from_previous"
        case proofOfDeliveryURL = "proof_of_delivery_url"
        case signatureURL = "signature_url"
        case deliveryNotes = "delivery_notes"
        case failureReason = "failure_reason"
        case failureNotes = "failure_notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toModel() -> DeliveryStop {
        let stop = DeliveryStop(
            id: id,
            sequenceOriginal: sequenceOriginal,
            address: address,
            latitude: latitude,
            longitude: longitude,
            priority: priority
        )
        stop.sequenceOptimized = sequenceOptimized
        stop.statusRaw = status
        stop.recipientName = recipientName
        stop.recipientPhone = recipientPhone
        stop.deliveryInstructions = deliveryInstructions
        stop.timeWindowStart = timeWindowStart
        stop.timeWindowEnd = timeWindowEnd
        stop.estimatedArrival = estimatedArrival
        stop.actualArrival = actualArrival
        stop.serviceDurationSeconds = serviceDurationSeconds
        stop.distanceFromPrevious = distanceFromPrevious
        stop.proofOfDeliveryURL = proofOfDeliveryURL
        stop.signatureURL = signatureURL
        stop.deliveryNotes = deliveryNotes
        stop.failureReasonRaw = failureReason
        stop.failureNotes = failureNotes
        stop.createdAt = createdAt
        stop.updatedAt = updatedAt
        return stop
    }
}

extension DeliveryStop {
    func toDTO() -> DeliveryStopDTO {
        DeliveryStopDTO(
            id: id,
            sequenceOriginal: sequenceOriginal,
            sequenceOptimized: sequenceOptimized,
            status: statusRaw,
            address: address,
            latitude: latitude,
            longitude: longitude,
            recipientName: recipientName,
            recipientPhone: recipientPhone,
            deliveryInstructions: deliveryInstructions,
            timeWindowStart: timeWindowStart,
            timeWindowEnd: timeWindowEnd,
            priority: priority,
            estimatedArrival: estimatedArrival,
            actualArrival: actualArrival,
            serviceDurationSeconds: serviceDurationSeconds,
            distanceFromPrevious: distanceFromPrevious,
            proofOfDeliveryURL: proofOfDeliveryURL,
            signatureURL: signatureURL,
            deliveryNotes: deliveryNotes,
            failureReason: failureReasonRaw,
            failureNotes: failureNotes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Type Alias for RouteStop

/// Alias for backward compatibility with route-based naming
typealias RouteStop = DeliveryStop
