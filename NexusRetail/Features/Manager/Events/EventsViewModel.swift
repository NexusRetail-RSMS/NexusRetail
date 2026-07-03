import SwiftUI

// MARK: - Models (Mock for UI Dev)
// TODO: Replace with real Supabase models later.

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



struct MockGuest: Identifiable, Codable {
    let id: UUID
    let name: String
    let email: String
    let phone: String
    let avatarName: String
}

struct MockEvent: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var eventType: EventType
    var venue: String
    var startDate: Date
    var endDate: Date
    var maximumGuests: Int
    var bannerImageData: Data?
    var bannerImageURL: String? // Prepared for backend
    var guests: [MockGuest]
    
    var status: EventStatus {
        let now = Date()
        let calendar = Calendar.current
        if calendar.isDateInToday(startDate) || (now >= startDate && now <= endDate) {
            return .today
        } else if now > endDate {
            return .completed
        } else {
            return .upcoming
        }
    }
    
    var invitedCount: Int { guests.count }
}

@Observable
class EventsViewModel {
    var events: [MockEvent] = []
    var allCustomers: [MockGuest] = []
    
    init() {
        generateMockData()
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockData() {
        // Generate Mock Customers
        let names = ["Aarav Patel", "Riya Sharma", "Ishaan Singh", "Diya Kumar", "Aditya Gupta", "Neha Verma", "Arjun Reddy", "Pooja Desai", "Kabir Joshi", "Ananya Rao"]
        
        allCustomers = names.enumerated().map { index, name in
            MockGuest(
                id: UUID(),
                name: name,
                email: "\(name.split(separator: " ").first!.lowercased())@example.com",
                phone: "+91 98765 \(String(format: "%04d", 4321 + index))",
                avatarName: name.prefix(1).uppercased()
            )
        }
        
        // Generate Mock Events
        let now = Date()
        
        let event1 = MockEvent(
            id: UUID(),
            title: "Summer Jewellery Launch",
            description: "Join us for the exclusive preview of our new summer jewellery collection. Refreshments will be served.",
            eventType: .productLaunch,
            venue: "NexusRetail Delhi, Main Hall",
            startDate: Calendar.current.date(byAdding: .day, value: 5, to: now)!,
            endDate: Calendar.current.date(byAdding: .day, value: 5, to: now)!.addingTimeInterval(3600 * 3),
            maximumGuests: 100,
            guests: Array(allCustomers.prefix(4))
        )
        
        let event2 = MockEvent(
            id: UUID(),
            title: "Luxury Watch Preview",
            description: "An intimate gathering for our VIP customers to experience the latest luxury timepieces.",
            eventType: .vipEvent,
            venue: "NexusRetail Mumbai, VIP Lounge",
            startDate: now.addingTimeInterval(3600 * 2), // Today
            endDate: now.addingTimeInterval(3600 * 5),
            maximumGuests: 50,
            guests: Array(allCustomers.suffix(6))
        )
        
        let event3 = MockEvent(
            id: UUID(),
            title: "Festive Sale Setup",
            description: "Preparation and early access for the grand festive sale.",
            eventType: .seasonalSale,
            venue: "NexusRetail Bangalore",
            startDate: Calendar.current.date(byAdding: .day, value: -10, to: now)!,
            endDate: Calendar.current.date(byAdding: .day, value: -9, to: now)!,
            maximumGuests: 200,
            guests: allCustomers
        )
        
        events = [event1, event2, event3]
    }
    
    // MARK: - Event Actions
    
    func createEvent(title: String, description: String, eventType: EventType, venue: String, startDate: Date, endDate: Date, maximumGuests: Int, bannerImageData: Data?) {
        let newEvent = MockEvent(
            id: UUID(),
            title: title,
            description: description,
            eventType: eventType,
            venue: venue,
            startDate: startDate,
            endDate: endDate,
            maximumGuests: maximumGuests,
            bannerImageData: bannerImageData,
            guests: []
        )
        events.append(newEvent)
    }
    
    func updateEvent(_ event: MockEvent) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        }
    }
    
    func deleteEvent(id: UUID) {
        events.removeAll { $0.id == id }
    }
    
    // MARK: - Guest Actions
    
    func inviteGuests(to eventId: UUID, guestIds: Set<UUID>) {
        guard let eventIndex = events.firstIndex(where: { $0.id == eventId }) else { return }
        
        let customersToInvite = allCustomers.filter { guestIds.contains($0.id) }
        
        // Add only guests that aren't already in the list
        for customer in customersToInvite {
            if !events[eventIndex].guests.contains(where: { $0.id == customer.id }) {
                events[eventIndex].guests.append(customer)
            }
        }
    }
    
    func removeGuest(eventId: UUID, guestId: UUID) {
        if let eventIndex = events.firstIndex(where: { $0.id == eventId }) {
            events[eventIndex].guests.removeAll { $0.id == guestId }
        }
    }
}
