//
//  VehicleMaintenanceRecord.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import SwiftData

/// Vehicle maintenance record model
@Model
final class VehicleMaintenanceRecord {
    // MARK: - Primary Identifiers

    @Attribute(.unique)
    var id: UUID

    // MARK: - Maintenance Details

    var maintenanceTypeRaw: String
    var recordDescription: String?
    var performedAt: Date
    var odometerAtService: Int

    // MARK: - Cost

    var cost: Decimal?
    var currency: String

    // MARK: - Service Provider

    var serviceProvider: String?
    var serviceLocation: String?
    var receiptURL: String?

    // MARK: - Next Service

    var nextServiceDate: Date?
    var nextServiceOdometer: Int?

    // MARK: - Notes

    var notes: String?

    // MARK: - Timestamps

    var createdAt: Date

    // MARK: - Relationships

    var vehicle: Vehicle?

    // MARK: - Computed Properties

    var maintenanceType: MaintenanceType {
        get { MaintenanceType(rawValue: maintenanceTypeRaw) ?? .other }
        set { maintenanceTypeRaw = newValue.rawValue }
    }

    var formattedCost: String? {
        guard let cost = cost else { return nil }
        return cost.formattedCurrency
    }

    /// Alias for performedAt for backward compatibility
    var date: Date {
        get { performedAt }
        set { performedAt = newValue }
    }

    /// Computed vehicleId for predicate compatibility
    var vehicleId: UUID? {
        vehicle?.id
    }

    var isOverdue: Bool {
        if let nextDate = nextServiceDate, nextDate < Date() {
            return true
        }
        if let nextOdometer = nextServiceOdometer,
           let vehicle = vehicle,
           vehicle.odometerReading >= nextOdometer {
            return true
        }
        return false
    }

    var dueDescription: String? {
        var components: [String] = []

        if let nextDate = nextServiceDate {
            let daysUntil = Date().daysBetween(nextDate)
            if daysUntil < 0 {
                components.append("\(abs(daysUntil)) days overdue")
            } else if daysUntil == 0 {
                components.append("Due today")
            } else {
                components.append("Due in \(daysUntil) days")
            }
        }

        if let nextOdometer = nextServiceOdometer, let vehicle = vehicle {
            let milesUntil = nextOdometer - vehicle.odometerReading
            if milesUntil < 0 {
                components.append("\(abs(milesUntil)) miles overdue")
            } else {
                components.append("\(milesUntil) miles until due")
            }
        }

        return components.isEmpty ? nil : components.joined(separator: " or ")
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        maintenanceType: MaintenanceType,
        performedAt: Date = Date(),
        odometerAtService: Int,
        cost: Decimal? = nil,
        currency: String = "USD"
    ) {
        self.id = id
        self.maintenanceTypeRaw = maintenanceType.rawValue
        self.recordDescription = nil
        self.performedAt = performedAt
        self.odometerAtService = odometerAtService
        self.cost = cost
        self.currency = currency
        self.serviceProvider = nil
        self.serviceLocation = nil
        self.receiptURL = nil
        self.nextServiceDate = nil
        self.nextServiceOdometer = nil
        self.notes = nil
        self.createdAt = Date()
        self.vehicle = nil
    }

    // MARK: - Methods

    func setNextService(date: Date?, odometer: Int?) {
        nextServiceDate = date
        nextServiceOdometer = odometer
    }

    /// Calculate default next service based on maintenance type
    func calculateDefaultNextService(currentOdometer: Int) {
        switch maintenanceType {
        case .oilChange:
            nextServiceDate = performedAt.addingMonths(6)
            nextServiceOdometer = odometerAtService + 5000
        case .tireRotation:
            nextServiceDate = performedAt.addingMonths(6)
            nextServiceOdometer = odometerAtService + 7500
        case .airFilter:
            nextServiceDate = performedAt.addingYears(1)
            nextServiceOdometer = odometerAtService + 15000
        case .cabinFilter:
            nextServiceDate = performedAt.addingYears(1)
            nextServiceOdometer = odometerAtService + 15000
        case .brakeService:
            nextServiceDate = performedAt.addingYears(2)
            nextServiceOdometer = odometerAtService + 30000
        case .transmissionService:
            nextServiceDate = performedAt.addingYears(3)
            nextServiceOdometer = odometerAtService + 60000
        case .sparkPlugs:
            nextServiceDate = performedAt.addingYears(3)
            nextServiceOdometer = odometerAtService + 60000
        case .coolantFlush:
            nextServiceDate = performedAt.addingYears(2)
            nextServiceOdometer = odometerAtService + 30000
        case .inspection:
            nextServiceDate = performedAt.addingYears(1)
        case .emissionsTest:
            nextServiceDate = performedAt.addingYears(2)
        default:
            break
        }
    }
}

// MARK: - Maintenance Type

enum MaintenanceType: String, Codable, CaseIterable {
    case oilChange = "oil_change"
    case tireRotation = "tire_rotation"
    case tireReplacement = "tire_replacement"
    case brakeService = "brake_service"
    case brakeReplacement = "brake_replacement"
    case transmissionService = "transmission_service"
    case coolantFlush = "coolant_flush"
    case airFilter = "air_filter"
    case cabinFilter = "cabin_filter"
    case sparkPlugs = "spark_plugs"
    case batteryReplacement = "battery_replacement"
    case wiperBlades = "wiper_blades"
    case alignment = "alignment"
    case suspension = "suspension"
    case inspection = "inspection"
    case emissionsTest = "emissions_test"
    case registrationRenewal = "registration_renewal"
    case insuranceRenewal = "insurance_renewal"
    case carWash = "car_wash"
    case detail = "detail"
    case other = "other"

    var displayName: String {
        switch self {
        case .oilChange: return "Oil Change"
        case .tireRotation: return "Tire Rotation"
        case .tireReplacement: return "Tire Replacement"
        case .brakeService: return "Brake Service"
        case .brakeReplacement: return "Brake Replacement"
        case .transmissionService: return "Transmission Service"
        case .coolantFlush: return "Coolant Flush"
        case .airFilter: return "Air Filter"
        case .cabinFilter: return "Cabin Filter"
        case .sparkPlugs: return "Spark Plugs"
        case .batteryReplacement: return "Battery Replacement"
        case .wiperBlades: return "Wiper Blades"
        case .alignment: return "Alignment"
        case .suspension: return "Suspension"
        case .inspection: return "Inspection"
        case .emissionsTest: return "Emissions Test"
        case .registrationRenewal: return "Registration Renewal"
        case .insuranceRenewal: return "Insurance Renewal"
        case .carWash: return "Car Wash"
        case .detail: return "Detailing"
        case .other: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .oilChange: return "drop.fill"
        case .tireRotation, .tireReplacement: return "circle.grid.2x2.fill"
        case .brakeService, .brakeReplacement: return "brake.fill"
        case .transmissionService: return "gearshape.2.fill"
        case .coolantFlush: return "thermometer.medium"
        case .airFilter, .cabinFilter: return "aqi.medium"
        case .sparkPlugs: return "bolt.fill"
        case .batteryReplacement: return "battery.100"
        case .wiperBlades: return "wiper.rear.and.fluid"
        case .alignment: return "arrow.left.and.right"
        case .suspension: return "suspension"
        case .inspection: return "checkmark.seal.fill"
        case .emissionsTest: return "smoke.fill"
        case .registrationRenewal: return "doc.text.fill"
        case .insuranceRenewal: return "shield.fill"
        case .carWash: return "drop.triangle.fill"
        case .detail: return "sparkles"
        case .other: return "wrench.fill"
        }
    }

    var category: MaintenanceCategory {
        switch self {
        case .oilChange, .airFilter, .cabinFilter, .sparkPlugs, .coolantFlush, .transmissionService:
            return .fluid
        case .tireRotation, .tireReplacement, .alignment:
            return .tires
        case .brakeService, .brakeReplacement:
            return .brakes
        case .batteryReplacement, .wiperBlades, .suspension:
            return .parts
        case .inspection, .emissionsTest, .registrationRenewal, .insuranceRenewal:
            return .compliance
        case .carWash, .detail:
            return .appearance
        case .other:
            return .other
        }
    }

    static var grouped: [(category: MaintenanceCategory, types: [MaintenanceType])] {
        MaintenanceCategory.allCases.map { category in
            (category, Self.allCases.filter { $0.category == category })
        }
    }
}

// MARK: - Maintenance Category

enum MaintenanceCategory: String, CaseIterable {
    case fluid = "Fluids & Filters"
    case tires = "Tires & Wheels"
    case brakes = "Brakes"
    case parts = "Parts & Components"
    case compliance = "Compliance"
    case appearance = "Appearance"
    case other = "Other"

    var iconName: String {
        switch self {
        case .fluid: return "drop.fill"
        case .tires: return "circle.grid.2x2.fill"
        case .brakes: return "brake.fill"
        case .parts: return "wrench.and.screwdriver.fill"
        case .compliance: return "checkmark.seal.fill"
        case .appearance: return "sparkles"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Type Alias

/// Alias for backward compatibility
typealias MaintenanceRecord = VehicleMaintenanceRecord
