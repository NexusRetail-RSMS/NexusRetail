import Foundation
import Supabase
import Combine

struct DBClient: Codable, Identifiable {
    let id: UUID
    let name: String
    let phone: String?
    let email: String?
}

struct SupabaseClientInsert: Codable {
    let name: String
    let phone: String?
    let email: String?
}

struct SupabaseAppointment: Codable, Identifiable {
    let id: UUID
    let clientId: UUID
    let associateId: UUID?
    let type: String
    let scheduledAt: Date
    let status: String
    let notes: String?
    let client: DBClient?

    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case associateId = "associate_id"
        case type
        case scheduledAt = "scheduled_at"
        case status
        case notes
        case client
    }
}

struct SupabaseAppointmentInsert: Codable {
    let clientId: UUID
    let associateId: UUID
    let type: String
    let scheduledAt: Date
    let status: String
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case associateId = "associate_id"
        case type
        case scheduledAt = "scheduled_at"
        case status
        case notes
    }
}

@Observable
final class AppointmentsViewModel {
    var appointments: [AssociateAppointment] = []
    var isLoading = false
    var error: Error?
    
    // Map from Supabase string to local enum
    private func mapMode(from type: String) -> AppointmentMode {
        return type == "video" ? .video : .inStore
    }
    
    private func mapModeString(from mode: AppointmentMode) -> String {
        return mode == .video ? "video" : "in_store"
    }
    
    private func mapStatus(from status: String) -> AppointmentStatus {
        switch status.lowercased() {
        case "confirmed": return .confirmed
        case "cancelled": return .cancelled
        default: return .pending
        }
    }
    
    @MainActor
    func fetchAppointments(for associateId: UUID) async {
        
        isLoading = true
        error = nil
        
        do {
            let response: [SupabaseAppointment] = try await SupabaseManager.shared.client
                .from("appointment")
                .select("*, client:client_id(*)")
                .eq("associate_id", value: associateId)
                .order("scheduled_at", ascending: true)
                .execute()
                .value
                
            self.appointments = response.map { dbAppt in
                AssociateAppointment(
                    id: dbAppt.id,
                    clientName: dbAppt.client?.name ?? "Unknown Client",
                    clientEmail: dbAppt.client?.email ?? "",
                    clientPhone: dbAppt.client?.phone ?? "",
                    date: dbAppt.scheduledAt,
                    mode: self.mapMode(from: dbAppt.type),
                    status: self.mapStatus(from: dbAppt.status),
                    productOrNote: dbAppt.notes ?? ""
                )
            }
        } catch {
            print("Failed to fetch appointments: \(error)")
            self.error = error
        }
        
        isLoading = false
    }
    
    @MainActor
    func saveAppointment(associateId: UUID, clientName: String, clientEmail: String, clientPhone: String, date: Date, mode: AppointmentMode, status: AppointmentStatus, notes: String) async -> Bool {
        
        do {
            // 1. Try to find existing client by phone or email
            var finalClientId: UUID? = nil
            
            let existingClients: [DBClient] = try await SupabaseManager.shared.client
                .from("client")
                .select("*")
                .eq("phone", value: clientPhone)
                .execute()
                .value
                
            if let first = existingClients.first {
                finalClientId = first.id
            } else {
                // Insert new client
                let newClient = SupabaseClientInsert(name: clientName, phone: clientPhone, email: clientEmail)
                let insertedClient: [DBClient] = try await SupabaseManager.shared.client
                    .from("client")
                    .insert(newClient)
                    .select()
                    .execute()
                    .value
                
                finalClientId = insertedClient.first?.id
            }
            
            guard let clientId = finalClientId else { return false }
            
            // 2. Insert appointment
            let newAppt = SupabaseAppointmentInsert(
                clientId: clientId,
                associateId: associateId,
                type: mapModeString(from: mode),
                scheduledAt: date,
                status: status.rawValue,
                notes: notes
            )
            
            try await SupabaseManager.shared.client
                .from("appointment")
                .insert(newAppt)
                .execute()
            
            // Refetch to update UI
            await fetchAppointments(for: associateId)
            return true
            
        } catch {
            print("Error saving appointment: \(error)")
            return false
        }
    }
}
