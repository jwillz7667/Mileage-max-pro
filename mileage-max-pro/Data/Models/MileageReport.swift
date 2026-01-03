//
//  MileageReport.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import SwiftData

/// Mileage report model for IRS-compliant documentation
@Model
final class MileageReport {
    // MARK: - Primary Identifiers

    @Attribute(.unique)
    var id: UUID

    // MARK: - Report Info

    var reportTypeRaw: String
    var reportName: String
    var dateRangeStart: Date
    var dateRangeEnd: Date

    // MARK: - Filters

    var vehicleIds: [UUID]?
    var categories: [String]?

    // MARK: - Trip Statistics

    var totalTrips: Int
    var totalMiles: Decimal
    var businessMiles: Decimal
    var personalMiles: Decimal
    var otherMiles: Decimal

    // MARK: - Expense Statistics

    var totalExpenses: Decimal
    var fuelExpenses: Decimal
    var maintenanceExpenses: Decimal
    var otherExpenses: Decimal

    // MARK: - IRS Calculation

    var irsRateUsed: Decimal

    // MARK: - Earnings

    var totalEarnings: Decimal?
    var netProfit: Decimal?

    // MARK: - Report Data

    var reportData: Data

    // MARK: - Generated Files

    var pdfURL: String?
    var csvURL: String?

    // MARK: - Status

    var statusRaw: String
    var generatedAt: Date?
    var expiresAt: Date?

    // MARK: - Timestamps

    var createdAt: Date

    // MARK: - Relationships

    var user: User?

    // MARK: - Computed Properties

    var reportType: ReportType {
        get { ReportType(rawValue: reportTypeRaw) ?? .custom }
        set { reportTypeRaw = newValue.rawValue }
    }

    var status: ReportStatus {
        get { ReportStatus(rawValue: statusRaw) ?? .generating }
        set { statusRaw = newValue.rawValue }
    }

    /// Calculated mileage deduction
    var mileageDeduction: Decimal {
        businessMiles * irsRateUsed
    }

    var formattedTotalMiles: String {
        totalMiles.doubleValue.formattedMiles
    }

    var formattedBusinessMiles: String {
        businessMiles.doubleValue.formattedMiles
    }

    var formattedMileageDeduction: String {
        mileageDeduction.formattedCurrency
    }

    var formattedTotalExpenses: String {
        totalExpenses.formattedCurrency
    }

    var dateRangeString: String {
        "\(dateRangeStart.mediumDateString) - \(dateRangeEnd.mediumDateString)"
    }

    var isReady: Bool {
        status == .ready
    }

    var isExpired: Bool {
        guard let expires = expiresAt else { return false }
        return Date() > expires
    }

    var decodedReportData: ReportData? {
        try? JSONDecoder().decode(ReportData.self, from: reportData)
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        reportType: ReportType,
        reportName: String,
        dateRangeStart: Date,
        dateRangeEnd: Date,
        irsRate: Decimal
    ) {
        self.id = id
        self.reportTypeRaw = reportType.rawValue
        self.reportName = reportName
        self.dateRangeStart = dateRangeStart
        self.dateRangeEnd = dateRangeEnd
        self.vehicleIds = nil
        self.categories = nil
        self.totalTrips = 0
        self.totalMiles = 0
        self.businessMiles = 0
        self.personalMiles = 0
        self.otherMiles = 0
        self.totalExpenses = 0
        self.fuelExpenses = 0
        self.maintenanceExpenses = 0
        self.otherExpenses = 0
        self.irsRateUsed = irsRate
        self.totalEarnings = nil
        self.netProfit = nil
        self.reportData = Data()
        self.pdfURL = nil
        self.csvURL = nil
        self.statusRaw = ReportStatus.generating.rawValue
        self.generatedAt = nil
        self.expiresAt = nil
        self.createdAt = Date()
        self.user = nil
    }

    // MARK: - Methods

    func updateStatistics(
        trips: [Trip],
        expenses: [Expense],
        earnings: [Earning]? = nil
    ) {
        totalTrips = trips.count

        // Calculate mileage by category
        var businessSum: Decimal = 0
        var personalSum: Decimal = 0
        var otherSum: Decimal = 0

        for trip in trips {
            let miles = Decimal(trip.distanceMiles)
            switch trip.category {
            case .business:
                businessSum += miles
            case .personal, .commute:
                personalSum += miles
            case .medical, .charity, .moving:
                otherSum += miles
            }
        }

        businessMiles = businessSum
        personalMiles = personalSum
        otherMiles = otherSum
        totalMiles = businessSum + personalSum + otherSum

        // Calculate expenses by category
        var fuelSum: Decimal = 0
        var maintenanceSum: Decimal = 0
        var expenseOtherSum: Decimal = 0

        for expense in expenses {
            switch expense.category {
            case .fuel:
                fuelSum += expense.amount
            case .maintenance, .repairs:
                maintenanceSum += expense.amount
            default:
                expenseOtherSum += expense.amount
            }
        }

        fuelExpenses = fuelSum
        maintenanceExpenses = maintenanceSum
        otherExpenses = expenseOtherSum
        totalExpenses = fuelSum + maintenanceSum + expenseOtherSum

        // Calculate earnings if provided
        if let earnings = earnings, !earnings.isEmpty {
            totalEarnings = earnings.reduce(0) { $0 + $1.netEarnings }
            netProfit = (totalEarnings ?? 0) - totalExpenses - mileageDeduction
        }
    }

    func setReportData(_ data: ReportData) {
        reportData = (try? JSONEncoder().encode(data)) ?? Data()
    }

    func markReady(pdfURL: String?, csvURL: String?, expiresIn: TimeInterval = 604800) {
        status = .ready
        self.pdfURL = pdfURL
        self.csvURL = csvURL
        generatedAt = Date()
        expiresAt = Date().addingTimeInterval(expiresIn) // Default 7 days
    }

    func markFailed() {
        status = .failed
    }
}

// MARK: - Report Type

enum ReportType: String, Codable, CaseIterable {
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case annual = "annual"
    case custom = "custom"
    case irsLog = "irs_log"

    var displayName: String {
        switch self {
        case .weekly: return "Weekly Report"
        case .monthly: return "Monthly Report"
        case .quarterly: return "Quarterly Report"
        case .annual: return "Annual Report"
        case .custom: return "Custom Report"
        case .irsLog: return "IRS Mileage Log"
        }
    }

    var iconName: String {
        switch self {
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .quarterly: return "calendar.badge.3"
        case .annual: return "calendar.circle"
        case .custom: return "doc.text.fill"
        case .irsLog: return "doc.richtext.fill"
        }
    }
}

// MARK: - Report Status

enum ReportStatus: String, Codable, CaseIterable {
    case generating = "generating"
    case ready = "ready"
    case failed = "failed"

    var displayName: String {
        switch self {
        case .generating: return "Generating"
        case .ready: return "Ready"
        case .failed: return "Failed"
        }
    }
}

// MARK: - Report Data

struct ReportData: Codable, Equatable {
    let summary: ReportSummary
    let tripsByCategory: [String: CategorySummary]
    let tripsByVehicle: [String: VehicleSummary]
    let expensesByCategory: [String: Decimal]
    let dailyBreakdown: [DailyBreakdown]
    let weeklyTrends: [WeeklyTrend]?

    struct ReportSummary: Codable, Equatable {
        let totalTrips: Int
        let totalMiles: Decimal
        let businessMiles: Decimal
        let deductibleMiles: Decimal
        let irsRate: Decimal
        let estimatedDeduction: Decimal
        let totalExpenses: Decimal
        let totalEarnings: Decimal?
    }

    struct CategorySummary: Codable, Equatable {
        let category: String
        let tripCount: Int
        let totalMiles: Decimal
        let percentage: Double
    }

    struct VehicleSummary: Codable, Equatable {
        let vehicleId: UUID
        let vehicleName: String
        let tripCount: Int
        let totalMiles: Decimal
    }

    struct DailyBreakdown: Codable, Equatable {
        let date: Date
        let tripCount: Int
        let miles: Decimal
        let expenses: Decimal
    }

    struct WeeklyTrend: Codable, Equatable {
        let weekStart: Date
        let tripCount: Int
        let miles: Decimal
        let expenses: Decimal
        let earnings: Decimal?
    }
}

// MARK: - Mileage Report DTO

struct MileageReportDTO: Codable, Identifiable, Equatable {
    let id: UUID
    let reportType: String
    let reportName: String
    let dateRangeStart: Date
    let dateRangeEnd: Date
    let totalTrips: Int
    let totalMiles: Decimal
    let businessMiles: Decimal
    let mileageDeduction: Decimal
    let totalExpenses: Decimal
    let irsRateUsed: Decimal
    let pdfURL: String?
    let csvURL: String?
    let status: String
    let generatedAt: Date?
    let expiresAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case reportType = "report_type"
        case reportName = "report_name"
        case dateRangeStart = "date_range_start"
        case dateRangeEnd = "date_range_end"
        case totalTrips = "total_trips"
        case totalMiles = "total_miles"
        case businessMiles = "business_miles"
        case mileageDeduction = "mileage_deduction"
        case totalExpenses = "total_expenses"
        case irsRateUsed = "irs_rate_used"
        case pdfURL = "pdf_url"
        case csvURL = "csv_url"
        case status
        case generatedAt = "generated_at"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
    }
}
