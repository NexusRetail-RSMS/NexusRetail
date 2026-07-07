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
    let imageURL: String?
    
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
        case imageURL = "image_url"
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
    let orderType: String?
    let status: String?
    let client: StoreOrderClient?
    // Pickup verification code (BOPIS). Presence + status 'open' => waiting for customer.
    let pickupCode: String?

    // Nested relationship
    let orderLineItems: [OrderLineItem]?

    enum CodingKeys: String, CodingKey {
        case id
        case clientID = "client_id"
        case storeID = "store_id"
        case associateID = "associate_id"
        case total
        case createdAt = "created_at"
        case orderType = "order_type"
        case status
        case client
        case pickupCode = "pickup_code"
        case orderLineItems = "order_line_item"
    }

    init(id: UUID, clientID: UUID?, storeID: UUID?, associateID: UUID?, total: Double, createdAt: String, orderType: String?, status: String?, client: StoreOrderClient?, orderLineItems: [OrderLineItem]?, pickupCode: String? = nil) {
        self.id = id
        self.clientID = clientID
        self.storeID = storeID
        self.associateID = associateID
        self.total = total
        self.createdAt = createdAt
        self.orderType = orderType
        self.status = status
        self.client = client
        self.pickupCode = pickupCode
        self.orderLineItems = orderLineItems
    }
}

struct StoreOrderClient: Codable {
    let name: String?
    let phone: String?
}

struct OrderLineItem: Codable, Identifiable {
    let id: UUID?
    let orderID: UUID?
    let quantity: Int
    // Optional: some queries don't select applied_price. Decoding must not fail
    // when the column is omitted (previously crashed the BOPIS fetch).
    let appliedPrice: Double?
    let products: NestedProduct?

    enum CodingKeys: String, CodingKey {
        case id
        case orderID = "order_id"
        case quantity
        case appliedPrice = "applied_price"
        case products
    }

    init(id: UUID?, orderID: UUID?, quantity: Int, appliedPrice: Double?, products: NestedProduct?) {
        self.id = id
        self.orderID = orderID
        self.quantity = quantity
        self.appliedPrice = appliedPrice
        self.products = products
    }
}

struct NestedProduct: Codable {
    // All optional: different queries select different subsets of product
    // columns, so decoding must tolerate any missing field rather than crash.
    let itemId: Int64?
    let itemName: String?
    let category: String?
    let skuCode: String?
    let price: Double?
    let pexelsPage: String?
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case itemName = "item_name"
        case category
        case skuCode = "sku_code"
        case price
        case pexelsPage = "pexels_page"
        case imageUrl = "image_url"
    }
}
