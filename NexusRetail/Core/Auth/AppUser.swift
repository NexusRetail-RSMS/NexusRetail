//
//  AppUser.swift
//  NexusRetail
//

import Foundation

/// Codable struct matching the app_user row in Supabase.
/// Maps snake_case database columns to camelCase Swift properties.
struct AppUser: Codable, Identifiable {
    /// The UUID matching the auth.users table in Supabase.
    let id: UUID
    let name: String?
    let email: String?
    let role: UserRole
    let storeID: UUID?
    let isActive: Bool?
    let phone: String?
    let address: String?
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case role
        case storeID = "store_id"
        case isActive = "is_active"
        case phone
        case address
        case imageUrl = "image_url"
    }
}
