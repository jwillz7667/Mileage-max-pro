//
//  Vehicle.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import SwiftData

/// Vehicle model for MileageMax Pro
@Model
final class Vehicle {
    // MARK: - Primary Identifiers

    @Attribute(.unique)
    var id: UUID

    // MARK: - Basic Information

    var nickname: String
    var make: String
    var model: String
    var year: Int
    var color: String?

    // MARK: - Registration

    var licensePlate: String?
    var licenseState: String?
    var vin: String?

    // MARK: - Fuel Configuration

    var fuelTypeRaw: String
    var fuelEconomyCity: Double?
    var fuelEconomyHighway: Double?
    var fuelTankCapacity: Double?

    // MARK: - Odometer

    var odometerReading: Int
    var odometerUnitRaw: String
    var odometerUpdatedAt: Date?

    // MARK: - Status

    var isPrimary: Bool
    var isActive: Bool
    var photoURL: String?

    // MARK: - Insurance

    var insuranceProvider: String?
    var insurancePolicyNumber: String?
    var insuranceExpiresAt: Date?

    // MARK: - Registration

    var registrationExpiresAt: Date?

    // MARK: - Timestamps

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    // MARK: - Relationships

    var user: User?

    @Relationship(deleteRule: .nullify, inverse: \Trip.vehicle)
    var trips: [Trip]

    @Relationship(deleteRule: .cascade, inverse: \VehicleMaintenanceRecord.vehicle)
    var maintenanceRecords: [VehicleMaintenanceRecord]

    @Relationship(deleteRule: .nullify, inverse: \Expense.vehicle)
    var expenses: [Expense]

    @Relationship(deleteRule: .cascade, inverse: \FuelPurchase.vehicle)
    var fuelPurchases: [FuelPurchase]

    // MARK: - Computed Properties

    var fuelType: FuelType {
        get { FuelType(rawValue: fuelTypeRaw) ?? .gasoline }
        set { fuelTypeRaw = newValue.rawValue }
    }

    var odometerUnit: DistanceUnit {
        get { DistanceUnit(rawValue: odometerUnitRaw) ?? .miles }
        set { odometerUnitRaw = newValue.rawValue }
    }

    /// Alias for nickname for backward compatibility
    var name: String {
        get { nickname }
        set { nickname = newValue }
    }

    /// Alias for odometerReading for backward compatibility
    var currentOdometer: Int {
        get { odometerReading }
        set { odometerReading = newValue }
    }

    /// Alias for isPrimary for backward compatibility
    var isDefault: Bool {
        get { isPrimary }
        set { isPrimary = newValue }
    }

    var syncStatus: SyncStatus {
        get { .synced }
        set { /* Not persisted */ }
    }

    var lastSyncedAt: Date? {
        updatedAt
    }

    var displayName: String {
        nickname.isEmpty ? "\(year) \(make) \(model)" : nickname
    }

    var fullName: String {
        "\(year) \(make) \(model)"
    }

    var combinedFuelEconomy: Double? {
        guard let city = fuelEconomyCity, let highway = fuelEconomyHighway else {
            return fuelEconomyCity ?? fuelEconomyHighway
        }
        // EPA combined formula: 1/((0.55/city) + (0.45/highway))
        return 1.0 / ((0.55 / city) + (0.45 / highway))
    }

    var totalMiles: Double {
        trips.reduce(0) { $0 + $1.distanceMiles }
    }

    var totalTrips: Int {
        trips.count
    }

    var averageTripDistance: Double {
        guard totalTrips > 0 else { return 0 }
        return totalMiles / Double(totalTrips)
    }

    var totalFuelCost: Decimal {
        fuelPurchases.reduce(0) { $0 + $1.totalCost }
    }

    var insuranceExpiresSoon: Bool {
        guard let expiresAt = insuranceExpiresAt else { return false }
        return expiresAt < Date().addingDays(30)
    }

    var registrationExpiresSoon: Bool {
        guard let expiresAt = registrationExpiresAt else { return false }
        return expiresAt < Date().addingDays(30)
    }

    var isElectric: Bool {
        fuelType == .electric
    }

    var needsOilChange: Bool {
        guard !isElectric else { return false }
        // Check if it's been more than 5000 miles since last oil change
        let lastOilChange = maintenanceRecords
            .filter { $0.maintenanceType == .oilChange }
            .max(by: { $0.performedAt < $1.performedAt })

        guard let lastChange = lastOilChange else { return true }
        let milesSinceChange = odometerReading - lastChange.odometerAtService
        return milesSinceChange >= 5000
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        nickname: String,
        make: String,
        model: String,
        year: Int,
        fuelType: FuelType = .gasoline
    ) {
        self.id = id
        self.nickname = nickname
        self.make = make
        self.model = model
        self.year = year
        self.color = nil
        self.licensePlate = nil
        self.licenseState = nil
        self.vin = nil
        self.fuelTypeRaw = fuelType.rawValue
        self.fuelEconomyCity = nil
        self.fuelEconomyHighway = nil
        self.fuelTankCapacity = nil
        self.odometerReading = 0
        self.odometerUnitRaw = DistanceUnit.miles.rawValue
        self.odometerUpdatedAt = nil
        self.isPrimary = false
        self.isActive = true
        self.photoURL = nil
        self.insuranceProvider = nil
        self.insurancePolicyNumber = nil
        self.insuranceExpiresAt = nil
        self.registrationExpiresAt = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil
        self.user = nil
        self.trips = []
        self.maintenanceRecords = []
        self.expenses = []
        self.fuelPurchases = []
    }

    // MARK: - Methods

    func update() {
        updatedAt = Date()
    }

    func updateOdometer(_ reading: Int) {
        odometerReading = reading
        odometerUpdatedAt = Date()
        update()
    }

    func softDelete() {
        isActive = false
        deletedAt = Date()
        update()
    }

    func makePrimary() {
        // This should be called in context where other vehicles are un-primaried
        isPrimary = true
        update()
    }

    func calculateFuelCostPerMile() -> Decimal? {
        guard totalMiles > 0, totalFuelCost > 0 else { return nil }
        return totalFuelCost / Decimal(totalMiles)
    }
}

// MARK: - Fuel Type

enum FuelType: String, Codable, CaseIterable {
    case gasoline = "gasoline"
    case diesel = "diesel"
    case electric = "electric"
    case hybrid = "hybrid"
    case pluginHybrid = "plugin_hybrid"

    var displayName: String {
        switch self {
        case .gasoline: return "Gasoline"
        case .diesel: return "Diesel"
        case .electric: return "Electric"
        case .hybrid: return "Hybrid"
        case .pluginHybrid: return "Plug-in Hybrid"
        }
    }

    var iconName: String {
        switch self {
        case .gasoline: return "fuelpump.fill"
        case .diesel: return "fuelpump.fill"
        case .electric: return "bolt.car.fill"
        case .hybrid: return "leaf.arrow.circlepath"
        case .pluginHybrid: return "bolt.fill"
        }
    }

    /// CO2 emissions per gallon/kWh in kg
    var co2PerUnit: Double {
        switch self {
        case .gasoline: return 8.887 // kg CO2 per gallon
        case .diesel: return 10.180 // kg CO2 per gallon
        case .electric: return 0.4 // kg CO2 per kWh (US average grid)
        case .hybrid: return 6.0 // Estimated average
        case .pluginHybrid: return 4.0 // Estimated average
        }
    }
}

// MARK: - Vehicle DTO

struct VehicleDTO: Codable, Identifiable, Equatable {
    let id: UUID
    let nickname: String
    let make: String
    let model: String
    let year: Int
    let color: String?
    let licensePlate: String?
    let licenseState: String?
    let vin: String?
    let fuelType: String
    let fuelEconomyCity: Double?
    let fuelEconomyHighway: Double?
    let fuelTankCapacity: Double?
    let odometerReading: Int
    let odometerUnit: String
    let isPrimary: Bool
    let isActive: Bool
    let photoURL: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, nickname, make, model, year, color, vin
        case licensePlate = "license_plate"
        case licenseState = "license_state"
        case fuelType = "fuel_type"
        case fuelEconomyCity = "fuel_economy_city"
        case fuelEconomyHighway = "fuel_economy_highway"
        case fuelTankCapacity = "fuel_tank_capacity"
        case odometerReading = "odometer_reading"
        case odometerUnit = "odometer_unit"
        case isPrimary = "is_primary"
        case isActive = "is_active"
        case photoURL = "photo_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toModel() -> Vehicle {
        let vehicle = Vehicle(
            id: id,
            nickname: nickname,
            make: make,
            model: model,
            year: year,
            fuelType: FuelType(rawValue: fuelType) ?? .gasoline
        )
        vehicle.color = color
        vehicle.licensePlate = licensePlate
        vehicle.licenseState = licenseState
        vehicle.vin = vin
        vehicle.fuelEconomyCity = fuelEconomyCity
        vehicle.fuelEconomyHighway = fuelEconomyHighway
        vehicle.fuelTankCapacity = fuelTankCapacity
        vehicle.odometerReading = odometerReading
        vehicle.odometerUnitRaw = odometerUnit
        vehicle.isPrimary = isPrimary
        vehicle.isActive = isActive
        vehicle.photoURL = photoURL
        vehicle.createdAt = createdAt
        vehicle.updatedAt = updatedAt
        return vehicle
    }
}

extension Vehicle {
    func toDTO() -> VehicleDTO {
        VehicleDTO(
            id: id,
            nickname: nickname,
            make: make,
            model: model,
            year: year,
            color: color,
            licensePlate: licensePlate,
            licenseState: licenseState,
            vin: vin,
            fuelType: fuelTypeRaw,
            fuelEconomyCity: fuelEconomyCity,
            fuelEconomyHighway: fuelEconomyHighway,
            fuelTankCapacity: fuelTankCapacity,
            odometerReading: odometerReading,
            odometerUnit: odometerUnitRaw,
            isPrimary: isPrimary,
            isActive: isActive,
            photoURL: photoURL,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
