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
    let latitude: Double?
    let longitude: Double?
    let city: String?
    let country: String?
    
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
        case latitude
        case longitude
        case city
        case country
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
    
    init(id: UUID, clientID: UUID?, storeID: UUID?, associateID: UUID?, total: Double, createdAt: String, orderLineItems: [OrderLineItem]?) {
        self.id = id
        self.clientID = clientID
        self.storeID = storeID
        self.associateID = associateID
        self.total = total
        self.createdAt = createdAt
        self.orderLineItems = orderLineItems
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
    
    init(id: UUID?, orderID: UUID?, quantity: Int, appliedPrice: Double, sku: NestedSKU?) {
        self.id = id
        self.orderID = orderID
        self.quantity = quantity
        self.appliedPrice = appliedPrice
        self.sku = sku
    }
}

struct NestedSKU: Codable, Identifiable {
    let id: UUID?
    let name: String
    let category: String
}

