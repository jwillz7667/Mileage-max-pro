//
//  RootView.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI
import SwiftData
import AuthenticationServices
import CoreLocation
import os

/// Root view that handles navigation based on authentication state
struct RootView: View {

    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var locationService: LocationTrackingService
    @EnvironmentObject private var networkMonitor: NetworkMonitor

    @State private var showSplash = true

    var body: some View {
        ZStack {
            // BYPASS AUTH - Go straight to main app
            MainTabView()
                .transition(.opacity)

            // Splash overlay
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.authState)
        .offlineBanner()
        .onAppear {
            // Initialize location services
            initializeLocationServices()

            // Dismiss splash after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showSplash = false
                }
            }
        }
        .onChange(of: locationService.authorizationStatus) { _, newStatus in
            // Start monitoring when permission is granted
            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                if locationService.trackingState == .idle {
                    locationService.startMonitoring()
                }
            }
        }
    }

    private func initializeLocationServices() {
        // Request location permission if not determined
        if locationService.authorizationStatus == .notDetermined {
            locationService.requestAuthorization()
        } else if locationService.hasAnyAuthorization {
            // Start monitoring if we already have permission
            locationService.startMonitoring()
        }
    }
}

// MARK: - Premium Splash View

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: CGFloat = 0
    @State private var textOpacity: CGFloat = 0
    @State private var taglineOpacity: CGFloat = 0
    @State private var ringRotation: Double = 0
    @State private var glowOpacity: CGFloat = 0

    var body: some View {
        ZStack {
            // Premium white background
            ColorConstants.background
                .ignoresSafeArea()

            // Subtle radial gradient
            RadialGradient(
                colors: [
                    ColorConstants.primary.opacity(0.08),
                    ColorConstants.background
                ],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Logo with animated ring
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [ColorConstants.primary.opacity(0.3), ColorConstants.primary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(ringRotation))
                        .opacity(glowOpacity)

                    // Inner circle background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ColorConstants.primary, ColorConstants.primary.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: ColorConstants.primary.opacity(0.4), radius: 20, x: 0, y: 10)

                    // Car icon
                    Image(systemName: "car.fill")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // App name with premium typography
                VStack(spacing: 4) {
                    Text("MileageMax")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(ColorConstants.Text.primary)
                        .tracking(-0.5)

                    Text("PRO")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(ColorConstants.primary)
                        .tracking(4)
                }
                .opacity(textOpacity)

                // Tagline
                Text("Track Every Mile. Maximize Every Deduction.")
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorConstants.Text.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(taglineOpacity)

                Spacer()

                // Bottom branding
                VStack(spacing: Spacing.xs) {
                    Text("Enterprise Mileage Tracking")
                        .font(Typography.caption2)
                        .foregroundStyle(ColorConstants.Text.tertiary)
                }
                .opacity(taglineOpacity)
                .padding(.bottom, Spacing.xl)
            }
            .padding(.horizontal, Spacing.xl)
        }
        .onAppear {
            // Staggered animations for premium feel
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                textOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                taglineOpacity = 1.0
                glowOpacity = 1.0
            }

            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showingActiveTrip = false
    @EnvironmentObject private var locationService: LocationTrackingService

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            TripsListView()
                .tabItem {
                    Label("Trips", systemImage: "car.fill")
                }
                .tag(1)

            RoutesListView()
                .tabItem {
                    Label("Routes", systemImage: "map.fill")
                }
                .tag(2)

            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "chart.bar.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .fullScreenCover(isPresented: $showingActiveTrip) {
            ActiveTripView()
        }
        .onChange(of: locationService.trackingState) { _, newState in
            // Show ActiveTripView when tracking starts
            if newState == .tracking {
                showingActiveTrip = true
            } else if newState == .monitoring || newState == .idle {
                showingActiveTrip = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToTrip)) { notification in
            if let _ = notification.userInfo?["tripId"] as? String {
                selectedTab = 1
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToRoute)) { notification in
            if let _ = notification.userInfo?["routeId"] as? String {
                selectedTab = 2
            }
        }
    }
}

// Note: Views are implemented in Features/ folder:
// - DashboardView in Features/Dashboard/Views/
// - TripsListView in Features/Trips/Views/
// - RoutesListView in Features/Routes/Views/
// - ReportsView in Features/Reports/Views/
// - SettingsView in Features/Settings/Views/

struct AuthenticationView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @State private var showingEmailAuth = false
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Logo and tagline
            VStack(spacing: Spacing.md) {
                Image(systemName: "car.fill")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(ColorConstants.primary)

                Text("MileageMax Pro")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(ColorConstants.Text.primary)

                Text("Track mileage. Maximize deductions.")
                    .font(Typography.body)
                    .foregroundStyle(ColorConstants.Text.secondary)
            }

            Spacer()

            // Sign in buttons
            VStack(spacing: Spacing.md) {
                // Sign in with Apple
                SignInWithAppleButton {
                    Task {
                        do {
                            try await authService.signInWithApple()
                        } catch {
                            errorMessage = error.localizedDescription
                            showingError = true
                            AppLogger.auth.error("Sign in with Apple failed: \(error.localizedDescription)")
                        }
                    }
                }
                .frame(height: 52)
                .cornerRadius(26)

                // Sign in with Google (placeholder)
                GlassButton("Continue with Google", icon: "g.circle.fill", style: .secondary, size: .fullWidth) {
                    // Google sign in
                }

                // Email sign in
                GlassButton("Continue with Email", icon: "envelope.fill", style: .tertiary, size: .fullWidth) {
                    showingEmailAuth = true
                }
            }
            .padding(.horizontal, Spacing.lg)

            // Terms
            Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                .font(Typography.caption2)
                .foregroundStyle(ColorConstants.Text.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.lg)
        }
        .sheet(isPresented: $showingEmailAuth) {
            EmailAuthSheet()
        }
        .alert("Sign In Failed", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred. Please try again.")
        }
    }
}

struct SignInWithAppleButton: UIViewRepresentable {
    var onRequest: () -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onRequest: onRequest)
    }

    class Coordinator: NSObject {
        var onRequest: () -> Void

        init(onRequest: @escaping () -> Void) {
            self.onRequest = onRequest
        }

        @objc func buttonTapped() {
            onRequest()
        }
    }
}

struct OnboardingView: View {
    var body: some View {
        VStack {
            Text("Onboarding")
                .font(Typography.largeTitle)
        }
    }
}

struct AddTripSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Add Trip")
            }
            .navigationTitle("Add Trip")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EmailAuthSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Email Authentication")
            }
            .navigationTitle("Sign In")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Root View") {
    RootView()
        .environmentObject(AuthenticationService.shared)
        .environmentObject(LocationTrackingService.shared)
        .environmentObject(NetworkMonitor.shared)
}
