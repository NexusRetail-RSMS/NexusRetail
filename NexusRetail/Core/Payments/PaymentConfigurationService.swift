//
//  PaymentConfigurationService.swift
//  NexusRetail
//
//  Supabase CRUD operations for payment gateway configurations.
//

import Foundation
import Supabase

/// Service for managing payment configurations in Supabase.
/// Adapted to work with the existing `payment_terminal` table and JSONB config.
struct PaymentConfigurationService {
    
    private let tableName = "payment_terminal"
    
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    // MARK: - Fetch
    
    /// Fetches all payment configurations for a given store.
    /// Returns an empty array if no configurations exist yet.
    func fetchConfigurations(storeID: UUID) async throws -> [PaymentConfiguration] {
        let terminals: [PaymentTerminal] = try await client
            .from(tableName)
            .select()
            .eq("store_id", value: storeID.uuidString)
            .execute()
            .value
        return terminals.map { PaymentConfiguration(from: $0) }
    }
    
    /// Fetches a single payment configuration for a specific provider and store.
    func fetchConfiguration(storeID: UUID, provider: PaymentProvider) async throws -> PaymentConfiguration? {
        let terminals: [PaymentTerminal] = try await client
            .from(tableName)
            .select()
            .eq("store_id", value: storeID.uuidString)
            .eq("type", value: provider.rawValue)
            .execute()
            .value
        return terminals.first.map { PaymentConfiguration(from: $0) }
    }
    
    /// Fetches a single terminal by ID. Internal helper.
    private func fetchTerminal(id: UUID) async throws -> PaymentTerminal {
        let terminal: PaymentTerminal = try await client
            .from(tableName)
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        return terminal
    }
    
    // MARK: - Insert
    
    /// Creates a new payment configuration record mapping to the `payment_terminal` table.
    @discardableResult
    func insertConfiguration(_ config: PaymentConfigurationInsert) async throws -> PaymentConfiguration {
        let payload = PaymentTerminalConfig(
            isEnabled: config.isEnabled,
            status: config.status,
            environment: config.environment,
            credential1: nil,
            credential2: nil,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        let insert = PaymentTerminalInsert(
            storeID: config.storeID,
            type: config.provider,
            config: payload
        )
        let result: PaymentTerminal = try await client
            .from(tableName)
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
        return PaymentConfiguration(from: result)
    }
    
    // MARK: - Update
    
    /// Toggles the `is_enabled` flag for a payment configuration.
    @discardableResult
    func toggleEnabled(id: UUID, isEnabled: Bool) async throws -> PaymentConfiguration {
        let terminal = try await fetchTerminal(id: id)
        var config = terminal.config
        config.isEnabled = isEnabled
        config.updatedAt = ISO8601DateFormatter().string(from: Date())
        
        let update = PaymentTerminalUpdate(config: config)
        let result: PaymentTerminal = try await client
            .from(tableName)
            .update(update)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
        return PaymentConfiguration(from: result)
    }
    
    /// Saves (upsert) a full credential update — sets credentials, status to configured, and updates timestamp.
    @discardableResult
    func saveCredentials(
        id: UUID,
        environment: PaymentEnvironment,
        credential1: String,
        credential2: String
    ) async throws -> PaymentConfiguration {
        let terminal = try await fetchTerminal(id: id)
        var config = terminal.config
        config.status = .configured
        config.environment = environment
        config.credential1 = credential1
        config.credential2 = credential2
        config.updatedAt = ISO8601DateFormatter().string(from: Date())
        
        let update = PaymentTerminalUpdate(config: config)
        let result: PaymentTerminal = try await client
            .from(tableName)
            .update(update)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
        return PaymentConfiguration(from: result)
    }
    
    // MARK: - Business Logic
    
    /// Returns `true` if the store has at least one payment gateway that is
    /// both **enabled** and **configured**.
    func canProcessPayments(storeID: UUID) async throws -> Bool {
        let configs = try await fetchConfigurations(storeID: storeID)
        return configs.contains { $0.isEnabled && $0.status == .configured }
    }
}
