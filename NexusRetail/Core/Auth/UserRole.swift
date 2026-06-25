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

// MARK: - UI Extensions for UserRole

extension UserRole: CaseIterable {
    public static var allCases: [UserRole] {
        [.admin, .manager, .salesAssociate, .afterSales]
    }
    
    var descriptionText: String {
        switch self {
        case .admin: return "Manage global pricing, onboarding, and store transfers."
        case .manager: return "Manage store operations, inventory, and staff performance."
        case .salesAssociate: return "Operate point of sale, clienteling, and order fulfillment."
        case .afterSales: return "Manage returns, warranties, and item condition estimates."
        }
    }
    
    var iconName: String {
        switch self {
        case .admin: return "globe.desk"
        case .manager: return "briefcase.fill"
        case .salesAssociate: return "cart.fill"
        case .afterSales: return "wrench.and.screwdriver.fill"
        }
    }
}
