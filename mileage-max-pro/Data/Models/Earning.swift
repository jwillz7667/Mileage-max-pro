//
//  Earning.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import SwiftData

/// Earnings model for gig economy income tracking
@Model
final class Earning {
    // MARK: - Primary Identifiers

    @Attribute(.unique)
    var id: UUID

    // MARK: - Platform

    var platformRaw: String
    var platformOther: String?

    // MARK: - Date

    var earningsDate: Date

    // MARK: - Amounts

    var grossEarnings: Decimal
    var tips: Decimal
    var bonuses: Decimal
    var tollsReimbursed: Decimal
    var platformFees: Decimal

    // MARK: - Activity

    var tripsCompleted: Int
    var hoursWorked: Double?
    var activeHours: Double?

    // MARK: - Notes

    var notes: String?

    // MARK: - Timestamps

    var createdAt: Date
    var updatedAt: Date

    // MARK: - Relationships

    var user: User?

    // MARK: - Computed Properties

    var platform: EarningPlatform {
        get { EarningPlatform(rawValue: platformRaw) ?? .other }
        set { platformRaw = newValue.rawValue }
    }

    /// Net earnings after platform fees
    var netEarnings: Decimal {
        grossEarnings + tips + bonuses + tollsReimbursed - platformFees
    }

    var formattedGrossEarnings: String {
        grossEarnings.formattedCurrency
    }

    var formattedNetEarnings: String {
        netEarnings.formattedCurrency
    }

    var formattedTips: String {
        tips.formattedCurrency
    }

    var formattedBonuses: String {
        bonuses.formattedCurrency
    }

    var platformDisplayName: String {
        platform == .other ? (platformOther ?? "Other") : platform.displayName
    }

    /// Hourly rate based on hours worked
    var hourlyRate: Decimal? {
        guard let hours = hoursWorked, hours > 0 else { return nil }
        return netEarnings / Decimal(hours)
    }

    var formattedHourlyRate: String? {
        hourlyRate.map { "\($0.formattedCurrency)/hr" }
    }

    /// Earnings per trip
    var perTripEarnings: Decimal? {
        guard tripsCompleted > 0 else { return nil }
        return netEarnings / Decimal(tripsCompleted)
    }

    var formattedPerTripEarnings: String? {
        perTripEarnings.map { "\($0.formattedCurrency)/trip" }
    }

    /// Active time percentage
    var activeTimePercentage: Double? {
        guard let total = hoursWorked, let active = activeHours, total > 0 else { return nil }
        return active / total
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        platform: EarningPlatform,
        earningsDate: Date,
        grossEarnings: Decimal
    ) {
        self.id = id
        self.platformRaw = platform.rawValue
        self.platformOther = nil
        self.earningsDate = earningsDate
        self.grossEarnings = grossEarnings
        self.tips = 0
        self.bonuses = 0
        self.tollsReimbursed = 0
        self.platformFees = 0
        self.tripsCompleted = 0
        self.hoursWorked = nil
        self.activeHours = nil
        self.notes = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.user = nil
    }

    // MARK: - Methods

    func update() {
        updatedAt = Date()
    }
}

// MARK: - Earning Platform

enum EarningPlatform: String, Codable, CaseIterable {
    case uber = "uber"
    case lyft = "lyft"
    case doordash = "doordash"
    case instacart = "instacart"
    case amazonFlex = "amazon_flex"
    case grubhub = "grubhub"
    case uberEats = "uber_eats"
    case spark = "spark"
    case shipt = "shipt"
    case other = "other"

    var displayName: String {
        switch self {
        case .uber: return "Uber"
        case .lyft: return "Lyft"
        case .doordash: return "DoorDash"
        case .instacart: return "Instacart"
        case .amazonFlex: return "Amazon Flex"
        case .grubhub: return "Grubhub"
        case .uberEats: return "Uber Eats"
        case .spark: return "Spark"
        case .shipt: return "Shipt"
        case .other: return "Other"
        }
    }

    var iconName: String {
        "car.fill" // All platforms use car icon for simplicity
    }

    var category: PlatformCategory {
        switch self {
        case .uber, .lyft:
            return .rideshare
        case .doordash, .grubhub, .uberEats:
            return .foodDelivery
        case .instacart, .shipt:
            return .groceryDelivery
        case .amazonFlex, .spark:
            return .packageDelivery
        case .other:
            return .other
        }
    }
}

// MARK: - Platform Category

enum PlatformCategory: String, CaseIterable {
    case rideshare = "Rideshare"
    case foodDelivery = "Food Delivery"
    case groceryDelivery = "Grocery Delivery"
    case packageDelivery = "Package Delivery"
    case other = "Other"

    var platforms: [EarningPlatform] {
        EarningPlatform.allCases.filter { $0.category == self }
    }
}

// MARK: - Earning DTO

struct EarningDTO: Codable, Identifiable, Equatable {
    let id: UUID
    let platform: String
    let platformOther: String?
    let earningsDate: Date
    let grossEarnings: Decimal
    let tips: Decimal
    let bonuses: Decimal
    let tollsReimbursed: Decimal
    let platformFees: Decimal
    let netEarnings: Decimal
    let tripsCompleted: Int
    let hoursWorked: Double?
    let activeHours: Double?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, platform, tips, bonuses, notes
        case platformOther = "platform_other"
        case earningsDate = "earnings_date"
        case grossEarnings = "gross_earnings"
        case tollsReimbursed = "tolls_reimbursed"
        case platformFees = "platform_fees"
        case netEarnings = "net_earnings"
        case tripsCompleted = "trips_completed"
        case hoursWorked = "hours_worked"
        case activeHours = "active_hours"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toModel() -> Earning {
        let earning = Earning(
            id: id,
            platform: EarningPlatform(rawValue: platform) ?? .other,
            earningsDate: earningsDate,
            grossEarnings: grossEarnings
        )
        earning.platformOther = platformOther
        earning.tips = tips
        earning.bonuses = bonuses
        earning.tollsReimbursed = tollsReimbursed
        earning.platformFees = platformFees
        earning.tripsCompleted = tripsCompleted
        earning.hoursWorked = hoursWorked
        earning.activeHours = activeHours
        earning.notes = notes
        earning.createdAt = createdAt
        earning.updatedAt = updatedAt
        return earning
    }
}

extension Earning {
    func toDTO() -> EarningDTO {
        EarningDTO(
            id: id,
            platform: platformRaw,
            platformOther: platformOther,
            earningsDate: earningsDate,
            grossEarnings: grossEarnings,
            tips: tips,
            bonuses: bonuses,
            tollsReimbursed: tollsReimbursed,
            platformFees: platformFees,
            netEarnings: netEarnings,
            tripsCompleted: tripsCompleted,
            hoursWorked: hoursWorked,
            activeHours: activeHours,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Earnings Summary

struct EarningsSummary: Equatable {
    let period: DateInterval
    let totalGross: Decimal
    let totalNet: Decimal
    let totalTips: Decimal
    let totalBonuses: Decimal
    let totalFees: Decimal
    let totalTrips: Int
    let totalHours: Double
    let averageHourlyRate: Decimal?
    let byPlatform: [EarningPlatform: Decimal]

    var formattedTotalGross: String { totalGross.formattedCurrency }
    var formattedTotalNet: String { totalNet.formattedCurrency }
    var formattedAverageHourlyRate: String? {
        averageHourlyRate.map { "\($0.formattedCurrency)/hr" }
    }
}
