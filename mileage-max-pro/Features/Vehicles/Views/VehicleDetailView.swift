//
//  VehicleDetailView.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI
import SwiftData
import Charts
import os

/// Detailed view for a single vehicle
struct VehicleDetailView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let vehicle: Vehicle
    @ObservedObject var viewModel: VehiclesViewModel

    @State private var showingEditSheet = false
    @State private var showingMaintenanceSheet = false
    @State private var showingOdometerUpdate = false
    @State private var showingDeleteConfirmation = false

    @State private var tripStats: VehicleTripStats?
    @State private var maintenanceRecords: [MaintenanceRecord] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Vehicle Header
                vehicleHeader

                // Quick Stats
                statsGrid

                // Trip History Chart
                tripHistoryChart

                // Maintenance Section
                maintenanceSection

                // Vehicle Details
                vehicleDetailsCard

                // Actions
                actionsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(vehicle.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Vehicle", systemImage: "pencil")
                    }

                    Button {
                        showingOdometerUpdate = true
                    } label: {
                        Label("Update Odometer", systemImage: "gauge.with.needle")
                    }

                    Button {
                        showingMaintenanceSheet = true
                    } label: {
                        Label("Add Maintenance", systemImage: "wrench.and.screwdriver")
                    }

                    Divider()

                    if vehicle.isDefault {
                        Button(role: .destructive) {
                            // Can't remove default status
                        } label: {
                            Label("Default Vehicle", systemImage: "star.fill")
                        }
                        .disabled(true)
                    } else {
                        Button {
                            Task {
                                await viewModel.setDefaultVehicle(vehicle)
                            }
                        } label: {
                            Label("Set as Default", systemImage: "star")
                        }
                    }

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Vehicle", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditVehicleSheet(vehicle: vehicle) {
                Task {
                    await viewModel.updateVehicle(vehicle)
                }
            }
        }
        .sheet(isPresented: $showingMaintenanceSheet) {
            AddMaintenanceSheet(vehicle: vehicle)
        }
        .sheet(isPresented: $showingOdometerUpdate) {
            OdometerUpdateSheet(vehicle: vehicle) {
                Task {
                    await viewModel.updateVehicle(vehicle)
                }
            }
        }
        .confirmationDialog(
            "Delete Vehicle",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteVehicle(vehicle)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete this vehicle.")
        }
        .task {
            await loadVehicleData()
        }
    }

    // MARK: - Vehicle Header

    private var vehicleHeader: some View {
        GlassCard {
            VStack(spacing: 16) {
                // Vehicle Icon
                ZStack {
                    Circle()
                        .fill(ColorConstants.Gradients.primary)
                        .frame(width: 80, height: 80)

                    Image(systemName: vehicleIcon)
                        .font(.largeTitle)
                        .foregroundStyle(ColorConstants.Text.inverse)
                }

                VStack(spacing: 4) {
                    Text(vehicle.displayName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Badges
                HStack(spacing: 8) {
                    if vehicle.isDefault {
                        Badge(text: "Default", color: ColorConstants.primary)
                    }

                    Badge(text: vehicle.fuelType.rawValue, color: fuelTypeColor)

                    if !vehicle.isActive {
                        Badge(text: "Archived", color: ColorConstants.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            VehicleStatCard(
                title: "Current Odometer",
                value: formatNumber(vehicle.currentOdometer),
                unit: "miles",
                icon: "gauge.with.needle",
                color: ColorConstants.primary
            )

            VehicleStatCard(
                title: "Total Trips",
                value: "\(tripStats?.totalTrips ?? 0)",
                unit: "trips",
                icon: "road.lanes",
                color: ColorConstants.success
            )

            VehicleStatCard(
                title: "Miles Tracked",
                value: formatNumber(Int(tripStats?.totalMiles ?? 0)),
                unit: "miles",
                icon: "map",
                color: ColorConstants.info
            )

            VehicleStatCard(
                title: "Avg Trip",
                value: String(format: "%.1f", tripStats?.averageTripDistance ?? 0),
                unit: "miles",
                icon: "chart.line.uptrend.xyaxis",
                color: ColorConstants.warning
            )
        }
    }

    // MARK: - Trip History Chart

    private var tripHistoryChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Trip History (Last 7 Days)")
                    .font(.headline)

                if let stats = tripStats, !stats.dailyMiles.isEmpty {
                    Chart {
                        ForEach(stats.dailyMiles, id: \.date) { day in
                            BarMark(
                                x: .value("Day", day.date, unit: .day),
                                y: .value("Miles", day.miles)
                            )
                            .foregroundStyle(ColorConstants.primary.gradient)
                            .cornerRadius(4)
                        }
                    }
                    .frame(height: 150)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                } else {
                    Text("No trip data available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
    }

    // MARK: - Maintenance Section

    private var maintenanceSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Maintenance")
                        .font(.headline)

                    Spacer()

                    Button {
                        showingMaintenanceSheet = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }

                if maintenanceRecords.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No maintenance records")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ForEach(maintenanceRecords.prefix(3)) { record in
                        MaintenanceRow(record: record)
                    }

                    if maintenanceRecords.count > 3 {
                        NavigationLink {
                            MaintenanceHistoryView(vehicle: vehicle)
                        } label: {
                            Text("View All (\(maintenanceRecords.count))")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Vehicle Details Card

    private var vehicleDetailsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Vehicle Details")
                    .font(.headline)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    DetailItem(label: "Make", value: vehicle.make)
                    DetailItem(label: "Model", value: vehicle.model)
                    DetailItem(label: "Year", value: "\(vehicle.year)")
                    DetailItem(label: "Fuel Type", value: vehicle.fuelType.rawValue)

                    if let plate = vehicle.licensePlate {
                        DetailItem(label: "License Plate", value: plate)
                    }

                    if let color = vehicle.color {
                        DetailItem(label: "Color", value: color)
                    }

                    if let vin = vehicle.vin {
                        DetailItem(label: "VIN", value: vin, isMonospace: true)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                // Start trip with this vehicle
            } label: {
                Label("Start Trip with This Vehicle", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassButtonStyleWrapper())

            HStack(spacing: 12) {
                Button {
                    showingEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyleWrapper(variant: .secondary))

                Button {
                    shareVehicle()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyleWrapper(variant: .secondary))
            }
        }
    }

    // MARK: - Helpers

    private var vehicleIcon: String {
        switch vehicle.fuelType {
        case .electric:
            return "bolt.car.fill"
        case .hybrid:
            return "leaf.fill"
        default:
            return "car.fill"
        }
    }

    private var fuelTypeColor: Color {
        switch vehicle.fuelType {
        case .electric: return ColorConstants.success
        case .hybrid: return ColorConstants.info
        case .gasoline: return ColorConstants.primary
        case .diesel: return ColorConstants.warning
        case .pluginHybrid: return ColorConstants.info
        }
    }

    private func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func loadVehicleData() async {
        // Load trip statistics
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -30, to: Date())!
        let targetVehicleId = vehicle.id

        // Fetch trips and filter by vehicle
        let tripDescriptor = FetchDescriptor<Trip>(
            predicate: #Predicate<Trip> { trip in
                trip.startTime >= startDate
            }
        )

        do {
            let allTrips = try modelContext.fetch(tripDescriptor)
            // Filter by vehicle in memory since predicates don't support computed vehicleId
            let trips = allTrips.filter { $0.vehicle?.id == targetVehicleId }

            // Calculate stats
            let totalMiles = trips.reduce(0) { $0 + $1.distanceMiles }
            let avgDistance = trips.isEmpty ? 0 : totalMiles / Double(trips.count)

            // Daily breakdown for last 7 days
            var dailyMiles: [(date: Date, miles: Double)] = []
            for dayOffset in 0..<7 {
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: calendar.startOfDay(for: Date()))!
                let nextDate = calendar.date(byAdding: .day, value: 1, to: date)!

                let dayTrips = trips.filter { trip in
                    trip.startTime >= date && trip.startTime < nextDate
                }

                let miles = dayTrips.reduce(0) { $0 + $1.distanceMiles }
                dailyMiles.append((date: date, miles: miles))
            }

            tripStats = VehicleTripStats(
                totalTrips: trips.count,
                totalMiles: totalMiles,
                averageTripDistance: avgDistance,
                dailyMiles: dailyMiles.reversed()
            )
        } catch {
            AppLogger.data.error("Failed to load trip stats: \(error.localizedDescription)")
        }

        // Load maintenance records - fetch all and filter by vehicle
        let maintenanceDescriptor = FetchDescriptor<MaintenanceRecord>(
            sortBy: [SortDescriptor(\MaintenanceRecord.performedAt, order: .reverse)]
        )

        do {
            let allRecords = try modelContext.fetch(maintenanceDescriptor)
            // Filter by vehicle in memory
            maintenanceRecords = allRecords.filter { $0.vehicle?.id == targetVehicleId }
        } catch {
            AppLogger.data.error("Failed to load maintenance: \(error.localizedDescription)")
        }
    }

    private func shareVehicle() {
        let text = """
        Vehicle: \(vehicle.displayName)
        \(vehicle.year) \(vehicle.make) \(vehicle.model)
        Odometer: \(formatNumber(vehicle.currentOdometer)) miles
        """

        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Vehicle Trip Stats

struct VehicleTripStats {
    let totalTrips: Int
    let totalMiles: Double
    let averageTripDistance: Double
    let dailyMiles: [(date: Date, miles: Double)]
}

// MARK: - Supporting Views

struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

private struct VehicleStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DetailItem: View {
    let label: String
    let value: String
    var isMonospace: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .fontDesign(isMonospace ? .monospaced : .default)
        }
    }
}

struct MaintenanceRow: View {
    let record: MaintenanceRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.maintenanceType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let cost = record.cost {
                Text(cost, format: .currency(code: "USD"))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Edit Vehicle Sheet

struct EditVehicleSheet: View {
    @Environment(\.dismiss) private var dismiss

    let vehicle: Vehicle
    let onSave: () -> Void

    @State private var make: String
    @State private var model: String
    @State private var year: Int
    @State private var nickname: String
    @State private var licensePlate: String
    @State private var color: String
    @State private var fuelType: FuelType

    private let years = Array((1990...Calendar.current.component(.year, from: Date()) + 1).reversed())

    init(vehicle: Vehicle, onSave: @escaping () -> Void) {
        self.vehicle = vehicle
        self.onSave = onSave
        _make = State(initialValue: vehicle.make)
        _model = State(initialValue: vehicle.model)
        _year = State(initialValue: vehicle.year)
        _nickname = State(initialValue: vehicle.nickname ?? "")
        _licensePlate = State(initialValue: vehicle.licensePlate ?? "")
        _color = State(initialValue: vehicle.color ?? "")
        _fuelType = State(initialValue: vehicle.fuelType)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle Information") {
                    TextField("Make", text: $make)
                    TextField("Model", text: $model)

                    Picker("Year", selection: $year) {
                        ForEach(years, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }

                    TextField("Nickname", text: $nickname)
                }

                Section("Details") {
                    TextField("License Plate", text: $licensePlate)
                        .textInputAutocapitalization(.characters)

                    TextField("Color", text: $color)

                    Picker("Fuel Type", selection: $fuelType) {
                        ForEach(FuelType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(make.isEmpty || model.isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        vehicle.make = make.trimmingCharacters(in: .whitespaces)
        vehicle.model = model.trimmingCharacters(in: .whitespaces)
        vehicle.year = year
        vehicle.nickname = nickname.isEmpty ? "\(year) \(make) \(model)" : nickname
        vehicle.licensePlate = licensePlate.isEmpty ? nil : licensePlate.uppercased()
        vehicle.color = color.isEmpty ? nil : color
        vehicle.fuelType = fuelType

        onSave()
        dismiss()
    }
}

// MARK: - Odometer Update Sheet

struct OdometerUpdateSheet: View {
    @Environment(\.dismiss) private var dismiss

    let vehicle: Vehicle
    let onSave: () -> Void

    @State private var newOdometer: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Current Reading")
                        Spacer()
                        Text("\(vehicle.currentOdometer) miles")
                            .foregroundStyle(.secondary)
                    }

                    TextField("New Odometer Reading", text: $newOdometer)
                        .keyboardType(.numberPad)
                } footer: {
                    Text("Enter the current odometer reading from your vehicle")
                }
            }
            .navigationTitle("Update Odometer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let value = Int(newOdometer), value >= vehicle.currentOdometer {
                            vehicle.currentOdometer = value
                            onSave()
                        }
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        guard let value = Int(newOdometer) else { return false }
        return value >= vehicle.currentOdometer
    }
}

// MARK: - Add Maintenance Sheet

struct AddMaintenanceSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let vehicle: Vehicle

    @State private var type: MaintenanceType = .oilChange
    @State private var date = Date()
    @State private var odometer = ""
    @State private var cost = ""
    @State private var notes = ""
    @State private var provider = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Maintenance Type") {
                    Picker("Type", selection: $type) {
                        ForEach(MaintenanceType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }

                Section("Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    TextField("Odometer", text: $odometer)
                        .keyboardType(.numberPad)

                    TextField("Cost", text: $cost)
                        .keyboardType(.decimalPad)

                    TextField("Service Provider", text: $provider)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Add Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecord()
                    }
                }
            }
        }
    }

    private func saveRecord() {
        let record = MaintenanceRecord(
            maintenanceType: type,
            performedAt: date,
            odometerAtService: Int(odometer) ?? 0,
            cost: cost.isEmpty ? nil : Decimal(string: cost)
        )
        record.vehicle = vehicle
        record.notes = notes.isEmpty ? nil : notes
        record.serviceProvider = provider.isEmpty ? nil : provider

        modelContext.insert(record)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            AppLogger.data.error("Failed to save maintenance: \(error.localizedDescription)")
        }
    }
}

// MARK: - Maintenance History View

struct MaintenanceHistoryView: View {
    @Environment(\.modelContext) private var modelContext

    let vehicle: Vehicle

    @State private var records: [MaintenanceRecord] = []

    var body: some View {
        List {
            ForEach(records) { record in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(record.maintenanceType.displayName)
                            .font(.headline)

                        Spacer()

                        if let cost = record.cost {
                            Text(cost, format: .currency(code: "USD"))
                                .fontWeight(.medium)
                        }
                    }

                    HStack {
                        Text(record.date.formatted(date: .abbreviated, time: .omitted))

                        Text("•")
                        Text("\(record.odometerAtService) mi")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if let notes = record.notes {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Maintenance History")
        .task {
            let targetVehicleId = vehicle.id
            let descriptor = FetchDescriptor<MaintenanceRecord>(
                sortBy: [SortDescriptor(\MaintenanceRecord.performedAt, order: .reverse)]
            )
            let allRecords = (try? modelContext.fetch(descriptor)) ?? []
            records = allRecords.filter { $0.vehicle?.id == targetVehicleId }
        }
    }
}

#Preview {
    NavigationStack {
        Text("Vehicle Detail Preview")
    }
}
