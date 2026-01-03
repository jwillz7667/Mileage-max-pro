//
//  Date+Extensions.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation

extension Date {

    // MARK: - Static Formatters (Cached for Performance)

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    private static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let longDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    private static let fullRelativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    private static let dayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()

    // MARK: - ISO 8601 Formatting

    /// Convert to ISO 8601 string for API communication
    var iso8601String: String {
        Self.isoFormatter.string(from: self)
    }

    /// Create Date from ISO 8601 string
    static func fromISO8601(_ string: String) -> Date? {
        isoFormatter.date(from: string)
    }

    // MARK: - Display Formatting

    /// Short date format (e.g., "1/2/26")
    var shortDateString: String {
        Self.shortDateFormatter.string(from: self)
    }

    /// Medium date format (e.g., "Jan 2, 2026")
    var mediumDateString: String {
        Self.mediumDateFormatter.string(from: self)
    }

    /// Long date format (e.g., "January 2, 2026")
    var longDateString: String {
        Self.longDateFormatter.string(from: self)
    }

    /// Time format (e.g., "2:30 PM")
    var timeString: String {
        Self.timeFormatter.string(from: self)
    }

    /// Date and time format (e.g., "Jan 2, 2026 at 2:30 PM")
    var dateTimeString: String {
        Self.dateTimeFormatter.string(from: self)
    }

    /// Relative time (e.g., "2h ago", "in 3d")
    var relativeString: String {
        Self.relativeDateFormatter.localizedString(for: self, relativeTo: Date())
    }

    /// Full relative time (e.g., "2 hours ago", "in 3 days")
    var fullRelativeString: String {
        Self.fullRelativeFormatter.localizedString(for: self, relativeTo: Date())
    }

    /// Day of week (e.g., "Monday")
    var dayOfWeek: String {
        Self.dayOfWeekFormatter.string(from: self)
    }

    /// Month and year (e.g., "January 2026")
    var monthYearString: String {
        Self.monthYearFormatter.string(from: self)
    }

    /// Year only (e.g., "2026")
    var yearString: String {
        Self.yearFormatter.string(from: self)
    }

    // MARK: - Smart Display

    /// Smart date string that shows relative for recent, absolute for older
    var smartDateString: String {
        let now = Date()
        let calendar = Calendar.current

        if calendar.isDateInToday(self) {
            return "Today, \(timeString)"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday, \(timeString)"
        } else if calendar.isDateInTomorrow(self) {
            return "Tomorrow, \(timeString)"
        } else if let days = calendar.dateComponents([.day], from: self, to: now).day,
                  abs(days) < 7 {
            return "\(dayOfWeek), \(timeString)"
        } else if calendar.component(.year, from: self) == calendar.component(.year, from: now) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: self)
        } else {
            return dateTimeString
        }
    }

    /// Alias for smartDateString for convenience
    var smartFormatted: String {
        smartDateString
    }

    /// Compact smart date for list views
    var compactDateString: String {
        let now = Date()
        let calendar = Calendar.current

        if calendar.isDateInToday(self) {
            return timeString
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else if let days = calendar.dateComponents([.day], from: self, to: now).day,
                  abs(days) < 7 {
            return dayOfWeek
        } else {
            return shortDateString
        }
    }

    // MARK: - Date Components

    /// Year component
    var year: Int {
        Calendar.current.component(.year, from: self)
    }

    /// Month component (1-12)
    var month: Int {
        Calendar.current.component(.month, from: self)
    }

    /// Day component (1-31)
    var day: Int {
        Calendar.current.component(.day, from: self)
    }

    /// Hour component (0-23)
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }

    /// Minute component (0-59)
    var minute: Int {
        Calendar.current.component(.minute, from: self)
    }

    /// Day of week (1 = Sunday, 7 = Saturday)
    var weekday: Int {
        Calendar.current.component(.weekday, from: self)
    }

    /// Week of year (1-52/53)
    var weekOfYear: Int {
        Calendar.current.component(.weekOfYear, from: self)
    }

    // MARK: - Date Calculations

    /// Start of day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// End of day (23:59:59.999)
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    /// Start of week (Monday)
    var startOfWeek: Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    /// End of week (Sunday)
    var endOfWeek: Date {
        var components = DateComponents()
        components.day = 6
        return Calendar.current.date(byAdding: components, to: startOfWeek)?.endOfDay ?? self
    }

    /// Start of month
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    /// End of month
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.day = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth)?.endOfDay ?? self
    }

    /// Start of year
    var startOfYear: Date {
        let components = Calendar.current.dateComponents([.year], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    /// End of year
    var endOfYear: Date {
        var components = DateComponents()
        components.year = 1
        components.day = -1
        return Calendar.current.date(byAdding: components, to: startOfYear)?.endOfDay ?? self
    }

    // MARK: - Date Arithmetic

    /// Add days to date
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Add weeks to date
    func addingWeeks(_ weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self) ?? self
    }

    /// Add months to date
    func addingMonths(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    /// Add years to date
    func addingYears(_ years: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: years, to: self) ?? self
    }

    /// Add time interval (convenience wrapper)
    func adding(_ component: Calendar.Component, value: Int) -> Date {
        Calendar.current.date(byAdding: component, value: value, to: self) ?? self
    }

    // MARK: - Comparisons

    /// Check if date is in the same day as another date
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }

    /// Check if date is in the same week as another date
    func isSameWeek(as date: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: .weekOfYear)
    }

    /// Check if date is in the same month as another date
    func isSameMonth(as date: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: .month)
    }

    /// Check if date is in the same year as another date
    func isSameYear(as date: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: .year)
    }

    /// Days between two dates
    func daysBetween(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: self, to: date).day ?? 0
    }

    /// Hours between two dates
    func hoursBetween(_ date: Date) -> Int {
        Calendar.current.dateComponents([.hour], from: self, to: date).hour ?? 0
    }

    /// Minutes between two dates
    func minutesBetween(_ date: Date) -> Int {
        Calendar.current.dateComponents([.minute], from: self, to: date).minute ?? 0
    }

    // MARK: - Business Logic

    /// Check if date falls within business hours
    func isWithinBusinessHours(start: Date, end: Date) -> Bool {
        let calendar = Calendar.current
        let selfHour = calendar.component(.hour, from: self)
        let selfMinute = calendar.component(.minute, from: self)
        let startHour = calendar.component(.hour, from: start)
        let startMinute = calendar.component(.minute, from: start)
        let endHour = calendar.component(.hour, from: end)
        let endMinute = calendar.component(.minute, from: end)

        let selfTime = selfHour * 60 + selfMinute
        let startTime = startHour * 60 + startMinute
        let endTime = endHour * 60 + endMinute

        return selfTime >= startTime && selfTime <= endTime
    }

    /// Check if date is on a work day (configurable)
    func isWorkDay(workDays: [Int] = [2, 3, 4, 5, 6]) -> Bool {
        // weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        workDays.contains(weekday)
    }

    /// Tax year for this date
    var taxYear: Int {
        // Tax year is typically the calendar year
        year
    }
}

// MARK: - TimeInterval Extensions

extension TimeInterval {
    /// Format duration as human-readable string
    var formattedDuration: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// Format duration as compact string (e.g., "2h 30m")
    var compactDuration: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "< 1m"
        }
    }

    /// Format duration as words (e.g., "2 hours, 30 minutes")
    var wordDuration: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60

        var components: [String] = []

        if hours > 0 {
            components.append("\(hours) \(hours == 1 ? "hour" : "hours")")
        }
        if minutes > 0 {
            components.append("\(minutes) \(minutes == 1 ? "minute" : "minutes")")
        }

        return components.isEmpty ? "Less than a minute" : components.joined(separator: ", ")
    }

    /// Create from hours
    static func hours(_ hours: Double) -> TimeInterval {
        hours * 3600
    }

    /// Create from minutes
    static func minutes(_ minutes: Double) -> TimeInterval {
        minutes * 60
    }

    /// Create from days
    static func days(_ days: Double) -> TimeInterval {
        days * 86400
    }
}
