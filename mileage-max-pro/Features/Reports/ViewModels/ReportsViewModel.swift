//
//  ReportsViewModel.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import Combine
import SwiftUI
import SwiftData
import PDFKit
import os

/// ViewModel for the Reports feature
@MainActor
final class ReportsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var reportType: ReportType = .mileage
    @Published var dateRange: DateRangeType = .thisYear
    @Published var customStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @Published var customEndDate = Date()

    @Published var isGenerating = false
    @Published var generatedReport: GeneratedReport?
    @Published var reportData: ReportDataSummary?

    @Published var selectedVehicle: Vehicle?
    @Published var includeExpenses = true
    @Published var groupBy: GroupingOption = .month

    // MARK: - Report Types

    enum ReportType: String, CaseIterable, Identifiable {
        case mileage = "Mileage Report"
        case tax = "Tax Summary"
        case expenses = "Expense Report"
        case vehicle = "Vehicle Report"
        case detailed = "Detailed Log"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .mileage: return "road.lanes"
            case .tax: return "dollarsign.circle"
            case .expenses: return "creditcard"
            case .vehicle: return "car"
            case .detailed: return "doc.text"
            }
        }

        var description: String {
            switch self {
            case .mileage:
                return "Summary of all trips and miles driven"
            case .tax:
                return "IRS-ready tax deduction summary"
            case .expenses:
                return "All expenses categorized and totaled"
            case .vehicle:
                return "Per-vehicle mileage and expense breakdown"
            case .detailed:
                return "Complete trip log with all details"
            }
        }
    }

    enum DateRangeType: String, CaseIterable, Identifiable {
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case thisQuarter = "This Quarter"
        case lastQuarter = "Last Quarter"
        case thisYear = "This Year"
        case lastYear = "Last Year"
        case custom = "Custom Range"

        var id: String { rawValue }

        func dateInterval(customStart: Date = Date(), customEnd: Date = Date()) -> (start: Date, end: Date) {
            let calendar = Calendar.current
            let now = Date()

            switch self {
            case .thisMonth:
                let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                return (start, now)

            case .lastMonth:
                let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                let start = calendar.date(byAdding: .month, value: -1, to: thisMonth)!
                let end = calendar.date(byAdding: .day, value: -1, to: thisMonth)!
                return (start, end)

            case .thisQuarter:
                let quarter = (calendar.component(.month, from: now) - 1) / 3
                let startMonth = quarter * 3 + 1
                var components = calendar.dateComponents([.year], from: now)
                components.month = startMonth
                components.day = 1
                let start = calendar.date(from: components)!
                return (start, now)

            case .lastQuarter:
                let quarter = (calendar.component(.month, from: now) - 1) / 3
                let lastQuarter = quarter == 0 ? 3 : quarter - 1
                let lastQuarterYear = quarter == 0 ? calendar.component(.year, from: now) - 1 : calendar.component(.year, from: now)
                let startMonth = lastQuarter * 3 + 1
                var startComponents = DateComponents()
                startComponents.year = lastQuarterYear
                startComponents.month = startMonth
                startComponents.day = 1
                let start = calendar.date(from: startComponents)!

                var endComponents = DateComponents()
                endComponents.year = lastQuarterYear
                endComponents.month = startMonth + 3
                endComponents.day = 0
                let end = calendar.date(from: endComponents)!
                return (start, end)

            case .thisYear:
                let start = calendar.date(from: calendar.dateComponents([.year], from: now))!
                return (start, now)

            case .lastYear:
                let thisYear = calendar.component(.year, from: now)
                var startComponents = DateComponents()
                startComponents.year = thisYear - 1
                startComponents.month = 1
                startComponents.day = 1
                let start = calendar.date(from: startComponents)!

                var endComponents = DateComponents()
                endComponents.year = thisYear - 1
                endComponents.month = 12
                endComponents.day = 31
                let end = calendar.date(from: endComponents)!
                return (start, end)

            case .custom:
                return (customStart, customEnd)
            }
        }
    }

    enum GroupingOption: String, CaseIterable, Identifiable {
        case day = "Daily"
        case week = "Weekly"
        case month = "Monthly"
        case quarter = "Quarterly"

        var id: String { rawValue }
    }

    // MARK: - Properties

    private let modelContext: ModelContext
    private let apiClient = APIClient.shared

    // MARK: - Computed Properties

    var dateInterval: (start: Date, end: Date) {
        dateRange.dateInterval(customStart: customStartDate, customEnd: customEndDate)
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Report Generation

    func generateReport() async {
        isGenerating = true
        generatedReport = nil

        let interval = dateInterval

        do {
            // Fetch data
            let data = try await fetchReportDataSummary(startDate: interval.start, endDate: interval.end)
            reportData = data

            // Generate PDF
            let pdfData = generatePDF(data: data)

            generatedReport = GeneratedReport(
                type: reportType,
                startDate: interval.start,
                endDate: interval.end,
                pdfData: pdfData,
                generatedAt: Date()
            )
        } catch {
            AppLogger.data.error("Failed to generate report: \(error.localizedDescription)")
        }

        isGenerating = false
    }

    private func fetchReportDataSummary(startDate: Date, endDate: Date) async throws -> ReportDataSummary {
        // Fetch trips - filter in memory to avoid predicate issues with enums
        let tripDescriptor = FetchDescriptor<Trip>(
            sortBy: [SortDescriptor(\Trip.startTime)]
        )

        let allTrips = try modelContext.fetch(tripDescriptor)
        let trips = allTrips.filter { trip in
            trip.startTime >= startDate && trip.startTime <= endDate && trip.status == .completed
        }

        // Fetch expenses if included
        var expenses: [Expense] = []
        if includeExpenses {
            let expenseDescriptor = FetchDescriptor<Expense>(
                predicate: #Predicate<Expense> { expense in
                    expense.date >= startDate && expense.date <= endDate
                },
                sortBy: [SortDescriptor(\Expense.date)]
            )
            expenses = try modelContext.fetch(expenseDescriptor)
        }

        // Fetch vehicles
        let vehicleDescriptor = FetchDescriptor<Vehicle>()
        let vehicles = try modelContext.fetch(vehicleDescriptor)

        // Calculate totals
        let totalMiles = trips.reduce(0) { $0 + $1.distanceMiles }
        let businessMiles = trips.filter { $0.category == .business }.reduce(0) { $0 + $1.distanceMiles }
        let personalMiles = trips.filter { $0.category == .personal }.reduce(0) { $0 + $1.distanceMiles }
        let medicalMiles = trips.filter { $0.category == .medical }.reduce(0) { $0 + $1.distanceMiles }
        let charityMiles = trips.filter { $0.category == .charity }.reduce(0) { $0 + $1.distanceMiles }

        // Calculate deduction
        let rate = AppConstants.IRSMileageRates.current
        let businessDeduction = businessMiles * rate.business
        let medicalDeduction = medicalMiles * rate.medical
        let charityDeduction = charityMiles * rate.charity
        let totalDeduction = businessDeduction + medicalDeduction + charityDeduction

        // Calculate expenses totals (convert Decimal to Double)
        let totalExpenses = expenses.reduce(0.0) { $0 + (Double(truncating: $1.amount as NSDecimalNumber)) }
        let deductibleExpenses = expenses.filter { $0.isDeductible }.reduce(0.0) { $0 + (Double(truncating: $1.amount as NSDecimalNumber)) }

        // Group by period
        let groupedTrips = groupTrips(trips, by: groupBy)
        let groupedExpenses = groupExpenses(expenses, by: groupBy)

        return ReportDataSummary(
            startDate: startDate,
            endDate: endDate,
            trips: trips,
            expenses: expenses,
            vehicles: vehicles,
            totalTrips: trips.count,
            totalMiles: totalMiles,
            businessMiles: businessMiles,
            personalMiles: personalMiles,
            medicalMiles: medicalMiles,
            charityMiles: charityMiles,
            businessDeduction: businessDeduction,
            medicalDeduction: medicalDeduction,
            charityDeduction: charityDeduction,
            totalDeduction: totalDeduction,
            totalExpenses: totalExpenses,
            deductibleExpenses: deductibleExpenses,
            irsRate: rate,
            groupedTrips: groupedTrips,
            groupedExpenses: groupedExpenses
        )
    }

    private func groupTrips(_ trips: [Trip], by option: GroupingOption) -> [(period: String, trips: [Trip], miles: Double)] {
        let calendar = Calendar.current
        var grouped: [String: [Trip]] = [:]

        let formatter = DateFormatter()

        switch option {
        case .day:
            formatter.dateFormat = "MMM d, yyyy"
        case .week:
            formatter.dateFormat = "'Week of' MMM d"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
        case .quarter:
            formatter.dateFormat = "QQQ yyyy"
        }

        for trip in trips {
            var dateToUse = trip.startTime

            if option == .week {
                let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: trip.startTime))!
                dateToUse = weekStart
            }

            let key = formatter.string(from: dateToUse)
            grouped[key, default: []].append(trip)
        }

        return grouped.map { (period: $0.key, trips: $0.value, miles: $0.value.reduce(0) { $0 + $1.distanceMiles }) }
            .sorted { $0.period < $1.period }
    }

    private func groupExpenses(_ expenses: [Expense], by option: GroupingOption) -> [(period: String, expenses: [Expense], total: Double)] {
        let calendar = Calendar.current
        var grouped: [String: [Expense]] = [:]

        let formatter = DateFormatter()

        switch option {
        case .day:
            formatter.dateFormat = "MMM d, yyyy"
        case .week:
            formatter.dateFormat = "'Week of' MMM d"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
        case .quarter:
            formatter.dateFormat = "QQQ yyyy"
        }

        for expense in expenses {
            var dateToUse = expense.date

            if option == .week {
                let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: expense.date))!
                dateToUse = weekStart
            }

            let key = formatter.string(from: dateToUse)
            grouped[key, default: []].append(expense)
        }

        return grouped.map { (period: $0.key, expenses: $0.value, total: $0.value.reduce(0.0) { $0 + Double(truncating: $1.amount as NSDecimalNumber) }) }
            .sorted { $0.period < $1.period }
    }

    // MARK: - PDF Generation

    private func generatePDF(data: ReportDataSummary) -> Data {
        let pageWidth: CGFloat = 612 // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let pdfData = pdfRenderer.pdfData { context in
            var currentY: CGFloat = margin

            // Start first page
            context.beginPage()

            // Header
            currentY = drawHeader(in: context.cgContext, at: currentY, width: pageWidth - 2 * margin, margin: margin, data: data)

            // Summary section
            currentY = drawSummary(in: context.cgContext, at: currentY, width: pageWidth - 2 * margin, margin: margin, data: data)

            // Tax Deduction section
            if reportType == .tax || reportType == .mileage {
                currentY = drawTaxDeduction(in: context.cgContext, at: currentY, width: pageWidth - 2 * margin, margin: margin, data: data)
            }

            // Trip details
            if reportType == .detailed || reportType == .mileage {
                currentY = drawTripDetails(
                    in: context,
                    startY: currentY,
                    pageHeight: pageHeight,
                    width: pageWidth - 2 * margin,
                    margin: margin,
                    data: data
                )
            }

            // Expenses section
            if includeExpenses && !data.expenses.isEmpty {
                if currentY > pageHeight - 200 {
                    context.beginPage()
                    currentY = margin
                }
                currentY = drawExpenses(in: context.cgContext, at: currentY, width: pageWidth - 2 * margin, margin: margin, data: data)
            }

            // Footer
            drawFooter(in: context.cgContext, pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)
        }

        return pdfData
    }

    private func drawHeader(in context: CGContext, at y: CGFloat, width: CGFloat, margin: CGFloat, data: ReportDataSummary) -> CGFloat {
        var currentY = y

        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.black
        ]

        let title = reportType.rawValue as NSString
        title.draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttributes)
        currentY += 35

        // Date range
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long

        let dateRangeText = "\(dateFormatter.string(from: data.startDate)) - \(dateFormatter.string(from: data.endDate))"
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.gray
        ]
        (dateRangeText as NSString).draw(at: CGPoint(x: margin, y: currentY), withAttributes: dateAttributes)
        currentY += 30

        // Divider
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: margin, y: currentY))
        context.addLine(to: CGPoint(x: margin + width, y: currentY))
        context.strokePath()
        currentY += 20

        return currentY
    }

    private func drawSummary(in context: CGContext, at y: CGFloat, width: CGFloat, margin: CGFloat, data: ReportDataSummary) -> CGFloat {
        var currentY = y

        let sectionTitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]

        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.black
        ]

        // Section title
        ("Summary" as NSString).draw(at: CGPoint(x: margin, y: currentY), withAttributes: sectionTitleAttrs)
        currentY += 25

        // Stats
        let stats: [(String, String)] = [
            ("Total Trips:", "\(data.totalTrips)"),
            ("Total Miles:", String(format: "%.1f mi", data.totalMiles)),
            ("Business Miles:", String(format: "%.1f mi", data.businessMiles)),
            ("Personal Miles:", String(format: "%.1f mi", data.personalMiles)),
            ("Medical Miles:", String(format: "%.1f mi", data.medicalMiles)),
            ("Charity Miles:", String(format: "%.1f mi", data.charityMiles))
        ]

        for (label, value) in stats {
            (label as NSString).draw(at: CGPoint(x: margin, y: currentY), withAttributes: labelAttrs)
            (value as NSString).draw(at: CGPoint(x: margin + 150, y: currentY), withAttributes: valueAttrs)
            currentY += 18
        }

        currentY += 15
        return currentY
    }

    private func drawTaxDeduction(in context: CGContext, at y: CGFloat, width: CGFloat, margin: CGFloat, data: ReportDataSummary) -> CGFloat {
        var currentY = y

        let sectionTitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]

        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.black
        ]

        let totalAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: UIColor(red: 0, green: 0.5, blue: 0, alpha: 1)
        ]

        // Section title
        ("Tax Deduction Summary" as NSString).draw(at: CGPoint(x: margin, y: currentY), withAttributes: sectionTitleAttrs)
        currentY += 25

        // IRS rates
        ("IRS Standard Mileage Rates for \(Calendar.current.component(.year, from: data.startDate)):" as NSString)
            .draw(at: CGPoint(x: margin, y: currentY), withAttributes: labelAttrs)
        currentY += 18

        let rates = [
            ("Business:", String(format: "$%.3f/mile", data.irsRate.business)),
            ("Medical:", String(format: "$%.2f/mile", data.irsRate.medical)),
            ("Charity:", String(format: "$%.2f/mile", data.irsRate.charity))
        ]

        for (label, value) in rates {
            ("  \(label)" as NSString).draw(at: CGPoint(x: margin, y: currentY), withAttributes: labelAttrs)
            (value as NSString).draw(at: CGPoint(x: margin + 100, y: currentY), withAttributes: valueAttrs)
            currentY += 16
        }

        currentY += 10

        // Deduction calculations
        let deductions = [
            ("Business Deduction:", String(format: "$%.2f", data.businessDeduction)),
            ("Medical Deduction:", String(format: "$%.2f", data.medicalDeduction)),
            ("Charity Deduction:", String(format: "$%.2f", data.charityDeduction))
        ]

        for (label, value) in deductions {
            (label as NSString).draw(at: CGPoint(x: margin, y: currentY), withAttributes: labelAttrs)
            (value as NSString).draw(at: CGPoint(x: margin + 150, y: currentY), withAttributes: valueAttrs)
            currentY += 18
        }

        currentY += 5

        // Total
        ("TOTAL TAX DEDUCTION:" as NSString).draw(at: CGPoint(x: margin, y: currentY), withAttributes: labelAttrs)
        (String(format: "$%.2f", data.totalDeduction) as NSString).draw(at: CGPoint(x: margin + 150, y: currentY), withAttributes: totalAttrs)
        currentY += 30

        return currentY
    }

    private func drawTripDetails(in renderer: UIGraphicsPDFRendererContext, startY: CGFloat, pageHeight: CGFloat, width: CGFloat, margin: CGFloat, data: ReportDataSummary) -> CGFloat {
        var currentY = startY

        let sectionTitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: UIColor.darkGray
        ]

        let cellAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.black
        ]

        // Section title
        ("Trip Details" as NSString).draw(at: CGPoint(x: margin, y: currentY), withAttributes: sectionTitleAttrs)
        currentY += 25

        // Table header
        let columns: [(String, CGFloat)] = [
            ("Date", 70),
            ("From", 120),
            ("To", 120),
            ("Miles", 45),
            ("Category", 70),
            ("Purpose", 80)
        ]

        var xOffset = margin
        for (header, columnWidth) in columns {
            (header as NSString).draw(at: CGPoint(x: xOffset, y: currentY), withAttributes: headerAttrs)
            xOffset += columnWidth
        }
        currentY += 18

        // Draw trips
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy"

        for trip in data.trips.prefix(50) { // Limit to 50 for PDF size
            if currentY > pageHeight - 60 {
                renderer.beginPage()
                currentY = margin
            }

            xOffset = margin

            // Date
            (dateFormatter.string(from: trip.startTime) as NSString).draw(at: CGPoint(x: xOffset, y: currentY), withAttributes: cellAttrs)
            xOffset += 70

            // From
            let fromText = (trip.startAddress ?? "Unknown").prefix(20)
            (String(fromText) as NSString).draw(at: CGPoint(x: xOffset, y: currentY), withAttributes: cellAttrs)
            xOffset += 120

            // To
            let toText = (trip.endAddress ?? "Unknown").prefix(20)
            (String(toText) as NSString).draw(at: CGPoint(x: xOffset, y: currentY), withAttributes: cellAttrs)
            xOffset += 120

            // Miles
            (String(format: "%.1f", trip.distanceMiles) as NSString).draw(at: CGPoint(x: xOffset, y: currentY), withAttributes: cellAttrs)
            xOffset += 45

            // Category
            (trip.category.rawValue as NSString).draw(at: CGPoint(x: xOffset, y: currentY), withAttributes: cellAttrs)
            xOffset += 70

            // Purpose
            let purposeText = (trip.purpose ?? "").prefix(15)
            (String(purposeText) as NSString).draw(at: CGPoint(x: xOffset, y: currentY), withAttributes: cellAttrs)

            currentY += 14
        }

        currentY += 15
        return currentY
    }

    private func drawExpenses(in context: CGContext, at y: CGFloat, width: CGFloat, margin: CGFloat, data: ReportDataSummary) -> CGFloat {
        var currentY = y

        let sectionTitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]

        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.black
        ]

        // Section title
        ("Expenses Summary" as NSString).draw(at: CGPoint(x: margin, y: currentY), withAttributes: sectionTitleAttrs)
        currentY += 25

        // Group by category
        var byCategory: [ExpenseCategory: Double] = [:]
        for expense in data.expenses {
            byCategory[expense.category, default: 0] += Double(truncating: expense.amount as NSDecimalNumber)
        }

        for (category, amount) in byCategory.sorted(by: { $0.value > $1.value }) {
            (category.rawValue as NSString).draw(at: CGPoint(x: margin, y: currentY), withAttributes: labelAttrs)
            (String(format: "$%.2f", amount) as NSString).draw(at: CGPoint(x: margin + 150, y: currentY), withAttributes: valueAttrs)
            currentY += 18
        }

        currentY += 10

        // Totals
        ("Total Expenses:" as NSString).draw(at: CGPoint(x: margin, y: currentY), withAttributes: labelAttrs)
        (String(format: "$%.2f", data.totalExpenses) as NSString).draw(at: CGPoint(x: margin + 150, y: currentY), withAttributes: valueAttrs)
        currentY += 18

        ("Deductible Expenses:" as NSString).draw(at: CGPoint(x: margin, y: currentY), withAttributes: labelAttrs)
        (String(format: "$%.2f", data.deductibleExpenses) as NSString).draw(at: CGPoint(x: margin + 150, y: currentY), withAttributes: valueAttrs)
        currentY += 25

        return currentY
    }

    private func drawFooter(in context: CGContext, pageWidth: CGFloat, pageHeight: CGFloat, margin: CGFloat) {
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.gray
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let footerText = "Generated by MileageMax Pro on \(dateFormatter.string(from: Date()))"
        (footerText as NSString).draw(at: CGPoint(x: margin, y: pageHeight - 30), withAttributes: footerAttrs)
    }

    // MARK: - Export

    func shareReport() -> URL? {
        guard let report = generatedReport else { return nil }

        let fileName = "\(reportType.rawValue.replacingOccurrences(of: " ", with: "_"))_\(ISO8601DateFormatter().string(from: Date())).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try report.pdfData.write(to: tempURL)
            return tempURL
        } catch {
            AppLogger.data.error("Failed to write PDF: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Report Data Summary

struct ReportDataSummary {
    let startDate: Date
    let endDate: Date
    let trips: [Trip]
    let expenses: [Expense]
    let vehicles: [Vehicle]
    let totalTrips: Int
    let totalMiles: Double
    let businessMiles: Double
    let personalMiles: Double
    let medicalMiles: Double
    let charityMiles: Double
    let businessDeduction: Double
    let medicalDeduction: Double
    let charityDeduction: Double
    let totalDeduction: Double
    let totalExpenses: Double
    let deductibleExpenses: Double
    let irsRate: AppConstants.IRSMileageRates.Rate
    let groupedTrips: [(period: String, trips: [Trip], miles: Double)]
    let groupedExpenses: [(period: String, expenses: [Expense], total: Double)]
}

// MARK: - Generated Report

struct GeneratedReport {
    let type: ReportsViewModel.ReportType
    let startDate: Date
    let endDate: Date
    let pdfData: Data
    let generatedAt: Date
}
