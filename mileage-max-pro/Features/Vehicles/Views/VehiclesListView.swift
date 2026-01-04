//
//  VehiclesListView.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI
import SwiftData

/// List view for managing vehicles
struct VehiclesListView: View {

    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: VehiclesViewModel

    @State private var showingAddVehicle = false
    @State private var vehicleToDelete: Vehicle?
    @State private var showingDeleteConfirmation = false

    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: VehiclesViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.loadState {
                case .idle, .loading:
                    loadingView

                case .loaded, .refreshing:
                    if viewModel.vehicles.isEmpty {
                        emptyStateView
                    } else {
                        vehiclesList
                    }

                case .error(let error):
                    errorView(error)
                }
            }
            .navigationTitle("Vehicles")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddVehicle = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search vehicles")
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showingAddVehicle) {
                AddVehicleView { vehicle in
                    Task {
                        await viewModel.addVehicle(vehicle)
                    }
                }
            }
            .confirmationDialog(
                "Delete Vehicle",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let vehicle = vehicleToDelete {
                        Task {
                            await viewModel.deleteVehicle(vehicle)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete this vehicle and all associated trip data.")
            }
            .task {
                await viewModel.loadVehicles()
            }
        }
    }

    // MARK: - Vehicles List

    private var vehiclesList: some View {
        List {
            // Active Vehicles Section
            if !viewModel.activeVehicles.isEmpty {
                Section {
                    ForEach(viewModel.filteredVehicles.filter { $0.isActive }) { vehicle in
                        NavigationLink(value: vehicle) {
                            VehicleRowView(vehicle: vehicle)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                vehicleToDelete = vehicle
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                Task {
                                    await viewModel.archiveVehicle(vehicle)
                                }
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            .tint(ColorConstants.warning)
                        }
                        .swipeActions(edge: .leading) {
                            if !vehicle.isDefault {
                                Button {
                                    Task {
                                        await viewModel.setDefaultVehicle(vehicle)
                                    }
                                } label: {
                                    Label("Set Default", systemImage: "star.fill")
                                }
                                .tint(ColorConstants.warning)
                            }
                        }
                    }
                } header: {
                    Text("Active Vehicles")
                }
            }

            // Archived Vehicles Section
            let archivedVehicles = viewModel.filteredVehicles.filter { !$0.isActive }
            if !archivedVehicles.isEmpty {
                Section {
                    ForEach(archivedVehicles) { vehicle in
                        NavigationLink(value: vehicle) {
                            VehicleRowView(vehicle: vehicle)
                                .opacity(0.6)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                vehicleToDelete = vehicle
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                Task {
                                    vehicle.isActive = true
                                    await viewModel.updateVehicle(vehicle)
                                }
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .tint(ColorConstants.success)
                        }
                    }
                } header: {
                    Text("Archived")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationDestination(for: Vehicle.self) { vehicle in
            VehicleDetailView(vehicle: vehicle, viewModel: viewModel)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading vehicles...")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Vehicles", systemImage: "car.2")
        } description: {
            Text("Add your first vehicle to start tracking mileage")
        } actions: {
            Button {
                showingAddVehicle = true
            } label: {
                Text("Add Vehicle")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Error View

    private func errorView(_ error: AppError) -> some View {
        ContentUnavailableView {
            Label("Error Loading Vehicles", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Retry") {
                Task {
                    await viewModel.loadVehicles()
                }
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Vehicle Row View

struct VehicleRowView: View {
    let vehicle: Vehicle

    var body: some View {
        HStack(spacing: 16) {
            // Vehicle Icon
            ZStack {
                Circle()
                    .fill(vehicleColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: vehicleIcon)
                    .font(.title2)
                    .foregroundStyle(vehicleColor)
            }

            // Vehicle Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(vehicle.displayName)
                        .font(.headline)

                    if vehicle.isDefault {
                        Text("DEFAULT")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ColorConstants.primary.opacity(0.15))
                            .foregroundStyle(ColorConstants.primary)
                            .clipShape(Capsule())
                    }
                }

                Text("\(vehicle.year) • \(formatOdometer(vehicle.currentOdometer)) miles")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Sync Status
            Image(systemName: syncIcon)
                .font(.caption)
                .foregroundStyle(syncColor)
        }
        .padding(.vertical, 4)
    }

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

    private var vehicleColor: Color {
        if let colorString = vehicle.color?.lowercased() {
            switch colorString {
            case "red": return ColorConstants.error
            case "blue": return ColorConstants.primary
            case "green": return ColorConstants.success
            case "black": return ColorConstants.Text.primary
            case "white": return ColorConstants.secondary
            case "silver", "gray", "grey": return ColorConstants.secondary
            case "yellow": return ColorConstants.warning
            case "orange": return ColorConstants.warning
            default: return ColorConstants.primary
            }
        }
        return ColorConstants.primary
    }

    private var syncIcon: String {
        switch vehicle.syncStatus {
        case .synced: return "checkmark.icloud"
        case .pending: return "icloud.and.arrow.up"
        case .failed: return "exclamationmark.icloud"
        }
    }

    private var syncColor: Color {
        switch vehicle.syncStatus {
        case .synced: return ColorConstants.success
        case .pending: return ColorConstants.warning
        case .failed: return ColorConstants.error
        }
    }

    private func formatOdometer(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

// MARK: - Add Vehicle View

struct AddVehicleView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (Vehicle) -> Void

    @State private var make = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var nickname = ""
    @State private var licensePlate = ""
    @State private var color = ""
    @State private var vin = ""
    @State private var fuelType: FuelType = .gasoline
    @State private var currentOdometer = ""
    @State private var isDefault = false

    @State private var showingVINScanner = false

    private let years = Array((1990...Calendar.current.component(.year, from: Date()) + 1).reversed())

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section("Vehicle Information") {
                    TextField("Make (e.g., Toyota)", text: $make)
                        .textContentType(.organizationName)

                    TextField("Model (e.g., Camry)", text: $model)

                    Picker("Year", selection: $year) {
                        ForEach(years, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }

                    TextField("Nickname (optional)", text: $nickname)
                }

                // Details
                Section("Additional Details") {
                    TextField("License Plate", text: $licensePlate)
                        .textInputAutocapitalization(.characters)

                    TextField("Color", text: $color)

                    HStack {
                        TextField("VIN", text: $vin)
                            .textInputAutocapitalization(.characters)

                        Button {
                            showingVINScanner = true
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                        }
                    }
                }

                // Fuel Type
                Section("Fuel Type") {
                    Picker("Fuel Type", selection: $fuelType) {
                        ForEach(FuelType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Odometer
                Section {
                    TextField("Current Odometer", text: $currentOdometer)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Odometer")
                } footer: {
                    Text("Enter the current odometer reading in miles")
                }

                // Default Setting
                Section {
                    Toggle("Set as Default Vehicle", isOn: $isDefault)
                } footer: {
                    Text("The default vehicle will be automatically selected when starting a new trip")
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveVehicle()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingVINScanner) {
                VINScannerView { scannedVIN in
                    vin = scannedVIN
                }
            }
        }
    }

    private var isValid: Bool {
        !make.trimmingCharacters(in: .whitespaces).isEmpty &&
        !model.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func saveVehicle() {
        let vehicleNickname = nickname.isEmpty ? "\(year) \(make) \(model)" : nickname.trimmingCharacters(in: .whitespaces)
        let vehicle = Vehicle(
            nickname: vehicleNickname,
            make: make.trimmingCharacters(in: .whitespaces),
            model: model.trimmingCharacters(in: .whitespaces),
            year: year,
            fuelType: fuelType
        )
        vehicle.licensePlate = licensePlate.isEmpty ? nil : licensePlate.uppercased()
        vehicle.color = color.isEmpty ? nil : color.trimmingCharacters(in: .whitespaces)
        vehicle.vin = vin.isEmpty ? nil : vin.uppercased()
        vehicle.odometerReading = Int(currentOdometer) ?? 0
        vehicle.isPrimary = isDefault
        vehicle.isActive = true

        onSave(vehicle)
        dismiss()
    }
}

// MARK: - VIN Scanner View

struct VINScannerView: View {
    @Environment(\.dismiss) private var dismiss

    let onScan: (String) -> Void

    @State private var manualVIN = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Camera placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray5))
                    .frame(height: 200)
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.viewfinder")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("Point camera at VIN barcode")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                Text("— or —")
                    .foregroundStyle(.secondary)

                // Manual entry
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter VIN manually")
                        .font(.headline)

                    TextField("17-character VIN", text: $manualVIN)
                        .textInputAutocapitalization(.characters)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: manualVIN) { _, newValue in
                            manualVIN = String(newValue.prefix(17)).uppercased()
                        }

                    if !manualVIN.isEmpty && manualVIN.count != 17 {
                        Text("VIN must be 17 characters")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal)

                Spacer()

                Button {
                    onScan(manualVIN)
                    dismiss()
                } label: {
                    Text("Use This VIN")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(manualVIN.count != 17)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle("Scan VIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Vehicle.self, configurations: config)

    return VehiclesListView(modelContext: container.mainContext)
        .modelContainer(container)
}
