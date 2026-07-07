import SwiftUI
import Supabase

// MARK: - Enums

enum EventType: String, CaseIterable, Codable {
    case productLaunch = "Product Launch"
    case promotion = "Promotion"
    case seasonalSale = "Seasonal Sale"
    case vipEvent = "VIP Event"
    case workshop = "Workshop"
    case storeAnniversary = "Store Anniversary"
    case custom = "Custom"
}

enum EventStatus: String, Codable {
    case upcoming = "Upcoming"
    case today = "Today"
    case completed = "Completed"
}

enum EventFilter: String, CaseIterable {
    case all = "All Events"
    case today = "Today"
    case upcoming = "Upcoming"
    case completed = "Completed"
}

@Observable
class EventsViewModel {
    var events: [SupabaseEvent] = []
    var storeCustomers: [SupabaseClientModel] = []
    
    // Using shared supabase client
    private var supabase: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    init() {
        // Initialization can be empty as we fetch async
    }
    
    // MARK: - Fetch Events
    
    @MainActor
    func fetchEvents(for storeID: UUID?) async {
        guard let storeID = storeID else { return }
        
        do {
            let fetchedEvents: [SupabaseEvent] = try await supabase
                .from("event")
                .select("*, event_guest(*, client(*))")
                .eq("store_id", value: storeID.uuidString)
                .order("scheduled_at", ascending: true)
                .execute()
                .value
                
            self.events = fetchedEvents
        } catch {
            print("Failed to fetch events: \(error)")
        }
    }
    
    // MARK: - Image Upload (resilient)

    /// Uploads a banner image, retrying on transient network drops (e.g. NSURLError -1005
    /// which the simulator throws intermittently). Uses the proven public `product-images`
    /// bucket. Returns the public URL, or nil if all attempts fail.
    private func uploadBanner(_ data: Data, attempts: Int = 3) async -> String? {
        for attempt in 1...attempts {
            do {
                return try await ImageUploader.uploadDirect(data: data, bucket: "product-images", folder: "events")
            } catch {
                print("Banner upload attempt \(attempt)/\(attempts) failed: \(error)")
                if attempt < attempts {
                    // brief backoff before retrying
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
            }
        }
        return nil
    }

    // MARK: - Event Actions

    /// Returns true on success so the UI can keep a spinner up until the work completes.
    @MainActor
    @discardableResult
    func createEvent(storeID: UUID, title: String, description: String, eventType: EventType, venue: String, eventDate: Date, startTime: Date, endTime: Date, maximumGuests: Int, bannerImageData: Data?) async -> Bool {
        // Start time is effectively the scheduledAt, we can combine eventDate and startTime
        // or just use startTime as scheduledAt
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: eventDate)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: startTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.second = timeComponents.second
        
        let scheduledAt = calendar.date(from: components) ?? startTime
        
        // Similar for endTime
        var endComponents = components
        let endTimeComponents = calendar.dateComponents([.hour, .minute, .second], from: endTime)
        endComponents.hour = endTimeComponents.hour
        endComponents.minute = endTimeComponents.minute
        endComponents.second = endTimeComponents.second
        let finalEndTime = calendar.date(from: endComponents) ?? endTime
        
        // Upload the banner image (if the manager picked one) and capture its public URL.
        var bannerURL: String? = nil
        if let bannerImageData {
            bannerURL = await uploadBanner(bannerImageData)
        }

        struct EventInsert: Codable {
            let store_id: UUID
            let name: String
            let description: String
            let event_type: String
            let venue: String
            let scheduled_at: Date
            let end_time: Date
            let max_guests: Int
            let banner_image_url: String?
        }
        
        let newEvent = EventInsert(
            store_id: storeID,
            name: title,
            description: description,
            event_type: eventType.rawValue,
            venue: venue,
            scheduled_at: scheduledAt,
            end_time: finalEndTime,
            max_guests: maximumGuests,
            banner_image_url: bannerURL
        )
        
        do {
            try await supabase
                .from("event")
                .insert(newEvent)
                .execute()
                
            // Refresh events list
            await fetchEvents(for: storeID)
            return true
        } catch {
            print("Failed to create event: \(error)")
            return false
        }
    }
    
    @MainActor
    @discardableResult
    func updateEvent(_ event: SupabaseEvent, newBannerData: Data? = nil) async -> Bool {
        // NOTE: we must NOT send the whole `SupabaseEvent` to `.update()` because it
        // carries the nested `event_guest` relation (and other read-only keys). PostgREST
        // rejects those since they are not columns on `event` (error PGRST204). Send only
        // the real, updatable columns via a dedicated payload struct.

        // If the manager picked a new banner, upload it; otherwise keep the existing URL.
        var bannerURL = event.bannerImageURL
        if let newBannerData {
            bannerURL = await uploadBanner(newBannerData) ?? event.bannerImageURL
        }

        struct EventUpdate: Encodable {
            let name: String
            let description: String?
            let event_type: String?
            let venue: String?
            let scheduled_at: Date
            let end_time: Date?
            let max_guests: Int?
            let banner_image_url: String?
        }

        let payload = EventUpdate(
            name: event.name,
            description: event.description,
            event_type: event.eventType,
            venue: event.venue,
            scheduled_at: event.scheduledAt,
            end_time: event.endTime,
            max_guests: event.maxGuests,
            banner_image_url: bannerURL
        )

        do {
            try await supabase
                .from("event")
                .update(payload)
                .eq("id", value: event.id.uuidString)
                .execute()

            if let storeID = event.storeID {
                await fetchEvents(for: storeID)
            }
            return true
        } catch {
            print("Failed to update event: \(error)")
            return false
        }
    }
    
    @MainActor
    func deleteEvent(id: UUID, storeID: UUID?) async {
        do {
            try await supabase
                .from("event")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
                
            if let storeID = storeID {
                await fetchEvents(for: storeID)
            }
        } catch {
            print("Failed to delete event: \(error)")
        }
    }
    
    // MARK: - Backend Ready Fetch
    
    @MainActor
    func fetchCustomers(for storeID: UUID?) async {
        // In reality, this might fetch clients from the 'client' table.
        // We'll fetch a limited set of clients for now.
        do {
            let fetchedCustomers: [SupabaseClientModel] = try await supabase
                .from("client")
                .select()
                .limit(50)
                .execute()
                .value
            self.storeCustomers = fetchedCustomers
        } catch {
            print("Failed to fetch customers: \(error)")
        }
    }
    
    // MARK: - Guest Actions
    
    @MainActor
    func inviteGuests(to eventId: UUID, guestIds: Set<UUID>, storeID: UUID?) async {
        let inserts = guestIds.map { guestId in
            return [
                "event_id": eventId.uuidString,
                "client_id": guestId.uuidString,
                "status": "invited"
            ]
        }
        
        do {
            try await supabase
                .from("event_guest")
                .insert(inserts)
                .execute()
                
            if let storeID = storeID {
                await fetchEvents(for: storeID)
            }
        } catch {
            print("Failed to invite guests: \(error)")
        }
    }
    
    @MainActor
    func removeGuest(eventId: UUID, guestId: UUID, storeID: UUID?) async {
        do {
            try await supabase
                .from("event_guest")
                .delete()
                .eq("event_id", value: eventId.uuidString)
                .eq("client_id", value: guestId.uuidString)
                .execute()
                
            if let storeID = storeID {
                await fetchEvents(for: storeID)
            }
        } catch {
            print("Failed to remove guest: \(error)")
        }
    }
}
