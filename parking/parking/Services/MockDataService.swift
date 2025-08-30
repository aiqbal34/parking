import Foundation
import Combine
import CoreLocation

// MARK: - MockDataService
/// Provides mock data for testing the app without Firebase
class MockDataService: ObservableObject {
    @Published var parkingSpots: [ParkingSpot] = []
    @Published var userBookings: [Booking] = []
    @Published var currentUser: User = User(name: "Guest User")
    
    init() {
        loadMockData()
    }
    
    /// Load mock parking spots and bookings
    private func loadMockData() {
        // Mock parking spots around common stadium/event areas
        parkingSpots = [
            ParkingSpot(
                address: "123 Stadium Way, San Francisco, CA 94107",
                latitude: 37.7749,
                longitude: -122.4194,
                hourlyRate: 15.0,
                isAvailable: true,
                availabilityStart: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date(),
                availabilityEnd: Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date(),
                maxVehicleSize: .any,
                description: "Secure driveway spot, 2 minutes walk to stadium entrance",
                imageURL: nil,
                ownerID: "owner1",
                ownerName: "John Smith"
            ),
            ParkingSpot(
                address: "456 Event Center Dr, San Francisco, CA 94107",
                latitude: 37.7849,
                longitude: -122.4094,
                hourlyRate: 12.0,
                isAvailable: true,
                availabilityStart: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                availabilityEnd: Calendar.current.date(byAdding: .hour, value: 8, to: Date()) ?? Date(),
                maxVehicleSize: .midsize,
                description: "Covered parking, easy access to main road",
                imageURL: nil,
                ownerID: "owner2",
                ownerName: "Sarah Johnson"
            ),
            ParkingSpot(
                address: "789 Arena Blvd, San Francisco, CA 94107",
                latitude: 37.7649,
                longitude: -122.4294,
                hourlyRate: 20.0,
                isAvailable: false,
                availabilityStart: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date(),
                availabilityEnd: Calendar.current.date(byAdding: .hour, value: 10, to: Date()) ?? Date(),
                maxVehicleSize: .large,
                description: "Premium spot with security camera, very close to venue",
                imageURL: nil,
                ownerID: "owner3",
                ownerName: "Mike Wilson"
            ),
            ParkingSpot(
                address: "321 Concert Hall St, San Francisco, CA 94107",
                latitude: 37.7549,
                longitude: -122.4394,
                hourlyRate: 8.0,
                isAvailable: true,
                availabilityStart: Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date(),
                availabilityEnd: Calendar.current.date(byAdding: .hour, value: 5, to: Date()) ?? Date(),
                maxVehicleSize: .compact,
                description: "Budget-friendly option, 5 minute walk",
                imageURL: nil,
                ownerID: "owner4",
                ownerName: "Lisa Davis"
            ),
            ParkingSpot(
                address: "654 Sports Complex Ave, San Francisco, CA 94107",
                latitude: 37.7449,
                longitude: -122.4494,
                hourlyRate: 18.0,
                isAvailable: true,
                availabilityStart: Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date(),
                availabilityEnd: Calendar.current.date(byAdding: .hour, value: 12, to: Date()) ?? Date(),
                maxVehicleSize: .suv,
                description: "Large spot perfect for SUVs and trucks",
                imageURL: nil,
                ownerID: "owner5",
                ownerName: "David Brown"
            )
        ]
        
        // Mock bookings for the current user
        userBookings = [
            Booking(
                spotID: parkingSpots[0].id,
                finderID: currentUser.id,
                finderName: currentUser.name,
                finderEmail: currentUser.email,
                startTime: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                endTime: Calendar.current.date(byAdding: .day, value: -2, to: Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date()) ?? Date(),
                totalAmount: 45.0,
                message: "Need parking for the game tonight"
            ),
            Booking(
                spotID: parkingSpots[1].id,
                finderID: currentUser.id,
                finderName: currentUser.name,
                finderEmail: currentUser.email,
                startTime: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                endTime: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()) ?? Date(),
                totalAmount: 48.0,
                message: "Attending a concert, will be respectful of your property"
            )
        ]
    }
    
    // MARK: - Parking Spot Operations
    
    /// Get all available parking spots
    func getAvailableParkingSpots() -> [ParkingSpot] {
        return parkingSpots.filter { $0.isAvailable }
    }
    
    /// Get parking spots near a location
    func getParkingSpotsNear(location: CLLocation, radius: Double = 5000) -> [ParkingSpot] {
        return parkingSpots.filter { spot in
            let spotLocation = CLLocation(latitude: spot.latitude, longitude: spot.longitude)
            return location.distance(from: spotLocation) <= radius
        }.sorted { spot1, spot2 in
            spot1.distance(from: location) < spot2.distance(from: location)
        }
    }
    
    /// Add a new parking spot
    func addParkingSpot(_ spot: ParkingSpot) {
        parkingSpots.append(spot)
    }
    
    /// Update an existing parking spot
    func updateParkingSpot(_ updatedSpot: ParkingSpot) {
        if let index = parkingSpots.firstIndex(where: { $0.id == updatedSpot.id }) {
            parkingSpots[index] = updatedSpot
        }
    }
    
    /// Delete a parking spot
    func deleteParkingSpot(withId id: String) {
        parkingSpots.removeAll { $0.id == id }
    }
    
    /// Get parking spots owned by current user
    func getUserParkingSpots() -> [ParkingSpot] {
        return parkingSpots.filter { $0.ownerID == currentUser.id }
    }
    
    // MARK: - Booking Request Operations
    
    /// Send a booking request for a parking spot
    func sendBookingRequest(spot: ParkingSpot, startTime: Date, endTime: Date, message: String? = nil) -> Booking {
        let hours = endTime.timeIntervalSince(startTime) / 3600
        let totalAmount = hours * spot.hourlyRate
        
        let booking = Booking(
            spotID: spot.id,
            finderID: currentUser.id,
            finderName: currentUser.name,
            finderEmail: currentUser.email,
            startTime: startTime,
            endTime: endTime,
            totalAmount: totalAmount,
            message: message
        )
        
        userBookings.append(booking)
        return booking
    }
    
    /// Cancel a booking request
    func cancelBookingRequest(_ booking: Booking) {
        if let index = userBookings.firstIndex(where: { $0.id == booking.id }) {
            userBookings[index].status = .cancelled
        }
    }
    
    /// Approve a booking request (for spot owners)
    func approveBookingRequest(_ booking: Booking, response: String? = nil) {
        if let index = userBookings.firstIndex(where: { $0.id == booking.id }) {
            userBookings[index].status = .approved
            userBookings[index].ownerResponse = response
            userBookings[index].respondedAt = Date()
        }
    }
    
    /// Reject a booking request (for spot owners)
    func rejectBookingRequest(_ booking: Booking, response: String? = nil) {
        if let index = userBookings.firstIndex(where: { $0.id == booking.id }) {
            userBookings[index].status = .rejected
            userBookings[index].ownerResponse = response
            userBookings[index].respondedAt = Date()
        }
    }
    
    /// Get bookings for current user
    func getUserBookings() -> [Booking] {
        return userBookings.sorted { $0.createdAt > $1.createdAt }
    }
    
    /// Get bookings for a specific parking spot (for owners)
    func getBookingsForSpot(spotId: String) -> [Booking] {
        return userBookings.filter { $0.spotID == spotId }
    }
    
    /// Get pending booking requests for current user's spots
    func getPendingBookingsForUserSpots() -> [Booking] {
        let userSpots = getUserParkingSpots()
        return userBookings.filter { booking in
            userSpots.contains { $0.id == booking.spotID } && booking.status == .pending
        }
    }
    
    // MARK: - Mock Bookings for Renter View
    
    /// Generate mock bookings for spots owned by current user
    func getMockBookingsForUserSpots() -> [Booking] {
        let userSpots = getUserParkingSpots()
        var mockBookings: [Booking] = []
        
        for spot in userSpots {
            // Generate 1-3 random bookings per spot
            let bookingCount = Int.random(in: 1...3)
            
            for i in 0..<bookingCount {
                let randomDaysAgo = Int.random(in: 1...7)
                let startTime = Calendar.current.date(byAdding: .day, value: -randomDaysAgo, to: Date()) ?? Date()
                let duration = Double.random(in: 2...6) // 2-6 hours
                let endTime = startTime.addingTimeInterval(duration * 3600)
                
                let mockNames = ["Alex Thompson", "Emma Rodriguez", "James Lee", "Sophia Chen", "Michael Davis"]
                let mockEmails = ["alex@example.com", "emma@example.com", "james@example.com", "sophia@example.com", "michael@example.com"]
                let randomName = mockNames.randomElement() ?? "Anonymous User"
                let randomEmail = mockEmails.randomElement() ?? "user@example.com"
                
                // Random status for variety
                let statuses: [BookingStatus] = [.pending, .approved, .rejected, .confirmed, .completed]
                let randomStatus = statuses.randomElement() ?? .pending
                
                let booking = Booking(
                    spotID: spot.id,
                    finderID: "mock_user_\(i)",
                    finderName: randomName,
                    finderEmail: randomEmail,
                    startTime: startTime,
                    endTime: endTime,
                    totalAmount: duration * spot.hourlyRate,
                    message: "Need parking for an event"
                )
                
                // Set the status after creation
                var updatedBooking = booking
                updatedBooking.status = randomStatus
                
                mockBookings.append(updatedBooking)
            }
        }
        
        return mockBookings.sorted { $0.startTime > $1.startTime }
    }
}
