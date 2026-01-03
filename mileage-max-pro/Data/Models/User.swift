//
//  User.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import SwiftData

/// User model for MileageMax Pro
@Model
final class User {
    // MARK: - Primary Identifiers

    @Attribute(.unique)
    var id: UUID

    @Attribute(.unique)
    var email: String

    var emailVerified: Bool

    var phoneNumber: String?
    var phoneVerified: Bool

    // MARK: - Profile Information

    var fullName: String
    var avatarURL: String?

    // MARK: - Localization

    var timezone: String
    var locale: String

    // MARK: - Subscription

    var subscriptionTierRaw: String
    var subscriptionStatusRaw: String
    var stripeCustomerId: String?
    var trialEndsAt: Date?

    // MARK: - Timestamps

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade, inverse: \Vehicle.user)
    var vehicles: [Vehicle]

    @Relationship(deleteRule: .cascade, inverse: \Trip.user)
    var trips: [Trip]

    @Relationship(deleteRule: .cascade, inverse: \DeliveryRoute.user)
    var deliveryRoutes: [DeliveryRoute]

    @Relationship(deleteRule: .cascade, inverse: \Expense.user)
    var expenses: [Expense]

    @Relationship(deleteRule: .cascade, inverse: \SavedLocation.user)
    var savedLocations: [SavedLocation]

    @Relationship(deleteRule: .cascade, inverse: \Earning.user)
    var earnings: [Earning]

    @Relationship(deleteRule: .cascade, inverse: \MileageReport.user)
    var mileageReports: [MileageReport]

    @Relationship(deleteRule: .cascade, inverse: \UserSettings.user)
    var settings: UserSettings?

    // MARK: - Computed Properties

    var subscriptionTier: AppConstants.SubscriptionTier {
        get { AppConstants.SubscriptionTier(rawValue: subscriptionTierRaw) ?? .free }
        set { subscriptionTierRaw = newValue.rawValue }
    }

    var subscriptionStatus: SubscriptionStatus {
        get { SubscriptionStatus(rawValue: subscriptionStatusRaw) ?? .active }
        set { subscriptionStatusRaw = newValue.rawValue }
    }

    var isActive: Bool {
        deletedAt == nil && subscriptionStatus == .active
    }

    var isPro: Bool {
        subscriptionTier == .pro || subscriptionTier == .business || subscriptionTier == .enterprise
    }

    var isBusiness: Bool {
        subscriptionTier == .business || subscriptionTier == .enterprise
    }

    var isTrialing: Bool {
        guard let trialEndsAt = trialEndsAt else { return false }
        return trialEndsAt > Date()
    }

    var primaryVehicle: Vehicle? {
        vehicles.first { $0.isPrimary && $0.isActive }
    }

    var activeVehicles: [Vehicle] {
        vehicles.filter { $0.isActive }
    }

    var firstName: String {
        fullName.split(separator: " ").first.map(String.init) ?? fullName
    }

    var lastName: String? {
        let components = fullName.split(separator: " ")
        guard components.count > 1 else { return nil }
        return components.dropFirst().joined(separator: " ")
    }

    var initials: String {
        let components = fullName.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "??"
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        email: String,
        fullName: String,
        timezone: String = TimeZone.current.identifier,
        locale: String = Locale.current.identifier
    ) {
        self.id = id
        self.email = email
        self.emailVerified = false
        self.phoneNumber = nil
        self.phoneVerified = false
        self.fullName = fullName
        self.avatarURL = nil
        self.timezone = timezone
        self.locale = locale
        self.subscriptionTierRaw = AppConstants.SubscriptionTier.free.rawValue
        self.subscriptionStatusRaw = SubscriptionStatus.active.rawValue
        self.stripeCustomerId = nil
        self.trialEndsAt = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil
        self.vehicles = []
        self.trips = []
        self.deliveryRoutes = []
        self.expenses = []
        self.savedLocations = []
        self.earnings = []
        self.mileageReports = []
        self.settings = nil
    }

    // MARK: - Methods

    func update() {
        updatedAt = Date()
    }

    func softDelete() {
        deletedAt = Date()
        update()
    }
}

// MARK: - Subscription Status

enum SubscriptionStatus: String, Codable, CaseIterable {
    case active = "active"
    case pastDue = "past_due"
    case canceled = "canceled"
    case paused = "paused"

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .pastDue: return "Past Due"
        case .canceled: return "Canceled"
        case .paused: return "Paused"
        }
    }

    var isActive: Bool {
        self == .active
    }
}

// MARK: - User DTO (for API communication)

struct UserDTO: Codable, Identifiable, Equatable {
    let id: UUID
    let email: String
    let emailVerified: Bool
    let phoneNumber: String?
    let phoneVerified: Bool
    let fullName: String
    let avatarURL: String?
    let timezone: String
    let locale: String
    let subscriptionTier: String
    let subscriptionStatus: String
    let trialEndsAt: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, email, timezone, locale
        case emailVerified = "email_verified"
        case phoneNumber = "phone_number"
        case phoneVerified = "phone_verified"
        case fullName = "full_name"
        case avatarURL = "avatar_url"
        case subscriptionTier = "subscription_tier"
        case subscriptionStatus = "subscription_status"
        case trialEndsAt = "trial_ends_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Convert to SwiftData model
    func toModel() -> User {
        let user = User(
            id: id,
            email: email,
            fullName: fullName,
            timezone: timezone,
            locale: locale
        )
        user.emailVerified = emailVerified
        user.phoneNumber = phoneNumber
        user.phoneVerified = phoneVerified
        user.avatarURL = avatarURL
        user.subscriptionTierRaw = subscriptionTier
        user.subscriptionStatusRaw = subscriptionStatus
        user.trialEndsAt = trialEndsAt
        user.createdAt = createdAt
        user.updatedAt = updatedAt
        return user
    }
}

extension User {
    /// Convert to DTO for API communication
    func toDTO() -> UserDTO {
        UserDTO(
            id: id,
            email: email,
            emailVerified: emailVerified,
            phoneNumber: phoneNumber,
            phoneVerified: phoneVerified,
            fullName: fullName,
            avatarURL: avatarURL,
            timezone: timezone,
            locale: locale,
            subscriptionTier: subscriptionTierRaw,
            subscriptionStatus: subscriptionStatusRaw,
            trialEndsAt: trialEndsAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
