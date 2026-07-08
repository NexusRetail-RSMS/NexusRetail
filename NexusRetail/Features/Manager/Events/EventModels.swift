import Foundation

// MARK: - Supabase Event Models

struct SupabaseEvent: Codable, Identifiable, Hashable {
    let id: UUID
    let storeID: UUID?
    let name: String
    let description: String?
    let scheduledAt: Date
    let venue: String?
    let launchSkuID: UUID?
    
    let eventType: String?
    let endTime: Date?
    let maxGuests: Int?
    let bannerImageURL: String?
    
    // Nested junction table data
    var eventGuests: [EventGuest]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case storeID = "store_id"
        case name
        case description
        case scheduledAt = "scheduled_at"
        case venue
        case launchSkuID = "launch_sku_id"
        case eventType = "event_type"
        case endTime = "end_time"
        case maxGuests = "max_guests"
        case bannerImageURL = "banner_image_url"
        case eventGuests = "event_guest"
    }
    
    // UI Computed Properties (replacing MockEvent)
    var title: String { name }
    var eventDate: Date { scheduledAt }
    var startTime: Date { scheduledAt }
    var maximumGuests: Int { maxGuests ?? 0 }
    var venueStr: String { venue ?? "TBA" }
    
    var status: EventStatus {
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let eventDay = calendar.startOfDay(for: scheduledAt)
        
        if eventDay == today {
            return .today
        } else if eventDay < today {
            return .completed
        } else {
            return .upcoming
        }
    }
    
    var invitedCount: Int { eventGuests?.count ?? 0 }
}

struct EventGuest: Codable, Identifiable, Hashable {
    let id: UUID
    let eventID: UUID?
    let clientID: UUID?
    let status: String?
    let createdAt: Date?
    
    // Nested relation to client
    var client: SupabaseClientModel?
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventID = "event_id"
        case clientID = "client_id"
        case status
        case createdAt = "created_at"
        case client
    }
}

struct SupabaseClientModel: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String?
    let phone: String?
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case phone
        case email
    }
    
    var avatarName: String {
        guard let name = name, !name.isEmpty else { return "U" }
        return String(name.prefix(1)).uppercased()
    }
}
