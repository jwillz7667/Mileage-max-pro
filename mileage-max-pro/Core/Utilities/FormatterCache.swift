//
//  FormatterCache.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation

/// Cached formatters for optimal performance
/// DateFormatter and NumberFormatter are expensive to create
final class FormatterCache {

    // MARK: - Singleton

    static let shared = FormatterCache()

    // MARK: - Date Formatters

    lazy var iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    lazy var shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    lazy var mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    lazy var longDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    lazy var shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    lazy var mediumTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()

    lazy var dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    lazy var relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    lazy var fullRelativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    lazy var dayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    lazy var shortDayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    lazy var monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    lazy var shortMonthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()

    lazy var yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()

    lazy var monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    lazy var timeOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    lazy var hour24Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    // MARK: - Number Formatters

    lazy var currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }()

    lazy var usdCurrencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    lazy var decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    lazy var percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    lazy var integerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    lazy var oneDecimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    lazy var twoDecimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    lazy var ordinalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()

    // MARK: - Measurement Formatters

    lazy var distanceFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()

    lazy var speedFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }()

    lazy var volumeFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 2
        return formatter
    }()

    // MARK: - Byte Count Formatter

    lazy var byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter
    }()

    // MARK: - Duration Formatter

    lazy var durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropLeading
        return formatter
    }()

    lazy var shortDurationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropLeading
        return formatter
    }()

    lazy var fullDurationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        formatter.zeroFormattingBehavior = .dropLeading
        return formatter
    }()

    // MARK: - List Formatter

    lazy var listFormatter: ListFormatter = {
        let formatter = ListFormatter()
        return formatter
    }()

    // MARK: - Person Name Formatter

    lazy var personNameFormatter: PersonNameComponentsFormatter = {
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .default
        return formatter
    }()

    lazy var shortNameFormatter: PersonNameComponentsFormatter = {
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .abbreviated
        return formatter
    }()

    // MARK: - Initialization

    private init() {}

    // MARK: - Convenience Methods

    /// Format date with specified style
    func formatDate(_ date: Date, style: DateFormatStyle) -> String {
        switch style {
        case .short:
            return shortDateFormatter.string(from: date)
        case .medium:
            return mediumDateFormatter.string(from: date)
        case .long:
            return longDateFormatter.string(from: date)
        case .time:
            return shortTimeFormatter.string(from: date)
        case .dateTime:
            return dateTimeFormatter.string(from: date)
        case .relative:
            return relativeDateFormatter.localizedString(for: date, relativeTo: Date())
        case .iso8601:
            return iso8601Formatter.string(from: date)
        }
    }

    /// Format number as currency
    func formatCurrency(_ value: Double, locale: Locale? = nil) -> String {
        if let locale = locale {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = locale
            return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
        }
        return currencyFormatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }

    /// Format number with decimals
    func formatDecimal(_ value: Double, decimals: Int = 2) -> String {
        let formatter: NumberFormatter
        switch decimals {
        case 0: formatter = integerFormatter
        case 1: formatter = oneDecimalFormatter
        case 2: formatter = twoDecimalFormatter
        default:
            let custom = NumberFormatter()
            custom.numberStyle = .decimal
            custom.minimumFractionDigits = decimals
            custom.maximumFractionDigits = decimals
            return custom.string(from: NSNumber(value: value)) ?? "\(value)"
        }
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// Format duration from seconds
    func formatDuration(_ seconds: TimeInterval, style: DurationFormatStyle = .abbreviated) -> String {
        let formatter: DateComponentsFormatter
        switch style {
        case .abbreviated:
            formatter = durationFormatter
        case .short:
            formatter = shortDurationFormatter
        case .full:
            formatter = fullDurationFormatter
        }
        return formatter.string(from: seconds) ?? "\(Int(seconds))s"
    }

    /// Format distance
    func formatDistance(_ meters: Double, unit: DistanceUnit = .miles) -> String {
        let measurement: Measurement<UnitLength>
        switch unit {
        case .miles:
            measurement = Measurement(value: meters * 0.000621371, unit: .miles)
        case .kilometers:
            measurement = Measurement(value: meters / 1000, unit: .kilometers)
        }
        return distanceFormatter.string(from: measurement)
    }

    /// Format file size
    func formatBytes(_ bytes: Int64) -> String {
        byteCountFormatter.string(fromByteCount: bytes)
    }
}

// MARK: - Date Format Style

enum DateFormatStyle {
    case short
    case medium
    case long
    case time
    case dateTime
    case relative
    case iso8601
}

// MARK: - Duration Format Style

enum DurationFormatStyle {
    case abbreviated
    case short
    case full
}
