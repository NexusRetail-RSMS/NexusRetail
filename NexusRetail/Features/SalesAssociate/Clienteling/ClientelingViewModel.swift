//
//  ClientelingViewModel.swift
//  NexusRetail
//
//  ViewModel for the Clienteling (Clients) tab. Owns client list state and
//  any future CRM / Supabase fetch logic.
//

import SwiftUI
import Observation

@Observable
final class ClientelingViewModel {

    // MARK: - State
    var clients: [AssociateClient] = SalesAssociateSampleData.clients
    var searchText: String = ""

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
    func addClient(name: String, phone: String, preferences: String) {
        let trimmedPrefs = preferences.trimmingCharacters(in: .whitespacesAndNewlines)
        clients.insert(
            AssociateClient(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
                preferences: trimmedPrefs.isEmpty ? "Preferences to be captured" : trimmedPrefs,
                tier: "New",
                purchasePattern: "New client. Purchase pattern will appear after assisted selling history is available.",
                recommendedNext: "Discovery edit"
            ),
            at: 0
        )
    }
}
