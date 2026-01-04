//
//  ExpensesListView.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI
import SwiftData
import PhotosUI

/// List view for managing expenses
struct ExpensesListView: View {

    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ExpensesViewModel

    @State private var showingAddExpense = false
    @State private var showingReceiptScanner = false
    @State private var expenseToDelete: Expense?
    @State private var showingDeleteConfirmation = false

    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: ExpensesViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.loadState {
                case .idle, .loading:
                    loadingView

                case .loaded, .refreshing:
                    if viewModel.expenses.isEmpty {
                        emptyStateView
                    } else {
                        expensesContent
                    }

                case .error(let error):
                    errorView(error)
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(ExpensesViewModel.DateRange.allCases, id: \.self) { range in
                            Button {
                                viewModel.dateRange = range
                                Task {
                                    await viewModel.loadExpenses()
                                }
                            } label: {
                                HStack {
                                    Text(range.rawValue)
                                    if viewModel.dateRange == range {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.dateRange.rawValue)
                            Image(systemName: "chevron.down")
                        }
                        .font(.subheadline)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingAddExpense = true
                        } label: {
                            Label("Add Manually", systemImage: "plus")
                        }

                        Button {
                            showingReceiptScanner = true
                        } label: {
                            Label("Scan Receipt", systemImage: "camera")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search expenses")
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView { expense in
                    Task {
                        await viewModel.addExpense(expense)
                    }
                }
            }
            .sheet(isPresented: $showingReceiptScanner) {
                ReceiptScannerView(viewModel: viewModel)
            }
            .confirmationDialog(
                "Delete Expense",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let expense = expenseToDelete {
                        Task {
                            await viewModel.deleteExpense(expense)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .task {
                await viewModel.loadExpenses()
            }
        }
    }

    // MARK: - Expenses Content

    private var expensesContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary Card
                summaryCard

                // Category Filter
                categoryFilter

                // Expenses List
                expensesList
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Expenses")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.totalExpenses, format: .currency(code: "USD"))
                            .font(.title)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Deductible")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.deductibleExpenses, format: .currency(code: "USD"))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                }

                Divider()

                // Category breakdown
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(Array(viewModel.expensesByCategory.sorted { $0.value > $1.value }.prefix(6)), id: \.key) { category, amount in
                        CategorySummaryItem(category: category, amount: amount)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All",
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    viewModel.selectedCategory = nil
                }

                ForEach(ExpenseCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.rawValue,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Expenses List

    private var expensesList: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.filteredExpenses) { expense in
                NavigationLink(value: expense) {
                    ExpenseRowView(expense: expense)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        // Edit action
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        expenseToDelete = expense
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationDestination(for: Expense.self) { expense in
            ExpenseDetailView(expense: expense, viewModel: viewModel)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading expenses...")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Expenses", systemImage: "dollarsign.circle")
        } description: {
            Text("Track your business expenses and scan receipts")
        } actions: {
            HStack {
                Button {
                    showingAddExpense = true
                } label: {
                    Text("Add Expense")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    showingReceiptScanner = true
                } label: {
                    Label("Scan Receipt", systemImage: "camera")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Error View

    private func errorView(_ error: AppError) -> some View {
        ContentUnavailableView {
            Label("Error Loading Expenses", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Retry") {
                Task {
                    await viewModel.loadExpenses()
                }
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Category Summary Item

struct CategorySummaryItem: View {
    let category: ExpenseCategory
    let amount: Decimal

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: categoryIcon)
                .font(.title3)
                .foregroundStyle(categoryColor)

            Text(NSDecimalNumber(decimal: amount).doubleValue, format: .currency(code: "USD"))
                .font(.caption)
                .fontWeight(.medium)

            Text(category.rawValue)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var categoryIcon: String {
        switch category {
        case .fuel: return "fuelpump.fill"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .insurance: return "shield.fill"
        case .parking: return "parkingsign"
        case .tolls: return "road.lanes"
        case .carWash: return "drop.fill"
        case .registration: return "doc.fill"
        case .repairs: return "wrench.and.screwdriver"
        case .supplies: return "shippingbox.fill"
        case .phone: return "iphone"
        case .equipment: return "gearshape.fill"
        case .meals: return "fork.knife"
        case .lodging: return "bed.double.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    private var categoryColor: Color {
        switch category {
        case .fuel: return ColorConstants.ExpenseCategory.fuel
        case .maintenance: return ColorConstants.ExpenseCategory.maintenance
        case .insurance: return ColorConstants.ExpenseCategory.insurance
        case .parking: return ColorConstants.ExpenseCategory.parking
        case .tolls: return ColorConstants.ExpenseCategory.tolls
        case .carWash: return ColorConstants.ExpenseCategory.carWash
        case .registration: return ColorConstants.ExpenseCategory.registration
        case .repairs: return ColorConstants.ExpenseCategory.repairs
        case .supplies: return ColorConstants.ExpenseCategory.supplies
        case .phone: return ColorConstants.primary
        case .equipment: return ColorConstants.warning
        case .meals: return ColorConstants.error
        case .lodging: return ColorConstants.secondary
        case .other: return ColorConstants.ExpenseCategory.other
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .medium : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? ColorConstants.primary : ColorConstants.Surface.secondaryGrouped)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Expense Row View

struct ExpenseRowView: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: categoryIcon)
                    .font(.title3)
                    .foregroundStyle(categoryColor)
            }

            // Expense Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(expense.vendor ?? expense.category.rawValue)
                        .font(.headline)

                    Spacer()

                    Text(expense.amount, format: .currency(code: "USD"))
                        .font(.headline)
                }

                HStack {
                    Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if expense.isDeductible {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Label("Deductible", systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    Spacer()

                    if expense.receiptImageData != nil {
                        Image(systemName: "doc.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var categoryIcon: String {
        switch expense.category {
        case .fuel: return "fuelpump.fill"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .insurance: return "shield.fill"
        case .parking: return "parkingsign"
        case .tolls: return "road.lanes"
        case .carWash: return "drop.fill"
        case .registration: return "doc.fill"
        case .repairs: return "wrench.and.screwdriver"
        case .supplies: return "shippingbox.fill"
        case .phone: return "iphone"
        case .equipment: return "gearshape.fill"
        case .meals: return "fork.knife"
        case .lodging: return "bed.double.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    private var categoryColor: Color {
        switch expense.category {
        case .fuel: return .orange
        case .maintenance: return .blue
        case .insurance: return .purple
        case .parking: return .green
        case .tolls: return .cyan
        case .carWash: return .teal
        case .registration: return .indigo
        case .repairs: return .red
        case .supplies: return .brown
        case .phone: return .mint
        case .equipment: return .yellow
        case .meals: return .pink
        case .lodging: return .secondary
        case .other: return .gray
        }
    }
}

// MARK: - Add Expense View

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (Expense) -> Void

    @State private var amount = ""
    @State private var category: ExpenseCategory = .fuel
    @State private var vendor = ""
    @State private var expenseDescription = ""
    @State private var date = Date()
    @State private var isDeductible = true
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var receiptImage: UIImage?

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    .font(.title2)
                }

                Section("Details") {
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }

                    TextField("Vendor / Merchant", text: $vendor)

                    TextField("Description (optional)", text: $expenseDescription, axis: .vertical)
                        .lineLimit(2...4)

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section {
                    Toggle("Tax Deductible", isOn: $isDeductible)
                } footer: {
                    Text("Mark as deductible for business-related expenses")
                }

                Section("Receipt") {
                    if let image = receiptImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    receiptImage = nil
                                    selectedPhoto = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white, .black.opacity(0.5))
                                }
                                .padding(8)
                            }
                    } else {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Add Receipt Photo", systemImage: "camera")
                        }
                    }
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExpense()
                    }
                    .disabled(!isValid)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        receiptImage = image
                    }
                }
            }
        }
    }

    private var isValid: Bool {
        guard let value = Double(amount), value > 0 else { return false }
        return true
    }

    private func saveExpense() {
        guard let amountValue = Double(amount) else { return }

        let expense = Expense(
            category: category,
            amount: Decimal(amountValue),
            expenseDate: date
        )
        expense.vendor = vendor.isEmpty ? nil : vendor
        expense.expenseDescription = expenseDescription.isEmpty ? nil : expenseDescription
        expense.isDeductible = isDeductible

        if let image = receiptImage,
           let data = image.jpegData(compressionQuality: 0.8) {
            expense.receiptOCRData = data
        }

        onSave(expense)
        dismiss()
    }
}

// MARK: - Receipt Scanner View

struct ReceiptScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ExpensesViewModel

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var showingCamera = false

    @State private var amount = ""
    @State private var vendor = ""
    @State private var date = Date()
    @State private var category: ExpenseCategory = .fuel

    var body: some View {
        NavigationStack {
            mainContent
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Scan Receipt")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .onChange(of: selectedPhoto) { _, newValue in
                    handlePhotoSelection(newValue)
                }
                .onChange(of: viewModel.scannedReceiptData) { _, data in
                    handleScannedData(data)
                }
                .fullScreenCover(isPresented: $showingCamera) {
                    cameraView
                }
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                imageSection
                if capturedImage != nil {
                    extractedDataForm
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var imageSection: some View {
        if let image = capturedImage {
            capturedImageView(image: image)
        } else {
            emptyImageView
        }
    }

    private func capturedImageView(image: UIImage) -> some View {
        VStack(spacing: 16) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            if viewModel.isProcessingReceipt {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Processing receipt...")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var emptyImageView: some View {
        VStack(spacing: 16) {
            placeholderRectangle
            captureButtons
        }
    }

    private var placeholderRectangle: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemGray5))
            .frame(height: 200)
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "doc.viewfinder")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Capture or select a receipt")
                        .foregroundStyle(.secondary)
                }
            }
    }

    private var captureButtons: some View {
        HStack(spacing: 16) {
            Button {
                showingCamera = true
            } label: {
                Label("Camera", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Library", systemImage: "photo.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private var extractedDataForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Extracted Data")
                .font(.headline)

            formFields
        }
    }

    private var formFields: some View {
        VStack(spacing: 12) {
            amountRow
            Divider()
            vendorRow
            Divider()
            DatePicker("Date", selection: $date, displayedComponents: .date)
            Divider()
            categoryPicker
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var amountRow: some View {
        HStack {
            Text("Amount")
                .foregroundStyle(.secondary)
            Spacer()
            HStack {
                Text("$")
                TextField("0.00", text: $amount)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            .frame(width: 120)
        }
    }

    private var vendorRow: some View {
        HStack {
            Text("Vendor")
                .foregroundStyle(.secondary)
            Spacer()
            TextField("Merchant name", text: $vendor)
                .multilineTextAlignment(.trailing)
        }
    }

    private var categoryPicker: some View {
        Picker("Category", selection: $category) {
            ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                Text(cat.rawValue).tag(cat)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") { saveScannedExpense() }
                .disabled(capturedImage == nil || amount.isEmpty)
        }
    }

    private var cameraView: some View {
        CameraView { image in
            capturedImage = image
            if let data = image.jpegData(compressionQuality: 0.8) {
                Task {
                    await viewModel.processReceipt(imageData: data)
                }
            }
        }
    }

    private func handlePhotoSelection(_ newValue: PhotosPickerItem?) {
        Task {
            if let data = try? await newValue?.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                capturedImage = image
                await viewModel.processReceipt(imageData: data)
            }
        }
    }

    private func handleScannedData(_ data: ScannedReceiptData?) {
        guard let data = data else { return }
        if let scannedAmount = data.amount {
            amount = String(format: "%.2f", scannedAmount)
        }
        if let scannedVendor = data.vendor {
            vendor = scannedVendor
        }
        if let scannedDate = data.date {
            date = scannedDate
        }
    }

    private func saveScannedExpense() {
        guard let amountValue = Double(amount),
              let image = capturedImage else { return }

        let expense = Expense(
            category: category,
            amount: Decimal(amountValue),
            expenseDate: date
        )
        expense.vendor = vendor.isEmpty ? nil : vendor
        expense.isDeductible = true

        if let data = image.jpegData(compressionQuality: 0.8) {
            expense.receiptOCRData = data
        }

        Task {
            await viewModel.addExpense(expense)
            dismiss()
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void

        init(onCapture: @escaping (UIImage) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Expense Detail View

struct ExpenseDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let expense: Expense
    @ObservedObject var viewModel: ExpensesViewModel

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Amount Card
                GlassCard {
                    VStack(spacing: 8) {
                        Text(expense.category.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(expense.amount, format: .currency(code: "USD"))
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        if expense.isDeductible {
                            Label("Tax Deductible", systemImage: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }

                // Details Card
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        if let vendor = expense.vendor {
                            DetailRow(label: "Vendor", value: vendor)
                        }

                        DetailRow(
                            label: "Date",
                            value: expense.date.formatted(date: .long, time: .omitted)
                        )

                        DetailRow(label: "Category", value: expense.category.rawValue)

                        if let description = expense.expenseDescription {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Description")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(description)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                }

                // Receipt Image
                if let imageData = expense.receiptImageData,
                   let image = UIImage(data: imageData) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Receipt")
                                .font(.headline)

                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding()
                    }
                }

                // Actions
                VStack(spacing: 12) {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Expense", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyleWrapper())

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Expense", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Expense Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            EditExpenseView(expense: expense) {
                Task {
                    await viewModel.updateExpense(expense)
                }
            }
        }
        .confirmationDialog(
            "Delete Expense",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteExpense(expense)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Edit Expense View

struct EditExpenseView: View {
    @Environment(\.dismiss) private var dismiss

    let expense: Expense
    let onSave: () -> Void

    @State private var amount: String
    @State private var category: ExpenseCategory
    @State private var vendor: String
    @State private var expenseDescription: String
    @State private var date: Date
    @State private var isDeductible: Bool

    init(expense: Expense, onSave: @escaping () -> Void) {
        self.expense = expense
        self.onSave = onSave
        _amount = State(initialValue: String(format: "%.2f", NSDecimalNumber(decimal: expense.amount).doubleValue))
        _category = State(initialValue: expense.category)
        _vendor = State(initialValue: expense.vendor ?? "")
        _expenseDescription = State(initialValue: expense.expenseDescription ?? "")
        _date = State(initialValue: expense.date)
        _isDeductible = State(initialValue: expense.isDeductible)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    HStack {
                        Text("$")
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Details") {
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }

                    TextField("Vendor", text: $vendor)

                    TextField("Description", text: $expenseDescription, axis: .vertical)

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section {
                    Toggle("Tax Deductible", isOn: $isDeductible)
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(Double(amount) == nil)
                }
            }
        }
    }

    private func saveChanges() {
        guard let amountValue = Double(amount) else { return }

        expense.amount = Decimal(amountValue)
        expense.category = category
        expense.vendor = vendor.isEmpty ? nil : vendor
        expense.expenseDescription = expenseDescription.isEmpty ? nil : expenseDescription
        expense.date = date
        expense.isDeductible = isDeductible

        onSave()
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Expense.self, configurations: config)

    return ExpensesListView(modelContext: container.mainContext)
        .modelContainer(container)
}
