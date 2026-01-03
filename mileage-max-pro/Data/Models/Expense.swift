//
//  Expense.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import SwiftData

/// Expense model for MileageMax Pro
@Model
final class Expense {
    // MARK: - Primary Identifiers

    @Attribute(.unique)
    var id: UUID

    // MARK: - Category

    var categoryRaw: String
    var subcategory: String?

    // MARK: - Amount

    var amount: Decimal
    var currency: String

    // MARK: - Date & Vendor

    var expenseDate: Date
    var vendorName: String?
    var vendorAddress: String?
    var vendorLatitude: Double?
    var vendorLongitude: Double?

    // MARK: - Details

    var expenseDescription: String?
    var paymentMethodRaw: String

    // MARK: - Reimbursement

    var isReimbursable: Bool
    var reimbursementStatusRaw: String

    // MARK: - Receipt

    var receiptURL: String?
    var receiptOCRData: Data?

    // MARK: - Tax

    var isTaxDeductible: Bool
    var taxCategory: String?

    // MARK: - Notes

    var notes: String?

    // MARK: - Timestamps

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    // MARK: - Relationships

    var user: User?
    var vehicle: Vehicle?
    var trip: Trip?

    @Relationship(deleteRule: .cascade, inverse: \FuelPurchase.expense)
    var fuelPurchase: FuelPurchase?

    // MARK: - Computed Properties

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodRaw) ?? .card }
        set { paymentMethodRaw = newValue.rawValue }
    }

    var reimbursementStatus: ReimbursementStatus {
        get { ReimbursementStatus(rawValue: reimbursementStatusRaw) ?? .notApplicable }
        set { reimbursementStatusRaw = newValue.rawValue }
    }

    // MARK: - Compatibility Aliases

    /// Alias for vendorName
    var vendor: String? {
        get { vendorName }
        set { vendorName = newValue }
    }

    /// Alias for expenseDate
    var date: Date {
        get { expenseDate }
        set { expenseDate = newValue }
    }

    /// Alias for isTaxDeductible
    var isDeductible: Bool {
        get { isTaxDeductible }
        set { isTaxDeductible = newValue }
    }

    /// Computed vehicleId for backward compatibility
    var vehicleId: UUID? {
        vehicle?.id
    }

    /// Computed tripId for backward compatibility
    var tripId: UUID? {
        trip?.id
    }

    /// Alias for receiptURL data (placeholder)
    var receiptImageData: Data? {
        receiptOCRData
    }

    var syncStatus: SyncStatus {
        get { .synced }
        set { /* Not persisted in this model */ }
    }

    var lastSyncedAt: Date? {
        updatedAt
    }

    var formattedAmount: String {
        amount.formattedCurrency
    }

    var displayDate: String {
        expenseDate.mediumDateString
    }

    var vendorDisplayName: String {
        vendorName ?? category.displayName
    }

    var hasReceipt: Bool {
        receiptURL != nil
    }

    var ocrData: ReceiptOCRResult? {
        get {
            guard let data = receiptOCRData else { return nil }
            return try? JSONDecoder().decode(ReceiptOCRResult.self, from: data)
        }
        set {
            receiptOCRData = try? JSONEncoder().encode(newValue)
        }
    }

    var isFuelExpense: Bool {
        category == .fuel && fuelPurchase != nil
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        category: ExpenseCategory,
        amount: Decimal,
        expenseDate: Date = Date(),
        currency: String = "USD"
    ) {
        self.id = id
        self.categoryRaw = category.rawValue
        self.subcategory = nil
        self.amount = amount
        self.currency = currency
        self.expenseDate = expenseDate
        self.vendorName = nil
        self.vendorAddress = nil
        self.vendorLatitude = nil
        self.vendorLongitude = nil
        self.expenseDescription = nil
        self.paymentMethodRaw = PaymentMethod.card.rawValue
        self.isReimbursable = false
        self.reimbursementStatusRaw = ReimbursementStatus.notApplicable.rawValue
        self.receiptURL = nil
        self.receiptOCRData = nil
        self.isTaxDeductible = category.isTypicallyDeductible
        self.taxCategory = nil
        self.notes = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil
        self.user = nil
        self.vehicle = nil
        self.trip = nil
        self.fuelPurchase = nil
    }

    // MARK: - Methods

    func update() {
        updatedAt = Date()
    }

    func softDelete() {
        deletedAt = Date()
        update()
    }

    func attachReceipt(url: String, ocrResult: ReceiptOCRResult? = nil) {
        receiptURL = url
        if let result = ocrResult {
            ocrData = result
            // Auto-fill from OCR if not already set
            if vendorName == nil {
                vendorName = result.vendorName
            }
            if expenseDescription == nil {
                expenseDescription = result.lineItems?.map { $0.description }.joined(separator: ", ")
            }
        }
        update()
    }

    func submitForReimbursement() {
        guard isReimbursable else { return }
        reimbursementStatus = .submitted
        update()
    }
}

// MARK: - Expense Category

enum ExpenseCategory: String, Codable, CaseIterable {
    case fuel = "fuel"
    case parking = "parking"
    case tolls = "tolls"
    case maintenance = "maintenance"
    case repairs = "repairs"
    case insurance = "insurance"
    case registration = "registration"
    case carWash = "car_wash"
    case supplies = "supplies"
    case phone = "phone"
    case equipment = "equipment"
    case meals = "meals"
    case lodging = "lodging"
    case other = "other"

    var displayName: String {
        switch self {
        case .fuel: return "Fuel"
        case .parking: return "Parking"
        case .tolls: return "Tolls"
        case .maintenance: return "Maintenance"
        case .repairs: return "Repairs"
        case .insurance: return "Insurance"
        case .registration: return "Registration"
        case .carWash: return "Car Wash"
        case .supplies: return "Supplies"
        case .phone: return "Phone"
        case .equipment: return "Equipment"
        case .meals: return "Meals"
        case .lodging: return "Lodging"
        case .other: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .fuel: return "fuelpump.fill"
        case .parking: return "parkingsign"
        case .tolls: return "road.lanes"
        case .maintenance: return "wrench.fill"
        case .repairs: return "wrench.and.screwdriver.fill"
        case .insurance: return "shield.fill"
        case .registration: return "doc.text.fill"
        case .carWash: return "drop.triangle.fill"
        case .supplies: return "shippingbox.fill"
        case .phone: return "iphone"
        case .equipment: return "gearshape.fill"
        case .meals: return "fork.knife"
        case .lodging: return "bed.double.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var isTypicallyDeductible: Bool {
        switch self {
        case .fuel, .parking, .tolls, .maintenance, .repairs, .insurance, .registration, .carWash, .supplies, .phone, .equipment:
            return true
        case .meals, .lodging, .other:
            return false
        }
    }

    var isVehicleRelated: Bool {
        switch self {
        case .fuel, .parking, .tolls, .maintenance, .repairs, .insurance, .registration, .carWash:
            return true
        default:
            return false
        }
    }
}

// MARK: - Payment Method

enum PaymentMethod: String, Codable, CaseIterable {
    case cash = "cash"
    case card = "card"
    case check = "check"
    case app = "app"
    case other = "other"

    var displayName: String {
        switch self {
        case .cash: return "Cash"
        case .card: return "Card"
        case .check: return "Check"
        case .app: return "App"
        case .other: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .cash: return "banknote.fill"
        case .card: return "creditcard.fill"
        case .check: return "doc.text.fill"
        case .app: return "iphone"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Reimbursement Status

enum ReimbursementStatus: String, Codable, CaseIterable {
    case notApplicable = "not_applicable"
    case pending = "pending"
    case submitted = "submitted"
    case approved = "approved"
    case paid = "paid"
    case rejected = "rejected"

    var displayName: String {
        switch self {
        case .notApplicable: return "N/A"
        case .pending: return "Pending"
        case .submitted: return "Submitted"
        case .approved: return "Approved"
        case .paid: return "Paid"
        case .rejected: return "Rejected"
        }
    }

    var iconName: String {
        switch self {
        case .notApplicable: return "minus.circle"
        case .pending: return "clock.fill"
        case .submitted: return "paperplane.fill"
        case .approved: return "checkmark.circle.fill"
        case .paid: return "dollarsign.circle.fill"
        case .rejected: return "xmark.circle.fill"
        }
    }
}

// MARK: - Receipt OCR Result

struct ReceiptOCRResult: Codable, Equatable {
    let vendorName: String?
    let date: Date?
    let total: Decimal?
    let subtotal: Decimal?
    let tax: Decimal?
    let paymentMethod: String?
    let lineItems: [ReceiptLineItem]?
    let rawText: String?
    let confidence: Double

    struct ReceiptLineItem: Codable, Equatable {
        let description: String
        let quantity: Double?
        let unitPrice: Decimal?
        let totalPrice: Decimal?
    }
}

// MARK: - Expense DTO

struct ExpenseDTO: Codable, Identifiable, Equatable {
    let id: UUID
    let category: String
    let subcategory: String?
    let amount: Decimal
    let currency: String
    let expenseDate: Date
    let vendorName: String?
    let vendorAddress: String?
    let description: String?
    let paymentMethod: String
    let isReimbursable: Bool
    let reimbursementStatus: String
    let receiptURL: String?
    let isTaxDeductible: Bool
    let taxCategory: String?
    let notes: String?
    let vehicleId: UUID?
    let tripId: UUID?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, category, subcategory, amount, currency, description, notes
        case expenseDate = "expense_date"
        case vendorName = "vendor_name"
        case vendorAddress = "vendor_address"
        case paymentMethod = "payment_method"
        case isReimbursable = "is_reimbursable"
        case reimbursementStatus = "reimbursement_status"
        case receiptURL = "receipt_url"
        case isTaxDeductible = "is_tax_deductible"
        case taxCategory = "tax_category"
        case vehicleId = "vehicle_id"
        case tripId = "trip_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toModel() -> Expense {
        let expense = Expense(
            id: id,
            category: ExpenseCategory(rawValue: category) ?? .other,
            amount: amount,
            expenseDate: expenseDate,
            currency: currency
        )
        expense.subcategory = subcategory
        expense.vendorName = vendorName
        expense.vendorAddress = vendorAddress
        expense.expenseDescription = description
        expense.paymentMethodRaw = paymentMethod
        expense.isReimbursable = isReimbursable
        expense.reimbursementStatusRaw = reimbursementStatus
        expense.receiptURL = receiptURL
        expense.isTaxDeductible = isTaxDeductible
        expense.taxCategory = taxCategory
        expense.notes = notes
        expense.createdAt = createdAt
        expense.updatedAt = updatedAt
        return expense
    }
}

extension Expense {
    func toDTO() -> ExpenseDTO {
        ExpenseDTO(
            id: id,
            category: categoryRaw,
            subcategory: subcategory,
            amount: amount,
            currency: currency,
            expenseDate: expenseDate,
            vendorName: vendorName,
            vendorAddress: vendorAddress,
            description: expenseDescription,
            paymentMethod: paymentMethodRaw,
            isReimbursable: isReimbursable,
            reimbursementStatus: reimbursementStatusRaw,
            receiptURL: receiptURL,
            isTaxDeductible: isTaxDeductible,
            taxCategory: taxCategory,
            notes: notes,
            vehicleId: vehicle?.id,
            tripId: trip?.id,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
