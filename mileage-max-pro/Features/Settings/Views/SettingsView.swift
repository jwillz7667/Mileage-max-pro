//
//  SettingsView.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI
import SwiftData
import LocalAuthentication
import os

/// Main settings view with all configuration options
struct SettingsView: View {

    @Environment(\.modelContext) private var modelContext

    @AppStorage("autoStartTrips") private var autoStartTrips = false
    @AppStorage("autoEndTrips") private var autoEndTrips = false
    @AppStorage("defaultCategory") private var defaultCategory = "Business"
    @AppStorage("distanceUnit") private var distanceUnit = "miles"
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("requireBiometric") private var requireBiometric = false
    @AppStorage("syncOverCellular") private var syncOverCellular = true
    @AppStorage("locationAccuracy") private var locationAccuracy = "high"
    @AppStorage("autoClassify") private var autoClassify = true

    @State private var showingExportOptions = false
    @State private var showingDeleteConfirmation = false
    @State private var showingLogout = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTerms = false
    @State private var showingSupport = false

    var body: some View {
        NavigationStack {
            List {
                // Account Section
                accountSection

                // Trip Settings
                tripSettingsSection

                // Tracking Settings
                trackingSettingsSection

                // Notifications
                notificationsSection

                // Appearance
                appearanceSection

                // Security
                securitySection

                // Data & Privacy
                dataPrivacySection

                // Support
                supportSection

                // About
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsSheet()
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                SafariView(url: URL(string: "https://mileagemaxpro.com/privacy")!)
            }
            .sheet(isPresented: $showingTerms) {
                SafariView(url: URL(string: "https://mileagemaxpro.com/terms")!)
            }
            .sheet(isPresented: $showingSupport) {
                SupportView()
            }
            .confirmationDialog(
                "Delete All Data",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all trips, vehicles, expenses, and settings. This cannot be undone.")
            }
            .confirmationDialog(
                "Sign Out",
                isPresented: $showingLogout,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your data will remain on your device but won't sync until you sign back in.")
            }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section {
            NavigationLink {
                AccountSettingsView()
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 50, height: 50)

                        Text("JD")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("John Doe")
                            .font(.headline)
                        Text("john@example.com")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            NavigationLink {
                SubscriptionView()
            } label: {
                HStack {
                    Label("Subscription", systemImage: "crown.fill")
                        .foregroundStyle(.orange)
                    Spacer()
                    Text("Pro")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Trip Settings Section

    private var tripSettingsSection: some View {
        Section {
            Toggle("Auto-Start Trips", isOn: $autoStartTrips)

            Toggle("Auto-End Trips", isOn: $autoEndTrips)

            Picker("Default Category", selection: $defaultCategory) {
                ForEach(TripCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category.rawValue)
                }
            }

            Toggle("Auto-Classify Trips", isOn: $autoClassify)

            NavigationLink {
                DefaultAddressesView()
            } label: {
                Text("Default Addresses")
            }
        } header: {
            Text("Trip Settings")
        } footer: {
            Text("Auto-start will begin tracking when you start driving. Auto-classify uses AI to categorize trips.")
        }
    }

    // MARK: - Tracking Settings Section

    private var trackingSettingsSection: some View {
        Section {
            Picker("Location Accuracy", selection: $locationAccuracy) {
                Text("High").tag("high")
                Text("Balanced").tag("balanced")
                Text("Low Power").tag("low")
            }

            Picker("Distance Unit", selection: $distanceUnit) {
                Text("Miles").tag("miles")
                Text("Kilometers").tag("kilometers")
            }

            NavigationLink {
                TrackingSettingsView()
            } label: {
                Text("Advanced Tracking")
            }
        } header: {
            Text("Tracking")
        } footer: {
            Text("High accuracy uses more battery but provides better tracking precision.")
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section {
            Toggle("Enable Notifications", isOn: $enableNotifications)

            if enableNotifications {
                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    Text("Notification Preferences")
                }
            }
        } header: {
            Text("Notifications")
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section {
            Toggle("Dark Mode", isOn: $darkMode)

            Toggle("Haptic Feedback", isOn: $hapticFeedback)

            NavigationLink {
                AppIconView()
            } label: {
                HStack {
                    Text("App Icon")
                    Spacer()
                    Image(systemName: "app.fill")
                        .foregroundStyle(.blue)
                }
            }
        } header: {
            Text("Appearance")
        }
    }

    // MARK: - Security Section

    private var securitySection: some View {
        Section {
            Toggle("Require Face ID / Touch ID", isOn: $requireBiometric)
                .onChange(of: requireBiometric) { _, newValue in
                    if newValue {
                        authenticateBiometric()
                    }
                }

            NavigationLink {
                SecuritySettingsView()
            } label: {
                Text("Security Settings")
            }
        } header: {
            Text("Security")
        }
    }

    // MARK: - Data & Privacy Section

    private var dataPrivacySection: some View {
        Section {
            Toggle("Sync Over Cellular", isOn: $syncOverCellular)

            NavigationLink {
                DataManagementView()
            } label: {
                Text("Data Management")
            }

            Button {
                showingExportOptions = true
            } label: {
                HStack {
                    Text("Export Data")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.secondary)
                }
            }

            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Text("Delete All Data")
            }
        } header: {
            Text("Data & Privacy")
        }
    }

    // MARK: - Support Section

    private var supportSection: some View {
        Section {
            Button {
                showingSupport = true
            } label: {
                HStack {
                    Label("Help & Support", systemImage: "questionmark.circle")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                // Rate app
                if let url = URL(string: "https://apps.apple.com/app/id123456789?action=write-review") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Rate MileageMax Pro", systemImage: "star")
                    .foregroundStyle(.primary)
            }

            Button {
                shareApp()
            } label: {
                Label("Share App", systemImage: "square.and.arrow.up")
                    .foregroundStyle(.primary)
            }
        } header: {
            Text("Support")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0 (100)")
                    .foregroundStyle(.secondary)
            }

            Button {
                showingPrivacyPolicy = true
            } label: {
                HStack {
                    Text("Privacy Policy")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                showingTerms = true
            } label: {
                HStack {
                    Text("Terms of Service")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button(role: .destructive) {
                showingLogout = true
            } label: {
                Text("Sign Out")
            }
        } header: {
            Text("About")
        } footer: {
            Text("Made with love in San Francisco")
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
        }
    }

    // MARK: - Actions

    private func authenticateBiometric() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to enable biometric lock") { success, _ in
                DispatchQueue.main.async {
                    if !success {
                        requireBiometric = false
                    }
                }
            }
        } else {
            requireBiometric = false
        }
    }

    private func deleteAllData() {
        // Delete all entities
        do {
            try modelContext.delete(model: Trip.self)
            try modelContext.delete(model: Vehicle.self)
            try modelContext.delete(model: Expense.self)
            try modelContext.delete(model: DeliveryRoute.self)
            try modelContext.delete(model: RouteStop.self)
            try modelContext.delete(model: MaintenanceRecord.self)
            try modelContext.save()
        } catch {
            AppLogger.data.error("Failed to delete data: \(error.localizedDescription)")
        }
    }

    private func signOut() {
        Task {
            await AuthenticationService.shared.signOut()
        }
    }

    private func shareApp() {
        let url = URL(string: "https://apps.apple.com/app/id123456789")!
        let activityVC = UIActivityViewController(
            activityItems: ["Check out MileageMax Pro for easy mileage tracking!", url],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Account Settings View

struct AccountSettingsView: View {
    @State private var name = "John Doe"
    @State private var email = "john@example.com"
    @State private var phone = ""
    @State private var company = ""

    var body: some View {
        Form {
            Section("Personal Information") {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                TextField("Phone", text: $phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }

            Section("Business Information") {
                TextField("Company Name", text: $company)
            }

            Section {
                NavigationLink {
                    ChangePasswordView()
                } label: {
                    Text("Change Password")
                }

                NavigationLink {
                    LinkedAccountsView()
                } label: {
                    Text("Linked Accounts")
                }
            }
        }
        .navigationTitle("Account")
    }
}

// MARK: - Subscription View

struct SubscriptionView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Plan
                GlassCard {
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)

                        Text("Pro Plan")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("$9.99/month")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("Renews on Jan 15, 2026")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }

                // Features
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pro Features")
                            .font(.headline)

                        FeatureRow(icon: "infinity", text: "Unlimited trips")
                        FeatureRow(icon: "car.2", text: "Multiple vehicles")
                        FeatureRow(icon: "doc.text", text: "Detailed reports")
                        FeatureRow(icon: "cloud", text: "Cloud backup")
                        FeatureRow(icon: "person.2", text: "Team sharing")
                        FeatureRow(icon: "headphones", text: "Priority support")
                    }
                    .padding()
                }

                // Manage
                Button {
                    // Open subscription management
                } label: {
                    Text("Manage Subscription")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Subscription")
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(text)
            Spacer()
            Image(systemName: "checkmark")
                .foregroundStyle(.green)
        }
    }
}

// MARK: - Export Options Sheet

struct ExportOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var exportFormat: FileFormat = .csv
    @State private var includeTrips = true
    @State private var includeExpenses = true
    @State private var includeVehicles = true
    @State private var dateRange: DateRangeOption = .allTime

    enum FileFormat: String, CaseIterable {
        case csv = "CSV"
        case pdf = "PDF"
        case json = "JSON"
    }

    enum DateRangeOption: String, CaseIterable {
        case allTime = "All Time"
        case thisYear = "This Year"
        case lastYear = "Last Year"
        case custom = "Custom"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Format") {
                    Picker("Export Format", selection: $exportFormat) {
                        ForEach(FileFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Include") {
                    Toggle("Trips", isOn: $includeTrips)
                    Toggle("Expenses", isOn: $includeExpenses)
                    Toggle("Vehicles", isOn: $includeVehicles)
                }

                Section("Date Range") {
                    Picker("Range", selection: $dateRange) {
                        ForEach(DateRangeOption.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") {
                        // Perform export
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Support View

struct SupportView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Link(destination: URL(string: "https://mileagemaxpro.com/faq")!) {
                        Label("FAQ", systemImage: "questionmark.circle")
                    }

                    Link(destination: URL(string: "https://mileagemaxpro.com/docs")!) {
                        Label("Documentation", systemImage: "book")
                    }
                }

                Section {
                    Link(destination: URL(string: "mailto:support@mileagemaxpro.com")!) {
                        Label("Email Support", systemImage: "envelope")
                    }

                    Button {
                        // Open chat
                    } label: {
                        Label("Live Chat", systemImage: "message")
                    }
                }

                Section {
                    NavigationLink {
                        DiagnosticsView()
                    } label: {
                        Label("Diagnostics", systemImage: "wrench.and.screwdriver")
                    }

                    Button {
                        // Send diagnostics
                    } label: {
                        Label("Send Feedback", systemImage: "paperplane")
                    }
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Placeholder Views

struct DefaultAddressesView: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    Text("Edit Home Address")
                } label: {
                    HStack {
                        Label("Home", systemImage: "house")
                        Spacer()
                        Text("Not Set")
                            .foregroundStyle(.secondary)
                    }
                }

                NavigationLink {
                    Text("Edit Work Address")
                } label: {
                    HStack {
                        Label("Work", systemImage: "building.2")
                        Spacer()
                        Text("Not Set")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Button {
                    // Add saved location
                } label: {
                    Label("Add Saved Location", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Default Addresses")
    }
}

struct TrackingSettingsView: View {
    @AppStorage("minTripDistance") private var minTripDistance = 0.1
    @AppStorage("pauseDetection") private var pauseDetection = true
    @AppStorage("speedThreshold") private var speedThreshold = 5.0

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Min Trip Distance")
                    Spacer()
                    Text(String(format: "%.1f mi", minTripDistance))
                }

                Slider(value: $minTripDistance, in: 0.1...1.0, step: 0.1)
            } footer: {
                Text("Trips shorter than this will be ignored")
            }

            Section {
                Toggle("Pause Detection", isOn: $pauseDetection)

                HStack {
                    Text("Speed Threshold")
                    Spacer()
                    Text(String(format: "%.0f mph", speedThreshold))
                }

                Slider(value: $speedThreshold, in: 3...15, step: 1)
            } footer: {
                Text("Movement below this speed will pause tracking")
            }
        }
        .navigationTitle("Advanced Tracking")
    }
}

struct NotificationSettingsView: View {
    @AppStorage("tripReminders") private var tripReminders = true
    @AppStorage("weeklyReports") private var weeklyReports = true
    @AppStorage("taxDeadlines") private var taxDeadlines = true
    @AppStorage("maintenanceAlerts") private var maintenanceAlerts = true

    var body: some View {
        Form {
            Section {
                Toggle("Trip Reminders", isOn: $tripReminders)
                Toggle("Weekly Reports", isOn: $weeklyReports)
                Toggle("Tax Deadlines", isOn: $taxDeadlines)
                Toggle("Maintenance Alerts", isOn: $maintenanceAlerts)
            }
        }
        .navigationTitle("Notifications")
    }
}

struct AppIconView: View {
    var body: some View {
        List {
            ForEach(["Default", "Dark", "Light", "Classic"], id: \.self) { icon in
                HStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                        .frame(width: 60, height: 60)

                    Text(icon)

                    Spacer()

                    if icon == "Default" {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .navigationTitle("App Icon")
    }
}

struct SecuritySettingsView: View {
    var body: some View {
        Form {
            Section {
                NavigationLink("Two-Factor Authentication") {
                    Text("2FA Settings")
                }

                NavigationLink("Login History") {
                    Text("Login History")
                }

                NavigationLink("Active Sessions") {
                    Text("Sessions")
                }
            }
        }
        .navigationTitle("Security")
    }
}

struct DataManagementView: View {
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Local Storage")
                    Spacer()
                    Text("124 MB")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Cloud Storage")
                    Spacer()
                    Text("89 MB")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Clear Cache") {
                    // Clear cache
                }

                Button("Sync Now") {
                    // Force sync
                }
            }
        }
        .navigationTitle("Data Management")
    }
}

struct ChangePasswordView: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    var body: some View {
        Form {
            Section {
                SecureField("Current Password", text: $currentPassword)
                SecureField("New Password", text: $newPassword)
                SecureField("Confirm Password", text: $confirmPassword)
            }

            Section {
                Button("Update Password") {
                    // Update password
                }
                .disabled(newPassword.isEmpty || newPassword != confirmPassword)
            }
        }
        .navigationTitle("Change Password")
    }
}

struct LinkedAccountsView: View {
    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "apple.logo")
                    Text("Apple")
                    Spacer()
                    Text("Connected")
                        .foregroundStyle(.green)
                }

                HStack {
                    Image(systemName: "g.circle.fill")
                    Text("Google")
                    Spacer()
                    Button("Connect") {}
                }
            }
        }
        .navigationTitle("Linked Accounts")
    }
}

struct DiagnosticsView: View {
    var body: some View {
        Form {
            Section("Device Info") {
                HStack {
                    Text("Model")
                    Spacer()
                    Text(UIDevice.current.model)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("iOS Version")
                    Spacer()
                    Text(UIDevice.current.systemVersion)
                        .foregroundStyle(.secondary)
                }
            }

            Section("App Info") {
                HStack {
                    Text("Build")
                    Spacer()
                    Text("100")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Last Sync")
                    Spacer()
                    Text("2 min ago")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("View Logs") {}
                Button("Clear Logs") {}
            }
        }
        .navigationTitle("Diagnostics")
    }
}

// MARK: - Safari View

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

#Preview {
    SettingsView()
}
