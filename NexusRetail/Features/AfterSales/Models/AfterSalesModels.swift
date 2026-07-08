//
//  AfterSalesModels.swift
//  NexusRetail
//

import Foundation
import SwiftUI

enum ServicePriority: String, CaseIterable, Codable {
    case high = "High Priority"
    case medium = "Medium Priority"
    case low = "Low Priority"
    
    var color: Color {
        switch self {
        case .high:
            return AppTheme().error
        case .medium:
            return AppTheme().warning
        case .low:
            return AppTheme().success
        }
    }
}

enum ServiceStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case repair = "Repair"
    case completed = "Completed"
    case returned = "Returned"
    
    var color: Color {
        switch self {
        case .pending:
            return AppTheme().warning
        case .repair:
            return AppTheme().primaryText // Or another custom color
        case .completed:
            return AppTheme().success
        case .returned:
            return AppTheme().burgundy
        }
    }
}

struct ServiceRequest: Identifiable {
    let id: UUID
    let serviceId: String
    let customerName: String
    let issueType: String
    let priority: ServicePriority
    let daysRemaining: Int
    let status: ServiceStatus
}

struct ServiceActivity: Identifiable {
    let id: UUID
    let statusIcon: String
    let statusText: String
    let customerName: String
    let serviceId: String
    let time: String
    let iconColor: Color
}

struct ServiceChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}
