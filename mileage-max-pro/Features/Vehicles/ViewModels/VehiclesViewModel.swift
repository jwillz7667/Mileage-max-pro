//
//  VehiclesViewModel.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import SwiftUI
import SwiftData
import Combine
import os

/// ViewModel for the Vehicles feature
@MainActor
final class VehiclesViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var vehicles: [Vehicle] = []
    @Published var loadState: LoadableState<[Vehicle]> = .idle
    @Published var searchText = ""

    @Published var showingAddVehicle = false
    @Published var showingVehicleDetail: Vehicle?
    @Published var selectedVehicle: Vehicle?

    // MARK: - Properties

    private let modelContext: ModelContext
    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var filteredVehicles: [Vehicle] {
        if searchText.isEmpty {
            return vehicles
        }

        let query = searchText.lowercased()
        return vehicles.filter { vehicle in
            vehicle.make.lowercased().contains(query) ||
            vehicle.model.lowercased().contains(query) ||
            vehicle.nickname.lowercased().contains(query)
        }
    }

    var activeVehicles: [Vehicle] {
        vehicles.filter { $0.isActive }
    }

    var defaultVehicle: Vehicle? {
        vehicles.first { $0.isDefault }
    }

    var totalMileage: Int {
        vehicles.reduce(0) { $0 + $1.currentOdometer }
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupBindings()
    }

    private func setupBindings() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    func loadVehicles() async {
        loadState = .loading

        let descriptor = FetchDescriptor<Vehicle>()

        do {
            let fetchedVehicles = try modelContext.fetch(descriptor)
            // Sort: primary first, then by make
            vehicles = fetchedVehicles.sorted {
                if $0.isPrimary != $1.isPrimary {
                    return $0.isPrimary && !$1.isPrimary
                }
                return $0.make < $1.make
            }
            loadState = .loaded(vehicles)

            // Sync from server if online
            if NetworkMonitor.shared.isConnected {
                await syncVehicles()
            }
        } catch {
            loadState = .error(AppError.from(error))
            AppLogger.data.error("Failed to fetch vehicles: \(error.localizedDescription)")
        }
    }

    func refresh() async {
        guard case .loaded = loadState else {
            await loadVehicles()
            return
        }

        loadState = .refreshing(vehicles)
        await loadVehicles()
    }

    private func syncVehicles() async {
        let endpoint = VehicleEndpoints.list

        do {
            let response: [VehicleResponse] = try await apiClient.request(endpoint)

            for vehicleResponse in response {
                await mergeVehicle(vehicleResponse)
            }

            try modelContext.save()
        } catch {
            AppLogger.sync.error("Failed to sync vehicles: \(error.localizedDescription)")
        }
    }

    private func mergeVehicle(_ response: VehicleResponse) async {
        guard let vehicleId = UUID(uuidString: response.id) else {
            AppLogger.data.error("Invalid vehicle ID: \(response.id)")
            return
        }

        let descriptor = FetchDescriptor<Vehicle>(
            predicate: #Predicate<Vehicle> { $0.id == vehicleId }
        )

        do {
            let existing = try modelContext.fetch(descriptor)

            if let localVehicle = existing.first {
                // Update existing vehicle
                localVehicle.updatedAt = Date()
            } else {
                // Create new vehicle from response
                let vehicle = Vehicle(
                    id: vehicleId,
                    nickname: response.name,
                    make: response.make,
                    model: response.model,
                    year: response.year,
                    fuelType: FuelType(rawValue: response.fuelType) ?? .gasoline
                )
                vehicle.licensePlate = response.licensePlate
                vehicle.color = response.color
                vehicle.vin = response.vin
                vehicle.odometerReading = Int(response.odometerReading)
                vehicle.isActive = response.isActive
                vehicle.updatedAt = Date()

                modelContext.insert(vehicle)
            }
        } catch {
            AppLogger.data.error("Failed to merge vehicle: \(error.localizedDescription)")
        }
    }

    // MARK: - Actions

    func addVehicle(_ vehicle: Vehicle) async {
        modelContext.insert(vehicle)

        // If this is the first vehicle, make it default
        if vehicles.isEmpty {
            vehicle.isDefault = true
        }

        do {
            try modelContext.save()
            vehicles.append(vehicle)

            // Sync to server
            if NetworkMonitor.shared.isConnected {
                await syncNewVehicle(vehicle)
            }
        } catch {
            AppLogger.data.error("Failed to add vehicle: \(error.localizedDescription)")
        }
    }

    private func syncNewVehicle(_ vehicle: Vehicle) async {
        let request = CreateVehicleRequest(
            name: vehicle.nickname,
            make: vehicle.make,
            model: vehicle.model,
            year: vehicle.year,
            licensePlate: vehicle.licensePlate,
            vin: vehicle.vin,
            color: vehicle.color,
            fuelType: vehicle.fuelType.rawValue,
            odometerReading: Double(vehicle.odometerReading),
            isDefault: vehicle.isPrimary
        )

        do {
            let _: VehicleResponse = try await apiClient.request(VehicleEndpoints.create(vehicle: request))
            vehicle.updatedAt = Date()
            try? modelContext.save()
        } catch {
            AppLogger.sync.error("Failed to sync new vehicle: \(error.localizedDescription)")
        }
    }

    func updateVehicle(_ vehicle: Vehicle) async {
        vehicle.updatedAt = Date()

        do {
            try modelContext.save()

            if NetworkMonitor.shared.isConnected {
                await syncUpdatedVehicle(vehicle)
            }
        } catch {
            AppLogger.data.error("Failed to update vehicle: \(error.localizedDescription)")
        }
    }

    private func syncUpdatedVehicle(_ vehicle: Vehicle) async {
        let request = UpdateVehicleRequest(
            name: vehicle.nickname,
            licensePlate: vehicle.licensePlate,
            color: vehicle.color,
            odometerReading: Double(vehicle.odometerReading),
            insuranceProvider: vehicle.insuranceProvider,
            insurancePolicyNumber: vehicle.insurancePolicyNumber,
            insuranceExpiryDate: vehicle.insuranceExpiresAt,
            registrationExpiryDate: vehicle.registrationExpiresAt,
            isActive: vehicle.isActive
        )

        do {
            try await apiClient.requestVoid(VehicleEndpoints.update(id: vehicle.id.uuidString, vehicle: request))
            vehicle.updatedAt = Date()
            try? modelContext.save()
        } catch {
            AppLogger.sync.error("Failed to sync vehicle update: \(error.localizedDescription)")
        }
    }

    func deleteVehicle(_ vehicle: Vehicle) async {
        modelContext.delete(vehicle)

        do {
            try modelContext.save()
            vehicles.removeAll { $0.id == vehicle.id }

            if NetworkMonitor.shared.isConnected {
                try await apiClient.requestVoid(VehicleEndpoints.delete(id: vehicle.id.uuidString))
            }
        } catch {
            AppLogger.data.error("Failed to delete vehicle: \(error.localizedDescription)")
        }
    }

    func setDefaultVehicle(_ vehicle: Vehicle) async {
        // Clear existing default
        for v in vehicles {
            v.isDefault = false
        }

        vehicle.isDefault = true

        await updateVehicle(vehicle)
    }

    func archiveVehicle(_ vehicle: Vehicle) async {
        vehicle.isActive = false
        await updateVehicle(vehicle)
    }
}
