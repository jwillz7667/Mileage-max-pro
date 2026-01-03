//
//  ColorConstants.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI

/// Color palette for MileageMax Pro following iOS 26.1 Liquid Glass design
enum ColorConstants {

    // MARK: - Primary Palette

    /// Primary brand color (iOS Blue with vibrancy)
    static let primary = Color(hex: "007AFF")

    /// Secondary brand color (iOS Purple)
    static let secondary = Color(hex: "5856D6")

    /// Accent color for positive actions (iOS Green)
    static let accent = Color(hex: "34C759")

    // MARK: - Semantic Colors

    /// Success state color
    static let success = Color(hex: "34C759")

    /// Warning state color
    static let warning = Color(hex: "FF9500")

    /// Error/destructive state color
    static let error = Color(hex: "FF3B30")

    /// Informational color
    static let info = Color(hex: "5AC8FA")

    // MARK: - Trip Category Colors

    enum TripCategory {
        static let business = Color(hex: "007AFF")
        static let personal = Color(hex: "5856D6")
        static let medical = Color(hex: "FF2D55")
        static let charity = Color(hex: "FF9500")
        static let moving = Color(hex: "AF52DE")
        static let commute = Color(hex: "00C7BE")
    }

    // MARK: - Vehicle Type Colors

    enum VehicleType {
        static let gasoline = Color(hex: "FF9500")
        static let diesel = Color(hex: "8E8E93")
        static let electric = Color(hex: "34C759")
        static let hybrid = Color(hex: "5AC8FA")
        static let pluginHybrid = Color(hex: "30D158")
    }

    // MARK: - Expense Category Colors

    enum ExpenseCategory {
        static let fuel = Color(hex: "FF9500")
        static let parking = Color(hex: "5856D6")
        static let tolls = Color(hex: "007AFF")
        static let maintenance = Color(hex: "FF2D55")
        static let repairs = Color(hex: "FF3B30")
        static let insurance = Color(hex: "AF52DE")
        static let registration = Color(hex: "5AC8FA")
        static let carWash = Color(hex: "00C7BE")
        static let supplies = Color(hex: "30D158")
        static let other = Color(hex: "8E8E93")
    }

    // MARK: - Chart Colors

    static let chartColors: [Color] = [
        Color(hex: "007AFF"),
        Color(hex: "34C759"),
        Color(hex: "FF9500"),
        Color(hex: "FF2D55"),
        Color(hex: "5856D6"),
        Color(hex: "5AC8FA"),
        Color(hex: "AF52DE"),
        Color(hex: "00C7BE"),
        Color(hex: "FF3B30"),
        Color(hex: "30D158")
    ]

    // MARK: - Gradient Definitions

    enum Gradients {
        /// Primary brand gradient
        static let primary = LinearGradient(
            colors: [Color(hex: "007AFF"), Color(hex: "5856D6")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Success gradient
        static let success = LinearGradient(
            colors: [Color(hex: "34C759"), Color(hex: "30D158")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Warning gradient
        static let warning = LinearGradient(
            colors: [Color(hex: "FF9500"), Color(hex: "FF6B00")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Error gradient
        static let error = LinearGradient(
            colors: [Color(hex: "FF3B30"), Color(hex: "FF2D55")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Glass overlay gradient for Liquid Glass effect
        static let glassOverlay = LinearGradient(
            colors: [
                Color.white.opacity(0.25),
                Color.white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Dark glass overlay for dark mode
        static let darkGlassOverlay = LinearGradient(
            colors: [
                Color.white.opacity(0.15),
                Color.white.opacity(0.02)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Shimmer gradient for loading states
        static let shimmer = LinearGradient(
            colors: [
                Color.gray.opacity(0.2),
                Color.gray.opacity(0.3),
                Color.gray.opacity(0.2)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Neumorphic Colors

    enum Neumorphic {
        /// Light mode light shadow color
        static let lightShadow = Color.white

        /// Light mode dark shadow color
        static let darkShadow = Color.black.opacity(0.15)

        /// Dark mode light shadow color (highlight)
        static let darkModeLightShadow = Color.white.opacity(0.05)

        /// Dark mode dark shadow color
        static let darkModeDarkShadow = Color.black.opacity(0.4)
    }

    // MARK: - Surface Colors

    enum Surface {
        /// Card background color
        static let card = Color(uiColor: .secondarySystemBackground)

        /// Elevated surface color
        static let elevated = Color(uiColor: .tertiarySystemBackground)

        /// Grouped background color
        static let grouped = Color(uiColor: .systemGroupedBackground)

        /// Secondary grouped background
        static let secondaryGrouped = Color(uiColor: .secondarySystemGroupedBackground)
    }

    // MARK: - Text Colors

    enum Text {
        /// Primary text color
        static let primary = Color(uiColor: .label)

        /// Secondary text color
        static let secondary = Color(uiColor: .secondaryLabel)

        /// Tertiary text color
        static let tertiary = Color(uiColor: .tertiaryLabel)

        /// Quaternary text color
        static let quaternary = Color(uiColor: .quaternaryLabel)

        /// Placeholder text color
        static let placeholder = Color(uiColor: .placeholderText)

        /// Disabled text color
        static let disabled = Color(uiColor: .tertiaryLabel)
    }

    // MARK: - Border Colors

    enum Border {
        /// Standard border color
        static let standard = Color(uiColor: .separator)

        /// Opaque border color
        static let opaque = Color(uiColor: .opaqueSeparator)

        /// Focus border color
        static let focus = primary

        /// Error border color
        static let error = ColorConstants.error
    }

    // MARK: - Map Colors

    enum Map {
        /// Route polyline color
        static let route = Color(hex: "007AFF")

        /// Active trip route color
        static let activeRoute = Color(hex: "34C759")

        /// Completed route color
        static let completedRoute = Color(hex: "8E8E93")

        /// Stop marker color
        static let stopMarker = Color(hex: "FF9500")

        /// Current location color
        static let currentLocation = Color(hex: "007AFF")

        /// Geofence fill color
        static let geofenceFill = Color(hex: "007AFF").opacity(0.2)

        /// Geofence stroke color
        static let geofenceStroke = Color(hex: "007AFF")
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    /// Initialize Color from hex string
    /// - Parameter hex: Hex color string (with or without #)
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Convert Color to hex string
    var hexString: String {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
