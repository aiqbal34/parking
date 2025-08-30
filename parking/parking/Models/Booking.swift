import Foundation

// MARK: - Booking Model
/// Represents a booking request made by a finder for a parking spot
struct Booking: Identifiable, Codable {
    let id: String
    var spotID: String
    var finderID: String
    var finderName: String
    var finderEmail: String
    var startTime: Date
    var endTime: Date
    var totalAmount: Double
    var status: BookingStatus
    var createdAt: Date
    var message: String? // Optional message from finder to owner
    var ownerResponse: String? // Optional response from owner
    var respondedAt: Date? // When the owner responded
    
    init(spotID: String, finderID: String, finderName: String, finderEmail: String, startTime: Date, endTime: Date, totalAmount: Double, message: String? = nil) {
        self.id = UUID().uuidString
        self.spotID = spotID
        self.finderID = finderID
        self.finderName = finderName
        self.finderEmail = finderEmail
        self.startTime = startTime
        self.endTime = endTime
        self.totalAmount = totalAmount
        self.status = .pending
        self.createdAt = Date()
        self.message = message
        self.ownerResponse = nil
        self.respondedAt = nil
    }
    
    // CodingKeys to map backend field names to iOS property names
    enum CodingKeys: String, CodingKey {
        case id
        case spotID = "spot_id"
        case finderID = "finder_id"
        case finderName = "finder_name"
        case finderEmail = "finder_email"
        case startTime = "start_time"
        case endTime = "end_time"
        case totalAmount = "total_amount"
        case status
        case createdAt = "created_at"
        case message
        case ownerResponse = "owner_response"
        case respondedAt = "responded_at"
    }
}

// MARK: - BookingStatus Enum
enum BookingStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case confirmed = "confirmed"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .approved:
            return "Approved"
        case .rejected:
            return "Rejected"
        case .confirmed:
            return "Confirmed"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }
    
    var color: String {
        switch self {
        case .pending:
            return "orange"
        case .approved:
            return "blue"
        case .rejected:
            return "red"
        case .confirmed:
            return "green"
        case .completed:
            return "gray"
        case .cancelled:
            return "red"
        }
    }
}