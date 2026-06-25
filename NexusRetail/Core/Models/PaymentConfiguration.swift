//
//  PaymentConfiguration.swift
//  NexusRetail
//
//  Data model for payment gateway configurations stored in Supabase.

import Foundation

// MARK: - Payment Provider

/// The supported payment gateway providers.
enum PaymentProvider: String, Codable, CaseIterable, Identifiable {
    case razorpay = "razorpay"
    case card = "card"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .razorpay: return "Razorpay"
        case .card: return "Card Payments (Stripe)"
        }
    }
    
    var subtitle: String {
        switch self {
        case .razorpay: return "Accept payments via Razorpay (UPI, Cards, Netbanking, Wallets)"
        case .card: return "Accept card payments via Stripe"
        }
    }
    
    var iconName: String {
        switch self {
        case .razorpay: return "indianrupeesign.circle.fill"
        case .card: return "creditcard.fill"
        }
    }
    
    /// Label for the first credential field.
    var credential1Label: String {
        switch self {
        case .razorpay: return "Key ID"
        case .card: return "Publishable Key"
        }
    }
    
    /// Placeholder for the first credential field.
    var credential1Placeholder: String {
        switch self {
        case .razorpay: return "Enter Razorpay Key ID"
        case .card: return "Enter Publishable Key"
        }
    }
    
    /// Label for the second credential field.
    var credential2Label: String {
        switch self {
        case .razorpay: return "Key Secret"
        case .card: return "Secret Key"
        }
    }
    
    /// Placeholder for the second credential field.
    var credential2Placeholder: String {
        switch self {
        case .razorpay: return "Enter Razorpay Key Secret"
        case .card: return "Enter Secret Key"
        }
    }
}

// MARK: - Payment Configuration Status

/// Represents the current state of a payment gateway configuration.
enum PaymentConfigStatus: String, Codable {
    case notConfigured = "not_configured"
    case configured = "configured"
    case invalid = "invalid"
}

// MARK: - Payment Environment

/// The environment mode for payment gateway credentials.
enum PaymentEnvironment: String, Codable, CaseIterable {
    case test = "test"
    case live = "live"
    
    var displayName: String {
        switch self {
        case .test: return "Test"
        case .live: return "Live"
        }
    }
}

// MARK: - Payment Configuration Model

/// Flat data model used by the UI (ViewModels and Views).
/// Adapted in the service layer from/to the real `payment_terminal` DB table.
struct PaymentConfiguration: Codable, Identifiable {
    let id: UUID
    var storeID: UUID
    var provider: PaymentProvider
    var isEnabled: Bool
    var status: PaymentConfigStatus
    var environment: PaymentEnvironment
    var credential1: String?
    var credential2: String?
    var createdAt: String?
    var updatedAt: String?
}

// MARK: - Supabase Table DTOs (payment_terminal)

/// Matches the real `payment_terminal` table rows.
struct PaymentTerminal: Codable, Identifiable {
    let id: UUID
    let storeID: UUID
    let type: PaymentProvider
    let config: PaymentTerminalConfig
    
    enum CodingKeys: String, CodingKey {
        case id
        case storeID = "store_id"
        case type
        case config
    }
}

/// Matches the jsonb `config` payload stored inside the `payment_terminal` table.
struct PaymentTerminalConfig: Codable {
    var isEnabled: Bool
    var status: PaymentConfigStatus
    var environment: PaymentEnvironment
    var credential1: String?
    var credential2: String?
    var updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case status
        case environment
        case credential1 = "credential_1"
        case credential2 = "credential_2"
        case updatedAt = "updated_at"
    }
}

/// DTO for inserting a new row into `payment_terminal`.
struct PaymentTerminalInsert: Codable {
    let storeID: UUID
    let type: PaymentProvider
    let config: PaymentTerminalConfig
    
    enum CodingKeys: String, CodingKey {
        case storeID = "store_id"
        case type
        case config
    }
}

/// DTO for updating `payment_terminal` row config.
struct PaymentTerminalUpdate: Codable {
    let config: PaymentTerminalConfig
}

// MARK: - DTO for list inserts (retains compatibility with old code)
struct PaymentConfigurationInsert: Codable {
    let storeID: UUID
    let provider: PaymentProvider
    var isEnabled: Bool
    var status: PaymentConfigStatus
    var environment: PaymentEnvironment
    var credential1: String? = nil
    var credential2: String? = nil
}

// MARK: - Adapter Mapping Extension

extension PaymentConfiguration {
    /// Adapts the database terminal row structure to the flat configurations structure.
    init(from terminal: PaymentTerminal) {
        self.id = terminal.id
        self.storeID = terminal.storeID
        self.provider = terminal.type
        self.isEnabled = terminal.config.isEnabled
        self.status = terminal.config.status
        self.environment = terminal.config.environment
        self.credential1 = terminal.config.credential1
        self.credential2 = terminal.config.credential2
        self.createdAt = nil
        self.updatedAt = terminal.config.updatedAt
    }
}

