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
            self.errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Creates a new store and re-fetches the list.
    func create(name: String, address: String, locale: String, currencyCode: String, timezone: String, managerID: UUID?, includeRazorpay: Bool, includeCard: Bool) async -> Bool {
        guard !name.isEmpty, !address.isEmpty else {
            errorMessage = "Name and Address are required."
            return false
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
            managerID: managerID,
            isWarehouse: false,
            status: .active
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
            return true
        } catch {
            self.errorMessage = "Failed to create store: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
}
