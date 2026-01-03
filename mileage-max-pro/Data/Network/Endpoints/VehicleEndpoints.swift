//
//  VehicleEndpoints.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation

/// Vehicle-related API endpoints
enum VehicleEndpoints {

    // MARK: - CRUD Operations

    case list
    case get(id: String)
    case create(vehicle: CreateVehicleRequest)
    case update(id: String, vehicle: UpdateVehicleRequest)
    case delete(id: String)

    // MARK: - Vehicle Actions

    case setActive(id: String)
    case updateOdometer(id: String, reading: Double)

    // MARK: - Maintenance

    case listMaintenance(vehicleId: String, pagination: PaginationParameters)
    case addMaintenance(vehicleId: String, record: CreateMaintenanceRequest)
    case updateMaintenance(vehicleId: String, recordId: String, record: UpdateMaintenanceRequest)
    case deleteMaintenance(vehicleId: String, recordId: String)

    // MARK: - Fuel

    case listFuelPurchases(vehicleId: String, pagination: PaginationParameters)
    case addFuelPurchase(vehicleId: String, purchase: CreateFuelPurchaseRequest)
    case deleteFuelPurchase(vehicleId: String, purchaseId: String)
    case fuelEfficiencyStats(vehicleId: String)

    // MARK: - Statistics

    case statistics(vehicleId: String)
}

extension VehicleEndpoints: APIEndpoint {

    var method: HTTPMethod {
        switch self {
        case .list, .get, .listMaintenance, .listFuelPurchases, .fuelEfficiencyStats, .statistics:
            return .get
        case .create, .addMaintenance, .addFuelPurchase:
            return .post
        case .update, .setActive, .updateOdometer, .updateMaintenance:
            return .patch
        case .delete, .deleteMaintenance, .deleteFuelPurchase:
            return .delete
        }
    }

    var path: String {
        let base = APIConstants.Endpoints.Vehicles

        switch self {
        case .list, .create:
            return base
        case .get(let id), .update(let id, _), .delete(let id):
            return "\(base)/\(id)"
        case .setActive(let id):
            return "\(base)/\(id)/set-active"
        case .updateOdometer(let id, _):
            return "\(base)/\(id)/odometer"
        case .listMaintenance(let vehicleId, _), .addMaintenance(let vehicleId, _):
            return "\(base)/\(vehicleId)/maintenance"
        case .updateMaintenance(let vehicleId, let recordId, _), .deleteMaintenance(let vehicleId, let recordId):
            return "\(base)/\(vehicleId)/maintenance/\(recordId)"
        case .listFuelPurchases(let vehicleId, _), .addFuelPurchase(let vehicleId, _):
            return "\(base)/\(vehicleId)/fuel"
        case .deleteFuelPurchase(let vehicleId, let purchaseId):
            return "\(base)/\(vehicleId)/fuel/\(purchaseId)"
        case .fuelEfficiencyStats(let vehicleId):
            return "\(base)/\(vehicleId)/fuel/stats"
        case .statistics(let vehicleId):
            return "\(base)/\(vehicleId)/statistics"
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .listMaintenance(_, let pagination), .listFuelPurchases(_, let pagination):
            return pagination.queryParameters
        default:
            return nil
        }
    }

    var body: Encodable? {
        switch self {
        case .create(let vehicle):
            return vehicle
        case .update(_, let vehicle):
            return vehicle
        case .updateOdometer(_, let reading):
            return OdometerUpdateRequest(odometerReading: reading)
        case .addMaintenance(_, let record):
            return record
        case .updateMaintenance(_, _, let record):
            return record
        case .addFuelPurchase(_, let purchase):
            return purchase
        default:
            return nil
        }
    }
}

// MARK: - Request Models

struct CreateVehicleRequest: Codable {
    let name: String
    let make: String
    let model: String
    let year: Int
    let licensePlate: String?
    let vin: String?
    let color: String?
    let fuelType: String
    let odometerReading: Double?
    let isDefault: Bool?
}

struct UpdateVehicleRequest: Codable {
    let name: String?
    let licensePlate: String?
    let color: String?
    let odometerReading: Double?
    let insuranceProvider: String?
    let insurancePolicyNumber: String?
    let insuranceExpiryDate: Date?
    let registrationExpiryDate: Date?
    let isActive: Bool?
}

struct OdometerUpdateRequest: Codable {
    let odometerReading: Double
}

struct CreateMaintenanceRequest: Codable {
    let type: String
    let description: String?
    let date: Date
    let odometerReading: Double?
    let cost: Double?
    let vendor: String?
    let notes: String?
    let nextServiceDate: Date?
    let nextServiceOdometer: Double?
}

struct UpdateMaintenanceRequest: Codable {
    let description: String?
    let cost: Double?
    let vendor: String?
    let notes: String?
    let nextServiceDate: Date?
    let nextServiceOdometer: Double?
}

struct CreateFuelPurchaseRequest: Codable {
    let date: Date
    let gallons: Double
    let pricePerGallon: Double
    let totalCost: Double
    let odometerReading: Double?
    let stationName: String?
    let stationAddress: String?
    let isFillUp: Bool
    let fuelGrade: String?
    let paymentMethod: String?
    let notes: String?
}

// MARK: - Response Models

struct VehicleResponse: Codable {
    let id: String
    let userId: String
    let name: String
    let make: String
    let model: String
    let year: Int
    let licensePlate: String?
    let vin: String?
    let color: String?
    let fuelType: String
    let odometerReading: Double
    let isActive: Bool
    let insuranceProvider: String?
    let insurancePolicyNumber: String?
    let insuranceExpiryDate: Date?
    let registrationExpiryDate: Date?
    let imageUrl: String?
    let createdAt: Date
    let updatedAt: Date
}

struct MaintenanceRecordResponse: Codable {
    let id: String
    let vehicleId: String
    let type: String
    let description: String?
    let date: Date
    let odometerReading: Double?
    let cost: Double?
    let vendor: String?
    let notes: String?
    let nextServiceDate: Date?
    let nextServiceOdometer: Double?
    let createdAt: Date
}

struct FuelPurchaseResponse: Codable {
    let id: String
    let vehicleId: String
    let date: Date
    let gallons: Double
    let pricePerGallon: Double
    let totalCost: Double
    let odometerReading: Double?
    let stationName: String?
    let stationAddress: String?
    let isFillUp: Bool
    let fuelGrade: String?
    let calculatedMpg: Double?
    let createdAt: Date
}

struct FuelEfficiencyStatsResponse: Codable {
    let averageMpg: Double
    let bestMpg: Double
    let worstMpg: Double
    let totalGallons: Double
    let totalFuelCost: Double
    let averagePricePerGallon: Double
    let monthlyBreakdown: [MonthlyFuelStats]

    struct MonthlyFuelStats: Codable {
        let month: String
        let gallons: Double
        let cost: Double
        let averageMpg: Double
    }
}

struct VehicleStatisticsResponse: Codable {
    let totalMiles: Double
    let totalTrips: Int
    let totalFuelCost: Double
    let totalMaintenanceCost: Double
    let averageMpg: Double
    let costPerMile: Double
    let businessMiles: Double
    let personalMiles: Double
    let upcomingMaintenance: [UpcomingMaintenance]

    struct UpcomingMaintenance: Codable {
        let type: String
        let dueDate: Date?
        let dueOdometer: Double?
        let isOverdue: Bool
    }
}
