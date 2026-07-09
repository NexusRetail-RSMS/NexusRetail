import Foundation
import SwiftUI

@Observable
class ProfileViewModel {
    var profile: UserProfile?
    var isLoading = false
    var errorMessage: String?
    
    init() {}
    
    @MainActor
    func fetchProfile(from appUser: AppUser?) async {
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        let role = appUser?.role ?? .manager
        let rawAddress = appUser?.address ?? ""
        let parts = rawAddress.components(separatedBy: ",")
        let country = parts.last?.trimmingCharacters(in: .whitespaces) ?? "United States"
        let addressStr = parts.dropLast().joined(separator: ",").trimmingCharacters(in: .whitespaces)
        
        let nameParts = (appUser?.name ?? "Admin User").components(separatedBy: .whitespaces)
        let firstName = nameParts.first ?? ""
        let lastName = nameParts.dropFirst().joined(separator: " ")
        
        self.profile = UserProfile(
            id: appUser?.id ?? UUID(),
            firstName: firstName,
            lastName: lastName,
            profileImage: appUser?.imageUrl,
            employeeId: "NX-\(Int.random(in: 1000...9999))",
            role: role,
            department: role == .admin ? "Management" : "Retail Operations",
            joiningDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date(),
            reportingManager: role == .admin ? "Board of Directors" : "Regional Director",
            phone: appUser?.phone ?? "+1 (555) 012-3456",
            email: appUser?.email ?? "employee@nexusretail.com",
            address: addressStr.isEmpty ? "123 Retail Ave" : addressStr,
            country: country,
            store: "Nexus Flagship Store"
        )
        
        isLoading = false
    }
    
    @MainActor
    func updateProfile(firstName: String, lastName: String, phone: String, email: String, address: String, country: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard var currentProfile = profile else { return }
        currentProfile.firstName = firstName
        currentProfile.lastName = lastName
        currentProfile.phone = phone
        currentProfile.email = email
        currentProfile.address = address
        currentProfile.country = country
        
        self.profile = currentProfile
    }
    
    @MainActor
    func changeEmail(newEmail: String) async throws {
        isLoading = true
        defer { isLoading = false }
        try await Task.sleep(nanoseconds: 1_000_000_000)
        profile?.email = newEmail
    }
    
    @MainActor
    func changePhone(newPhone: String) async throws {
        isLoading = true
        defer { isLoading = false }
        try await Task.sleep(nanoseconds: 1_000_000_000)
        profile?.phone = newPhone
    }
    
    @MainActor
    func changePassword(current: String, new: String) async throws {
        isLoading = true
        defer { isLoading = false }
        try await Task.sleep(nanoseconds: 1_500_000_000)
        // Mock successful password change
    }
    
    @MainActor
    func uploadProfileImage(_ data: Data) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        try await Task.sleep(nanoseconds: 1_500_000_000)
        // Mock image URL return
        let mockUrl = "https://example.com/mock_image.jpg"
        profile?.profileImage = mockUrl
        return mockUrl
    }
}
