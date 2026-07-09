import Foundation

/// A comprehensive backend-ready Profile model that encompasses both
/// AppUser core authentication data and extended HR/Employment properties.
struct UserProfile: Identifiable {
    let id: UUID
    var firstName: String
    var lastName: String
    var profileImage: String?
    
    // Employment Info
    var employeeId: String
    let role: UserRole
    var department: String
    var joiningDate: Date
    var reportingManager: String?
    
    // Contact & Location
    var phone: String
    var email: String
    var address: String
    var country: String
    var store: String
    
    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}
