//
//  AppLogger.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import os

/// Centralized logging facility for MileageMax Pro
enum AppLogger {

    // MARK: - Subsystem

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.mileagemaxpro"

    // MARK: - Log Categories

    static let app = os.Logger(subsystem: subsystem, category: "app")
    static let network = os.Logger(subsystem: subsystem, category: "network")
    static let data = os.Logger(subsystem: subsystem, category: "data")
    static let sync = os.Logger(subsystem: subsystem, category: "sync")
    static let location = os.Logger(subsystem: subsystem, category: "location")
    static let trip = os.Logger(subsystem: subsystem, category: "trip")
    static let auth = os.Logger(subsystem: subsystem, category: "auth")
    static let ui = os.Logger(subsystem: subsystem, category: "ui")
}
