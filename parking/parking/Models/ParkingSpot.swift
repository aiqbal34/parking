import Foundation
import CoreLocation

// MARK: - ParkingSpot Model
/// Represents a parking spot that can be rented out
struct ParkingSpot: Identifiable, Codable {
    let id: String
    var address: String
    var latitude: Double
    var longitude: Double
    var hourlyRate: Double
    var isAvailable: Bool
    var availabilityStart: Date
    var availabilityEnd: Date
    var maxVehicleSize: VehicleSize
    var description: String
    var imageURL: String?
    var ownerID: String
    var ownerName: String
    var createdAt: Date?
    var updatedAt: Date?
    
    // Computed property for CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // Distance calculation helper
    func distance(from location: CLLocation) -> Double {
        let spotLocation = CLLocation(latitude: latitude, longitude: longitude)
        return location.distance(from: spotLocation)
    }
    
    // Custom initializer for creating new spots
    init(address: String, latitude: Double, longitude: Double, hourlyRate: Double, isAvailable: Bool, availabilityStart: Date, availabilityEnd: Date, maxVehicleSize: VehicleSize, description: String, imageURL: String?, ownerID: String, ownerName: String) {
        self.id = UUID().uuidString
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.hourlyRate = hourlyRate
        self.isAvailable = isAvailable
        self.availabilityStart = availabilityStart
        self.availabilityEnd = availabilityEnd
        self.maxVehicleSize = maxVehicleSize
        self.description = description
        self.imageURL = imageURL
        self.ownerID = ownerID
        self.ownerName = ownerName
        self.createdAt = nil
        self.updatedAt = nil
    }
    
    // CodingKeys to map backend field names to iOS property names
    enum CodingKeys: String, CodingKey {
        case id
        case address
        case latitude
        case longitude
        case hourlyRate = "hourly_rate"
        case isAvailable = "is_available"
        case availabilityStart = "availability_start"
        case availabilityEnd = "availability_end"
        case maxVehicleSize = "max_vehicle_size"
        case description
        case imageURL = "image_url"
        case ownerID = "owner_id"
        case ownerName = "owner_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - VehicleSize Enum
enum VehicleSize: String, CaseIterable, Codable {
    case compact = "compact"
    case midsize = "midsize"
    case large = "large"
    case suv = "suv"
    case any = "any"
    
    var displayName: String {
        switch self {
        case .compact:
            return "Compact"
        case .midsize:
            return "Mid-size"
        case .large:
            return "Large"
        case .suv:
            return "SUV/Truck"
        case .any:
            return "Any Size"
        }
    }
}