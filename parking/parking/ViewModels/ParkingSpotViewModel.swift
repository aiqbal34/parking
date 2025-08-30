import Foundation
import CoreLocation
import Combine

// MARK: - ParkingSpotViewModel
/// Main view model that manages parking spot data and user interactions
class ParkingSpotViewModel: ObservableObject {
    @Published var parkingSpots: [ParkingSpot] = []
    @Published var userParkingSpots: [ParkingSpot] = []
    @Published var userBookings: [Booking] = []
    @Published var pendingBookings: [Booking] = [] // Bookings waiting for owner approval
    @Published var selectedSpot: ParkingSpot?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    // Firebase service will be injected
    var firebaseService: FirebaseService?
    
    init() {
        setupBindings()
    }
    
    /// Setup reactive bindings
    private func setupBindings() {
        // Update user parking spots when main spots change
        $parkingSpots
            .map { spots in
                guard let currentUser = self.firebaseService?.currentUser,
                      let firebaseUID = currentUser.firebaseUID else {
                    return []
                }
                return spots.filter { $0.ownerID == firebaseUID }
            }
            .assign(to: \.userParkingSpots, on: self)
            .store(in: &cancellables)
    }
    
    /// Set Firebase service and load initial data
    func setFirebaseService(_ service: FirebaseService) {
        print("🔍 Setting Firebase service in ViewModel...")
        print("🔍 Service authenticated: \(service.isAuthenticated)")
        print("🔍 Current user: \(service.currentUser?.name ?? "nil")")
        print("🔍 Firebase UID: \(service.currentUser?.firebaseUID ?? "nil")")
        
        self.firebaseService = service
        loadData()
        // Manually update user parking spots after setting the service
        updateUserParkingSpots()
    }
    
    /// Manually update user parking spots
    private func updateUserParkingSpots() {
        print("🔍 Updating user parking spots...")
        print("🔍 Total parking spots: \(parkingSpots.count)")
        print("🔍 Current user: \(firebaseService?.currentUser?.name ?? "nil")")
        print("🔍 Firebase UID: \(firebaseService?.currentUser?.firebaseUID ?? "nil")")
        
        guard let currentUser = firebaseService?.currentUser,
              let firebaseUID = currentUser.firebaseUID else {
            print("❌ No current user or firebase UID")
            userParkingSpots = []
            return
        }
        
        let userSpots = parkingSpots.filter { spot in
            let isOwned = spot.ownerID == firebaseUID
            if isOwned {
                print("✅ Found user spot: \(spot.address) (ID: \(spot.ownerID))")
            }
            return isOwned
        }
        
        userParkingSpots = userSpots
        print("✅ User parking spots: \(userParkingSpots.count)")
    }
    
    /// Load initial data
    private func loadData() {
        print("🔍 Loading initial data...")
        Task {
            print("🔍 Starting to fetch parking spots...")
            await fetchParkingSpots()
            print("🔍 Starting to fetch my parking spots...")
            await fetchMyParkingSpots()
            print("🔍 Starting to fetch user bookings...")
            await fetchUserBookings()
            print("🔍 Starting to fetch pending bookings...")
            await fetchPendingBookings()
            print("🔍 Finished loading initial data")
        }
    }
    
    // MARK: - Location Services
    
    /// Get location manager for location services
    func getLocationManager() -> LocationManager {
        return locationManager
    }
    
    /// Get nearby parking spots based on current location
    func getNearbyParkingSpots(location: CLLocation) async -> [ParkingSpot] {
        guard let firebaseService = firebaseService else { return [] }
        
        do {
            return try await firebaseService.fetchNearbyParkingSpots(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch nearby spots: \(error.localizedDescription)"
            }
            return []
        }
    }
    
    // MARK: - Finder Operations
    
    /// Select a parking spot for detailed view
    func selectSpot(_ spot: ParkingSpot) {
        selectedSpot = spot
    }
    
    /// Send a booking request for a parking spot
    func sendBookingRequest(spot: ParkingSpot, startTime: Date, endTime: Date, message: String? = nil) {
        guard let firebaseService = firebaseService else { return }
        
        Task {
            do {
                let bookingId = try await firebaseService.createBookingRequest(
                    spot: spot,
                    startTime: startTime,
                    endTime: endTime,
                    message: message
                )
                
                await MainActor.run {
                    self.errorMessage = "Booking request sent! Reference: \(String(bookingId.prefix(8)))"
                }
                
                // Refresh bookings
                await fetchUserBookings()
                
                // Clear the message after 3 seconds
                try await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    if self.errorMessage?.contains("Booking request sent") == true {
                        self.errorMessage = nil
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to send booking request: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Cancel a booking request
    func cancelBookingRequest(_ booking: Booking) {
        guard let firebaseService = firebaseService else { return }
        
        Task {
            do {
                try await firebaseService.cancelBookingRequest(bookingId: booking.id)
                
                await MainActor.run {
                    self.errorMessage = "Booking request cancelled successfully!"
                }
                
                // Refresh bookings
                await fetchUserBookings()
                
                // Clear the message after 3 seconds
                try await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    if self.errorMessage?.contains("cancelled successfully") == true {
                        self.errorMessage = nil
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to cancel booking request: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Renter Operations
    
    /// Approve a booking request
    func approveBookingRequest(_ booking: Booking, response: String? = nil) {
        guard let firebaseService = firebaseService else { return }
        
        Task {
            do {
                try await firebaseService.approveBookingRequest(
                    bookingId: booking.id,
                    responseMessage: response
                )
                
                await MainActor.run {
                    self.errorMessage = "Booking request approved!"
                }
                
                // Refresh pending bookings
                await fetchPendingBookings()
                
                // Clear the message after 3 seconds
                try await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    if self.errorMessage?.contains("approved") == true {
                        self.errorMessage = nil
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to approve booking request: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Reject a booking request
    func rejectBookingRequest(_ booking: Booking, response: String? = nil) {
        guard let firebaseService = firebaseService else { return }
        
        Task {
            do {
                try await firebaseService.rejectBookingRequest(
                    bookingId: booking.id,
                    responseMessage: response
                )
                
                await MainActor.run {
                    self.errorMessage = "Booking request rejected!"
                }
                
                // Refresh pending bookings
                await fetchPendingBookings()
                
                // Clear the message after 3 seconds
                try await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    if self.errorMessage?.contains("rejected") == true {
                        self.errorMessage = nil
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to reject booking request: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Add a new parking spot
    func addParkingSpot(
        address: String,
        coordinate: CLLocationCoordinate2D,
        hourlyRate: Double,
        availabilityStart: Date,
        availabilityEnd: Date,
        maxVehicleSize: VehicleSize,
        description: String
    ) {
        guard let firebaseService = firebaseService,
              let currentUser = firebaseService.currentUser else { return }
        
        let newSpot = ParkingSpot(
            address: address,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            hourlyRate: hourlyRate,
            isAvailable: true,
            availabilityStart: availabilityStart,
            availabilityEnd: availabilityEnd,
            maxVehicleSize: maxVehicleSize,
            description: description,
            imageURL: nil,
            ownerID: currentUser.firebaseUID ?? "",
            ownerName: currentUser.name
        )
        
        Task {
            do {
                let spotId = try await firebaseService.createParkingSpot(newSpot)
                
                await MainActor.run {
                    self.errorMessage = "Parking spot added successfully!"
                }
                
                // Refresh parking spots
                await fetchParkingSpots()
                
                // Fetch user's own spots immediately
                await fetchMyParkingSpots()
                
                // Clear the message after 3 seconds
                try await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    if self.errorMessage?.contains("added successfully") == true {
                        self.errorMessage = nil
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to add parking spot: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Update an existing parking spot
    func updateParkingSpot(_ spot: ParkingSpot) {
        guard let firebaseService = firebaseService else { return }
        
        Task {
            do {
                try await firebaseService.updateParkingSpot(spot)
                
                await MainActor.run {
                    self.errorMessage = "Parking spot updated successfully!"
                }
                
                // Refresh parking spots
                await fetchParkingSpots()
                
                // Clear the message after 3 seconds
                try await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    if self.errorMessage?.contains("updated successfully") == true {
                        self.errorMessage = nil
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update parking spot: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Delete a parking spot
    func deleteParkingSpot(_ spot: ParkingSpot) {
        guard let firebaseService = firebaseService else { return }
        
        Task {
            do {
                try await firebaseService.deleteParkingSpot(spot.id)
                
                await MainActor.run {
                    self.errorMessage = "Parking spot deleted successfully!"
                }
                
                // Refresh parking spots
                await fetchParkingSpots()
                
                // Clear the message after 3 seconds
                try await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    if self.errorMessage?.contains("deleted successfully") == true {
                        self.errorMessage = nil
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to delete parking spot: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Toggle availability of a parking spot
    func toggleSpotAvailability(_ spot: ParkingSpot) {
        var updatedSpot = spot
        updatedSpot.isAvailable.toggle()
        updateParkingSpot(updatedSpot)
    }
    
    /// Get bookings for user's parking spots
    func getBookingsForUserSpots() -> [Booking] {
        return userBookings
    }
    
    /// Get pending booking requests for user's spots
    func getPendingBookingsForUserSpots() -> [Booking] {
        return pendingBookings
    }
    
    // MARK: - Data Fetching
    
    /// Fetch all parking spots
    func fetchParkingSpots() async {
        guard let firebaseService = firebaseService else { return }
        
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            let spots = try await firebaseService.fetchParkingSpots()
            await MainActor.run {
                self.parkingSpots = spots
                self.isLoading = false
                // Update user parking spots after fetching all spots
                self.updateUserParkingSpots()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch parking spots: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Fetch user's own parking spots using dedicated endpoint
    func fetchMyParkingSpots() async {
        guard let firebaseService = firebaseService else { return }
        
        do {
            let mySpots = try await firebaseService.fetchMyParkingSpots()
            await MainActor.run {
                self.userParkingSpots = mySpots
                print("✅ Updated user parking spots: \(mySpots.count) spots")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch my parking spots: \(error.localizedDescription)"
                print("❌ Error fetching my spots: \(error)")
            }
        }
    }
    
    /// Fetch user's bookings
    func fetchUserBookings() async {
        guard let firebaseService = firebaseService else { return }
        
        do {
            let bookings = try await firebaseService.fetchMyBookings()
            await MainActor.run {
                self.userBookings = bookings
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch bookings: \(error.localizedDescription)"
            }
        }
    }
    
    /// Fetch pending booking requests
    func fetchPendingBookings() async {
        guard let firebaseService = firebaseService else { return }
        
        do {
            let pendingRequests = try await firebaseService.fetchPendingRequests()
            await MainActor.run {
                self.pendingBookings = pendingRequests
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch pending requests: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Utility Methods
    
    /// Format distance for display
    func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
    /// Format price for display
    func formatPrice(_ price: Double) -> String {
        return String(format: "$%.0f/hr", price)
    }
    
    /// Calculate total price for a time period
    func calculateTotalPrice(hourlyRate: Double, startTime: Date, endTime: Date) -> Double {
        let hours = endTime.timeIntervalSince(startTime) / 3600
        return hours * hourlyRate
    }
    
    /// Format date for display
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Refresh all data (spots, bookings, etc.)
    func refreshAllData() async {
        await fetchParkingSpots()
        await fetchMyParkingSpots()
        await fetchUserBookings()
        await fetchPendingBookings()
    }
    
    /// Test method to check authentication status
    func testAuthentication() {
        print("🔍 === AUTHENTICATION TEST ===")
        print("🔍 Firebase service exists: \(firebaseService != nil)")
        print("🔍 Is authenticated: \(firebaseService?.isAuthenticated ?? false)")
        print("🔍 Current user: \(firebaseService?.currentUser?.name ?? "nil")")
        print("🔍 Firebase UID: \(firebaseService?.currentUser?.firebaseUID ?? "nil")")
        print("🔍 === END TEST ===")
    }
}
