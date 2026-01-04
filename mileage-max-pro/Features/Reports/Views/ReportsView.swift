//
//  ReportsView.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI
import SwiftData
import PDFKit
import os

/// Main view for generating and viewing reports
struct ReportsView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ReportsContentView(modelContext: modelContext)
    }
}

/// Internal content view with initialized ViewModel
private struct ReportsContentView: View {
    @StateObject private var viewModel: ReportsViewModel

    @State private var showingReportPreview = false
    @State private var showingShareSheet = false

    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: ReportsViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Report Type Selection
                    reportTypeSection

                    // Date Range Selection
                    dateRangeSection

                    // Options
                    optionsSection

                    // Generate Button
                    generateButton

                    // Generated Report Preview
                    if let report = viewModel.generatedReport {
                        reportPreviewSection(report)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Reports")
            .sheet(isPresented: $showingReportPreview) {
                if let report = viewModel.generatedReport {
                    PDFPreviewView(pdfData: report.pdfData)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = viewModel.shareReport() {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    // MARK: - Report Type Section

    private var reportTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Report Type")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(ReportsViewModel.ReportType.allCases) { type in
                    ReportTypeCard(
                        type: type,
                        isSelected: viewModel.reportType == type
                    ) {
                        viewModel.reportType = type
                    }
                }
            }
        }
    }

    // MARK: - Date Range Section

    private var dateRangeSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Date Range")
                    .font(.headline)

                Picker("Date Range", selection: $viewModel.dateRange) {
                    ForEach(ReportsViewModel.DateRangeType.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)

                if viewModel.dateRange == .custom {
                    VStack(spacing: 12) {
                        DatePicker(
                            "Start Date",
                            selection: $viewModel.customStartDate,
                            displayedComponents: .date
                        )

                        DatePicker(
                            "End Date",
                            selection: $viewModel.customEndDate,
                            in: viewModel.customStartDate...,
                            displayedComponents: .date
                        )
                    }
                }

                // Display selected range
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)

                    let interval = viewModel.dateInterval
                    Text("\(interval.start.formatted(date: .abbreviated, time: .omitted)) - \(interval.end.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Options")
                    .font(.headline)

                Toggle("Include Expenses", isOn: $viewModel.includeExpenses)

                Picker("Group By", selection: $viewModel.groupBy) {
                    ForEach(ReportsViewModel.GroupingOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            Task {
                await viewModel.generateReport()
            }
        } label: {
            HStack {
                if viewModel.isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "doc.badge.plus")
                }

                Text(viewModel.isGenerating ? "Generating..." : "Generate Report")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(GlassButtonStyleWrapper())
        .disabled(viewModel.isGenerating)
    }

    // MARK: - Report Preview Section

    private func reportPreviewSection(_ report: GeneratedReport) -> some View {
        GlassCard {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(report.type.rawValue)
                            .font(.headline)

                        Text("Generated \(report.generatedAt.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(ColorConstants.success)
                }

                Divider()

                // Stats summary
                if let data = viewModel.reportData {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ReportStatBox(
                            title: "Trips",
                            value: "\(data.totalTrips)"
                        )

                        ReportStatBox(
                            title: "Miles",
                            value: String(format: "%.0f", data.totalMiles)
                        )

                        ReportStatBox(
                            title: "Deduction",
                            value: String(format: "$%.0f", data.totalDeduction)
                        )
                    }
                }

                Divider()

                // Actions
                HStack(spacing: 12) {
                    Button {
                        showingReportPreview = true
                    } label: {
                        Label("Preview", systemImage: "eye")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        showingShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }
}

// MARK: - Report Type Card

struct ReportTypeCard: View {
    let type: ReportsViewModel.ReportType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? ColorConstants.Text.inverse : ColorConstants.primary)

                VStack(spacing: 4) {
                    Text(type.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(isSelected ? ColorConstants.Text.inverse : ColorConstants.Text.primary)

                    Text(type.description)
                        .font(.caption2)
                        .foregroundStyle(isSelected ? ColorConstants.Text.inverse.opacity(0.8) : ColorConstants.Text.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? ColorConstants.primary : ColorConstants.Surface.secondaryGrouped)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Report Stat Box

struct ReportStatBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - PDF Preview View

struct PDFPreviewView: View {
    @Environment(\.dismiss) private var dismiss

    let pdfData: Data

    var body: some View {
        NavigationStack {
            PDFKitView(data: pdfData)
                .navigationTitle("Report Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - PDFKit View

struct PDFKitView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        if let document = PDFDocument(data: data) {
            pdfView.document = document
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Tax Summary View

struct TaxSummaryView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var taxData: TaxSummaryData?
    @State private var isLoading = true

    private let years = Array((2020...Calendar.current.component(.year, from: Date())).reversed())

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Year Picker
                Picker("Tax Year", selection: $year) {
                    ForEach(years, id: \.self) { y in
                        Text(String(y)).tag(y)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: year) { _, _ in
                    loadTaxData()
                }

                if isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if let data = taxData {
                    // Summary Card
                    GlassCard {
                        VStack(spacing: 16) {
                            Text("Tax Year \(year)")
                                .font(.title2)
                                .fontWeight(.bold)

                            Divider()

                            // Total Deduction
                            VStack(spacing: 4) {
                                Text("Total Tax Deduction")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text(data.totalDeduction, format: .currency(code: "USD"))
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundStyle(ColorConstants.success)
                            }
                        }
                        .padding()
                    }

                    // Mileage Breakdown
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Mileage Breakdown")
                                .font(.headline)

                            TaxLineItem(
                                category: "Business",
                                miles: data.businessMiles,
                                rate: data.rate.business,
                                deduction: data.businessDeduction
                            )

                            TaxLineItem(
                                category: "Medical",
                                miles: data.medicalMiles,
                                rate: data.rate.medical,
                                deduction: data.medicalDeduction
                            )

                            TaxLineItem(
                                category: "Charity",
                                miles: data.charityMiles,
                                rate: data.rate.charity,
                                deduction: data.charityDeduction
                            )

                            Divider()

                            HStack {
                                Text("Total Miles")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(String(format: "%.1f mi", data.totalMiles))
                                    .fontWeight(.bold)
                            }
                        }
                        .padding()
                    }

                    // Expenses
                    if data.deductibleExpenses > 0 {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Deductible Expenses")
                                    .font(.headline)

                                HStack {
                                    Text("Total Deductible")
                                    Spacer()
                                    Text(data.deductibleExpenses, format: .currency(code: "USD"))
                                        .fontWeight(.bold)
                                }

                                Text("Note: This is in addition to mileage deduction. You can deduct actual expenses OR mileage, not both.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                        }
                    }

                    // IRS Rates
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("IRS Standard Mileage Rates (\(year))")
                                .font(.headline)

                            HStack {
                                Text("Business")
                                Spacer()
                                Text(String(format: "$%.3f/mile", data.rate.business))
                            }

                            HStack {
                                Text("Medical/Moving")
                                Spacer()
                                Text(String(format: "$%.2f/mile", data.rate.medical))
                            }

                            HStack {
                                Text("Charity")
                                Spacer()
                                Text(String(format: "$%.2f/mile", data.rate.charity))
                            }
                        }
                        .padding()
                    }

                    // Disclaimer
                    Text("This is an estimate only. Consult a tax professional for accurate tax advice.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Tax Summary")
        .task {
            loadTaxData()
        }
    }

    private func loadTaxData() {
        isLoading = true

        Task {
            let calendar = Calendar.current
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = 1
            startComponents.day = 1
            let startDate = calendar.date(from: startComponents)!

            var endComponents = DateComponents()
            endComponents.year = year
            endComponents.month = 12
            endComponents.day = 31
            let endDate = calendar.date(from: endComponents)!

            // Fetch trips - filter in memory to avoid predicate issues with enums
            let tripDescriptor = FetchDescriptor<Trip>()
            let expenseDescriptor = FetchDescriptor<Expense>()

            do {
                let allTrips = try modelContext.fetch(tripDescriptor)
                let trips = allTrips.filter { trip in
                    trip.startTime >= startDate && trip.startTime <= endDate && trip.status == .completed
                }

                let allExpenses = try modelContext.fetch(expenseDescriptor)
                let expenses = allExpenses.filter { expense in
                    expense.date >= startDate && expense.date <= endDate && expense.isDeductible
                }

                let rate = AppConstants.IRSMileageRates.current

                let businessMiles = trips.filter { $0.category == .business }.reduce(0) { $0 + $1.distanceMiles }
                let medicalMiles = trips.filter { $0.category == .medical }.reduce(0) { $0 + $1.distanceMiles }
                let charityMiles = trips.filter { $0.category == .charity }.reduce(0) { $0 + $1.distanceMiles }

                let businessDeduction = businessMiles * rate.business
                let medicalDeduction = medicalMiles * rate.medical
                let charityDeduction = charityMiles * rate.charity

                taxData = TaxSummaryData(
                    year: year,
                    totalMiles: trips.reduce(0) { $0 + $1.distanceMiles },
                    businessMiles: businessMiles,
                    medicalMiles: medicalMiles,
                    charityMiles: charityMiles,
                    businessDeduction: businessDeduction,
                    medicalDeduction: medicalDeduction,
                    charityDeduction: charityDeduction,
                    totalDeduction: businessDeduction + medicalDeduction + charityDeduction,
                    deductibleExpenses: expenses.reduce(0.0) { $0 + Double(truncating: $1.amount as NSDecimalNumber) },
                    rate: rate
                )
            } catch {
                AppLogger.data.error("Failed to load tax data: \(error.localizedDescription)")
            }

            isLoading = false
        }
    }
}

// MARK: - Tax Summary Data

struct TaxSummaryData {
    let year: Int
    let totalMiles: Double
    let businessMiles: Double
    let medicalMiles: Double
    let charityMiles: Double
    let businessDeduction: Double
    let medicalDeduction: Double
    let charityDeduction: Double
    let totalDeduction: Double
    let deductibleExpenses: Double
    let rate: AppConstants.IRSMileageRates.Rate
}

// MARK: - Tax Line Item

struct TaxLineItem: View {
    let category: String
    let miles: Double
    let rate: Double
    let deduction: Double

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(category)
                    .fontWeight(.medium)
                Spacer()
                Text(deduction, format: .currency(code: "USD"))
                    .fontWeight(.semibold)
                    .foregroundStyle(ColorConstants.success)
            }

            HStack {
                Text(String(format: "%.1f mi × $%.3f", miles, rate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        Text("Reports Preview")
    }
}
