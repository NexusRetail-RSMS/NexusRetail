//
//  UserRole.swift
//  NexusRetail
//

import Foundation

/// The four user roles. Drives RBAC + navigation.
enum UserRole: String, Codable {
    case admin = "admin"
    case manager = "manager"
    case salesAssociate = "sales_associate"
    case afterSales = "after_sales"
    
    var displayName: String {
        switch self {
        case .admin: return "Admin"
        case .manager: return "Manager"
        case .salesAssociate: return "Sales Associate"
        case .afterSales: return "After Sales"
        }
    }
}
