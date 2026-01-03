//
//  ExpensesViewModel.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import Combine
import SwiftUI
import SwiftData
import PhotosUI
import Vision
import os

/// ViewModel for the Expenses feature
@MainActor
final class ExpensesViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var expenses: [Expense] = []
    @Published var loadState: LoadableState<[Expense]> = .idle
    @Published var searchText = ""
    @Published var selectedCategory: ExpenseCategory?
    @Published var dateRange: DateRange = .thisMonth

    @Published var showingAddExpense = false
    @Published var showingExpenseDetail: Expense?
    @Published var showingFilters = false

    // Receipt scanning
    @Published var isProcessingReceipt = false
    @Published var scannedReceiptData: ScannedReceiptData?

    // MARK: - Properties

    private let modelContext: ModelContext
    private let apiClient = APIClient.shared

    // MARK: - Date Range

    enum DateRange: String, CaseIterable, Identifiable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case thisQuarter = "This Quarter"
        case thisYear = "This Year"
        case custom = "Custom"

        var id: String { rawValue }

        var dateInterval: (start: Date, end: Date) {
            let calendar = Calendar.current
            let now = Date()

            switch self {
            case .thisWeek:
                let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
                return (start, now)
            case .thisMonth:
                let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                return (start, now)
            case .thisQuarter:
                let quarter = (calendar.component(.month, from: now) - 1) / 3
                let startMonth = quarter * 3 + 1
                var components = calendar.dateComponents([.year], from: now)
                components.month = startMonth
                components.day = 1
                let start = calendar.date(from: components)!
                return (start, now)
            case .thisYear:
                let start = calendar.date(from: calendar.dateComponents([.year], from: now))!
                return (start, now)
            case .custom:
                let start = calendar.date(byAdding: .month, value: -1, to: now)!
                return (start, now)
            }
        }
    }

    // MARK: - Computed Properties

    var filteredExpenses: [Expense] {
        var result = expenses

        // Search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { expense in
                expense.vendor?.lowercased().contains(query) == true ||
                expense.expenseDescription?.lowercased().contains(query) == true ||
                expense.category.rawValue.lowercased().contains(query)
            }
        }

        // Category filter
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        return result
    }

    var totalExpenses: Decimal {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    var expensesByCategory: [ExpenseCategory: Decimal] {
        var result: [ExpenseCategory: Decimal] = [:]

        for expense in filteredExpenses {
            result[expense.category, default: 0] += expense.amount
        }

        return result
    }

    var deductibleExpenses: Decimal {
        filteredExpenses
            .filter { $0.isDeductible }
            .reduce(0) { $0 + $1.amount }
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading

    func loadExpenses() async {
        loadState = .loading

        let interval = dateRange.dateInterval

        let startDate = interval.start
        let endDate = interval.end
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate<Expense> { expense in
                expense.expenseDate >= startDate && expense.expenseDate <= endDate
            },
            sortBy: [SortDescriptor(\Expense.expenseDate, order: .reverse)]
        )

        do {
            expenses = try modelContext.fetch(descriptor)
            loadState = .loaded(expenses)

            if NetworkMonitor.shared.isConnected {
                await syncExpenses()
            }
        } catch {
            loadState = .error(AppError.from(error))
            AppLogger.data.error("Failed to fetch expenses: \(error.localizedDescription)")
        }
    }

    func refresh() async {
        guard case .loaded = loadState else {
            await loadExpenses()
            return
        }

        loadState = .refreshing(expenses)
        await loadExpenses()
    }

    private func syncExpenses() async {
        let interval = dateRange.dateInterval

        var filters = ExpenseFilters()
        filters.startDate = interval.start
        filters.endDate = interval.end

        let endpoint = ExpenseEndpoints.list(
            pagination: PaginationParameters(),
            filters: filters
        )

        do {
            let response: [ExpenseResponse] = try await apiClient.request(endpoint)

            for expenseResponse in response {
                await mergeExpense(expenseResponse)
            }

            try modelContext.save()
        } catch {
            AppLogger.sync.error("Failed to sync expenses: \(error.localizedDescription)")
        }
    }

    private func mergeExpense(_ response: ExpenseResponse) async {
        let expenseId = UUID(uuidString: response.id)!
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate<Expense> { $0.id == expenseId }
        )

        do {
            let existing = try modelContext.fetch(descriptor)

            if existing.first != nil {
                // Expense already exists locally, no need to merge
            } else {
                let expense = Expense(
                    id: expenseId,
                    category: ExpenseCategory(rawValue: response.category) ?? .other,
                    amount: Decimal(response.amount),
                    expenseDate: response.date
                )
                expense.vendorName = response.vendor
                expense.expenseDescription = response.description
                expense.isTaxDeductible = response.isDeductible

                modelContext.insert(expense)
            }
        } catch {
            AppLogger.data.error("Failed to merge expense: \(error.localizedDescription)")
        }
    }

    // MARK: - Expense Management

    func addExpense(_ expense: Expense) async {
        modelContext.insert(expense)

        do {
            try modelContext.save()
            expenses.insert(expense, at: 0)

            if NetworkMonitor.shared.isConnected {
                await syncNewExpense(expense)
            }
        } catch {
            AppLogger.data.error("Failed to add expense: \(error.localizedDescription)")
        }
    }

    private func syncNewExpense(_ expense: Expense) async {
        let request = CreateExpenseRequest(
            category: expense.category.rawValue,
            amount: NSDecimalNumber(decimal: expense.amount).doubleValue,
            date: expense.expenseDate,
            description: expense.expenseDescription,
            vendor: expense.vendorName,
            vehicleId: expense.vehicle?.id.uuidString,
            tripId: expense.trip?.id.uuidString,
            paymentMethod: expense.paymentMethod.rawValue,
            isDeductible: expense.isTaxDeductible,
            notes: expense.notes
        )

        do {
            let _: ExpenseResponse = try await apiClient.request(ExpenseEndpoints.create(expense: request))
            try? modelContext.save()

            // Upload receipt if exists
            if let receiptData = expense.receiptOCRData {
                await uploadReceipt(expenseId: expense.id, imageData: receiptData)
            }
        } catch {
            AppLogger.sync.error("Failed to sync expense: \(error.localizedDescription)")
        }
    }

    func updateExpense(_ expense: Expense) async {
        expense.update()

        do {
            try modelContext.save()

            if NetworkMonitor.shared.isConnected {
                await syncUpdatedExpense(expense)
            }
        } catch {
            AppLogger.data.error("Failed to update expense: \(error.localizedDescription)")
        }
    }

    private func syncUpdatedExpense(_ expense: Expense) async {
        let request = UpdateExpenseRequest(
            category: expense.category.rawValue,
            amount: NSDecimalNumber(decimal: expense.amount).doubleValue,
            date: expense.expenseDate,
            description: expense.expenseDescription,
            vendor: expense.vendorName,
            vehicleId: expense.vehicle?.id.uuidString,
            tripId: expense.trip?.id.uuidString,
            paymentMethod: expense.paymentMethod.rawValue,
            isDeductible: expense.isTaxDeductible,
            notes: expense.notes
        )

        do {
            try await apiClient.requestVoid(ExpenseEndpoints.update(id: expense.id.uuidString, expense: request))
            try? modelContext.save()
        } catch {
            AppLogger.sync.error("Failed to sync expense update: \(error.localizedDescription)")
        }
    }

    func deleteExpense(_ expense: Expense) async {
        modelContext.delete(expense)

        do {
            try modelContext.save()
            expenses.removeAll { $0.id == expense.id }

            if NetworkMonitor.shared.isConnected {
                try await apiClient.requestVoid(ExpenseEndpoints.delete(id: expense.id.uuidString))
            }
        } catch {
            AppLogger.data.error("Failed to delete expense: \(error.localizedDescription)")
        }
    }

    // MARK: - Receipt Scanning

    func processReceipt(imageData: Data) async {
        isProcessingReceipt = true

        do {
            // Use Vision to extract text from receipt
            let extractedData = try await extractReceiptData(from: imageData)
            scannedReceiptData = extractedData
        } catch {
            AppLogger.data.error("Failed to process receipt: \(error.localizedDescription)")
        }

        isProcessingReceipt = false
    }

    private func extractReceiptData(from imageData: Data) async throws -> ScannedReceiptData {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            throw AppError.validationFailed("Invalid image data")
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: ScannedReceiptData())
                    return
                }

                var extractedText = ""
                for observation in observations {
                    if let topCandidate = observation.topCandidates(1).first {
                        extractedText += topCandidate.string + "\n"
                    }
                }

                // Parse extracted text
                let data = self.parseReceiptText(extractedText)
                continuation.resume(returning: data)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func parseReceiptText(_ text: String) -> ScannedReceiptData {
        var data = ScannedReceiptData()
        data.rawText = text

        let lines = text.components(separatedBy: .newlines)

        // Extract vendor (usually first line)
        if let firstLine = lines.first {
            data.vendor = firstLine.trimmingCharacters(in: .whitespaces)
        }

        // Extract amounts using regex
        let amountPattern = #"\$?\d+\.\d{2}"#
        if let regex = try? NSRegularExpression(pattern: amountPattern) {
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: range)

            var amounts: [Double] = []
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let amountString = String(text[range]).replacingOccurrences(of: "$", with: "")
                    if let amount = Double(amountString) {
                        amounts.append(amount)
                    }
                }
            }

            // Assume largest amount is the total
            if let maxAmount = amounts.max() {
                data.amount = maxAmount
            }
        }

        // Extract date
        let datePatterns = [
            #"\d{1,2}/\d{1,2}/\d{2,4}"#,
            #"\d{1,2}-\d{1,2}-\d{2,4}"#
        ]

        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                let dateString = String(text[range])
                let formatter = DateFormatter()
                formatter.dateFormat = dateString.contains("-") ? "MM-dd-yyyy" : "MM/dd/yyyy"

                if let date = formatter.date(from: dateString) {
                    data.date = date
                    break
                }
            }
        }

        return data
    }

    private func uploadReceipt(expenseId: UUID, imageData: Data) async {
        // Upload receipt image to server
        do {
            let endpoint = ExpenseEndpoints.uploadReceipt(expenseId: expenseId.uuidString)
            let _: MessageResponse = try await apiClient.upload(
                endpoint,
                fileData: imageData,
                filename: "receipt.jpg",
                mimeType: "image/jpeg"
            )
        } catch {
            AppLogger.sync.error("Failed to upload receipt: \(error.localizedDescription)")
        }
    }

    // MARK: - Filters

    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        dateRange = .thisMonth
    }
}

// MARK: - Scanned Receipt Data

struct ScannedReceiptData: Equatable {
    var vendor: String?
    var amount: Double?
    var date: Date?
    var rawText: String?
}
