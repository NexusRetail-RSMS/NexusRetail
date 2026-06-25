//
//  RazorpayConfigurationViewModel.swift
//  NexusRetail
//
//  ViewModel for the Razorpay credential configuration screen.
//  Uses @Observable (Observation framework) — not ObservableObject.

import Foundation

@Observable
class RazorpayConfigurationViewModel {

    // MARK: - Form Fields

    var environment: PaymentEnvironment = .test
    var keyID: String = ""
    var keySecret: String = ""

    // MARK: - UI State

    var isLoading: Bool = false
    var isSaving: Bool = false
    var errorMessage: String = ""
    var showError: Bool = false
    var showSuccess: Bool = false
    var successMessage: String = ""

    // MARK: - Field Validation Errors

    var keyIDError: String = ""
    var keySecretError: String = ""

    // MARK: - Editing State

    /// `true` when editing an existing configuration (vs. creating a new one).
    var isEditing: Bool = false

    /// The database ID of the existing configuration, if any.
    var configID: UUID? = nil

    // MARK: - Service

    let service = PaymentConfigurationService()

    // MARK: - Load Existing

    /// Fetches the existing Razorpay configuration for the given store.
    /// If a record exists, populates the form fields and switches to edit mode.
    func loadExisting(storeID: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            if let config = try await service.fetchConfiguration(
                storeID: storeID,
                provider: .razorpay
            ) {
                environment = config.environment
                keyID = config.credential1 ?? ""
                keySecret = config.credential2 ?? ""
                isEditing = true
                configID = config.id
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Validation

    /// Validates required fields. Returns `true` when all fields pass.
    func validate() -> Bool {
        var isValid = true
        let trimmedKeyID = keyID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKeySecret = keySecret.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate Key ID
        if trimmedKeyID.isEmpty {
            keyIDError = "Key ID is required."
            isValid = false
        } else {
            let expectedPrefix = environment == .test ? "rzp_test_" : "rzp_live_"
            if !trimmedKeyID.hasPrefix(expectedPrefix) {
                keyIDError = "Key ID must start with '\(expectedPrefix)' for the selected environment."
                isValid = false
            } else if trimmedKeyID.count != 23 {
                keyIDError = "Key ID must be exactly 23 characters long (current length: \(trimmedKeyID.count))."
                isValid = false
            } else {
                // Check if remaining characters are alphanumeric
                let suffix = String(trimmedKeyID.dropFirst(expectedPrefix.count))
                let isAlphanumeric = suffix.allSatisfy { $0.isLetter || $0.isNumber }
                if !isAlphanumeric {
                    keyIDError = "Key ID must contain only alphanumeric characters after the prefix."
                    isValid = false
                } else {
                    keyIDError = ""
                }
            }
        }

        // Validate Key Secret
        if trimmedKeySecret.isEmpty {
            keySecretError = "Key Secret is required."
            isValid = false
        } else {
            if trimmedKeySecret.count < 20 || trimmedKeySecret.count > 32 {
                keySecretError = "Key Secret must be between 20 and 32 characters long."
                isValid = false
            } else {
                let isAlphanumeric = trimmedKeySecret.allSatisfy { $0.isLetter || $0.isNumber }
                if !isAlphanumeric {
                    keySecretError = "Key Secret must contain only alphanumeric characters."
                    isValid = false
                } else {
                    keySecretError = ""
                }
            }
        }

        return isValid
    }

    // MARK: - Save

    /// Saves the Razorpay configuration.
    /// Creates a new record when `configID` is nil; otherwise updates the existing one.
    func save(storeID: UUID) async {
        guard validate() else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            if let existingID = configID {
                // Update existing configuration credentials.
                try await service.saveCredentials(
                    id: existingID,
                    environment: environment,
                    credential1: keyID.trimmingCharacters(in: .whitespacesAndNewlines),
                    credential2: keySecret.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            } else {
                // Insert a brand-new configuration record.
                let insert = PaymentConfigurationInsert(
                    storeID: storeID,
                    provider: .razorpay,
                    isEnabled: true,
                    status: .configured,
                    environment: environment,
                    credential1: keyID.trimmingCharacters(in: .whitespacesAndNewlines),
                    credential2: keySecret.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                let created = try await service.insertConfiguration(insert)
                configID = created.id
                isEditing = true
            }

            successMessage = isEditing
                ? "Razorpay configuration updated successfully."
                : "Razorpay configuration saved successfully."
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
