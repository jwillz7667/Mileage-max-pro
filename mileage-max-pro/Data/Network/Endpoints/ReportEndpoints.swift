//
//  ReportEndpoints.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation

/// Mileage reporting and export API endpoints
enum ReportEndpoints {

    // MARK: - Report Management

    case list(pagination: PaginationParameters, year: Int?)
    case get(id: String)
    case create(report: CreateReportRequest)
    case delete(id: String)

    // MARK: - Report Generation

    case generate(request: GenerateReportRequest)
    case regenerate(id: String)
    case getStatus(id: String)

    // MARK: - Export

    case exportPDF(id: String)
    case exportCSV(id: String)
    case exportExcel(id: String)
    case downloadReport(id: String, format: ExportFormat)

    // MARK: - IRS Compliance

    case irsLogPreview(request: IRSLogPreviewRequest)
    case generateIRSLog(request: GenerateIRSLogRequest)

    // MARK: - Report Data

    case getSummary(reportId: String)
    case getTripDetails(reportId: String, pagination: PaginationParameters)
    case getCategoryBreakdown(reportId: String)

    // MARK: - Scheduled Reports

    case listScheduled
    case createScheduled(schedule: CreateScheduledReportRequest)
    case updateScheduled(id: String, schedule: UpdateScheduledReportRequest)
    case deleteScheduled(id: String)
}

extension ReportEndpoints: APIEndpoint {

    var method: HTTPMethod {
        switch self {
        case .list, .get, .getStatus, .exportPDF, .exportCSV, .exportExcel, .downloadReport,
             .getSummary, .getTripDetails, .getCategoryBreakdown, .listScheduled, .irsLogPreview:
            return .get
        case .create, .generate, .generateIRSLog, .createScheduled:
            return .post
        case .regenerate, .updateScheduled:
            return .patch
        case .delete, .deleteScheduled:
            return .delete
        }
    }

    var path: String {
        let base = APIConstants.Endpoints.Reports

        switch self {
        case .list, .create:
            return base
        case .get(let id), .delete(let id):
            return "\(base)/\(id)"
        case .generate:
            return "\(base)/generate"
        case .regenerate(let id):
            return "\(base)/\(id)/regenerate"
        case .getStatus(let id):
            return "\(base)/\(id)/status"
        case .exportPDF(let id):
            return "\(base)/\(id)/export/pdf"
        case .exportCSV(let id):
            return "\(base)/\(id)/export/csv"
        case .exportExcel(let id):
            return "\(base)/\(id)/export/excel"
        case .downloadReport(let id, let format):
            return "\(base)/\(id)/download/\(format.rawValue)"
        case .irsLogPreview:
            return "\(base)/irs-log/preview"
        case .generateIRSLog:
            return "\(base)/irs-log/generate"
        case .getSummary(let reportId):
            return "\(base)/\(reportId)/summary"
        case .getTripDetails(let reportId, _):
            return "\(base)/\(reportId)/trips"
        case .getCategoryBreakdown(let reportId):
            return "\(base)/\(reportId)/breakdown"
        case .listScheduled:
            return "\(base)/scheduled"
        case .createScheduled:
            return "\(base)/scheduled"
        case .updateScheduled(let id, _), .deleteScheduled(let id):
            return "\(base)/scheduled/\(id)"
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .list(let pagination, let year):
            var params = pagination.queryParameters
            if let year = year {
                params["year"] = String(year)
            }
            return params
        case .getTripDetails(_, let pagination):
            return pagination.queryParameters
        case .irsLogPreview(let request):
            let formatter = ISO8601DateFormatter()
            return [
                "start_date": formatter.string(from: request.startDate),
                "end_date": formatter.string(from: request.endDate),
                "categories": request.categories.joined(separator: ",")
            ]
        default:
            return nil
        }
    }

    var body: Encodable? {
        switch self {
        case .create(let report):
            return report
        case .generate(let request):
            return request
        case .generateIRSLog(let request):
            return request
        case .createScheduled(let schedule):
            return schedule
        case .updateScheduled(_, let schedule):
            return schedule
        default:
            return nil
        }
    }
}

// MARK: - Export Format

enum ReportExportFormat: String {
    case pdf
    case csv
    case excel
}

// MARK: - Request Models

struct CreateReportRequest: Codable {
    let name: String
    let type: String
    let startDate: Date
    let endDate: Date
    let categories: [String]?
    let vehicleIds: [String]?
    let includeDetails: Bool?
}

struct GenerateReportRequest: Codable {
    let type: String
    let startDate: Date
    let endDate: Date
    let categories: [String]?
    let vehicleIds: [String]?
    let format: String?
    let includeTripsWithoutEndLocation: Bool?
    let irsRateOverride: Double?
}

struct IRSLogPreviewRequest: Codable {
    let startDate: Date
    let endDate: Date
    let categories: [String]
}

struct GenerateIRSLogRequest: Codable {
    let year: Int
    let quarters: [Int]?
    let categories: [String]
    let vehicleIds: [String]?
    let format: String
    let includeSignatureLine: Bool?
}

struct CreateScheduledReportRequest: Codable {
    let name: String
    let type: String
    let frequency: String
    let categories: [String]?
    let vehicleIds: [String]?
    let emailRecipients: [String]?
    let format: String
    let isActive: Bool?
}

struct UpdateScheduledReportRequest: Codable {
    let name: String?
    let frequency: String?
    let categories: [String]?
    let vehicleIds: [String]?
    let emailRecipients: [String]?
    let format: String?
    let isActive: Bool?
}

// MARK: - Response Models

struct ReportResponse: Codable {
    let id: String
    let userId: String
    let name: String
    let type: String
    let status: String
    let startDate: Date
    let endDate: Date
    let categories: [String]
    let vehicleIds: [String]?
    let totalMiles: Double
    let totalTrips: Int
    let businessMiles: Double
    let personalMiles: Double
    let medicalMiles: Double
    let charityMiles: Double
    let estimatedDeduction: Double
    let irsRate: Double
    let pdfUrl: String?
    let csvUrl: String?
    let excelUrl: String?
    let generatedAt: Date?
    let createdAt: Date
}

struct ReportStatusResponse: Codable {
    let reportId: String
    let status: String
    let progress: Double
    let message: String?
    let estimatedCompletionTime: Date?
}

struct ReportSummaryResponse: Codable {
    let reportId: String
    let period: PeriodInfo
    let totals: TotalsMileage
    let categoryBreakdown: [CategoryMileage]
    let vehicleBreakdown: [VehicleMileage]
    let monthlyTrend: [MonthlyMileage]
    let taxDeduction: TaxDeductionInfo

    struct PeriodInfo: Codable {
        let startDate: Date
        let endDate: Date
        let totalDays: Int
        let businessDays: Int
    }

    struct TotalsMileage: Codable {
        let totalMiles: Double
        let totalTrips: Int
        let averageTripDistance: Double
        let averageTripsPerDay: Double
    }

    struct CategoryMileage: Codable {
        let category: String
        let miles: Double
        let trips: Int
        let percentage: Double
    }

    struct VehicleMileage: Codable {
        let vehicleId: String
        let vehicleName: String
        let miles: Double
        let trips: Int
    }

    struct MonthlyMileage: Codable {
        let month: String
        let miles: Double
        let trips: Int
    }

    struct TaxDeductionInfo: Codable {
        let irsRate: Double
        let businessMiles: Double
        let medicalMiles: Double
        let charityMiles: Double
        let businessDeduction: Double
        let medicalDeduction: Double
        let charityDeduction: Double
        let totalDeduction: Double
    }
}

struct CategoryBreakdownResponse: Codable {
    let reportId: String
    let breakdown: [CategoryDetail]

    struct CategoryDetail: Codable {
        let category: String
        let totalMiles: Double
        let totalTrips: Int
        let totalDuration: Int
        let averageDistance: Double
        let averageDuration: Int
        let topDestinations: [Destination]
        let peakHours: [Int]
    }

    struct Destination: Codable {
        let name: String
        let address: String
        let visitCount: Int
        let totalMiles: Double
    }
}

struct IRSLogPreviewResponse: Codable {
    let startDate: Date
    let endDate: Date
    let tripCount: Int
    let totalMiles: Double
    let deductibleMiles: Double
    let estimatedDeduction: Double
    let warnings: [String]
    let incompleteTrips: Int
}

struct ScheduledReportResponse: Codable {
    let id: String
    let userId: String
    let name: String
    let type: String
    let frequency: String
    let categories: [String]
    let vehicleIds: [String]?
    let emailRecipients: [String]?
    let format: String
    let isActive: Bool
    let lastRunAt: Date?
    let nextRunAt: Date?
    let createdAt: Date
}
