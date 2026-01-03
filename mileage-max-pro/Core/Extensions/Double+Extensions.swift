//
//  Double+Extensions.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation

extension Double {

    // MARK: - Distance Formatting

    /// Format as miles (e.g., "12.5 mi")
    var formattedMiles: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        let value = formatter.string(from: NSNumber(value: self)) ?? "\(self)"
        return "\(value) mi"
    }

    /// Format as miles without unit (e.g., "12.5")
    var formattedMilesValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    /// Format as kilometers (e.g., "20.1 km")
    var formattedKilometers: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        let value = formatter.string(from: NSNumber(value: self)) ?? "\(self)"
        return "\(value) km"
    }

    /// Format distance adaptively (meters for small, miles for larger)
    func formattedDistance(unit: DistanceUnit = .miles) -> String {
        switch unit {
        case .miles:
            if self < 0.1 {
                let feet = self * 5280
                return "\(Int(feet)) ft"
            }
            return formattedMiles
        case .kilometers:
            if self < 0.1 {
                let meters = self * 1000
                return "\(Int(meters)) m"
            }
            return formattedKilometers
        }
    }

    /// Convert meters to miles
    var metersToMiles: Double {
        self * 0.000621371
    }

    /// Convert miles to meters
    var milesToMeters: Double {
        self / 0.000621371
    }

    /// Convert meters to kilometers
    var metersToKilometers: Double {
        self / 1000
    }

    /// Convert kilometers to meters
    var kilometersToMeters: Double {
        self * 1000
    }

    /// Convert miles to kilometers
    var milesToKilometers: Double {
        self * 1.60934
    }

    /// Convert kilometers to miles
    var kilometersToMiles: Double {
        self / 1.60934
    }

    // MARK: - Speed Formatting

    /// Format as mph (e.g., "65 mph")
    var formattedMPH: String {
        "\(Int(self)) mph"
    }

    /// Format as km/h (e.g., "105 km/h")
    var formattedKMH: String {
        "\(Int(self)) km/h"
    }

    /// Convert meters per second to miles per hour
    var mpsToMPH: Double {
        self * 2.23694
    }

    /// Convert miles per hour to meters per second
    var mphToMPS: Double {
        self / 2.23694
    }

    /// Convert meters per second to km/h
    var mpsToKMH: Double {
        self * 3.6
    }

    /// Convert km/h to meters per second
    var kmhToMPS: Double {
        self / 3.6
    }

    // MARK: - Currency Formatting

    /// Format as currency (e.g., "$12.50")
    var formattedCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: self)) ?? "$\(self)"
    }

    /// Format as currency with explicit locale
    func formattedCurrency(locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: NSNumber(value: self)) ?? "$\(self)"
    }

    /// Format as USD specifically
    var formattedUSD: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: self)) ?? "$\(self)"
    }

    /// Alias for formattedCurrency for convenience
    func asCurrency() -> String {
        formattedCurrency
    }

    /// Alias for formattedMiles for convenience
    func asMiles() -> String {
        formattedMiles
    }

    /// Format as compact currency (e.g., "$1.2K")
    var compactCurrency: String {
        if self >= 1_000_000 {
            return String(format: "$%.1fM", self / 1_000_000)
        } else if self >= 1_000 {
            return String(format: "$%.1fK", self / 1_000)
        } else {
            return formattedCurrency
        }
    }

    // MARK: - Fuel Formatting

    /// Format as gallons (e.g., "12.5 gal")
    var formattedGallons: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 2
        let value = formatter.string(from: NSNumber(value: self)) ?? "\(self)"
        return "\(value) gal"
    }

    /// Format as liters (e.g., "47.3 L")
    var formattedLiters: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        let value = formatter.string(from: NSNumber(value: self)) ?? "\(self)"
        return "\(value) L"
    }

    /// Format as MPG (e.g., "28.5 mpg")
    var formattedMPG: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        let value = formatter.string(from: NSNumber(value: self)) ?? "\(self)"
        return "\(value) mpg"
    }

    /// Format as L/100km
    var formattedL100km: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        let value = formatter.string(from: NSNumber(value: self)) ?? "\(self)"
        return "\(value) L/100km"
    }

    /// Convert gallons to liters
    var gallonsToLiters: Double {
        self * 3.78541
    }

    /// Convert liters to gallons
    var litersToGallons: Double {
        self / 3.78541
    }

    /// Convert MPG to L/100km
    var mpgToL100km: Double {
        guard self > 0 else { return 0 }
        return 235.215 / self
    }

    /// Convert L/100km to MPG
    var l100kmToMPG: Double {
        guard self > 0 else { return 0 }
        return 235.215 / self
    }

    // MARK: - Percentage Formatting

    /// Format as percentage (e.g., "85.5%")
    var formattedPercentage: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: self)) ?? "\(self * 100)%"
    }

    /// Format as percentage without multiplication
    var formattedPercentageValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        let value = formatter.string(from: NSNumber(value: self)) ?? "\(self)"
        return "\(value)%"
    }

    // MARK: - General Formatting

    /// Format with decimal places
    func formatted(decimals: Int) -> String {
        String(format: "%.\(decimals)f", self)
    }

    /// Format with thousands separator
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    /// Format as compact number (e.g., "1.2K", "3.5M")
    var compactFormatted: String {
        if abs(self) >= 1_000_000 {
            return String(format: "%.1fM", self / 1_000_000)
        } else if abs(self) >= 1_000 {
            return String(format: "%.1fK", self / 1_000)
        } else {
            return formattedWithSeparator
        }
    }

    // MARK: - Rounding

    /// Round to specified decimal places
    func rounded(toPlaces places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }

    /// Round up to specified decimal places
    func roundedUp(toPlaces places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded(.up) / multiplier
    }

    /// Round down to specified decimal places
    func roundedDown(toPlaces places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded(.down) / multiplier
    }

    // MARK: - Clamping

    /// Clamp value between min and max
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }

    /// Clamp to positive values
    var clampedPositive: Double {
        max(self, 0)
    }

    // MARK: - CO2 Emissions

    /// Calculate CO2 emissions in kg from fuel gallons (average gasoline)
    var gallonsToCO2Kg: Double {
        self * 8.887 // EPA: 8.887 kg CO2 per gallon of gasoline
    }

    /// Format as CO2 emissions
    var formattedCO2: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        let value = formatter.string(from: NSNumber(value: self)) ?? "\(self)"
        return "\(value) kg CO2"
    }
}

// MARK: - Distance Unit

enum DistanceUnit: String, CaseIterable, Codable {
    case miles = "miles"
    case kilometers = "kilometers"

    var abbreviation: String {
        switch self {
        case .miles: return "mi"
        case .kilometers: return "km"
        }
    }

    var displayName: String {
        switch self {
        case .miles: return "Miles"
        case .kilometers: return "Kilometers"
        }
    }
}

// MARK: - Fuel Unit

enum FuelUnit: String, CaseIterable, Codable {
    case gallons = "gallons"
    case liters = "liters"

    var abbreviation: String {
        switch self {
        case .gallons: return "gal"
        case .liters: return "L"
        }
    }

    var displayName: String {
        switch self {
        case .gallons: return "Gallons"
        case .liters: return "Liters"
        }
    }
}

// MARK: - Fuel Economy Unit

enum FuelEconomyUnit: String, CaseIterable, Codable {
    case mpg = "mpg"
    case l100km = "l100km"
    case kml = "kml"

    var displayName: String {
        switch self {
        case .mpg: return "MPG"
        case .l100km: return "L/100km"
        case .kml: return "km/L"
        }
    }
}

// MARK: - Int Extensions

extension Int {
    /// Format with thousands separator
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    /// Format as compact number
    var compactFormatted: String {
        Double(self).compactFormatted
    }

    /// Format as ordinal (e.g., "1st", "2nd", "3rd")
    var ordinal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

// MARK: - Decimal Extensions

extension Decimal {
    /// Format as currency
    var formattedCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: self as NSNumber) ?? "$\(self)"
    }

    /// Format as USD
    var formattedUSD: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: self as NSNumber) ?? "$\(self)"
    }

    /// Convert to Double
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
