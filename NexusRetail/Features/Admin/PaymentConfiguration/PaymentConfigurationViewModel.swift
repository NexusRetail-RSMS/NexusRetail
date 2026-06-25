//
//  PaymentConfigurationViewModel.swift
//  NexusRetail
//
//  ViewModel for the Payment Configuration list screen.
//  Follows the @Observable MVVM pattern used throughout the project.

import Foundation
import SwiftUI

/// Manages state for the Payment Configuration list screen.
/// Fetches, caches, and mutates payment gateway configurations for a store.
@Observable
class PaymentConfigurationViewModel {

    // MARK: - Published State

    var configurations: [PaymentConfiguration] = []
    var isLoading: Bool = false
    var errorMessage: String = ""
    var showError: Bool = false
    var showSuccess: Bool = false
    var successMessage: String = ""

    // MARK: - Computed Properties

    /// The Razorpay configuration, if one exists.
    var razorpayConfig: PaymentConfiguration? {
        configurations.first { $0.provider == .razorpay }
    }

    /// The Card (Stripe) configuration, if one exists.
    var cardConfig: PaymentConfiguration? {
        configurations.first { $0.provider == .card }
    }

    /// `true` when at least one gateway is both enabled **and** configured.
    var canProcessPayments: Bool {
        configurations.contains { $0.isEnabled && $0.status == .configured }
    }

    // MARK: - Service

    let service = PaymentConfigurationService()

    // MARK: - Actions

    /// Fetches all payment configurations for the given store.
    /// If a provider has no existing record, a default disabled/notConfigured row is inserted.
    func loadConfigurations(storeID: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            var configs = try await service.fetchConfigurations(storeID: storeID)

            // Ensure every provider has a row — insert defaults for any that are missing.
            for provider in PaymentProvider.allCases {
                if !configs.contains(where: { $0.provider == provider }) {
                    let insert = PaymentConfigurationInsert(
                        storeID: storeID,
                        provider: provider,
                        isEnabled: false,
                        status: .notConfigured,
                        environment: .test
                    )
                    let newConfig = try await service.insertConfiguration(insert)
                    configs.append(newConfig)
                }
            }

            configurations = configs
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    /// Toggles the `isEnabled` flag for a configuration and reloads.
    /// If a non-configured gateway is toggled on, it stays enabled but the
    /// status remains `.notConfigured` (the user must still enter credentials).
    func toggleEnabled(for config: PaymentConfiguration) async {
        let newValue = !config.isEnabled

        do {
            _ = try await service.toggleEnabled(id: config.id, isEnabled: newValue)

            // Reload the full list so the UI reflects the latest server state.
            await loadConfigurations(storeID: config.storeID)

            if newValue {
                successMessage = "\(config.provider.displayName) has been enabled."
            } else {
                successMessage = "\(config.provider.displayName) has been disabled."
            }
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
