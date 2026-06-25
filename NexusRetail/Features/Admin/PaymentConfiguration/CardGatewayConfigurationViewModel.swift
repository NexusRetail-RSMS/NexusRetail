//
//  CardGatewayConfigurationViewModel.swift
//  NexusRetail
//
//  ViewModel for the Card Gateway (Stripe) credential configuration screen.
//  Uses @Observable (Observation framework).
//

import Foundation

@Observable
class CardGatewayConfigurationViewModel {

    // MARK: - Form Fields

    var environment: PaymentEnvironment = .test
    var publicKey: String = ""
    var secretKey: String = ""

    // MARK: - UI State

    var isLoading: Bool = false
    var isSaving: Bool = false
    var errorMessage: String = ""
    var showError: Bool = false
    var showSuccess: Bool = false
    var successMessage: String = ""

    // MARK: - Field Validation Errors

    var publicKeyError: String = ""
    var secretKeyError: String = ""

    // MARK: - Editing State

    /// `true` when editing an existing configuration (vs. creating a new one).
    var isEditing: Bool = false

    /// The database ID of the existing configuration, if any.
    var configID: UUID? = nil

    // MARK: - Service

    let service = PaymentConfigurationService()

    // MARK: - Load Existing

    /// Fetches the existing Card Gateway configuration for the given store.
    /// If a record exists, populates the form fields and switches to edit mode.
    func loadExisting(storeID: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            if let config = try await service.fetchConfiguration(
                storeID: storeID,
                provider: .card
            ) {
                environment = config.environment
                publicKey = config.credential1 ?? ""
                secretKey = config.credential2 ?? ""
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
        let trimmedPublicKey = publicKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSecretKey = secretKey.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate Publishable Key
        if trimmedPublicKey.isEmpty {
            publicKeyError = "Publishable Key is required."
            isValid = false
        } else {
            let expectedPrefix = environment == .test ? "pk_test_" : "pk_live_"
            if !trimmedPublicKey.hasPrefix(expectedPrefix) {
                publicKeyError = "Publishable Key must start with '\(expectedPrefix)' for the selected environment."
                isValid = false
            } else if trimmedPublicKey.count < 24 {
                publicKeyError = "Publishable Key must be at least 24 characters long."
                isValid = false
            } else {
                // Check if characters after prefix are alphanumeric/underscores/hyphens
                let suffix = String(trimmedPublicKey.dropFirst(expectedPrefix.count))
                let isValidCharacters = suffix.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
                if !isValidCharacters {
                    publicKeyError = "Publishable Key contains invalid characters."
                    isValid = false
                } else {
                    publicKeyError = ""
                }
            }
        }

        // Validate Secret Key
        if trimmedSecretKey.isEmpty {
            secretKeyError = "Secret Key is required."
            isValid = false
        } else {
            let expectedPrefix = environment == .test ? "sk_test_" : "sk_live_"
            if !trimmedSecretKey.hasPrefix(expectedPrefix) {
                secretKeyError = "Secret Key must start with '\(expectedPrefix)' for the selected environment."
                isValid = false
            } else if trimmedSecretKey.count < 24 {
                secretKeyError = "Secret Key must be at least 24 characters long."
                isValid = false
            } else {
                // Check if characters after prefix are alphanumeric/underscores/hyphens
                let suffix = String(trimmedSecretKey.dropFirst(expectedPrefix.count))
                let isValidCharacters = suffix.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
                if !isValidCharacters {
                    secretKeyError = "Secret Key contains invalid characters."
                    isValid = false
                } else {
                    secretKeyError = ""
                }
            }
        }

        return isValid
    }

    // MARK: - Save

    /// Saves the Card Gateway configuration.
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
                    credential1: publicKey.trimmingCharacters(in: .whitespacesAndNewlines),
                    credential2: secretKey.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            } else {
                // Insert a brand-new configuration record.
                let insert = PaymentConfigurationInsert(
                    storeID: storeID,
                    provider: .card,
                    isEnabled: true,
                    status: .configured,
                    environment: environment,
                    credential1: publicKey.trimmingCharacters(in: .whitespacesAndNewlines),
                    credential2: secretKey.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                let created = try await service.insertConfiguration(insert)
                configID = created.id
                isEditing = true
            }

            successMessage = isEditing
                ? "Card Gateway configuration updated successfully."
                : "Card Gateway configuration saved successfully."
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
