//
//  StoreModels.swift
//  NexusRetail
//

import Foundation

enum StoreStatus: String, Codable {
    case active = "active"
    case archived = "archived"
}

struct Store: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let address: String?
    let locale: String?
    let currencyCode: String?
    let timezone: String?
    let phone: String?
    let managerID: UUID?
    let isWarehouse: Bool?
    let status: StoreStatus?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case locale
        case currencyCode = "currency_code"
        case timezone
        case phone
        case managerID = "manager_id"
        case isWarehouse = "is_warehouse"
        case status
    }
    
    var readableLocale: String {
        guard let localeId = locale else { return "Unknown Locale" }
        return Locale(identifier: localeId).localizedString(forIdentifier: localeId) ?? localeId
    }
}

// MARK: - Store Order Analytics

struct StoreOrder: Codable, Identifiable {
    let id: UUID
    let clientID: UUID?
    let storeID: UUID?
    let associateID: UUID?
    let total: Double
    let createdAt: String
    
    // Nested relationship
    let orderLineItems: [OrderLineItem]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientID = "client_id"
        case storeID = "store_id"
        case associateID = "associate_id"
        case total
        case createdAt = "created_at"
        case orderLineItems = "order_line_item"
    }
}

struct OrderLineItem: Codable, Identifiable {
    let id: UUID?
    let orderID: UUID?
    let quantity: Int
    let appliedPrice: Double
    let sku: NestedSKU?
    
    enum CodingKeys: String, CodingKey {
        case id
        case orderID = "order_id"
        case quantity
        case appliedPrice = "applied_price"
        case sku
    }
}

struct NestedSKU: Codable, Identifiable {
    let id: UUID?
    let name: String
    let category: String
}

