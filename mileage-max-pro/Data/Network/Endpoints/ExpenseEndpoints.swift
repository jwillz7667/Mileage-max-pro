//
//  ExpenseEndpoints.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation

/// Expense tracking API endpoints
enum ExpenseEndpoints {

    // MARK: - CRUD Operations

    case list(pagination: PaginationParameters, filters: ExpenseFilters?)
    case get(id: String)
    case create(expense: CreateExpenseRequest)
    case update(id: String, expense: UpdateExpenseRequest)
    case delete(id: String)

    // MARK: - Receipt Management

    case uploadReceipt(expenseId: String)
    case getReceipt(expenseId: String)
    case deleteReceipt(expenseId: String)
    case scanReceipt
    case parseReceiptOCR(imageData: Data)

    // MARK: - Batch Operations

    case batchCreate(expenses: [CreateExpenseRequest])
    case batchDelete(ids: [String])
    case batchUpdateCategory(ids: [String], category: String)

    // MARK: - Statistics

    case statistics(period: StatsPeriod, filters: ExpenseFilters?)
    case categoryBreakdown(startDate: Date, endDate: Date)
    case monthlyTrend(year: Int)

    // MARK: - Reimbursement

    case markForReimbursement(ids: [String])
    case markReimbursed(ids: [String], date: Date, reference: String?)
    case getReimbursementStatus
}

extension ExpenseEndpoints: APIEndpoint {

    var method: HTTPMethod {
        switch self {
        case .list, .get, .getReceipt, .statistics, .categoryBreakdown, .monthlyTrend, .getReimbursementStatus:
            return .get
        case .create, .uploadReceipt, .scanReceipt, .parseReceiptOCR, .batchCreate:
            return .post
        case .update, .batchUpdateCategory, .markForReimbursement, .markReimbursed:
            return .patch
        case .delete, .deleteReceipt, .batchDelete:
            return .delete
        }
    }

    var path: String {
        let base = APIConstants.Endpoints.Expenses

        switch self {
        case .list, .create:
            return base
        case .get(let id), .update(let id, _), .delete(let id):
            return "\(base)/\(id)"
        case .uploadReceipt(let expenseId), .getReceipt(let expenseId), .deleteReceipt(let expenseId):
            return "\(base)/\(expenseId)/receipt"
        case .scanReceipt:
            return "\(base)/receipts/scan"
        case .parseReceiptOCR:
            return "\(base)/receipts/parse"
        case .batchCreate:
            return "\(base)/batch"
        case .batchDelete:
            return "\(base)/batch"
        case .batchUpdateCategory:
            return "\(base)/batch/category"
        case .statistics:
            return "\(base)/statistics"
        case .categoryBreakdown:
            return "\(base)/breakdown/category"
        case .monthlyTrend:
            return "\(base)/trend/monthly"
        case .markForReimbursement:
            return "\(base)/reimbursement/pending"
        case .markReimbursed:
            return "\(base)/reimbursement/complete"
        case .getReimbursementStatus:
            return "\(base)/reimbursement/status"
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .list(let pagination, let filters):
            var params = pagination.queryParameters
            if let filters = filters {
                params.merge(filters.queryParameters) { _, new in new }
            }
            return params

        case .statistics(let period, let filters):
            var params = ["period": period.rawValue]
            if let filters = filters {
                params.merge(filters.queryParameters) { _, new in new }
            }
            return params

        case .categoryBreakdown(let startDate, let endDate):
            let formatter = ISO8601DateFormatter()
            return [
                "start_date": formatter.string(from: startDate),
                "end_date": formatter.string(from: endDate)
            ]

        case .monthlyTrend(let year):
            return ["year": String(year)]

        default:
            return nil
        }
    }

    var body: Encodable? {
        switch self {
        case .create(let expense):
            return expense
        case .update(_, let expense):
            return expense
        case .batchCreate(let expenses):
            return BatchCreateExpensesRequest(expenses: expenses)
        case .batchDelete(let ids):
            return BatchDeleteRequest(ids: ids)
        case .batchUpdateCategory(let ids, let category):
            return BatchUpdateCategoryRequest(ids: ids, category: category)
        case .markForReimbursement(let ids):
            return MarkReimbursementRequest(ids: ids)
        case .markReimbursed(let ids, let date, let reference):
            return CompleteReimbursementRequest(ids: ids, date: date, reference: reference)
        default:
            return nil
        }
    }

    var contentType: ContentType {
        switch self {
        case .uploadReceipt, .parseReceiptOCR:
            return .multipartFormData
        default:
            return .json
        }
    }
}

// MARK: - Request Models

struct CreateExpenseRequest: Codable {
    let category: String
    let amount: Double
    let date: Date
    let description: String?
    let vendor: String?
    let vehicleId: String?
    let tripId: String?
    let paymentMethod: String?
    let isDeductible: Bool?
    let notes: String?
}

struct UpdateExpenseRequest: Codable {
    let category: String?
    let amount: Double?
    let date: Date?
    let description: String?
    let vendor: String?
    let vehicleId: String?
    let tripId: String?
    let paymentMethod: String?
    let isDeductible: Bool?
    let notes: String?
}

struct BatchCreateExpensesRequest: Codable {
    let expenses: [CreateExpenseRequest]
}

struct BatchUpdateCategoryRequest: Codable {
    let ids: [String]
    let category: String
}

struct MarkReimbursementRequest: Codable {
    let ids: [String]
}

struct CompleteReimbursementRequest: Codable {
    let ids: [String]
    let date: Date
    let reference: String?
}

// MARK: - Response Models

struct ExpenseResponse: Codable {
    let id: String
    let userId: String
    let category: String
    let amount: Double
    let date: Date
    let description: String?
    let vendor: String?
    let vehicleId: String?
    let tripId: String?
    let paymentMethod: String?
    let isDeductible: Bool
    let receiptUrl: String?
    let receiptOcrData: ReceiptOCRData?
    let reimbursementStatus: String?
    let reimbursedAt: Date?
    let reimbursementReference: String?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
}

struct ReceiptOCRData: Codable {
    let extractedVendor: String?
    let extractedAmount: Double?
    let extractedDate: Date?
    let extractedItems: [ExtractedItem]?
    let confidence: Double
    let rawText: String?

    struct ExtractedItem: Codable {
        let description: String
        let quantity: Int?
        let unitPrice: Double?
        let totalPrice: Double?
    }
}

struct ReceiptScanResponse: Codable {
    let success: Bool
    let data: ReceiptOCRData?
    let suggestedCategory: String?
    let suggestedVendor: String?
    let suggestedAmount: Double?
    let suggestedDate: Date?
}

struct ExpenseStatisticsResponse: Codable {
    let totalExpenses: Int
    let totalAmount: Double
    let averageExpense: Double
    let deductibleAmount: Double
    let nonDeductibleAmount: Double
    let byCategory: [CategoryStats]
    let byPaymentMethod: [PaymentMethodStats]
    let topVendors: [VendorStats]

    struct CategoryStats: Codable {
        let category: String
        let count: Int
        let amount: Double
        let percentage: Double
    }

    struct PaymentMethodStats: Codable {
        let paymentMethod: String
        let count: Int
        let amount: Double
    }

    struct VendorStats: Codable {
        let vendor: String
        let count: Int
        let totalAmount: Double
    }
}

struct ExpenseCategoryBreakdownResponse: Codable {
    let startDate: Date
    let endDate: Date
    let totalAmount: Double
    let categories: [CategoryDetail]

    struct CategoryDetail: Codable {
        let category: String
        let amount: Double
        let count: Int
        let percentage: Double
        let averagePerExpense: Double
        let trend: TrendInfo?
    }

    struct TrendInfo: Codable {
        let direction: String
        let percentageChange: Double
        let previousPeriodAmount: Double
    }
}

struct MonthlyExpenseTrendResponse: Codable {
    let year: Int
    let totalAmount: Double
    let averageMonthly: Double
    let months: [MonthlyExpense]

    struct MonthlyExpense: Codable {
        let month: Int
        let monthName: String
        let amount: Double
        let count: Int
        let topCategory: String
    }
}

struct ReimbursementStatusResponse: Codable {
    let pendingCount: Int
    let pendingAmount: Double
    let reimbursedCount: Int
    let reimbursedAmount: Double
    let pendingExpenses: [ExpenseResponse]
}

// MARK: - Filter Types

struct ExpenseFilters {
    var category: ExpenseCategory?
    var vehicleId: String?
    var startDate: Date?
    var endDate: Date?
    var minAmount: Double?
    var maxAmount: Double?
    var isDeductible: Bool?
    var reimbursementStatus: ReimbursementStatus?
    var searchQuery: String?

    var queryParameters: [String: String] {
        var params: [String: String] = [:]
        let formatter = ISO8601DateFormatter()

        if let category = category {
            params["category"] = category.rawValue
        }
        if let vehicleId = vehicleId {
            params["vehicle_id"] = vehicleId
        }
        if let startDate = startDate {
            params["start_date"] = formatter.string(from: startDate)
        }
        if let endDate = endDate {
            params["end_date"] = formatter.string(from: endDate)
        }
        if let minAmount = minAmount {
            params["min_amount"] = String(minAmount)
        }
        if let maxAmount = maxAmount {
            params["max_amount"] = String(maxAmount)
        }
        if let isDeductible = isDeductible {
            params["is_deductible"] = String(isDeductible)
        }
        if let reimbursementStatus = reimbursementStatus {
            params["reimbursement_status"] = reimbursementStatus.rawValue
        }
        if let searchQuery = searchQuery {
            params["q"] = searchQuery
        }

        return params
    }
}
