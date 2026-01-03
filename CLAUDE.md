# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
# Build the project (via Xcode)
xcodebuild -project mileage-max-pro.xcodeproj -scheme mileage-max-pro -sdk iphonesimulator build

# Run tests
xcodebuild -project mileage-max-pro.xcodeproj -scheme mileage-max-pro -sdk iphonesimulator test

# Run a single test
xcodebuild -project mileage-max-pro.xcodeproj -scheme mileage-max-pro -sdk iphonesimulator \
  -only-testing:mileage-max-proTests/TestClassName/testMethodName test

# Clean build
xcodebuild -project mileage-max-pro.xcodeproj -scheme mileage-max-pro clean
```

## Architecture Overview

**MileageMax Pro** is an enterprise iOS mileage tracking app built with SwiftUI and SwiftData, targeting iOS 26.1 with the Liquid Glass design language.

### Core Layers

1. **App Layer** (`App/`)
   - `MileageMaxProApp.swift` - Entry point, SwiftData container setup with CloudKit sync
   - `RootView.swift` - Auth state routing (splash → auth → main tabs)

2. **Services Layer** (`Services/`) - Singleton services injected via SwiftUI environment
   - `AuthenticationService` - Sign in with Apple, token management, biometrics
   - `LocationTrackingService` - GPS tracking, trip detection, waypoint recording

3. **Data Layer** (`Data/`)
   - `Models/` - SwiftData models: `User`, `Vehicle`, `Trip`, `TripWaypoint`, `Expense`, `SavedLocation`, `DeliveryRoute`, `DeliveryStop`, `MileageReport`
   - `Network/` - API client with automatic token refresh, typed endpoints for each domain

4. **Design System** (`Design/`)
   - `Theme/` - `AppTheme`, `LiquidGlassTheme`, `Typography`, `Spacing`
   - `Components/` - Reusable glass-morphic UI: `GlassButton`, `GlassMorphicCard`, `StatCard`, `GlassTextField`, `GlassToggle`, `GlassListRow`
   - `Animations/` - `MicroAnimations` with spring curves and view modifiers

5. **Core Utilities** (`Core/`)
   - `Constants/` - `AppConstants` (IRS rates, thresholds), `APIConstants`, `ColorConstants`
   - `Extensions/` - `Date+`, `Double+`, `View+`, `CLLocation+`
   - `Utilities/` - `AppLogger`, `HapticManager`, `BiometricAuthManager`, `FormatterCache`

### Key Patterns

- **Singleton Services**: `AuthenticationService.shared`, `LocationTrackingService.shared`, `APIClient.shared`, `NetworkMonitor.shared`
- **Environment Injection**: Services exposed via custom `EnvironmentKey` for SwiftUI access
- **Typed API Endpoints**: Each domain (Auth, Trips, Vehicles, Routes, Expenses, Reports, Locations) has an endpoint enum conforming to `APIEndpoint` protocol
- **State Management**: `LoadableState<T>` enum for async data (idle, loading, loaded, error, refreshing)

### API Architecture

The `APIClient` handles:
- Automatic token refresh on 401 responses
- Keychain-based token storage
- Retry logic with exponential backoff for 5xx errors
- Request/response logging via `AppLogger.network`

Endpoints are defined as enums implementing `APIEndpoint`:
```swift
enum TripEndpoints: APIEndpoint {
    case list(pagination: PaginationParameters, filters: TripFilters?)
    case create(trip: CreateTripRequest)
    // ...
}
```

### Design System Usage

All UI components follow the Liquid Glass aesthetic:
- Use `GlassMorphicCard` for container cards
- Use `GlassButton` with style variants: `.primary`, `.secondary`, `.tertiary`, `.destructive`, `.success`, `.glass`
- Use `Typography.` constants for text styles
- Use `Spacing.` constants (4-point grid: `.xs` = 4, `.sm` = 8, `.md` = 16, etc.)
- Use `ColorConstants.` for semantic colors

### SwiftData Models

Models use `@Model` macro with explicit relationships. The container is configured with CloudKit sync:
```swift
ModelConfiguration(cloudKitDatabase: .private("iCloud.com.mileagemaxpro"))
```

Key relationships:
- `User` → `Vehicle[]`, `Trip[]`, `Expense[]`, `SavedLocation[]`
- `Trip` → `TripWaypoint[]`, `Vehicle`
- `DeliveryRoute` → `DeliveryStop[]`

## Specification Reference

The project follows `mileage-tracker-spec.md` in the repository root, which defines:
- Complete data models and API contracts
- IRS mileage rates and compliance requirements
- UI/UX specifications for the Liquid Glass design
- Backend API structure (Node.js/Express on Railway with PostgreSQL+PostGIS)
