import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

// MARK: - FirebaseService
/// Service class for Firebase Authentication and API calls
class FirebaseService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let baseURL = "https://parkingappbackend.vercel.app/api"//"http://localhost:8000/api" // Change to your Vercel URL in production

    
    init() {
        setupAuthStateListener()
    }
    
    // Helper function to create a JSONDecoder with custom date decoding strategy
    private func createJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        
        // Custom date decoding strategy to handle multiple date formats
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try different date formats
            let formatters: [DateFormatter] = [
                // ISO8601 format
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    return formatter
                }(),
                // ISO8601 format without microseconds
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    return formatter
                }(),
                // ISO8601 format with timezone offset
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXX"
                    return formatter
                }(),
                // ISO8601 format without microseconds and with timezone offset
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
                    return formatter
                }(),
                // Firestore timestamp format (seconds since epoch)
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    return formatter
                }()
            ]
            
            for formatter in formatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            // If all formatters fail, try parsing as timestamp
            if let timestamp = Double(dateString) {
                return Date(timeIntervalSince1970: timestamp)
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Date string does not match any expected format: \(dateString)")
        }
        
        return decoder
    }
    
    // MARK: - Authentication
    
    private func setupAuthStateListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                print("🔍 Auth state changed - User: \(user?.uid ?? "nil")")
                if let user = user {
                    self?.isAuthenticated = true
                    print("🔍 User authenticated, fetching profile...")
                    self?.fetchUserProfile(uid: user.uid)
                } else {
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                    print("🔍 User signed out")
                }
            }
        }
    }
    
    func signUp(email: String, password: String, name: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let uid = result.user.uid
            
            // Create user profile
            let userData = [
                "uid": uid,
                "email": email,
                "name": name,
                "role": "finder",
                "created_at": FieldValue.serverTimestamp(),
                "last_login_at": FieldValue.serverTimestamp()
            ] as [String : Any]
            
            try await db.collection("users").document(uid).setData(userData)
            
            // Register with backend API
            try await registerWithBackend(uid: uid, email: email, name: name)
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            let uid = result.user.uid
            
            // Update last login time
            try await db.collection("users").document(uid).updateData([
                "last_login_at": FieldValue.serverTimestamp()
            ])
            
            // Login with backend API
            try await loginWithBackend(uid: uid)
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signOut() async throws {
        do {
            try auth.signOut()
            try await logoutWithBackend()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    private func fetchUserProfile(uid: String) {
        print("🔍 Fetching user profile for UID: \(uid)")
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error fetching user profile: \(error)")
                    return
                }
                
                if let document = document, document.exists {
                    let data = document.data() ?? [:]
                    print("✅ User profile data: \(data)")
                    self?.currentUser = User(
                        firebaseUID: data["uid"] as? String,
                        email: data["email"] as? String ?? "",
                        name: data["name"] as? String ?? "",
                        phoneNumber: data["phone_number"] as? String,
                        profileImageURL: data["profile_image_url"] as? String,
                        isGuest: false
                    )
                    print("✅ Current user set: \(self?.currentUser?.name ?? "nil")")
                } else {
                    print("❌ User document not found")
                }
            }
        }
    }
    
    // MARK: - Backend API Calls
    
    private func getAuthHeaders() async -> [String: String] {
        print("🔍 Getting auth headers...")
        print("🔍 Current user: \(auth.currentUser?.uid ?? "nil")")
        print("🔍 Is authenticated: \(auth.currentUser != nil)")
        
        guard let user = auth.currentUser else { 
            print("❌ No current user")
            return [:]
        }
        
        do {
            let token = try await user.getIDToken()
            print("✅ Got ID token: \(String(token.prefix(20)))...")
            return [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(token)"
            ]
        } catch {
            print("❌ Error getting ID token: \(error)")
            return [:]
        }
    }
    
    private func convertVehicleSizeToBackend(_ vehicleSize: VehicleSize) -> String {
        return vehicleSize.rawValue
    }
    
    private func registerWithBackend(uid: String, email: String, name: String) async throws {
        let url = URL(string: "\(baseURL)/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "firebase_uid": uid,
            "email": email,
            "name": name,
            "role": "finder"
        ] as [String : Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.registrationFailed
        }
    }
    
    private func loginWithBackend(uid: String) async throws {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["firebase_uid": uid]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.loginFailed
        }
    }
    
    private func logoutWithBackend() async throws {
        let url = URL(string: "\(baseURL)/auth/logout")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = await getAuthHeaders()
        
        let (_, _) = try await URLSession.shared.data(for: request)
    }
    
    /// Test method to check authentication and token
    func testAuthAndToken() async {
        print("🔍 === FIREBASE AUTH TEST ===")
        print("🔍 Current user: \(auth.currentUser?.uid ?? "nil")")
        print("🔍 Is authenticated: \(isAuthenticated)")
        print("🔍 Current user object: \(currentUser?.name ?? "nil")")
        
        if let user = auth.currentUser {
            do {
                let token = try await user.getIDToken()
                print("✅ Got valid token: \(String(token.prefix(20)))...")
                
                let headers = await getAuthHeaders()
                print("✅ Auth headers: \(headers)")
            } catch {
                print("❌ Failed to get token: \(error)")
            }
        } else {
            print("❌ No current user")
        }
        print("🔍 === END FIREBASE TEST ===")
    }
    
    // MARK: - Parking Spots API
    
    func fetchParkingSpots() async throws -> [ParkingSpot] {
        let url = URL(string: "\(baseURL)/parking-spots/")!
        var request = URLRequest(url: url)
        let headers = await getAuthHeaders()
        request.allHTTPHeaderFields = headers
        
        print("🔍 Fetching parking spots...")
        print("🔍 Headers: \(headers)")
        print("🔍 Current user: \(auth.currentUser?.uid ?? "nil")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw APIError.fetchFailed
        }
        
        print("🔍 Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP error: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Response body: \(responseString)")
            }
            throw APIError.fetchFailed
        }
        

        
        let decoder = createJSONDecoder()
        

        
        // Decode the response with the correct structure
        do {
            let apiResponse = try decoder.decode(APIResponse<ParkingSpotsResponse>.self, from: data)
            print("✅ Fetched \(apiResponse.data.spots.count) parking spots")
            return apiResponse.data.spots
        } catch {
            print("❌ Decoding error: \(error)")
            print("❌ Decoding error details: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchNearbyParkingSpots(latitude: Double, longitude: Double, radius: Double = 5000) async throws -> [ParkingSpot] {
        let url = URL(string: "\(baseURL)/parking-spots/nearby?latitude=\(latitude)&longitude=\(longitude)&radius=\(radius)")!
        var request = URLRequest(url: url)
        let headers = await getAuthHeaders()
        request.allHTTPHeaderFields = headers
        
        print("🔍 Fetching nearby parking spots...")
        print("🔍 Location: \(latitude), \(longitude), radius: \(radius)")
        print("🔍 Headers: \(headers)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response for nearby spots")
            throw APIError.fetchFailed
        }
        
        print("🔍 Nearby response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP error for nearby spots: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Nearby response body: \(responseString)")
            }
            throw APIError.fetchFailed
        }
        
        let decoder = createJSONDecoder()
        

        
        // Decode the response with the correct structure
        do {
            let apiResponse = try decoder.decode(APIResponse<NearbySpotsResponse>.self, from: data)
            print("✅ Fetched \(apiResponse.data.spots.count) nearby parking spots")
            return apiResponse.data.spots
        } catch {
            print("❌ Decoding error for nearby spots: \(error)")
            print("❌ Decoding error details: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchMyParkingSpots() async throws -> [ParkingSpot] {
        let url = URL(string: "\(baseURL)/parking-spots/my-spots")!
        var request = URLRequest(url: url)
        let headers = await getAuthHeaders()
        request.allHTTPHeaderFields = headers
        
        print("🔍 Fetching my parking spots...")
        print("🔍 Headers: \(headers)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response for my spots")
            throw APIError.fetchFailed
        }
        
        print("🔍 My spots response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP error for my spots: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ My spots response body: \(responseString)")
            }
            throw APIError.fetchFailed
        }
        
        let decoder = createJSONDecoder()
        

        
        // Decode the response with the correct structure
        do {
            let apiResponse = try decoder.decode(APIResponse<NearbySpotsResponse>.self, from: data)
            print("✅ Fetched \(apiResponse.data.spots.count) my parking spots")
            return apiResponse.data.spots
        } catch {
            print("❌ Decoding error for my spots: \(error)")
            print("❌ Decoding error details: \(error.localizedDescription)")
            throw error
        }
    }
    
    func createParkingSpot(_ spot: ParkingSpot) async throws -> String {
        let url = URL(string: "\(baseURL)/parking-spots/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = await getAuthHeaders()
        
        let spotData = [
            "address": spot.address,
            "latitude": spot.latitude,
            "longitude": spot.longitude,
            "hourly_rate": spot.hourlyRate,
            "is_available": spot.isAvailable,
            "availability_start": ISO8601DateFormatter().string(from: spot.availabilityStart),
            "availability_end": ISO8601DateFormatter().string(from: spot.availabilityEnd),
            "max_vehicle_size": convertVehicleSizeToBackend(spot.maxVehicleSize),
            "description": spot.description,
            "image_url": spot.imageURL,
            "owner_id": spot.ownerID,
            "owner_name": spot.ownerName
        ] as [String : Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: spotData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.createFailed
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<[String: String]>.self, from: data)
        return apiResponse.data["spot_id"] ?? ""
    }
    
    func updateParkingSpot(_ spot: ParkingSpot) async throws {
        let url = URL(string: "\(baseURL)/parking-spots/\(spot.id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = await getAuthHeaders()
        
        let spotData = [
            "address": spot.address,
            "latitude": spot.latitude,
            "longitude": spot.longitude,
            "hourly_rate": spot.hourlyRate,
            "is_available": spot.isAvailable,
            "availability_start": ISO8601DateFormatter().string(from: spot.availabilityStart),
            "availability_end": ISO8601DateFormatter().string(from: spot.availabilityEnd),
            "max_vehicle_size": convertVehicleSizeToBackend(spot.maxVehicleSize),
            "description": spot.description,
            "image_url": spot.imageURL
        ] as [String : Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: spotData)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.updateFailed
        }
    }
    
    func deleteParkingSpot(_ spotId: String) async throws {
        let url = URL(string: "\(baseURL)/parking-spots/\(spotId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = await getAuthHeaders()
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.deleteFailed
        }
    }
    
    // MARK: - Bookings API
    
    func createBookingRequest(spot: ParkingSpot, startTime: Date, endTime: Date, message: String?) async throws -> String {
        let url = URL(string: "\(baseURL)/bookings/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = await getAuthHeaders()
        
        let bookingData = [
            "spot_id": spot.id,
            "finder_id": currentUser?.firebaseUID ?? "",
            "finder_name": currentUser?.name ?? "",
            "finder_email": currentUser?.email ?? "",
            "start_time": ISO8601DateFormatter().string(from: startTime),
            "end_time": ISO8601DateFormatter().string(from: endTime),
            "message": message
        ] as [String : Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: bookingData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.createFailed
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<[String: String]>.self, from: data)
        return apiResponse.data["booking_id"] ?? ""
    }
    
    func fetchMyBookings() async throws -> [Booking] {
        let url = URL(string: "\(baseURL)/bookings/my-bookings")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = await getAuthHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.fetchFailed
        }
        
        let decoder = createJSONDecoder()
        
        let apiResponse = try decoder.decode(APIResponse<BookingsResponse>.self, from: data)
        return apiResponse.data.bookings
    }
    
    func fetchPendingRequests() async throws -> [Booking] {
        let url = URL(string: "\(baseURL)/bookings/pending-requests")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = await getAuthHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.fetchFailed
        }
        
        let decoder = createJSONDecoder()
        
        let apiResponse = try decoder.decode(APIResponse<PendingRequestsResponse>.self, from: data)
        return apiResponse.data.requests
    }
    
    func approveBookingRequest(bookingId: String, responseMessage: String?) async throws {
        let url = URL(string: "\(baseURL)/bookings/\(bookingId)/approve")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = await getAuthHeaders()
        
        if let message = responseMessage {
            let body = ["response_message": message]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.updateFailed
        }
    }
    
    func rejectBookingRequest(bookingId: String, responseMessage: String?) async throws {
        let url = URL(string: "\(baseURL)/bookings/\(bookingId)/reject")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = await getAuthHeaders()
        
        if let message = responseMessage {
            let body = ["response_message": message]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.updateFailed
        }
    }
    
    func cancelBookingRequest(bookingId: String) async throws {
        let url = URL(string: "\(baseURL)/bookings/\(bookingId)/cancel")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = await getAuthHeaders()
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.updateFailed
        }
    }
}

// MARK: - API Response Models

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String
    let data: T
}

// Specific response models for different endpoints
struct ParkingSpotsResponse: Codable {
    let spots: [ParkingSpot]
    let pagination: PaginationInfo?
}

struct NearbySpotsResponse: Codable {
    let spots: [ParkingSpot]
}

struct BookingsResponse: Codable {
    let bookings: [Booking]
}

struct PendingRequestsResponse: Codable {
    let requests: [Booking]
}

struct PaginationInfo: Codable {
    let total: Int
    let page: Int
    let size: Int
    let pages: Int
}

// MARK: - API Errors

enum APIError: Error, LocalizedError {
    case registrationFailed
    case loginFailed
    case fetchFailed
    case createFailed
    case updateFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .registrationFailed:
            return "Failed to register user"
        case .loginFailed:
            return "Failed to login"
        case .fetchFailed:
            return "Failed to fetch data"
        case .createFailed:
            return "Failed to create item"
        case .updateFailed:
            return "Failed to update item"
        case .deleteFailed:
            return "Failed to delete item"
        }
    }
}
