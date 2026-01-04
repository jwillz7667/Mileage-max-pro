//
//  RootView.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI
import SwiftData
import AuthenticationServices
import os

/// Root view that handles navigation based on authentication state
struct RootView: View {

    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var networkMonitor: NetworkMonitor

    @State private var showSplash = true

    var body: some View {
        ZStack {
            // Main content based on auth state
            switch authService.authState {
            case .unknown:
                SplashView()

            case .unauthenticated:
                AuthenticationView()
                    .transition(.opacity)

            case .onboarding:
                OnboardingView()
                    .transition(.opacity)

            case .authenticated:
                MainTabView()
                    .transition(.opacity)
            }

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
            // Dismiss splash after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Splash View

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: CGFloat = 0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    ColorConstants.primary,
                    ColorConstants.secondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                // Logo
                Image(systemName: "car.fill")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                // App name
                VStack(spacing: Spacing.xs) {
                    Text("MileageMax")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Pro")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .opacity(logoOpacity)

                // Tagline
                Text("Track Every Mile. Maximize Every Deduction.")
                    .font(Typography.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var locationService: LocationTrackingService

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)

                TripsListView()
                    .tag(1)

                RoutesListView()
                    .tag(2)

                ReportsView()
                    .tag(3)

                SettingsView()
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom tab bar
            GlassTabBar(
                selectedTab: $selectedTab,
                tabs: [
                    ("house.fill", "Home"),
                    ("car.fill", "Trips"),
                    ("map.fill", "Routes"),
                    ("chart.bar.fill", "Reports"),
                    ("gearshape.fill", "Settings")
                ]
            )
        }
        .ignoresSafeArea(.keyboard)
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
