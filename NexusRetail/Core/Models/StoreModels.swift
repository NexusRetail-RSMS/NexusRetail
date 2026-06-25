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

