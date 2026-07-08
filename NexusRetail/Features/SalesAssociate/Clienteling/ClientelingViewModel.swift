//
//  ClientelingViewModel.swift
//  NexusRetail
//
//  ViewModel for the Clienteling (Clients) tab. Owns client list state and
//  any future CRM / Supabase fetch logic.
//

import SwiftUI
import Observation
import Supabase

struct ClientRow: Decodable {
    let id: UUID
    let name: String
    let phone: String
    let email: String?
    let style_preferences: [String: String]?
}

@Observable
final class ClientelingViewModel {

    // MARK: - State
    var clients: [AssociateClient] = []
    var searchText: String = ""
    var isLoading: Bool = false

    // MARK: - Computed
    var filteredClients: [AssociateClient] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return clients }
        return clients.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.phone.localizedCaseInsensitiveContains(query) ||
            $0.preferences.localizedCaseInsensitiveContains(query)
        }
    }

    // MARK: - Mutations
    
    func fetchClients() async {
        await MainActor.run { isLoading = true }
        do {
            let rows: [ClientRow] = try await SupabaseManager.shared.client
                .from("client")
                .select("id, name, phone, email, style_preferences")
                .order("created_at", ascending: false)
                .execute()
                .value
                
            let mapped = rows.map { row in
                let manualPref = row.style_preferences?["manual"]
                let prefText = (manualPref?.isEmpty == false) ? manualPref! : "Analyzing..."
                
                return AssociateClient(
                    dbId: row.id,
                    name: row.name,
                    phone: row.phone,
                    email: row.email ?? "",
                    preferences: prefText,
                    purchasePattern: "Analyzing..."
                )
            }
            
            await MainActor.run {
                self.clients = mapped
                self.isLoading = false
            }
        } catch {
            print("Failed to fetch clients: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
    
    func addClient(name: String, phone: String, email: String = "", preferences: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPrefs = preferences.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                struct InsertClient: Encodable {
                    let name: String
                    let phone: String
                    let email: String
                    let style_preferences: [String: String]
                }
                
                let newClient = InsertClient(
                    name: trimmedName,
                    phone: trimmedPhone,
                    email: trimmedEmail,
                    style_preferences: ["manual": trimmedPrefs]
                )
                
                let inserted: [ClientRow] = try await SupabaseManager.shared.client
                    .from("client")
                    .insert(newClient)
                    .select("id, name, phone, email, style_preferences")
                    .execute()
                    .value
                    
                if let row = inserted.first {
                    let manualPref = row.style_preferences?["manual"]
                    let prefText = (manualPref?.isEmpty == false) ? manualPref! : "Preferences to be captured"
                    
                    await MainActor.run {
                        self.clients.insert(
                            AssociateClient(
                                dbId: row.id,
                                name: row.name,
                                phone: row.phone,
                                email: row.email ?? "",
                                preferences: prefText,
                                purchasePattern: "New client. Purchase pattern will appear after assisted selling history is available."
                            ),
                            at: 0
                        )
                    }
                }
            } catch {
                print("Failed to save new client: \(error)")
            }
        }
    }
}
