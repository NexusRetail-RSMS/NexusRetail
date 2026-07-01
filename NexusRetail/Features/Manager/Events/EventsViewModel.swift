import SwiftUI
import Supabase

struct AppEvent: Codable, Identifiable {
    let id: UUID
    let store_id: UUID?
    let launch_sku_id: UUID?
    let name: String
    let scheduled_at: Date
    let venue: String?
    let description: String?
}

@Observable
class EventsViewModel {
    var upcomingEvents: [UpcomingEvent] = []
    var isLoading = false
    var errorMessage: String? = nil
    
    init() {
        Task {
            await loadEvents()
        }
    }
    
    func loadEvents() async {
        isLoading = true
        errorMessage = nil
        do {
            let response: [AppEvent] = try await SupabaseManager.shared.client
                .from("event")
                .select()
                .order("scheduled_at", ascending: true)
                .execute()
                .value
            
            let formatter = DateFormatter()
            self.upcomingEvents = response.map { event in
                formatter.dateFormat = "dd MMM yyyy"
                let dateString = formatter.string(from: event.scheduled_at)
                formatter.dateFormat = "hh:mm a"
                let timeString = formatter.string(from: event.scheduled_at)
                
                return UpcomingEvent(
                    id: event.id,
                    title: event.name,
                    date: dateString,
                    time: timeString,
                    location: event.venue ?? "Current Store",
                    imageColor: RSMSColors.burgundy,
                    icon: "sparkles"
                )
            }
        } catch {
            print("Error loading events: \(error)")
            self.errorMessage = "Failed to load events"
        }
        isLoading = false
    }
    
    func addEvent(title: String, date: Date) async {
        let newId = UUID()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        let dateString = formatter.string(from: date)
        formatter.dateFormat = "hh:mm a"
        let timeString = formatter.string(from: date)
        
        let newUpcoming = UpcomingEvent(
            id: newId,
            title: title,
            date: dateString,
            time: timeString,
            location: "Current Store",
            imageColor: RSMSColors.burgundy,
            icon: "shippingbox.fill"
        )
        
        withAnimation {
            self.upcomingEvents.append(newUpcoming)
        }
        
        do {
            let appEvent = AppEvent(
                id: newId,
                store_id: nil, // We'll just leave it nil for now unless we know the current store ID
                launch_sku_id: nil,
                name: title,
                scheduled_at: date,
                venue: "Current Store",
                description: nil
            )
            try await SupabaseManager.shared.client
                .from("event")
                .insert(appEvent)
                .execute()
        } catch {
            print("Error saving event: \(error)")
        }
    }
}
