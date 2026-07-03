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
            return RSMSColors.error
        case .medium:
            return RSMSColors.warning
        case .low:
            return RSMSColors.success
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
            return RSMSColors.warning
        case .repair:
            return RSMSColors.primaryText // Or another custom color
        case .completed:
            return RSMSColors.success
        case .returned:
            return RSMSColors.burgundy
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
