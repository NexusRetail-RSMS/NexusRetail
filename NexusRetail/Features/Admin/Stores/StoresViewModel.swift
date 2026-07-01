//
//  StoresViewModel.swift
//  NexusRetail
//

import Foundation
import SwiftUI

@Observable
class StoresViewModel {
    var stores: [Store] = []
    var managers: [AppUser] = []

    /// Returns managers that are not already assigned to any store,
    /// plus the manager currently assigned to `excludingStoreID` (so editing a store keeps its own manager visible).
    func availableManagers(excludingStoreID: UUID? = nil) -> [AppUser] {
        // Collect all manager IDs that are already assigned to a store
        let assignedManagerIDs: Set<UUID> = stores.reduce(into: Set<UUID>()) { result, store in
            // If we're editing a store, don't count its own manager as "taken"
            if let exclude = excludingStoreID, store.id == exclude { return }
            if let mid = store.managerID { result.insert(mid) }
        }
        return managers.filter { !assignedManagerIDs.contains($0.id) }
    }
    
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    private let repository = StoreRepository()
    
    /// Loads stores and managers concurrently.
    func load() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let fetchStoresTask = repository.fetchStores()
            async let fetchManagersTask = repository.fetchManagers()
            
            let (fetchedStores, fetchedManagers) = try await (fetchStoresTask, fetchManagersTask)
            
            // Only update UI once both are done successfully
            self.stores = fetchedStores
            self.managers = fetchedManagers
        } catch let error as DecodingError {
            print("Decoding Error: \(error)")
            self.errorMessage = "Decoding Error: \(error)"
        } catch {
            if error is CancellationError { return }
            self.errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Creates a new store and re-fetches the list.
    func create(name: String, address: String, phone: String, locale: String, currencyCode: String, timezone: String, managerID: UUID?, status: StoreStatus, includeRazorpay: Bool, includeCard: Bool, latitude: Double?, longitude: Double?, city: String?, country: String?) async -> UUID? {
        guard !name.isEmpty, !address.isEmpty else {
            errorMessage = "Name and Address are required."
            return nil
        }

        // One-manager-one-store rule
        if let mid = managerID, stores.contains(where: { $0.managerID == mid }) {
            errorMessage = "This manager is already assigned to another store. Each manager can only manage one store."
            return nil
        }

        isLoading = true
        errorMessage = nil
        
        let newStoreId = UUID()
        let newStore = Store(
            id: newStoreId,
            name: name,
            address: address,
            locale: locale,
            currencyCode: currencyCode,
            timezone: timezone,
            phone: phone.isEmpty ? nil : phone,
            managerID: managerID,
            isWarehouse: false,
            status: status,
            latitude: latitude,
            longitude: longitude,
            city: (city?.isEmpty ?? true) ? nil : city,
            country: (country?.isEmpty ?? true) ? nil : country
        )
        
        var terminals: [PaymentTerminal] = []
        if includeRazorpay {
            let initialConfig = PaymentTerminalConfig(
                isEnabled: false,
                status: .notConfigured,
                environment: .test,
                credential1: nil,
                credential2: nil,
                updatedAt: nil
            )
            terminals.append(PaymentTerminal(id: UUID(), storeID: newStoreId, type: .razorpay, config: initialConfig))
        }
        if includeCard {
            let initialConfig = PaymentTerminalConfig(
                isEnabled: false,
                status: .notConfigured,
                environment: .test,
                credential1: nil,
                credential2: nil,
                updatedAt: nil
            )
            terminals.append(PaymentTerminal(id: UUID(), storeID: newStoreId, type: .card, config: initialConfig))
        }
        
        do {
            try await repository.createStore(newStore, terminals: terminals)
            await load() // Refresh list
            return newStoreId
        } catch {
            self.errorMessage = "Failed to create store: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }
    
    /// Updates an existing store.
    func update(storeId: UUID, name: String, address: String, phone: String, locale: String, currencyCode: String, timezone: String, managerID: UUID?, status: StoreStatus, latitude: Double?, longitude: Double?, city: String?, country: String?) async -> Bool {
        guard !name.isEmpty else {
            errorMessage = "Name is required."
            return false
        }

        // One-manager-one-store rule: check if the chosen manager is assigned to a *different* store
        if let mid = managerID,
           let conflictingStore = stores.first(where: { $0.managerID == mid && $0.id != storeId }) {
            errorMessage = "This manager is already assigned to \"\(conflictingStore.name)\". Each manager can only manage one store."
            return false
        }

        isLoading = true
        errorMessage = nil
        
        // Find existing store to retain fields that shouldn't change
        guard let existingStore = stores.first(where: { $0.id == storeId }) else {
            errorMessage = "Store not found."
            isLoading = false
            return false
        }
        
        let updatedStore = Store(
            id: storeId,
            name: name,
            address: address.isEmpty ? nil : address,
            locale: locale,
            currencyCode: currencyCode,
            timezone: timezone,
            phone: phone.isEmpty ? nil : phone,
            managerID: managerID,
            isWarehouse: existingStore.isWarehouse,
            status: status,
            latitude: latitude,
            longitude: longitude,
            city: (city?.isEmpty ?? true) ? nil : city,
            country: (country?.isEmpty ?? true) ? nil : country
        )
        
        do {
            try await repository.updateStore(updatedStore)
            await load() // Refresh list
            return true
        } catch {
            self.errorMessage = "Failed to update store: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
}
