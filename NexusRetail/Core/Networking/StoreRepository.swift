//
//  StoreRepository.swift
//  NexusRetail
//

import Foundation
import Supabase

struct StoreRepository {
    private let client = SupabaseManager.shared.client
    
    /// Fetches all active and archived stores.
    func fetchStores() async throws -> [Store] {
        let response: [Store] = try await client
            .from("store")
            .select()
            .order("name", ascending: true)
            .execute()
            .value
        return response
    }
    
    /// Fetches all users with the 'manager' role.
    /// Fetches all managers with aggregated stats (performance, revenue, tenure).
    func fetchManagers() async throws -> [DisplayManager] {
        let stats: [ManagerStatsRPC] = try await client
            .rpc("get_manager_stats")            .execute()
            .value
        return stats.map(DisplayManager.init(rpc:))
    }
    
    /// Creates a new store and optionally attaches payment terminals.
    func createStore(_ store: Store, terminals: [PaymentTerminal]) async throws {
        // 1. Insert Store
        try await client
            .from("store")
            .insert(store)
            .execute()
        
        // 2. Insert Terminals (if any)
        if !terminals.isEmpty {
            try await client
                .from("payment_terminal")
                .insert(terminals)
                .execute()
        }
    }
    
    /// Archives a store (soft delete).
    func archiveStore(id: UUID) async throws {
        try await client
            .from("store")
            .update(["status": "archived"])
            .eq("id", value: id)
            .execute()
    }
    
    /// Updates an existing store.
    func updateStore(_ store: Store) async throws {
        try await client
            .from("store")
            .update(store)
            .eq("id", value: store.id)
            .execute()
    }
}
