import SwiftUI
import CoreLocation

struct FinderView: View {
    @EnvironmentObject var viewModel: ParkingSpotViewModel
    @StateObject private var locationManager = LocationManager()
    @State private var showingListView = false
    @State private var selectedSpot: ParkingSpot?
    @State private var nearbySpots: [ParkingSpot] = []
    @State private var isLoadingNearby = false
    @State private var centerOnUserLocation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map View
                MapView(
                    parkingSpots: nearbySpots,
                    userLocation: locationManager.location,
                    currentUserID: viewModel.firebaseService?.currentUser?.firebaseUID,
                    selectedSpot: $selectedSpot,
                    centerOnUserLocation: $centerOnUserLocation
                )
                
                // Controls overlay
                VStack {
                    // Top controls
                    HStack {
                        // Refresh button
                        Button(action: {
                            Task {
                                await refreshNearbySpots()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                                .rotationEffect(.degrees(isLoadingNearby ? 360 : 0))
                                .animation(isLoadingNearby ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoadingNearby)
                        }
                        .padding(.leading)
                        
                        // Location status indicator
                        HStack(spacing: 4) {
                            Image(systemName: locationManager.isLocationEnabled ? "location.fill" : "location.slash")
                                .foregroundColor(locationManager.isLocationEnabled ? .green : .red)
                                .font(.caption)
                            
                            if let location = locationManager.location {
                                Text("📍 \(String(format: "%.4f", location.coordinate.latitude)), \(String(format: "%.4f", location.coordinate.longitude))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("No location")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(UIColor.systemBackground).opacity(0.8))
                        .cornerRadius(8)
                        
                        // Center on location button
                        Button(action: {
                            centerOnUserLocation = true
                        }) {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(locationManager.location != nil ? Color.blue : Color.gray)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .disabled(locationManager.location == nil)
                        
                        // Map legend
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("My spots")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 8, height: 8)
                                Text("Other spots")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(UIColor.systemBackground).opacity(0.8))
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        // Toggle between map and list view
                        Button(action: {
                            showingListView.toggle()
                        }) {
                            Image(systemName: showingListView ? "map.fill" : "list.bullet")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing)
                    }
                    .padding(.top)
                    
                    Spacer()
                    
                    // Bottom sheet for available spots
                    if !nearbySpots.isEmpty {
                        VStack(spacing: 0) {
                            // Handle bar
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 40, height: 5)
                                .padding(.top, 8)
                            
                            // Content
                            if showingListView {
                                // List view
                                List(nearbySpots) { spot in
                                    ParkingSpotRowView(spot: spot) {
                                        selectedSpot = spot
                                    }
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                                }
                                .listStyle(PlainListStyle())
                                .frame(maxHeight: 300)
                            } else {
                                // Horizontal scroll view
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 16) {
                                        ForEach(nearbySpots) { spot in
                                            ParkingSpotCardView(spot: spot) {
                                                selectedSpot = spot
                                            }
                                            .frame(width: 280)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .frame(height: 180)
                            }
                        }
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(16, corners: [.topLeft, .topRight])
                        .shadow(radius: 8)
                    } else if isLoadingNearby {
                        // Loading state
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            
                            Text("Finding nearby parking spots...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(16, corners: [.topLeft, .topRight])
                        .shadow(radius: 8)
                    } else {
                        // No spots found
                        VStack(spacing: 16) {
                            Image(systemName: "car.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text("No parking spots found nearby")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Refresh") {
                                Task {
                                    await refreshNearbySpots()
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(16, corners: [.topLeft, .topRight])
                        .shadow(radius: 8)
                    }
                }
            }
            .navigationTitle("Find Parking")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                locationManager.requestLocationAndStartUpdates()
                Task {
                    // Refresh all data first
                    await viewModel.refreshAllData()
                    // Then refresh nearby spots
                    await refreshNearbySpots()
                }
            }
            .onChange(of: locationManager.location) { _ in
                Task {
                    await refreshNearbySpots()
                }
            }
            .sheet(item: $selectedSpot) { spot in
                SpotDetailView(spot: spot)
                    .environmentObject(viewModel)
            }
        }
    }
    
    /// Refresh nearby parking spots
    private func refreshNearbySpots() async {
        print("Refreshing nearby spots...")
        
        await MainActor.run {
            isLoadingNearby = true
        }
        
        // First, ensure we have the latest data
        await viewModel.fetchParkingSpots()
        
        guard let location = locationManager.location else {
            print("No location available, showing all spots")
            // If no location, show all spots (including user's own spots)
            await MainActor.run {
                nearbySpots = viewModel.parkingSpots
                isLoadingNearby = false
                print("Found \(nearbySpots.count) total spots")
            }
            return
        }
        
        print("Using location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // Get nearby spots from API
        let nearbySpotsFromAPI = await viewModel.getNearbyParkingSpots(location: location)
        
        // Combine nearby spots with user's own spots to ensure they show up on the map
        let userSpots = viewModel.userParkingSpots
        let allSpots = nearbySpotsFromAPI + userSpots.filter { userSpot in
            !nearbySpotsFromAPI.contains { $0.id == userSpot.id }
        }
        
        await MainActor.run {
            nearbySpots = allSpots
            isLoadingNearby = false
            print("Found \(nearbySpots.count) total spots (including \(userSpots.count) user spots)")
        }
    }
}

// MARK: - ParkingSpotCardView
struct ParkingSpotCardView: View {
    let spot: ParkingSpot
    let onTap: () -> Void
    @EnvironmentObject var viewModel: ParkingSpotViewModel
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.formatPrice(spot.hourlyRate))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    if let location = locationManager.location {
                        Text(viewModel.formatDistance(spot.distance(from: location)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Vehicle size badge
                Text(spot.maxVehicleSize.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
            }
            
            // Address
            Text(spot.address)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            // Description
            Text(spot.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Book button
            Button(action: onTap) {
                HStack {
                    Text("View Details")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - ParkingSpotRowView
struct ParkingSpotRowView: View {
    let spot: ParkingSpot
    let onTap: () -> Void
    @EnvironmentObject var viewModel: ParkingSpotViewModel
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        HStack(spacing: 12) {
            // Placeholder image
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "car.fill")
                        .foregroundColor(.gray)
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(viewModel.formatPrice(spot.hourlyRate))
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    if let location = locationManager.location {
                        Text(viewModel.formatDistance(spot.distance(from: location)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(spot.address)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(spot.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Arrow
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - View Extension for Corner Radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    FinderView()
        .environmentObject(ParkingSpotViewModel())
}