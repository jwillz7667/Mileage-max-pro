//
//  PushNotificationManager.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import Combine
import UserNotifications
import UIKit
import os

/// Manages push notification registration and token storage
@MainActor
final class PushNotificationManager: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = PushNotificationManager()

    // MARK: - Properties

    @Published private(set) var currentToken: String?
    @Published private(set) var isAuthorized = false

    // MARK: - Initialization

    private override init() {
        super.init()
        loadStoredToken()
    }

    // MARK: - Token Management

    func updateToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        currentToken = token
        storeToken(token)
        AppLogger.network.info("Push token updated")
    }

    func clearToken() {
        currentToken = nil
        UserDefaults.standard.removeObject(forKey: "pushNotificationToken")
    }

    private func loadStoredToken() {
        currentToken = UserDefaults.standard.string(forKey: "pushNotificationToken")
    }

    private func storeToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "pushNotificationToken")
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted

            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }

            return granted
        } catch {
            AppLogger.network.error("Push notification authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }
}
