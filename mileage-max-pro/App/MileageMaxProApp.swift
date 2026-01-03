//
//  MileageMaxProApp.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI
import SwiftData
import os

@main
struct MileageMaxProApp: App {

    // MARK: - Services

    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var locationService = LocationTrackingService.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared

    // MARK: - App Delegate

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - SwiftData

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Vehicle.self,
            VehicleMaintenanceRecord.self,
            Trip.self,
            TripWaypoint.self,
            Expense.self,
            FuelPurchase.self,
            SavedLocation.self,
            Earning.self,
            DeliveryRoute.self,
            DeliveryStop.self,
            MileageReport.self,
            UserSettings.self
        ])

        // Disable CloudKit for now - requires proper entitlements setup
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Log the actual error for debugging
            print("ModelContainer Error: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(locationService)
                .environmentObject(networkMonitor)
                .environment(\.authService, authService)
                .environment(\.locationService, locationService)
                .environment(\.networkMonitor, networkMonitor)
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // Configure appearance
        configureAppearance()

        // Register for remote notifications
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()

        // Check Apple ID credential state
        Task {
            await AuthenticationService.shared.checkAppleCredentialState()
        }

        AppLogger.app.info("App launched")

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppLogger.app.info("Registered for push notifications: \(token)")
        // TODO: Send token to backend
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        AppLogger.app.error("Failed to register for push notifications: \(error.localizedDescription)")
    }

    private func configureAppearance() {
        // Navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold, width: .standard)
        ]

        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance

        // Tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        handleNotification(userInfo: userInfo)
        completionHandler()
    }

    private func handleNotification(userInfo: [AnyHashable: Any]) {
        // Parse notification and navigate
        if let tripId = userInfo["trip_id"] as? String {
            NotificationCenter.default.post(
                name: .navigateToTrip,
                object: nil,
                userInfo: ["tripId": tripId]
            )
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToTrip = Notification.Name("navigateToTrip")
    static let navigateToRoute = Notification.Name("navigateToRoute")
    static let navigateToReport = Notification.Name("navigateToReport")
}
