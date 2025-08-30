import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ParkingSpotViewModel()
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var showingProfile = false
    
    var body: some View {
        TabView {
            // Finder Tab - Find parking spots
            FinderView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Find Parking")
                }
            
            // Renter Tab - Rent out parking spots
            RenterView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Rent Out Spot")
                }
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .environmentObject(viewModel)
        .environmentObject(firebaseService)
        .accentColor(.blue)
        .onAppear {
            // Set Firebase service in ViewModel
            viewModel.setFirebaseService(firebaseService)
            
            // Request location permission when app starts
            viewModel.getLocationManager().requestLocationPermission()
            
            // Test authentication status
            viewModel.testAuthentication()
            
            // Test Firebase authentication and token
            Task {
                await firebaseService.testAuthAndToken()
            }
        }
        .overlay(
            // Global error message overlay
            Group {
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Image(systemName: errorMessage.contains("confirmed") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(errorMessage.contains("confirmed") ? .green : .orange)
                            
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button("Dismiss") {
                                viewModel.clearError()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 8)
                        .padding(.horizontal)
                        .padding(.bottom, 100) // Account for tab bar
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: viewModel.errorMessage)
                }
            }
        )
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // User Info Section
                Section {
                    HStack {
                        // Profile Image
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(firebaseService.currentUser?.name ?? "User")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(firebaseService.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Account Settings Section
                Section("Account") {
                    NavigationLink(destination: AccountSettingsView()) {
                        Label("Account Settings", systemImage: "person.circle")
                    }
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("Notifications", systemImage: "bell")
                    }
                    
                    NavigationLink(destination: PrivacySettingsView()) {
                        Label("Privacy & Security", systemImage: "lock.shield")
                    }
                }
                
                // App Settings Section
                Section("App") {
                    NavigationLink(destination: HelpSupportView()) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        Label("About", systemImage: "info.circle")
                    }
                    
                    Button("Test Authentication") {
                        Task {
                            await firebaseService.testAuthAndToken()
                        }
                    }
                    .foregroundColor(.blue)
                    
                    Button("Test Fetch Spots") {
                        Task {
                            do {
                                let spots = try await firebaseService.fetchParkingSpots()
                                print("✅ Successfully fetched \(spots.count) spots")
                            } catch {
                                print("❌ Failed to fetch spots: \(error)")
                            }
                        }
                    }
                    .foregroundColor(.green)
                    
                    Button("Test Fetch My Spots") {
                        Task {
                            do {
                                let mySpots = try await firebaseService.fetchMyParkingSpots()
                                print("✅ Successfully fetched \(mySpots.count) my spots")
                            } catch {
                                print("❌ Failed to fetch my spots: \(error)")
                            }
                        }
                    }
                    .foregroundColor(.orange)
                }
                
                // Logout Section
                Section {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        do {
                            try await firebaseService.signOut()
                        } catch {
                            // Error is handled by the service
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

// MARK: - Placeholder Views for Navigation

struct AccountSettingsView: View {
    var body: some View {
        Text("Account Settings")
            .navigationTitle("Account Settings")
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        Text("Notification Settings")
            .navigationTitle("Notifications")
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Text("Privacy & Security")
            .navigationTitle("Privacy & Security")
    }
}

struct HelpSupportView: View {
    var body: some View {
        Text("Help & Support")
            .navigationTitle("Help & Support")
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Parking App")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Find or rent parking spots near you with ease.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("About")
    }
}

#Preview {
    ContentView()
        .environmentObject(FirebaseService())
}
