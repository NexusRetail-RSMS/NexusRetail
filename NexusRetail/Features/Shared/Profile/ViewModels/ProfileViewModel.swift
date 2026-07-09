import Foundation
import SwiftUI
import Supabase

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
        var addressStr = "123 Retail Ave"
        var countryStr = "United States"
        var storeNameStr = "Nexus Flagship Store"
        
        // Fetch real store address if available
        if let storeId = appUser?.storeID {
            struct StoreRow: Decodable {
                let name: String
                let address: String?
                let country: String?
            }
            if let store: StoreRow = try? await SupabaseManager.shared.client
                .from("store")
                .select("name, address, country")
                .eq("id", value: storeId)
                .single()
                .execute()
                .value {
                storeNameStr = store.name
                if let addr = store.address, !addr.isEmpty { addressStr = addr }
                if let c = store.country, !c.isEmpty { countryStr = c }
            }
        } else {
            // Fallback parsing from appUser if no store assigned
            let rawAddress = appUser?.address ?? ""
            let parts = rawAddress.components(separatedBy: ",")
            if !parts.isEmpty && !rawAddress.isEmpty {
                countryStr = parts.last?.trimmingCharacters(in: .whitespaces) ?? "United States"
                let remaining = parts.dropLast().joined(separator: ",").trimmingCharacters(in: .whitespaces)
                addressStr = remaining.isEmpty ? "123 Retail Ave" : remaining
            }
        }
        
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
            address: addressStr,
            country: countryStr,
            store: storeNameStr
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
