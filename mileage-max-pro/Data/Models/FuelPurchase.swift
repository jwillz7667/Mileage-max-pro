//
//  FuelPurchase.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import SwiftData

/// Fuel purchase record model
@Model
final class FuelPurchase {
    // MARK: - Primary Identifiers

    @Attribute(.unique)
    var id: UUID

    // MARK: - Fuel Details

    var fuelTypeRaw: String
    var gallons: Double
    var pricePerGallon: Decimal
    var totalCost: Decimal

    // MARK: - Odometer

    var odometerReading: Int?
    var isFullTank: Bool

    // MARK: - Station

    var stationName: String?
    var stationBrand: String?
    var stationAddress: String?
    var stationLatitude: Double?
    var stationLongitude: Double?

    // MARK: - Calculated

    var mpgCalculated: Double?

    // MARK: - Timestamps

    var createdAt: Date

    // MARK: - Relationships

    var expense: Expense?
    var vehicle: Vehicle?

    // MARK: - Computed Properties

    var fuelType: FuelType {
        get { FuelType(rawValue: fuelTypeRaw) ?? .gasoline }
        set { fuelTypeRaw = newValue.rawValue }
    }

    var formattedGallons: String {
        gallons.formattedGallons
    }

    var formattedPricePerGallon: String {
        pricePerGallon.formattedCurrency
    }

    var formattedTotalCost: String {
        totalCost.formattedCurrency
    }

    var formattedMPG: String? {
        mpgCalculated?.formattedMPG
    }

    var stationDisplayName: String {
        stationName ?? stationBrand ?? "Unknown Station"
    }

    /// CO2 emissions from this fuel purchase in kg
    var carbonEmissions: Double {
        gallons * fuelType.co2PerUnit
    }

    var formattedCarbonEmissions: String {
        carbonEmissions.formattedCO2
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        fuelType: FuelType = .gasoline,
        gallons: Double,
        pricePerGallon: Decimal,
        isFullTank: Bool = true
    ) {
        self.id = id
        self.fuelTypeRaw = fuelType.rawValue
        self.gallons = gallons
        self.pricePerGallon = pricePerGallon
        self.totalCost = Decimal(gallons) * pricePerGallon
        self.odometerReading = nil
        self.isFullTank = isFullTank
        self.stationName = nil
        self.stationBrand = nil
        self.stationAddress = nil
        self.stationLatitude = nil
        self.stationLongitude = nil
        self.mpgCalculated = nil
        self.createdAt = Date()
        self.expense = nil
        self.vehicle = nil
    }

    // MARK: - Methods

    /// Calculate MPG based on previous fill-up
    func calculateMPG(previousOdometer: Int, previousWasFullTank: Bool) -> Double? {
        guard isFullTank,
              previousWasFullTank,
              let currentOdometer = odometerReading,
              currentOdometer > previousOdometer,
              gallons > 0 else {
            return nil
        }

        let milesDriven = currentOdometer - previousOdometer
        let mpg = Double(milesDriven) / gallons
        mpgCalculated = mpg
        return mpg
    }

    /// Set station information
    func setStation(
        name: String?,
        brand: String?,
        address: String?,
        latitude: Double?,
        longitude: Double?
    ) {
        stationName = name
        stationBrand = brand
        stationAddress = address
        stationLatitude = latitude
        stationLongitude = longitude
    }

    /// Create expense from this fuel purchase
    func createExpense() -> Expense {
        let expense = Expense(
            category: .fuel,
            amount: totalCost,
            expenseDate: createdAt
        )
        expense.vendorName = stationDisplayName
        expense.vendorAddress = stationAddress
        expense.vendorLatitude = stationLatitude
        expense.vendorLongitude = stationLongitude
        expense.expenseDescription = "\(formattedGallons) at \(formattedPricePerGallon)/gal"
        expense.isTaxDeductible = true
        expense.vehicle = vehicle
        expense.fuelPurchase = self
        self.expense = expense
        return expense
    }
}

// MARK: - Fuel Purchase DTO

struct FuelPurchaseDTO: Codable, Identifiable, Equatable {
    let id: UUID
    let fuelType: String
    let gallons: Double
    let pricePerGallon: Decimal
    let totalCost: Decimal
    let odometerReading: Int?
    let isFullTank: Bool
    let stationName: String?
    let stationBrand: String?
    let stationAddress: String?
    let stationLatitude: Double?
    let stationLongitude: Double?
    let mpgCalculated: Double?
    let vehicleId: UUID?
    let expenseId: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, gallons
        case fuelType = "fuel_type"
        case pricePerGallon = "price_per_gallon"
        case totalCost = "total_cost"
        case odometerReading = "odometer_reading"
        case isFullTank = "is_full_tank"
        case stationName = "station_name"
        case stationBrand = "station_brand"
        case stationAddress = "station_address"
        case stationLatitude = "station_latitude"
        case stationLongitude = "station_longitude"
        case mpgCalculated = "mpg_calculated"
        case vehicleId = "vehicle_id"
        case expenseId = "expense_id"
        case createdAt = "created_at"
    }

    func toModel() -> FuelPurchase {
        let purchase = FuelPurchase(
            id: id,
            fuelType: FuelType(rawValue: fuelType) ?? .gasoline,
            gallons: gallons,
            pricePerGallon: pricePerGallon,
            isFullTank: isFullTank
        )
        purchase.odometerReading = odometerReading
        purchase.stationName = stationName
        purchase.stationBrand = stationBrand
        purchase.stationAddress = stationAddress
        purchase.stationLatitude = stationLatitude
        purchase.stationLongitude = stationLongitude
        purchase.mpgCalculated = mpgCalculated
        return purchase
    }
}

extension FuelPurchase {
    func toDTO() -> FuelPurchaseDTO {
        FuelPurchaseDTO(
            id: id,
            fuelType: fuelTypeRaw,
            gallons: gallons,
            pricePerGallon: pricePerGallon,
            totalCost: totalCost,
            odometerReading: odometerReading,
            isFullTank: isFullTank,
            stationName: stationName,
            stationBrand: stationBrand,
            stationAddress: stationAddress,
            stationLatitude: stationLatitude,
            stationLongitude: stationLongitude,
            mpgCalculated: mpgCalculated,
            vehicleId: vehicle?.id,
            expenseId: expense?.id,
            createdAt: createdAt
        )
    }
}
