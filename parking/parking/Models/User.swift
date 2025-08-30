import Foundation

// MARK: - User Model
/// Represents a user of the app (both finders and renters)
struct User: Identifiable, Codable {
    let id: String
    var firebaseUID: String? // Firebase Authentication UID
    var email: String
    var name: String
    var phoneNumber: String?
    var profileImageURL: String?
    var isGuest: Bool
    var createdAt: Date
    var lastLoginAt: Date?
    
    init(firebaseUID: String? = nil, email: String = "", name: String = "", phoneNumber: String? = nil, profileImageURL: String? = nil, isGuest: Bool = true) {
        self.id = UUID().uuidString
        self.firebaseUID = firebaseUID
        self.email = email
        self.name = name
        self.phoneNumber = phoneNumber
        self.profileImageURL = profileImageURL
        self.isGuest = isGuest
        self.createdAt = Date()
        self.lastLoginAt = Date()
    }
}

// MARK: - UserRole Enum
enum UserRole: String, CaseIterable, Codable {
    case finder = "finder"
    case renter = "renter"
    case both = "both"
    
    var displayName: String {
        switch self {
        case .finder:
            return "Finder"
        case .renter:
            return "Renter"
        case .both:
            return "Both"
        }
    }
}