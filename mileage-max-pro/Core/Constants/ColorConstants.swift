//
//  ColorConstants.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//  Premium Design System - iOS 26 Liquid Glass
//

import SwiftUI

/// Premium color palette for MileageMax Pro
/// Design System: iOS 26 Liquid Glass + 3D Neomorphism
enum ColorConstants {

    // MARK: - Brand Colors

    /// Primary accent - Vibrant Blue #0087FF
    static let primary = Color(hex: "0087FF")

    /// Secondary accent - Sophisticated Gray #8C8C8C
    static let secondary = Color(hex: "8C8C8C")

    /// Tertiary accent - Lighter primary for highlights
    static let tertiary = Color(hex: "0087FF").opacity(0.6)

    /// Pure white background
    static let background = Color(hex: "FFFFFF")

    /// Primary text - Pure Black #000000
    static let textPrimary = Color(hex: "000000")

    // MARK: - Extended Palette

    /// Light primary tint for backgrounds
    static let primaryLight = Color(hex: "0087FF").opacity(0.08)

    /// Medium primary tint for hover states
    static let primaryMedium = Color(hex: "0087FF").opacity(0.15)

    /// Dark primary for pressed states
    static let primaryDark = Color(hex: "0066CC")

    /// Secondary light for subtle elements
    static let secondaryLight = Color(hex: "8C8C8C").opacity(0.1)

    /// Off-white for card backgrounds
    static let surfaceWhite = Color(hex: "FAFAFA")

    /// Subtle border color
    static let border = Color(hex: "E5E5E5")

    // MARK: - Semantic Colors

    /// Success state - Fresh green
    static let success = Color(hex: "00C853")

    /// Warning state - Warm amber
    static let warning = Color(hex: "FFB300")

    /// Error/destructive state - Crisp red
    static let error = Color(hex: "FF3D00")

    /// Info state - Cool blue
    static let info = Color(hex: "0087FF")

    // MARK: - Trip Category Colors

    enum TripCategory {
        static let business = Color(hex: "0087FF")
        static let personal = Color(hex: "8C8C8C")
        static let medical = Color(hex: "FF3D00")
        static let charity = Color(hex: "00C853")
        static let moving = Color(hex: "7C4DFF")
        static let commute = Color(hex: "FFB300")
    }

    // MARK: - Vehicle Type Colors

    enum VehicleType {
        static let gasoline = Color(hex: "FFB300")
        static let diesel = Color(hex: "8C8C8C")
        static let electric = Color(hex: "00C853")
        static let hybrid = Color(hex: "0087FF")
        static let pluginHybrid = Color(hex: "00E676")
    }

    // MARK: - Expense Category Colors

    enum ExpenseCategory {
        static let fuel = Color(hex: "FFB300")
        static let parking = Color(hex: "7C4DFF")
        static let tolls = Color(hex: "0087FF")
        static let maintenance = Color(hex: "FF3D00")
        static let repairs = Color(hex: "D50000")
        static let insurance = Color(hex: "8C8C8C")
        static let registration = Color(hex: "00B8D4")
        static let carWash = Color(hex: "00C853")
        static let supplies = Color(hex: "76FF03")
        static let other = Color(hex: "8C8C8C")
    }

    // MARK: - Chart Colors

    static let chartColors: [Color] = [
        Color(hex: "0087FF"),
        Color(hex: "00C853"),
        Color(hex: "FFB300"),
        Color(hex: "FF3D00"),
        Color(hex: "7C4DFF"),
        Color(hex: "00B8D4"),
        Color(hex: "8C8C8C"),
        Color(hex: "00E676"),
        Color(hex: "FF6D00"),
        Color(hex: "D500F9")
    ]

    // MARK: - Gradients

    enum Gradients {
        /// Primary brand gradient - Blue to lighter blue
        static let primary = LinearGradient(
            colors: [Color(hex: "0087FF"), Color(hex: "00A8FF")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Premium shimmer gradient
        static let shimmer = LinearGradient(
            colors: [Color(hex: "0087FF"), Color(hex: "00D4FF"), Color(hex: "0087FF")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Success gradient
        static let success = LinearGradient(
            colors: [Color(hex: "00C853"), Color(hex: "00E676")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Warning gradient
        static let warning = LinearGradient(
            colors: [Color(hex: "FFB300"), Color(hex: "FFC107")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Error gradient
        static let error = LinearGradient(
            colors: [Color(hex: "FF3D00"), Color(hex: "FF6E40")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Glass overlay - Premium liquid glass effect
        static let glassOverlay = LinearGradient(
            colors: [
                Color.white.opacity(0.4),
                Color.white.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Subtle glass highlight
        static let glassHighlight = LinearGradient(
            colors: [
                Color.white.opacity(0.6),
                Color.white.opacity(0.0)
            ],
            startPoint: .top,
            endPoint: .center
        )

        /// Card gradient background
        static let cardBackground = LinearGradient(
            colors: [
                Color(hex: "FFFFFF"),
                Color(hex: "F8F9FA")
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        /// Neomorphic inner shadow gradient
        static let neomorphicInner = LinearGradient(
            colors: [
                Color.black.opacity(0.05),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Neomorphic Colors

    enum Neomorphic {
        /// Light shadow (top-left)
        static let lightShadow = Color.white

        /// Dark shadow (bottom-right)
        static let darkShadow = Color.black.opacity(0.08)

        /// Inner light for pressed states
        static let innerLight = Color.white.opacity(0.8)

        /// Inner dark for pressed states
        static let innerDark = Color.black.opacity(0.03)

        /// Elevated surface
        static let elevated = Color(hex: "FFFFFF")

        /// Recessed surface
        static let recessed = Color(hex: "F0F0F0")
    }

    // MARK: - Surface Colors

    enum Surface {
        /// Pure white card
        static let card = Color(hex: "FFFFFF")

        /// Elevated white with subtle tint
        static let elevated = Color(hex: "FAFAFA")

        /// Grouped background - Very subtle gray
        static let grouped = Color(hex: "F5F5F7")

        /// Secondary grouped
        static let secondaryGrouped = Color(hex: "FFFFFF")

        /// Tertiary grouped
        static let tertiaryGrouped = Color(hex: "F0F0F2")

        /// Overlay background
        static let overlay = Color(hex: "000000").opacity(0.4)
    }

    // MARK: - Text Colors

    enum Text {
        /// Primary text - Pure black
        static let primary = Color(hex: "000000")

        /// Secondary text - Dark gray
        static let secondary = Color(hex: "666666")

        /// Tertiary text - Medium gray
        static let tertiary = Color(hex: "8C8C8C")

        /// Quaternary text - Light gray
        static let quaternary = Color(hex: "AEAEAE")

        /// Placeholder text
        static let placeholder = Color(hex: "C7C7C7")

        /// Disabled text
        static let disabled = Color(hex: "C7C7C7")

        /// Inverse text (white on dark)
        static let inverse = Color(hex: "FFFFFF")
    }

    // MARK: - Border Colors

    enum Border {
        /// Standard border - Subtle gray
        static let standard = Color(hex: "E5E5E5")

        /// Focused border - Primary blue
        static let focus = Color(hex: "0087FF")

        /// Error border - Red
        static let error = Color(hex: "FF3D00")

        /// Success border - Green
        static let success = Color(hex: "00C853")

        /// Glass border - White with opacity
        static let glass = Color.white.opacity(0.3)
    }

    // MARK: - Map Colors

    enum Map {
        /// Active route - Primary blue
        static let route = Color(hex: "0087FF")

        /// Active trip route - Success green
        static let activeRoute = Color(hex: "00C853")

        /// Completed route - Secondary gray
        static let completedRoute = Color(hex: "8C8C8C")

        /// Stop marker - Warning amber
        static let stopMarker = Color(hex: "FFB300")

        /// Start marker - Success green
        static let startMarker = Color(hex: "00C853")

        /// End marker - Error red
        static let endMarker = Color(hex: "FF3D00")

        /// Current location - Primary blue
        static let currentLocation = Color(hex: "0087FF")

        /// Geofence fill
        static let geofenceFill = Color(hex: "0087FF").opacity(0.15)

        /// Geofence stroke
        static let geofenceStroke = Color(hex: "0087FF")
    }

    // MARK: - Glass Effect Colors

    enum Glass {
        /// Glass tint - White base
        static let tint = Color.white.opacity(0.7)

        /// Glass border
        static let border = Color.white.opacity(0.4)

        /// Glass shadow
        static let shadow = Color.black.opacity(0.06)

        /// Frosted glass overlay
        static let frosted = Color.white.opacity(0.85)

        /// Primary tinted glass
        static let primaryTint = Color(hex: "0087FF").opacity(0.08)
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

// MARK: - Accent Color Alias

extension Color {
    /// App accent color shorthand
    static var accent: Color { ColorConstants.primary }
}
