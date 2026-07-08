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
                return try await ImageUploader.upload(data: data, bucket: "product-images", folder: "events")
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
    func inviteGuests(
        to eventId: UUID,
        guestIds: Set<UUID>,
        storeID: UUID?,
        managerName: String?,
        managerEmail: String?
    ) async -> Bool {
        let inserts = guestIds.map { guestId in
            return [
                "event_id": eventId.uuidString,
                "client_id": guestId.uuidString,
                "status": "invited"
            ]
        }
        
        do {
            guard let event = events.first(where: { $0.id == eventId }) else {
                print("Failed to invite guests: event not found.")
                return false
            }

            let invitedGuests = storeCustomers.filter { guestIds.contains($0.id) }
            let emailSuccess = await sendEventInvitationEmails(
                for: event,
                to: invitedGuests,
                managerName: managerName,
                managerEmail: managerEmail
            )

            guard emailSuccess else {
                return false
            }

            try await supabase
                .from("event_guest")
                .insert(inserts)
                .execute()
                
            if let storeID = storeID {
                await fetchEvents(for: storeID)
            }
            return true
        } catch {
            print("Failed to invite guests: \(error)")
            return false
        }
    }

    @MainActor
    func inviteGuest(
        _ guest: SupabaseClientModel,
        to eventId: UUID,
        storeID: UUID?,
        managerName: String?,
        managerEmail: String?
    ) async -> Bool {
        await inviteGuests(
            to: eventId,
            guestIds: [guest.id],
            storeID: storeID,
            managerName: managerName,
            managerEmail: managerEmail
        )
    }

    private func sendEventInvitationEmails(
        for event: SupabaseEvent,
        to guests: [SupabaseClientModel],
        managerName: String?,
        managerEmail: String?
    ) async -> Bool {
        var didSendAllEmails = !guests.isEmpty

        for guest in guests {
            guard let email = guest.email?.trimmingCharacters(in: .whitespacesAndNewlines),
                  isValidEmail(email) else {
                didSendAllEmails = false
                continue
            }

            let didSendEmail = await sendEventInvitationEmail(
                event: event,
                guestName: guest.name,
                guestEmail: email,
                managerName: managerName,
                managerEmail: managerEmail
            )
            didSendAllEmails = didSendAllEmails && didSendEmail
        }

        return didSendAllEmails
    }

    private func sendEventInvitationEmail(
        event: SupabaseEvent,
        guestName: String?,
        guestEmail: String,
        managerName: String?,
        managerEmail: String?
    ) async -> Bool {
        let resendApiKey = "re_3ot8yx3s_BDYPp6FcxJXDcFsSXU6bGW7t"

        guard let url = URL(string: "https://api.resend.com/emails") else { return false }

        let senderName = cleanEmailDisplayName(managerName) ?? "Nexus Retail Manager"
        let senderEmail = "admin@updates.nexusretail.tech"
        let replyToEmail = managerEmail?.trimmingCharacters(in: .whitespacesAndNewlines)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(resendApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let guestDisplayNameRaw = guestName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let guestDisplayName = htmlEscaped(guestDisplayNameRaw?.isEmpty == false ? guestDisplayNameRaw! : "Guest")
        let eventName = htmlEscaped(event.name)
        let venue = htmlEscaped(event.venueStr)
        let description = event.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        let descriptionHtml = description?.isEmpty == false ? """
        <tr>
            <td style="padding: 0 32px 22px 32px; color: #4b5563; font-size: 15px; line-height: 1.6;">
                \(htmlEscaped(description!))
            </td>
        </tr>
        """ : ""
        let endTimeHtml = event.endTime.map {
            """
            <tr>
                <td style="padding: 10px 0; color: #111827; font-size: 15px;">
                    <strong>End Time:</strong> \($0.formatted(date: .omitted, time: .shortened))
                </td>
            </tr>
            """
        } ?? ""
        let bannerHtml = event.bannerImageURL.flatMap { urlString in
            guard URL(string: urlString) != nil else { return nil }
            return """
            <tr>
                <td>
                    <img src="\(htmlEscaped(urlString))" alt="\(eventName)" style="display: block; width: 100%; max-width: 640px; height: auto; border: 0;" />
                </td>
            </tr>
            """
        } ?? ""

        let htmlBody = """
        <!doctype html>
        <html>
        <body style="margin: 0; padding: 0; background-color: #f4f1ef; font-family: Arial, Helvetica, sans-serif;">
            <span style="display: none; max-height: 0; overflow: hidden;">
                You are invited to \(eventName) at \(venue).
            </span>

            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #f4f1ef; padding: 28px 12px;">
                <tr>
                    <td align="center">
                        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width: 640px; background-color: #ffffff; border-radius: 18px; overflow: hidden; border: 1px solid #eadfdb;">
                            \(bannerHtml)
                            <tr>
                                <td style="background-color: #7b1e3a; padding: 28px 32px;">
                                    <p style="margin: 0 0 8px 0; color: #f7d9df; font-size: 13px; letter-spacing: 1px; text-transform: uppercase;">Event Invitation</p>
                                    <h1 style="margin: 0; color: #ffffff; font-size: 28px; line-height: 1.25; font-weight: 700;">\(eventName)</h1>
                                </td>
                            </tr>
                            <tr>
                                <td style="padding: 30px 32px 14px 32px; color: #111827; font-size: 16px; line-height: 1.6;">
                                    Hi \(guestDisplayName),
                                    <br><br>
                                    You are warmly invited to join us for <strong>\(eventName)</strong>. We would be delighted to host you.
                                </td>
                            </tr>
                            \(descriptionHtml)
                            <tr>
                                <td style="padding: 0 32px 24px 32px;">
                                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #fbf7f5; border: 1px solid #eadfdb; border-radius: 14px; padding: 16px 18px;">
                                        <tr>
                                            <td style="padding: 10px 0; color: #111827; font-size: 15px;">
                                                <strong>Date:</strong> \(event.scheduledAt.formatted(date: .long, time: .omitted))
                                            </td>
                                        </tr>
                                        <tr>
                                            <td style="padding: 10px 0; color: #111827; font-size: 15px;">
                                                <strong>Start Time:</strong> \(event.scheduledAt.formatted(date: .omitted, time: .shortened))
                                            </td>
                                        </tr>
                                        \(endTimeHtml)
                                        <tr>
                                            <td style="padding: 10px 0; color: #111827; font-size: 15px;">
                                                <strong>Venue:</strong> \(venue)
                                            </td>
                                        </tr>
                                    </table>
                                </td>
                            </tr>
                            <tr>
                                <td style="padding: 0 32px 30px 32px; color: #4b5563; font-size: 15px; line-height: 1.6;">
                                    Please reply to this email if you have any questions.
                                    <br><br>
                                    Warm regards,<br>
                                    <strong style="color: #111827;">\(htmlEscaped(senderName))</strong>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </table>
        </body>
        </html>
        """

        let plainTextBody = """
        Hi \(guestDisplayNameRaw?.isEmpty == false ? guestDisplayNameRaw! : "Guest"),

        You are invited to \(event.name).

        Date: \(event.scheduledAt.formatted(date: .long, time: .omitted))
        Start Time: \(event.scheduledAt.formatted(date: .omitted, time: .shortened))
        \(event.endTime.map { "End Time: \($0.formatted(date: .omitted, time: .shortened))" } ?? "")
        Venue: \(event.venueStr)

        \(description ?? "")

        Warm regards,
        \(senderName)
        """

        var payload: [String: Any] = [
            "from": "\(senderName) <\(senderEmail)>",
            "to": [guestEmail],
            "subject": "You're invited: \(event.name)",
            "html": htmlBody,
            "text": plainTextBody
        ]

        if let replyToEmail, isValidEmail(replyToEmail) {
            payload["reply_to"] = replyToEmail
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpRes = response as? HTTPURLResponse, httpRes.statusCode >= 300 {
                print("Failed to send event invitation email. Status: \(httpRes.statusCode)")
                print(String(data: data, encoding: .utf8) ?? "")
                return false
            } else {
                print("Successfully dispatched event invitation email via Resend to \(guestEmail)!")
                return true
            }
        } catch {
            print("Network error sending event invitation email: \(error)")
            return false
        }
    }

    private func cleanEmailDisplayName(_ name: String?) -> String? {
        let cleaned = name?
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned?.isEmpty == false ? cleaned : nil
    }

    private func htmlEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = #"^\S+@\S+\.\S+$"#
        return email.range(of: regex, options: .regularExpression) != nil
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
