//
//  SalesNotificationViewModel.swift
//  NexusRetail
//

import Foundation
import SwiftUI
import Supabase

enum SalesNotificationType: Equatable {
    case newEvent(name: String, time: Date, venue: String?, description: String?, eventType: String?)
    case upcomingAppointment(clientName: String, time: Date, type: String?, notes: String?)
}

struct SalesNotification: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let timestamp: Date
    let type: SalesNotificationType
    let icon: String
    let color: Color
    var imageUrl: String? = nil
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// DTOs
private struct EventRow: Codable, Identifiable {
    let id: UUID
    let name: String
    let scheduledAt: Date
    let venue: String?
    let description: String?
    let eventType: String?
    let bannerImageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, venue, description
        case scheduledAt = "scheduled_at"
        case eventType = "event_type"
        case bannerImageUrl = "banner_image_url"
    }
}

private struct AppointmentRow: Codable, Identifiable {
    let id: UUID
    let client: ClientInfo?
    let scheduledAt: Date
    let type: String?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id, client, type, notes
        case scheduledAt = "scheduled_at"
    }
    
    struct ClientInfo: Codable {
        let name: String
    }
}

@Observable
final class SalesNotificationViewModel {
    var notifications: [SalesNotification] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    /// IDs the associate has already seen/dismissed
    private(set) var readIDs: Set<UUID> = []
    
    private var monitoredStoreID: UUID?
    private var realtimeChannel: RealtimeChannelV2?
    private var refreshTimer: Timer?
    
    var unreadCount: Int {
        notifications.filter { !readIDs.contains($0.id) }.count
    }
    
    init() {
        loadReadIDs()
    }
    
    private func loadReadIDs() {
        let array = UserDefaults.standard.stringArray(forKey: "salesReadNotificationIDs") ?? []
        readIDs = Set(array.compactMap { UUID(uuidString: $0) })
    }
    
    private func saveReadIDs() {
        let array = readIDs.map { $0.uuidString }
        UserDefaults.standard.set(array, forKey: "salesReadNotificationIDs")
    }
    
    func isRead(_ notification: SalesNotification) -> Bool {
        readIDs.contains(notification.id)
    }
    
    func markAsRead(_ id: UUID) {
        readIDs.insert(id)
        saveReadIDs()
    }
    
    func markAllAsRead() {
        for notification in notifications {
            readIDs.insert(notification.id)
        }
        saveReadIDs()
    }
    
    func load(storeID: UUID?, associateID: UUID?) async {
        guard let storeID = storeID, let associateID = associateID else { return }
        await MainActor.run { isLoading = true }
        
        do {
            let now = ISO8601DateFormatter().string(from: Date())
            let oneHourFromNow = ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600))
            
            async let eventsTask: [EventRow] = SupabaseManager.shared.client
                .from("event")
                .select("id, name, scheduled_at, venue, description, event_type, banner_image_url")
                .eq("store_id", value: storeID.uuidString)
                .gte("scheduled_at", value: now)
                .order("scheduled_at", ascending: true)
                .execute()
                .value
                
            async let apptsTask: [AppointmentRow] = SupabaseManager.shared.client
                .from("appointment")
                .select("id, scheduled_at, type, notes, client:client_id(name)")
                .eq("associate_id", value: associateID.uuidString)
                .gte("scheduled_at", value: now)
                .lte("scheduled_at", value: oneHourFromNow)
                .order("scheduled_at", ascending: true)
                .execute()
                .value
                
            let (events, appts) = try await (eventsTask, apptsTask)
            
            let eventNotifications = events.map { e in
                SalesNotification(
                    id: e.id,
                    title: "New Event: \(e.name)",
                    subtitle: "Scheduled for \(e.scheduledAt.formatted(date: .abbreviated, time: .shortened))",
                    timestamp: e.scheduledAt,
                    type: .newEvent(name: e.name, time: e.scheduledAt, venue: e.venue, description: e.description, eventType: e.eventType),
                    icon: "calendar.badge.plus",
                    color: RSMSColors.burgundy,
                    imageUrl: e.bannerImageUrl
                )
            }
            
            let apptNotifications = appts.map { a in
                SalesNotification(
                    id: a.id,
                    title: "Upcoming Appointment",
                    subtitle: "With \(a.client?.name ?? "Client") at \(a.scheduledAt.formatted(date: .omitted, time: .shortened))",
                    timestamp: a.scheduledAt,
                    type: .upcomingAppointment(clientName: a.client?.name ?? "Client", time: a.scheduledAt, type: a.type, notes: a.notes),
                    icon: "clock.badge.exclamationmark",
                    color: .orange
                )
            }
            
            let combined = eventNotifications + apptNotifications
            
            await MainActor.run {
                self.notifications = combined.sorted { $0.timestamp < $1.timestamp }
                self.isLoading = false
                self.errorMessage = nil
            }
        } catch {
            print("SalesNotification fetch error: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func startListening(storeID: UUID?, associateID: UUID?) async {
        guard let storeID = storeID, let associateID = associateID else { return }
        monitoredStoreID = storeID
        
        await stopListening()
        
        let channelName = "sales-notifications-\(UUID().uuidString)"
        let channel = SupabaseManager.shared.client.realtimeV2.channel(channelName)
        
        let eventChanges = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "event",
            filter: .eq("store_id", value: storeID.uuidString)
        )
        
        let apptChanges = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "appointment",
            filter: .eq("associate_id", value: associateID.uuidString)
        )
        
        try? await channel.subscribeWithError()
        self.realtimeChannel = channel
        
        // Listen for realtime DB changes
        Task {
            for await _ in eventChanges {
                try? await Task.sleep(for: .milliseconds(500))
                await self.load(storeID: storeID, associateID: associateID)
            }
        }
        
        Task {
            for await _ in apptChanges {
                try? await Task.sleep(for: .milliseconds(500))
                await self.load(storeID: storeID, associateID: associateID)
            }
        }
        
        // Periodically refresh to catch appointments entering the 1-hour window
        await MainActor.run {
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                Task {
                    await self?.load(storeID: storeID, associateID: associateID)
                }
            }
        }
    }
    
    func stopListening() async {
        if let channel = realtimeChannel {
            await channel.unsubscribe()
            realtimeChannel = nil
        }
        await MainActor.run {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }
}
