//
//  DeviceInfo.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import UIKit

/// Provides device information for API requests
enum DeviceInfo {

    /// Unique device identifier (persisted in Keychain)
    static var deviceId: String {
        let service = "com.mileagemaxpro.device"
        let account = "deviceId"

        // Try to read existing ID
        if let data = KeychainHelper.shared.read(service: service, account: account),
           let id = String(data: data, encoding: .utf8) {
            return id
        }

        // Generate new UUID
        let newId = UUID().uuidString
        if let data = newId.data(using: .utf8) {
            KeychainHelper.shared.save(data, service: service, account: account)
        }
        return newId
    }

    /// Device name (e.g., "John's iPhone")
    static var deviceName: String {
        UIDevice.current.name
    }

    /// Device model (e.g., "iPhone15,2")
    static var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }

    /// iOS version (e.g., "17.0")
    static var osVersion: String {
        UIDevice.current.systemVersion
    }
}
